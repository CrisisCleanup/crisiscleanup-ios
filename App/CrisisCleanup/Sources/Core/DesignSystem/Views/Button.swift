import SwiftUI

// TODO: Move into common dimensions
private let maxButtonHeight = 56.0

struct PrimaryButtonStyle: ButtonStyle {
    let disabled: Bool
    var textSidePadding = 16.0
    var weight: Font.Weight = .semibold

    init(_ disabled: Bool = false) {
        self.disabled = disabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: maxButtonHeight)
            .background(disabled ? .gray.disabledAlpha() : appTheme.colors.themePrimaryContainer)
            .foregroundColor(disabled ? .black.disabledAlpha() : .black)
            .cornerRadius(appTheme.cornerRadius)
    }
}

struct PrimaryButtonStyleModifier: ViewModifier {
    @Environment(\.isEnabled) var isEnabled
    func body(content: Content) -> some View {
        return content.buttonStyle(PrimaryButtonStyle(!isEnabled))
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
            .frame(maxWidth: .infinity, maxHeight: maxButtonHeight)
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
            .frame(maxWidth: .infinity, maxHeight: maxButtonHeight)
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
    func stylePrimary() -> some View {
        ModifiedContent(content: self, modifier: PrimaryButtonStyleModifier())
    }

    func styleCancel() -> some View {
        ModifiedContent(content: self, modifier: CancelButtonSytleModifier())
    }

    func styleBlack() -> some View {
        ModifiedContent(content: self, modifier: BlackButtonSytleModifier())
    }
}
