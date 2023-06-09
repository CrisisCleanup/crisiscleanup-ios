import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    let disabled: Bool
    var textSidePadding = 16.0
    var weight: Font.Weight = .semibold

    init(_ disabled: Bool = false) {
        self.disabled = disabled
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: 56)
            .background(disabled ? .gray.disabledAlpha() : appTheme.colors.themePrimaryContainer)
            .foregroundColor(.black)
            .cornerRadius(appTheme.cornerRadius)
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
            .frame(maxWidth: .infinity, maxHeight: 56)
            .background(disabled ? .gray.disabledAlpha() : appTheme.colors.cancelButtonContainerColor)
            .foregroundColor(.black)
            .cornerRadius(appTheme.cornerRadius)
    }
}

struct BusyButtonContent: View {
    var isBusy: Bool
    var text: String

    var body: some View {
        if isBusy {
            ProgressView(value: 0.0).circularProgress()
        } else {
            Text(text)
        }
    }
}
