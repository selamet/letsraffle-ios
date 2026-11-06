import Foundation

enum HTTPMethod: String {
    case get = "GET", post = "POST", put = "PUT", delete = "DELETE"
}

enum AuthRequirement {
    /// No `Authorization` header.
    case none
    /// Sends the token when available (e.g. manual draw can be created as guest).
    case optional
    /// Requires a token; a 401 triggers a single refresh + retry.
    case required
}

/// Marker for endpoints that return no body (204).
struct EmptyResponse: Decodable, Equatable {}

struct Endpoint<Response: Decodable> {
    var method: HTTPMethod
    var path: String
    var body: (any Encodable)?
    var auth: AuthRequirement = .none
    var headers: [String: String] = [:]
}

/// Catalog of letsraffle-api v1 endpoints.
enum API {
    // MARK: Auth

    static func login(email: String, password: String) -> Endpoint<AuthResponse> {
        Endpoint(method: .post, path: "auth/login", body: Credentials(email: email, password: password))
    }

    static func register(email: String, password: String) -> Endpoint<AuthResponse> {
        Endpoint(method: .post, path: "auth/register", body: Credentials(email: email, password: password))
    }

    static func signInWithApple(_ credential: AppleCredential) -> Endpoint<AuthResponse> {
        Endpoint(
            method: .post,
            path: "auth/apple",
            body: AppleSignInRequest(identityToken: credential.identityToken, firstName: credential.firstName, lastName: credential.lastName)
        )
    }

    static func refresh(token: String) -> Endpoint<AuthResponse> {
        Endpoint(method: .post, path: "auth/refresh", body: RefreshRequest(refreshToken: token))
    }

    static func forgotPassword(email: String, language: AppLanguage) -> Endpoint<MessageResponse> {
        Endpoint(
            method: .post,
            path: "auth/forgot-password",
            body: ForgotPasswordRequest(email: email, language: language.rawValue.lowercased())
        )
    }

    static func me() -> Endpoint<User> {
        Endpoint(method: .get, path: "auth/me", auth: .required)
    }

    static func deleteAccount() -> Endpoint<EmptyResponse> {
        Endpoint(method: .delete, path: "auth/me", auth: .required)
    }

    // MARK: Draws (organizer)

    static func draws() -> Endpoint<[DrawListItem]> {
        Endpoint(method: .get, path: "draws", auth: .required)
    }

    static func drawDetail(inviteCode: String) -> Endpoint<DrawDetail> {
        Endpoint(method: .get, path: "draws/\(inviteCode.urlPathEncoded)", auth: .required)
    }

    static func createManualDraw(_ request: ManualDrawRequest) -> Endpoint<ManualDrawResponse> {
        Endpoint(method: .post, path: "draws/manual", body: request, auth: .optional)
    }

    static func createDynamicDraw(_ request: DynamicDrawRequest) -> Endpoint<DynamicDrawResponse> {
        Endpoint(method: .post, path: "draws/dynamic", body: request, auth: .required)
    }

    static func deleteParticipant(drawId: Int, participantId: Int) -> Endpoint<EmptyResponse> {
        Endpoint(method: .delete, path: "draws/\(drawId)/participants/\(participantId)", auth: .required)
    }

    static func updateSchedule(drawId: Int, date: Date?) -> Endpoint<UpdateScheduleResponse> {
        Endpoint(method: .put, path: "draws/\(drawId)/schedule", body: UpdateScheduleRequest(drawDate: date), auth: .required)
    }

    static func executeDraw(drawId: Int) -> Endpoint<ExecuteDrawResponse> {
        Endpoint(method: .post, path: "draws/\(drawId)/execute", auth: .required)
    }

    // MARK: Results

    static func participantResult(token: String) -> Endpoint<MatchResult> {
        Endpoint(method: .get, path: "participants/me/result", headers: ["X-Participant-Token": token])
    }

    static func organizerResult(inviteCode: String) -> Endpoint<MatchResult> {
        Endpoint(method: .get, path: "draws/\(inviteCode.urlPathEncoded)/my-result", auth: .required)
    }

    // MARK: Devices (push)

    static func registerDevice(_ registration: DeviceRegistration) -> Endpoint<DeviceRegistrationResponse> {
        Endpoint(method: .post, path: "devices", body: registration, auth: .optional)
    }

    static func unregisterDevice(token: String) -> Endpoint<EmptyResponse> {
        Endpoint(method: .delete, path: "devices/\(token.urlPathEncoded)")
    }

    // MARK: Join (public)

    static func publicDraw(inviteCode: String) -> Endpoint<DrawPublicInfo> {
        Endpoint(method: .get, path: "draws/join/\(inviteCode.urlPathEncoded)")
    }

    static func joinDraw(inviteCode: String, participant: ParticipantInput) -> Endpoint<JoinDrawResponse> {
        Endpoint(method: .post, path: "draws/join/\(inviteCode.urlPathEncoded)", body: participant)
    }
}

private extension String {
    var urlPathEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))) ?? self
    }
}
