import SwiftUI

enum AppTheme {
    case standard
    case thinScreen
}

class ThemeValues: ObservableObject {
    // TODO: Group in dimensions object
    @Published var textFieldInnerPadding: Double
    @Published var textFieldOutlineWidth: Double
    @Published var cornerRadius: Double
    @Published var shadowRadius: Double
    @Published var rowItemHeight: Double
    @Published var buttonSize: Double
    @Published var buttonSizeDoublePlus1: Double
    @Published var gridItemSpacing: Double
    @Published var listItemVerticalPadding: Double
    @Published var textListVerticalPadding: Double

    // TODO: Group in timings object
    @Published var layoutAnimationDuration: Double

    @Published var colors: ThemeColor

    init(
        textFieldInnerPadding: Double = 16.0,
        textFieldOutlineWidth: Double = 0.5,
        cornerRadius: Double = 4.0,
        shadowRadius: Double = 1.0,
        rowItemHeight: Double = 56,
        buttonSize: Double = 48,
        gridItemSpacing: Double = 8,
        listItemVerticalPadding: Double = 8,
        textListVerticalPadding: Double = 4,
        layoutAnimationDuration: Double = 0.3
    ) {
        self.textFieldInnerPadding = textFieldInnerPadding
        self.textFieldOutlineWidth = textFieldOutlineWidth
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.rowItemHeight = rowItemHeight
        self.buttonSize = buttonSize
        buttonSizeDoublePlus1 = buttonSize * 2 + 1
        self.gridItemSpacing = gridItemSpacing
        self.listItemVerticalPadding = listItemVerticalPadding
        self.textListVerticalPadding = textListVerticalPadding

        self.layoutAnimationDuration = layoutAnimationDuration

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
