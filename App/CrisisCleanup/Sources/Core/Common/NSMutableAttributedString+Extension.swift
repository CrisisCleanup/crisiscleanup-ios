import Foundation
import UIKit

// https://stackoverflow.com/questions/43723345/nsattributedstring-change-the-font-overall-but-keep-all-other-attributes
extension NSMutableAttributedString {
    func replaceFont(font: UIFont, size: CGFloat) {
        beginEditing()
        self.enumerateAttribute(.font, in: NSRange(location: 0, length: self.length)) { (value, range, stop) in
            if let f = value as? UIFont {
                let ufd = f.fontDescriptor.withFamily(font.familyName).withSymbolicTraits(f.fontDescriptor.symbolicTraits)!
                let newFont = UIFont(descriptor: ufd, size: 16)
                removeAttribute(.font, range: range)
                addAttribute(.font, value: newFont, range: range)
            }
        }
        endEditing()
    }
}
