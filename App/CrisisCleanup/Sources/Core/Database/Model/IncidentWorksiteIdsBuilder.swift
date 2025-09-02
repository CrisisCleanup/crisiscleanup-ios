// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension IncidentWorksiteIds {
	// A default style constructor for the .copy fn to use
	init(
		incidentId: Int64,
		id: Int64,
		networkId: Int64,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.incidentId = incidentId
		self.id = id
		self.networkId = networkId
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> IncidentWorksiteIds {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toIncidentWorksiteIds()
	}

	struct Builder {
		var incidentId: Int64
		var id: Int64
		var networkId: Int64

		fileprivate init(original: IncidentWorksiteIds) {
			self.incidentId = original.incidentId
			self.id = original.id
			self.networkId = original.networkId
		}

		fileprivate func toIncidentWorksiteIds() -> IncidentWorksiteIds {
			return IncidentWorksiteIds(
				incidentId: incidentId,
				id: id,
				networkId: networkId
			)
		}
	}
}
