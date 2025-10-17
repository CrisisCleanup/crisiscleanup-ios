import Foundation

struct LockingValue<T> {
    private var value: T

    private let lock = NSRecursiveLock()

    init(_ value: T) {
        self.value = value
    }

    func get() -> T {
        return lock.withLock {
            return value
        }
    }

    mutating func getAndSet(to t: T) -> T {
        return lock.withLock {
            let prev = value
            value = t
            return prev
        }
    }

    mutating func set(to t: T) {
        lock.withLock {
            value = t
        }
    }
}

struct LockingBool {
    private var l = LockingValue(false)

    func get() -> Bool {
        l.get()
    }

    mutating func getAndSet(to b: Bool) -> Bool {
        l.getAndSet(to: b)
    }

    mutating func set(to b: Bool) {
        l.set(to: b)
    }
}
