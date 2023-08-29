import SwiftUI

struct IncidentSelectView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: IncidentSelectViewModel
    var onDismiss: () -> Void

    var body: some View{
        VStack {
            Text(t.t("nav.change_incident"))
                .fontHeader3()
                .padding()

            let selectedId = viewModel.incidentsData.selectedId
            ScrollViewReader { scrollView in
                List(viewModel.incidentsData.incidents, id: \.id) { incident in
                    let isSelected = selectedId == incident.id
                    Text(incident.name)
                        .bold(isSelected)
                        .onTapGesture {
                            viewModel.incidentSelector.setIncident(incident)
                            onDismiss()
                        }
                        // TODO: Common dimensions
                        .frame(height: 48)
                }
                .task {
                    viewModel.onOptionsRendered()
                }
                .onReceive(viewModel.$selectedIncidentId) { id in
                    if id > -1 {
                        scrollView.scrollTo(id, anchor: .top)
                    }
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
