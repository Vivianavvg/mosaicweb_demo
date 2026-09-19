import Foundation

public final class RedactionEngine {
    public static let shared = RedactionEngine()

    private init() {}

    /// Redacts all sensitive personal identifiers before any processing or network transmission
    public func redactText(_ text: String) -> String {
        var result = text

        // 1. Redact SSN: 000-00-0000 or 000000000
        result = result.replacingOccurrences(
            of: #"\b\d{3}[- ]?\d{2}[- ]?\d{4}\b"#,
            with: "[SSN REDACTED]",
            options: .regularExpression
        )

        // 2. Redact long account numbers (12 to 19 digits), leaving last 4 digits
        if let regex = try? NSRegularExpression(pattern: #"\b(?:\d[ -]?){11,18}(\d{4})\b"#) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(
                in: result,
                options: [],
                range: range,
                withTemplate: "**** $1"
            )
        }

        // 3. Redact Phone numbers
        result = result.replacingOccurrences(
            of: #"\b(?:\+?1[-. ]?)?\(?\d{3}\)?[-. ]?\d{3}[-. ]?\d{4}\b"#,
            with: "[PHONE REDACTED]",
            options: .regularExpression
        )

        // 4. Redact Email addresses
        result = result.replacingOccurrences(
            of: #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}"#,
            with: "[EMAIL REDACTED]",
            options: .regularExpression
        )

        // 5. Redact Date of Birth
        result = result.replacingOccurrences(
            of: #"(?i)(?:DOB|Date of Birth|Birth Date)[:\s]+(?:\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\w+\s+\d{1,2},?\s+\d{4})"#,
            with: "DOB: [DOB REDACTED]",
            options: .regularExpression
        )

        // 6. Redact Street Address prefixes (keep city/state if available)
        result = result.replacingOccurrences(
            of: #"\b\d{1,5}\s+[A-Za-z0-9\., ]+(?:Street|St|Avenue|Ave|Boulevard|Blvd|Road|Rd|Drive|Dr|Lane|Ln|Court|Ct|Way)\b"#,
            with: "[STREET REDACTED]",
            options: .regularExpression
        )

        return result
    }

    /// Masks an account number safely to only its last 4 digits
    public func maskAccount(_ accountString: String) -> String {
        let digits = accountString.filter { $0.isNumber }
        if digits.count >= 4 {
            let last4 = String(digits.suffix(4))
            return "**** \(last4)"
        } else if !digits.isEmpty {
            return "**** \(digits)"
        }
        return "**** 0000"
    }
}
