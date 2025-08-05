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
    func navTabItem(
        _ destination: TopLevelDestination,
        _ translator: KeyAssetTranslator,
        badgeText: String? = nil,
    ) -> some View {
        tabItem {
            NavTabView(
                text: translator.t(destination.titleTranslateKey),
                imageName: destination.imageName,
            )
        }
        .if (badgeText != nil) {
            $0.badge(badgeText!)
        }
    }
}
