// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension WorkTypeRecord {
	// A default style constructor for the .copy fn to use
	init(
		id: Int64?,
		networkId: Int64,
		worksiteId: Int64,
		createdAt: Date?,
		orgClaim: Int64?,
		nextRecurAt: Date?,
		phase: Int?,
		recur: String?,
		status: String,
		workType: String,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.id = id
		self.networkId = networkId
		self.worksiteId = worksiteId
		self.createdAt = createdAt
		self.orgClaim = orgClaim
		self.nextRecurAt = nextRecurAt
		self.phase = phase
		self.recur = recur
		self.status = status
		self.workType = workType
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> WorkTypeRecord {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toWorkTypeRecord()
	}

	struct Builder {
		var id: Int64?
		var networkId: Int64
		var worksiteId: Int64
		var createdAt: Date?
		var orgClaim: Int64?
		var nextRecurAt: Date?
		var phase: Int?
		var recur: String?
		var status: String
		var workType: String

		fileprivate init(original: WorkTypeRecord) {
			self.id = original.id
			self.networkId = original.networkId
			self.worksiteId = original.worksiteId
			self.createdAt = original.createdAt
			self.orgClaim = original.orgClaim
			self.nextRecurAt = original.nextRecurAt
			self.phase = original.phase
			self.recur = original.recur
			self.status = original.status
			self.workType = original.workType
		}

		fileprivate func toWorkTypeRecord() -> WorkTypeRecord {
			return WorkTypeRecord(
				id: id,
				networkId: networkId,
				worksiteId: worksiteId,
				createdAt: createdAt,
				orgClaim: orgClaim,
				nextRecurAt: nextRecurAt,
				phase: phase,
				recur: recur,
				status: status,
				workType: workType
			)
		}
	}
}
