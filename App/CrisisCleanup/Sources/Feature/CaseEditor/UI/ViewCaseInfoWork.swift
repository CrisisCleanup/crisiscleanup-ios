import SwiftUI

struct InfoWorkView : View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: ViewCaseViewModel

    let profile: WorkTypeProfile

    var body: some View {
        HStack(alignment: .center) {
            ViewCaseRowHeader(rowNum: 3, rowTitle: t.t("caseForm.work"))

            Spacer()

            VStack (alignment: .trailing) {
                if profile.unclaimed.isNotEmpty {
                    WorkTypeAction(t.t("actions.claim_all_alt"), true) {
                        viewModel.claimAll()
                    }
                }

                if profile.releasableCount > 0 {
                    WorkTypeAction(t.t("actions.release_all"), false) {
                        viewModel.releaseAll()
                    }
                } else if profile.requestableCount > 0 {
                    WorkTypeAction(t.t("actions.request_all"), false) {
                        viewModel.requestAll()
                    }
                }
            }
            .padding(.bottom)
        }
        .padding(.horizontal)

        if profile.otherOrgClaims.isNotEmpty {
            ForEach(profile.otherOrgClaims) { otherOrgClaim in
                OrganizationWorkClaims(orgClaimWorkType: otherOrgClaim)
            }
        }

        if profile.orgClaims.workTypes.isNotEmpty {
            OrganizationWorkClaims(orgClaimWorkType: profile.orgClaims)
        }

        if profile.unclaimed.isNotEmpty {
            WorkTypeSectionTitle(t.t("caseView.unclaimed_work_types"))
            ExistingWorkTypeItems(summaries: profile.unclaimed)
        }

        Rectangle()
            .fill(.clear)
            .frame(height: 4)
            .background(.clear)
    }
}

struct WorkTypeAction: View {
    @EnvironmentObject var editableView: EditableView

    private let title: String
    private let isPrimary: Bool
    private let disabled: Bool?
    private let action: () -> Void

    init(
        _ title: String,
        _ isPrimary: Bool,
        disabled: Bool? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isPrimary = isPrimary
        self.disabled = disabled
        self.action = action
    }

    var body: some View {
        let isDisabled = disabled ?? editableView.disabled
        Button {
            action()
        } label: {
            if isPrimary {
                let backgroundColor = isDisabled ? .gray : appTheme.colors.themePrimaryContainer
                Text(title)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.5)
                    .padding()
                    .frame(minWidth: 100)
                    .background(backgroundColor.animation(.easeInOut))
                    .cornerRadius(appTheme.cornerRadius)
                    .tint(.black)
                    .fontHeader4()
            } else {
                let borderColor: Color = isDisabled ? .gray : .black
                Text(title)
                    .lineLimit(1)
                    .padding()
                    .frame(minWidth: 100)
                    .background(.white)
                    .cornerRadius(appTheme.cornerRadius)
                    .tint(.black)
                    .fontHeader4()
                    .roundedBorder(
                        color: borderColor,
                        lineWidth: appTheme.buttonOutlineWidth
                    )
            }
        }
        .disabled(isDisabled)
    }
}

private struct WorkTypeSectionTitle: View {
    private let title: String
    private let isSmallTitle: Bool

    init(
        _ title: String,
        _ isSmallTitle: Bool = false
    ) {
        self.title = title
        self.isSmallTitle = isSmallTitle
    }

    var body: some View {
        let font = isSmallTitle ? Font.bodySmall : Font.bodyLarge
        Text(title)
            .font(font)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WorkTypeSummaryView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: ViewCaseViewModel

    var summary: WorkTypeSummary

    var body: some View {
        VStack {
            Text(summary.name)
                .frame(maxWidth: .infinity, alignment: .leading)
            if summary.jobSummary.isNotBlank {
                Text(summary.jobSummary)
                    .padding(.vertical, 1.0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fontBodySmall()
            }

            HStack {
                WorkTypeStatusPicker(
                    selectedStatus: summary.workType.status,
                    isClaimed: summary.workType.orgClaim != nil,
                    statusOptions: viewModel.statusOptions,
                    spanWidth: true
                ) { status in
                    viewModel.updateWorkType(
                        summary.workType.copy { $0.statusLiteral = status.literal },
                        true
                    )
                }

                Spacer()

                if summary.workType.isClaimed {
                    if summary.isClaimedByMyOrg {
                        WorkTypeAction(t.t("actions.unclaim"), false) {
                            viewModel.updateWorkType(
                                summary.workType.copy { $0.orgClaim = nil },
                                false
                            )
                        }
                    } else if summary.isReleasable {
                        WorkTypeAction(t.t("actions.release"), false) {
                            viewModel.releaseWorkType(summary.workType)
                        }
                    } else if summary.isRequested {
                        Text(t.t("caseView.requested"))
                    } else {
                        WorkTypeAction(t.t("actions.request"), false) {
                            viewModel.requestWorkType(summary.workType)
                        }
                    }
                } else {
                    WorkTypeAction(t.t("actions.claim"), true) {
                        viewModel.updateWorkType(
                            summary.workType.copy { $0.orgClaim = summary.myOrgId },
                            false
                        )
                    }
                }
            }
        }
        .padding()
    }
}

private struct ExistingWorkTypeItems: View {
    var summaries: [WorkTypeSummary]

    var body: some View {
        ForEach(summaries) { summary in
            WorkTypeSummaryView(summary: summary)
                .cardContainer()
                .padding(.horizontal)
                .padding(.top, 1.0)
        }
    }
}

private struct OrganizationWorkClaims: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    var orgClaimWorkType: OrgClaimWorkType

    var body: some View {
        if orgClaimWorkType.isMyOrg {
            WorkTypeSectionTitle(t.t("caseView.claimed_by_my_org"))
        } else {
            WorkTypeSectionTitle(t.t("caseView.claimed_by"), true)
            WorkTypeSectionTitle(t.t(orgClaimWorkType.orgName))
        }

        ExistingWorkTypeItems(
            summaries: orgClaimWorkType.workTypes
        )
    }
}
