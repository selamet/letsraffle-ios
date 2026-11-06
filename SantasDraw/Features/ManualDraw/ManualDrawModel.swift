import Foundation
import Observation

/// Local state for a manual draw before it is submitted.
@MainActor
@Observable
final class ManualDrawModel {
    static let minimumParticipants = 3

    var participants: [ParticipantInput] = []
    var requireAddress = false
    var requirePhone = false
    var isSubmitting = false
    var submitError: String?
    var completedDrawId: Int?

    /// Participants that miss a field made mandatory after they were added.
    func isIncomplete(_ p: ParticipantInput) -> Bool {
        (requireAddress && (p.address ?? "").trimmed.isEmpty) || (requirePhone && (p.phone ?? "").trimmed.isEmpty)
    }

    var canRun: Bool {
        participants.count >= Self.minimumParticipants && !participants.contains(where: isIncomplete) && !isSubmitting
    }

    /// Returns a validation error message for the add/edit sheet, if any.
    func error(for candidate: ParticipantInput, editing id: UUID?, _ t: Strings) -> [ParticipantField: String] {
        var errors: [ParticipantField: String] = [:]
        if let e = Validation.requiredError(candidate.firstName, t) { errors[.firstName] = e }
        if let e = Validation.requiredError(candidate.lastName, t) { errors[.lastName] = e }
        if let e = Validation.emailError(candidate.email, t) {
            errors[.email] = e
        } else if participants.contains(where: { $0.id != id && $0.email.lowercased() == candidate.email.trimmed.lowercased() }) {
            errors[.email] = t.duplicateEmail
        }
        if requireAddress, let e = Validation.requiredError(candidate.address, t) { errors[.address] = e }
        if requirePhone, let e = Validation.requiredError(candidate.phone, t) { errors[.phone] = e }
        return errors
    }

    func upsert(_ candidate: ParticipantInput) {
        var clean = candidate
        clean.firstName = candidate.firstName.trimmed
        clean.lastName = candidate.lastName.trimmed
        clean.email = candidate.email.trimmed.lowercased()
        clean.address = candidate.address?.trimmed.nilIfEmpty
        clean.phone = candidate.phone?.trimmed.nilIfEmpty
        if let index = participants.firstIndex(where: { $0.id == candidate.id }) {
            participants[index] = clean
        } else {
            participants.append(clean)
        }
    }

    func remove(_ id: UUID) {
        participants.removeAll { $0.id == id }
    }

    func makeRequest(language: AppLanguage) -> ManualDrawRequest {
        ManualDrawRequest(
            addressRequired: requireAddress,
            phoneNumberRequired: requirePhone,
            language: language.rawValue,
            participants: participants
        )
    }

    func submit(api: APIClient, language: AppLanguage, _ t: Strings) async {
        guard canRun else { return }
        isSubmitting = true
        submitError = nil
        defer { isSubmitting = false }
        do {
            let response = try await api.send(API.createManualDraw(makeRequest(language: language)))
            completedDrawId = response.drawId
        } catch {
            submitError = error.userMessage(t)
        }
    }
}

enum ParticipantField: Hashable {
    case firstName, lastName, email, address, phone
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
