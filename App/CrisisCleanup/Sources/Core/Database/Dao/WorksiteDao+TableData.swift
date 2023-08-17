import CoreLocation
import GRDB

extension WorksiteDao {
    func loadTableWorksites(
        incidentId: Int64,
        filters: CasesFilter,
        organizationAffiliates: Set<Int64>,
        sortBy: WorksiteSortBy,
        coordinates: CLLocationCoordinate2D?,
        searchRadius: Double,
        count: Int,
        locationAreaBounds: OrganizationLocationAreaBounds
    ) async throws -> [PopulatedTableDataWorksite] {
        if sortBy == .nearest {
            if let coordinates = coordinates {
                return try await getNearestTableWorksites(
                    incidentId: incidentId,
                    count: count,
                    searchRadius: searchRadius,
                    filters: filters,
                    organizationAffiliates: organizationAffiliates,
                    coordinates: coordinates,
                    locationAreaBounds: locationAreaBounds
                )
            }
            return []
        }
        return try await getFilteredTableWorksites(
            sortBy: sortBy,
            incidentId: incidentId,
            count: count,
            filters: filters,
            organizationAffiliates: organizationAffiliates,
            coordinates: coordinates,
            locationAreaBounds: locationAreaBounds
        )
    }

    private func getTableWorksites(_ incidentId: Int64) throws -> [PopulatedTableDataWorksite] {
        try reader.read { db in
            let request = WorksiteRootRecord
                .all()
                .including(required: WorksiteRootRecord.worksite)
                .including(all: WorksiteRootRecord.worksiteFlags)
                .including(all: WorksiteRootRecord.worksiteFormData)
                .including(all: WorksiteRootRecord.workTypes)
                .including(all: WorksiteRootRecord.worksiteWorkTypeRequests)
                .byIncidentId(incidentId)
                .asRequest(of: PopulatedTableDataWorksite.self)
            return try request.fetchAll(db)
        }
    }

    private func getNearestTableWorksites(
        incidentId: Int64,
        count: Int,
        searchRadius: Double,
        filters: CasesFilter,
        organizationAffiliates: Set<Int64>,
        coordinates: CLLocationCoordinate2D,
        locationAreaBounds: OrganizationLocationAreaBounds
    ) async throws -> [PopulatedTableDataWorksite] {
        let strideCount = 100

        let latitude = coordinates.latitude
        let longitude = coordinates.longitude

        let worksiteCount = try getWorksitesCount(incidentId)

        let boundedWorksites: [PopulatedTableDataWorksite]
        if worksiteCount <= count {
            boundedWorksites = try getTableWorksites(incidentId).filter(
                filters,
                organizationAffiliates,
                coordinates,
                locationAreaBounds
            )
        } else {
            let r = max(searchRadius, 24.0)
            let latitudeRadialDegrees = r / 69.0
            let longitudeRadialDegrees = r / 54.6
            let areaBounds = SwNeBounds(
                south: max(latitude - latitudeRadialDegrees, -90.0),
                north: min(latitude + latitudeRadialDegrees, 90.0),
                west: max(longitude - longitudeRadialDegrees, -180.0),
                east: min(longitude + longitudeRadialDegrees, 180.0)
            )
            let boundedWorksiteRectCount = try getWorksitesCount(
                incidentId,
                south: areaBounds.south,
                north: areaBounds.north,
                west: areaBounds.west,
                east: areaBounds.east
            )
            let gridQuery = CoordinateGridQuery(areaBounds)
            let targetBucketCount = 10
            gridQuery.initializeGrid(
                boundedWorksiteRectCount,
                targetGridSize: targetBucketCount
            )

            let maxQueryCount = Int(Double(count) * 1.5)
            boundedWorksites = try await loadBoundedTableWorksites(
                incidentId: incidentId,
                maxLoadCount: maxQueryCount,
                remainingBounds: gridQuery.getSwNeGridCells(),
                filters: filters,
                organizationAffiliates: organizationAffiliates,
                coordinates: coordinates,
                locationAreaBounds: locationAreaBounds
            )
        }

        let latRad = latitude.radians
        let lngRad = longitude.radians
        var withDistance = [(PopulatedTableDataWorksite, Double)]()
        for i in boundedWorksites.indices {
            let worksite = boundedWorksites[i]
            let entity = worksite.worksite
            let distance = haversineDistance(
                latRad, lngRad,
                entity.latitude.radians, entity.longitude.radians
            )
            withDistance.append((worksite, distance))
            if (i % strideCount == 0) {
                try Task.checkCancellation()
            }
        }
        return withDistance
            .sorted(by: { a, b in a.1 < b.1 })
            .map { $0.0 }
    }

