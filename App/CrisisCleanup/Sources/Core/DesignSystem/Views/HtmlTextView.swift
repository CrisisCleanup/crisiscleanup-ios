import WebKit
import SwiftUI

// https://developer.apple.com/forums/thread/653935
struct HtmlTextView: UIViewRepresentable {
    let htmlContent: String

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UITextView {
        let label = UITextView()
        DispatchQueue.main.async {
            let data = Data(self.htmlContent.utf8)
            if let attributedString = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html
                ],
                documentAttributes: nil
            ) {
                label.isEditable = false
                label.attributedText = attributedString
                label.font = .bodyLarge
            }
        }

        return label
    }

    func updateUIView(_ uiView: UITextView, context: Context) {}
}
