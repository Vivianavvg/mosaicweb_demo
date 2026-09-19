import Foundation

public final class ReportDiffEngine {
    public static let shared = ReportDiffEngine()

    private init() {}

    /// Performs normalized local diff between a current snapshot and an optional prior snapshot
    public func diff(current: ReportSnapshot, prior: ReportSnapshot?) -> [ChangeItem] {
        var changes: [ChangeItem] = []

        guard let prior = prior else {
            // First scan scenario: inventory all open or flagged accounts as items needing review
            for account in current.accounts {
                let severity: ChangeSeverity = account.accountType.lowercased() == "collection" ? .urgentReview : .review
                let type: ChangeType = account.accountType.lowercased() == "collection" ? .collectionOrChargeoffChange : .newAccount

                changes.append(ChangeItem(
                    userId: current.userId,
                    currentSnapshotId: current.id,
                    priorSnapshotId: nil,
                    changeType: type,
                    severity: severity,
                    summary: "\(account.issuerName) (**** \(account.accountLast4)): Balance \(account.formattedBalance)",
                    sourcePages: [account.sourcePage],
                    confidence: account.extractionConfidence,
                    deltaSummary: "Initial report inventory — balance \(account.formattedBalance)",
                    whySeeingThis: "This item was inventoried on your initial credit report scan.",
                    relatedAccountLast4: account.accountLast4,
                    issuerName: account.issuerName
                ))
            }

            for inquiry in current.inquiries {
                changes.append(ChangeItem(
                    userId: current.userId,
                    currentSnapshotId: current.id,
                    priorSnapshotId: nil,
                    changeType: .newInquiry,
                    severity: .informational,
                    summary: "Inquiry from \(inquiry.inquirerName)",
                    sourcePages: [inquiry.sourcePage],
                    confidence: inquiry.extractionConfidence,
                    deltaSummary: inquiry.inquiryDate.map { "Reported on \($0)" },
                    whySeeingThis: "Credit inquiry appears on your initial report.",
                    relatedAccountLast4: nil,
                    issuerName: inquiry.inquirerName
                ))
            }

            for address in current.addresses {
                changes.append(ChangeItem(
                    userId: current.userId,
                    currentSnapshotId: current.id,
                    priorSnapshotId: nil,
                    changeType: .newAddress,
                    severity: .informational,
                    summary: "Address: \(address.redactedAddressLabel)",
                    sourcePages: [address.sourcePage],
                    confidence: 0.95,
                    deltaSummary: address.reportedDate.map { "Reported on \($0)" },
                    whySeeingThis: "Address listed on your initial report.",
                    relatedAccountLast4: nil,
                    issuerName: nil
                ))
            }

            return changes
        }

        // Two-report comparison scenario:
        let priorAccountsByFingerprint = Dictionary(grouping: prior.accounts, by: { "\($0.issuerName.lowercased())_\($0.accountLast4)" }).compactMapValues({ $0.first })
        let currentAccountsByFingerprint = Dictionary(grouping: current.accounts, by: { "\($0.issuerName.lowercased())_\($0.accountLast4)" }).compactMapValues({ $0.first })

        // Check accounts present in current report
        for (fingerprint, currentAcc) in currentAccountsByFingerprint {
            if let priorAcc = priorAccountsByFingerprint[fingerprint] {
                // Account exists in both: check for changes

                // 1. Joint / Authorized User change
                if !priorAcc.jointIndicator && currentAcc.jointIndicator {
                    changes.append(ChangeItem(
                        userId: current.userId,
                        currentSnapshotId: current.id,
                        priorSnapshotId: prior.id,
                        changeType: .jointOrAuthorizedUserChange,
                        severity: .urgentReview,
                        summary: "\(currentAcc.issuerName) (**** \(currentAcc.accountLast4)): Joint status changed",
                        sourcePages: [currentAcc.sourcePage],
                        confidence: currentAcc.extractionConfidence,
                        deltaSummary: "Changed from Individual to Joint account",
                        whySeeingThis: "Account status modified to indicate joint liability.",
                        relatedAccountLast4: currentAcc.accountLast4,
                        issuerName: currentAcc.issuerName
                    ))
                }

                // 2. Balance changes
                if let currBal = currentAcc.balanceCents, let priorBal = priorAcc.balanceCents {
                    let diffCents = currBal - priorBal
                    if diffCents > 0 {
                        let diffDollars = Double(diffCents) / 100.0
                        changes.append(ChangeItem(
                            userId: current.userId,
                            currentSnapshotId: current.id,
                            priorSnapshotId: prior.id,
                            changeType: .balanceIncrease,
                            severity: diffCents > 50000 ? .review : .informational,
                            summary: "\(currentAcc.issuerName) (**** \(currentAcc.accountLast4)): Balance increased by $\(Int(diffDollars))",
                            sourcePages: [currentAcc.sourcePage],
                            confidence: currentAcc.extractionConfidence,
                            deltaSummary: "\(priorAcc.formattedBalance) -> \(currentAcc.formattedBalance) (+$\(Int(diffDollars)))",
                            whySeeingThis: "Outstanding balance reported increased between report dates.",
                            relatedAccountLast4: currentAcc.accountLast4,
                            issuerName: currentAcc.issuerName
                        ))
                    } else if diffCents < 0 {
                        let diffDollars = Double(abs(diffCents)) / 100.0
                        changes.append(ChangeItem(
                            userId: current.userId,
                            currentSnapshotId: current.id,
                            priorSnapshotId: prior.id,
                            changeType: .balanceDecrease,
                            severity: .informational,
                            summary: "\(currentAcc.issuerName) (**** \(currentAcc.accountLast4)): Balance decreased by $\(Int(diffDollars))",
                            sourcePages: [currentAcc.sourcePage],
                            confidence: currentAcc.extractionConfidence,
                            deltaSummary: "\(priorAcc.formattedBalance) -> \(currentAcc.formattedBalance) (-$\(Int(diffDollars)))",
                            whySeeingThis: "Balance decreased between report dates.",
                            relatedAccountLast4: currentAcc.accountLast4,
                            issuerName: currentAcc.issuerName
                        ))
                    }
                }

                // 3. Status changes
                if priorAcc.status.lowercased() != currentAcc.status.lowercased() {
                    changes.append(ChangeItem(
                        userId: current.userId,
                        currentSnapshotId: current.id,
                        priorSnapshotId: prior.id,
                        changeType: .statusChange,
                        severity: .review,
                        summary: "\(currentAcc.issuerName) (**** \(currentAcc.accountLast4)): Status changed to \(currentAcc.status)",
                        sourcePages: [currentAcc.sourcePage],
                        confidence: currentAcc.extractionConfidence,
                        deltaSummary: "Status updated: \(priorAcc.status) -> \(currentAcc.status)",
                        whySeeingThis: "The reported standing or status for this account changed.",
                        relatedAccountLast4: currentAcc.accountLast4,
                        issuerName: currentAcc.issuerName
                    ))
                }
            } else {
                // New account on current report
                let isCollection = currentAcc.accountType.lowercased() == "collection" || currentAcc.issuerName.lowercased().contains("recovery")
                let changeType: ChangeType = isCollection ? .collectionOrChargeoffChange : .newAccount
                let severity: ChangeSeverity = isCollection ? .urgentReview : .review

                changes.append(ChangeItem(
                    userId: current.userId,
                    currentSnapshotId: current.id,
                    priorSnapshotId: prior.id,
                    changeType: changeType,
                    severity: severity,
                    summary: "\(currentAcc.issuerName) (**** \(currentAcc.accountLast4)): New \(isCollection ? "Collection" : "Account")",
                    sourcePages: [currentAcc.sourcePage],
                    confidence: currentAcc.extractionConfidence,
                    deltaSummary: "New on this report with balance \(currentAcc.formattedBalance)",
                    whySeeingThis: isCollection ? "A collection agency or debt assignee appeared for the first time." : "This account did not appear on the prior report.",
                    relatedAccountLast4: currentAcc.accountLast4,
                    issuerName: currentAcc.issuerName
                ))
            }
        }

        // Check for closed accounts (in prior but missing from current)
        for (fingerprint, priorAcc) in priorAccountsByFingerprint {
            if currentAccountsByFingerprint[fingerprint] == nil {
                changes.append(ChangeItem(
                    userId: current.userId,
                    currentSnapshotId: current.id,
                    priorSnapshotId: prior.id,
                    changeType: .closedAccount,
                    severity: .informational,
                    summary: "\(priorAcc.issuerName) (**** \(priorAcc.accountLast4)): No longer listed / closed",
                    sourcePages: [1],
                    confidence: 0.92,
                    deltaSummary: "Removed from active open accounts",
                    whySeeingThis: "Account present on prior report no longer appears on the current report.",
                    relatedAccountLast4: priorAcc.accountLast4,
                    issuerName: priorAcc.issuerName
                ))
            }
        }

        // Compare inquiries
        let priorInquirerNames = Set(prior.inquiries.map { $0.inquirerName.lowercased() })
        for inquiry in current.inquiries {
            if !priorInquirerNames.contains(inquiry.inquirerName.lowercased()) {
                changes.append(ChangeItem(
                    userId: current.userId,
                    currentSnapshotId: current.id,
                    priorSnapshotId: prior.id,
                    changeType: .newInquiry,
                    severity: .review,
                    summary: "New hard inquiry: \(inquiry.inquirerName)",
                    sourcePages: [inquiry.sourcePage],
                    confidence: inquiry.extractionConfidence,
                    deltaSummary: inquiry.inquiryDate.map { "Inquiry date: \($0)" } ?? "New on this report",
                    whySeeingThis: "A creditor checked your credit profile since the prior report.",
                    relatedAccountLast4: nil,
                    issuerName: inquiry.inquirerName
                ))
            }
        }

        // Compare addresses
        let priorAddressLabels = Set(prior.addresses.map { $0.redactedAddressLabel.lowercased() })
        for address in current.addresses {
            if !priorAddressLabels.contains(address.redactedAddressLabel.lowercased()) {
                changes.append(ChangeItem(
                    userId: current.userId,
                    currentSnapshotId: current.id,
                    priorSnapshotId: prior.id,
                    changeType: .newAddress,
                    severity: .review,
                    summary: "New address reported: \(address.redactedAddressLabel)",
                    sourcePages: [address.sourcePage],
                    confidence: 0.95,
                    deltaSummary: address.reportedDate.map { "Reported: \($0)" } ?? "Newly added address",
                    whySeeingThis: "A new mailing or residential address was added to your bureau file.",
                    relatedAccountLast4: nil,
                    issuerName: nil
                ))
            }
        }

        return changes
    }
}
