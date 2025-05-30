import SwiftUI

struct UnsupportedBuildView: View {
    let supportedInfo: MinSupportedAppVersion

    var body: some View {
        VStack(alignment: .leading) {
            Image("crisis_cleanup_logo", bundle: .module)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 240)
                .padding(24)

            if let title = supportedInfo.title {
                Text(title)
                    .fontHeader2()
                    .padding(.vertical)
            }

            Text(supportedInfo.message)
                .padding(.vertical, 8)

            if let link = supportedInfo.link {
                Link(
                    link,
                    destination: URL(string: link)!
                )
            }
        }
    }
}
