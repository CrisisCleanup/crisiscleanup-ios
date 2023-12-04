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
    @Environment(\.openURL) var openURL

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

                    Button(t.translate("loginForm.login_with_email", "Login with email")) {
                        router.openEmailLogin()
                    }
                    .stylePrimary()

                    Button(t.translate("loginForm.login_with_cell", "Login with phone")) {
                        router.openPhoneLogin()
                    }
                    .stylePrimary()

                    Button(t.translate("actions.request_access", "Volunteer with org")) {
                        router.openVolunteerOrg()
                    }
                    .styleOutline()
                    .disabled(viewModel.viewData.hasAuthenticated)

                    Button(t.translate("loginForm.need_help_cleaning_up", "I need cleanup")) {
                        openURL(URL(string: "https://crisiscleanup.org/survivor")!)
                    }
                    .styleOutline()

                    VStack(alignment: .leading) {
                        Text(t.translate("publicNav.relief_orgs_only", "Relief orgs and goverment only"))

                        Link(
                            t.translate("actions.register", "Register action"),
                            destination: URL(string: "https://crisiscleanup.org/register")!
                        )
                    }
                    .padding(.top)

                    if viewModel.viewData.hasAuthenticated {
                        Button(t.translate("actions.back", "Back action")) {
                            dismissScreen()
                        }
                        .padding(.vertical, appTheme.listItemVerticalPadding)
                    }
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
