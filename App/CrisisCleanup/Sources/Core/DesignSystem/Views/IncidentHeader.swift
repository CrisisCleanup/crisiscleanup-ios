//  Created by Anthony Aguilar on 7/5/23.

import SwiftUI

struct IncidentHeader: View {
    var incident: Incident

    var body: some View {
        HStack {
            IncidentDisasterImage(incident)
            Text(incident.shortName)
                .fontHeader1()
        }
    }
}
