import SwiftUI

struct CasesTableView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewLayout: ViewLayoutDescription
    @EnvironmentObject var viewModel: CasesViewModel

    @Binding var phoneCallNumbers: [ParsedPhoneNumber]

    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let isLoadingIncidents: Bool
    let hasNoIncidents: Bool

    @State private var showWrongLocationDialog = false

    var body: some View {
        let isLoadingData = viewModel.isLoadingData
        let isEditable = viewModel.isTableEditable

        if viewLayout.isListDetailLayout {
            ZStack {
                GeometryReader { proxy in
                    HStack {
                        VStack(alignment: .trailing, spacing: appTheme.gridActionSpacing) {
                            TableViewIncidentSelector(
                                isLoadingIncidents: isLoadingIncidents,
                                hasNoIncidents: hasNoIncidents,
                                selectedIncident: viewModel.incidentsData.selected,
                                incidentSelectViewBuilder: incidentSelectViewBuilder,
                                isLoadingData: isLoadingData
                            )

                            TableViewCaseCountSortOptions(
                                isLoading: isLoadingData,
                                isEditable: isEditable,
                                isSpaced: false
                            )

                            Spacer()

                            TableViewButtons(filtersCount: viewModel.filtersCount)
                        }
                        .frame(width: proxy.size.width * listDetailListFractionalWidth)
                        .if (viewLayout.isShort) {
                            $0.padding(.vertical)
                        }
                        // TODO: Horizontal padding doesn't apply

                        VStack {
                            // TODO: Show claim action error dialog if error has occurred

                            if viewModel.tableSortResultsMessage.isNotBlank {
                                Text(viewModel.tableSortResultsMessage)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .listItemPadding()
                            }

                            TableViewCasesList(
                                isEditable: isEditable,
                                showWrongLocationDialog: $showWrongLocationDialog,
                                phoneCallNumbers: $phoneCallNumbers
                            )
                        }
                        .frame(width: proxy.size.width * listDetailDetailFractionalWidth)
                    }
                }
                .frame(maxWidth: appTheme.wideContentMaxWidth, alignment: .center)
            }
            .frame(maxWidth: .infinity)
            .background(.white)
        } else {
            VStack {
                HStack(spacing: appTheme.gridActionSpacing) {
                    TableViewIncidentSelector(
                        isLoadingIncidents: isLoadingIncidents,
                        hasNoIncidents: hasNoIncidents,
                        selectedIncident: viewModel.incidentsData.selected,
                        incidentSelectViewBuilder: incidentSelectViewBuilder,
                        isLoadingData: isLoadingData
                    )

                    if viewLayout.isWide {
                        TableViewCaseCountSortOptions(
                            isLoading: isLoadingData,
                            isEditable: isEditable,
                            isSpaced: true
                        )
                        .padding(.horizontal)
                    } else {
                        Spacer()
                    }

                    TableViewButtons(filtersCount: viewModel.filtersCount)
                }
                .padding()

                VStack {
                    if !viewLayout.isWide {
                        HStack {
                            TableViewCaseCountSortOptions(
                                isLoading: isLoadingData,
                                isEditable: isEditable,
                                isSpaced: true
                            )
                        }
                        .listItemPadding()
                    }

                    // TODO: Show claim action error dialog if error has occurred

                    if viewModel.tableSortResultsMessage.isNotBlank {
                        Text(viewModel.tableSortResultsMessage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .listItemPadding()
                    }

                    TableViewCasesList(
                        isEditable: isEditable,
                        showWrongLocationDialog: $showWrongLocationDialog,
                        phoneCallNumbers: $phoneCallNumbers
                    )
                }
                .frame(maxWidth: appTheme.contentMaxWidth, alignment: .center)
            }
            .background(.white)
        }

        if viewModel.isLoadingTableViewData {
            ProgressView()
                .frame(alignment: .center)
        }
    }
}

private struct TableViewIncidentSelector: View {
    let isLoadingIncidents: Bool
    let hasNoIncidents: Bool
    let selectedIncident: Incident
    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let isLoadingData: Bool

