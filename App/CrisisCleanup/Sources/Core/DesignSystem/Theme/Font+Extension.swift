import SwiftUI

private let fontBaseName = "NunitoSans10pt"
private let appFontRegularName = "\(fontBaseName)-Regular"
private let appFontBoldName = "\(fontBaseName)-Bold"
extension Font {
    static var bodyLarge: Font {
        Font.custom(appFontRegularName, size: 16.0)
    }

    static var bodySmall: Font {
        Font.custom(appFontRegularName, size: 14.0)
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

fileprivate struct FontLineHeight: ViewModifier {
    let font: Font
    let lineHeight: CGFloat

    func body(content: Content) -> some View {
        content
            .font(font)
        // TODO: Set line height when relevant
    }
}

extension View {
    func fontBodySmall() -> some View {
        ModifiedContent(
            content: self,
            modifier: FontLineHeight(font: Font.bodySmall, lineHeight: 16.8)
        )
    }

    func fontHeader1() -> some View {
        ModifiedContent(
            content: self,
            modifier: FontLineHeight(font: Font.header1, lineHeight: 28.7)
        )
    }

    func fontHeader2() -> some View {
        ModifiedContent(
            content: self,
            modifier: FontLineHeight(font: Font.header2, lineHeight: 27.28)
        )
    }

    func fontHeader3() -> some View {
        ModifiedContent(
            content: self,
            modifier: FontLineHeight(font: Font.header3, lineHeight: 24.55)
        )
    }

    func fontHeader4() -> some View {
        ModifiedContent(
            content: self,
            modifier: FontLineHeight(font: Font.header4, lineHeight: 18)
        )
    }

    func fontHeader5() -> some View {
        ModifiedContent(
            content: self,
            modifier: FontLineHeight(font: Font.header5, lineHeight: 16)
        )
    }
}
