public struct WorksiteMapMark: Equatable {
    let id: Int64
    // Added in iOS due to specific map platform functionality relating to managing annotations
    let incidentId: Int64
    let latitude: Double
    let longitude: Double
    let statusClaim: WorkTypeStatusClaim
    let workType: WorkTypeType
    let workTypeCount: Int
    let isFavorite: Bool
    let isHighPriority: Bool
    let isDuplicate: Bool
    let isFilteredOut: Bool
    let hasPhotos: Bool

    init(
        id: Int64,
        incidentId: Int64,
        latitude: Double,
        longitude: Double,
        statusClaim: WorkTypeStatusClaim,
        workType: WorkTypeType,
        workTypeCount: Int,
        isFavorite: Bool = false,
        isHighPriority: Bool = false,
        isDuplicate: Bool = false,
        isFilteredOut: Bool = false,
        hasPhotos: Bool = false,
    ) {
        self.id = id
        self.incidentId = incidentId
        self.latitude = latitude
        self.longitude = longitude
        self.statusClaim = statusClaim
        self.workType = workType
        self.workTypeCount = workTypeCount
        self.isFavorite = isFavorite
        self.isHighPriority = isHighPriority
        self.isDuplicate = isDuplicate
        self.isFilteredOut = isFilteredOut
        self.hasPhotos = hasPhotos
    }
}
