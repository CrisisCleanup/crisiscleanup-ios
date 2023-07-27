import SwiftUI

struct HtmlAS: View {

    @State var htmlContent: String
    @State var htmlAS: AttributedString = AttributedString()

    var body: some View {
        Text(htmlAS)
            .onAppear {
                DispatchQueue.main.async{
                    let data = Data(htmlContent.utf8)
                    if let attributedString = try? NSAttributedString(
                        data: data,
                        options: [
                            .documentType: NSAttributedString.DocumentType.html
                        ],
                        documentAttributes: nil
                    ) {
                        htmlAS = AttributedString(attributedString)
                    }

                }
            }
            .onChange(of: htmlContent) { html in
                DispatchQueue.main.async{
                    let data = Data(html.utf8)
                    if let attributedString = try? NSAttributedString(
                        data: data,
                        options: [
                            .documentType: NSAttributedString.DocumentType.html
                        ],
                        documentAttributes: nil
                    ) {
                        htmlAS = AttributedString(attributedString)
                    }

                }
            }
    }
}
