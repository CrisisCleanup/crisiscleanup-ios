// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension AccountInfo {
	// A default style constructor for the .copy fn to use
	init(
		id: Int64,
		email: String,
		firstName: String,
		lastName: String,
		expirySeconds: Int64,
		profilePictureUri: String,
		accessToken: String,
		orgId: Int64,
		orgName: String,
		hasAcceptedTerms: Bool,
		incidentIds: Set<Int64>,
		activeRoles: Set<Int>,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.id = id
		self.email = email
		self.firstName = firstName
		self.lastName = lastName
		self.expirySeconds = expirySeconds
		self.profilePictureUri = profilePictureUri
		self.accessToken = accessToken
		self.orgId = orgId
		self.orgName = orgName
		self.hasAcceptedTerms = hasAcceptedTerms
		self.incidentIds = incidentIds
		self.activeRoles = activeRoles
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> AccountInfo {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toAccountInfo()
	}

	struct Builder {
		var id: Int64
		var email: String
		var firstName: String
		var lastName: String
		var expirySeconds: Int64
		var profilePictureUri: String
		var accessToken: String
		var orgId: Int64
		var orgName: String
		var hasAcceptedTerms: Bool
		var incidentIds: Set<Int64>
		var activeRoles: Set<Int>

		fileprivate init(original: AccountInfo) {
			self.id = original.id
			self.email = original.email
			self.firstName = original.firstName
			self.lastName = original.lastName
			self.expirySeconds = original.expirySeconds
			self.profilePictureUri = original.profilePictureUri
			self.accessToken = original.accessToken
			self.orgId = original.orgId
			self.orgName = original.orgName
			self.hasAcceptedTerms = original.hasAcceptedTerms
			self.incidentIds = original.incidentIds
			self.activeRoles = original.activeRoles
		}

		fileprivate func toAccountInfo() -> AccountInfo {
			return AccountInfo(
				id: id,
				email: email,
				firstName: firstName,
				lastName: lastName,
				expirySeconds: expirySeconds,
				profilePictureUri: profilePictureUri,
				accessToken: accessToken,
				orgId: orgId,
				orgName: orgName,
				hasAcceptedTerms: hasAcceptedTerms,
				incidentIds: incidentIds,
				activeRoles: activeRoles
			)
		}
	}
}
