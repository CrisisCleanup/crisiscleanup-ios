import CoreLocation
import GRDB

struct PopulatedFilterDataWorksite: Equatable, Decodable, FetchableRecord {
    let worksiteRoot: WorksiteRootRecord
    let worksite: WorksiteRecord
    let workTypes: [WorkTypeRecord]
    let worksiteFormData: [WorksiteFormDataRecord]
    let worksiteFlags: [WorksiteFlagRecord]

    func asExternalModel() -> Worksite {
        Worksite.from(worksiteRoot, worksite, workTypes)
    }

    fileprivate var isFavorite: Bool { worksiteRoot.isFavorite(worksite) }
}

extension Array where Element == PopulatedFilterDataWorksite {
    func filter(
        _ filters: CasesFilter,
        _ organizationAffiliates: Set<Int64>,
        _ locationLatitudeRad: Double?,
        _ locationLongitudeRad: Double?,
        _ locationAreaBounds: OrganizationLocationAreaBounds
    ) -> [PopulatedFilterDataWorksite] {
        if (filters.isDefault) {
            return self
        }

        let filterByDistance = locationLatitudeRad != nil &&
        locationLongitudeRad != nil &&
        filters.hasDistanceFilter
        let latitudeRad = locationLatitudeRad ?? 0.0
        let longitudeRad = locationLongitudeRad ?? 0.0
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
