// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension FlagSnapshot.Flag {
	// A default style constructor for the .copy fn to use
	init(
		id: Int64,
		action: String,
		createdAt: Date,
		isHighPriority: Bool,
		notes: String,
		reasonT: String,
		reason: String,
		requestedAction: String,
		involvesMyOrg: Bool?,
		haveContactedOtherOrg: Bool?,
		organizationIds: [Int64],
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.id = id
		self.action = action
		self.createdAt = createdAt
		self.isHighPriority = isHighPriority
		self.notes = notes
		self.reasonT = reasonT
		self.reason = reason
		self.requestedAction = requestedAction
		self.involvesMyOrg = involvesMyOrg
		self.haveContactedOtherOrg = haveContactedOtherOrg
		self.organizationIds = organizationIds
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> FlagSnapshot.Flag {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toFlag()
	}

	struct Builder {
		var id: Int64
		var action: String
		var createdAt: Date
		var isHighPriority: Bool
		var notes: String
		var reasonT: String
		var reason: String
		var requestedAction: String
		var involvesMyOrg: Bool?
		var haveContactedOtherOrg: Bool?
		var organizationIds: [Int64]

		fileprivate init(original: FlagSnapshot.Flag) {
			self.id = original.id
			self.action = original.action
			self.createdAt = original.createdAt
			self.isHighPriority = original.isHighPriority
			self.notes = original.notes
			self.reasonT = original.reasonT
			self.reason = original.reason
			self.requestedAction = original.requestedAction
			self.involvesMyOrg = original.involvesMyOrg
			self.haveContactedOtherOrg = original.haveContactedOtherOrg
			self.organizationIds = original.organizationIds
		}

		fileprivate func toFlag() -> FlagSnapshot.Flag {
			return FlagSnapshot.Flag(
				id: id,
				action: action,
				createdAt: createdAt,
				isHighPriority: isHighPriority,
				notes: notes,
				reasonT: reasonT,
				reason: reason,
				requestedAction: requestedAction,
				involvesMyOrg: involvesMyOrg,
				haveContactedOtherOrg: haveContactedOtherOrg,
				organizationIds: organizationIds
			)
		}
	}
}
