// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension AccountData {
	// A default style constructor for the .copy fn to use
	init(
		id: Int64,
		tokenExpiry: Date,
		fullName: String,
		emailAddress: String,
		profilePictureUri: String,
		org: OrgData,
		hasAcceptedTerms: Bool,
		areTokensValid: Bool,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.id = id
		self.tokenExpiry = tokenExpiry
		self.fullName = fullName
		self.emailAddress = emailAddress
		self.profilePictureUri = profilePictureUri
		self.org = org
		self.hasAcceptedTerms = hasAcceptedTerms
		self.areTokensValid = areTokensValid
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> AccountData {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toAccountData()
	}

	struct Builder {
		var id: Int64
		var tokenExpiry: Date
		var fullName: String
		var emailAddress: String
		var profilePictureUri: String
		var org: OrgData
		var hasAcceptedTerms: Bool
		var areTokensValid: Bool

		fileprivate init(original: AccountData) {
			self.id = original.id
			self.tokenExpiry = original.tokenExpiry
			self.fullName = original.fullName
			self.emailAddress = original.emailAddress
			self.profilePictureUri = original.profilePictureUri
			self.org = original.org
			self.hasAcceptedTerms = original.hasAcceptedTerms
			self.areTokensValid = original.areTokensValid
		}

		fileprivate func toAccountData() -> AccountData {
			return AccountData(
				id: id,
				tokenExpiry: tokenExpiry,
				fullName: fullName,
				emailAddress: emailAddress,
				profilePictureUri: profilePictureUri,
				org: org,
				hasAcceptedTerms: hasAcceptedTerms,
				areTokensValid: areTokensValid
			)
		}
	}
}
