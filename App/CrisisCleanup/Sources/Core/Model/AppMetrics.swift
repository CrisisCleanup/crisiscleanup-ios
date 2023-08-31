import Foundation

public struct MinSupportedAppVersion: Codable {
    let minBuild: Int64
    let title: String?
    let message: String
    let link: String?
}

let supportedAppVersion = MinSupportedAppVersion(
    minBuild: Int64.max,
    title: nil,
    message: "",
    link: nil
)

// sourcery: copyBuilder, skipCopyInit
public struct AppMetrics: Codable {
    let openBuild: Int64
    let openTimestamp: Date
    let minSupportedVersion: MinSupportedAppVersion

    init(
        openBuild: Int64 = 0,
        openTimestamp: Date = Date.init(timeIntervalSince1970: 0),
        minSupportedVersion: MinSupportedAppVersion? = nil
    ) {
        self.openBuild = openBuild
        self.openTimestamp = openTimestamp
        self.minSupportedVersion = minSupportedVersion ?? supportedAppVersion
    }
}
