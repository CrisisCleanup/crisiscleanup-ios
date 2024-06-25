// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension IncidentRecord {
	// A default style constructor for the .copy fn to use
	init(
		id: Int64,
		startAt: Date,
		name: String,
		shortName: String,
		caseLabel: String,
		type: String,
		activePhoneNumber: String?,
		turnOnRelease: Bool,
		isArchived: Bool,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.id = id
		self.startAt = startAt
		self.name = name
		self.shortName = shortName
		self.caseLabel = caseLabel
		self.type = type
		self.activePhoneNumber = activePhoneNumber
		self.turnOnRelease = turnOnRelease
		self.isArchived = isArchived
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> IncidentRecord {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toIncidentRecord()
	}

	struct Builder {
		var id: Int64
		var startAt: Date
		var name: String
		var shortName: String
		var caseLabel: String
		var type: String
		var activePhoneNumber: String?
		var turnOnRelease: Bool
		var isArchived: Bool

		fileprivate init(original: IncidentRecord) {
			self.id = original.id
			self.startAt = original.startAt
			self.name = original.name
			self.shortName = original.shortName
			self.caseLabel = original.caseLabel
			self.type = original.type
			self.activePhoneNumber = original.activePhoneNumber
			self.turnOnRelease = original.turnOnRelease
			self.isArchived = original.isArchived
		}

		fileprivate func toIncidentRecord() -> IncidentRecord {
			return IncidentRecord(
				id: id,
				startAt: startAt,
				name: name,
				shortName: shortName,
				caseLabel: caseLabel,
				type: type,
				activePhoneNumber: activePhoneNumber,
				turnOnRelease: turnOnRelease,
				isArchived: isArchived
			)
		}
	}
}
