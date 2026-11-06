import Foundation

/// Async HTTP client for letsraffle-api.
///
/// Attaches the bearer token, transparently refreshes it once on a 401 and
/// retries the original request. Concurrent 401s share a single refresh call.
actor APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let tokenStore: TokenStore
    private var refreshTask: Task<AuthTokens, Error>?

    /// Called when the refresh token is rejected and the user must log in again.
    private var onSessionExpired: (@Sendable () -> Void)?

    init(baseURL: URL = AppConfig.apiBaseURL, session: URLSession = .shared, tokenStore: TokenStore) {
        self.baseURL = baseURL
        self.session = session
        self.tokenStore = tokenStore
    }

    func setSessionExpiredHandler(_ handler: @escaping @Sendable () -> Void) {
        onSessionExpired = handler
    }

    var isAuthenticated: Bool { tokenStore.tokens != nil }

    func storeTokens(_ tokens: AuthTokens?) {
        tokenStore.tokens = tokens
    }

    func send<Response: Decodable>(_ endpoint: Endpoint<Response>) async throws -> Response {
        let token = endpoint.auth == .none ? nil : tokenStore.tokens?.accessToken
        if endpoint.auth == .required && token == nil {
            throw APIError.unauthorized
        }

        let (data, response) = try await perform(endpoint, accessToken: token)

        if response.statusCode == 401, endpoint.auth != .none, token != nil {
            let refreshed = try await refreshTokens()
            let (retryData, retryResponse) = try await perform(endpoint, accessToken: refreshed.accessToken)
            return try decode(endpoint, data: retryData, response: retryResponse)
        }

        return try decode(endpoint, data: data, response: response)
    }

    // MARK: - Private

    private func perform<R>(_ endpoint: Endpoint<R>, accessToken: String?) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: baseURL.appending(path: endpoint.path))
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body = endpoint.body {
            request.httpBody = try JSONCoding.encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        endpoint.headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            return (data, http)
        } catch let error as APIError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw APIError.network
        }
    }

    private func decode<R: Decodable>(_ endpoint: Endpoint<R>, data: Data, response: HTTPURLResponse) throws -> R {
        guard (200..<300).contains(response.statusCode) else {
            throw APIError.from(status: response.statusCode, data: data)
        }
        if R.self == EmptyResponse.self, let empty = EmptyResponse() as? R {
            return empty
        }
        do {
            return try JSONCoding.decoder.decode(R.self, from: data)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }

    private func refreshTokens() async throws -> AuthTokens {
        if let refreshTask {
            return try await refreshTask.value
        }
        guard let refreshToken = tokenStore.tokens?.refreshToken else {
            expireSession()
            throw APIError.unauthorized
        }

        let task = Task { [baseURL, session] in
            let client = APIClient(baseURL: baseURL, session: session, tokenStore: InMemoryTokenStore())
            return try await client.send(API.refresh(token: refreshToken)).tokens
        }
        refreshTask = task
        defer { refreshTask = nil }

        do {
            let tokens = try await task.value
            tokenStore.tokens = tokens
            return tokens
        } catch {
            if case APIError.network = error { throw error }
            expireSession()
            throw APIError.unauthorized
        }
    }

    private func expireSession() {
        tokenStore.tokens = nil
        if let onSessionExpired {
            Task { @MainActor in onSessionExpired() }
        }
    }
}
