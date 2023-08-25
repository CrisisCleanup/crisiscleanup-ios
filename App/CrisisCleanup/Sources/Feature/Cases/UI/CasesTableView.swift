import SwiftUI

struct CasesTableView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter
    @EnvironmentObject var viewModel: CasesViewModel

    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let hasNoIncidents: Bool

    var body: some View {
        let isLoadingData = viewModel.isLoadingData
        let isEditable = viewModel.isTableEditable

        VStack {
            HStack {
                TableViewIncidentSelector(
                    hasNoIncidents: hasNoIncidents,
                    selectedIncident: viewModel.incidentsData.selected,
                    incidentSelectViewBuilder: incidentSelectViewBuilder,
                    isLoadingData: isLoadingData
                )

                Spacer()

                TableViewButtons(filtersCount: viewModel.filtersCount)
            }
            .padding()

            HStack {
                // TODO: Animate
                if viewModel.casesCountTableText.isNotBlank {
                    Text(viewModel.casesCountTableText)
                        .fontHeader4()
                        .disabled(isLoadingData)
                        .onTapGesture {
                            viewModel.syncWorksitesData()
                        }
                }

                Spacer()

                Picker("", selection: $viewModel.tableViewSort ) {
                    ForEach(WorksiteSortBy.allCases, id: \.self) { sortBy in
                        Text(t.t(sortBy.translateKey))
                    }
                }
                .disabled(isLoadingData || !isEditable)
                .tint(.black)
                .blackBorder()
            }
            .listItemPadding()

            // TODO: Show phone numbers in bottom sheet if there are more than 1 phone numbers
            // TODO: Show claim action error dialog if error has occurred

            if viewModel.tableSortResultsMessage.isNotBlank {
                Text(viewModel.tableSortResultsMessage)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listItemPadding()
            }

            let casesData = viewModel.tableData
            let isTurnOnRelease = viewModel.selectedIncident.turnOnRelease
            let changingClaimIds = viewModel.worksitesChangingClaimAction
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
                            }
                        )
                    }
                }
            }
            .onReceive(viewModel.openWorksiteAddFlagCounter) { _ in
                if viewModel.takeOpenWorksiteAddFlag() {
                    router.openCaseFlags(isFromCaseEdit: false)
                }
            }
        }
        .background(.white)

        if viewModel.isLoadingTableViewData {
            // TODO: Is VStack necessary?
            VStack {
                ProgressView()
                    .frame(alignment: .center)
            }
        }
    }
}

private struct TableViewIncidentSelector: View {
    let hasNoIncidents: Bool
    let selectedIncident: Incident
    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let isLoadingData: Bool

    @State private var openIncidentSelect = false

    var body: some View {
        Button {
            openIncidentSelect.toggle()
        } label: {
            IncidentHeader(
                incident: selectedIncident,
                drop: true,
                disabled: hasNoIncidents,
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
        .disabled(hasNoIncidents)
    }
}

struct TableViewButtons: View {
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
                // TODO: Badge
                Image("ic_dials", bundle: .module)
                    .frame(width: buttonSize, height: buttonSize)
                    .background(Color.white)
                    .foregroundColor(Color.black)
            }
            .if(filtersCount > 0) {
                // TODO: Don't clip overlay
                $0.overlay(alignment: .topTrailing) {
                    filterBadge(filtersCount)
                }
            }
        }
        .frame(width: appTheme.buttonSizeDoublePlus1, height: buttonSize)
    }
}

private struct CaseTableItemCard: View {
    @EnvironmentObject var router: NavigationRouter
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CasesViewModel

    let worksiteDistance: WorksiteDistance
    var worksite: Worksite { worksiteDistance.data.worksite }

    let isEditable: Bool
    let isTurnOnRelease: Bool
    let isChangingClaim: Bool
    let onWorksiteClaimAction: (TableWorksiteClaimAction) -> Void

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

            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(Color.gray)

                Text(worksite.name)
            }
            .padding(.bottom, 4)

            let (fullAddress, addressMapItem) = worksite.addressQuery

            HStack {
                Image(systemName: "mappin")
                    .foregroundColor(Color.gray)

                Text(fullAddress)

                Spacer()

                if worksite.hasWrongLocationFlag {
                    // TODO: Button when clicked pops message about wrong location flag is set
                }
            }
            .padding(.bottom, 4)

            HStack {
                Button {
                    // TODO: Present multiple phone numbers if defined
                    let urlString =  "tel:\(worksite.phone1)"
                    if let url = URL(string: urlString) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                } label : {
                    Image(systemName: "phone.fill")
                    // TODO: Common dimensions
                        .frame(width: 75, height: 35)
                        .fontHeader3()
                        .blackBorder()
                }
                .tint(.black)

                Button {
                    addressMapItem.openInMaps()
                } label : {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    // TODO: Common dimensions
                        .frame(width: 75, height: 35)
                        .fontHeader3()
                        .blackBorder()
                }
                .tint(.black)

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
