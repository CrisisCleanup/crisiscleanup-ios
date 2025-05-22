import Foundation

private let relativeTimeFormatter = RelativeDateTimeFormatter()

extension Date {
    static var epochZero: Date {
        Date(timeIntervalSince1970: 0)
    }

    var relativeTime: String {
        relativeTimeFormatter.localizedString(for: self, relativeTo: Date.now)
    }

    var isPast: Bool {
        self < Date.now
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
