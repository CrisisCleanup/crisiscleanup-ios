import SwiftUI

struct IncidentSelectView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: IncidentSelectViewModel
    var onDismiss: () -> Void

    @State private var incidentSheetSize: CGSize = .zero

    var body: some View{
        VStack {
            Text(t("nav.change_incident")).frame(alignment: .bottom).padding()
                List(viewModel.incidentsData.incidents, id: \.id) { ee in
                    let isSelected: Bool = viewModel.incidentsData.selected.id == ee.id
                    HStack {
                        Text(ee.name).bold(isSelected).onTapGesture {
                            viewModel.incidentSelector.setIncident(incident: ee)
                            onDismiss()
                        }
                    }
                }
            Button(t("actions.close")) {
                onDismiss()
            }
        }
    }
}
