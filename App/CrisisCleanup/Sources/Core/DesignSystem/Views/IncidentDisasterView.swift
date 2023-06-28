import SwiftUI

private let incidentsAssetIconPath = "incident_type_icons"

struct IncidentDisasterImage: View {
    private let isValidIncident: Bool
    private let iconPath: String

    init(_ incident: Incident) {
        isValidIncident = incident != EmptyIncident
        let disaster = isValidIncident ? incident.disasterLiteral : "other"
        iconPath = "\(incidentsAssetIconPath)/\(disaster)"
    }

    var body: some View {
        Image(iconPath, bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(width: 48, height: 48)
            .foregroundColor(isValidIncident ? appTheme.colors.incidentDisasterContainerColor : Color.gray)
    }
}
