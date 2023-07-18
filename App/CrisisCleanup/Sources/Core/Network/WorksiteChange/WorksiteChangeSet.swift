import Foundation

struct WorksiteChangeSet {
    let updatedAtFallback: Date
    let worksite: NetworkWorksitePush?
    let isOrgMember: Bool?
    let extraNotes: [(Int64, NetworkNote)]
    let flagChanges: ([(Int64, NetworkFlag)], [Int64])
    var workTypeChanges: [WorkTypeChange]

    let hasNonCoreChanges: Bool

    init(
        updatedAtFallback: Date,
        worksite: NetworkWorksitePush?,
        isOrgMember: Bool?,
        extraNotes: [(Int64, NetworkNote)] = [],
        flagChanges: ([(Int64, NetworkFlag)], [Int64]) = ([], []),
        workTypeChanges: [WorkTypeChange] = []
    ) {
        self.updatedAtFallback = updatedAtFallback
        self.worksite = worksite
        self.isOrgMember = isOrgMember
        self.extraNotes = extraNotes
        self.flagChanges = flagChanges
        self.workTypeChanges = workTypeChanges
        hasNonCoreChanges = isOrgMember != nil ||
        extraNotes.isNotEmpty ||
        flagChanges.0.isNotEmpty ||
        flagChanges.1.isNotEmpty ||
        workTypeChanges.isNotEmpty
    }
}
