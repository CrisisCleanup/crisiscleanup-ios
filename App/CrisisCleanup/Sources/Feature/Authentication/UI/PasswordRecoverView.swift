import SwiftUI

struct PasswordRecoverView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: PasswordRecoverViewModel

    @State private var animateIsBusy = false

    var body: some View {
        ZStack {
            if animateIsBusy {
                ProgressView()
                    .frame(alignment: .center)
            }
        }
        .screenTitle(t.t(viewModel.screenTitleKey))
        .onChange(of: viewModel.isBusy, perform: { newValue in
            animateIsBusy = newValue
        })
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}
