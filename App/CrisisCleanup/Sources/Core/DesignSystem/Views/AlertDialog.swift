import SwiftUI

struct AlertDialog<Content>: View where Content : View {
    let title: String
    let positiveActionText: String
    let negativeActionText: String
    let dismissDialog: () -> Void
    var negativeAction: () -> Void = {}
    var positiveAction: () -> Void = {}
    @ViewBuilder let content: () -> Content

    var body: some View {
        // TODO: Common dimensions throughout
        ZStack {
            Color(.black).disabledAlpha()
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismissDialog()
                }

            VStack {
                Text(title)
                    .fontHeader3()
                    .padding(16)

                content()

                if positiveActionText.isNotBlank || negativeActionText.isNotBlank {
                    HStack(spacing: 16) {
                        Spacer()

                        if negativeActionText.isNotBlank {
                            Button {
                                negativeAction()
                            } label: {
                                Text(negativeActionText)
                                    .fontHeader4()
                            }
                        }

                        if positiveActionText.isNotBlank {
                            Button {
                                positiveAction()
                            } label: {
                                Text(positiveActionText)
                                    .fontHeader4()
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.all, 16)
                }
            }
            .cardContainerPadded()
            .frame(maxWidth: 400)
        }
    }
}

struct OpenAppSettingsDialog<Content>: View where Content : View {
    @Environment(\.translator) var t: KeyAssetTranslator

    let title: String
    let dismissDialog: () -> Void
    var positiveAction: () -> Void = {}
    @ViewBuilder let content: () -> Content

    var body: some View {
        AlertDialog(
            title: title,
            positiveActionText: t.t("info.app_settings"),
            negativeActionText: t.t("actions.close"),
            dismissDialog: dismissDialog,
            negativeAction: dismissDialog,
            positiveAction: {
                guard let url = URL(string: UIApplication.openSettingsURLString) else {
                   return
                }
                if UIApplication.shared.canOpenURL(url) {
                   UIApplication.shared.open(url, options: [:])
                }
                dismissDialog()
            },
            content: content
        )
    }
}
