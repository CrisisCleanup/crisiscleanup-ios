import CachedAsyncImage
import SVGView
import SwiftUI

struct AvatarView: View {
    let url: URL
    let isSvg: Bool

    var body: some View {
        let imageSize = appTheme.avatarSize

        if isSvg {
            SVGView(contentsOf: url)
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
