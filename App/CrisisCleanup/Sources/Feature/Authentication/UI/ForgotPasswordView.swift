import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Text("Forgot password view")
    }
}
