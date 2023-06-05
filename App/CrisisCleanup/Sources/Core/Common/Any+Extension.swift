// From https://gist.github.com/claybridges/753c28b90e9a6c3cc55526617d9c53f2
@discardableResult
@inline(__always)
public func with<T>(_ item: T, _ closure: (inout T) -> Void) -> T {
    var mutableItem = item
    closure(&mutableItem)
    return mutableItem
}

extension Array {
    var firstOrNil: Element? { isEmpty ? nil : first }
    var isNotEmpty: Bool { !isEmpty }
}
