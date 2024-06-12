import Foundation
import GRDB
import XCTest
@testable import CrisisCleanup

class ListDaoTests: XCTestCase {
    private var now: Date = dateNowRoundedSeconds

    private var dbQueue: DatabaseQueue!
    private var appDb: AppDatabase!
    private var listDao: ListDao!

    override func setUp() async throws {
        let initialized = try initializeTestDb()
        dbQueue = initialized.0
        appDb = initialized.1
        listDao = ListDao(
            appDb,
            WorksiteTestUtil.silentAppLogger
        )

        try await dbQueue.write { db in
            for incident in WorksiteTestUtil.testIncidents {
                try incident.upsert(db)
            }
        }
    }

    private func insertLists(_ lists: [ListRecord]) async throws {
        try await dbQueue.write { db in
            for list in lists {
                var list = list
                try list.insert(db, onConflict: .ignore)
            }
        }
    }

    func testSingleList() async throws {
        let updatedAt = now.addingTimeInterval((-1.2).days)

        let list = testListRecord(532, updatedAt, "list-a")
        try await insertLists([list])

        let actual = listDao.getList(1)
        let expected = list.copy {
            $0.id = 1
        }
        XCTAssertEqual(actual, expected)

        try await listDao.deleteList(1)
        let deleted = listDao.getList(1)
        XCTAssertNil(deleted)
    }

    func testMultipleLists() async throws {
        let incident = WorksiteTestUtil.testIncidents[1]

        let listA = testListRecord(532, now, "list-a")
        let listB = testListRecord(81, now, "list-b")
        let listC = testListRecord(
            978,
            now,
            "list-c",
            incidentId: incident.id
        )
        try await insertLists([listA, listB, listC])

        let orderedLists = [
            listB.copy { $0.id = 2 },
            listA.copy { $0.id = 1 },
            listC.copy { $0.id = 3 },
        ]

        let populatedLists = listDao.getListsByNetworkIds([81, 978])
        let actual = populatedLists
            .map { $0.list }
            .sorted { a, b in a.networkId < b.networkId }
        XCTAssertEqual(actual, [orderedLists[0], orderedLists[2]])

        // TODO: Set other incident properties and compare
        let expectedIncidentNameType = IncidentIdNameType(
            id: incident.id,
            name: incident.name,
            shortName: incident.shortName,
            disasterLiteral: incident.type
        )
        XCTAssertEqual(populatedLists[1].asExternalModel().incident, expectedIncidentNameType)

        try await listDao.deleteListsByNetworkIds(Set([978]))
        let notDeleted = listDao.getListsByNetworkIds([81, 532, 978])
            .map { $0.list }
            .sorted { a, b in a.networkId < b.networkId }
        XCTAssertEqual(notDeleted, [orderedLists[0], orderedLists[1]])
    }

    func testSyncUpsert() async throws {
        let incidentA = WorksiteTestUtil.testIncidents[1]
        let incidentB = WorksiteTestUtil.testIncidents[0]

        let listA = testListRecord(532, now, "list-a")
        let listB = testListRecord(81, now, "list-b")
        let listC = testListRecord(
            978,
            now,
            "list-c",
            incidentId: incidentA.id
        )
        try await insertLists([listA, listB, listC])

        let listD = testListRecord(74, now, "list-d")
        let updatedAtC = now.addingTimeInterval(5.hours)
        let listCUpdate = listC.copy {
            $0.id = 3
            $0.updatedBy = 352
            $0.updatedAt = updatedAtC
            $0.parent = 2
            $0.name = "list-c-updated"
            $0.description = "description-c"
            $0.listOrder = 1
            $0.tags = "tags"
            $0.model = ListModel.organization.literal
            $0.objectIds = [532,63].map { String($0) }.joined(separator: ",")
            $0.shared = ListShare.team.literal
            $0.permissions = ListPermission.readCopy.literal
            $0.incidentId = incidentB.id
        }
        var allLists = try await dbQueue.write { db in
            try listD.syncUpsert(db)
            try listCUpdate.syncUpsert(db)

            return try ListRecord.fetchAll(db)
        }
        allLists = allLists.sorted(by: { a, b in
            a.networkId < b.networkId
        })

        let expected = [
            listD.copy { $0.id = 4 },
            listB.copy { $0.id = 2 },
            listA.copy { $0.id = 1 },
            listCUpdate,
        ]
        XCTAssertEqual(allLists, expected)
    }
}

internal func testListRecord(
    _ networkId: Int64,
    _ updatedAt: Date,
    _ name: String,
    incidentId: Int64? = nil,
    id: Int64? = nil,
    localGlobalUuid: String = "",
    createdAt: Date = Date.init(timeIntervalSince1970: 0),
    updatedBy: Int64? = nil,
    parent: Int64? = nil,
    description: String = "",
    listOrder: Int64? = nil,
    tags: String = "",
    model: String = "",
    shared: String = "",
    objectIds: String = "",
    permissions: String = ""
) -> ListRecord {
    ListRecord(
        id: id,
        networkId: networkId,
        localGlobalUuid: localGlobalUuid,
        createdBy: nil,
        updatedBy: updatedBy,
        createdAt: createdAt,
        updatedAt: updatedAt,
        parent: parent,
        name: name,
        description: description,
        listOrder: listOrder,
        tags: tags,
        model: model,
        objectIds: objectIds,
        shared: shared,
        permissions: permissions,
        incidentId: incidentId
    )
}
