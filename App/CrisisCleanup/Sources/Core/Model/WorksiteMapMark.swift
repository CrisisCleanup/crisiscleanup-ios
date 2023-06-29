public struct WorksiteMapMark: Equatable {
    let id: Int64
    let latitude: Double
    let longitude: Double
    let statusClaim: WorkTypeStatusClaim
    let workType: WorkTypeType
    let workTypeCount: Int
    let isFavorite: Bool
    let isHighPriority: Bool

    init(
        id: Int64,
        latitude: Double,
        longitude: Double,
        statusClaim: WorkTypeStatusClaim,
        workType: WorkTypeType,
        workTypeCount: Int,
        isFavorite: Bool = false,
        isHighPriority: Bool = false
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.statusClaim = statusClaim
        self.workType = workType
        self.workTypeCount = workTypeCount
        self.isFavorite = isFavorite
        self.isHighPriority = isHighPriority
    }
}
