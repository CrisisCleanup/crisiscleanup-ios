extension Array {
    var firstOrNil: Element? { isEmpty ? nil : first }
    var isNotEmpty: Bool { !isEmpty }

    func associateBy<T>(_ transform: (Element) throws -> T) rethrows -> [T: Element] {
        var dictionary = [T: Element]()
        try forEach {
            let key = try transform($0)
            dictionary[key] = $0
        }
        return dictionary
    }

    func associate<Key, Value>(_ transform: (Element) throws -> (Key, Value)) rethrows -> [Key: Value] {
        var dictionary = [Key: Value]()
        try forEach {
            let (key, value) = try transform($0)
            dictionary[key] = value
        }
        return dictionary
    }

    /**
     * - Returns (trueys, falseys)
     */
    func split(_ predicate: (Element) -> Bool) -> ([Element], [Element]) {
        var trueBucket: [Element] = []
        var falseBucket: [Element] = []
        forEach {
            if predicate($0) {
                trueBucket.append($0)
            } else {
                falseBucket.append($0)
            }
        }
        return (trueBucket, falseBucket)
    }
}

extension [String] {
    var commaJoined: String { joined(separator: ",") }
}
