import Foundation

struct User: Codable, Equatable, Identifiable {
    let id: Int
    let email: String
    let createdAt: Date
    let updatedAt: Date
    /// Present once the backend ships `GET /auth/me` (letsraffle-api#59).
    var hasApple: Bool?

    enum CodingKeys: String, CodingKey {
        case id, email
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case hasApple = "has_apple"
    }
}

struct AuthTokens: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
}

/// `TokenResponse` from `/auth/login`, `/auth/register`, `/auth/refresh` (snake_case).
struct AuthResponse: Decodable, Equatable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let user: User

    var tokens: AuthTokens { AuthTokens(accessToken: accessToken, refreshToken: refreshToken) }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case user
    }
}

struct Credentials: Encodable {
    let email: String
    let password: String
}

struct RefreshRequest: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct ForgotPasswordRequest: Encodable {
    let email: String
    /// Backend email templates use lowercase language codes here.
    let language: String
}

struct MessageResponse: Decodable, Equatable {
    let message: String
}
