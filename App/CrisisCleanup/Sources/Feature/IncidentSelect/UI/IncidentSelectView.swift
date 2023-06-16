import SwiftUI

struct IncidentSelectView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: IncidentSelectViewModel
    var onDismiss: () -> Void

    @State private var incidentSheetSize: CGSize = .zero

    var body: some View{
        VStack {
            HStack {
                let count = viewModel.incidentsData.incidents.count
                Text("Present incident select \(count)")
            }
            .padding()
            Button(t("actions.close")) {
                onDismiss()
            }
        }
        .padding()
        .overlay {
            GeometryReader { geometry in
                Color.clear.preference(key: FloatPreferenceKey.self, value: geometry.size.height)
            }
        }
        .onPreferenceChange(FloatPreferenceKey.self) { incidentSheetSize.height = $0 }
        .presentationDetents([.height(incidentSheetSize.height)])
    }
}
