import Atomics
import Foundation

extension String {
    var isBlank: Bool { allSatisfy({ $0.isWhitespace }) }
    public var isNotBlank: Bool { !isBlank }

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

    private func range(_ start: Int, _ end: Int) -> Range<String.Index> {
        index(startIndex, offsetBy: start)..<index(startIndex, offsetBy: end)
    }

    func substring(_ start: Int, _ end: Int) -> String {
        let s = self[range(start, end)]
        return String(s)
    }
}

extension Array where Element == Optional<String> {
    func filterNotBlankTrim() -> [String] {
        filter { $0?.isNotBlank == true }
            .map { $0!.trim() }
    }

    public func combineTrimText(_ separator: String = ", ") -> String {
        filterNotBlankTrim()
            .joined(separator: separator)
    }
}

extension Array where Element == String {
    func filterNotBlankTrim() -> [String] {
        filter { $0.isNotBlank == true }
            .map { $0.trim() }
    }

    public func combineTrimText(_ separator: String = ", ") -> String {
        filterNotBlankTrim()
            .joined(separator: separator)
    }
}

class AtomicString: AtomicValue {
    typealias AtomicRepresentation = AtomicReferenceStorage<AtomicString>

    let value: String

    init(_ value: String = "") {
        self.value = value
    }
}
