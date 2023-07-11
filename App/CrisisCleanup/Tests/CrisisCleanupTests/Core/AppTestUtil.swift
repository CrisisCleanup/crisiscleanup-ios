import Foundation
import XCTest
@testable import CrisisCleanup

var dateNowRoundedSeconds: Date {
    let seconds = Date.now.timeIntervalSince1970.rounded()
    return Date(timeIntervalSince1970: seconds)
}

func XCTAssertNearNow(
    _ date: Date,
    _ tolerance: Double = 1.seconds
) {
    let deltaSeconds = Date.now.timeIntervalSince1970 - date.timeIntervalSince1970
    XCTAssertTrue(deltaSeconds < tolerance)
}
