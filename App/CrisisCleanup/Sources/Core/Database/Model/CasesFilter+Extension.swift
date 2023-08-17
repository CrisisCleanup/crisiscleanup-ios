import Foundation

extension CasesFilter {
    func passesFilter(
        organizationAffiliates: Set<Int64>,
        flags: [WorksiteFlagRecord],
        formData: [WorksiteFormDataRecord],
        workTypes: [WorkTypeRecord],
        worksiteCreatedAt: Date?,
        worksiteIsFavorite: Bool,
        worksiteReportedBy: Int64?,
        worksiteUpdatedAt: Date,
        worksiteLatitude: Double,
        worksiteLongitude: Double,
        locationAreaBounds: OrganizationLocationAreaBounds
    ) -> Bool {
        if hasWorkTypeFilters {
            var assignedToMyTeamCount = 0
            var unclaimedCount = 0
            var claimedByMyOrgCount = 0
            var matchingStatusCount = 0
            var matchingWorkTypeCount = 0

            let matchingStatuses = matchingStatuses
            let matchingWorkTypes = matchingWorkTypes

            workTypes.forEach { workType in
                if let orgClaim = workType.orgClaim {
                    if organizationAffiliates.contains(orgClaim) {
                        assignedToMyTeamCount += 1
                    }
                    if (organizationAffiliates.contains(orgClaim)) {
                        claimedByMyOrgCount += 1
                    }
                } else {
                    unclaimedCount += 1
                }

                if matchingStatuses.contains(workType.status) {
                    matchingStatusCount += 1
                }

                if matchingWorkTypes.contains(workType.workType) {
                    matchingWorkTypeCount += 1
                }
            }

            if isAssignedToMyTeam && assignedToMyTeamCount == 0 {
                return false
            }

            if isUnclaimed && unclaimedCount == 0 {
                return false
            }

            if isClaimedByMyOrg && claimedByMyOrgCount == 0 {
                return false
            }

            if !matchingStatuses.isEmpty && matchingStatusCount == 0 {
                return false
            }

            if !matchingWorkTypes.isEmpty && matchingWorkTypeCount == 0 {
                return false
            }
        }

        if isReportedByMyOrg,
           let reportedBy = worksiteReportedBy,
           !organizationAffiliates.contains(reportedBy) {
            return false
        }

        if isMemberOfMyOrg && !worksiteIsFavorite {
            return false
        }

        let formDataFilters = matchingFormData
        if !formDataFilters.isEmpty,
           !formData.contains(where: {
               formDataFilters.contains($0.fieldKey) && $0.isBoolValue
           }) {
            return false
        }

        let worksiteFlags = worksiteFlags
        if !worksiteFlags.isEmpty {
            let matchingFlags = matchingFlags
            if !flags.contains(where: {
                matchingFlags.contains($0.reasonT)
            }) {
                return false
            }
        }

        if let range = createdAt,
           let at = worksiteCreatedAt,
           (at < range.start || at > range.end) {
            return false
        }

        if let range = updatedAt,
           (worksiteUpdatedAt < range.start || worksiteUpdatedAt > range.end) {
            return false
        }

        if isWithinPrimaryResponseArea {
            if let bounds = locationAreaBounds.primary,
               !bounds.isInBounds(worksiteLatitude, worksiteLongitude) {
                return false
            }
        }

        if isWithinSecondaryResponseArea {
            if let bounds = locationAreaBounds.secondary,
               !bounds.isInBounds(worksiteLatitude, worksiteLongitude) {
                return false
            }
        }

        return true
    }
}
