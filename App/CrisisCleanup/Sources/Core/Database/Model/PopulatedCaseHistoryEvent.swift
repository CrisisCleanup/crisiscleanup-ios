import GRDB

struct PopulatedCaseHistoryEvent: Equatable, Decodable, FetchableRecord {
    let caseHistoryEvent: CaseHistoryEventRecord
    let caseHistoryEventAttr: CaseHistoryEventAttrRecord

    func asExternalModel(_ translator: KeyTranslator) -> CaseHistoryEvent {
        func translate(_ key: String?) -> String {
            guard key != nil else { return ""}
            return translator.translate(key!) ?? ""
        }
        let event = caseHistoryEvent
        let attr = caseHistoryEventAttr
        return CaseHistoryEvent(
            id: event.id,
            worksiteId: event.worksiteId,
            createdAt: event.createdAt,
            createdBy: event.createdBy,
            eventKey: event.eventKey,
            pastTenseDescription: translate(event.pastTenseT)
                .replace("{incident_name}", attr.incidentName)
                .replace("{patient_case_number}", attr.patientCaseNumber ?? "?")
                .replace("{patient_label_t}", translate(attr.patientLabelT))
                .replace("{patient_location_name}", attr.patientLocationName ?? "")
                .replace("{patient_name_t}", translate(attr.patientNameT))
                .replace("{patient_reason_t}", translate(attr.patientReasonT))
                .replace("{patient_status_name_t}", translate(attr.patientStatusNameT))
                .replace("{recipient_case_number}", attr.recipientCaseNumber ?? "")
                .replace("{recipient_name}", attr.recipientName ?? "?")
                .replace("{recipient_name_t}", translate(attr.recipientNameT)),
            actorLocationName: event.actorLocationName,
            recipientLocationName: event.recipientLocationName
        )
    }
}

extension String {
    fileprivate func replace(_ of: String, _ with: String) -> String {
        replacingOccurrences(of: of, with: with)
    }
}
