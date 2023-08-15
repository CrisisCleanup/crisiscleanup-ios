//  Created by Anthony Aguilar on 7/5/23.

import SwiftUI

struct IncidentHeader: View {
    var incident: Incident
    var drop: Bool?
    var text = ""
    var disabled: Bool = false
    var isLoading: Bool = false

    var body: some View {
        HStack(spacing: appTheme.gridItemSpacing) {
            IncidentDisasterImage(
                incident,
                disabled: disabled
            )

            Text(text.isBlank ? incident.shortName : text)
                .fontHeader1()

            if drop != nil {
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
