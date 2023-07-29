import SwiftUI

struct FocusSectionSlider: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let sectionTitles: [String]
    let proxy: ScrollViewProxy

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false ) {
            HStack {
                ForEach(Array(sectionTitles.enumerated()), id: \.offset) { (index, sectionTranslateKey) in
                    Text("\(index + 1). \(t.t(sectionTranslateKey))")
                        .padding(.leading)
                        .id("scrollBar\(index)")
                        .onTapGesture {
                            // TODO: Expand the section if it is collapsed
                            withAnimation {
                                proxy.scrollTo("section\(index)", anchor: .top)
                                proxy.scrollTo("scrollBar\(index)", anchor: .leading)
                            }
                        }
                }
                Group {
                    ForEach(sectionTitles.indices, id: \.self) { index in
                        Text("scrollBar\(index)")
                    }
                }
                .hidden()
            }
        }
    }
}

extension View {
    func onScrollSectionFocus(
        _ proxy: ScrollViewProxy,
        scrollToId: String,
        frameName: String = "scrollFrom"
    ) -> some View {
        self.background(GeometryReader {
            let frame = $0.frame(in: .named(frameName))
            Color.clear.preference(
                key: ViewOffsetKey.self,
                value: (-frame.minY)
            )
            // TODO: Run animation once the list has settled scrolling or animating
            .onPreferenceChange(ViewOffsetKey.self) {
                if($0 < frame.height && $0 > 0) {
                    withAnimation {
                        proxy.scrollTo(scrollToId, anchor: .leading)
                    }
                }
            }
        })
    }
}
