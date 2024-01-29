import SwiftUI

internal struct LocationOutOfBoundsAlert: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CaseChangeLocationAddressViewModel

    let outOfBoundsData: LocationOutOfBounds

    var body: some View {
        VStack(alignment: .leading) {
            let isInRecentIncidentBounds = outOfBoundsData.recentIncident != nil

            let incident = outOfBoundsData.recentIncident ?? outOfBoundsData.incident

            let titleKey = isInRecentIncidentBounds ? "caseForm.incorrect_location" : "caseForm.case_outside_incident"
            let title = t.t(titleKey)
            let text = isInRecentIncidentBounds
            ? t.t("caseForm.suggested_incident")
                .replacingOccurrences(of: "{incident}", with: incident.name)
            : t.t("caseForm.warning_case_outside_incident")
                .replacingOccurrences(of: "{incident}", with: incident.name)

            Text(title)
                .fontHeader3()
                .frame(maxWidth: .infinity, alignment: .leading)
                .listItemModifier()
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .listItemModifier()

            Spacer()

            HStack(spacing: appTheme.nestedItemPadding) {
                Button {
                    viewModel.acceptOutOfBounds(outOfBoundsData)
                } label: {
                    let actionTextKey = isInRecentIncidentBounds ? "caseForm.no" : "actions.continue_anyway"
                    Text(t.t(actionTextKey))
                        .fontHeader4()
                }

                Button {
                    if isInRecentIncidentBounds {
                        viewModel.changeIncidentOutOfBounds(outOfBoundsData)
                    } else {
                        viewModel.cancelOutOfBounds()
                    }
                } label: {
                    let actionTextKey = isInRecentIncidentBounds ? "caseForm.yes" : "actions.retry"
                    Text(t.t(actionTextKey))
                        .fontHeader4()
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding()
        }
    }
}
