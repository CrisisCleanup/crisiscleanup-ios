extension Array {
    var firstOrNil: Element? { isEmpty ? nil : first }
    var isNotEmpty: Bool { !isEmpty }

    func associateBy<T>(_ transform: (Element) throws -> T) rethrows -> [T: Element] {
        Dictionary(uniqueKeysWithValues: zip(
            try map(transform),
            self
        ))
    }

    func associate<Key, Value>(_ transform: (Element) throws -> (Key, Value)) rethrows -> [Key: Value] {
        var keys: [Key] = []
        var values: [Value] = []
        try forEach {
            let (key, value) = try transform($0)
            keys.append(key)
            values.append(value)
        }
        return Dictionary(uniqueKeysWithValues: zip(keys, values))
    }
}

extension [String] {
    var commaJoined: String { joined(separator: ",") }
}
