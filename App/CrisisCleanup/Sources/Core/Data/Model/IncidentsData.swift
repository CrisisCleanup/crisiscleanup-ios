// sourcery: copyBuilder
public struct IncidentsData {
    let isLoading: Bool
    let selected: Incident
    let incidents: [Incident]

    // sourcery:begin: skipCopy
    lazy var isEmpty: Bool = { incidents.isEmpty }()
    lazy var selectedId: Int64 = { selected.id }()
    // sourcery:end
}

let LoadingIncidentsData = IncidentsData(
    isLoading: true,
    selected: EmptyIncident,
    incidents: []
)
