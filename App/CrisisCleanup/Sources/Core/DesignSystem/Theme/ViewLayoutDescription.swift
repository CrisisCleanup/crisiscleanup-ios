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
                var width = Device.screen.width
                var height = Device.screen.height
                if isLandscape {
                    width = Device.screen.height
                    height = Device.screen.width
                }
                update(width: width, height: height)
            }
        }
    }

    func update(width: CGFloat, height: CGFloat) {
        let isPortrait = width <= height
        let isListDetailLayout = width > height && width > 600
        isWide = width > 600
        isShort = height < 400

        self.isPortrait = isPortrait
        isLandscape = !isPortrait
        self.isListDetailLayout = isListDetailLayout
        isOneColumnLayout = !isListDetailLayout
    }
}
