import SwiftUI

private let incidentsAssetIconPath = "incident_type_icons"
private let shapeSize = 48.0

struct IncidentDisasterImage: View {
    private let isValidIncident: Bool
    private let iconPath: String
    private let isEditable: Bool
    private let backgroundColor: Color?

    init (
        _ incident: Incident,
        disabled: Bool = false,
        background: Color? = nil
    ) {
        self.init(
            incident != EmptyIncident,
            incident.disaster.literal,
            disabled: disabled,
            background: background
        )
    }

    init (
        _ isValidIncident: Bool,
        _ disasterLiteral: String,
        disabled: Bool = false,
        background: Color? = nil
    ) {
        self.isValidIncident = isValidIncident
        iconPath = "\(incidentsAssetIconPath)/\(disasterLiteral)"
        isEditable = !disabled
        backgroundColor = background
    }

    var body: some View {
        let foregroundColor = isValidIncident && isEditable ? appTheme.colors.incidentDisasterContainerColor : Color.gray
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
