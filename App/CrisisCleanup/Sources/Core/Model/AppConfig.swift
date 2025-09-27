// sourcery: copyBuilder
public struct AppConfig: Codable {
    let claimCountThreshold: Int
    let closedClaimRatioThreshold: Float

    init(
        claimCountThreshold: Int = 0,
        closedClaimRatioThreshold: Float = 0.0,
    ) {
        self.claimCountThreshold = claimCountThreshold
        self.closedClaimRatioThreshold = closedClaimRatioThreshold
    }
}
