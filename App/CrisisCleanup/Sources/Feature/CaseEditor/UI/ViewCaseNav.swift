import SwiftUI

internal struct ViewCaseNav: View {
    var isSideNav = false

    var body: some View {
        if isSideNav {
            SideNav()
        } else {
            BottomNav()
        }
    }
}

private struct BottomNavButton: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var editableView: EditableView

    private let action: () -> Void
    private let imageName: String
    private let textTranslateKey: String

    init(
        _ imageName: String,
        _ textTranslateKey: String,
        _ action: @escaping () -> Void
    ) {
        self.imageName = imageName
        self.textTranslateKey = textTranslateKey
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            VStack {
                Image(imageName, bundle: .module)
                Text(t.t(textTranslateKey))
                    .fontBodySmall()
            }
        }
        .disabled(editableView.disabled)
    }
}

private struct BottomNav: View {
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: ViewCaseViewModel
    @EnvironmentObject var focusableViewState: TextInputFocusableView

    var body: some View {
        if focusableViewState.isFocused {
            OpenKeyboardActionsView()
        } else {
            HStack {
                BottomNavButton("ic_case_share", "actions.share")
                {
                    router.openCaseShare()
                }
                Spacer()
                BottomNavButton("ic_case_flag", "nav.flag") {
                    router.openCaseFlags(isFromCaseEdit: true)
                }
                Spacer()
                BottomNavButton("ic_case_history", "actions.history") {
                    router.openCaseHistory()
                }
                Spacer()
                BottomNavButton("ic_case_edit", "actions.edit") {
                    router.createEditCase(
                        incidentId: viewModel.incidentIdIn,
                        worksiteId: viewModel.worksiteIdIn
                    )
                }
            }
            // TODO: Common dimensions and styling
            .padding(.horizontal, 24)
            // TODO: Change padding on device and see if takes
            .padding(.top)
            .tint(.black)
        }
    }
}

private struct SideNav: View {
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: ViewCaseViewModel

    var body: some View {
        // TODO: Common dimensions
        VStack(spacing: 16) {
            Spacer()
            BottomNavButton("ic_case_share", "actions.share")
            {
                router.openCaseShare()
            }
            BottomNavButton("ic_case_flag", "nav.flag") {
                router.openCaseFlags(isFromCaseEdit: true)
            }
            BottomNavButton("ic_case_history", "actions.history") {
                router.openCaseHistory()
            }
            BottomNavButton("ic_case_edit", "actions.edit") {
                router.createEditCase(
                    incidentId: viewModel.incidentIdIn,
                    worksiteId: viewModel.worksiteIdIn
                )
            }
        }
        .padding(.horizontal, appTheme.listItemVerticalPadding)
        .tint(.black)
    }
}
