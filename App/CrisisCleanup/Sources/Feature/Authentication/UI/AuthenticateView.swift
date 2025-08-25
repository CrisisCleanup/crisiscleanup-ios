import SwiftUI

struct AuthenticateView: View {
    @ObservedObject var viewModel: AuthenticateViewModel

    let dismiss: () -> Void

    var body: some View {
        ZStack {
            let viewData = viewModel.viewData
            if viewData.state == .loading {
                ProgressView()
                    .frame(alignment: .center)
            } else if viewData.isAccountValid {
                LogoutView(
                    dismissScreen: dismiss
                )
            } else {
                LoginOptionsView(
                    dismissScreen: dismiss
                )
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
    }
}

private struct LoginOptionsView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.openURL) var openURL

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: AuthenticateViewModel

    let dismissScreen: () -> Void

    var body: some View {
        ScrollCenterContent {
            CrisisCleanupLogoView()

            let hotlineIncidents = viewModel.hotlineIncidents
            if hotlineIncidents.isNotEmpty {
                Rectangle()
                    .fill(.clear)
                    .background(.clear)
                    // TODO: Common dimensions
                    .frame(height: 32)
            }
            HotlineIncidentsView(
                incidents: hotlineIncidents,
                linkifyPhoneNumbers: true,
                expandHotline: true
            )

            VStack(alignment: .leading, spacing: appTheme.gridActionSpacing) {
                Text(t.translate("actions.login", "Login action"))
                    .fontHeader1()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical)
                    .accessibilityIdentifier("rootAuthLoginText")

                Button(t.translate("loginForm.login_with_email", "Login with email")) {
                    router.openEmailLogin()
                }
                .stylePrimary()
                .accessibilityIdentifier("loginWithEmailAction")

                Button(t.translate("loginForm.login_with_cell", "Login with phone")) {
                    router.openPhoneLogin()
                }
                .stylePrimary()
                .accessibilityIdentifier("loginWithPhoneAction")

                Button(t.translate("actions.request_access", "Volunteer with org")) {
                    router.openVolunteerOrg()
                }
                .styleOutline()
                .disabled(viewModel.viewData.hasAuthenticated)
                .accessibilityIdentifier("rootAuthVolunteerWithOrgAction")

                Button(t.translate("loginForm.need_help_cleaning_up", "I need cleanup")) {
                    openURL(URL(string: "https://crisiscleanup.org/survivor")!)
                }
                .styleOutline()
                .accessibilityIdentifier("rootAuthNeedHelpAction")

                if viewModel.showRegister {
                    VStack(alignment: .leading) {
                        Text(t.translate("publicNav.relief_orgs_only", "Relief orgs and goverment only"))
                            .accessibilityIdentifier("rootAuthReliefOrgAndGovText")

                        Link(
                            t.translate("actions.register", "Register action"),
                            destination: URL(string: "https://crisiscleanup.org/register")!
                        )
                        .accessibilityIdentifier("rootAuthRegisterAction")
                    }
                    .padding(.top)
                }

                if viewModel.viewData.hasAuthenticated {
                    Button(t.translate("actions.back", "Back action")) {
                        dismissScreen()
                    }
                    .padding(.vertical, appTheme.listItemVerticalPadding)
                    .accessibilityIdentifier("rootAuthBackAction")
                }
            }
            .padding()
        }
    }
}

struct LogoutView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: AuthenticateViewModel

    var dismissScreen: () -> ()

    var body: some View {
        ScrollCenterContent {
            CrisisCleanupLogoView()
                .padding(.bottom)

            VStack(alignment: .leading) {
                Text(viewModel.accountInfo)
                    .padding(.bottom)
                    .accessibilityIdentifier("authedAccountInfoText")

                if viewModel.organizationInfo.isNotBlank {
                    Text(viewModel.organizationInfo)
                        .padding(.bottom)
                }

                Button(t.t("actions.logout")) {
                    viewModel.logout()
                }
                .stylePrimary()
                .padding(.bottom)
                .accessibilityIdentifier("authedLogoutAction")

                Button(t.t("actions.back")) {
                    dismissScreen()
                }
                .padding(.vertical, appTheme.listItemVerticalPadding)
                .accessibilityIdentifier("authedCloseScreenAction")
            }
            .padding()
        }
    }
}
