import SwiftUI

struct ExtractionReviewView: View {
    @EnvironmentObject private var appState: AppState
    let snapshot: ReportSnapshot
    let onProceedToCompare: () -> Void

    @State private var selectedTab: Int = 0
    @State private var editingAccount: ReportAccount? = nil
    @State private var showCorrectionSheet: Bool = false

    var currentSnapshotAccounts: [ReportAccount] {
        appState.currentSnapshot?.accounts ?? snapshot.accounts
    }

    var body: some View {
        VStack(spacing: 0) {
            // Segmented Picker
            Picker("Section", selection: $selectedTab) {
                Text("Accounts (\(currentSnapshotAccounts.count))").tag(0)
                Text("Inquiries (\(snapshot.inquiries.count))").tag(1)
                Text("Addresses (\(snapshot.addresses.count))").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.mosaicPage)

            ScrollView {
                VStack(spacing: 14) {
                    if selectedTab == 0 {
                        // Accounts List
                        ForEach(currentSnapshotAccounts) { account in
                            Button(action: {
                                editingAccount = account
                                showCorrectionSheet = true
                            }) {
                                AccountCard(account: account)
                            }
                            .buttonStyle(.plain)
                        }
                    } else if selectedTab == 1 {
                        // Inquiries List
                        ForEach(snapshot.inquiries) { inquiry in
                            InquiryCard(inquiry: inquiry)
                        }
                    } else {
                        // Addresses List
                        ForEach(snapshot.addresses) { address in
                            AddressCard(address: address)
                        }
                    }

                    NavigationLink(destination: CompareView()) {
                        HStack {
                            Text("Compare Reports & Review Changes")
                            Image(systemName: "arrow.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.mosaicInk)
                        .cornerRadius(12)
                    }
                    .padding(.top, 12)
                }
                .padding(16)
            }
        }
        .background(Color.mosaicPage.ignoresSafeArea())
        .navigationTitle("Extracted Facts Review")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingAccount) { acc in
            AccountCorrectionSheet(account: acc) { updated in
                if var current = appState.currentSnapshot {
                    if let idx = current.accounts.firstIndex(where: { $0.id == updated.id }) {
                        current.accounts[idx] = updated
                        appState.currentSnapshot = current
                        appState.changeItems = ReportDiffEngine.shared.diff(current: current, prior: appState.priorSnapshot)
                    }
                }
            }
        }
    }
}

private struct AccountCorrectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var account: ReportAccount
    let onSave: (ReportAccount) -> Void

    @State private var balanceDollars: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Account Identification")) {
                    Text("Issuer: \(account.issuerName)")
                    Text("Last 4: **** \(account.accountLast4)")
                    Text("Source Page: Page \(account.sourcePage)")
                }

                Section(header: Text("Balance & Standing")) {
                    HStack {
                        Text("Balance ($)")
                        Spacer()
                        TextField("Amount", text: $balanceDollars)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    Toggle("Joint Liability Account", isOn: $account.jointIndicator)

                    Picker("Status", selection: $account.status) {
                        Text("Open / Current").tag("Open / Current")
                        Text("Past Due 30 Days").tag("Past Due 30 Days")
                        Text("Assigned to Collections").tag("Seriously Past Due / Assigned to Collections")
                        Text("Closed").tag("Closed")
                    }
                }
            }
            .navigationTitle("Correct Extracted Fact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let dollars = Int(balanceDollars) {
                            account.balanceCents = dollars * 100
                        }
                        onSave(account)
                        dismiss()
                    }
                    .foregroundColor(Color.mosaicAccent)
                }
            }
            .onAppear {
                if let cents = account.balanceCents {
                    balanceDollars = "\(cents / 100)"
                }
            }
        }
    }
}

private struct AccountCard: View {
    let account: ReportAccount

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.issuerName)
                        .font(.headline)
                        .foregroundColor(Color.mosaicInk)
                    Text("Account: **** \(account.accountLast4) • \(account.accountType)")
                        .font(.caption)
                        .foregroundColor(Color.mosaicMuted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(account.formattedBalance)
                        .font(.title3.bold())
                        .foregroundColor(Color.mosaicAccent)
                    Text("Tap to edit")
                        .font(.system(size: 9))
                        .foregroundColor(Color.mosaicMuted)
                }
            }

            Divider().background(Color.mosaicCardBorder)

            HStack(spacing: 16) {
                InfoColumn(title: "Status", value: account.status)
                InfoColumn(title: "Standing", value: account.paymentStatus ?? "Current")
                InfoColumn(title: "Liability", value: account.jointIndicator ? "Joint" : "Individual")
            }

            HStack {
                Text("Source: Page \(account.sourcePage)")
                    .font(.caption2.bold())
                    .foregroundColor(Color.mosaicTeal)
                Spacer()
                Text("Confidence: \(Int(account.extractionConfidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(Color.mosaicMuted)
            }
        }
        .padding(14)
        .background(Color.mosaicCardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.mosaicCardBorder, lineWidth: 1)
        )
    }
}

private struct InquiryCard: View {
    let inquiry: ReportInquiry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(inquiry.inquirerName)
                    .font(.headline)
                    .foregroundColor(Color.mosaicInk)
                if let date = inquiry.inquiryDate {
                    Text("Date Reported: \(date)")
                        .font(.caption)
                        .foregroundColor(Color.mosaicMuted)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Page \(inquiry.sourcePage)")
                    .font(.caption2.bold())
                    .foregroundColor(Color.mosaicAccent)
                Text("\(Int(inquiry.extractionConfidence * 100))% conf")
                    .font(.caption2)
                    .foregroundColor(Color.mosaicMuted)
            }
        }
        .padding(14)
        .background(Color.mosaicCardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.mosaicCardBorder, lineWidth: 1)
        )
    }
}

private struct AddressCard: View {
    let address: ReportAddress

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(address.redactedAddressLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color.mosaicInk)
                if let date = address.reportedDate {
                    Text("Reported Date: \(date)")
                        .font(.caption)
                        .foregroundColor(Color.mosaicMuted)
                }
            }
            Spacer()
            Text("Page \(address.sourcePage)")
                .font(.caption2.bold())
                .foregroundColor(Color.mosaicAccent)
        }
        .padding(14)
        .background(Color.mosaicCardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.mosaicCardBorder, lineWidth: 1)
        )
    }
}

private struct InfoColumn: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(Color.mosaicMuted)
            Text(value)
                .font(.caption.bold())
                .foregroundColor(Color.mosaicInk)
        }
    }
}
