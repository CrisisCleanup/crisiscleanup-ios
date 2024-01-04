import CachedAsyncImage
import SVGView
import SwiftUI

struct AvatarView: View {
    let url: URL
    let isSvg: Bool

    var body: some View {
        let imageSize = appTheme.avatarSize

        if isSvg {
            // TODO: Update URL or fix SVG render
//            SVGView(contentsOf: url)
            Image(systemName: "person")
                .frame(width: imageSize, height: imageSize)
        } else {
            CachedAsyncImage(url: url) { image in
                image.resizable()
                    .scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: imageSize, height: imageSize)
            .clipShape(Circle())
        }
    }
}
