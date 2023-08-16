import SwiftUI

private let fontBaseName = "NunitoSans10pt"
private let appFontRegularName = "\(fontBaseName)-Regular"
private let appFontBoldName = "\(fontBaseName)-Bold"
private let smallFontSize = 14.0
extension Font {
    static var bodyLarge: Font {
        Font.custom(appFontRegularName, size: 16.0)
    }

    static var bodySmall: Font {
        Font.custom(appFontRegularName, size: smallFontSize)
    }

    static var header1: Font {
        Font.custom(appFontBoldName, size: 24.0 )
    }

    static var header2: Font {
        Font.custom(appFontBoldName, size: 20.0)
    }

    static var header3: Font {
        Font.custom(appFontBoldName, size: 18.0)
    }

    static var header4: Font {
        Font.custom(appFontBoldName, size: 16.0)
    }

    static var header5: Font {
        Font.custom(appFontBoldName, size: 14.0)
    }
}

extension UIFont {
    static var bodySmall: UIFont {
        UIFont(name: appFontRegularName, size: smallFontSize)!
    }
}

fileprivate struct FontLineHeight: ViewModifier {
    let font: Font
    let lineHeight: CGFloat

    func body(content: Content) -> some View {
        content
            .font(font)
        // TODO: Set line height when relevant
    }
}

private let bodySmallModifier = FontLineHeight(font: Font.bodySmall, lineHeight: 16.8)
private let header1Modifier = FontLineHeight(font: Font.header1, lineHeight: 28.7)
private let header2Modifier = FontLineHeight(font: Font.header2, lineHeight: 27.28)
private let header3Modifier = FontLineHeight(font: Font.header3, lineHeight: 24.55)
private let header4Modifier = FontLineHeight(font: Font.header4, lineHeight: 18)
private let header5Modifier = FontLineHeight(font: Font.header5, lineHeight: 16)
extension View {
    func fontBodySmall() -> some View {
        ModifiedContent(
            content: self,
            modifier: bodySmallModifier
        )
    }

    func fontHeader1() -> some View {
        ModifiedContent(
            content: self,
            modifier: header1Modifier
        )
    }

    func fontHeader2() -> some View {
        ModifiedContent(
            content: self,
            modifier: header2Modifier
        )
    }

    func fontHeader3() -> some View {
        ModifiedContent(
            content: self,
            modifier: header3Modifier
        )
    }

    func fontHeader4() -> some View {
        ModifiedContent(
            content: self,
            modifier: header4Modifier
        )
    }

    func fontHeader5() -> some View {
        ModifiedContent(
            content: self,
            modifier: header5Modifier
        )
    }

    func fontHeader(size: Int) -> some View {
        let modifier = {
            switch size {
            case 1: return header1Modifier
            case 2: return header2Modifier
            case 3: return header3Modifier
            case 4: return header4Modifier
            case 5: return header5Modifier
            default: return header1Modifier
            }
        }()
        return ModifiedContent(
            content: self,
            modifier: modifier
        )
    }
}
