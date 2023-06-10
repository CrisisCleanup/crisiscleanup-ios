import XCTest
@testable import CrisisCleanup

final class NetworkOrganizationTests: XCTestCase {
    func testGetIncidentOrganizations() throws {
        let result = Bundle(for: NetworkOrganizationTests.self)
            .loadJson("incidentOrganizations", NetworkOrganizationsResult.self)

        XCTAssertNil(result.errors)

        XCTAssertEqual(391, result.count)

        let organizations = result.results!
        XCTAssertEqual(2, organizations.count)
        let expected = NetworkIncidentOrganization(
            id:  5120,
            name:  "test",
            affiliates:  [5120],
            primaryLocation:  79749,
            typeT:  "orgType.government",
            primaryContacts:  [
                NetworkPersonContact(
                    id:  29695,
                    firstName:  "test",
                    lastName:  "test",
                    email:  "test@test.com",
                    mobile:  "5353151368"
                )
            ]
        )
        XCTAssertEqual(expected, organizations[0])
    }
}
