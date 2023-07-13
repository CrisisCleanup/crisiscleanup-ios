import SwiftUI

struct ViewImageView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: ViewImageViewModel

    var body: some View {
        Text("View image under construction")
    }
}
