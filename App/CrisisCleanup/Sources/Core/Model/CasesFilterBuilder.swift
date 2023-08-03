// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Foundation

extension CasesFilter {
	// struct copy, lets you overwrite specific variables retaining the value of the rest
	// using a closure to set the new values for the copy of the struct
	func copy(build: (inout Builder) -> Void) -> CasesFilter {
		var builder = Builder(original: self)
		build(&builder)
		return builder.toCasesFilter()
	}

	struct Builder {
		var svi: Double
		var daysAgoUpdated: Int
		var distance: Double
		var isWithinPrimaryResponseArea: Bool
		var isWithinSecondaryResponseArea: Bool
		var isAssignedToMyTeam: Bool
		var isUnclaimed: Bool
		var isClaimedByMyOrg: Bool
		var isReportedByMyOrg: Bool
		var isStatusOpen: Bool
		var isStatusClosed: Bool
		var workTypeStatuses: Set<WorkTypeStatus>
		var isMemberOfMyOrg: Bool
		var isOlderThan60: Bool
		var hasChildrenInHome: Bool
		var isFirstResponder: Bool
		var isVeteran: Bool
		var worksiteFlags: [WorksiteFlagType]
		var workTypes: Set<String>
		var isNoWorkType: Bool
		var createdAt: DateRange?
		var updatedAt: DateRange?

		fileprivate init(original: CasesFilter) {
			self.svi = original.svi
			self.daysAgoUpdated = original.daysAgoUpdated
			self.distance = original.distance
			self.isWithinPrimaryResponseArea = original.isWithinPrimaryResponseArea
			self.isWithinSecondaryResponseArea = original.isWithinSecondaryResponseArea
			self.isAssignedToMyTeam = original.isAssignedToMyTeam
			self.isUnclaimed = original.isUnclaimed
			self.isClaimedByMyOrg = original.isClaimedByMyOrg
			self.isReportedByMyOrg = original.isReportedByMyOrg
			self.isStatusOpen = original.isStatusOpen
			self.isStatusClosed = original.isStatusClosed
			self.workTypeStatuses = original.workTypeStatuses
			self.isMemberOfMyOrg = original.isMemberOfMyOrg
			self.isOlderThan60 = original.isOlderThan60
			self.hasChildrenInHome = original.hasChildrenInHome
			self.isFirstResponder = original.isFirstResponder
			self.isVeteran = original.isVeteran
			self.worksiteFlags = original.worksiteFlags
			self.workTypes = original.workTypes
			self.isNoWorkType = original.isNoWorkType
			self.createdAt = original.createdAt
			self.updatedAt = original.updatedAt
		}

		fileprivate func toCasesFilter() -> CasesFilter {
			return CasesFilter(
				svi: svi,
				daysAgoUpdated: daysAgoUpdated,
				distance: distance,
				isWithinPrimaryResponseArea: isWithinPrimaryResponseArea,
				isWithinSecondaryResponseArea: isWithinSecondaryResponseArea,
				isAssignedToMyTeam: isAssignedToMyTeam,
				isUnclaimed: isUnclaimed,
				isClaimedByMyOrg: isClaimedByMyOrg,
				isReportedByMyOrg: isReportedByMyOrg,
				isStatusOpen: isStatusOpen,
				isStatusClosed: isStatusClosed,
				workTypeStatuses: workTypeStatuses,
				isMemberOfMyOrg: isMemberOfMyOrg,
				isOlderThan60: isOlderThan60,
				hasChildrenInHome: hasChildrenInHome,
				isFirstResponder: isFirstResponder,
				isVeteran: isVeteran,
				worksiteFlags: worksiteFlags,
				workTypes: workTypes,
				isNoWorkType: isNoWorkType,
				createdAt: createdAt,
				updatedAt: updatedAt
			)
		}
	}
}
