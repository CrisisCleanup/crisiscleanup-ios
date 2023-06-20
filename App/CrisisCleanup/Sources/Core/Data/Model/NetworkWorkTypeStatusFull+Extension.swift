extension NetworkWorkTypeStatusFull {
    func asPopulatedModel() -> PopulatedWorkTypeStatus {
        PopulatedWorkTypeStatus(
            status: status,
            name: name,
            primaryState: primaryState
        )
    }
}

struct PopulatedWorkTypeStatus {
    let status: String
    let name: String
    let primaryState: String
}
