import SwiftUI

struct UserFeedbackView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: UserFeedbackViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(alignment: .center)
            } else if let formUrl = viewModel.formHtmlPath {
                LocalFileWebView(url: formUrl)
                    .navigationTitle("nav.feedback")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                VStack {
                    Text("info.feedback_modified_error")
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
