import SwiftUI

internal struct ViewCaseHeaderText: View {
    var headerTitle: String = ""
    var headerSubTitle: String = ""

    var body: some View {
        if headerTitle.isNotBlank {
            Text(headerTitle)
                .fontHeader3()
        }
        if headerSubTitle.isNotBlank {
            Text(headerSubTitle)
                .fontBodySmall()
        }
    }
}

internal struct ViewCaseHeaderActions: View {
    @EnvironmentObject var viewModel: ViewCaseViewModel

    private func getTopIconActionColor(_ isActive: Bool) -> Color {
        isActive ? appTheme.colors.primaryRedColor : appTheme.colors.neutralIconColor
    }

    var body: some View {
        let disable = viewModel.editableViewState.disabled

        Button {
            viewModel.toggleHighPriority()
        } label: {
            let tint = getTopIconActionColor(viewModel.referenceWorksite.hasHighPriorityFlag)
            Image(systemName: "exclamationmark.triangle.fill")
                .tint(tint)
        }
        .disabled(disable)

        Button {
            viewModel.toggleFavorite()
        } label: {
            let isFavorite = viewModel.referenceWorksite.isLocalFavorite
            let tint = getTopIconActionColor(isFavorite)
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .tint(tint)
        }
        .disabled(disable)
    }
}

internal struct ViewCaseUpdatedAtView: View {
    var updatedAt: String = ""
    var addPadding = false

    var body: some View {
        if updatedAt.isNotBlank {
            Text(updatedAt)
                .fontBodySmall()
                .if (addPadding) {
                    $0.listItemModifier()
                }
        }
    }
}

internal struct ViewCaseSideHeader: View {
    @EnvironmentObject var viewModel: ViewCaseViewModel

    var body: some View {
        HStack {
            ViewCaseNav(isSideNav: true)

            VStack(alignment: .leading, spacing: appTheme.listItemVerticalPadding) {
                ViewCaseHeaderText(headerSubTitle: viewModel.subTitle)
                    .padding(.vertical, appTheme.listItemVerticalPadding)

                ViewCaseUpdatedAtView(updatedAt: viewModel.updatedAtText)

                Spacer()

                // TODO: Common dimensions
                HStack(spacing: 24) {
                    ViewCaseHeaderActions()
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
