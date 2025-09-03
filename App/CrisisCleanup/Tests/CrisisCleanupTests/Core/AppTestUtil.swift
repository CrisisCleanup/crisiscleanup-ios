import Foundation
import XCTest
@testable import CrisisCleanup

var dateNowRoundedSeconds: Date {
    let seconds = Date.now.timeIntervalSince1970.rounded()
    return Date(timeIntervalSince1970: seconds)
}

func clearUserDefaults() {
    UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
}

func XCTAssertNearNow(
    _ date: Date,
    _ tolerance: Double = 1.seconds
) {
    let deltaSeconds = Date.now.timeIntervalSince1970 - date.timeIntervalSince1970
    XCTAssertTrue(deltaSeconds < tolerance)
}

func XCTAssertEqual<A: Equatable, B: Equatable>(_ a: (A, B), _ b: (A, B)) {
    XCTAssertEqual(a.0, b.0)
    XCTAssertEqual(a.1, b.1)
}

func XCTAssertEqual<A: Equatable, B: Equatable, C: Equatable>(_ a: (A, B, C), _ b: (A, B, C)) {
    XCTAssertEqual(a.0, b.0)
    XCTAssertEqual(a.1, b.1)
    XCTAssertEqual(a.2, b.2)
}

func XCTAssertEqual<A: Equatable, B: Equatable>(_ a: [(A, B)], _ b: [(A, B)]) {
    XCTAssertEqual(a.count, b.count)
    for i in 0..<a.count {
        XCTAssertEqual(a[i], b[i])
    }
}

func XCTAssertEqual<A: Equatable, B: Equatable, C: Equatable>(_ a: ([A], [B], [C]), _ b: ([A], [B], [C])) {

    XCTAssertEqual(a.0.count, b.0.count)
    for i in 0..<a.0.count {
        XCTAssertEqual(a.0[i], b.0[i])
    }

    XCTAssertEqual(a.1.count, b.1.count)
    for i in 0..<a.1.count {
        XCTAssertEqual(a.1[i], b.1[i])
    }

    XCTAssertEqual(a.2.count, b.2.count)
    for i in 0..<a.2.count {
        XCTAssertEqual(a.2[i], b.2[i])
    }
}

func XCTAssertEqual<A: Equatable, B: Equatable, C: Equatable, D: Equatable>(_ a: ([(A, D)], [B], [C]), _ b: ([(A, D)], [B], [C])) {

    XCTAssertEqual(a.0.count, b.0.count)
    for i in 0..<a.0.count {
        XCTAssertEqual(a.0[i], b.0[i])
    }

    XCTAssertEqual(a.1.count, b.1.count)
    for i in 0..<a.1.count {
        XCTAssertEqual(a.1[i], b.1[i])
    }

    XCTAssertEqual(a.2.count, b.2.count)
    for i in 0..<a.2.count {
        XCTAssertEqual(a.2[i], b.2[i])
    }
}

extension String {
    var toDate: Date {
        let dateFormatter = ISO8601DateFormatter()
        if let isoFormat = dateFormatter.date(from:self) {
            return isoFormat
        }

        let millisecondsFormat = with(DateFormatter()) {
            $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        }
        return millisecondsFormat.date(from: self)!
    }
}
