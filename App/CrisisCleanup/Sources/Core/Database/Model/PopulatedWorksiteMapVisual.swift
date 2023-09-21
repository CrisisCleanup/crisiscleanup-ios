import CoreLocation

extension Array where Element == PopulatedWorksiteMapVisual {
    func filterMapVisuals(
        _ filters: CasesFilter,
        _ organizationAffiliates: Set<Int64>,
        _ locationAreaBounds: OrganizationLocationAreaBounds,
        _ location: CLLocation? = nil
    ) throws -> [WorksiteMapMark] {
        if filters.isDefault {
            return map { $0.asExternalModel() }
        }

        try Task.checkCancellation()

        let filterByDistance = location != nil && filters.hasDistanceFilter
        let coordinates = location?.coordinate
        let latRad = filterByDistance ? coordinates!.latitude.radians : 0.0
        let lngRad = filterByDistance ? coordinates!.longitude.radians : 0.0
        return compactMap {
            let worksite = $0.worksite
            let distance = filterByDistance ? haversineDistance(
                latRad, lngRad,
                worksite.latitude.radians, worksite.longitude.radians
            ).kmToMiles : 0.0
            if !filters.passesFilter(
                worksite.svi,
                worksite.updatedAt,
                distance
            ) {
                return nil
            }

            let isFilteredOut = filters.hasAdditionalFilters &&
            !filters.passesFilter(
                organizationAffiliates: organizationAffiliates,
                flags: $0.worksiteFlags,
                formData: $0.worksiteFormData,
                workTypes: $0.workTypes,
                worksiteCreatedAt: worksite.createdAt,
                worksiteIsFavorite: $0.isFavorite,
                worksiteReportedBy: worksite.reportedBy,
                worksiteUpdatedAt: worksite.updatedAt,
                worksiteLatitude: worksite.latitude,
                worksiteLongitude: worksite.longitude,
                locationAreaBounds: locationAreaBounds
            )
            return $0.asExternalModel(isFilteredOut)
        }
    }
}

extension PopulatedWorksiteMapVisual {
    fileprivate var isFavorite: Bool {
        isLocalModified ? worksite.isLocalFavorite : worksite.favoriteId != nil
    }
}
