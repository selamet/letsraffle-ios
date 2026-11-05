import Foundation

enum DrawType: String, Codable {
    case manual
    case dynamic
}

enum DrawStatus: String, Codable {
    case active
    case inProgress = "in_progress"
    case completed
    case cancelled
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = DrawStatus(rawValue: raw) ?? .unknown
    }
}

/// Item of `GET /draws` (camelCase aliases).
struct DrawListItem: Decodable, Identifiable, Equatable, Hashable {
    let id: Int
    let drawType: DrawType
    let status: DrawStatus
    let inviteCode: String?
    let participantCount: Int
    let createdAt: Date
    let drawDate: Date?
    let language: String
}

struct Participant: Decodable, Identifiable, Equatable, Hashable {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String
    let address: String?
    let phone: String?
    let createdAt: Date

    var fullName: String { "\(firstName) \(lastName)" }
}

/// `GET /draws/{invite_code}` (organizer only).
struct DrawDetail: Decodable, Identifiable, Equatable {
    let id: Int
    let drawType: DrawType
    let status: DrawStatus
    let inviteCode: String?
    let requireAddress: Bool
    let requirePhone: Bool
    let drawDate: Date?
    let createdAt: Date
    let language: String
    let participants: [Participant]
}

/// `GET /draws/join/{invite_code}` (public).
struct DrawPublicInfo: Decodable, Identifiable, Equatable {
    let id: Int
    let requireAddress: Bool
    let requirePhone: Bool
    let drawDate: Date?
    let status: DrawStatus
    let participantCount: Int
    let language: String
    /// Added by letsraffle-api#58; optional for backward compatibility.
    let organizerName: String?
}

/// Participant payload shared by manual/dynamic create and join requests.
struct ParticipantInput: Codable, Equatable, Hashable, Identifiable {
    var id = UUID()
    var firstName: String
    var lastName: String
    var email: String
    var address: String?
    var phone: String?

    var fullName: String { "\(firstName) \(lastName)" }

    enum CodingKeys: String, CodingKey {
        case firstName, lastName, email, address, phone
    }
}

struct ManualDrawRequest: Encodable {
    let addressRequired: Bool
    let phoneNumberRequired: Bool
    let language: String
    let participants: [ParticipantInput]
}

struct DynamicDrawRequest: Encodable {
    let addressRequired: Bool
    let phoneNumberRequired: Bool
    let language: String
    let drawDate: Date?
    /// Exactly one participant: the organizer.
    let participants: [ParticipantInput]
}

struct ManualDrawResponse: Decodable, Equatable {
    let success: Bool
    let message: String
    let drawId: Int
}

struct DynamicDrawResponse: Decodable, Equatable {
    let success: Bool
    let message: String
    let drawId: Int
    let inviteCode: String
    /// Added by letsraffle-api#60.
    let participantToken: String?
}

struct JoinDrawResponse: Decodable, Equatable {
    let success: Bool
    let message: String
    let participantId: Int
    let drawId: Int
    /// Added by letsraffle-api#60.
    let participantToken: String?
}

struct UpdateScheduleRequest: Encodable {
    let drawDate: Date?
}

struct UpdateScheduleResponse: Decodable, Equatable {
    let success: Bool
    let message: String
    let drawDate: Date?
}

struct ExecuteDrawResponse: Decodable, Equatable {
    let success: Bool
    let message: String
}
