// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension FlagSnapshot {
	// A default style constructor for the .copy fn to use
	init(
		localId: Int64,
		flag: Flag,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.localId = localId
		self.flag = flag
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> FlagSnapshot {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toFlagSnapshot()
	}

	struct Builder {
		var localId: Int64
		var flag: Flag

		fileprivate init(original: FlagSnapshot) {
			self.localId = original.localId
			self.flag = original.flag
		}

		fileprivate func toFlagSnapshot() -> FlagSnapshot {
			return FlagSnapshot(
				localId: localId,
				flag: flag
			)
		}
	}
}