    @State private var openIncidentSelect = false

    var body: some View {
        Button {
            openIncidentSelect.toggle()
        } label: {
            IncidentHeaderView(
                incident: selectedIncident,
                showDropdown: !hasNoIncidents,
                isLoading: isLoadingData,
                isSpaceConstrained: true
            )
            .tint(.black)
        }
        .sheet(
            isPresented: $openIncidentSelect,
            onDismiss: {
                incidentSelectViewBuilder.onIncidentSelectDismiss()
            }
        ) {
            incidentSelectViewBuilder.incidentSelectView(
                onDismiss: { openIncidentSelect = false }
            )
        }
        .disabled(isLoadingIncidents)
    }
}

private struct TableViewButtons: View {
    @EnvironmentObject var router: NavigationRouter

    let filtersCount: Int
    let buttonSize = appTheme.buttonSize

    var body: some View {
        HStack(spacing: 0) {
            Button {
                router.openSearchCases()
            } label: {
                Image("ic_search", bundle: .module)
                    .frame(width: buttonSize, height: buttonSize)
                    .background(Color.white)
                    .foregroundColor(Color.black)
            }

            Divider()
                .frame(height: buttonSize)
                .hidden()

            Button {
                router.openFilterCases()
            } label: {
                Image("ic_dials", bundle: .module)
                    .frame(width: buttonSize, height: buttonSize)
                    .background(Color.white)
                    .foregroundColor(Color.black)
            }
            .if (filtersCount > 0) {
                // TODO: Don't clip overlay
                $0.overlay(alignment: .topTrailing) {
                    filterBadge(filtersCount)
                }
            }
        }
    }
}

private struct TableViewCaseCountSortOptions: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CasesViewModel

    let isLoading: Bool
    let isEditable: Bool
    let isSpaced: Bool

    var body: some View {
        // TODO: Animate
        if viewModel.casesCountTableText.isNotBlank {
            Text(viewModel.casesCountTableText)
                .fontHeader4()
                .disabled(isLoading)
                .onTapGesture {
                    viewModel.syncWorksitesData()
                }
                .onLongPressGesture {
                    viewModel.syncWorksitesData(true)
                }
        }

        if isSpaced {
            Spacer()
        }

        let sortByOptions = viewModel.tableViewSort == .none
        ? WorksiteSortBy.allCases
        : WorksiteSortBy.allCasesNotNone
        Picker("", selection: $viewModel.tableViewSort ) {
            ForEach(sortByOptions, id: \.self) { sortBy in
                Text(t.t(sortBy.translateKey))
            }
        }
        .disabled(isLoading || !isEditable)
        .tint(.black)
        .roundedCorners()
    }
}

private struct TableViewCasesList: View {
    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: CasesViewModel

    let isEditable: Bool

    @Binding var showWrongLocationDialog: Bool
    @Binding var phoneCallNumbers: [ParsedPhoneNumber]

    var body: some View {
        let casesData = viewModel.tableData
        let isTurnOnRelease = viewModel.selectedIncident.turnOnRelease
        let changingClaimIds = viewModel.worksitesChangingClaimAction

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack {
                    ForEach(0..<casesData.count, id: \.self) { index in
                        if index > 0 {
                            FormListSectionSeparator()
                        }

                        let worksite = casesData[index].worksite
                        let isChangingClaim = changingClaimIds.contains(worksite.id)
                        CaseTableItemCard(
                            worksiteDistance: casesData[index],
                            isEditable: isEditable,
                            isTurnOnRelease: isTurnOnRelease,
                            isChangingClaim: isChangingClaim,
                            onWorksiteClaimAction: { claimAction in
                                viewModel.onWorksiteClaimAction(worksite, claimAction)
                            },
                            showWrongLocationDialog: $showWrongLocationDialog,
                            phoneCallNumbers: $phoneCallNumbers
                        )
                        .if (index == 0) {
                            $0.id("case-table-first")
                        }
                    }
                }
            }
            .onReceive(viewModel.openWorksiteAddFlagCounter) { _ in
                if viewModel.takeOpenWorksiteAddFlag() {
                    router.openCaseFlags(isFromCaseEdit: false)
                }
            }
            .onChange(of: viewModel.tableViewSort) { newValue in
                proxy.scrollTo("case-table-first", anchor: .top)
            }
        }
    }
}

