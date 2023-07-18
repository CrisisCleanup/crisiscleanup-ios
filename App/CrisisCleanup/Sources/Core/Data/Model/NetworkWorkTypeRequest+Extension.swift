extension NetworkWorkTypeRequest {
    func asRecord(_ worksiteId: Int64) -> WorkTypeRequestRecord {
        WorkTypeRequestRecord(
            networkId: id,
            worksiteId: worksiteId,
            workType: workType.workType,
            reason: "",
            byOrg: byOrg.id,
            toOrg: toOrg.id,
            createdAt: createdAt,
            approvedAt: approvedAt,
            rejectedAt: rejectedAt,
            approvedRejectedReason: acceptedRejectedReason ?? ""
        )
    }
}
