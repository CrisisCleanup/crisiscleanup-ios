import Combine
import Foundation
import GRDB

public class IncidentOrganizationDao {
    private let database: AppDatabase
    private let reader: DatabaseReader

    init(_ database: AppDatabase) {
        self.database = database
        reader = database.reader
    }

    func streamOrganizationNames() -> AnyPublisher<[OrganizationIdName], Error> {
        // TODO: Do
        CurrentValueSubject<[OrganizationIdName], Error>([])
            .eraseToAnyPublisher()
    }

    func streamOrganizations() -> AnyPublisher<[PopulatedIncidentOrganization], Error> {
        // TODO: Do
        CurrentValueSubject<[PopulatedIncidentOrganization], Error>([])
            .eraseToAnyPublisher()
    }

    func getAffiliateOrganizationIds(_ organizationId: Int64) -> [Int64] {
        // TODO: Do
        []
    }

    func saveOrganizations(
        _ organizations: [IncidentOrganizationRecord],
        _ primaryContacts: [PersonContactRecord]
    ) async throws {
        // TODO: Do
    }

    func saveOrganizationReferences(
        _ organizations: [IncidentOrganizationRecord],
        _ organizationContactCrossRefs: [OrganizationToPrimaryContactRecord],
        _ organizationAffiliates: [OrganizationAffiliateRecord]
    ) async throws {
        // TODO: Do
    }

    func getOrganizations(_ organizationIds: [Int64]) throws -> [PopulatedIncidentOrganization] {
        // TODO: Do
        []
    }
}

struct PopulatedIncidentOrganization: Equatable, Decodable, FetchableRecord {
    let id: Int64
    let name: String
    let personContacts: [PersonContactRecord]
    let organizationAffiliates: [OrganizationAffiliateRecord]

    func asExternalModel() -> IncidentOrganization {
        var affiliateIds: Set<Int64> = [id]
        organizationAffiliates.forEach { record in
            affiliateIds.insert(record.affiliateId)
        }
        return IncidentOrganization(
            id: id,
            name: name,
            primaryContacts: personContacts.map { $0.asExternalModel() },
            affiliateIds: affiliateIds
        )
    }
}
