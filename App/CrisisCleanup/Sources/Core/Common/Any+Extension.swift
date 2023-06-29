// From https://gist.github.com/claybridges/753c28b90e9a6c3cc55526617d9c53f2
@discardableResult
@inline(__always)
public func with<T>(_ item: T, _ closure: (inout T) -> Void) -> T {
    var mutableItem = item
    closure(&mutableItem)
    return mutableItem
}

@discardableResult
@inline(__always)
public func with<T>(_ item: T, _ closure: (inout T) async throws -> Void) async throws -> T {
    var mutableItem = item
    try await closure(&mutableItem)
    return mutableItem
}

@discardableResult
public func withLet<T>(_ item: Optional<T>, _ closure: (inout T) -> Void) -> Optional<T> {
  guard let item = item else { return nil }
  return with(item, closure)
}
