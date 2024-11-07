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
		var syncAttempt: SyncAttempt
		var tableViewSortBy: WorksiteSortBy
		var shareLocationWithOrg: Bool

		fileprivate init(original: AppPreferences) {
			self.hideOnboarding = original.hideOnboarding
			self.hideGettingStartedVideo = original.hideGettingStartedVideo
			self.selectedIncidentId = original.selectedIncidentId
			self.languageKey = original.languageKey
			self.syncAttempt = original.syncAttempt
			self.tableViewSortBy = original.tableViewSortBy
			self.shareLocationWithOrg = original.shareLocationWithOrg
		}

		fileprivate func toAppPreferences() -> AppPreferences {
			return AppPreferences(
				hideOnboarding: hideOnboarding,
				hideGettingStartedVideo: hideGettingStartedVideo,
				selectedIncidentId: selectedIncidentId,
				languageKey: languageKey,
				syncAttempt: syncAttempt,
				tableViewSortBy: tableViewSortBy,
				shareLocationWithOrg: shareLocationWithOrg
			)
		}
	}
}
