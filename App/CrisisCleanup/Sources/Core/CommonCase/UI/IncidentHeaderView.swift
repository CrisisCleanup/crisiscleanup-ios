import SwiftUI

struct IncidentHeaderView: View {
    var incident: Incident
    var showDropdown: Bool = false
    var text = ""
    var disabled: Bool = false
    var isLoading: Bool = false
    var isSpaceConstrained: Bool = false

    var body: some View {
        HStack(spacing: appTheme.gridItemSpacing) {
            IncidentDisasterImage(
                incident,
                disabled: disabled
            )

            Text(text.ifBlank { incident.shortName })
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
