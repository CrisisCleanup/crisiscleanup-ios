import Foundation

private let relativeTimeFormatter = RelativeDateTimeFormatter()

extension Date {
    var relativeTime: String {
        relativeTimeFormatter.localizedString(for: self, relativeTo: Date.now)
    }
}

extension DateFormatter {
    func format(_ format: String) -> Self {
        dateFormat = format
        return self
    }

    func utcTimeZone() -> Self {
        timeZone = TimeZone(abbreviation: "UTC")
        return self
    }
}
