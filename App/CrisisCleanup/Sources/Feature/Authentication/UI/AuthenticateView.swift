import SwiftUI

struct AuthenticateView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: AuthenticateViewModel

    let dismiss: () -> Void

    var body: some View {
        ZStack {
            let viewData = viewModel.viewData
            if viewData.state == .loading {
                ProgressView()
                    .frame(alignment: .center)
            } else {
                if viewData.isAccountValid {
                    let logout = { viewModel.logout() }
                    LogoutView(
                        viewModel: viewModel,
                        logout: logout,
                        dismissScreen: dismiss
                    )
                } else {
                    LoginOptionsView(
                        viewModel: viewModel,
                        dismissScreen: dismiss
                    )
                }
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}

private struct LoginOptionsView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: AuthenticateViewModel

    let dismissScreen: () -> Void

    var body: some View {
        VStack {
            ScrollView {
                CrisisCleanupLogoView()

                // TODO: Common dimensions
                VStack(alignment: .leading, spacing: 16) {
                    Text(t.translate("actions.login", "Login action"))
                        .fontHeader1()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical)

                    Button(t.t("loginForm.login_with_email")) {
                        router.openEmailLogin()
                    }
                    .stylePrimary()

                    Button(t.t("loginForm.login_with_cell")) {
                        // TODO: Do
                    }
                    .stylePrimary()
                    .disabled(true)

                    Button(t.t("actions.request_access")) {
                        // TODO: Do
                    }
                    .styleOutline()
                    .disabled(true)

                    Button(t.t("loginForm.need_help_cleaning_up")) {
                        // TODO: Do
                    }
                    .styleOutline()

                    VStack(alignment: .leading) {
                        Text(t.t("publicNav.relief_orgs_only"))

                        Button(t.t("actions.register")) {
                            // TODO: Web link
                        }
                    }
                    .padding(.top)
                }
                .padding()
            }
        }
    }
}

struct LogoutView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @ObservedObject var viewModel: AuthenticateViewModel
    var logout: () -> ()
    var dismissScreen: () -> ()

    var body: some View {
        ScrollView {
            CrisisCleanupLogoView()
                .padding(.bottom)

            VStack{
                Button(t.t("actions.logout")) {
                    logout()
                }
                .stylePrimary()
                .padding([.vertical])

                Button {
                    dismissScreen()
                } label:  {
                    Text(t.t("actions.back"))
                }
                .padding(.vertical, appTheme.listItemVerticalPadding)
            }
            .padding()
        }
    }
}
