import SwiftUI

struct CasesTableView: View {
    var body: some View {
        VStack {
            Text("Top row")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Second row")

            Spacer()

            ScrollView {
                Text("Results")
            }
        }
        .background(.white)
    }
}
