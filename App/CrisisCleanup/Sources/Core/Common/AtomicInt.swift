import Atomics

class AtomicInt {
    private let storage = ManagedAtomic(0)

    init(_ initialValue: Int = 0) {
        set(initialValue)
    }

    var value: Int {
        storage.load(ordering: .relaxed)
    }

    func set(_ newValue: Int) {
        storage.store(newValue, ordering: .relaxed)
    }

    func get() -> Int {
        value
    }

    func incrementAndGet() -> Int {
        storage.wrappingIncrementThenLoad(ordering: .relaxed)
    }

    func decrementAndGet() -> Int {
        storage.wrappingDecrementThenLoad(ordering: .relaxed)
    }

    func getAndIncrement() -> Int {
        storage.loadThenWrappingIncrement(ordering: .relaxed)
    }
}
