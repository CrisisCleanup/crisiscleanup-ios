// From https://gist.github.com/claybridges/753c28b90e9a6c3cc55526617d9c53f2
@discardableResult
@inline(__always)
public func with<T>(_ item: T, _ closure: (inout T) -> Void) -> T {
    var mutableItem = item
    closure(&mutableItem)
    return mutableItem
}

@discardableResult
public func withLet<T>(_ item: Optional<T>, _ closure: (inout T) -> Void) -> Optional<T> {
  guard let item = item else { return nil }
  return with(item, closure)
}

extension Array {
    var firstOrNil: Element? { isEmpty ? nil : first }
    var isNotEmpty: Bool { !isEmpty }

    func associateBy<T>(_ transform: (Element) throws -> T) rethrows -> [T: Element] {
        return Dictionary(uniqueKeysWithValues: zip(
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
