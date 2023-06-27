// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension WorksiteNoteRecord {
	// A default style constructor for the .copy fn to use
	init(
		id: Int64?,
		localGlobalUuid: String,
		networkId: Int64,
		worksiteId: Int64,
		createdAt: Date,
		isSurvivor: Bool,
		note: String,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.id = id
		self.localGlobalUuid = localGlobalUuid
		self.networkId = networkId
		self.worksiteId = worksiteId
		self.createdAt = createdAt
		self.isSurvivor = isSurvivor
		self.note = note
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> WorksiteNoteRecord {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toWorksiteNoteRecord()
	}

	struct Builder {
		var id: Int64?
		var localGlobalUuid: String
		var networkId: Int64
		var worksiteId: Int64
		var createdAt: Date
		var isSurvivor: Bool
		var note: String

		fileprivate init(original: WorksiteNoteRecord) {
			self.id = original.id
			self.localGlobalUuid = original.localGlobalUuid
			self.networkId = original.networkId
			self.worksiteId = original.worksiteId
			self.createdAt = original.createdAt
			self.isSurvivor = original.isSurvivor
			self.note = original.note
		}

		fileprivate func toWorksiteNoteRecord() -> WorksiteNoteRecord {
			return WorksiteNoteRecord(
				id: id,
				localGlobalUuid: localGlobalUuid,
				networkId: networkId,
				worksiteId: worksiteId,
				createdAt: createdAt,
				isSurvivor: isSurvivor,
				note: note
			)
		}
	}
}
