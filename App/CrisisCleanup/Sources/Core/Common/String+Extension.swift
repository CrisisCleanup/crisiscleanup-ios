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

    @inline(__always)
    func ifBlank(_ closure: () -> String?) -> String? {
        isBlank ? closure() : self
    }

    @inline(__always)
    func ifBlank(_ closure: () -> String) -> String {
        isBlank ? closure() : self
    }
}

extension Array where Element == Optional<String> {
    func filterNotBlankTrim() -> [String] {
        filter { $0?.isNotBlank == true }
            .map { $0!.trim() }
    }

    func combineTrimText(_ separator: String = ", ") -> String {
        filterNotBlankTrim()
            .joined(separator: separator)
    }
}
