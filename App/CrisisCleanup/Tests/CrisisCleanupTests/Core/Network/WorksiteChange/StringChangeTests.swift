import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class StringChangeTests: XCTestCase {
    func testChanges() {
        // No diff (between nil, empty, blank) results in base
        XCTAssertEqual("base", "base".change("same", "same"))
        XCTAssertEqual("base", "base".change("same ", " same"))

        // Diff results in to
        XCTAssertEqual("to", "base".change("", "to"))
        XCTAssertEqual("to", "base".change(" ", "to"))
        XCTAssertEqual("to", "base".change("from", "to"))
        XCTAssertEqual("", "base".change("from", ""))
        XCTAssertEqual(" ", "base".change("from", " "))
    }

    func testBaseChange_nilBase() {
        // No diff (between nil, empty, blank) results in base (nil)
        XCTAssertNil(baseChange(nil, nil, nil))
        XCTAssertNil(baseChange(nil, "", nil))
        XCTAssertNil(baseChange(nil, nil, ""))
        XCTAssertNil(baseChange(nil, " ", nil))
        XCTAssertNil(baseChange(nil, nil, " "))
        XCTAssertNil(baseChange(nil, "same", "same"))
        XCTAssertNil(baseChange(nil, " same", "same "))

        // Diff results in to
        XCTAssertEqual("to", baseChange(nil, nil, "to"))
        XCTAssertEqual("to", baseChange(nil, "", "to"))
        XCTAssertEqual("to", baseChange(nil, " ", "to"))
        XCTAssertEqual("to", baseChange(nil, "from", "to"))
        XCTAssertEqual(nil, baseChange(nil, "from", nil))
        XCTAssertEqual("", baseChange(nil, "from", ""))
        XCTAssertEqual(" ", baseChange(nil, "from", " "))
    }

    func testBaseChange_baseNotnil() {
        // No diff (between nil, empty, blank) results in base
        XCTAssertEqual("base", baseChange("base", nil, nil))
        XCTAssertEqual("base", baseChange("base", "", nil))
        XCTAssertEqual("base", baseChange("base", nil, ""))
        XCTAssertEqual("base", baseChange("base", " ", nil))
        XCTAssertEqual("base", baseChange("base", nil, " "))
        XCTAssertEqual("base", baseChange("base", "same", "same"))
        XCTAssertEqual("base", baseChange("base", "same ", " same"))

        // Diff results in to
        XCTAssertEqual("to", baseChange("base", nil, "to"))
        XCTAssertEqual("to", baseChange("base", "", "to"))
        XCTAssertEqual("to", baseChange("base", " ", "to"))
        XCTAssertEqual("to", baseChange("base", "from", "to"))
        XCTAssertEqual(nil, baseChange("base", "from", nil))
        XCTAssertEqual("", baseChange("base", "from", ""))
        XCTAssertEqual(" ", baseChange("base", "from", " "))
    }
}
