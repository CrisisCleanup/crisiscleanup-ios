import SwiftUI

extension CrisisCleanupList {
    var ListIcon: Image {
        get {
            switch model {
            case .none:
                return Image(systemName: "exclamationmark.triangle.fill")
            case .file:
                return Image(systemName: "doc.fill")
            case .incident:
                return Image("incident_type_icons/tornado_line", bundle: .module)
            case .list:
                return Image(systemName: "list.bullet")
            case .organization:
                return Image(systemName: "building.2.fill")
            case .organizationIncidentTeam:
                return Image(systemName: "person.3.fill")
            case .user:
                return Image(systemName: "person.fill")
            case .worksite:
                return Image("cases", bundle: .module)
            }
        }
    }
}
