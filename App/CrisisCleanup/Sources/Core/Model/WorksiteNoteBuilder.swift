// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension WorksiteNote {
	// A default style constructor for the .copy fn to use
	init(
		id: Int64,
		createdAt: Date,
		isSurvivor: Bool,
		note: String,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.id = id
		self.createdAt = createdAt
		self.isSurvivor = isSurvivor
		self.note = note
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> WorksiteNote {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toWorksiteNote()
	}

	struct Builder {
		var id: Int64
		var createdAt: Date
		var isSurvivor: Bool
		var note: String

		fileprivate init(original: WorksiteNote) {
			self.id = original.id
			self.createdAt = original.createdAt
			self.isSurvivor = original.isSurvivor
			self.note = original.note
		}

		fileprivate func toWorksiteNote() -> WorksiteNote {
			return WorksiteNote(
				id: id,
				createdAt: createdAt,
				isSurvivor: isSurvivor,
				note: note
			)
		}
	}
}
