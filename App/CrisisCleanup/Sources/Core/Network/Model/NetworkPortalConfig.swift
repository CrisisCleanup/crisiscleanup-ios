public struct NetworkPortalConfig: Codable {
    let attr: NetworkClaimThreshold
}

public struct NetworkClaimThreshold: Codable {
    let workTypeCount: Int
    let workTypeClosedRatio: Float

    enum CodingKeys: String, CodingKey {
        case workTypeCount = "claimed_work_type_count_threshold",
             workTypeClosedRatio = "claimed_work_type_closed_ratio_threshold"
    }
}
