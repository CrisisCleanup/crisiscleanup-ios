import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class FavoriteChangeTests: XCTestCase {
    private let noFavoriteA = testCoreSnapshot(id: 513)
    private let noFavoriteB = testCoreSnapshot(id: 642)
    private let favoriteIdA = testCoreSnapshot(id: 69, favoriteId: 53)
    private let favoriteIdB = testCoreSnapshot(id: 83, favoriteId: 73)
    private let assignedA = testCoreSnapshot(id: 48, isAssignedToOrgMember: true)
    private let assignedB = testCoreSnapshot(id: 72, isAssignedToOrgMember: true)

    private let nullFavoriteWorksite = testNetworkWorksite()
    private let favoriteWorksite =
    testNetworkWorksite(favorite: NetworkType(id: 53, typeT: "", createdAt: ChangeTestUtil.createdAtA))

    func testNoChange() {
        XCTAssertNil(nullFavoriteWorksite.getFavoriteChange(noFavoriteA, noFavoriteB))
        XCTAssertNil(nullFavoriteWorksite.getFavoriteChange(favoriteIdA, favoriteIdB))
        XCTAssertNil(nullFavoriteWorksite.getFavoriteChange(assignedA, noFavoriteB))
        XCTAssertNil(nullFavoriteWorksite.getFavoriteChange(assignedA, favoriteIdB))

        XCTAssertNil(favoriteWorksite.getFavoriteChange(assignedA, assignedB))
        XCTAssertNil(favoriteWorksite.getFavoriteChange(noFavoriteA, assignedB))
        XCTAssertNil(favoriteWorksite.getFavoriteChange(favoriteIdB, assignedB))
    }

    func testChange() {
        XCTAssertEqual(false, favoriteWorksite.getFavoriteChange(assignedA, noFavoriteB))
        XCTAssertEqual(false, favoriteWorksite.getFavoriteChange(assignedB, favoriteIdA))

        XCTAssertEqual(true, nullFavoriteWorksite.getFavoriteChange(noFavoriteA, assignedB))
        XCTAssertEqual(true, nullFavoriteWorksite.getFavoriteChange(favoriteIdB, assignedA))
    }
}
