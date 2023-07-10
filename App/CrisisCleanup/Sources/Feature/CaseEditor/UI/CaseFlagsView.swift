import SwiftUI

struct CaseFlagsView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: CaseFlagsViewModel

    var body: some View {
        Text("Case flags under construction")
    }
}
