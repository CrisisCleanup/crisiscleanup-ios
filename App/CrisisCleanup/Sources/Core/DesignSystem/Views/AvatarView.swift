import CachedAsyncImage
import SVGView
import SwiftDraw
import SwiftUI

struct AvatarView: View {
    let url: URL
    let isSvg: Bool

    @State private var svg: SVG? = nil

    var body: some View {
        let imageSize = appTheme.avatarSize

        if isSvg {
            if let svg = svg {
                SVGView(svg: svg)
                    .frame(width: imageSize, height: imageSize)
            } else {
                Image(systemName: "person")
                    .frame(width: imageSize, height: imageSize)
                    .task {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            if let svgFromData = SVG(data: data) {
                                svg = svgFromData
                            }
                        } catch {}
                    }
            }
        } else {
            CachedAsyncImage(url: url, urlCache: .imageCache) { image in
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
