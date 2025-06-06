// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension Incident {
	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> Incident {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toIncident()
	}

	struct Builder {
		var id: Int64
		var name: String
		var shortName: String
		var caseLabel: String
		var locationIds: [Int64]
		var activePhoneNumbers: [String]
		var formFields: [IncidentFormField]
		var turnOnRelease: Bool
		var disasterLiteral: String
		var startAt: Date?

		fileprivate init(original: Incident) {
			self.id = original.id
			self.name = original.name
			self.shortName = original.shortName
			self.caseLabel = original.caseLabel
			self.locationIds = original.locationIds
			self.activePhoneNumbers = original.activePhoneNumbers
			self.formFields = original.formFields
			self.turnOnRelease = original.turnOnRelease
			self.disasterLiteral = original.disasterLiteral
			self.startAt = original.startAt
		}

		fileprivate func toIncident() -> Incident {
			return Incident(
				id: id,
				name: name,
				shortName: shortName,
				caseLabel: caseLabel,
				locationIds: locationIds,
				activePhoneNumbers: activePhoneNumbers,
				formFields: formFields,
				turnOnRelease: turnOnRelease,
				disasterLiteral: disasterLiteral,
				startAt: startAt
			)
		}
	}
}
