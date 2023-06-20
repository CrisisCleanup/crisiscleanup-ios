// sourcery: copyBuilder
public struct IncidentsData {
    let isLoading: Bool
    let selected: Incident
    let incidents: [Incident]

    // sourcery:begin: skipCopy
    var isEmpty: Bool { incidents.isEmpty }
    var selectedId: Int64 { selected.id }
    // sourcery:end
}

let LoadingIncidentsData = IncidentsData(
    isLoading: true,
    selected: EmptyIncident,
    incidents: []
)
