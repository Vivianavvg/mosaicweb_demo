import Foundation

public enum MosaicAPIError: LocalizedError {
    case notConfigured
    case invalidURL
    case unauthorized
    case server(statusCode: Int)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Mosaic cloud sync is not configured for this build."
        case .invalidURL:
            return "Mosaic could not create the cloud sync URL."
        case .unauthorized:
            return "Mosaic cloud sync authorization expired. Please sign in again."
        case .server(let statusCode):
            return "Mosaic cloud sync failed with server status \(statusCode)."
        case .invalidResponse:
            return "Mosaic received an invalid cloud sync response."
        }
    }
}

/// Authenticated API client for the user's structured workspace state.
/// The client intentionally never uploads the original PDF bytes.
public final class MosaicAPIService {
    public static let shared = MosaicAPIService()

    private let session: URLSession
    private var accessToken: String?

    private init(session: URLSession = .shared) {
        self.session = session
    }

    public var isConfigured: Bool {
        !SecretsConfig.shared.mosaicAPIBaseURL.isEmpty && accessToken?.isEmpty == false
    }

    public func configure(accessToken: String?) {
        self.accessToken = accessToken
    }

    public func clearCredentials() {
        accessToken = nil
    }

    public func fetchWorkspace() async throws -> WorkspaceState? {
        let response: SyncResponse = try await request(path: "/v1/sync", method: "GET")
        return response.workspace
    }

    public func saveWorkspace(_ workspace: WorkspaceState) async throws {
        let _: SyncResponse = try await request(
            path: "/v1/sync",
            method: "PUT",
            body: SyncRequest(workspace: workspace)
        )
    }

    public func deleteWorkspace() async throws {
        let _: SyncResponse = try await request(path: "/v1/sync", method: "DELETE")
    }

    private struct SyncRequest: Encodable {
        let workspace: WorkspaceState
    }

    private struct SyncResponse: Decodable {
        let workspace: WorkspaceState?
        let updatedAt: Date?
    }

    private func request<Response: Decodable, Body: Encodable>(
        path: String,
        method: String,
        body: Body? = nil
    ) async throws -> Response {
        guard isConfigured else { throw MosaicAPIError.notConfigured }
        guard let url = URL(string: SecretsConfig.shared.mosaicAPIBaseURL + path) else {
            throw MosaicAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue("Bearer \(accessToken ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MosaicAPIError.invalidResponse
        }
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw MosaicAPIError.unauthorized
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw MosaicAPIError.server(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Response.self, from: data)
    }

    private func request<Response: Decodable>(
        path: String,
        method: String
    ) async throws -> Response {
        try await request(path: path, method: method, body: Optional<EmptyBody>.none)
    }

    private struct EmptyBody: Encodable {}
}
