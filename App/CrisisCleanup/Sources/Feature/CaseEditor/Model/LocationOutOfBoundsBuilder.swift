// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension LocationOutOfBounds {
	// A default style constructor for the .copy fn to use
	init(
		incident: Incident,
		coordinates: LatLng,
		address: LocationAddress?,
		recentIncident: Incident?,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.incident = incident
		self.coordinates = coordinates
		self.address = address
		self.recentIncident = recentIncident
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> LocationOutOfBounds {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toLocationOutOfBounds()
	}

	struct Builder {
		var incident: Incident
		var coordinates: LatLng
		var address: LocationAddress?
		var recentIncident: Incident?

		fileprivate init(original: LocationOutOfBounds) {
			self.incident = original.incident
			self.coordinates = original.coordinates
			self.address = original.address
			self.recentIncident = original.recentIncident
		}

		fileprivate func toLocationOutOfBounds() -> LocationOutOfBounds {
			return LocationOutOfBounds(
				incident: incident,
				coordinates: coordinates,
				address: address,
				recentIncident: recentIncident
			)
		}
	}
}