    private func getFilteredTableWorksites(
        sortBy: WorksiteSortBy,
        incidentId: Int64,
        count: Int,
        filters: CasesFilter,
        organizationAffiliates: Set<Int64>,
        coordinates: CLLocationCoordinate2D?,
        locationAreaBounds: OrganizationLocationAreaBounds
    ) async throws -> [PopulatedTableDataWorksite] {
        let queryCount = max(count, 100)
        var queryOffset = 0

        var worksiteData = [PopulatedTableDataWorksite]()
        while worksiteData.count < queryCount {
            let records = try getTableWorksites(
                incidentId,
                sortBy,
                queryCount,
                offset: queryOffset
            )

            try Task.checkCancellation()

            let filteredRecords = records.filter(
                filters,
                organizationAffiliates,
                coordinates,
                locationAreaBounds
            )

            try Task.checkCancellation()

            worksiteData += filteredRecords

            queryOffset += queryCount

            if sortBy == .nearest || records.count < queryCount {
                break
            }
        }

        return worksiteData
    }

    private func loadBoundedTableWorksites(
        incidentId: Int64,
        maxLoadCount: Int,
        remainingBounds: [SwNeBounds],
        filters: CasesFilter,
        organizationAffiliates: Set<Int64>,
        coordinates: CLLocationCoordinate2D,
        locationAreaBounds: OrganizationLocationAreaBounds
    ) async throws -> [PopulatedTableDataWorksite] {
        var loadedWorksites = [PopulatedTableDataWorksite]()

        var boundsIndex = 0
        while (boundsIndex < remainingBounds.count) {
            var records: [PopulatedTableDataWorksite]
            let bounds = remainingBounds[boundsIndex]
            boundsIndex += 1
            records = try getTableWorksitesInBounds(
                incidentId,
                south: bounds.south,
                north: bounds.north,
                west: bounds.west,
                east: bounds.east
            )

            try Task.checkCancellation()

            let filteredRecords = records.filter(
                filters,
                organizationAffiliates,
                coordinates,
                locationAreaBounds
            )

            try Task.checkCancellation()

            loadedWorksites += filteredRecords

            if (loadedWorksites.count > maxLoadCount) {
                break
            }
        }

        return loadedWorksites
    }

    private func getTableWorksitesInBounds(
        _ incidentId: Int64,
        south: Double,
        north: Double,
        west: Double,
        east: Double
    ) throws -> [PopulatedTableDataWorksite] {
        try reader.read { db in
            let worksiteAlias = TableAlias(name: "w")
            let worksiteRecord = WorksiteRootRecord.worksite
                .aliased(worksiteAlias)
            return try WorksiteRootRecord
                .all()
                .byIncidentId(incidentId)
                .including(required: worksiteRecord
                    .byBounds(
                        alias: worksiteAlias,
                        south: south,
                        north: north,
                        west: west,
                        east: east
                    )
                        .orderByUpdatedAtDescIdDesc()
                )
                .including(all: WorksiteRootRecord.worksiteFlags)
                .including(all: WorksiteRootRecord.worksiteFormData)
                .including(all: WorksiteRootRecord.workTypes)
                .including(all: WorksiteRootRecord.worksiteWorkTypeRequests)
                .asRequest(of: PopulatedTableDataWorksite.self)
                .fetchAll(db)
        }
    }

    private func getTableWorksites(
        _ incidentId: Int64,
        _ sortBy: WorksiteSortBy,
        _ limit: Int,
        offset: Int
    ) throws -> [PopulatedTableDataWorksite] {
        try reader.read { db in
            let worksiteAlias = TableAlias(name: "w")
            var record = WorksiteRootRecord.worksite
                .aliased(worksiteAlias)

            switch sortBy {
            case .name: record = record.orderByName()
            case .city: record = record.orderByCity()
            case .countyParish: record = record.orderByCounty()
            default: record = record.orderByCaseNumber()
            }

            return try WorksiteRootRecord
                .all()
                .byIncidentId(incidentId)
                .including(required: record)
                .including(all: WorksiteRootRecord.worksiteFlags)
                .including(all: WorksiteRootRecord.worksiteFormData)
                .including(all: WorksiteRootRecord.workTypes)
                .including(all: WorksiteRootRecord.worksiteWorkTypeRequests)
                .limit(limit, offset: offset)
                .asRequest(of: PopulatedTableDataWorksite.self)
                .fetchAll(db)
        }
    }
}
