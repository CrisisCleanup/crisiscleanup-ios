import SwiftUI
import SVGView

struct MenuView: View {
    @ObservedObject var viewModel: MenuViewModel
    let authenticateViewBuilder: AuthenticateViewBuilder

    var body: some View{
        VStack {
            HStack {
                Text("Show incidents")
                Spacer()
                NavigationLink {
                    authenticateViewBuilder.authenticateView
                        .navigationBarTitle("")
                        .navigationBarHidden(true)
                } label: {
                    if let url = viewModel.profilePictureUri {
                        SVGView(contentsOf: url)
                            .frame(width: 30, height: 30)
                            .padding([.vertical], 8)
                    } else {
                        Text("Auth")
                    }
                }
            }
            .padding([.vertical])

            Text("\(viewModel.versionText)")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.isDebuggable {
                Button("Expire token") {
                    viewModel.expireToken()
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
        }
        .padding()
    }
}
