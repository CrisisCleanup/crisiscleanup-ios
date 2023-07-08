extension NetworkWorkType {
    func asRecord() -> WorkTypeRecord {
        WorkTypeRecord(
            id: nil,
            // Incoming network ID is always defined
            networkId: id!,
            worksiteId: 0,
            createdAt: createdAt,
            orgClaim: orgClaim,
            nextRecurAt: nextRecurAt,
            phase: phase,
            recur: recur,
            status: status,
            workType: workType
        )
    }
}
