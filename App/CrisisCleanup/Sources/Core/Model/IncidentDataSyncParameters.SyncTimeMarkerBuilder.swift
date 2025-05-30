// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension IncidentDataSyncParameters.SyncTimeMarker {
	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> IncidentDataSyncParameters.SyncTimeMarker {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toSyncTimeMarker()
	}

	struct Builder {
		var before: Date
		var after: Date

		fileprivate init(original: IncidentDataSyncParameters.SyncTimeMarker) {
			self.before = original.before
			self.after = original.after
		}

		fileprivate func toSyncTimeMarker() -> IncidentDataSyncParameters.SyncTimeMarker {
			return IncidentDataSyncParameters.SyncTimeMarker(
				before: before,
				after: after
			)
		}
	}
}
