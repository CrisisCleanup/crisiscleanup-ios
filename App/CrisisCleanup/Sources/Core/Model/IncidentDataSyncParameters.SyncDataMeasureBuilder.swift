// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension IncidentDataSyncParameters.SyncDataMeasure {
	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> IncidentDataSyncParameters.SyncDataMeasure {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toSyncDataMeasure()
	}

	struct Builder {
        var core: IncidentDataSyncParameters.SyncTimeMarker
        var additional: IncidentDataSyncParameters.SyncTimeMarker

		fileprivate init(original: IncidentDataSyncParameters.SyncDataMeasure) {
			self.core = original.core
			self.additional = original.additional
		}

		fileprivate func toSyncDataMeasure() -> IncidentDataSyncParameters.SyncDataMeasure {
			return IncidentDataSyncParameters.SyncDataMeasure(
				core: core,
				additional: additional
			)
		}
	}
}
