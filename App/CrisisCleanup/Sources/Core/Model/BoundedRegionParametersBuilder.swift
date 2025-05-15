// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension BoundedRegionParameters {
	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> BoundedRegionParameters {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toBoundedRegionParameters()
	}

	struct Builder {
		var isRegionMyLocation: Bool
		var regionLatitude: Double
		var regionLongitude: Double
		var regionRadiusMiles: Double

		fileprivate init(original: BoundedRegionParameters) {
			self.isRegionMyLocation = original.isRegionMyLocation
			self.regionLatitude = original.regionLatitude
			self.regionLongitude = original.regionLongitude
			self.regionRadiusMiles = original.regionRadiusMiles
		}

		fileprivate func toBoundedRegionParameters() -> BoundedRegionParameters {
			return BoundedRegionParameters(
				isRegionMyLocation: isRegionMyLocation,
				regionLatitude: regionLatitude,
				regionLongitude: regionLongitude,
				regionRadiusMiles: regionRadiusMiles
			)
		}
	}
}
