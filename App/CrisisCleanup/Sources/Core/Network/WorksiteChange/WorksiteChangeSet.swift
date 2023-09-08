import Foundation

struct WorksiteChangeSet {
    let updatedAtFallback: Date
    let worksite: NetworkWorksitePush?
    let isOrgMember: Bool?
    let extraNotes: [(Int64, NetworkNote)]
    let flagChanges: ([(Int64, NetworkFlag)], [Int64])
    let newWorkTypes: [String: WorkTypeChange]
    var workTypeChanges: [WorkTypeChange]

    let hasNonCoreChanges: Bool

    init(
        updatedAtFallback: Date,
        worksite: NetworkWorksitePush?,
        isOrgMember: Bool?,
        extraNotes: [(Int64, NetworkNote)] = [],
        flagChanges: ([(Int64, NetworkFlag)], [Int64]) = ([], []),
        newWorkTypes: [String: WorkTypeChange] = [:],
        workTypeChanges: [WorkTypeChange] = []
    ) {
        self.updatedAtFallback = updatedAtFallback
        self.worksite = worksite
        self.isOrgMember = isOrgMember
        self.extraNotes = extraNotes
        self.flagChanges = flagChanges
        self.newWorkTypes = newWorkTypes
        self.workTypeChanges = workTypeChanges
        hasNonCoreChanges = isOrgMember != nil ||
        extraNotes.isNotEmpty ||
        flagChanges.0.isNotEmpty ||
        flagChanges.1.isNotEmpty ||
        newWorkTypes.isNotEmpty ||
        workTypeChanges.isNotEmpty
    }
}
