import Foundation

enum APIError: Error, Equatable {
    /// Non-2xx response. `detail` is the FastAPI error message when available.
    case server(status: Int, detail: String?)
    case unauthorized
    case network
    case decoding(String)
    case invalidResponse

    var status: Int? {
        switch self {
        case let .server(status, _): status
        case .unauthorized: 401
        default: nil
        }
    }

    /// Message suitable for showing to the user.
    func message(_ t: Strings) -> String {
        switch self {
        case let .server(_, detail?) where !detail.isEmpty: detail
        case .unauthorized: t.sessionExpired
        case .network: t.networkError
        default: t.genericError
        }
    }

    /// Builds an error from a FastAPI error body.
    ///
    /// FastAPI returns either `{"detail": "message"}` or, for validation errors,
    /// `{"detail": [{"loc": [...], "msg": "...", "type": "..."}]}`.
    static func from(status: Int, data: Data) -> APIError {
        if status == 401 { return .unauthorized }
        return .server(status: status, detail: detailMessage(from: data))
    }

    static func detailMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let detail = object["detail"] as? String { return detail }
        if let items = object["detail"] as? [[String: Any]] {
            let messages = items.compactMap { $0["msg"] as? String }.map(cleanValidationMessage)
            return messages.isEmpty ? nil : messages.joined(separator: "\n")
        }
        return nil
    }

    private static func cleanValidationMessage(_ message: String) -> String {
        let prefix = "Value error, "
        return message.hasPrefix(prefix) ? String(message.dropFirst(prefix.count)) : message
    }
}

extension Error {
    /// Maps any error to a user-facing message.
    func userMessage(_ t: Strings) -> String {
        if let api = self as? APIError { return api.message(t) }
        if self is URLError { return t.networkError }
        return t.genericError
    }
}
