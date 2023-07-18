import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class FormDataChangeTests: XCTestCase {
    private let emptyFormData = [KeyDynamicValuePair]()
    private let baseFormData = [
        KeyDynamicValuePair("abf", DynamicValue(false)),
        KeyDynamicValuePair("abt", DynamicValue(true)),
        KeyDynamicValuePair("bs", DynamicValue("botu")),
        KeyDynamicValuePair("cs", DynamicValue("cosu")),
        KeyDynamicValuePair("ds", DynamicValue("domu")),
        KeyDynamicValuePair("es", DynamicValue("eopu")),
    ]

    private var emptyWorksite: NetworkWorksiteFull!
    private var baseWorksite: NetworkWorksiteFull!

    override func setUp() {
        emptyWorksite = testNetworkWorksite(formData: emptyFormData)
        baseWorksite = testNetworkWorksite(formData: baseFormData)
    }

    func testNoChange() {
        XCTAssertEqual(emptyFormData, emptyWorksite.getFormDataChanges([:], [:]))
        XCTAssertEqual(baseFormData, baseWorksite.getFormDataChanges([:], [:]))

        let noChangeMap = [
            "a": DynamicValue("b"),
            "b": DynamicValue(true),
        ]
        XCTAssertEqual(emptyFormData, emptyWorksite.getFormDataChanges(noChangeMap, noChangeMap))
        XCTAssertEqual(baseFormData, baseWorksite.getFormDataChanges(noChangeMap, noChangeMap))
    }

    func testNewAdd() {
        let newChangesMap = [
            "new-a": DynamicValue("b"),
            "new-b": DynamicValue(true),
        ]

        let expectedEmpty = newChangesMap.map { KeyDynamicValuePair($0.key, $0.value) }
            .sorted { a, b in a.key.localizedCompare(b.key) == .orderedAscending }

        XCTAssertEqual(expectedEmpty, emptyWorksite.getFormDataChanges([:], newChangesMap))

        let expectedBase = [
            KeyDynamicValuePair("abf", DynamicValue(false)),
            KeyDynamicValuePair("abt", DynamicValue(true)),
            KeyDynamicValuePair("bs", DynamicValue("botu")),
            KeyDynamicValuePair("cs", DynamicValue("cosu")),
            KeyDynamicValuePair("ds", DynamicValue("domu")),
            KeyDynamicValuePair("es", DynamicValue("eopu")),
            KeyDynamicValuePair("new-a", DynamicValue("b")),
            KeyDynamicValuePair("new-b", DynamicValue(true)),
        ]
        XCTAssertEqual(expectedBase, baseWorksite.getFormDataChanges([:], newChangesMap))
    }

    func testNewUpdate() {
        let newChangesMap = [
            "bs": DynamicValue("bs-new"),
            "abf": DynamicValue(true),
        ]

        let expected = [
            KeyDynamicValuePair("abf", DynamicValue(true)),
            KeyDynamicValuePair("abt", DynamicValue(true)),
            KeyDynamicValuePair("bs", DynamicValue("bs-new")),
            KeyDynamicValuePair("cs", DynamicValue("cosu")),
            KeyDynamicValuePair("ds", DynamicValue("domu")),
            KeyDynamicValuePair("es", DynamicValue("eopu")),
        ]

        XCTAssertEqual(expected, baseWorksite.getFormDataChanges([:], newChangesMap))
    }

    func testDeleteNone() {
        let changesMap = [
            "r": DynamicValue("r"),
            "s": DynamicValue("s")
        ]

        XCTAssertEqual(emptyFormData, emptyWorksite.getFormDataChanges(changesMap, [:]))
        XCTAssertEqual(baseFormData, baseWorksite.getFormDataChanges(changesMap, [:]))
    }

    func testDeleteExisting() {
        let fromMap = [
            "bs": DynamicValue("botu"),
            "ds": DynamicValue("domu"),
            "abt": DynamicValue(true),
            "r": DynamicValue(true),
        ]
        let toMap = [
            "bs": DynamicValue("botu"),
        ]

        let actual = baseWorksite.getFormDataChanges(fromMap, toMap)

        let expected = [
            KeyDynamicValuePair("abf", DynamicValue(false)),
            KeyDynamicValuePair("bs", DynamicValue("botu")),
            KeyDynamicValuePair("cs", DynamicValue("cosu")),
            KeyDynamicValuePair("es", DynamicValue("eopu")),
        ]
        XCTAssertEqual(expected, actual)
    }

    func testChangeNew() {
        let start = [
            "change-new": DynamicValue(true),
        ]
        let change = [
            "change-new": DynamicValue(false),
        ]

        let actual = baseWorksite.getFormDataChanges(start, change)

        let expected = [
            KeyDynamicValuePair("abf", DynamicValue(false)),
            KeyDynamicValuePair("abt", DynamicValue(true)),
            KeyDynamicValuePair("bs", DynamicValue("botu")),
            KeyDynamicValuePair("change-new", DynamicValue(false)),
            KeyDynamicValuePair("cs", DynamicValue("cosu")),
            KeyDynamicValuePair("ds", DynamicValue("domu")),
            KeyDynamicValuePair("es", DynamicValue("eopu")),
        ]
        XCTAssertEqual(expected, actual)
    }

    func testChangeExisting() {
        let start = [
            "abt": DynamicValue(true),
            "cs": DynamicValue("c-unchanged"),
            "bs": DynamicValue("botu-a"),
        ]
        let change = [
            "abt": DynamicValue(false),
            "cs": DynamicValue("c-unchanged"),
            "bs": DynamicValue("botu-b"),
        ]

        let actual = baseWorksite.getFormDataChanges(start, change)

        let expected = [
            KeyDynamicValuePair("abf", DynamicValue(false)),
            KeyDynamicValuePair("abt", DynamicValue(false)),
            KeyDynamicValuePair("bs", DynamicValue("botu-b")),
            KeyDynamicValuePair("cs", DynamicValue("cosu")),
            KeyDynamicValuePair("ds", DynamicValue("domu")),
            KeyDynamicValuePair("es", DynamicValue("eopu")),
        ]
        XCTAssertEqual(expected, actual)
    }

    func testUnchanged() {
        let start = [
            "abt": DynamicValue(true),
            "cs": DynamicValue("c-unchanged"),
            "unchanged": DynamicValue("unchanged"),
        ]
        let change = [
            "abt": DynamicValue(true),
            "cs": DynamicValue("c-unchanged"),
            "unchanged": DynamicValue("unchanged"),
        ]

        XCTAssertEqual([], emptyWorksite.getFormDataChanges(start, change))

        let actual = baseWorksite.getFormDataChanges(start, change)
        let expected = [
            KeyDynamicValuePair("abf", DynamicValue(false)),
            KeyDynamicValuePair("abt", DynamicValue(true)),
            KeyDynamicValuePair("bs", DynamicValue("botu")),
            KeyDynamicValuePair("cs", DynamicValue("cosu")),
            KeyDynamicValuePair("ds", DynamicValue("domu")),
            KeyDynamicValuePair("es", DynamicValue("eopu")),
        ]
        XCTAssertEqual(expected, actual)
    }

    func testComplex() {
        let start = [
            "unchanged": DynamicValue("unchanged"),
            "ds": DynamicValue("ds-no-change"),
            "bs": DynamicValue("start-bs"),
            "peno": DynamicValue("din"),
            "start-dis": DynamicValue("is deleting"),
            "abf": DynamicValue(true),
            "arto": DynamicValue("starto"),
        ]
        let change = [
            "new": DynamicValue(true),
            "abt": DynamicValue(false),
            "unchanged": DynamicValue("unchanged"),
            "ds": DynamicValue("ds-no-change"),
            "bs": DynamicValue("change-bs"),
            "peno": DynamicValue("fin"),
            "arto": DynamicValue("starto"),
        ]

        let actual = baseWorksite.getFormDataChanges(start, change)
        let expected = [
            KeyDynamicValuePair("abt", DynamicValue(false)),
            KeyDynamicValuePair("bs", DynamicValue("change-bs")),
            KeyDynamicValuePair("cs", DynamicValue("cosu")),
            KeyDynamicValuePair("ds", DynamicValue("domu")),
            KeyDynamicValuePair("es", DynamicValue("eopu")),
            KeyDynamicValuePair("new", DynamicValue(true)),
            KeyDynamicValuePair("peno", DynamicValue("fin")),
        ]
        XCTAssertEqual(expected, actual)
    }
}
