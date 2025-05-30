// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension IncidentDataSyncParameters.BoundedRegion {
	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> IncidentDataSyncParameters.BoundedRegion {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toBoundedRegion()
	}

	struct Builder {
		var latitude: Double
		var longitude: Double
		var radius: Double

		fileprivate init(original: IncidentDataSyncParameters.BoundedRegion) {
			self.latitude = original.latitude
			self.longitude = original.longitude
			self.radius = original.radius
		}

		fileprivate func toBoundedRegion() -> IncidentDataSyncParameters.BoundedRegion {
			return IncidentDataSyncParameters.BoundedRegion(
				latitude: latitude,
				longitude: longitude,
				radius: radius
			)
		}
	}
}