private struct CaseTableItemCard: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: CasesViewModel

    let worksiteDistance: WorksiteDistance
    var worksite: Worksite { worksiteDistance.data.worksite }

    let isEditable: Bool
    let isTurnOnRelease: Bool
    let isChangingClaim: Bool
    let onWorksiteClaimAction: (TableWorksiteClaimAction) -> Void

    @Binding var showWrongLocationDialog: Bool
    @Binding var phoneCallNumbers: [ParsedPhoneNumber]

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    viewModel.onOpenCaseFlags(worksite)
                } label: {
                    Image(systemName: "flag.fill")
                }
                .tint(.black)
                .disabled(!isEditable)

                Button {
                    router.viewCase(
                        incidentId: worksite.incidentId,
                        worksiteId: worksite.id
                    )
                } label: {
                    Text(worksite.caseNumber)
                        .fontHeader3()
                }
                .tint(.black)

                Spacer()

                if (worksiteDistance.distanceMiles > 0) {
                    let distanceText = String(format: "%.01f", worksiteDistance.distanceMiles)
                    Text(distanceText)
                        .fontBodySmall()
                        .fontWeight(.bold)
                    // TODO: Common dimensions
                        .padding(.trailing, 2)

                    Text(t.t("caseView.miles_abbrv"))
                        .fontBodySmall()
                }
            }
            .padding(.bottom, 4)

            WorksiteNameView(name: worksite.name)
                .padding(.bottom, 4)

            let (fullAddress, addressMapItem) = worksite.addressQuery

            WorksiteAddressView(fullAddress: fullAddress) {
                if worksite.hasWrongLocationFlag {
                    ExplainWrongLocationDialog(showDialog: _showWrongLocationDialog)
                }
            }
            .padding(.bottom, 4)

            HStack {
                WorksiteCallButton(
                    phone1: worksite.phone1,
                    phone2: worksite.phone2,
                    enable: isEditable,
                    phoneNumberParser: viewModel.phoneNumberParser
                ) { parsedNumbers in
                    phoneCallNumbers = parsedNumbers
                }

                WorksiteAddressButton(
                    addressMapItem: addressMapItem,
                    enable: isEditable
                )

                Spacer()

                let isClaimActionDisabled = !isEditable || isChangingClaim

                switch worksiteDistance.claimStatus {
                case .hasUnclaimed:
                    WorkTypeAction(
                        t.t("actions.claim"),
                        true,
                        disabled: isClaimActionDisabled
                    ) {
                        onWorksiteClaimAction(.claim)
                    }
                case .claimedByMyOrg:
                    WorkTypeAction(
                        t.t("actions.unclaim"),
                        false,
                        disabled: isClaimActionDisabled
                    ) {
                        onWorksiteClaimAction(.unclaim)
                    }
                case .claimedByOthers:
                    let isReleasable = viewModel.incidentsData.selected.turnOnRelease && worksite.isReleaseEligible
                    let actionText = isReleasable ? t.t("actions.release") : t.t("actions.request")
                    WorkTypeAction(
                        actionText,
                        false,
                        disabled: isClaimActionDisabled
                    ) {
                        onWorksiteClaimAction(isReleasable ? .release : .request)
                    }
                case .requested:
                    Text(t.t("caseView.requested"))
                        .padding(.vertical, appTheme.listItemVerticalPadding)
                }
            }
            .padding(.bottom, 4)
        }
        .padding()
        .background()
        .onTapGesture {
            router.viewCase(
                incidentId: worksite.incidentId,
                worksiteId: worksite.id
            )
        }
    }
}
