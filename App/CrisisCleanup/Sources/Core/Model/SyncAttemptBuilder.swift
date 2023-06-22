// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension SyncAttempt {
	// A default style constructor for the .copy fn to use
	init(
		successfulSeconds: Double,
		attemptedSeconds: Double,
		attemptedCounter: Int,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.successfulSeconds = successfulSeconds
		self.attemptedSeconds = attemptedSeconds
		self.attemptedCounter = attemptedCounter
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> SyncAttempt {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toSyncAttempt()
	}

	struct Builder {
		var successfulSeconds: Double
		var attemptedSeconds: Double
		var attemptedCounter: Int

		fileprivate init(original: SyncAttempt) {
			self.successfulSeconds = original.successfulSeconds
			self.attemptedSeconds = original.attemptedSeconds
			self.attemptedCounter = original.attemptedCounter
		}

		fileprivate func toSyncAttempt() -> SyncAttempt {
			return SyncAttempt(
				successfulSeconds: successfulSeconds,
				attemptedSeconds: attemptedSeconds,
				attemptedCounter: attemptedCounter
			)
		}
	}
}
