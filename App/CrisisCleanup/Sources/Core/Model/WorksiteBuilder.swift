// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension Worksite {
	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> Worksite {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toWorksite()
	}

	struct Builder {
		var id: Int64
		var address: String
		var autoContactFrequencyT: String
		var caseNumber: String
		var city: String
		var county: String
		var createdAt: Date?
		var email: String?
		var favoriteId: Int64?
		var files: [NetworkImage]
		var flags: [WorksiteFlag]?
		var formData: [String: WorksiteFormValue]?
		var incidentId: Int64
		var keyWorkType: WorkType?
		var latitude: Double
		var longitude: Double
		var name: String
		var networkId: Int64
		var notes: [WorksiteNote]
		var phone1: String
		var phone2: String
		var plusCode: String?
		var postalCode: String
		var reportedBy: Int64?
		var state: String
		var svi: Double?
		var updatedAt: Date?
		var what3Words: String?
		var workTypes: [WorkType]
		var workTypeRequests: [WorkTypeRequest]
		var isAssignedToOrgMember: Bool

		fileprivate init(original: Worksite) {
			self.id = original.id
			self.address = original.address
			self.autoContactFrequencyT = original.autoContactFrequencyT
			self.caseNumber = original.caseNumber
			self.city = original.city
			self.county = original.county
			self.createdAt = original.createdAt
			self.email = original.email
			self.favoriteId = original.favoriteId
			self.files = original.files
			self.flags = original.flags
			self.formData = original.formData
			self.incidentId = original.incidentId
			self.keyWorkType = original.keyWorkType
			self.latitude = original.latitude
			self.longitude = original.longitude
			self.name = original.name
			self.networkId = original.networkId
			self.notes = original.notes
			self.phone1 = original.phone1
			self.phone2 = original.phone2
			self.plusCode = original.plusCode
			self.postalCode = original.postalCode
			self.reportedBy = original.reportedBy
			self.state = original.state
			self.svi = original.svi
			self.updatedAt = original.updatedAt
			self.what3Words = original.what3Words
			self.workTypes = original.workTypes
			self.workTypeRequests = original.workTypeRequests
			self.isAssignedToOrgMember = original.isAssignedToOrgMember
		}

		fileprivate func toWorksite() -> Worksite {
			return Worksite(
				id: id,
				address: address,
				autoContactFrequencyT: autoContactFrequencyT,
				caseNumber: caseNumber,
				city: city,
				county: county,
				createdAt: createdAt,
				email: email,
				favoriteId: favoriteId,
				files: files,
				flags: flags,
				formData: formData,
				incidentId: incidentId,
				keyWorkType: keyWorkType,
				latitude: latitude,
				longitude: longitude,
				name: name,
				networkId: networkId,
				notes: notes,
				phone1: phone1,
				phone2: phone2,
				plusCode: plusCode,
				postalCode: postalCode,
				reportedBy: reportedBy,
				state: state,
				svi: svi,
				updatedAt: updatedAt,
				what3Words: what3Words,
				workTypes: workTypes,
				workTypeRequests: workTypeRequests,
				isAssignedToOrgMember: isAssignedToOrgMember
			)
		}
	}
}
