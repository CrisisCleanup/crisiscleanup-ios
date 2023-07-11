// sourcery: AutoMockable
protocol WorksiteChangeSerializer {
    /**
     * Serializes changes to a worksite for applying (on a reference) later
     *
     * Lookups map local ID to network ID where network IDs are specified.
     */
    func serialize(
        _ isDataChange: Bool,
        worksiteStart: Worksite,
        worksiteChange: Worksite,
        flagIdLookup: [Int64: Int64],
        noteIdLookup: [Int64: Int64],
        workTypeIdLookup: [Int64: Int64],
        requestReason: String,
        requestWorkTypes: [String],
        releaseReason: String,
        releaseWorkTypes: [String]
    ) throws -> (Int, String)
}

extension WorksiteChangeSerializer {
    func serialize(
        isDataChange: Bool,
        worksiteStart: Worksite,
        worksiteChange: Worksite,
        flagIdLookup: [Int64: Int64] = [:],
        noteIdLookup: [Int64: Int64] = [:],
        workTypeIdLookup: [Int64: Int64] = [:],
        requestReason: String = "",
        requestWorkTypes: [String] = [],
        releaseReason: String = "",
        releaseWorkTypes: [String] = []
    ) throws -> (Int, String) {
        try serialize(
            isDataChange,
            worksiteStart: worksiteStart,
            worksiteChange: worksiteChange,
            flagIdLookup: flagIdLookup,
            noteIdLookup: noteIdLookup,
            workTypeIdLookup: workTypeIdLookup,
            requestReason: requestReason,
            requestWorkTypes: requestWorkTypes,
            releaseReason: releaseReason,
            releaseWorkTypes: releaseWorkTypes
        )
    }
}
