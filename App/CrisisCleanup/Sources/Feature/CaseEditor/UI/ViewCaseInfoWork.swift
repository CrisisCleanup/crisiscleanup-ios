import SwiftUI

struct InfoWorkView : View {
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: ViewCaseViewModel

    let profile: WorkTypeProfile

    var body: some View {
        HStack {
            ViewCaseRowHeader(rowNum: 3, rowTitle: viewModel.t("caseForm.work"))

            Spacer()

            VStack (alignment: .trailing) {
                if profile.unclaimed.isNotEmpty {
                    WorkTypeAction(viewModel.t("actions.claim_all_alt"), true) {
                        viewModel.claimAll()
                    }
                }

                if profile.releasableCount > 0 {
                    WorkTypeAction(viewModel.t("actions.release_all"), false) {
                        viewModel.releaseAll()
                    }
                } else if profile.requestableCount > 0 {
                    WorkTypeAction(viewModel.t("actions.request_all"), false) {
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
            WorkTypeSectionTitle(viewModel.t("caseView.unclaimed_work_types"))
            ExistingWorkTypeItems(summaries: profile.unclaimed)
        }

        Rectangle()
            .fill(.clear)
            .frame(height: 4)
            .background(.clear)
    }
}

private struct WorkTypeAction: View {
    @EnvironmentObject var editableView: EditableView

    private let title: String
    private let isPrimary: Bool
    private let action: () -> Void

    init(
        _ title: String,
        _ isPrimary: Bool,
        _ action: @escaping () -> Void
    ) {
        self.title = title
        self.isPrimary = isPrimary
        self.action = action
    }

    var body: some View {
        let isDisabled = editableView.disabled
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
            } else {
                let borderColor: Color = isDisabled ? .gray : .black
                Text(title)
                    .lineLimit(1)
                    .padding()
                    .frame(minWidth: 100)
                    .background(.white)
                    .cornerRadius(appTheme.cornerRadius)
                    .tint(.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: appTheme.cornerRadius)
                            .stroke(borderColor, lineWidth: 1)
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
        let font = isSmallTitle ? Font.caption : Font.body
        Text(title)
            .font(font)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WorkTypeSummaryView: View {
    @EnvironmentObject var viewModel: ViewCaseViewModel

    var summary: WorkTypeSummary

    var body: some View {
        VStack {
            Text(summary.name)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            if summary.jobSummary.isNotBlank {
                Text(summary.jobSummary)
                    .font(.callout)
                    .padding(.vertical, 1.0)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                WorkTypeStatusPicker(
                    translator: viewModel,
                    selectedStatus: summary.workType.status,
                    statusOptions: viewModel.statusOptions
                ) { status in
                    viewModel.updateWorkType(summary.workType.copy {
                        $0.statusLiteral = status.literal
                    })
                }

                Spacer()

                if summary.workType.isClaimed {
                    if summary.isClaimedByMyOrg {
                        WorkTypeAction(viewModel.t("actions.unclaim"), false) {
                            viewModel.updateWorkType(summary.workType.copy {
                                $0.orgClaim = nil
                            })
                        }
                    } else if summary.isReleasable {
                        WorkTypeAction(viewModel.t("actions.release"), false) {
                            viewModel.releaseWorkType(summary.workType)
                        }
                    } else if summary.isRequested {
                        Text(viewModel.t("caseView.requested"))
                    } else {
                        WorkTypeAction(viewModel.t("actions.request"), false) {
                            viewModel.requestWorkType(summary.workType)
                        }
                    }
                } else {
                    WorkTypeAction(viewModel.t("actions.claim"), true) {
                        viewModel.updateWorkType(summary.workType.copy {
                            $0.orgClaim = summary.myOrgId
                        })
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
    @EnvironmentObject var viewModel: ViewCaseViewModel

    var orgClaimWorkType: OrgClaimWorkType

    var body: some View {
        if orgClaimWorkType.isMyOrg {
            WorkTypeSectionTitle(viewModel.t("caseView.claimed_by_my_org"))
        } else {
            WorkTypeSectionTitle(viewModel.t("caseView.claimed_by"), true)
            WorkTypeSectionTitle(viewModel.t(orgClaimWorkType.orgName))
        }

        ExistingWorkTypeItems(
            summaries: orgClaimWorkType.workTypes
        )
    }
}
