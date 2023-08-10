import Foundation
import XCTest
@testable import CrisisCleanup

class CaseNumberOrderTests: XCTestCase {
    func testParseNoCaseNumber() {
        let noCaseNumbers = [
            "",
            "leters",
            "symbols*F@",
        ]

        noCaseNumbers.forEach {
            XCTAssertEqual(0, WorksiteRecord.parseCaseNumberOrder($0))
        }
    }

    func testParseCaseNumber() {
        let caseNumbers = [
            ("35ksd", Int64(35)),
            ("ef-5235", Int64(5235)),
            ("Pre 642Post", Int64(642)),
            ("a62b46", Int64(62)),
        ]

        caseNumbers.forEach {
            XCTAssertEqual($0.1, WorksiteRecord.parseCaseNumberOrder($0.0))
        }
    }
}
