import SwiftUI

private let _disabledAlpha = 0.38

extension Color {

    init(hex: Int64) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: Double((hex >> 24) & 0xff) / 255
        )
    }

    func disabledAlpha() -> Color {
        return opacity(_disabledAlpha)
    }
}

struct ThemeColor {
    let themePrimary: Color
    let themePrimaryContainer: Color

    let primaryBlueColor: Color
    let primaryBlueOneTenthColor: Color
    let primaryRedColor: Color
    let primaryOrangeColor: Color
    let incidentDisasterContainerColor: Color
    let incidentDisasterContentColor: Color
    let attentionBackgroundColor: Color
    let cancelButtonContainerColor: Color
    let cancelButtonContentColor: Color
    let actionLinkColor: Color
    let separatorColor: Color
    let selectedOptionContainerColor: Color
    let neutralIconColor: Color

    init(
        themePrimary: Color = Color(hex: 0xFF2D2D2D),
        themePrimaryContainer: Color = Color(hex: 0xFFFECE09),

        primaryBlueColor: Color = Color(hex: 0xFF009BFF),
        primaryRedColor: Color = Color(hex: 0xFFED4747),
        primaryOrangeColor: Color = Color(hex: 0xFFF79820),
        incidentDisasterContentColor: Color = Color(hex: 0xFFFFFFFF),
        cancelButtonContainerColor: Color = Color(hex: 0xFFEAEAEA),
        separatorColor: Color = Color(hex: 0xFFF6F8F9),
        selectedOptionContainerColor: Color = Color(hex: 0xFFF6F8F9),
        neutralIconColor: Color = Color(hex: 0xFF848F99)
    ) {
        self.themePrimary = themePrimary
        self.themePrimaryContainer = themePrimaryContainer

        self.primaryBlueColor = primaryBlueColor
        primaryBlueOneTenthColor = primaryBlueColor.opacity(0.1)
        self.primaryRedColor = primaryRedColor
        self.primaryOrangeColor = primaryOrangeColor
        incidentDisasterContainerColor = primaryBlueColor
        self.incidentDisasterContentColor = incidentDisasterContentColor
        attentionBackgroundColor = themePrimaryContainer
        self.cancelButtonContainerColor = cancelButtonContainerColor
        cancelButtonContentColor = themePrimary
        actionLinkColor = primaryBlueColor
        self.separatorColor = separatorColor
        self.selectedOptionContainerColor = selectedOptionContainerColor
        self.neutralIconColor = neutralIconColor
    }
}
