import Foundation

public enum StorageMode: String, Codable, CaseIterable {
    case localOnly = "local_only"
    case redactedStructured = "redacted_structured"
}

public struct ReportSnapshot: Identifiable, Codable, Hashable {
    public let id: UUID
    public var userId: String
    public var localFingerprint: String
    public var reportDate: Date?
    public var importedAt: Date
    public var pageCount: Int
    public var storageMode: StorageMode
    public var isSynthetic: Bool
    public var accounts: [ReportAccount]
    public var inquiries: [ReportInquiry]
    public var addresses: [ReportAddress]

    public init(
        id: UUID = UUID(),
        userId: String = "user_demo",
        localFingerprint: String,
        reportDate: Date? = nil,
        importedAt: Date = Date(),
        pageCount: Int = 1,
        storageMode: StorageMode = .localOnly,
        isSynthetic: Bool = false,
        accounts: [ReportAccount] = [],
        inquiries: [ReportInquiry] = [],
        addresses: [ReportAddress] = []
    ) {
        self.id = id
        self.userId = userId
        self.localFingerprint = localFingerprint
        self.reportDate = reportDate
        self.importedAt = importedAt
        self.pageCount = pageCount
        self.storageMode = storageMode
        self.isSynthetic = isSynthetic
        self.accounts = accounts
        self.inquiries = inquiries
        self.addresses = addresses
    }
}

public struct ReportAccount: Identifiable, Codable, Hashable {
    public let id: UUID
    public var snapshotId: UUID
    public var issuerName: String
    public var accountLast4: String
    public var accountType: String
    public var openedDate: String?
    public var balanceCents: Int?
    public var status: String
    public var paymentStatus: String?
    public var jointIndicator: Bool
    public var sourcePage: Int
    public var extractionConfidence: Double
    public var localFingerprint: String

    public var formattedBalance: String {
        guard let cents = balanceCents else { return "N/A" }
        let dollars = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: dollars)) ?? "$\(dollars)"
    }

    public init(
        id: UUID = UUID(),
        snapshotId: UUID = UUID(),
        issuerName: String,
        accountLast4: String,
        accountType: String,
        openedDate: String? = nil,
        balanceCents: Int? = nil,
        status: String = "open",
        paymentStatus: String? = "Current",
        jointIndicator: Bool = false,
        sourcePage: Int = 1,
        extractionConfidence: Double = 0.95,
        localFingerprint: String = ""
    ) {
        self.id = id
        self.snapshotId = snapshotId
        self.issuerName = issuerName
        self.accountLast4 = accountLast4
        self.accountType = accountType
        self.openedDate = openedDate
        self.balanceCents = balanceCents
        self.status = status
        self.paymentStatus = paymentStatus
        self.jointIndicator = jointIndicator
        self.sourcePage = sourcePage
        self.extractionConfidence = extractionConfidence
        self.localFingerprint = localFingerprint.isEmpty ? "\(issuerName)_\(accountLast4)" : localFingerprint
    }
}

public struct ReportInquiry: Identifiable, Codable, Hashable {
    public let id: UUID
    public var snapshotId: UUID
    public var inquirerName: String
    public var inquiryDate: String?
    public var sourcePage: Int
    public var extractionConfidence: Double

    public init(
        id: UUID = UUID(),
        snapshotId: UUID = UUID(),
        inquirerName: String,
        inquiryDate: String? = nil,
        sourcePage: Int = 1,
        extractionConfidence: Double = 0.95
    ) {
        self.id = id
        self.snapshotId = snapshotId
        self.inquirerName = inquirerName
        self.inquiryDate = inquiryDate
        self.sourcePage = sourcePage
        self.extractionConfidence = extractionConfidence
    }
}

public struct ReportAddress: Identifiable, Codable, Hashable {
    public let id: UUID
    public var snapshotId: UUID
    public var redactedAddressLabel: String
    public var addressHash: String
    public var reportedDate: String?
    public var sourcePage: Int

    public init(
        id: UUID = UUID(),
        snapshotId: UUID = UUID(),
        redactedAddressLabel: String,
        addressHash: String = "",
        reportedDate: String? = nil,
        sourcePage: Int = 1
    ) {
        self.id = id
        self.snapshotId = snapshotId
        self.redactedAddressLabel = redactedAddressLabel
        self.addressHash = addressHash.isEmpty ? UUID().uuidString : addressHash
        self.reportedDate = reportedDate
        self.sourcePage = sourcePage
    }
}
