import SwiftUI

struct LoginMagicLinkCodeView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: LoginWithMagicLinkViewModel

    let dismiss: () -> Void

    var body: some View {
        ZStack {
            if viewModel.errorMessage.isNotBlank {
                VStack {
                    Text(viewModel.errorMessage)
                        .listItemModifier()

                    Spacer()
                }
            }

            if viewModel.isAuthenticating {
                ProgressView()
                    .frame(alignment: .center)
            }
        }
        .screenTitle(t.t("actions.login"))
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .onChange(of: viewModel.isAuthenticateSuccessful) { b in
            if b {
                router.returnToAuth()
                dismiss()
            }
        }
    }
}
