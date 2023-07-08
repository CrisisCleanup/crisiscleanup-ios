import SwiftUI

private let incidentsAssetIconPath = "incident_type_icons"

struct IncidentDisasterImage: View {
    private let isValidIncident: Bool
    private let iconPath: String
    private let isEditable: Bool

    init(
        _ incident: Incident,
        disabled: Bool = false
    ) {
        isValidIncident = incident != EmptyIncident
        let disaster = incident.disaster.literal
        iconPath = "\(incidentsAssetIconPath)/\(disaster)"
        isEditable = !disabled
    }

    var body: some View {
        Image(iconPath, bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(width: 48, height: 48)
            .foregroundColor(isValidIncident && isEditable ? appTheme.colors.incidentDisasterContainerColor : Color.gray)
    }
}
