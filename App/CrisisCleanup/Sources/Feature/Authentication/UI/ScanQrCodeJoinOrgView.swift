import SwiftUI

struct ScanQrCodeJoinOrgView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    var body: some View {
        VStack {
            Text(t.t("~~Use the camera app to scan the QR code."))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            Spacer()
        }
    }
}
