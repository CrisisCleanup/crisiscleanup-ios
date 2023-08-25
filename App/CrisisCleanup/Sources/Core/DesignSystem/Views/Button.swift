import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    let disabled: Bool
    let maxWidth: CGFloat?
    var textSidePadding = 16.0
    var weight: Font.Weight = .semibold

    init(
        _ disabled: Bool = false,
        _ maxWidth: CGFloat? = nil
    ) {
        self.disabled = disabled
        self.maxWidth = maxWidth
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: maxWidth, minHeight: appTheme.buttonSize)
            .background(disabled ? .gray.disabledAlpha() : appTheme.colors.themePrimaryContainer)
            .foregroundColor(disabled ? .black.disabledAlpha() : .black)
            .cornerRadius(appTheme.cornerRadius)
    }
}

struct PrimaryButtonStyleModifier: ViewModifier {
    @Environment(\.isEnabled) var isEnabled

    var isWrapWidth: Bool

    func body(content: Content) -> some View {
        return content.buttonStyle(PrimaryButtonStyle(!isEnabled, isWrapWidth ? nil : .infinity))
    }
}

struct CancelButtonStyle: ButtonStyle {
    let disabled: Bool
    var textSidePadding = 16.0
    var weight: Font.Weight = .semibold

    init(_ disabled: Bool = false) {
        self.disabled = disabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: appTheme.buttonSize)
            .background(disabled ? .gray.disabledAlpha() : appTheme.colors.cancelButtonContainerColor)
            .foregroundColor(disabled ? .black.disabledAlpha() : .black)
            .cornerRadius(appTheme.cornerRadius)
    }
}

struct CancelButtonSytleModifier: ViewModifier {
    @Environment(\.isEnabled) var isEnabled
    func body(content: Content) -> some View {
        return content.buttonStyle(CancelButtonStyle(!isEnabled))
    }
}

struct BlackButtonStyle: ButtonStyle {
    let disabled: Bool
    var textSidePadding = 16.0
    var weight: Font.Weight = .semibold

    init(_ disabled: Bool = false) {
        self.disabled = disabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: appTheme.buttonSize)
            .background(disabled ? .gray.disabledAlpha() : appTheme.colors.navigationContainerColor)
            .foregroundColor(disabled ? .white.disabledAlpha() : .white)
            .cornerRadius(appTheme.cornerRadius)
    }
}

struct BlackButtonSytleModifier: ViewModifier {
    @Environment(\.isEnabled) var isEnabled
    func body(content: Content) -> some View {
        return content.buttonStyle(BlackButtonStyle(!isEnabled))
    }
}

struct RoundedRectangleButtonStyle: ButtonStyle {
    let disabled: Bool

    init(_ disabled: Bool = false) {
        self.disabled = disabled
    }

    func makeBody(configuration: Configuration) -> some View {
        let backgroundColor = appTheme.colors.attentionBackgroundColor
        let foregroundColor = Color.black
        let buttonSize = appTheme.buttonSize
        configuration.label
            .background(disabled ? backgroundColor.disabledAlpha() : backgroundColor)
            .foregroundColor(disabled ? foregroundColor.disabledAlpha() : foregroundColor)
            .frame(width: buttonSize, height: buttonSize)
            .cornerRadius(appTheme.cornerRadius)
            .shadow(radius: appTheme.shadowRadius)
    }
}

struct RoundedRectangleStyleModifier: ViewModifier {
    @Environment(\.isEnabled) var isEnabled
    func body(content: Content) -> some View {
        return content.buttonStyle(RoundedRectangleButtonStyle(!isEnabled))
    }
}

struct BusyButtonContent: View {
    var isBusy: Bool
    var text: String

    var body: some View {
        if isBusy {
            ProgressView().circularProgress()
        } else {
            Text(text)
        }
    }
}

extension Button {
    func stylePrimary(_ isWrapWidth: Bool = false) -> some View {
        ModifiedContent(content: self, modifier: PrimaryButtonStyleModifier(isWrapWidth: isWrapWidth))
    }

    func styleCancel() -> some View {
        ModifiedContent(content: self, modifier: CancelButtonSytleModifier())
    }

    func styleBlack() -> some View {
        ModifiedContent(content: self, modifier: BlackButtonSytleModifier())
    }

    func styleRoundedRectanglePrimary() -> some View {
        ModifiedContent(content: self, modifier: RoundedRectangleStyleModifier())
    }
}
