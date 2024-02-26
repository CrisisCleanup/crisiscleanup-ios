import WebKit
import SwiftUI

// https://developer.apple.com/forums/thread/653935
struct HtmlTextView: View {
    let htmlContent: String

    @State private var contentAttributedString = AttributedString()

    var body: some View {
        Text(contentAttributedString)
            .onAppear {
                DispatchQueue.main.async {
                    let data = Data(self.htmlContent.utf8)
                    if let attributedString = try? NSMutableAttributedString(
                        data: data,
                        options: [
                            .documentType: NSAttributedString.DocumentType.html
                        ],
                        documentAttributes: nil
                    ) {
                        attributedString.replaceFontBodyLarge()
                        contentAttributedString = AttributedString(attributedString)
                    }
                }
            }
            .multilineTextAlignment(.leading)
            .disabled(true)
    }
}
