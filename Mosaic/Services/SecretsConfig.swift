import Foundation

/// Centralized configuration for sponsor API credentials.
/// Reads from ProcessInfo environment variables first, then looks for a local uncommitted `Secrets.plist` in the app bundle.
public struct SecretsConfig {
    public static let shared = SecretsConfig()

    public let geminiApiKey: String
    public let backboardApiKey: String

    public init() {
        var gemini = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""
        var backboard = ProcessInfo.processInfo.environment["BACKBOARD_API_KEY"] ?? ""

        // Load from local Secrets.plist if present in the main bundle
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
            if gemini.isEmpty, let val = dict["GEMINI_API_KEY"] as? String, !val.isEmpty, !val.hasPrefix("YOUR_") {
                gemini = val
            }
            if backboard.isEmpty, let val = dict["BACKBOARD_API_KEY"] as? String, !val.isEmpty, !val.hasPrefix("YOUR_") {
                backboard = val
            }
        }

        self.geminiApiKey = gemini
        self.backboardApiKey = backboard
    }
}
