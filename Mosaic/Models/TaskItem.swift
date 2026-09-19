import Foundation

public enum RecipientType: String, Codable, CaseIterable {
    case bureau = "bureau"
    case furnisher = "furnisher"
    case ftc = "ftc_preparation"
    case security = "security_freeze"
    case other = "other"

    public var displayName: String {
        switch self {
        case .bureau: return "Credit Reporting Bureau"
        case .furnisher: return "Creditor / Furnisher"
        case .ftc: return "FTC Worksheet / Prep"
        case .security: return "Bureau Security Freeze"
        case .other: return "Other Entity"
        }
    }
}

public enum TaskStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case sent = "sent"
    case received = "received"
    case needsFollowUp = "needs_follow_up"
    case resolved = "resolved"
    case closed = "closed"

    public var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .sent: return "Sent"
        case .received: return "Response Received"
        case .needsFollowUp: return "Needs Follow-Up"
        case .resolved: return "Resolved"
        case .closed: return "Closed"
        }
    }

    public var isCompleted: Bool {
        return self == .resolved || self == .closed
    }
}

public struct TaskItem: Identifiable, Codable, Hashable {
    public let id: UUID
    public var packetId: UUID?
    public var title: String
    public var recipientType: RecipientType
    public var dueAt: Date?
    public var sentDate: Date?
    public var deliveryMethod: String?
    public var referenceNumber: String?
    public var expectedResponseDate: Date?
    public var responseReceivedDate: Date?
    public var status: TaskStatus
    public var notes: String
    public var sourceUrl: String
    public var ruleVersion: String
    public var completedAt: Date?

    public var isCompleted: Bool {
        return status.isCompleted
    }

    public init(
        id: UUID = UUID(),
        packetId: UUID? = nil,
        title: String,
        recipientType: RecipientType = .bureau,
        dueAt: Date? = nil,
        sentDate: Date? = nil,
        deliveryMethod: String? = "Certified Mail w/ Return Receipt",
        referenceNumber: String? = nil,
        expectedResponseDate: Date? = nil,
        responseReceivedDate: Date? = nil,
        status: TaskStatus = .draft,
        notes: String = "",
        sourceUrl: String = "https://www.consumerfinance.gov/ask-cfpb/how-do-i-dispute-an-error-on-my-credit-report-en-314/",
        ruleVersion: String = "CFPB Regulation V (12 CFR § 1022.43) / FCRA § 611",
        completedAt: Date? = nil
    ) {
        self.id = id
        self.packetId = packetId
        self.title = title
        self.recipientType = recipientType
        self.dueAt = dueAt
        self.sentDate = sentDate
        self.deliveryMethod = deliveryMethod
        self.referenceNumber = referenceNumber
        self.expectedResponseDate = expectedResponseDate
        self.responseReceivedDate = responseReceivedDate
        self.status = status
        self.notes = notes
        self.sourceUrl = sourceUrl
        self.ruleVersion = ruleVersion
        self.completedAt = completedAt
    }
}
