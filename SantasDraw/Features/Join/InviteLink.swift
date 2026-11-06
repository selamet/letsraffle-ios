import Foundation

/// Extracts an invite code from user input, QR payloads and deep links.
///
/// Accepted forms:
/// - `jolly-reindeer-742`
/// - `https://letsraffle.com/draw/join/jolly-reindeer-742` (web route, QR content)
/// - `letsraffle://join/jolly-reindeer-742` (custom scheme)
enum InviteLink {
    static let scheme = "letsraffle"

    static func code(from raw: String) -> String? {
        let input = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return nil }

        if input.contains("/"), let url = URL(string: input), url.scheme != nil {
            return code(from: url)
        }
        return sanitize(input)
    }

    static func code(from url: URL) -> String? {
        let parts = url.pathComponents.filter { $0 != "/" }
        if url.scheme == scheme {
            // letsraffle://join/<code> → host "join", path "/<code>"
            if url.host == "join" { return parts.first.flatMap(sanitize) }
            if parts.first == "join" { return parts.dropFirst().first.flatMap(sanitize) }
            return nil
        }
        guard url.scheme == "https" || url.scheme == "http" else { return nil }
        if let index = parts.firstIndex(of: "join"), index + 1 < parts.count, index > 0, parts[index - 1] == "draw" {
            return sanitize(parts[index + 1])
        }
        return nil
    }

    static func deepLink(for code: String) -> URL {
        URL(string: "\(scheme)://join/\(code)")!
    }

    /// Codes are lowercase words, digits and dashes (e.g. `merry-elf-100`).
    private static func sanitize(_ value: String) -> String? {
        let lowered = value.lowercased()
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        guard lowered.count <= 64, lowered.unicodeScalars.allSatisfy(allowed.contains) else { return nil }
        return lowered
    }
}
