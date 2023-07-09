import SwiftUI

// TODO: Disable interactivity during loading or saving
struct InfoWorkView : View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter

    let profile: WorkTypeProfile

    var body: some View {
        HStack {
            ViewCaseRowHeader(rowNum: 3, rowTitle: t("caseForm.work"))

            VStack (alignment: .trailing) {
                if profile.unclaimed.isNotEmpty {
                    WorkTypeAction(t("actions.claim_all_alt"), true) {
                        // TODO: Claim all
                    }
                }

                if profile.releasableCount > 0 {
                    WorkTypeAction(t("actions.release_all"), false) {
                        // TODO: Release all
                    }
                } else if profile.requestableCount > 0 {
                    WorkTypeAction(t("actions.request_all"), false) {
                        // TODO: Release all
                    }
                }
            }
            .padding(.trailing)
        }

        if profile.otherOrgClaims.isNotEmpty {
            ForEach(profile.otherOrgClaims) { otherOrgClaim in
                OrganizationWorkClaims(
                    orgClaimWorkType: otherOrgClaim,
                    // TODO: View model callbacks
                    updateWorkType: {_ in },
                    requestWorkType: {_ in },
                    releaseWorkType: {_ in }
                )
            }
        }

        if profile.orgClaims.workTypes.isNotEmpty {
            OrganizationWorkClaims(
                orgClaimWorkType: profile.orgClaims,
                // TODO: View model callbacks
                updateWorkType: {_ in },
                requestWorkType: {_ in },
                releaseWorkType: {_ in }
            )
        }

        if profile.unclaimed.isNotEmpty {
            WorkTypeSectionTitle(t("caseView.unclaimed_work_types"))
            ExistingWorkTypeItems(
                summaries: profile.unclaimed,
                // TODO: View model callbacks
                updateWorkType: {_ in },
                requestWorkType: {_ in },
                releaseWorkType: {_ in }
            )
        }

        Rectangle()
            .fill(.clear)
            .frame(height: 4)
            .background(.clear)
    }
}

private struct WorkTypeAction: View {
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
        Button {
            action()
        } label: {
            if isPrimary {
                Text(title)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.5)
                    .padding()
                    .frame(minWidth: 100)
                    .background(appTheme.colors.themePrimaryContainer)
                    .cornerRadius(appTheme.cornerRadius)
                    .tint(.black)
            } else {
                Text(title)
                    .lineLimit(1)
                    .padding()
                    .frame(minWidth: 100)
                    .background(Color.white)
                    .border(.black, width: 2)
                    .cornerRadius(appTheme.cornerRadius)
                    .tint(.black)
            }
        }
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
    @Environment(\.translator) var t: KeyAssetTranslator

    var summary: WorkTypeSummary
    var updateWorkType: (WorkType) -> Void
    var requestWorkType: (WorkType) -> Void
    var releaseWorkType: (WorkType) -> Void

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
                    selectedStatus: summary.workType.status
                ) { status in
                    updateWorkType(summary.workType.copy {
                        $0.statusLiteral = status.literal
                    })
                }

                Spacer()

                if summary.workType.isClaimed {
                    if summary.isClaimedByMyOrg {
                        WorkTypeAction(t("actions.unclaim"), false) {
                            updateWorkType(summary.workType.copy {
                                $0.orgClaim = nil
                            })
                        }
                    } else if summary.isReleasable {
                        WorkTypeAction(t("actions.release"), false) {
                            releaseWorkType(summary.workType)
                        }
                    } else if summary.isRequested {
                        Text(t("caseView.requested"))
                    } else {
                        WorkTypeAction(t("actions.request"), false) {
                            requestWorkType(summary.workType)
                        }
                    }
                } else {
                    WorkTypeAction(t("actions.claim"), true) {
                        updateWorkType(summary.workType.copy {
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
    var updateWorkType: (WorkType) -> Void
    var requestWorkType: (WorkType) -> Void
    var releaseWorkType: (WorkType) -> Void

    var body: some View {
        ForEach(summaries) { summary in
            WorkTypeSummaryView(
                summary: summary,
                updateWorkType: updateWorkType,
                requestWorkType: requestWorkType,
                releaseWorkType: releaseWorkType
            )
            .cardContainer()
            .padding(.horizontal)
            .padding(.top, 1.0)
        }
    }
}

private struct OrganizationWorkClaims: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    var orgClaimWorkType: OrgClaimWorkType
    var updateWorkType: (WorkType) -> Void
    var requestWorkType: (WorkType) -> Void
    var releaseWorkType: (WorkType) -> Void

    var body: some View {
        if orgClaimWorkType.isMyOrg {
            WorkTypeSectionTitle(t("caseView.claimed_by_my_org"))
        } else {
            WorkTypeSectionTitle(t("caseView.claimed_by"), true)
            WorkTypeSectionTitle(t(orgClaimWorkType.orgName))
        }

        ExistingWorkTypeItems(
            summaries: orgClaimWorkType.workTypes,
            updateWorkType: updateWorkType,
            requestWorkType: requestWorkType,
            releaseWorkType: releaseWorkType
        )
    }
}

private struct WorkTypeStatusPicker: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    var selectedStatus: WorkTypeStatus
    var onSelectStatus: (WorkTypeStatus) -> Void

    let pickerStatusOptions: [String: Color] = [
        "unknown": Color.black,
        "open_assigned": Color.yellow,
        "open_unassigned": Color.orange,
        "open_partially-completed": Color.blue,
        "open_needs-follow-up": Color.pink,
        "open_unresponsive": Color.gray,
        "closed_completed": Color.green,
        "closed_incomplete": Color.green,
        "closed_out-of-scope": Color.black,
        "closed_done-by-others": Color.green,
        "closed_no-help-wanted": Color.green,
        "closed_duplicate": Color.green,
        "closed_rejected": Color.black
    ]

    var body: some View {
        //        VStack {
        //            HStack {
        Text(t(selectedStatus.literal))
        //                Spacer()
        //                Text("Close")
        //                    .foregroundColor(Color.accentColor)
        //                    .padding(.trailing)
        //                    .onTapGesture {
        //                         // TODO: Dismiss picker
        //                    }
        //            }
        //            Picker("Please choose a status", selection: $selectedStatus) {
        //                let options = Array(pickerStatusOptions.keys)
        //                ForEach(options, id: \.self) { option in
        //                    HStack {
        //                        Circle()
        //                            .foregroundColor(pickerStatusOptions[option])
        //                        Text(option)
        //                            .foregroundColor(Color.black)
        //
        //                    }
        //                    .onTapGesture {
        //                         // onSelectStatus(option)
        //                    }
        //                }
        //            }
        //            .pickerStyle(.wheel)
        //        }
    }
}
