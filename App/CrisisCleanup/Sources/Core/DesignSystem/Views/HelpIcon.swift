import SwiftUI

struct HelpIcon: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @State var helpSheet: Bool = false
    @State var textAS: AttributedString = AttributedString()
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
                VStack {
                    HStack {
                        // TODO: Help text may contain HTML. Markup as necessary.
                        //                    HtmlTextView(htmlContent: t.t(helpText))

                        Text(textAS)
                            .onAppear {
                                DispatchQueue.main.async {
                                    let desc = t.t(helpText)
                                    let data = Data(desc.utf8)
                                    if let attributedString = try? NSMutableAttributedString(
                                        data: data,
                                        options: [
                                            .documentType: NSMutableAttributedString.DocumentType.html
                                        ],
                                        documentAttributes: nil
                                    ) {

                                        attributedString.replaceFont(font: .systemFont(ofSize: 16), size: 16)
                                        textAS = AttributedString(attributedString)
                                    }
                                }
                            }
                    }.padding()
                    Spacer()
                }
            }
            .presentationDetents([.medium, .fraction(0.25)])
        }
    }
}
