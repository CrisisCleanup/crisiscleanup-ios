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
                    .navigationTitle("~~Crisis Cleanup Feedback")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                VStack {
                    Text("~~Oops. It seems feedback was unintentionally modified.")
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
