import Foundation

/// A public, verified contact route for a report furnisher or creditor.
/// This never contains a user's report contents or personal identifiers.
public struct RecipientContact: Codable, Hashable, Identifiable {
    public let id: UUID
    public let issuerName: String
    public let email: String
    public let sourceURL: String
    public let sourceLabel: String
    public let verificationStatus: String
    public let verifiedAt: Date?

    public var isVerified: Bool {
        verificationStatus.lowercased() == "verified" && email.contains("@")
    }

    public init(
        id: UUID = UUID(),
        issuerName: String,
        email: String,
        sourceURL: String,
        sourceLabel: String,
        verificationStatus: String = "verified",
        verifiedAt: Date? = Date()
    ) {
        self.id = id
        self.issuerName = issuerName
        self.email = email
        self.sourceURL = sourceURL
        self.sourceLabel = sourceLabel
        self.verificationStatus = verificationStatus
        self.verifiedAt = verifiedAt
    }
}
