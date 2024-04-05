import Foundation

protocol IncidentCacheDataPageRequest: Codable {
    var incidentId: Int64 { get }
    var requestTime: Date { get }
    var page: Int { get }
    var startCount: Int { get }
    var totalCount: Int { get }
}

struct IncidentWorksitesPageRequest: IncidentCacheDataPageRequest {
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

struct IncidentWorksitesSecondaryDataPageRequest: IncidentCacheDataPageRequest {
    let incidentId: Int64
    let requestTime: Date
    let page: Int
    // Indicates the number of records coming before this data
    let startCount: Int
    let totalCount: Int
    let secondaryData: [NetworkFlagsFormData]
}
