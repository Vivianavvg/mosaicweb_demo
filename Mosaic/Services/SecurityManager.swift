import Foundation
import CryptoKit
import LocalAuthentication

public final class SecurityManager {
    public static let shared = SecurityManager()

    private init() {}

    /// Computes local SHA-256 fingerprint of data or file
    public func sha256(for data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Authenticates with Face ID, Touch ID, or Device Passcode
    public func authenticateUser(reason: String = "Authenticate to unlock Mosaic", completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, evalError in
                DispatchQueue.main.async {
                    completion(success, evalError)
                }
            }
        } else {
            // Biometrics/passcode not configured or available
            DispatchQueue.main.async {
                completion(true, nil)
            }
        }
    }

    /// Safely copies a file from security-scoped URL to temporary sandbox
    public func copyToSandbox(from sourceURL: URL) throws -> URL {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent("mosaic_imports", isDirectory: true)
        if !fm.fileExists(atPath: tempDir.path) {
            try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        }

        let destinationURL = tempDir.appendingPathComponent(UUID().uuidString + "_" + sourceURL.lastPathComponent)
        if fm.fileExists(atPath: destinationURL.path) {
            try fm.removeItem(at: destinationURL)
        }

        _ = sourceURL.startAccessingSecurityScopedResource()
        defer { sourceURL.stopAccessingSecurityScopedResource() }

        try fm.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }

    /// Securely deletes all temporary files in the sandbox container
    public func purgeTemporaryFiles() {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent("mosaic_imports", isDirectory: true)
        try? fm.removeItem(at: tempDir)
    }
}
