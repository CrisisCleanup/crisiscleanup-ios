// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension WorkTypeSnapshot.WorkType {
	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> WorkTypeSnapshot.WorkType {
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
		var status: String
		var workType: String

		fileprivate init(original: WorkTypeSnapshot.WorkType) {
			self.id = original.id
			self.createdAt = original.createdAt
			self.orgClaim = original.orgClaim
			self.nextRecurAt = original.nextRecurAt
			self.phase = original.phase
			self.recur = original.recur
			self.status = original.status
			self.workType = original.workType
		}

		fileprivate func toWorkType() -> WorkTypeSnapshot.WorkType {
			return WorkTypeSnapshot.WorkType(
				id: id,
                status: status,
                workType: workType,
                createdAt: createdAt,
                orgClaim: orgClaim,
                nextRecurAt: nextRecurAt,
                phase: phase,
                recur: recur
			)
		}
	}
}
