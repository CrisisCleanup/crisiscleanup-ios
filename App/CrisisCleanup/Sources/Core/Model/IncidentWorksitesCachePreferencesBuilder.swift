// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension IncidentWorksitesCachePreferences {
    // struct copy, lets you overwrite specific variables retaining the value of the rest
    // using a closure to set the new values for the copy of the struct
    func copy(build: (inout Builder) -> Void) -> IncidentWorksitesCachePreferences {
        var builder = Builder(original: self)
        build(&builder)
        return builder.toIncidentWorksitesCachePreferences()
    }

    struct Builder {
        var isPaused: Bool
        var isRegionBounded: Bool
        var boundedRegionParameters: BoundedRegionParameters
        var lastReconciled: Date?

        fileprivate init(original: IncidentWorksitesCachePreferences) {
            self.isPaused = original.isPaused
            self.isRegionBounded = original.isRegionBounded
            self.boundedRegionParameters = original.boundedRegionParameters
            self.lastReconciled = original.lastReconciled
        }

        fileprivate func toIncidentWorksitesCachePreferences() -> IncidentWorksitesCachePreferences {
            return IncidentWorksitesCachePreferences(
                isPaused: isPaused,
                isRegionBounded: isRegionBounded,
                boundedRegionParameters: boundedRegionParameters,
                lastReconciled: lastReconciled,
            )
        }
    }
}
