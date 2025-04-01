import CoreGraphics
import Foundation
import SwiftUI

let listDetailListFractionalWidth = 0.3
let listDetailDetailFractionalWidth = 1 - listDetailListFractionalWidth

private let landscapeOrientations: Set<UIDeviceOrientation> = Set([
    .landscapeLeft,
    .landscapeRight
])

class ViewLayoutDescription: ObservableObject {
    @Published private(set) var isPortrait = true
    @Published private(set) var isLandscape = false
    @Published private(set) var isListDetailLayout = false
    @Published private(set) var isOneColumnLayout = true
    @Published private(set) var isWide = false
    @Published private(set) var isShort = false
    @Published private(set) var isLargeScreen = false

    private var orientationObserver: NSObjectProtocol?

    init() {
        setInitialProperties()

        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: nil
        ) { [unowned self] notification in
            guard let device = notification.object as? UIDevice else {
                return
            }

            let isLandscape = landscapeOrientations.contains(device.orientation)
            if isLandscape != self.isLandscape {
                var width = min(Device.screen.width, Device.screen.height)
                var height = max(Device.screen.width, Device.screen.height)
                if isLandscape {
                    let temp = width
                    width = height
                    height = temp
                }
                update(isLandscape, width: width, height: height)
            }
        }
    }

    private func setInitialProperties() {
        let width = Device.screen.width
        let height = Device.screen.height
        update(width > height, width: width, height: height)

        var isMac = false
        var isIpad = false
#if targetEnvironment(macCatalyst)
        isMac = true
#else
        isIpad = UIDevice.current.model == "iPad"
#endif
        isLargeScreen = isMac || isIpad
    }

    private func update(_ isLandscape: Bool, width: CGFloat, height: CGFloat) {
        let isListDetailLayout = width > height && width > 600
        isWide = width > 600
        isShort = height < 400

        isPortrait = !isLandscape
        self.isLandscape = isLandscape
        self.isListDetailLayout = isListDetailLayout
        isOneColumnLayout = !isListDetailLayout
    }
}
