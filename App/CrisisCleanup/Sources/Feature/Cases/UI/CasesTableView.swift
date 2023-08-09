import SwiftUI

struct CasesTableView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CasesViewModel

    let incidentSelectViewBuilder: IncidentSelectViewBuilder
    let hasNoIncidents: Bool

    @State var openIncidentSelect = false

    var body: some View {
        VStack {
            HStack {
                Button {
                    openIncidentSelect.toggle()
                } label: {
                    IncidentHeader(
                        incident: viewModel.incidentsData.selected,
                        drop: true
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

                Spacer()

                TableViewButtons()
            }
            .padding()

            HStack {
                Text("\(viewModel.tableData.count) \(t.t("casesVue.cases"))")

                Spacer()

                Picker("", selection: viewModel.tableViewSort ) {
                    ForEach(WorksiteSortBy.allCases, id: \.self) { sortBy in
                        Text(t.t(sortBy.translateKey))
                            .onTapGesture {
                                viewModel.changeTableSort(sortBy)
                            }
                    }
                }
                .tint(.black)
                .blackBorder()
            }
            .padding()

            Spacer()

            ScrollView {
                LazyVStack {
                    ForEach(0..<viewModel.tableData.count, id: \.self) { index in
                        TableCard(
                            worksiteDistance: viewModel.tableData[index]
                        )

                        if index != viewModel.tableData.count - 1 {
                            FormListSectionSeparator()
                        }
                    }
                }
            }
        }
        .background(.white)

        if(viewModel.isLoadingTableViewData) {
            VStack {
                ProgressView()
                    .frame(alignment: .center)
            }
        }
    }
}

struct TableViewButtons: View {
    @EnvironmentObject var router: NavigationRouter
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

        }
        .frame(width: appTheme.buttonSizeDoublePlus1, height: buttonSize)
    }
}

struct TableCard: View {
    @EnvironmentObject var router: NavigationRouter
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var viewModel: CasesViewModel
    var worksiteDistance: WorksiteDistance
    var worksite: Worksite { worksiteDistance.data.worksite }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    // TODO: Set Case before opening
                    // router.openCaseFlags()
                } label: {
                    Image(systemName: "flag.fill")
                }
                .tint(.black)

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
                    Text("\(distanceText) ~~mi")
                }
            }
            .padding(.bottom, 4)

            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(Color.gray)

                Text(worksite.name)
            }
            .padding(.bottom, 4)

            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(Color.gray)

                Text(worksite.address)

            }
            .padding(.bottom, 4)

            HStack {
                Button {
                    let urlString =  "tel:\(worksite.phone1)"
                    if let url = URL(string: urlString) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                } label : {
                    Image(systemName: "phone.fill")
                        .frame(width: 75, height: 35)
                        .fontHeader3()
                        .blackBorder()
                }
                .tint(.black)

                Button {
                    let urlString =  "maps://?address=" + (worksite.address.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed) ?? worksite.address)
                    if let url = URL(string: urlString) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                } label : {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .frame(width: 75, height: 35)
                        .fontHeader3()
                        .blackBorder()
                }
                .tint(.black)

                Spacer()

                switch worksiteDistance.claimStatus {
                case .hasUnclaimed:
                    WorkTypeAction(t.t("actions.claim"), true) {

                    }
                    .environmentObject(EditableView())
                case .claimedByMyOrg:
                    WorkTypeAction(t.t("actions.unclaim"), true) {

                    }
                    .environmentObject(EditableView())
                case .claimedByOthers:
                    let isReleasable = viewModel.incidentsData.selected.turnOnRelease // && worksite.isReleaseEligible
                    let actionText = isReleasable ? t.t("actions.release") : t.t("actions.request")
                    WorkTypeAction(actionText, true) {

                    }
                    .environmentObject(EditableView())
                case .requested:
                    WorkTypeAction(t.t("caseView.requested"), true) {

                    }
                    .environmentObject(EditableView())
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
