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
    @Published var isPortrait = true
    @Published var isLandscape = false
    @Published var isListDetailLayout = false
    @Published var isOneColumnLayout = true
    @Published var isWide = false
    @Published var isShort = false

    private var _observer: NSObjectProtocol?

    init() {
        _observer = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: nil
        ) { [unowned self] notification in
            guard let device = notification.object as? UIDevice else {
                return
            }

            let isLandscape = landscapeOrientations.contains(device.orientation)
            if isLandscape != self.isLandscape {
                // TODO: Test on Mac
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
