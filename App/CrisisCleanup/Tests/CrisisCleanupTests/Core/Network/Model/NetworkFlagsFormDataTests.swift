import XCTest
@testable import CrisisCleanup

final class NetworkFlagsFormDataTests: XCTestCase {
    func testGetFlagsFormDataSuccess() throws {
        let result = Bundle(for: NetworkFlagsFormDataTests.self)
            .loadJson("getFlagsFormDataSuccess", NetworkFlagsFormDataResult.self)

        XCTAssertNil(result.errors)

        XCTAssertEqual(20, result.count)

        let entry = result.results![2]

        let expected = NetworkFlagsFormData(
            id: 229138,
            caseNumber: "VW2UVP",
            formData: [
                KeyDynamicValuePair(
                    "debris_info",
                    DynamicValue(valueString: "", isBool: true, valueBool: true)
                ),
                KeyDynamicValuePair(
                    "debris_description",
                    DynamicValue(valueString: "shed has well and was damaged  ")
                ),
                KeyDynamicValuePair(
                    "unsalvageable_structure",
                    DynamicValue(valueString: "", isBool: true, valueBool: true)
                ),
                KeyDynamicValuePair(
                    "vegitative_debris_removal",
                    DynamicValue(valueString: "", isBool: true, valueBool: true)
                ),
                KeyDynamicValuePair(
                    "habitable",
                    DynamicValue(valueString: "formOptions.yes")
                ),
                KeyDynamicValuePair(
                    "residence_type",
                    DynamicValue(valueString: "formOptions.primary_living_in_home")
                ),
                KeyDynamicValuePair(
                    "dwelling_type",
                    DynamicValue(valueString: "formOptions.mobile_home")
                ),
                KeyDynamicValuePair(
                    "work_without_resident",
                    DynamicValue(valueString: "", isBool: true, valueBool: true)
                ),
                KeyDynamicValuePair(
                    "tree_info",
                    DynamicValue(valueString: "", isBool: true, valueBool: true)
                ),
            ],
            flags: [],
            phone1: "1234567890",
            reportedBy: 861
        )
        XCTAssertEqual(expected, entry)
    }
}
