import Foundation

private let relativeTimeFormatter = RelativeDateTimeFormatter()

extension Date {
    var relativeTime: String {
        relativeTimeFormatter.localizedString(for: self, relativeTo: Date.now)
    }
}
