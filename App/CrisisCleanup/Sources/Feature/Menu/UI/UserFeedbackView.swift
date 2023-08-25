import SwiftUI
import WebKit

struct UserFeedbackView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: UserFeedbackViewModel

    var body: some View {
        Text("user feedback web view full screen")
    }
}
