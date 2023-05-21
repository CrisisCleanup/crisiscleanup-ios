import SwiftUI

struct MenuView<ViewModel>: View where ViewModel: MenuViewModelProtocol {
    @ObservedObject var viewModel: ViewModel
    let authenticateViewBuilder: AuthenticateViewBuilder

    var body: some View{
        VStack {
            HStack {
                Text("Show incidents")
                Spacer()
                NavigationLink(destination: authenticateViewBuilder.authenticateView
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
                ) {
                    Text("Auth")
                }
            }
            .padding([.vertical])
            Text("\(viewModel.versionText)")
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
        }
        .padding()
    }
}
