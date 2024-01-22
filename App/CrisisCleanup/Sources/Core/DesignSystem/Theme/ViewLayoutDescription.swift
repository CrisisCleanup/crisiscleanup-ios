import CoreGraphics
import Foundation

let listDetailListFractionalWidth = 0.3
let listDetailDetailFractionalWidth = 1 - listDetailListFractionalWidth

struct ViewLayoutDescription {
    let isPortrait: Bool
    let isLandscape: Bool
    let isListDetailLayout: Bool
    let isOneColumnLayout: Bool
    let isWide: Bool

    init(_ size: CGSize = CGSizeZero) {
        let isPortrait = size.width <= size.height
        let isListDetailLayout = size.width > size.height && size.width > 600
        isWide = size.width > 600

        self.isPortrait = isPortrait
        isLandscape = !isPortrait
        self.isListDetailLayout = isListDetailLayout
        isOneColumnLayout = !isListDetailLayout
    }
}
