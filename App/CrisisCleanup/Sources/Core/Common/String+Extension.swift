extension String {
    var isBlank: Bool { allSatisfy({ $0.isWhitespace }) }
}
