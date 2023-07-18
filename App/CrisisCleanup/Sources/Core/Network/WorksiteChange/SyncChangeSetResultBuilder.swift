// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension SyncChangeSetResult {
	// A default style constructor for the .copy fn to use
	init(
		isPartiallySynced: Bool,
		isFullySynced: Bool,
		worksite: NetworkWorksiteFull?,
		hasClaimChange: Bool,
		isConnectedToInternet: Bool,
		isValidToken: Bool,
		exception: Error?,
		favoriteException: Error?,
		addFlagExceptions: [Int64: Error],
		deleteFlagExceptions: [Int64: Error],
		noteExceptions: [Int64: Error],
		workTypeStatusExceptions: [Int64: Error],
		workTypeClaimException: Error?,
		workTypeUnclaimException: Error?,
		workTypeRequestException: Error?,
		workTypeReleaseException: Error?,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.isPartiallySynced = isPartiallySynced
		self.isFullySynced = isFullySynced
		self.worksite = worksite
		self.hasClaimChange = hasClaimChange
		self.isConnectedToInternet = isConnectedToInternet
		self.isValidToken = isValidToken
		self.exception = exception
		self.favoriteException = favoriteException
		self.addFlagExceptions = addFlagExceptions
		self.deleteFlagExceptions = deleteFlagExceptions
		self.noteExceptions = noteExceptions
		self.workTypeStatusExceptions = workTypeStatusExceptions
		self.workTypeClaimException = workTypeClaimException
		self.workTypeUnclaimException = workTypeUnclaimException
		self.workTypeRequestException = workTypeRequestException
		self.workTypeReleaseException = workTypeReleaseException
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> SyncChangeSetResult {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toSyncChangeSetResult()
	}

	struct Builder {
		var isPartiallySynced: Bool
		var isFullySynced: Bool
		var worksite: NetworkWorksiteFull?
		var hasClaimChange: Bool
		var isConnectedToInternet: Bool
		var isValidToken: Bool
		var exception: Error?
		var favoriteException: Error?
		var addFlagExceptions: [Int64: Error]
		var deleteFlagExceptions: [Int64: Error]
		var noteExceptions: [Int64: Error]
		var workTypeStatusExceptions: [Int64: Error]
		var workTypeClaimException: Error?
		var workTypeUnclaimException: Error?
		var workTypeRequestException: Error?
		var workTypeReleaseException: Error?

		fileprivate init(original: SyncChangeSetResult) {
			self.isPartiallySynced = original.isPartiallySynced
			self.isFullySynced = original.isFullySynced
			self.worksite = original.worksite
			self.hasClaimChange = original.hasClaimChange
			self.isConnectedToInternet = original.isConnectedToInternet
			self.isValidToken = original.isValidToken
			self.exception = original.exception
			self.favoriteException = original.favoriteException
			self.addFlagExceptions = original.addFlagExceptions
			self.deleteFlagExceptions = original.deleteFlagExceptions
			self.noteExceptions = original.noteExceptions
			self.workTypeStatusExceptions = original.workTypeStatusExceptions
			self.workTypeClaimException = original.workTypeClaimException
			self.workTypeUnclaimException = original.workTypeUnclaimException
			self.workTypeRequestException = original.workTypeRequestException
			self.workTypeReleaseException = original.workTypeReleaseException
		}

		fileprivate func toSyncChangeSetResult() -> SyncChangeSetResult {
			return SyncChangeSetResult(
				isPartiallySynced: isPartiallySynced,
				isFullySynced: isFullySynced,
				worksite: worksite,
				hasClaimChange: hasClaimChange,
				isConnectedToInternet: isConnectedToInternet,
				isValidToken: isValidToken,
				exception: exception,
				favoriteException: favoriteException,
				addFlagExceptions: addFlagExceptions,
				deleteFlagExceptions: deleteFlagExceptions,
				noteExceptions: noteExceptions,
				workTypeStatusExceptions: workTypeStatusExceptions,
				workTypeClaimException: workTypeClaimException,
				workTypeUnclaimException: workTypeUnclaimException,
				workTypeRequestException: workTypeRequestException,
				workTypeReleaseException: workTypeReleaseException
			)
		}
	}
}
