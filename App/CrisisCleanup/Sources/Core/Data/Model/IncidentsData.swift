// sourcery: copyBuilder, skipCopyInit
public struct IncidentsData: Equatable {
    let isLoading: Bool
    let selected: Incident
    let incidents: [Incident]

    // sourcery:begin: skipCopy
    let isEmpty: Bool
    let selectedId: Int64
    // sourcery:end

    init(
        isLoading: Bool,
        selected: Incident,
        incidents: [Incident]
    ) {
        self.isLoading = isLoading
        self.selected = selected
        self.incidents = incidents
        isEmpty = incidents.isEmpty
        selectedId = selected.id
    }
}

let LoadingIncidentsData = IncidentsData(
    isLoading: true,
    selected: EmptyIncident,
    incidents: []
)
