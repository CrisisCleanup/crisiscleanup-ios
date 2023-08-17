import CoreLocation
import GRDB

struct PopulatedTableDataWorksite: Equatable, Decodable, FetchableRecord {
    let worksiteRoot: WorksiteRootRecord
    let worksite: WorksiteRecord
    let workTypes: [WorkTypeRecord]
    let worksiteWorkTypeRequests: [WorkTypeRequestRecord]

    // For filtering
    let worksiteFormData: [WorksiteFormDataRecord]
    let worksiteFlags: [WorksiteFlagRecord]

    func asExternalModel() -> Worksite {
        Worksite.from(worksiteRoot, worksite, workTypes)
            .copy {
                $0.workTypeRequests = worksiteWorkTypeRequests.map { $0.asExternalModel() }
            }
    }

    fileprivate var isFavorite: Bool { worksiteRoot.isFavorite(worksite) }
}

extension WorksiteRootRecord {
    internal func isFavorite(_ worksite: WorksiteRecord) -> Bool {
        isLocalModified ? worksite.isLocalFavorite : worksite.favoriteId != nil
    }
}

extension Array where Element == PopulatedTableDataWorksite {
    func filter(
        _ filters: CasesFilter,
        _ organizationAffiliates: Set<Int64>,
        _ location: CLLocationCoordinate2D?,
        _ locationAreaBounds: OrganizationLocationAreaBounds
    ) -> [PopulatedTableDataWorksite] {
        if (filters.isDefault) {
            return self
        }

        let filterByDistance = location != nil && filters.hasDistanceFilter
        let latitudeRad = location?.latitude.radians ?? 0.0
        let longitudeRad = location?.longitude.radians ?? 0.0
        return compactMap {
            filters.passes(
                $0.worksite,
                filterByDistance,
                latitudeRad,
                longitudeRad,
                organizationAffiliates,
                $0.worksiteFlags,
                $0.worksiteFormData,
                $0.workTypes,
                $0.isFavorite,
                locationAreaBounds
            ) ? $0 : nil
        }
    }
}

extension CasesFilter {
    internal func passes(
        _ worksite: WorksiteRecord,
        _ filterByDistance: Bool,
        _ latitudeRad: Double,
        _ longitudeRad: Double,
        _ organizationAffiliates: Set<Int64>,
        _ flags: [WorksiteFlagRecord],
        _ formData: [WorksiteFormDataRecord],
        _ workTypes: [WorkTypeRecord],
        _ isFavorite: Bool,
        _ locationAreaBounds: OrganizationLocationAreaBounds
    ) -> Bool {
        let distance = filterByDistance ? haversineDistance(
            latitudeRad, longitudeRad,
            worksite.latitude.radians, worksite.longitude.radians
        ).kmToMiles : 0.0
        if !passesFilter(
            worksite.svi ?? 0.0,
            worksite.updatedAt,
            distance
        ) {
            return false
        }

        if hasAdditionalFilters,
            !passesFilter(
                organizationAffiliates: organizationAffiliates,
                flags: flags,
                formData: formData,
                workTypes: workTypes,
                worksiteCreatedAt: worksite.createdAt,
                worksiteIsFavorite: isFavorite,
                worksiteReportedBy: worksite.reportedBy,
                worksiteUpdatedAt: worksite.updatedAt,
                worksiteLatitude: worksite.latitude,
                worksiteLongitude: worksite.longitude,
                locationAreaBounds: locationAreaBounds
        ) {
            return false
        }

        return true
    }
}
