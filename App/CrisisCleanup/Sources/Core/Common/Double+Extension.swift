
private let degreesPerRadian = 180 / Double.pi
extension Double {
    var degrees: Double { self * degreesPerRadian }
}

private let oneRadian = Double.pi / 180
extension Double {
    var radians: Double { self * oneRadian }
}

extension Double {
    var kmToMiles: Double { self * 0.621371 }
    var milesToMeters: Double { self * 1609.344 }
}
