import UIKit

// From https://stackoverflow.com/questions/69126164/add-a-drop-shadow-on-an-uiimage-not-uiimageview
extension UIImage {
    /// Returns a new image with the specified shadow properties.
    /// This will increase the size of the image to fit the shadow and the original image.
    func withShadow(
        blur: CGFloat,
        offset: CGSize = .zero,
        color: UIColor = UIColor(white: 0.7, alpha: 0.8)
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
            1
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
}
