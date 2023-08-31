import SwiftUI

struct CopyWithAnimation: ViewModifier {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var viewModel: ViewCaseViewModel

    @Binding var pressed: Bool
    var copy: String

    func body(content: Content) -> some View {
        content
            .background {
                Color.gray.opacity(pressed ? 0.5 : 0)
                    .animation(.easeInOut(duration: 0.25), value: pressed)
                    .cornerRadius(appTheme.cornerRadius)
            }
            .gesture(
                LongPressGesture()
                    .onEnded { _ in
                        pressed.toggle()
                        let message = t.t("info.copied_value")
                            .replacingOccurrences(of: "{copied_string}", with: copy)
                        viewModel.toggleAlert(message: message)
                        viewModel.alertCount += 1
                        UIPasteboard.general.string = copy
                        let impactLight = UIImpactFeedbackGenerator(style: .light)
                        impactLight.impactOccurred()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            pressed.toggle()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            viewModel.alertCount -= 1
                            if viewModel.alertCount == 0 {
                                viewModel.clearAlert()
                            }
                        }
                    }
            )
    }
}

struct CustomLink: ViewModifier {
    var urlString: String

    func body(content: Content) -> some View {
        let url = URL(string: urlString)
        content
        .onTapGesture {
            if let url = url {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        .foregroundColor(url != nil ? Color(.systemBlue) : Color.black)
        .underline(url != nil, color: url != nil ? Color(.systemBlue) : Color.black)
    }
}

extension View {
    func customLink(urlString: String) -> some View {
        modifier( CustomLink(urlString: urlString) )
    }
}
