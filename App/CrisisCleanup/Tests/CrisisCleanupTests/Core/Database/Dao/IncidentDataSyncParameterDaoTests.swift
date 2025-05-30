import Combine
import Foundation
import GRDB
import TestableCombinePublishers
import XCTest
@testable import CrisisCleanup

class IncidentDataSyncParameterDaoTests: XCTestCase {
    private var dbQueue: DatabaseQueue!
    private var appDb: AppDatabase!
    private var syncParameterDao: IncidentDataSyncParameterDao!
    private let logger = SilentAppLogger()

    private var testIncidentId: Int64 = 0

    private let beforeSyncedAtA = dateNowRoundedSeconds.addingTimeInterval(1.days * 365)

    private lazy var syncMarkerA: IncidentDataSyncParameters.SyncTimeMarker =  {
        IncidentDataSyncParameters.SyncTimeMarker(
            before: beforeSyncedAtA,
            after: IncidentDataSyncParameters.timeMarkerZero,
        )
    }()

    private lazy var syncMarkerNone: IncidentDataSyncParameters.SyncTimeMarker =  {
        IncidentDataSyncParameters.SyncTimeMarker(
            before: IncidentDataSyncParameters.timeMarkerZero,
            after: IncidentDataSyncParameters.timeMarkerZero,
        )
    }()

    override func setUp() async throws {
        let initialized = try initializeTestDb()
        dbQueue = initialized.0
        appDb = initialized.1
        syncParameterDao = IncidentDataSyncParameterDao(appDb, logger)

        try await dbQueue.write { db in
            for incident in WorksiteTestUtil.testIncidents {
                try incident.upsert(db)
            }
        }

        testIncidentId = WorksiteTestUtil.testIncidents.last!.id
    }

    private func getSyncParameters(
        _ boundedRegion: IncidentDataSyncParameters.BoundedRegion?,
        _ syncedAt: Date? = nil,
    ) -> IncidentDataSyncParameters {
        IncidentDataSyncParameters(
            incidentId: testIncidentId,
            syncDataMeasures: IncidentDataSyncParameters.SyncDataMeasure(
                core: syncMarkerA,
                additional: syncMarkerNone,
            ),
            boundedRegion: boundedRegion,
            boundedSyncedAt: syncedAt ?? dateNowRoundedSeconds.addingTimeInterval(-1.days),
        )
    }

    func testInsertParameters() async throws {
        let parameters = getSyncParameters(
            IncidentDataSyncParameters.BoundedRegion(
                latitude: -14.451,
                longitude: 158.156561,
                radius: 2.365
            )
        )

        try await syncParameterDao.insertSyncStats(parameters.asRecord(logger))

        let actual = try syncParameterDao.getSyncStats(testIncidentId)

        XCTAssertEqual(actual, parameters)
    }

    func testInsertNoRegion() async throws {
        let parameters = getSyncParameters(nil)

        try await syncParameterDao.insertSyncStats(parameters.asRecord(logger))

        let actual = try syncParameterDao.getSyncStats(testIncidentId)

        XCTAssertEqual(actual, parameters)
    }

