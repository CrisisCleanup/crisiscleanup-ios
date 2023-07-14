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
                HStack{
                    Text(t.t(helpText))
                }.padding()
            }
            .presentationDetents([.medium, .fraction(0.25)])
        }
    }
}
