import SwiftUI

struct HelpIcon: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @State var helpSheet: Bool = false
    var helpText: String

    init(_ helpText: String) {
        self.helpText = helpText
    }

    var body: some View {
        Image(systemName: "questionmark.circle")
            .onTapGesture {
                helpSheet.toggle()
            }
            .sheet(isPresented: $helpSheet) {
            ZStack {
                HStack {
                    // TODO: Help text may contain HTML. Markup as necessary.
                    HtmlTextView(htmlContent: t.t(helpText))
                }.padding()
            }
            .presentationDetents([.medium, .fraction(0.25)])
        }
    }
}
