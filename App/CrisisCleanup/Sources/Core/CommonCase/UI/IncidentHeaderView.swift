import SwiftUI

struct IncidentHeaderView: View {
    var incident: Incident? = nil
    var isValidIncident: Bool = false
    var disasterLiteral: String = ""
    var showDropdown: Bool = false
    var text = ""
    var disabled: Bool = false
    var isLoading: Bool = false
    var isSpaceConstrained: Bool = false

    var body: some View {
        HStack(spacing: appTheme.gridItemSpacing) {
            if let incident = incident {
                IncidentDisasterImage(
                    incident,
                    disabled: disabled
                )
            } else {
                IncidentDisasterImage(
                    isValidIncident,
                    disasterLiteral,
                    disabled: disabled
                )
            }

            Text(text.ifBlank { incident?.shortName ?? "" })
                .fontHeader(size: isSpaceConstrained ? 2 : 1)

            if showDropdown {
                DropDownIcon()
            }

            // TODO: Animate
            if isLoading {
                ProgressView()
                    .circularProgress()
            }
        }
    }
}
