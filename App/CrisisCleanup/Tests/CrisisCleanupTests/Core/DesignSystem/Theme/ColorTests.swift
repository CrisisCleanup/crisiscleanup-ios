import SwiftUI
import XCTest
@testable import CrisisCleanup

final class ColorTests: XCTestCase {
    func testHex() {
        let colorA = Color(hex: 0x2BF8821A)
        XCTAssertEqual(0xF8821A, colorA.hexRgb)

        XCTAssertEqual(0x00F8821A, colorA.hex(0.0))
        XCTAssertEqual(0xFFF8821A, colorA.hex(1.0))
    }
}
