// sourcery: AutoMockable
public protocol WorkTypeAnalyzer {
    func countUnsyncedClaimCloseWork(
        orgId: Int64,
        incidentId: Int64,
        ignoreWorksiteIds: Set<Int64>,
    ) throws -> ClaimCloseCounts
}

extension WorkTypeSnapshot.WorkType {
    var isClosed: Bool {
        let workTypeStatus = statusFromLiteral(status)
        return closedWorkTypeStatuses.contains(workTypeStatus)
    }
}

class WorksiteChangeWorkTypeAnalyzer: WorkTypeAnalyzer {
    private let worksiteChangeDao: WorksiteChangeDataProvider

    init(
        worksiteChangeDao: WorksiteChangeDataProvider,
    ) {
        self.worksiteChangeDao = worksiteChangeDao
    }

    func countUnsyncedClaimCloseWork(
        orgId: Int64,
        incidentId: Int64,
        ignoreWorksiteIds: Set<Int64>,
    ) throws -> ClaimCloseCounts {
        var worksiteChangesLookup = [Int64: (String, String?)]()

        try worksiteChangeDao.getOrgChanges(orgId)
            .filter {
                !ignoreWorksiteIds.contains($0.worksiteId)
            }
            .forEach {
                worksiteChangesLookup[$0.worksiteId] = if let entry = worksiteChangesLookup[$0.worksiteId] {
                    (entry.0, $0.changeData)
                } else {
                     ($0.changeData, nil)
                }
            }

        var workTypeChanges = [(WorkTypeSnapshot.WorkType, WorkTypeSnapshot.WorkType?)]()

        let jsonDecoder = JsonDecoderFactory().decoder()

        try worksiteChangesLookup.forEach {
            let (firstSerializedChange, lastSerializedChange) = $0.value
            let firstEncodedData = firstSerializedChange.data(using: .utf8)!
            let firstChange = try jsonDecoder.decode(WorksiteChange.self, from: firstEncodedData)
            if let firstSnapshot = firstChange.start,
               firstSnapshot.core.networkId > 0 {
                let lastSnapshot = if let lastEncodedData = lastSerializedChange?.data(using: .utf8) {
                    try jsonDecoder.decode(WorksiteChange.self, from: lastEncodedData).change
                } else {
                    firstChange.change
                }
                if lastSnapshot.core.incidentId == incidentId {
                    let startWorkLookup = firstSnapshot.workTypes.associateBy { $0.localId }
                    let lastWorkLookup = lastSnapshot.workTypes.associateBy { $0.localId }
                    for (id, startWorkType) in startWorkLookup {
                        // TODO: Test coverage on last work type is nil
                        let lastWorkType = lastWorkLookup[id]?.workType
                        let change = (startWorkType.workType, lastWorkType)
                        workTypeChanges.append(change)
                    }
                }
            }
        }

        var claimCount = 0
        var closeCount = 0
        for (startWorkType, lastWorkType) in workTypeChanges {
            let wasClaimed = startWorkType.orgClaim == orgId
            let isClaimed = lastWorkType?.orgClaim == orgId
            if wasClaimed != isClaimed {
                claimCount += isClaimed ? 1 : -1

                if isClaimed,
                   lastWorkType?.isClosed ?? false {
                    closeCount += 1
                }
            } else if isClaimed {
                let wasClosed = startWorkType.isClosed
                let isClosed = lastWorkType?.isClosed ?? false
                if wasClosed != isClosed {
                    closeCount = isClosed ? 1 : -1
                }
            }
        }

        return ClaimCloseCounts(claimCount: claimCount, closeCount: closeCount)
    }
}

public struct ClaimCloseCounts: Equatable {
    let claimCount: Int
    let closeCount: Int
}
