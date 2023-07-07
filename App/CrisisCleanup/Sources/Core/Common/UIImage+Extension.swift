import CoreGraphics
import UIKit

// From https://stackoverflow.com/questions/69126164/add-a-drop-shadow-on-an-uiimage-not-uiimageview
extension UIImage {
    /// Returns a new image with the specified shadow properties.
    /// This will increase the size of the image to fit the shadow and the original image.
    func withShadow(
        blur: CGFloat,
        offset: CGSize = .zero,
        color: UIColor = UIColor(white: 0.1, alpha: 0.7)
    ) -> UIImage {
        let shadowRect = CGRect(
            x: offset.width - blur,
            y: offset.height - blur,
            width: size.width + blur * 2,
            height: size.height + blur * 2
        )

        UIGraphicsBeginImageContextWithOptions(
            CGSize(
                width: max(shadowRect.maxX, size.width) - min(shadowRect.minX, 0),
                height: max(shadowRect.maxY, size.height) - min(shadowRect.minY, 0)
            ),
            false,
            0
        )

        let context = UIGraphicsGetCurrentContext()!
        context.interpolationQuality = .high
        context.setShouldAntialias(true)
        context.setShadow(
            offset: offset,
            blur: blur,
            color: color.cgColor
        )

        draw(
            in: CGRect(
                x: max(0, -shadowRect.origin.x),
                y: max(0, -shadowRect.origin.y),
                width: size.width,
                height: size.height
            )
        )
        let image = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()

        return image
    }

    // TODO: Reserach a sharper scaling algorithm that can preserve quality edges as well as outlines.
    func scaleImage(
        imageSize: Double,
        offset: Double = 0,
        scaleToScreen: Bool = false
    ) -> UIImage {
        let drawSize = imageSize - 2 * offset

        let baseSize = size
        let widthD = Double(baseSize.width)
        let heightD = Double(baseSize.height)
        let widthScale = drawSize / widthD
        let heightScale = drawSize / heightD
        let scale = min(widthScale, heightScale)
        let scaledSize = CGSize(
            width: widthD * scale,
            height: heightD * scale
        )

        let x = offset + (drawSize - scaledSize.width) * 0.5
        let y = offset + (drawSize - scaledSize.height) * 0.5
        let offsetRect = CGRectMake(x, y, x + scaledSize.width, y + scaledSize.height)
        let squareSize = CGSize(width: imageSize, height: imageSize)

        UIGraphicsBeginImageContextWithOptions(squareSize, false, scaleToScreen ? 1 : 0)

        let context = UIGraphicsGetCurrentContext()!
        context.interpolationQuality = .high
        context.setShouldAntialias(true)

        draw(in: offsetRect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return scaledImage
    }
}
