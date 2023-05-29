// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension AppPreferences {
	// A default style constructor for the .copy fn to use
	init(
		selectedIncidentId: Int64,
		saveCredentialsPromptCount: Int,
		disableSaveCredentialsPrompt: Bool,
		languageKey: String,
		syncAttempt: SyncAttempt,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.selectedIncidentId = selectedIncidentId
		self.saveCredentialsPromptCount = saveCredentialsPromptCount
		self.disableSaveCredentialsPrompt = disableSaveCredentialsPrompt
		self.languageKey = languageKey
		self.syncAttempt = syncAttempt
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> AppPreferences {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toAppPreferences()
	}

	struct Builder {
		var selectedIncidentId: Int64
		var saveCredentialsPromptCount: Int
		var disableSaveCredentialsPrompt: Bool
		var languageKey: String
		var syncAttempt: SyncAttempt

		fileprivate init(original: AppPreferences) {
			self.selectedIncidentId = original.selectedIncidentId
			self.saveCredentialsPromptCount = original.saveCredentialsPromptCount
			self.disableSaveCredentialsPrompt = original.disableSaveCredentialsPrompt
			self.languageKey = original.languageKey
			self.syncAttempt = original.syncAttempt
		}

		fileprivate func toAppPreferences() -> AppPreferences {
			return AppPreferences(
				selectedIncidentId: selectedIncidentId,
				saveCredentialsPromptCount: saveCredentialsPromptCount,
				disableSaveCredentialsPrompt: disableSaveCredentialsPrompt,
				languageKey: languageKey,
				syncAttempt: syncAttempt
			)
		}
	}
}
