import SwiftUI

struct RequestRedeployView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: RequestRedeployViewModel

    @State private var animateLoading = false

    var body: some View {
        ZStack {
            if animateLoading {
                ProgressView()
            } else {
                Text("Request redeploy")
            }
        }
        .hideNavBarUnderSpace()
        .screenTitle(t.t("requestRedeploy.request_redeploy"))
        .onChange(of: viewModel.isLoading) { newValue in
            animateLoading = newValue
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
    }
}
