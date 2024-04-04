import SwiftUI

struct IncidentSelectView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: IncidentSelectViewModel
    var onDismiss: () -> Void

    @State private var isRefreshing = false
    @State private var animateIsRefreshing = false

    var body: some View{
        VStack {
            Text(t.t("nav.change_incident"))
                .fontHeader3()
                .padding(.top)

            ZStack {
                let selectedId = viewModel.incidentsData.selectedId
                ScrollViewReader { scrollView in
                    List(viewModel.incidentsData.incidents, id: \.id) { incident in
                        let isSelected = selectedId == incident.id
                        Text(incident.name)
                            .bold(isSelected)
                            .fullWidthSelector()
                            .onTapGesture {
                                viewModel.incidentSelector.setIncident(incident)
                                onDismiss()
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
                            }
                        }
                    }
                    .onChange(of: isRefreshing) { newValue in
                        withAnimation {
                            animateIsRefreshing = newValue
                        }
                    }
                }

                if animateIsRefreshing {
                    ProgressView()
                        .circularProgress()
                        .padding()
                }
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
