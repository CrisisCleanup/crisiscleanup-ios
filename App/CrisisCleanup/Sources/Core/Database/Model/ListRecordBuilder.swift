// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension ListRecord {
	// A default style constructor for the .copy fn to use
	init(
		id: Int64?,
		networkId: Int64,
		localGlobalUuid: String,
		createdBy: Int64?,
		updatedBy: Int64?,
		createdAt: Date,
		updatedAt: Date,
		parent: Int64?,
		name: String,
		description: String?,
		listOrder: Int64?,
		tags: String?,
		model: String,
		objectIds: String,
		shared: String,
		permissions: String,
		incidentId: Int64?,
		// This is to prevent overriding the default init if it exists already
		forCopyInit: Void? = nil
	) {
		self.id = id
		self.networkId = networkId
		self.localGlobalUuid = localGlobalUuid
		self.createdBy = createdBy
		self.updatedBy = updatedBy
		self.createdAt = createdAt
		self.updatedAt = updatedAt
		self.parent = parent
		self.name = name
		self.description = description
		self.listOrder = listOrder
		self.tags = tags
		self.model = model
		self.objectIds = objectIds
		self.shared = shared
		self.permissions = permissions
		self.incidentId = incidentId
	}

	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> ListRecord {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toListRecord()
	}

	struct Builder {
		var id: Int64?
		var networkId: Int64
		var localGlobalUuid: String
		var createdBy: Int64?
		var updatedBy: Int64?
		var createdAt: Date
		var updatedAt: Date
		var parent: Int64?
		var name: String
		var description: String?
		var listOrder: Int64?
		var tags: String?
		var model: String
		var objectIds: String
		var shared: String
		var permissions: String
		var incidentId: Int64?

		fileprivate init(original: ListRecord) {
			self.id = original.id
			self.networkId = original.networkId
			self.localGlobalUuid = original.localGlobalUuid
			self.createdBy = original.createdBy
			self.updatedBy = original.updatedBy
			self.createdAt = original.createdAt
			self.updatedAt = original.updatedAt
			self.parent = original.parent
			self.name = original.name
			self.description = original.description
			self.listOrder = original.listOrder
			self.tags = original.tags
			self.model = original.model
			self.objectIds = original.objectIds
			self.shared = original.shared
			self.permissions = original.permissions
			self.incidentId = original.incidentId
		}

		fileprivate func toListRecord() -> ListRecord {
			return ListRecord(
				id: id,
				networkId: networkId,
				localGlobalUuid: localGlobalUuid,
				createdBy: createdBy,
				updatedBy: updatedBy,
				createdAt: createdAt,
				updatedAt: updatedAt,
				parent: parent,
				name: name,
				description: description,
				listOrder: listOrder,
				tags: tags,
				model: model,
				objectIds: objectIds,
				shared: shared,
				permissions: permissions,
				incidentId: incidentId
			)
		}
	}
}
