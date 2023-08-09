import SwiftUI

struct CasesTableView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @ObservedObject var viewModel: CasesViewModel
    let incidentSelectViewBuilder: IncidentSelectViewBuilder

    @State var openIncidentSelect = false
    @State var selectSort: String = "~~Sort by Name"

    @State var sortOptions = [
        "~~Sort by Nearest",
        "~~Sort by Case Number",
        "~~Sort by Name",
        "~~Sort by City",
        "~~Sort by County/Parish",
    ]

    var worksiteIds = [1,2,3,4,5]

    var body: some View {
        VStack {
            HStack {
                Button {
                    openIncidentSelect.toggle()
                } label: {
                    HStack{
                        CaseIncidentView(
                            incident: viewModel.incidentsData.selected,
                            isPendingSync: false,
                            isSyncing: false,//viewModel.isSyncing,
                            scheduleSync: {
                                //viewModel.scheduleSync()
                            },
                            drop: true
                        )

                        Spacer()
                    }
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
                //.disabled(hasNoIncidents)
                Spacer()
                TableViewButtons()
            }
            .padding()


            HStack {
                Text("t.t1234 cases")
                Spacer()

                Picker("", selection: $selectSort ) {
                    ForEach(sortOptions, id: \.self) { option in
                        Text(option)
                    }
                }
                .tint(.black)
                .blackBorder()

            }
            .padding()

            Spacer()

            ScrollView {
                LazyVStack {

                    ForEach(worksiteIds, id: \.self) { id in
                        TableCard()
                        if id != worksiteIds.last {
                            FormListSectionSeparator()
                        }
                    }


                }
            }
        }
        .background(.white)
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

    @Environment(\.translator) var t: KeyAssetTranslator

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "flag.fill")

                Text("U513")

                Spacer()

                Text("1161.3 ~~mi")
            }
            .padding(.bottom, 4)

            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(Color.gray)

                Text("AJ Walker")
            }
            .padding(.bottom, 4)

            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(Color.gray)

                Text("12345 main st, main, fl, 12345")

            }
            .padding(.bottom, 4)

            HStack {
                Image(systemName: "phone.fill")
                    .frame(width: 75, height: 35)
                    .blackBorder()

                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    .frame(width: 75, height: 35)
                    .blackBorder()

                Spacer()

                WorkTypeAction(t.t("actions.claim"), true) {

                }
                .environmentObject(EditableView())
            }
            .padding(.bottom, 4)
        }
        .padding()
    }

}
