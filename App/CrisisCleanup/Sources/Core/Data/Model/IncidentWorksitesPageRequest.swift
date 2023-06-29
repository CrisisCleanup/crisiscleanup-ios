import Foundation

struct IncidentWorksitesPageRequest: Codable {
    let incidentId: Int64
    let requestTime: Date
    let page: Int
    // Indicates the number of records coming before this data
    let startCount: Int
    let totalCount: Int
    let worksites: [NetworkWorksitePage]
}

struct IncidentOrganizationsPageRequest: Codable {
    let incidentId: Int64
    let offset: Int
    let totalCount: Int
    let organizations: [NetworkIncidentOrganization]
}
