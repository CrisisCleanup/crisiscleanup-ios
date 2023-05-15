import SwiftUI

public struct MainView: View {
    @StateObject private var viewModel = MainViewModel()

    public init() {}

    public var body: some View {
        TabView {
            CasesView()
                .navTabItem(destination: .cases)
            MenuView()
                .navTabItem(destination: .menu)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
