import Foundation

enum DateParsing {
    private static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func parse(_ value: String) -> Date {
        if let parsed = iso8601WithFractional.date(from: value) {
            return parsed
        }
        return iso8601.date(from: value) ?? .distantPast
    }

    static func humanReadable(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}
