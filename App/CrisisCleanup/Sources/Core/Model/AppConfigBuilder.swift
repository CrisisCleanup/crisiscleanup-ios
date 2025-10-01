// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension AppConfig {
    // struct copy, lets you overwrite specific variables retaining the value of the rest
    // using a closure to set the new values for the copy of the struct
    func copy(build: (inout Builder) -> Void) -> AppConfig {
        var builder = Builder(original: self)
        build(&builder)
        return builder.toAppConfigData()
    }

    struct Builder {
        var claimCountThreshold: Int
        var closedClaimRatioThreshold: Float

        fileprivate init(original: AppConfig) {
            self.claimCountThreshold = original.claimCountThreshold
            self.closedClaimRatioThreshold = original.closedClaimRatioThreshold
        }

        fileprivate func toAppConfigData() -> AppConfig {
            return AppConfig(
                claimCountThreshold: claimCountThreshold,
                closedClaimRatioThreshold: closedClaimRatioThreshold
            )
        }
    }
}
