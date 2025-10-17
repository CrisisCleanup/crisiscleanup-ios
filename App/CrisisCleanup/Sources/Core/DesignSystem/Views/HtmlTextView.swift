import WebKit
import SwiftUI

// https://developer.apple.com/forums/thread/653935
struct HtmlTextView: View {
    let htmlContent: String
    var linkify: Bool = true

    @State private var contentAttributedString = AttributedString()

    var body: some View {
        Text(contentAttributedString)
            .onAppear {
                DispatchQueue.main.async {
                    let data = Data(htmlContent.utf8)
                    if let attributedString = try? NSMutableAttributedString(
                        data: data,
                        options: [
                            .documentType: NSAttributedString.DocumentType.html
                        ],
                        documentAttributes: nil
                    ) {
                        attributedString.replaceFontBodyLarge()
                        contentAttributedString = AttributedString(attributedString)

                        if !linkify {
                            for run in contentAttributedString.runs {
                                if run.link != nil {
                                    contentAttributedString[run.range].link = nil
                                }
                            }
                        }
                    }
                }
            }
            .multilineTextAlignment(.leading)
            .disabled(true)
    }
}
