import Foundation

extension String {
    var isBlank: Bool { allSatisfy({ $0.isWhitespace }) }
    var isNotBlank: Bool { !isBlank }

    var toDate: Date {
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter.date(from:self)!
    }

    func trim() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
