import SwiftUI

struct IncidentSelectView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: IncidentSelectViewModel
    var onDismiss: () -> Void

    @State private var isRefreshing = false
    @State private var animateIsRefreshing = false
    @State private var animateIsLoadingIncidents = false

    var body: some View{
        VStack {
            let incidents = viewModel.incidentsData.incidents
            let isLoadingIncidents = viewModel.isLoadingIncidents
            ZStack {
                if incidents.isEmpty {
                    ReloadIncidentsView(isRefreshingIncidents: isLoadingIncidents) {
                        viewModel.refreshIncidents()
                    }
                } else {
                    Text(t.t("nav.change_incident"))
                        .fontHeader3()
                        .padding(.top)

                    let selectedId = viewModel.incidentsData.selectedId

                    let incidentId0 = incidents.isNotEmpty ? incidents[0].id : -1
                    ScrollViewReader { scrollView in
                        List(incidents, id: \.id) { incident in
                            let isSelected = selectedId == incident.id
                            Text(incident.displayLabel)
                                .bold(isSelected)
                                .fullWidthSelector()
                                .onTapGesture {
                                    viewModel.incidentSelector.selectIncident(incident)
                                    onDismiss()
                                }
                                .if (incident.id == incidentId0) {
                                    $0.id("first-incident-item")
                                }
                        }
                        .task {
                            viewModel.onOptionsRendered()
                        }
                        .onChange(of: viewModel.selectedIncidentId) { id in
                            if id > -1 {
                                scrollView.scrollTo(id, anchor: .top)
                            }
                        }
                        .refreshable {
                            isRefreshing = true
                            Task {
                                do {
                                    defer  { isRefreshing = false}

                                    await viewModel.pullIncidents()
                                    withAnimation {
                                        scrollView.scrollTo("first-incident-item", anchor: .top)
                                    }
                                }
                            }
                        }
                        .onChange(of: isRefreshing) { newValue in
                            withAnimation {
                                animateIsRefreshing = newValue
                            }
                        }
                    }
                }

                if animateIsRefreshing || animateIsLoadingIncidents {
                    ProgressView()
                        .circularProgress()
                        .padding()
                }
            }
            .onChange(of: isLoadingIncidents) { newValue in
                animateIsLoadingIncidents = newValue
            }

            Button(t.t("actions.close")) {
                onDismiss()
            }
            .padding()
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}