    func testUpdateSyncData() async throws {
        let regionA = IncidentDataSyncParameters.BoundedRegion(
            latitude: -14.451,
            longitude: 158.156561,
            radius: 2.365
        )
        let parameters = getSyncParameters(regionA)

        try await syncParameterDao.insertSyncStats(parameters.asRecord(logger))

        let updatedBefore = dateNowRoundedSeconds.addingTimeInterval(-9.days)
        try await syncParameterDao.updateUpdatedBefore(parameters.incidentId, updatedBefore)

        let actualBefore = try syncParameterDao.getSyncStats(testIncidentId)
        let parametersBefore = parameters.copy { p in
            p.syncDataMeasures = p.syncDataMeasures.copy { sdm in
                sdm.core = sdm.core.copy { c in
                    c.before = updatedBefore
                }
            }
        }
        XCTAssertEqual(actualBefore, parametersBefore)

        let updatedAfter = dateNowRoundedSeconds.addingTimeInterval(-7.days)
        try await syncParameterDao.updateUpdatedAfter(parameters.incidentId, updatedAfter)

        let actualAfter = try syncParameterDao.getSyncStats(testIncidentId)
        let parametersAfter = parametersBefore.copy { p in
            p.syncDataMeasures = p.syncDataMeasures.copy { sdm in
                sdm.core = sdm.core.copy { c in
                    c.after = updatedAfter
                }
            }
        }
        XCTAssertEqual(actualAfter, parametersAfter)

        let updatedAdditionalBefore = dateNowRoundedSeconds.addingTimeInterval(-3.days)
        try await syncParameterDao.updateAdditionalUpdatedBefore(parameters.incidentId, updatedAdditionalBefore)

        let actualAdditionalBefore = try syncParameterDao.getSyncStats(testIncidentId)
        let parametersAdditionalBefore = parametersAfter.copy { p in
            p.syncDataMeasures = p.syncDataMeasures.copy { sdm in
                sdm.additional = sdm.additional.copy { a in
                    a.before = updatedAdditionalBefore
                }
            }
        }
        XCTAssertEqual(actualAdditionalBefore, parametersAdditionalBefore)

        let updatedAdditionalAfter = dateNowRoundedSeconds.addingTimeInterval(-3.hours)
        try await syncParameterDao.updateAdditionalUpdatedAfter(parameters.incidentId, updatedAdditionalAfter)

        let actualAdditionalAfter = try syncParameterDao.getSyncStats(testIncidentId)
        let parametersAdditionalAfter = parametersAdditionalBefore.copy { p in
            p.syncDataMeasures = p.syncDataMeasures.copy { sdm in
                sdm.additional = sdm.additional.copy { a in
                    a.after = updatedAdditionalAfter
                }
            }
        }
        XCTAssertEqual(actualAdditionalAfter, parametersAdditionalAfter)
    }

    func testUpdateBounding() async throws {
        let regionA = IncidentDataSyncParameters.BoundedRegion(
            latitude: -19.451,
            longitude: 18.217561,
            radius: 23.365
        )
        let parameters = getSyncParameters(regionA)

        try await syncParameterDao.insertSyncStats(parameters.asRecord(logger))

        let jsonEncoder = JSONEncoder()

        let boundedUpdate = IncidentDataSyncParameters.BoundedRegion(
            latitude: 69.158,
            longitude: -89.321548,
            radius: 16.2
        )
        let syncedAtA = dateNowRoundedSeconds.addingTimeInterval(-10.hours)
        try await syncParameterDao.updateBoundedParameters(
            parameters.incidentId,
            jsonEncoder.encodeToString(boundedUpdate),
            syncedAtA
        )

        let actualBoundedA = try syncParameterDao.getSyncStats(testIncidentId)
        let parametersBoundedA = parameters.copy {
            $0.boundedRegion = boundedUpdate
            $0.boundedSyncedAt = syncedAtA
        }
        XCTAssertEqual(actualBoundedA, parametersBoundedA)

        let syncedAtB = dateNowRoundedSeconds.addingTimeInterval(-10.minutes)
        try await syncParameterDao.updateBoundedParameters(
            parameters.incidentId,
            "invalid-json",
            syncedAtB
        )

        let actualBoundedB = try syncParameterDao.getSyncStats(testIncidentId)
        let parametersBoundedB = parameters.copy {
            $0.boundedRegion = nil
            $0.boundedSyncedAt = syncedAtB
        }
        XCTAssertEqual(actualBoundedB, parametersBoundedB)
    }

    func testDeleteParameters() async throws {
        let parameters = getSyncParameters(nil)

        try await syncParameterDao.insertSyncStats(parameters.asRecord(logger))

        let actual = try syncParameterDao.getSyncStats(testIncidentId)

        XCTAssertEqual(actual, parameters)

        try syncParameterDao.deleteSyncParameters(testIncidentId)

        let actualDeleted = try syncParameterDao.getSyncStats(testIncidentId)

        XCTAssertNil(actualDeleted)
    }
}
