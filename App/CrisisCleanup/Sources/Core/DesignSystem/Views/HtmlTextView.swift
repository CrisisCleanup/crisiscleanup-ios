import WebKit
import SwiftUI

// https://developer.apple.com/forums/thread/653935
struct HtmlTextView: UIViewRepresentable {
    let htmlContent: String
    var fontSize = 16.0

    // TODO: Configure links to open in browser
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
                label.font = .systemFont(ofSize: fontSize)
                label.isScrollEnabled = false
            }
        }

        return label
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        DispatchQueue.main.async {
            let data = Data(self.htmlContent.utf8)
            if let attributedString = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html
                ],
                documentAttributes: nil
            ) {
                uiView.attributedText = attributedString
                uiView.font = .systemFont(ofSize: fontSize)
                uiView.textContainer.lineBreakMode = .byWordWrapping
//                uiView.contentMode = .scaleAspectFit
//                uiView.autoresizesSubviews = true
//                let size = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
//                let frame = UIScreen.main.applicationFrame
////                uiView.frame = frame
//                uiView.frame = CGRect(x: 1, y: 1, width: 20, height: 45)
//                uiView.bounds = UIScreen.main.bounds
//                uiView.clipsToBounds = true
//                uiView.textContainer.size = size
//                uiView.sizeToFit()
//                uiView.layoutIfNeeded()


//                uiView.sizeToFit()
//                uiView.sizeThatFits(size)
//                uiView.
//                let superBounds = uiView.superview?.bounds
//                var tempBounds = uiView.bounds
//                let newBounds = CGRect(x: tempBounds.minX, y: tempBounds.minY, width: UIScreen.main.bounds.width, height: tempBounds.height)
//                uiView.bounds = superBounds!
            }
        }



    }
}
