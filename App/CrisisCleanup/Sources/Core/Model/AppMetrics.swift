import Foundation

public struct MinSupportedAppVersion: Codable {
    let minBuild: Int64
    let title: String?
    let message: String
    let link: String?
}

let supportedAppVersion = MinSupportedAppVersion(
    minBuild: 0,
    title: nil,
    message: "",
    link: nil
)

// sourcery: copyBuilder, skipCopyInit
public struct AppMetrics: Codable {
    let openBuild: Int64
    let openTimestamp: Date
    let minSupportedVersion: MinSupportedAppVersion
    let installBuild: Int64

    init(
        openBuild: Int64 = 0,
        openTimestamp: Date = Date.epochZero,
        minSupportedVersion: MinSupportedAppVersion? = nil,
        installBuild: Int64? = nil,
    ) {
        self.openBuild = openBuild
        self.openTimestamp = openTimestamp
        self.minSupportedVersion = minSupportedVersion ?? supportedAppVersion
        self.installBuild = installBuild ?? 0
    }
}
