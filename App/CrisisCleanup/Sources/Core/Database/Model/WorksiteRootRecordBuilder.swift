// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension WorksiteRootRecord {
	// A default style constructor for the .copy fn to use
	init(
		id: Int64?,
		syncUuid: String,
		localModifiedAt: Date,
		syncedAt: Date,
		localGlobalUuid: String,
		isLocalModified: Bool,
		syncAttempt: Int64,
		networkId: Int64,
		incidentId: Int64,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.id = id
		self.syncUuid = syncUuid
		self.localModifiedAt = localModifiedAt
		self.syncedAt = syncedAt
		self.localGlobalUuid = localGlobalUuid
		self.isLocalModified = isLocalModified
		self.syncAttempt = syncAttempt
		self.networkId = networkId
		self.incidentId = incidentId
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> WorksiteRootRecord {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toWorksiteRootRecord()
	}

	struct Builder {
		var id: Int64?
		var syncUuid: String
		var localModifiedAt: Date
		var syncedAt: Date
		var localGlobalUuid: String
		var isLocalModified: Bool
		var syncAttempt: Int64
		var networkId: Int64
		var incidentId: Int64

		fileprivate init(original: WorksiteRootRecord) {
			self.id = original.id
			self.syncUuid = original.syncUuid
			self.localModifiedAt = original.localModifiedAt
			self.syncedAt = original.syncedAt
			self.localGlobalUuid = original.localGlobalUuid
			self.isLocalModified = original.isLocalModified
			self.syncAttempt = original.syncAttempt
			self.networkId = original.networkId
			self.incidentId = original.incidentId
		}

		fileprivate func toWorksiteRootRecord() -> WorksiteRootRecord {
			return WorksiteRootRecord(
				id: id,
				syncUuid: syncUuid,
				localModifiedAt: localModifiedAt,
				syncedAt: syncedAt,
				localGlobalUuid: localGlobalUuid,
				isLocalModified: isLocalModified,
				syncAttempt: syncAttempt,
				networkId: networkId,
				incidentId: incidentId
			)
		}
	}
}
