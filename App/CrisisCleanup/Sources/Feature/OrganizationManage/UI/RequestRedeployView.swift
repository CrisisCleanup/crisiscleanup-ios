import SwiftUI

struct RequestRedeployView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: RequestRedeployViewModel

    @State private var animateLoading = true

    @State private var selectedIncident = EmptyIncidentIdNameType

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
                        Text(t.t("info.deployed_to_all_incidents"))
                            .listItemModifier()
                        Spacer()
                    }
                } else {
                    let isTransient = viewModel.isTransient
                    let isEditable = !isTransient
                    let errorMessage = viewModel.redeployErrorMessage
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
                                .disabled(!isEditable || selectedIncident == EmptyIncidentIdNameType)
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

                        let approvedIds = viewModel.viewState.approvedIncidentIds
                        let requestedIds = viewModel.viewState.requestedIncidentIds

                        List(incidents, id: \.id) { incident in
                            let isSelected = incident.id == selectedIncident.id
                            let isApproved = approvedIds.contains(incident.id)
                            let isRequested = requestedIds.contains(incident.id)
                            let disabled = isApproved || isRequested
                            HStack(spacing: appTheme.gridItemSpacing) {
                                Text(incident.name)
                                    .bold(isSelected)
                                    .fullWidthSelector()
                                // TODO: Use newer APIs where possible
                                // if #available(iOS 17, *) {
                                //    .selectionDisabled(isRequested)
                                    .if (disabled) {
                                        $0.tag("disabled")
                                            .foregroundColor(.black.disabledAlpha())
                                    }
                                    .onTapGesture {
                                        if !disabled {
                                            selectedIncident = incident
                                            showIncidentOptions = false
                                        }
                                    }

                                Spacer()

                                if isApproved {
                                    Image(systemName: "checkmark")
                                    .foregroundColor(appTheme.colors.green600)
                                } else if isRequested {
                                    Image(systemName: "clock")
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
