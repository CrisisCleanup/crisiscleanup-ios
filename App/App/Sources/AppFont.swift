import Foundation
import UIKit

// Modified from https://medium.com/fabcoding/set-default-custom-font-for-entire-app-swift-5-55709e36e6f3

private let fontBaseName = "NunitoSans_10pt"
struct AppFontName {
    static let light = "\(fontBaseName)-Light"
    static let regular = "\(fontBaseName)-Regular"
    static let italic = "\(fontBaseName)-Italic"
    static let bold = "\(fontBaseName)-Bold"
}

extension UIFontDescriptor.AttributeName {
  static let nsctFontUIUsage = UIFontDescriptor.AttributeName(rawValue: "NSCTFontUIUsageAttribute")
}

extension UIFont {

    @objc class func mySystemFont(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: AppFontName.light, size: size)!
    }

    @objc class func myBoldSystemFont(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: AppFontName.regular, size: size)!
    }

    @objc class func myItalicSystemFont(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: AppFontName.italic, size: size)!
    }

  @objc convenience init(myCoder aDecoder: NSCoder) {
    guard
        let fontDescriptor = aDecoder.decodeObject(forKey: "UIFontDescriptor") as? UIFontDescriptor,
        let fontAttribute = fontDescriptor.fontAttributes[.nsctFontUIUsage] as? String else {
        self.init(myCoder: aDecoder)
        return
    }
    var fontName = ""
    switch fontAttribute {
    case "CTFontRegularUsage":
        fontName = AppFontName.regular
        fontName = AppFontName.bold
    case "CTFontObliqueUsage":
        fontName = AppFontName.italic
    default:
        fontName = AppFontName.regular
    }
    self.init(name: fontName, size: fontDescriptor.pointSize)!
  }

  class func overrideInitialize() {
    guard self == UIFont.self else { return }

    if let systemFontMethod = class_getClassMethod(self, #selector(systemFont(ofSize:))),
        let mySystemFontMethod = class_getClassMethod(self, #selector(mySystemFont(ofSize:))) {
        method_exchangeImplementations(systemFontMethod, mySystemFontMethod)
    }

    if let boldSystemFontMethod = class_getClassMethod(self, #selector(boldSystemFont(ofSize:))),
        let myBoldSystemFontMethod = class_getClassMethod(self, #selector(myBoldSystemFont(ofSize:))) {
        method_exchangeImplementations(boldSystemFontMethod, myBoldSystemFontMethod)
    }

    if let italicSystemFontMethod = class_getClassMethod(self, #selector(italicSystemFont(ofSize:))),
        let myItalicSystemFontMethod = class_getClassMethod(self, #selector(myItalicSystemFont(ofSize:))) {
        method_exchangeImplementations(italicSystemFontMethod, myItalicSystemFontMethod)
    }

    if let initCoderMethod = class_getInstanceMethod(self, #selector(UIFontDescriptor.init(coder:))), // Trick to get over the lack of UIFont.init(coder:))
        let myInitCoderMethod = class_getInstanceMethod(self, #selector(UIFont.init(myCoder:))) {
        method_exchangeImplementations(initCoderMethod, myInitCoderMethod)
    }
  }
}
