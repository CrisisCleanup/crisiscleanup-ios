import SwiftUI

struct CaseIncidentView: View {
    let incident: Incident
    let isPendingSync: Bool
    let isSyncing: Bool
    let scheduleSync: () -> Void

    var body: some View {
        HStack{
            IncidentHeaderView(incident: incident)
            Spacer()
            Group {
                if isSyncing {
                    Image(systemName: "arrow.triangle.2.circlepath")
                } else if isPendingSync {
                    Button {
                        scheduleSync()
                    } label: {
                        Image(systemName: "icloud.slash.fill")
                    }
                    .tint(appTheme.colors.primaryOrangeColor)
                }
            }
            .padding()
        }
    }
}

struct CaseIncidentView_Previews: PreviewProvider {
    struct PendingSyncPreview: View {
        var body: some View {
            CaseIncidentView(
                incident: Incident(
                    id: 0,
                    name: "Heavy showers over the hill",
                    shortName: "Showers",
                    caseLabel: "E",
                    locationIds: [],
                    activePhoneNumbers: [],
                    formFields: [],
                    turnOnRelease: false,
                    disasterLiteral: Disaster.floodRain.literal
                ),
                isPendingSync: true,
                isSyncing: false,
                scheduleSync: {}
            )
        }
    }

    struct IsSyncingPreview: View {
        var body: some View {
            CaseIncidentView(
                incident: Incident(
                    id: 0,
                    name: "Heavy showers over the hill",
                    shortName: "Showers",
                    caseLabel: "E",
                    locationIds: [],
                    activePhoneNumbers: [],
                    formFields: [],
                    turnOnRelease: false,
                    disasterLiteral: Disaster.floodRain.literal
                ),
                isPendingSync: false,
                isSyncing: true,
                scheduleSync: {}
            )
        }
    }

    static var previews: some View {
        NavigationStack {
            PendingSyncPreview()
            IsSyncingPreview()
        }
    }
}
