import SwiftUI

private let incidentsAssetIconPath = "incident_type_icons"
private let shapeSize = 48.0

struct IncidentDisasterImage: View {
    @Environment(\.isEnabled) private var isEnabled

    private let isValidIncident: Bool
    private let iconPath: String
    private let backgroundColor: Color?

    init (
        _ incident: Incident,
        background: Color? = nil
    ) {
        self.init(
            incident != EmptyIncident,
            incident.disaster.literal,
            background: background
        )
    }

    init (
        _ isValidIncident: Bool,
        _ disasterLiteral: String,
        background: Color? = nil
    ) {
        self.isValidIncident = isValidIncident
        iconPath = "\(incidentsAssetIconPath)/\(disasterLiteral)"
        backgroundColor = background
    }

    var body: some View {
        let foregroundColor = if isValidIncident,
            isEnabled {
                appTheme.colors.incidentDisasterContainerColor
            } else if isEnabled {
                appTheme.colors.primaryOrangeColor
            } else {
                Color.gray
            }
        if backgroundColor == nil {
            DisasterImage(
                iconPath: iconPath,
                foregroundColor: foregroundColor
            )
        } else {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: shapeSize, height: shapeSize)
                DisasterImage(
                    iconPath: iconPath,
                    foregroundColor: foregroundColor
                )
            }
        }
    }
}

fileprivate struct DisasterImage: View {
    let iconPath: String
    let foregroundColor: Color?

    var body: some View {
        Image(iconPath, bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(width: shapeSize, height: shapeSize)
            .foregroundColor(foregroundColor)
    }
}
