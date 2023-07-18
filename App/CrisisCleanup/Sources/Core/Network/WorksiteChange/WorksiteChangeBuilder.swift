// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension WorksiteChange {
	// A default style constructor for the .copy fn to use
	init(
		isWorksiteDataChange: Bool?,
		start: WorksiteSnapshot?,
		change: WorksiteSnapshot,
		requestWorkTypes: WorkTypeTransfer?,
		releaseWorkTypes: WorkTypeTransfer?,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.isWorksiteDataChange = isWorksiteDataChange
		self.start = start
		self.change = change
		self.requestWorkTypes = requestWorkTypes
		self.releaseWorkTypes = releaseWorkTypes
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> WorksiteChange {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toWorksiteChange()
	}

	struct Builder {
		var isWorksiteDataChange: Bool?
		var start: WorksiteSnapshot?
		var change: WorksiteSnapshot
		var requestWorkTypes: WorkTypeTransfer?
		var releaseWorkTypes: WorkTypeTransfer?

		fileprivate init(original: WorksiteChange) {
			self.isWorksiteDataChange = original.isWorksiteDataChange
			self.start = original.start
			self.change = original.change
			self.requestWorkTypes = original.requestWorkTypes
			self.releaseWorkTypes = original.releaseWorkTypes
		}

		fileprivate func toWorksiteChange() -> WorksiteChange {
			return WorksiteChange(
				isWorksiteDataChange: isWorksiteDataChange,
				start: start,
				change: change,
				requestWorkTypes: requestWorkTypes,
				releaseWorkTypes: releaseWorkTypes
			)
		}
	}
}
