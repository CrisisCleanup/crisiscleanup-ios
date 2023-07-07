import CoreGraphics
import Foundation
import LRUCache
import SwiftUI

class WorkTypeIconProvider: MapCaseIconProvider {
    private static func loadIcon(_ iconName: String) -> UIImage {
        UIImage(named: iconName, in: .module, compatibleWith: nil)!
    }

    private let cacheLock = NSLock()
    private let cache = LRUCache<CacheKey, UIImage>(countLimit: 64)
    private let bwCache = LRUCache<String, UIImage>(countLimit: 16)
    private let cgImageCache = LRUCache<CacheKey, CGImage>(countLimit: 64)

    // TODO: Parameterize values

    private let shadowRadius = 2.0
    private let shadowColor = 0xFF666666

    private let bitmapSize: Double
    private var bitmapCenterOffset = (0.0, 0.0)

    private let plusImageSize: Double

    var iconOffset: (Double, Double)

    private lazy var plusImageLazy: UIImage = {
        let image = WorkTypeIconProvider.loadIcon("ic_work_type_plus")
        let filteredImage = grayscaleToColor(image, fromColorInt: 0, toColorInt: -1)
        return UIImage(cgImage: filteredImage)
    }()

    init() {
        bitmapSize = 36.0 + 2 * shadowRadius
        let centerOffset = bitmapSize * 0.5
        bitmapCenterOffset = (centerOffset, centerOffset)
        iconOffset = bitmapCenterOffset

        plusImageSize = bitmapSize * 0.4
    }

    private func cacheIconBitmap(_ cacheKey: CacheKey) -> UIImage {
        let image = drawIcon(cacheKey)
        let uiImage = UIImage(cgImage: image)
        return cacheLock.withLock {
            cgImageCache.setValue(image, forKey: cacheKey)
            cache.setValue(uiImage, forKey: cacheKey)
            return uiImage
        }
    }

    func getIcon(
        _ statusClaim: WorkTypeStatusClaim,
        _ workType: WorkTypeType,
        _ isFavorite: Bool,
        _ isImportant: Bool,
        _ hasMultipleWorkTypes: Bool
    ) -> UIImage? {
        let cacheKey = CacheKey(
            statusClaim,
            workType,
            hasMultipleWorkTypes,
            isFavorite: isFavorite,
            isImportant: isImportant
        )
        let existing = cacheLock.withLock { cache.value(forKey: cacheKey) }
        guard existing == nil else { return existing }

        return cacheIconBitmap(cacheKey)
    }

    func getIcon(
        _ statusClaim: WorkTypeStatusClaim,
        _ workType: WorkTypeType,
        _ hasMultipleWorkTypes: Bool
    ) -> UIImage? {
        return getIcon(statusClaim, workType, false, false, hasMultipleWorkTypes)
    }

    private func grayscaleToColor(_ imageIn: UIImage, fromColorInt: Int64, toColorInt: Int64) -> CGImage {
        let context = CIContext()
        let ciImage = CIImage(image: imageIn)
        let imageFilter = LerpGrayscaleToColor()
        imageFilter.inputImage = ciImage
        imageFilter.zeroColorInt = fromColorInt
        imageFilter.oneColorInt = toColorInt
        let ciImageOut = imageFilter.outputImage!
        return context.createCGImage(ciImageOut, from: ciImageOut.extent)!
    }

    private func drawIcon(_ cacheKey: CacheKey) -> CGImage {
        var lookupKey = cacheKey.workType
        if cacheKey.isFavorite {
            lookupKey = .favorite
        }
        else if cacheKey.isImportant {
            lookupKey = .important
        }
        let iconName = workTypeIconLookup[lookupKey] ?? workTypeIconLookup[.unknown]!

        var bwImage = bwCache.value(forKey: iconName)
        if bwImage == nil {
            let baseImage = WorkTypeIconProvider.loadIcon(iconName)
            bwCache.setValue(bwImage, forKey: iconName)
            bwImage = baseImage
        }

        let colors = getMapMarkerColors(cacheKey.statusClaim)
        let filteredImage = grayscaleToColor(bwImage!, fromColorInt: colors.fillLong, toColorInt: colors.strokeLong)

        let shadowImage = UIImage(cgImage: filteredImage).withShadow(blur: 6)

        var plussedImage = shadowImage
        if cacheKey.hasMultipleWorkTypes {
            let plusImage = plusImageLazy
            let plusSize = plusImage.size

            let size = plussedImage.size
            let padding = 1.0
            let rightBounds = size.width - padding
            let bottomBounds = size.height - padding
            let x = rightBounds - plusSize.width
            let y = bottomBounds - plusSize.height
            let offsetRect = CGRectMake(x, y, plusSize.width, plusSize.height)

            UIGraphicsBeginImageContextWithOptions(size, false, 1)

            let context = UIGraphicsGetCurrentContext()!
            context.interpolationQuality = .high
            context.setShouldAntialias(true)

            plussedImage.draw(in: CGRect(origin: .zero, size: size))
            plusImage.draw(in: offsetRect)
            plussedImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }

        let scaledImage = plussedImage.scaleImage(imageSize: bitmapSize, offset: shadowRadius, scaleToScreen: true)
        return scaledImage.cgImage!
    }
}

private struct CacheKey: Hashable {
    let statusClaim: WorkTypeStatusClaim
    let workType: WorkTypeType
    let hasMultipleWorkTypes: Bool
    let isFavorite: Bool
    let isImportant: Bool

    init(
        _ statusClaim: WorkTypeStatusClaim,
        _ workType: WorkTypeType,
        _ hasMultipleWorkTypes: Bool,
        isFavorite: Bool = false,
        isImportant: Bool = false
    ) {
        self.statusClaim = statusClaim
        self.workType = workType
        self.hasMultipleWorkTypes = hasMultipleWorkTypes
        self.isFavorite = isFavorite
        self.isImportant = isImportant
    }
}
