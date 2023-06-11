// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension WorkType {
	// A default style constructor for the .copy fn to use
	init(
		id: Int64,
		createdAt: Date?,
		orgClaim: Int64?,
		nextRecurAt: Date?,
		phase: Int?,
		recur: String?,
		statusLiteral: String,
		workTypeLiteral: String,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.id = id
		self.createdAt = createdAt
		self.orgClaim = orgClaim
		self.nextRecurAt = nextRecurAt
		self.phase = phase
		self.recur = recur
		self.statusLiteral = statusLiteral
		self.workTypeLiteral = workTypeLiteral
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> WorkType {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toWorkType()
	}

	struct Builder {
		var id: Int64
		var createdAt: Date?
		var orgClaim: Int64?
		var nextRecurAt: Date?
		var phase: Int?
		var recur: String?
		var statusLiteral: String
		var workTypeLiteral: String

		fileprivate init(original: WorkType) {
			self.id = original.id
			self.createdAt = original.createdAt
			self.orgClaim = original.orgClaim
			self.nextRecurAt = original.nextRecurAt
			self.phase = original.phase
			self.recur = original.recur
			self.statusLiteral = original.statusLiteral
			self.workTypeLiteral = original.workTypeLiteral
		}

		fileprivate func toWorkType() -> WorkType {
			return WorkType(
				id: id,
				createdAt: createdAt,
				orgClaim: orgClaim,
				nextRecurAt: nextRecurAt,
				phase: phase,
				recur: recur,
				statusLiteral: statusLiteral,
				workTypeLiteral: workTypeLiteral
			)
		}
	}
}
