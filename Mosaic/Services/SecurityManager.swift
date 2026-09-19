import Foundation
import CryptoKit
import LocalAuthentication
import Security

public enum SecurityManagerError: LocalizedError {
    case keychain(OSStatus)
    case unableToCreateSecureDirectory
    case unableToCreateSealedBox
    case invalidEncryptedPDF

    public var errorDescription: String? {
        switch self {
        case .keychain(let status):
            return "Mosaic could not access its protected encryption key (Keychain status \(status))."
        case .unableToCreateSecureDirectory:
            return "Mosaic could not create its protected local storage area."
        case .unableToCreateSealedBox:
            return "Mosaic could not seal the imported PDF."
        case .invalidEncryptedPDF:
            return "Mosaic could not open the protected PDF copy."
        }
    }
}

public final class SecurityManager {
    public static let shared = SecurityManager()

    private let keychainService = "com.hackhers.mosaic.secure-pdf"
    private let keychainAccount = "pdf-encryption-key-v1"

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

    /// Encrypts PDF bytes into app-private, complete-file-protected storage.
    /// The original filename is intentionally not persisted; the encrypted copy uses a random name.
    /// This is local-at-rest protection, not production-grade end-to-end encryption.
    @discardableResult
    public func encryptPDF(_ data: Data, originalFilename: String? = nil) throws -> URL {
        _ = originalFilename
        let key = try loadOrCreatePDFKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw SecurityManagerError.unableToCreateSealedBox
        }

        let directoryURL = try securePDFDirectoryURL(createIfNeeded: true)
        let fileURL = directoryURL.appendingPathComponent("\(UUID().uuidString).mosaicpdf", isDirectory: false)
        try combined.write(to: fileURL, options: [.atomic, .completeFileProtection])
        try applyCompleteFileProtection(to: fileURL)
        excludeFromBackup(fileURL)
        return fileURL
    }

    /// Decrypts an encrypted local PDF for internal parsing only.
    public func decryptPDF(at url: URL) throws -> Data {
        let encryptedData = try Data(contentsOf: url, options: [.mappedIfSafe])
        let sealedBox: AES.GCM.SealedBox
        do {
            sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        } catch {
            throw SecurityManagerError.invalidEncryptedPDF
        }

        do {
            return try AES.GCM.open(sealedBox, using: loadOrCreatePDFKey())
        } catch {
            throw SecurityManagerError.invalidEncryptedPDF
        }
    }

    /// Best-effort emergency wipe for encrypted PDFs and the Keychain key used to open them.
    public func purgeEncryptedStore() {
        if let directoryURL = try? securePDFDirectoryURL(createIfNeeded: false) {
            try? FileManager.default.removeItem(at: directoryURL)
        }
        deletePDFKey()
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
        for directoryName in ["mosaic_imports", "mosaic_packets"] {
            let tempDir = fm.temporaryDirectory.appendingPathComponent(directoryName, isDirectory: true)
            try? fm.removeItem(at: tempDir)
        }
    }

    private func securePDFDirectoryURL(createIfNeeded: Bool) throws -> URL {
        let fm = FileManager.default
        guard let applicationSupportURL = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw SecurityManagerError.unableToCreateSecureDirectory
        }

        let directoryURL = applicationSupportURL.appendingPathComponent("MosaicSecure", isDirectory: true)
        if createIfNeeded {
            try fm.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try fm.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: directoryURL.path)
            excludeFromBackup(directoryURL)
        }
        return directoryURL
    }

    private func applyCompleteFileProtection(to url: URL) throws {
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )
    }

    private func excludeFromBackup(_ url: URL) {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = url
        try? mutableURL.setResourceValues(values)
    }

    private func loadOrCreatePDFKey() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let keyData = result as? Data {
            return SymmetricKey(data: keyData)
        }
        guard status == errSecItemNotFound else {
            throw SecurityManagerError.keychain(status)
        }

        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: keyData
        ]

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess || addStatus == errSecDuplicateItem else {
            throw SecurityManagerError.keychain(addStatus)
        }

        if addStatus == errSecDuplicateItem {
            return try loadOrCreatePDFKey()
        }
        return key
    }

    private func deletePDFKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Mosaic could not delete the PDF encryption key: Keychain status \(status)")
        }
    }
}
