// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension IncidentDataSyncStats {
	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> IncidentDataSyncStats {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toIncidentDataSyncStats()
	}

	struct Builder {
		var incidentId: Int64
		var syncStart: Date
		var dataCount: Int
		var pagedCount: Int
		var syncAttempt: SyncAttempt
		var appBuildVersionCode: Int64
		var stableModelVersion: Int

		fileprivate init(original: IncidentDataSyncStats) {
			self.incidentId = original.incidentId
			self.syncStart = original.syncStart
			self.dataCount = original.dataCount
			self.pagedCount = original.pagedCount
			self.syncAttempt = original.syncAttempt
			self.appBuildVersionCode = original.appBuildVersionCode
			self.stableModelVersion = original.stableModelVersion
		}

		fileprivate func toIncidentDataSyncStats() -> IncidentDataSyncStats {
			return IncidentDataSyncStats(
				incidentId: incidentId,
				syncStart: syncStart,
				dataCount: dataCount,
				pagedCount: pagedCount,
				syncAttempt: syncAttempt,
				appBuildVersionCode: appBuildVersionCode,
				stableModelVersion: stableModelVersion
			)
		}
	}
}
