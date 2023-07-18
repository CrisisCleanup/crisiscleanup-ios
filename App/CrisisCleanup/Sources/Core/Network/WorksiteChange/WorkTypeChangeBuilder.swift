// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension WorkTypeChange {
	// A default style constructor for the .copy fn to use
	init(
		localId: Int64,
		networkId: Int64,
		workType: WorkTypeSnapshot.WorkType,
		changedAt: Date,
		isClaimChange: Bool,
		isStatusChange: Bool,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.localId = localId
		self.networkId = networkId
		self.workType = workType
		self.changedAt = changedAt
		self.isClaimChange = isClaimChange
		self.isStatusChange = isStatusChange
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> WorkTypeChange {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toWorkTypeChange()
	}

	struct Builder {
		var localId: Int64
		var networkId: Int64
		var workType: WorkTypeSnapshot.WorkType
		var changedAt: Date
		var isClaimChange: Bool
		var isStatusChange: Bool

		fileprivate init(original: WorkTypeChange) {
			self.localId = original.localId
			self.networkId = original.networkId
			self.workType = original.workType
			self.changedAt = original.changedAt
			self.isClaimChange = original.isClaimChange
			self.isStatusChange = original.isStatusChange
		}

		fileprivate func toWorkTypeChange() -> WorkTypeChange {
			return WorkTypeChange(
				localId: localId,
				networkId: networkId,
				workType: workType,
				changedAt: changedAt,
				isClaimChange: isClaimChange,
				isStatusChange: isStatusChange
			)
		}
	}
}
