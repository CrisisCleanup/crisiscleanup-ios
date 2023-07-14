// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension WorkTypeRequestRecord {
	// A default style constructor for the .copy fn to use
	init(
		id: Int64?,
		networkId: Int64,
		worksiteId: Int64,
		workType: String,
		reason: String,
		byOrg: Int64,
		toOrg: Int64,
		createdAt: Date,
		approvedAt: Date?,
		rejectedAt: Date?,
		approvedRejectedReason: String,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.id = id
		self.networkId = networkId
		self.worksiteId = worksiteId
		self.workType = workType
		self.reason = reason
		self.byOrg = byOrg
		self.toOrg = toOrg
		self.createdAt = createdAt
		self.approvedAt = approvedAt
		self.rejectedAt = rejectedAt
		self.approvedRejectedReason = approvedRejectedReason
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> WorkTypeRequestRecord {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toWorkTypeRequestRecord()
	}

	struct Builder {
		var id: Int64?
		var networkId: Int64
		var worksiteId: Int64
		var workType: String
		var reason: String
		var byOrg: Int64
		var toOrg: Int64
		var createdAt: Date
		var approvedAt: Date?
		var rejectedAt: Date?
		var approvedRejectedReason: String

		fileprivate init(original: WorkTypeRequestRecord) {
			self.id = original.id
			self.networkId = original.networkId
			self.worksiteId = original.worksiteId
			self.workType = original.workType
			self.reason = original.reason
			self.byOrg = original.byOrg
			self.toOrg = original.toOrg
			self.createdAt = original.createdAt
			self.approvedAt = original.approvedAt
			self.rejectedAt = original.rejectedAt
			self.approvedRejectedReason = original.approvedRejectedReason
		}

		fileprivate func toWorkTypeRequestRecord() -> WorkTypeRequestRecord {
			return WorkTypeRequestRecord(
				id: id,
				networkId: networkId,
				worksiteId: worksiteId,
				workType: workType,
				reason: reason,
				byOrg: byOrg,
				toOrg: toOrg,
				createdAt: createdAt,
				approvedAt: approvedAt,
				rejectedAt: rejectedAt,
				approvedRejectedReason: approvedRejectedReason
			)
		}
	}
}
