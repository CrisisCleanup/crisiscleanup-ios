// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension IncidentsData {
	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> IncidentsData {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toIncidentsData()
	}

	struct Builder {
		var isLoading: Bool
		var selected: Incident
		var incidents: [Incident]

		fileprivate init(original: IncidentsData) {
			self.isLoading = original.isLoading
			self.selected = original.selected
			self.incidents = original.incidents
		}

		fileprivate func toIncidentsData() -> IncidentsData {
			return IncidentsData(
				isLoading: isLoading,
				selected: selected,
				incidents: incidents
			)
		}
	}
}
