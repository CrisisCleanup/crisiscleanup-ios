// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension WorksiteFlagRecord {
	// A default style constructor for the .copy fn to use
	init(
		id: Int64?,
		networkId: Int64,
		worksiteId: Int64,
		action: String?,
		createdAt: Date,
		isHighPriority: Bool?,
		notes: String?,
		reasonT: String,
		requestedAction: String?,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.id = id
		self.networkId = networkId
		self.worksiteId = worksiteId
		self.action = action
		self.createdAt = createdAt
		self.isHighPriority = isHighPriority
		self.notes = notes
		self.reasonT = reasonT
		self.requestedAction = requestedAction
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> WorksiteFlagRecord {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toWorksiteFlagRecord()
	}

	struct Builder {
		var id: Int64?
		var networkId: Int64
		var worksiteId: Int64
		var action: String?
		var createdAt: Date
		var isHighPriority: Bool?
		var notes: String?
		var reasonT: String
		var requestedAction: String?

		fileprivate init(original: WorksiteFlagRecord) {
			self.id = original.id
			self.networkId = original.networkId
			self.worksiteId = original.worksiteId
			self.action = original.action
			self.createdAt = original.createdAt
			self.isHighPriority = original.isHighPriority
			self.notes = original.notes
			self.reasonT = original.reasonT
			self.requestedAction = original.requestedAction
		}

		fileprivate func toWorksiteFlagRecord() -> WorksiteFlagRecord {
			return WorksiteFlagRecord(
				id: id,
				networkId: networkId,
				worksiteId: worksiteId,
				action: action,
				createdAt: createdAt,
				isHighPriority: isHighPriority,
				notes: notes,
				reasonT: reasonT,
				requestedAction: requestedAction
			)
		}
	}
}
