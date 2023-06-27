
private let degreesPerRadian = 180 / Double.pi
extension Double {
    var degrees: Double { self * degreesPerRadian }
}

private let oneRadian = Double.pi / 180
extension Double {
    var radians: Double { self * oneRadian }
}
