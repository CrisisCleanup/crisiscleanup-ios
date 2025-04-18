import Combine
import SwiftUI

struct FocusSectionSliderTopHeightKey: PreferenceKey {
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}

struct FocusSectionSlider: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let sectionTitles: [String]
    let proxy: ScrollViewProxy
    let referenceFrameName: String
    let onScrollToSection: (Int) -> Void

    @State private var visibleItems = [Int: CGFloat]()

    @State private var hasScrolled = false

    private let scrollChangeSubject = CurrentValueSubject<(CGFloat), Never>((0.0))
    private let scrollStopDelay: AnyPublisher<CGFloat, Never>

    init(
        sectionTitles: [String],
        proxy: ScrollViewProxy,
        referenceFrameName: String = "scrollFrom",
        onScrollToSection: @escaping (Int) -> Void = {_ in}
    ) {
        self.sectionTitles = sectionTitles
        self.proxy = proxy
        self.referenceFrameName = referenceFrameName
        self.onScrollToSection = onScrollToSection

        scrollStopDelay = scrollChangeSubject
            .debounce(for: .seconds(0.3), scheduler: RunLoop.current)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private func scrollToSection(_ index: Int) {
        onScrollToSection(index)
        withAnimation {
            proxy.scrollTo("section\(index)", anchor: .top)
            proxy.scrollTo("scrollBar\(index)", anchor: .leading)
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Divider()
                    .id("scrollBarFrontBumper")
                    .frame(width: 1, height: 1)

                ForEach(Array(sectionTitles.enumerated()), id: \.offset) { (index, sectionTranslateKey) in
                    Text("\(index + 1). \(t.t(sectionTranslateKey))")
                        .id("scrollBar\(index)")
                        .fontHeader4()
                        .padding(.leading)
                        .padding(.horizontal, appTheme.gridItemSpacing)
                        .onTapGesture {
                            scrollToSection(index)
                        }
                        .background(GeometryReader {
                            let frame = $0.frame(in: .named(referenceFrameName))
                            Color.clear.preference(
                                key: SliderItemOffsetKey.self,
                                value: frame.origin.x
                            )
                            .onPreferenceChange(SliderItemOffsetKey.self) {
                                let endX = frame.width + $0
                                if endX > 0 {
                                    visibleItems[index] = frame.origin.x
                                } else {
                                    visibleItems.removeValue(forKey: index)
                                }
                            }
                        })
                }
                Rectangle()
                    .fill(.clear)
                    .frame(width: UIScreen.main.bounds.width, height: 1)
            }
            .background(GeometryReader {
                let frame = $0.frame(in: .named(referenceFrameName))
                Color.clear.preference(
                    key: SliderOffsetKey.self,
                    value: -frame.origin.x
                )
                .onPreferenceChange(SliderOffsetKey.self) {
                    if !hasScrolled {
                        hasScrolled = $0 > 0
                    }
                    scrollChangeSubject.send($0)
                }
            })
        }
        .onReceive(scrollStopDelay) { _ in
            var index = sectionTitles.count - 1
            var offset = CGFloat.infinity
            if visibleItems.isNotEmpty {
                if let minIndex = visibleItems.keys.min() {
                    index = minIndex
                    if let minIndexOffset = visibleItems[index] {
                        offset = minIndexOffset
                    }
                }
            }
            if abs(offset) > 0,
               (index > 0 || hasScrolled) {
                scrollToSection(index)
            }
        }
    }
}

private struct SliderOffsetKey: PreferenceKey {
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

private struct SliderItemOffsetKey: PreferenceKey {
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

extension View {
    func onScrollSectionFocus(
        _ proxy: ScrollViewProxy,
        scrollToId: String,
        scrollChangeSubject: any Subject<(String, CGFloat), Never>,
        yOffset: CGFloat = 0,
        frameName: String = "scrollFrom"
    ) -> some View {
        self.background(GeometryReader {
            let frame = $0.frame(in: .named(frameName))
            Color.clear.preference(
                key: ContentOffsetKey.self,
                value: -frame.origin.y
            )
            .onPreferenceChange(ContentOffsetKey.self) {
                let y = $0 + yOffset
                if (y >= 0 && y < frame.height) {
                    scrollChangeSubject.send((scrollToId, $0))
                }
            }
        })
    }
}

private struct ContentOffsetKey: PreferenceKey {
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}
