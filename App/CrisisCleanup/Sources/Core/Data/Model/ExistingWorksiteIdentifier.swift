public struct ExistingWorksiteIdentifier: Hashable {
    let incidentId: Int64
    let worksiteId: Int64

    var isDefined: Bool {
        incidentId != EmptyIncident.id &&
        worksiteId != EmptyWorksite.id
    }
}

let ExistingWorksiteIdentifierNone = ExistingWorksiteIdentifier(
    incidentId: EmptyIncident.id,
    worksiteId: EmptyWorksite.id
)
