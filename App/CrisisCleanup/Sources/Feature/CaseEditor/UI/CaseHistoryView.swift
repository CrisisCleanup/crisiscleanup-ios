import SwiftUI

struct CaseHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseHistoryViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(t.t("caseHistory.do_not_share_contact_warning"))
                    .padding([.horizontal, .top])
                    .bold()
                Text(t.t("caseHistory.do_not_share_contact_explanation"))
                    .padding([.horizontal, .bottom])

                Text("~~No History")
                    .padding(.horizontal)

                HistoryCard()
                HistoryCard()
                HistoryCard()
                Spacer()
            }
        }
    }
}


struct HistoryCard: View {

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text("First Last")
                        .bold() // TODO: change to app font
                        .foregroundColor(Color.gray)
                    Text("Some Org Inc")
                        .font(.caption) // TODO: change to app font
                        .foregroundColor(Color.gray)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    let phoneText = "123-456-7890"
                    Text(phoneText)
                        .font(.caption)
                        .customLink(urlString: "tel:\(phoneText)")

                    let email = "firstlast@email.com"
                    Text(email)
                        .font(.caption)
                        .customLink(urlString: email)
                }
            }
            .padding()

            HistoryAction()
                .padding()
            HistoryAction()
                .padding()
        }
        .cardContainerPadded()
    }
}

struct HistoryAction: View {
    var body: some View {
        VStack(alignment: .leading ) {
            Text("Viewed case C67 in Medium Flood")
            HStack {
                Text("1 Day ago • Some, Location")
                    .font(.caption)
                    .foregroundColor(Color.gray)
                Spacer()
            }
        }
    }
}
