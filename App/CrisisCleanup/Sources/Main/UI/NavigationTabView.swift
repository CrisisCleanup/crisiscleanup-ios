import SwiftUI

struct NavTabView: View {
    let text: String
    let imageName: String

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(imageName, bundle: .module)
        }
    }
}

extension View {
    func navTabItem(destination: TopLevelDestination) -> some View {
        self.tabItem {
            NavTabView(text: destination.title, imageName: destination.imageName)
        }
    }
}
