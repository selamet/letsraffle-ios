import Foundation

enum JSONCoding {
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            guard let date = APIDate.parse(raw) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported date: \(raw)")
            }
            return date
        }
        return decoder
    }()

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(APIDate.format(date))
        }
        return encoder
    }()
}

/// Date handling for the FastAPI backend.
///
/// The API returns ISO-8601 strings with microsecond precision and either a `Z`
/// or `+00:00` suffix (e.g. `2026-11-05T14:47:12.123456+00:00`). Naive values
/// without an offset are treated as UTC. Outgoing dates always carry an explicit
/// offset so the backend does not apply its language-based timezone guess.
enum APIDate {
    private static let withFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let plain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func parse(_ raw: String) -> Date? {
        var value = raw.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "T")

        // Trim fractional seconds to milliseconds; ISO8601DateFormatter rejects 6 digits.
        if let dot = value.firstIndex(of: ".") {
            let fractionStart = value.index(after: dot)
            let fractionEnd = value[fractionStart...].firstIndex { !$0.isNumber } ?? value.endIndex
            let digits = value[fractionStart..<fractionEnd]
            let millis = String(digits.prefix(3)).padding(toLength: 3, withPad: "0", startingAt: 0)
            value.replaceSubrange(fractionStart..<fractionEnd, with: millis)
        }

        // Naive timestamps are UTC.
        let timePart = value.split(separator: "T").last ?? ""
        if !value.hasSuffix("Z") && !timePart.contains("+") && !timePart.contains("-") {
            value += "Z"
        }

        return withFraction.date(from: value) ?? plain.date(from: value)
    }

    static func format(_ date: Date) -> String {
        plain.string(from: date)
    }
}
