struct NetworkUser: Codable, Equatable {
    let id: Int64
    let organization: NetworkAuthOrganization
    let files: [NetworkFile]
}
