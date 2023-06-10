import XCTest
@testable import CrisisCleanup

final class NetworkFormFieldTests: XCTestCase {
    func testDeserializeFormFields() throws {
        let testCases = [
            ("incidentFormFields1", 61),
            ("incidentFormFields2", 89),
            ("incidentFormFields3", 70),
            ("incidentFormFields4", 59),
        ]
        testCases.forEach {
            let result = Bundle(for: NetworkFormFieldTests.self)
                .loadJson($0.0, IncidentFormField.self)

            XCTAssertEqual($0.1, result.fields.count)
        }
    }
}

private struct IncidentFormField: Codable, Equatable {
    let id: Int64
    let name: String
    let fields: [NetworkIncidentFormField]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fields = "form_fields"
    }
}
