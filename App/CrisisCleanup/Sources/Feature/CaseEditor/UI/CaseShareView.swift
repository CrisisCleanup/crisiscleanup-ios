import SwiftUI

struct CaseShareView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: CaseShareViewModel

    var body: some View {
        Text("Case share under construction")
    }
}
