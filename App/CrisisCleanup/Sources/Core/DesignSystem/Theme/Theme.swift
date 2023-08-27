import SwiftUI

enum AppTheme {
    case standard
    case thinScreen
}

class ThemeValues: ObservableObject {
    // TODO: Group in dimensions object
    @Published var textFieldInnerPadding: Double
    @Published var textFieldOutlineWidth: Double
    @Published var buttonOutlineWidth: Double
    @Published var cornerRadius: Double
    @Published var shadowRadius: Double
    @Published var rowItemHeight: Double
    @Published var buttonSize: Double
    @Published var buttonSizeDoublePlus1: Double
    @Published var gridItemSpacing: Double
    @Published var listItemVerticalPadding: Double
    @Published var textListVerticalPadding: Double
    @Published var nestedItemPadding: Double
    @Published var listItemMapHeight: Double

    // TODO: Group in timings object
    @Published var layoutAnimationDuration: Double
    @Published var visibleSlowAnimationDuration: Double

    @Published var colors: ThemeColor

    init(
        textFieldInnerPadding: Double = 16.0,
        textFieldOutlineWidth: Double = 0.5,
        buttonOutlineWidth: Double = 1.0,
        cornerRadius: Double = 4.0,
        shadowRadius: Double = 1.0,
        rowItemHeight: Double = 56,
        buttonSize: Double = 48,
        gridItemSpacing: Double = 8,
        listItemVerticalPadding: Double = 8,
        textListVerticalPadding: Double = 4,
        layoutAnimationDuration: Double = 0.3,
        visibleSlowAnimationDuration: Double = 1.0,
        nestedItemPadding: Double = 16,
        listItemMapHeight: Double = 180
    ) {
        self.textFieldInnerPadding = textFieldInnerPadding
        self.textFieldOutlineWidth = textFieldOutlineWidth
        self.buttonOutlineWidth = buttonOutlineWidth
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.rowItemHeight = rowItemHeight
        self.buttonSize = buttonSize
        buttonSizeDoublePlus1 = buttonSize * 2 + 1
        self.gridItemSpacing = gridItemSpacing
        self.listItemVerticalPadding = listItemVerticalPadding
        self.textListVerticalPadding = textListVerticalPadding
        self.nestedItemPadding = nestedItemPadding
        self.listItemMapHeight = listItemMapHeight

        self.layoutAnimationDuration = layoutAnimationDuration
        self.visibleSlowAnimationDuration = visibleSlowAnimationDuration

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
