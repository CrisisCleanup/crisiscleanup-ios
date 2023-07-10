import SwiftUI

struct CaseHistoryView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: CaseHistoryViewModel

    var body: some View {
        Text("Case history under construction")
    }
}
