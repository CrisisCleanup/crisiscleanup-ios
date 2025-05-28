import Atomics

class AtomicInt {
    private let storage = ManagedAtomic<Int>(0)

    init(_ initialValue: Int = 0) {
        storage.store(initialValue, ordering: .relaxed)
    }

    var value: Int {
        return storage.load(ordering: .relaxed)
    }

    func set(_ newValue: Int) {
        storage.store(newValue, ordering: .relaxed)
    }

    func get() -> Int {
        return storage.load(ordering: .relaxed)
    }

    func incrementAndGet() -> Int {
        return storage.loadThenWrappingIncrement(ordering: .relaxed) + 1
    }

    func decrementAndGet() -> Int {
        return storage.loadThenWrappingDecrement(ordering: .relaxed) - 1
    }
}
