import Foundation

public struct LetterUserProfile: Equatable {
    public var fullName: String
    public var mailingAddress: String
    public var phone: String
    public var email: String

    public init(
        fullName: String = "",
        mailingAddress: String = "",
        phone: String = "",
        email: String = ""
    ) {
        self.fullName = fullName
        self.mailingAddress = mailingAddress
        self.phone = phone
        self.email = email
    }

    public var isComplete: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !mailingAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@")
    }
}
