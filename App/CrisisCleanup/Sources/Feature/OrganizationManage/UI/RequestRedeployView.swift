import SwiftUI

struct RequestRedeployView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: RequestRedeployViewModel

    @State private var animateLoading = true

    @State private var selectedIncident = EmptyIncident

    @State private var showIncidentOptions = false

    var body: some View {
        ZStack {
            if animateLoading {
                ProgressView()
            } else if viewModel.isRedeployRequested {
                VStack {
                    Text(t.t("requestRedeploy.request_redeploy_success"))
                        .listItemModifier()
                    Spacer()
                }
            } else {
                let incidents = viewModel.viewState.incidents

                if incidents.isEmpty {
                    VStack {
                        Text(t.t("~~There are no Incidents left for deploying."))
                            .listItemModifier()
                        Spacer()
                    }
                } else {
                    let isTransient = viewModel.isTransient
                    let isEditable = !isTransient
                    let errorMessage = viewModel.redeployErrorMessage
                    let requestedIncidentIds = viewModel.requestedIncidentIds
                    let isRequestingRedeploy = viewModel.isRequestingRedeploy

                    let selectIncidentHint = t.t("actions.select_incident")
                    let selectedIncidentText = selectedIncident.name.ifBlank { selectIncidentHint }

                    VStack {
                        Text(t.t("requestRedeploy.choose_an_incident"))
                            .listItemModifier()

                        if errorMessage.isNotBlank {
                            Text(errorMessage)
                                .listItemPadding()
                                .foregroundColor(appTheme.colors.primaryRedColor)
                        }

                        if showIncidentOptions {
                            Spacer()
                        } else {
                            HStack {
                                Text(selectedIncidentText)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                            }
                            .textFieldBorder()
                            .listItemModifier()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showIncidentOptions = true
                            }

                            Spacer()

                            HStack {
                                Button(t.t("actions.cancel")) {
                                    dismiss()
                                }
                                .styleCancel()
                                .disabled(!isEditable)

                                Button {
                                    viewModel.requestRedeploy(incident: selectedIncident)
                                } label: {
                                    BusyButtonContent(
                                        isBusy: isRequestingRedeploy,
                                        text: t.t("actions.submit")
                                    )
                                }
                                .stylePrimary()
                                .disabled(!isEditable || selectedIncident == EmptyIncident)
                            }
                            .listItemPadding()
                        }
                    }
                    // TODO: Common dimensions
                    .frame(maxWidth: 600.0)
                    .sheet(isPresented: $showIncidentOptions) {
                        Text(selectIncidentHint)
                            .fontHeader3()
                            .padding(.top)

                        List(incidents, id: \.id) { incident in
                            let isSelected = incident.id == selectedIncident.id
                            let isRequested = requestedIncidentIds.contains(incident.id)
                            Text(incident.displayLabel)
                                .bold(isSelected)
                                .fullWidthSelector()
                                // TODO: Use newer APIs where possible
                                // if #available(iOS 17, *) {
                                //    .selectionDisabled(isRequested)
                                .if (isRequested) {
                                    $0.tag("disabled")
                                        .foregroundColor(.black.disabledAlpha())
                                }
                                .onTapGesture {
                                    if !isRequested {
                                        selectedIncident = incident
                                        showIncidentOptions = false
                                    }
                                }
                        }

                        Button(t.t("actions.close")) {
                            showIncidentOptions = false
                        }
                        .padding()
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
