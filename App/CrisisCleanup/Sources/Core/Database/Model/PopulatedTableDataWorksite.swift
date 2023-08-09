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

    fileprivate var isFavorite: Bool {
        worksiteRoot.isLocalModified ? worksite.isLocalFavorite : worksite.favoriteId != nil
    }
}

extension Array where Element == PopulatedTableDataWorksite {
    func filter(
        _ filters: CasesFilter,
        _ organizationAffiliates: Set<Int64>,
        _ location: CLLocationCoordinate2D? = nil
    ) -> [PopulatedTableDataWorksite] {
        if (filters.isDefault) {
            return self
        }

        let filterByDistance = location != nil && filters.hasDistanceFilter
        let latitudeRad = location?.latitude.radians ?? 0.0
        let longitudeRad = location?.longitude.radians ?? 0.0

        return compactMap {
            var result: PopulatedTableDataWorksite? = $0

            let worksite = $0.worksite

            let distance = filterByDistance ? haversineDistance(
                latitudeRad, longitudeRad,
                worksite.latitude.radians, worksite.longitude.radians
            ).kmToMiles : 0.0
            if !filters.passesFilter(
                worksite.svi ?? 0.0,
                worksite.updatedAt,
                distance
            ) {
                result = nil
            } else if filters.hasAdditionalFilters,
                !filters.passesFilter(
                    organizationAffiliates: organizationAffiliates,
                    flags: $0.worksiteFlags,
                    formData: $0.worksiteFormData,
                    workTypes: $0.workTypes,
                    worksiteCreatedAt: worksite.createdAt,
                    worksiteIsFavorite: $0.isFavorite,
                    worksiteReportedBy: worksite.reportedBy,
                    worksiteUpdatedAt: worksite.updatedAt
            ) {
                result = nil
            }

            return result
        }
    }
}
