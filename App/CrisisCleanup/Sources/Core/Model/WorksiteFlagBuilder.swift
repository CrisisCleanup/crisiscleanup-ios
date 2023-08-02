// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension WorksiteFlag {
	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> WorksiteFlag {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toWorksiteFlag()
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
		var attr: FlagAttributes?

		fileprivate init(original: WorksiteFlag) {
			self.id = original.id
			self.action = original.action
			self.createdAt = original.createdAt
			self.isHighPriority = original.isHighPriority
			self.notes = original.notes
			self.reasonT = original.reasonT
			self.reason = original.reason
			self.requestedAction = original.requestedAction
			self.attr = original.attr
		}

		fileprivate func toWorksiteFlag() -> WorksiteFlag {
			return WorksiteFlag(
				id: id,
				action: action,
				createdAt: createdAt,
				isHighPriority: isHighPriority,
				notes: notes,
				reasonT: reasonT,
				reason: reason,
				requestedAction: requestedAction,
				attr: attr
			)
		}
	}
}
