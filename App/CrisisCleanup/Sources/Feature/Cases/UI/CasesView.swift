import SwiftUI

struct CasesView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CasesViewModel
    let incidentSelectViewBuilder: IncidentSelectViewBuilder

    var body: some View {
        Text(t("casesVue.cases"))
    }
}
