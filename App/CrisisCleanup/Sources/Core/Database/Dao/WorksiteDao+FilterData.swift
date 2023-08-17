import CoreLocation
import Foundation
import GRDB

private typealias AssociateRootToWorksite = HasOneAssociation<WorksiteRootRecord, WorksiteRecord>

extension WorksiteDao {
    func getWorksitesCount(
        _ incidentId: Int64,
        _ totalCount: Int,
        _ filters: CasesFilter,
        _ organizationAffiliates: Set<Int64>,
        _ coordinates: CLLocation?,
        _ locationAreaBounds: OrganizationLocationAreaBounds
    ) async throws -> IncidentIdWorksiteCount {
        let stride = 2000
        var offset = 0
        var count = 0
        let latRad = coordinates?.latLng.latitude.radians
        let lngRad = coordinates?.latLng.longitude.radians
        while offset < totalCount {
            try Task.checkCancellation()

            let worksites: [PopulatedFilterDataWorksite]
            if filters.hasSviFilter {
                worksites = getFilterWorksites(incidentId, stride, offset) {
                    $0.bySviLte(filters.svi)
                        .orderBySvi()
                }
            } else if filters.hasUpdatedFilter {
                let daysAgo = Date.now.addingTimeInterval(-Double(filters.daysAgoUpdated).days)
                worksites = getFilterWorksites(incidentId, stride, offset) {
                    $0.byUpdatedGte(daysAgo)
                        .orderByUpdatedAt()
                }
            } else if filters.updatedAt != nil {
                worksites = getFilterWorksites(incidentId, stride, offset) {
                    $0.byUpdatedBetween(
                        filters.updatedAt!.start,
                        filters.updatedAt!.end
                    )
                    .orderByUpdatedAt()
                }
            } else if filters.createdAt != nil {
                worksites = getFilterWorksites(incidentId, stride, offset) {
                    $0.byUpdatedBetween(
                        filters.createdAt!.start,
                        filters.createdAt!.end
                    )
                    .orderByUpdatedAt()
                }
            } else {
                worksites = getFilterWorksites(incidentId, stride, offset) {
                    $0.orderById()
                }
            }
            if worksites.isEmpty {
                break
            }

            try Task.checkCancellation()

            count += worksites.filter(
                filters,
                organizationAffiliates,
                latRad,
                lngRad,
                locationAreaBounds
            ).count

            offset += stride
        }

        return IncidentIdWorksiteCount(
            id: incidentId,
            totalCount: totalCount,
            filteredCount: count
        )
    }

    private func getFilterWorksites(
        _ incidentId: Int64,
        _ limit: Int,
        _ offset: Int,
        _ association: (AssociateRootToWorksite) -> AssociateRootToWorksite
    ) -> [PopulatedFilterDataWorksite] {
        try! reader.read { db in
            let worksiteAlias = TableAlias(name: "w")
            let record = association(
                WorksiteRootRecord.worksite
                    .aliased(worksiteAlias)
            )

            return try WorksiteRootRecord
                .all()
                .byIncidentId(incidentId)
                .including(required: record)
                .including(all: WorksiteRootRecord.worksiteFlags)
                .including(all: WorksiteRootRecord.worksiteFormData)
                .including(all: WorksiteRootRecord.workTypes)
                .limit(limit, offset: offset)
                .asRequest(of: PopulatedFilterDataWorksite.self)
                .fetchAll(db)
        }
    }
}
