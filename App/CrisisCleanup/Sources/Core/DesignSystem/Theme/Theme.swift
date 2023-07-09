import SwiftUI

enum AppTheme {
    case standard
    case thinScreen
}

class ThemeValues: ObservableObject {
    @Published var textFieldInnerPadding: Double
    @Published var textFieldOutlineWidth: Double
    @Published var cornerRadius: Double
    @Published var shadowRadius: Double

    @Published var colors: ThemeColor

    init(
        textFieldInnerPadding: Double = 16.0,
        textFieldOutlineWidth: Double = 0.5,
        cornerRadius: Double = 4.0,
        shadowRadius: Double = 1.0
    ) {
        self.textFieldInnerPadding = textFieldInnerPadding
        self.textFieldOutlineWidth = textFieldOutlineWidth
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius

        self.colors = ThemeColor()
    }

    func setTheme(theme: AppTheme) {
        switch theme {
        case .thinScreen:
            textFieldInnerPadding = 16.0
        default:
            textFieldInnerPadding = 16.0
        }
    }
}

let appTheme = ThemeValues()
