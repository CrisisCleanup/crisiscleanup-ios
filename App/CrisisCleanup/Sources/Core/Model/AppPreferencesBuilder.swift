// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension AppPreferences {
    // struct copy, lets you overwrite specific variables retaining the value of the rest
    // using a closure to set the new values for the copy of the struct
    func copy(build: (inout Builder) -> Void) -> AppPreferences {
        var builder = Builder(original: self)
        build(&builder)
        return builder.toAppPreferences()
    }

    struct Builder {
        var hideOnboarding: Bool
        var hideGettingStartedVideo: Bool
        var selectedIncidentId: Int64
        var languageKey: String
        var tableViewSortBy: WorksiteSortBy
        var shareLocationWithOrg: Bool
        var notifyDataSyncProgress: Bool?
        var casesMapBounds: IncidentCoordinateBounds?
        var teamMapBounds: IncidentCoordinateBounds?
        var isWorkScreenTableView: Bool?
        var isMapSatelliteView: Bool?

        fileprivate init(original: AppPreferences) {
            self.hideOnboarding = original.hideOnboarding
            self.hideGettingStartedVideo = original.hideGettingStartedVideo
            self.selectedIncidentId = original.selectedIncidentId
            self.languageKey = original.languageKey
            self.tableViewSortBy = original.tableViewSortBy
            self.shareLocationWithOrg = original.shareLocationWithOrg
            self.notifyDataSyncProgress = original.notifyDataSyncProgress
            self.casesMapBounds = original.casesMapBounds
            self.teamMapBounds = original.teamMapBounds
            self.isWorkScreenTableView = original.isWorkScreenTableView
            self.isMapSatelliteView = original.isMapSatelliteView
        }

        fileprivate func toAppPreferences() -> AppPreferences {
            return AppPreferences(
                hideOnboarding: hideOnboarding,
                hideGettingStartedVideo: hideGettingStartedVideo,
                selectedIncidentId: selectedIncidentId,
                languageKey: languageKey,
                tableViewSortBy: tableViewSortBy,
                shareLocationWithOrg: shareLocationWithOrg,
                notifyDataSyncProgress: notifyDataSyncProgress,
                casesMapBounds: casesMapBounds,
                teamMapBounds: teamMapBounds,
                isWorkScreenTableView: isWorkScreenTableView,
                isMapSatelliteView: isMapSatelliteView,
            )
        }
    }
}
