import SwiftUI

struct CasesConstant {
    private static let IS_IPAD = UIDevice.current.model == "iPad"

    // TODO: Differ by screen size
#if targetEnvironment(macCatalyst)
    static let MAP_DOTS_ZOOM_LEVEL = 16
#else
    static let MAP_DOTS_ZOOM_LEVEL = IS_IPAD ? 16 : 13
#endif

    // TODO: Differ by screen size
#if targetEnvironment(macCatalyst)
    static let MAP_MARKERS_ZOOM_LEVEL = 12.0
#else
    static let MAP_MARKERS_ZOOM_LEVEL = IS_IPAD ? 12.0 : 11.0
#endif

#if targetEnvironment(macCatalyst)
    static let MAX_MARKERS_ON_MAP = 1600
#else
    static let MAX_MARKERS_ON_MAP = IS_IPAD ? 1600 : 1024
#endif
}
