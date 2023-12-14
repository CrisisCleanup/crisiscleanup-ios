import SwiftUI

struct ScanQrCodeJoinOrgView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: ScanQrCodeJoinOrgViewModel

    @State private var showOpenSettings = false

    var body: some View {
        ZStack {
            VStack {
                if viewModel.isCameraDenied {
                    Text(t.t("info.camera_access_needed"))
                    Button(t.t("info.grant_camera_access")) {
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
                                let label = t.t("nav.camera")
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
                    title: t.t("info.allow_camera_access"),
                    dismissDialog: { showOpenSettings = false }
                ) {
                    Text(t.t("info.open_settings_to_grant_camera_access"))
                        .padding(.horizontal)
                }
            }
        }
        .screenTitle(t.t("volunteerOrg.scan_qr_code"))
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}
