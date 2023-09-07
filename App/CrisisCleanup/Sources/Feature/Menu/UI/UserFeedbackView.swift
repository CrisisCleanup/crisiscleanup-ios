import SwiftUI

struct UserFeedbackView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: UserFeedbackViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(alignment: .center)
            } else if let formUrl = viewModel.formHtmlPath {
                LocalFileWebView(url: formUrl)
                    .navigationTitle(t.t("nav.feedback"))
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                VStack {
                    Text(t.t("info.feedback_modified_error"))
                        .fontHeader3()
                        .padding()

                    Spacer()
                }
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}
