import Atomics

extension Int {
    func clamp(lower: Int, upper: Int) -> Int {
        self < lower ? lower : (self > upper ? upper : self)
    }
}

extension Double {
    func clamp(lower: Double, upper: Double) -> Double {
        self < lower ? lower : (self > upper ? upper : self)
    }
}

class AtomicDouble: AtomicValue {
    typealias AtomicRepresentation = AtomicReferenceStorage<AtomicDouble>

    let value: Double

    init(_ value: Double = 0.0) {
        self.value = value
    }
}

class AtomicDoubleOptional: AtomicValue {
    typealias AtomicRepresentation = AtomicReferenceStorage<AtomicDoubleOptional>

    let value: Double?

    init(_ value: Double? = nil) {
        self.value = value
    }
}
