import SwiftUI

struct ScanQrCodeJoinOrgView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: ScanQrCodeJoinOrgViewModel

    @State private var showOpenSettings = false

    var body: some View {
        ZStack {
            VStack {
                if viewModel.isCameraDenied {
                    Text(t.t("~~Access to the camera is needed to scan QR codes"))
                    Button("Grant camera access") {
                        showOpenSettings = true
                    }
                    .stylePrimary()
                    .padding()

                    Spacer()
                } else {
                    let errorMessage = viewModel.errorMessage
                    if errorMessage.isNotBlank {
                        // TODO: Common styles
                        Text(errorMessage)
                            .padding()

                        Spacer()
                    } else {
                        if let image = viewModel.frameImage {
                            GeometryReader { geometry in
                                let label = t.t("~~Camera")
                                Image(image, scale: 1.0, orientation: .up, label: Text(label))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(
                                        width: geometry.size.width,
                                        height: geometry.size.height,
                                        alignment: .center)
                                    .clipped()
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.isSeekingAccess {
                ProgressView()
            }

            if showOpenSettings {
                OpenAppSettingsDialog(
                    title: t.t("~~Allow access to camera"),
                    dismissDialog: { showOpenSettings = false }
                ) {
                    Text(t.t("~~Open settings to grant access to camera."))
                        .padding(.horizontal)
                }
            }
        }
        .screenTitle(t.t("~~Scan QR Code"))
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}
