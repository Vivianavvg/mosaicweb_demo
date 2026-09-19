import Foundation

public enum ChangeType: String, Codable, CaseIterable {
    case newAccount = "new_account"
    case closedAccount = "closed_account"
    case balanceIncrease = "balance_increase"
    case balanceDecrease = "balance_decrease"
    case statusChange = "status_change"
    case newInquiry = "new_inquiry"
    case newAddress = "new_address"
    case jointOrAuthorizedUserChange = "joint_or_authorized_user_change"
    case collectionOrChargeoffChange = "collection_or_chargeoff_change"
    case duplicateOrInconsistentEntry = "duplicate_or_inconsistent_entry"

    public var displayName: String {
        switch self {
        case .newAccount: return "New Account on Report"
        case .closedAccount: return "Account Closed"
        case .balanceIncrease: return "Balance Increase"
        case .balanceDecrease: return "Balance Decrease"
        case .statusChange: return "Account Status Change"
        case .newInquiry: return "New Credit Inquiry"
        case .newAddress: return "New Address Reported"
        case .jointOrAuthorizedUserChange: return "Joint / Authorized User Status Change"
        case .collectionOrChargeoffChange: return "Collection or Charge-off Entry"
        case .duplicateOrInconsistentEntry: return "Potential Inconsistency"
        }
    }
}

public enum ChangeSeverity: String, Codable, CaseIterable {
    case informational = "informational"
    case review = "review"
    case urgentReview = "urgent_review"

    public var label: String {
        switch self {
        case .informational: return "Info"
        case .review: return "Needs Review"
        case .urgentReview: return "Priority Review"
        }
    }
}

public enum UserClassification: String, Codable, CaseIterable {
    case recognized = "recognized"
    case unrecognized = "unrecognized"
    case pressuredOrNotFreelyAgreed = "pressured_or_not_freely_agreed"
    case notSure = "not_sure"
    case ignored = "ignored"

    public var title: String {
        switch self {
        case .recognized: return "Recognized"
        case .unrecognized: return "Unrecognized"
        case .pressuredOrNotFreelyAgreed: return "Pressured / No Consent"
        case .notSure: return "Not Sure"
        case .ignored: return "Ignore"
        }
    }

    public var descriptionText: String {
        switch self {
        case .recognized:
            return "I opened and authorized this account myself."
        case .unrecognized:
            return "I did not open, authorize, or use this account."
        case .pressuredOrNotFreelyAgreed:
            return "I was pressured or did not freely agree to this account."
        case .notSure:
            return "I need time to review my own records first."
        case .ignored:
            return "No action needed at this time."
        }
    }
}

public struct ChangeItem: Identifiable, Codable, Hashable {
    public let id: UUID
    public var userId: String
    public var currentSnapshotId: UUID
    public var priorSnapshotId: UUID?
    public var changeType: ChangeType
    public var severity: ChangeSeverity
    public var summary: String
    public var sourcePages: [Int]
    public var confidence: Double
    public var classification: UserClassification?
    public var createdAt: Date
    public var deltaSummary: String?
    public var whySeeingThis: String
    public var relatedAccountLast4: String?
    public var issuerName: String?

    public init(
        id: UUID = UUID(),
        userId: String = "user_demo",
        currentSnapshotId: UUID,
        priorSnapshotId: UUID? = nil,
        changeType: ChangeType,
        severity: ChangeSeverity = .review,
        summary: String,
        sourcePages: [Int] = [1],
        confidence: Double = 0.95,
        classification: UserClassification? = nil,
        createdAt: Date = Date(),
        deltaSummary: String? = nil,
        whySeeingThis: String = "This item appeared or changed between reports.",
        relatedAccountLast4: String? = nil,
        issuerName: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.currentSnapshotId = currentSnapshotId
        self.priorSnapshotId = priorSnapshotId
        self.changeType = changeType
        self.severity = severity
        self.summary = summary
        self.sourcePages = sourcePages
        self.confidence = confidence
        self.classification = classification
        self.createdAt = createdAt
        self.deltaSummary = deltaSummary
        self.whySeeingThis = whySeeingThis
        self.relatedAccountLast4 = relatedAccountLast4
        self.issuerName = issuerName
    }
}
