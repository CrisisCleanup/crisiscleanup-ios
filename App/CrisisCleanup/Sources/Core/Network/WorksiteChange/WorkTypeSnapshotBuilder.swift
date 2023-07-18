// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension WorkTypeSnapshot {
	// A default style constructor for the .copy fn to use
	init(
		localId: Int64,
		workType: WorkType,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.localId = localId
		self.workType = workType
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> WorkTypeSnapshot {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toWorkTypeSnapshot()
	}

	struct Builder {
		var localId: Int64
		var workType: WorkType

		fileprivate init(original: WorkTypeSnapshot) {
			self.localId = original.localId
			self.workType = original.workType
		}

		fileprivate func toWorkTypeSnapshot() -> WorkTypeSnapshot {
			return WorkTypeSnapshot(
				localId: localId,
				workType: workType
			)
		}
	}
}
