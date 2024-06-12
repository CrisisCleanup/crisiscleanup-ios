import Foundation
import GRDB

struct PopulatedList: Equatable, Decodable, FetchableRecord {
    let list: ListRecord
    let incident: IncidentRecord?

    func asExternalModel() -> CrisisCleanupList {
        let numericObjectIds = list.objectIds.trim()
            .split(separator: ",")
            .compactMap { Int64(String($0).trim()) }
        let incidentNameType = if let incident = incident {
            IncidentIdNameType(
                id: incident.id,
                name: incident.name,
                shortName: incident.shortName,
                disasterLiteral: incident.type
            )
        } else {
            EmptyList.incident
        }
        return CrisisCleanupList(
            id: list.id!,
            updatedAt: list.updatedAt,
            networkId: list.networkId,
            parentNetworkId: list.parent,
            name: list.name,
            description: list.description ?? "",
            listOrder: list.listOrder,
            tags: list.tags,
            model: listModelFromLiteral(list.model),
            objectIds: numericObjectIds,
            shared: listShareFromLiteral(list.shared),
            permission: listPermissionFromLiteral(list.permissions),
            incident: incidentNameType
        )
    }
}
