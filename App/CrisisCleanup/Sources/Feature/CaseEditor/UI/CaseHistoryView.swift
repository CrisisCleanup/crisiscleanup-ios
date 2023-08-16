import SwiftUI

struct CaseHistoryView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseHistoryViewModel

    private let columns = [GridItem(.flexible())]

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                Text(t.t("caseHistory.do_not_share_contact_warning"))
                    .fontHeader3()
                    .listItemPadding()

                ScrollView {
                    LazyVGrid(columns: columns) {
                        Text(t.t("caseHistory.do_not_share_contact_explanation"))
                            .listItemPadding()

                        if viewModel.hasEvents {
                            ForEach(viewModel.historyEvents, id: \.userId) { userEvents in
                                VStack(alignment: .leading) {
                                    CaseHistoryUser(userEvents: userEvents)
                                    CaseHistoryEvents(events: userEvents.events)
                                }
                                .cardContainerPadded()
                            }
                        }
                        else if !viewModel.isLoadingCaseHistory {
                            Text(t.t("caseHistory.no_history"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .listItemPadding()
                        }
                    }
                }
            }

            if viewModel.isLoadingCaseHistory {
                VStack {
                    ProgressView()
                        .frame(alignment: .center)
                }
            }
        }
        .screenTitle(viewModel.screenTitle)
        .environmentObject(viewModel)
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}

private struct CaseHistoryUser: View {
    let userEvents: CaseHistoryUserEvents

    var body: some View {
        VStack {
            HStack {
                Text(userEvents.userName)
                    .fontHeader4()

                Spacer()

                let phoneText = userEvents.userPhone
                Text(phoneText)
                    .customLink(urlString: "tel:\(phoneText)")
            }

            HStack {
                Text(userEvents.orgName)

                Spacer()

                let email = userEvents.userEmail
                if email.isNotBlank {
                    Text(email)
                        .customLink(urlString: email)
                }
            }
        }
        // TODO: Common dimensions
        .padding(.all, 16)
        .background(.white)
    }
}

private struct CaseHistoryEvents: View {
    let events: [CaseHistoryEvent]
    var body: some View {
        // TODO: Common dimensions
        VStack(spacing: 16) {
            ForEach(events, id: \.id) { event in
                VStack(
                    alignment: .leading,
                    // TODO: Common dimensions
                    spacing: 4
                ) {
                    Text(event.pastTenseDescription)
                    HStack {
                        Text(event.createdAt.relativeTime)
                            .foregroundColor(appTheme.colors.neutralFontColor)
                            .fontBodySmall()
                        Text(event.actorLocationName)
                            .foregroundColor(appTheme.colors.neutralFontColor)
                            .fontBodySmall()
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        // TODO: Common dimensions
        .padding(.all, 16)
        .background(appTheme.colors.neutralBackgroundColor)
    }
}
