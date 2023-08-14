extension NetworkCaseHistoryEvent {
    func asRecords(_ worksiteId: Int64) -> (CaseHistoryEventRecord, CaseHistoryEventAttrRecord) {
        (
            CaseHistoryEventRecord(
                id: id,
                worksiteId: worksiteId,
                createdAt: createdAt,
                createdBy: createdBy,
                eventKey: eventKey,
                pastTenseT: pastTenseT,
                actorLocationName: actorLocationName ?? "",
                recipientLocationName: recipientLocationName
            ),
            CaseHistoryEventAttrRecord(
                id: id,
                incidentName: attr.incidentName,
                patientCaseNumber: attr.patientCaseNumber,
                patientId: attr.patientId ?? 0,
                patientLabelT: attr.patientLabelT,
                patientLocationName: attr.patientLocationName,
                patientNameT: attr.patientNameT,
                patientReasonT: attr.patientReasonT,
                patientStatusNameT: attr.patientStatusNameT,
                recipientCaseNumber: attr.recipientCaseNumber,
                recipientId: attr.recipientId,
                recipientName: attr.recipientName,
                recipientNameT: attr.recipientNameT
            )
        )
    }
}
