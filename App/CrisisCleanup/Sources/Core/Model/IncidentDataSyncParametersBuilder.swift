// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension IncidentDataSyncParameters {
	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> IncidentDataSyncParameters {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toIncidentDataSyncParameters()
	}

	struct Builder {
		var incidentId: Int64
		var syncDataMeasures: SyncDataMeasure
		var boundedRegion: BoundedRegion?
		var boundedSyncedAt: Date

		fileprivate init(original: IncidentDataSyncParameters) {
			self.incidentId = original.incidentId
			self.syncDataMeasures = original.syncDataMeasures
			self.boundedRegion = original.boundedRegion
			self.boundedSyncedAt = original.boundedSyncedAt
		}

		fileprivate func toIncidentDataSyncParameters() -> IncidentDataSyncParameters {
			return IncidentDataSyncParameters(
				incidentId: incidentId,
				syncDataMeasures: syncDataMeasures,
				boundedRegion: boundedRegion,
				boundedSyncedAt: boundedSyncedAt
			)
		}
	}
}
