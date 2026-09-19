import Foundation

public enum PacketDocumentType: String, Codable, CaseIterable {
    case ftcPrep = "ftc_prep"
    case bureauDispute = "bureau_dispute"
    case furnisherDispute = "furnisher_dispute"
    case evidenceChecklist = "evidence_checklist"
    case freezeChecklist = "freeze_checklist"

    public var title: String {
        switch self {
        case .ftcPrep: return "FTC IdentityTheft.gov Preparation Worksheet"
        case .bureauDispute: return "Credit Bureau Dispute Letter (Draft)"
        case .furnisherDispute: return "Furnisher / Creditor Notice (Draft)"
        case .evidenceChecklist: return "Evidence & Records Checklist"
        case .freezeChecklist: return "Credit Freeze & Fraud Alert Guide"
        }
    }

    public var defaultSourceUrl: String {
        switch self {
        case .ftcPrep: return "https://www.identitytheft.gov/"
        case .bureauDispute: return "https://www.consumerfinance.gov/consumer-tools/credit-reports-and-scores/"
        case .furnisherDispute: return "https://www.consumerfinance.gov/ask-cfpb/how-do-i-dispute-an-error-on-my-credit-report-en-314/"
        case .evidenceChecklist: return "https://www.consumerfinance.gov/"
        case .freezeChecklist: return "https://consumer.ftc.gov/articles/credit-freezes-and-fraud-alerts"
        }
    }
}

public enum PacketStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case readyForReview = "ready_for_review"
    case exported = "exported"
    case inProgress = "in_progress"
    case resolved = "resolved"

    public var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .readyForReview: return "Ready for Review"
        case .exported: return "Exported"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        }
    }
}

public struct PacketDocument: Identifiable, Codable, Hashable {
    public let id: UUID
    public var packetId: UUID
    public var documentType: PacketDocumentType
    public var title: String
    public var draftText: String
    public var sourceUrls: [String]
    public var generatedBy: String
    public var reviewedByUserAt: Date?

    public init(
        id: UUID = UUID(),
        packetId: UUID = UUID(),
        documentType: PacketDocumentType,
        title: String? = nil,
        draftText: String,
        sourceUrls: [String] = [],
        generatedBy: String = "gemini-3.6-flash",
        reviewedByUserAt: Date? = nil
    ) {
        self.id = id
        self.packetId = packetId
        self.documentType = documentType
        self.title = title ?? documentType.title
        self.draftText = draftText
        self.sourceUrls = sourceUrls.isEmpty ? [documentType.defaultSourceUrl] : sourceUrls
        self.generatedBy = generatedBy
        self.reviewedByUserAt = reviewedByUserAt
    }
}

public struct RecoveryPacket: Identifiable, Codable, Hashable {
    public let id: UUID
    public var userId: String
    public var changeItemId: UUID
    public var classificationAtCreation: UserClassification
    public var status: PacketStatus
    public var createdAt: Date
    public var updatedAt: Date
    public var documents: [PacketDocument]
    public var itemName: String
    public var itemLast4: String?
    public var sourcePage: Int

    public init(
        id: UUID = UUID(),
        userId: String = "user_demo",
        changeItemId: UUID,
        classificationAtCreation: UserClassification,
        status: PacketStatus = .draft,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        documents: [PacketDocument] = [],
        itemName: String = "Credit Item",
        itemLast4: String? = nil,
        sourcePage: Int = 1
    ) {
        self.id = id
        self.userId = userId
        self.changeItemId = changeItemId
        self.classificationAtCreation = classificationAtCreation
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.documents = documents
        self.itemName = itemName
        self.itemLast4 = itemLast4
        self.sourcePage = sourcePage
    }
}
