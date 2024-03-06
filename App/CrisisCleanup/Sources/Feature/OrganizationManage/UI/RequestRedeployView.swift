import SwiftUI

struct RequestRedeployView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: RequestRedeployViewModel

    @State private var animateLoading = false

    @State private var selectedIncident = EmptyIncident

    var body: some View {
        ZStack {
            if animateLoading {
                ProgressView()
            } else if viewModel.isRedeployRequested {
                Text(t.t("requestRedeploy.request_redeploy_success"))
                    .listItemModifier()
            } else {
                let incidents = viewModel.viewState.incidents

                if incidents.isNotEmpty {
                    let isTransient = viewModel.isTransient
                    let isEditable = !isTransient
                    let errorMessage = viewModel.redeployErrorMessage
                    let requestedIncidentIds = viewModel.requestedIncidentIds
                    let isRequestingRedeploy = viewModel.isRequestingRedeploy

                    let selectIncidentHint = t.t("actions.select_incident")

                    VStack {
                        RequestRedeployContent(
                            isEditable: isEditable,
                            incidents: incidents,
                            requestedIncidentIds: requestedIncidentIds,
                            errorMessage: errorMessage,
                            selectedIncidentText: selectedIncident.name.ifBlank { selectIncidentHint },
                            selectIncidentHint: selectIncidentHint,
                            selectedIncident: $selectedIncident
                        )

                        Spacer()

                        // TODO: Actions
                    }
                }
            }
        }
        .hideNavBarUnderSpace()
        .screenTitle(t.t("requestRedeploy.request_redeploy"))
        .onChange(of: viewModel.isLoading) { newValue in
            animateLoading = newValue
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
    }
}

private struct RequestRedeployContent: View {
    var isEditable: Bool
    var incidents: [Incident]
    var requestedIncidentIds: Set<Int64>
    var errorMessage: String
    var selectedIncidentText: String
    var selectIncidentHint: String

    @Binding var selectedIncident: Incident

    @State private var showIncidentOptions = false

    var body: some View {
        if incidents.isNotEmpty {
            Text("Request redeploy \(incidents.count)")
        }
    }
}
