extension Worksite {
    func getClaimStatus(_ affiliateIds: Set<Int64>) -> TableWorksiteClaimStatus {
        let workTypeCount = workTypes.count
        let claimedBy = workTypes.compactMap { $0.orgClaim }
        let unclaimedCount = workTypeCount - claimedBy.count
        var claimStatus: TableWorksiteClaimStatus = .hasUnclaimed
        if unclaimedCount == 0 {
            let claimedByMyOrgCount = claimedBy.filter { affiliateIds.contains($0) }.count
            claimStatus = claimedByMyOrgCount > 0 ? .claimedByMyOrg : .claimedByOthers
            // TODO: Test
            if claimStatus == .claimedByOthers &&
                workTypeRequests.filter({ $0.hasNoResponse }).count == workTypeCount
            {
                claimStatus = .requested
            }
        }
        return claimStatus
    }
}

public struct TableDataWorksite {
    let worksite: Worksite
    let claimStatus: TableWorksiteClaimStatus
}

enum TableWorksiteClaimStatus: String, Identifiable, CaseIterable {
    case hasUnclaimed,

         claimedByMyOrg,

         /**
          * Claimed by an unaffiliated org
          */
         claimedByOthers,

         /**
          * All work types have been requested
          */
         requested

    var id: String { rawValue }
}

enum TableWorksiteClaimAction: String, Identifiable, CaseIterable {
    case claim,
         unclaim,
         request,
         release

    var id: String { rawValue }
}
