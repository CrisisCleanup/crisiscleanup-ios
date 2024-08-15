import Combine
import Foundation
import GRDB

public class IncidentDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func getIncidentCount() -> Int {
        try! reader.read { try IncidentRecord.fetchCount($0) }
    }

    func getIncident(_ id: Int64) throws -> Incident? {
        try reader.read { db in try fetchIncident(db, id) }?.asExternalModel()
    }
    private func fetchIncident(_ db: Database, _ id: Int64) throws -> PopulatedIncident? {
        try IncidentRecord
            .filter(id: id)
            .isNotArchived()
            .including(all: IncidentRecord.locations)
            .asRequest(of: PopulatedIncident.self)
            .fetchOne(db)
    }

    func getFormFieldsIncident(_ id: Int64) throws -> Incident? {
        try reader.read { db in try fetchFormFieldsIncident(db, id) }?.asExternalModel()
    }

    func getIncidents(_ startAt: Date) throws -> [Incident] {
        try reader.read { db in
            try fetchIncidentsStartingAt(db, startAt)
        }
        .map { $0.asExternalModel() }
    }

    func getIncidents(_ ids: [Int64]) -> [Incident] {
        try! reader.read { db in
            try IncidentRecord
                .all()
                .filter(ids: ids)
                .including(all: IncidentRecord.locations)
                .asRequest(of: PopulatedIncident.self)
                .fetchAll(db)
        }
        .map { $0.asExternalModel() }
    }

    private func fetchIncidentsStartingAt(_ db: Database, _ startAt: Date) throws -> [PopulatedIncident] {
        try IncidentRecord
            .all()
            .isNotArchived()
            .startingAt(startAt)
            .orderedByStartAtDesc()
            .including(all: IncidentRecord.locations)
            .asRequest(of: PopulatedIncident.self)
            .fetchAll(db)
    }

    func streamIncidents() -> AnyPublisher<[Incident], Never> {
        ValueObservation
            .tracking(fetchIncidents(_:))
            .removeDuplicates()
            .map { $0.map { p in p.asExternalModel() } }
            .shared(in: reader)
            .publisher()
            .assertNoFailure()
            .eraseToAnyPublisher()
    }

    private func fetchIncidents(_ db: Database) throws -> [PopulatedIncident] {
        try IncidentRecord
            .all()
            .isNotArchived()
            .orderedByStartAtDesc()
            .including(all: IncidentRecord.locations)
            .asRequest(of: PopulatedIncident.self)
            .fetchAll(db)
    }

    func streamFormFieldsIncident(_ id: Int64) -> AnyPublisher<Incident?, Error> {
        ValueObservation
            .tracking({ db in try self.fetchFormFieldsIncident(db, id) })
            .removeDuplicates()
            .map { p in p?.asExternalModel() }
            .shared(in: reader)
            .publisher()
            .eraseToAnyPublisher()
    }

    private func fetchFormFieldsIncident(_ db: Database, _ id: Int64) throws -> PopulatedFormFieldsIncident? {
        try IncidentRecord
            .filter(id: id)
            .isNotArchived()
            .including(all: IncidentRecord.locations)
            .including(all: IncidentRecord.incidentFormFields)
            .asRequest(of: PopulatedFormFieldsIncident.self)
            .fetchOne(db)
    }

    func saveIncidents(
        _ incidents: [IncidentRecord],
        _ locations: [IncidentLocationRecord],
        _ locationXrs: [IncidentToIncidentLocationRecord]
    ) async throws {
        try await database.saveIncidents(incidents, locations, locationXrs)
    }

    func updateFormFields(
        _ incidentData: [(Int64, [IncidentFormFieldRecord])]
    ) async throws {
        try await database.updateFormFields(incidentData)
    }

    func getMatchingIncidents(_ q: String) -> [IncidentIdNameType] {
        try! reader.read { db in
            let sql = """
                SELECT i.*
                FROM incident i
                JOIN incident_ft fts
                    ON fts.rowid = i.rowid
                WHERE incident_ft MATCH ?
                ORDER BY startAt DESC
                """
            let pattern = FTS3Pattern(matchingAllPrefixesIn: q)
            return try IncidentRecord.fetchAll(
                db,
                sql: sql,
                arguments: [pattern]
            )
        }
        .map {
            IncidentIdNameType(
                id: $0.id,
                name: $0.name,
                shortName: $0.shortName,
                disasterLiteral: $0.type
            )
        }
    }
}

extension AppDatabase {
    fileprivate func saveIncidents(
        _ incidents: [IncidentRecord],
        _ locations: [IncidentLocationRecord],
        _ locationXrs: [IncidentToIncidentLocationRecord]
    ) async throws {
        let incidentIds = incidents.map { $0.id }
        try await dbWriter.write { db in
            try incidents.forEach { incident in
                try incident.upsert(db)
            }
            try locations.forEach { location in
                try location.upsert(db)
            }

            try IncidentToIncidentLocationRecord
                .filter(IncidentToIncidentLocationRecord.filterByIds(ids: incidentIds))
                .deleteAll(db)
            try locationXrs.forEach { xr in
                _ = try xr.insertAndFetch(db, onConflict: .ignore)
            }
        }
    }

    fileprivate func updateFormFields(
        _ incidentData: [(Int64, [IncidentFormFieldRecord])]
    ) async throws {
        try await dbWriter.write { db in
            try incidentData.forEach { (incidentId, formFields) in
                if formFields.isNotEmpty {
                    let validFields = formFields.filter { !$0.isInvalidated }
                    let validFieldKeys = Set(validFields.map { $0.fieldKey })
                    try IncidentFormFieldRecord.invalidateUnspecifiedFormFields(db, incidentId, validFieldKeys)
                    try validFields.forEach { field in
                        try field.upsert(db)
                    }
                }
            }
        }
    }
}

// MARK: - Requests

private struct PopulatedIncident: Equatable, Decodable, FetchableRecord {
    let incident: IncidentRecord
    let incidentLocations: [IncidentLocationRecord]

    func asExternalModel() -> Incident {
        incident.asExternalModel(locationIds: incidentLocations.locationIds)
    }
}

private struct PopulatedFormFieldsIncident: Equatable, Decodable, FetchableRecord {
    let incident: IncidentRecord
    let incidentLocations: [IncidentLocationRecord]
    let incidentFormFields: [IncidentFormFieldRecord]

    func asExternalModel() -> Incident {
        let formFields = incidentFormFields
            .map { r in try! r.asExternalModel() }
            .filter { f in !(f.isInvalidated || f.isDivEnd) }
        return incident.asExternalModel(
            locationIds: incidentLocations.locationIds,
            formFields: formFields
        )
    }
}

extension [IncidentLocationRecord] {
    fileprivate var locationIds: [Int64] { map { $0.location } }
}
