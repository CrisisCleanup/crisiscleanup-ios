import CoreGraphics
import Foundation
import LRUCache
import SwiftUI

class WorkTypeIconProvider: MapCaseIconProvider {
    // TODO: Resize image before rastering
    private static func loadIcon(_ iconName: String, size: CGSize) -> UIImage {
        UIImage(named: iconName, in: .module, compatibleWith: nil)!
    }

    private let cacheLock = NSLock()
    private let cache = LRUCache<CacheKey, UIImage>(countLimit: 64)
    private let bwCache = LRUCache<String, UIImage>(countLimit: 16)
    private let cgImageCache = LRUCache<CacheKey, CGImage>(countLimit: 64)

    // TODO: Parameterize values

    private let shadowRadius = 2.0
    private let shadowColor = 0xFF666666

    private let bitmapSize: CGSize
    private let bitmapLength: Double
    private var bitmapCenterOffset = (0.0, 0.0)

    private let cornerMarkLength: Double
    private let cornerMarkSize: CGSize

    var iconOffset: (Double, Double)


    private lazy var plusImageLazy: UIImage = {
        let image = WorkTypeIconProvider.loadIcon("ic_work_type_plus", size: cornerMarkSize)
        let filteredImage = grayscaleToColor(image, fromColorInt: 0xFF000000, toColorInt: 0xFFFFFFFF)
        return UIImage(cgImage: filteredImage)
    }()

    private lazy var cameraImageLazy: UIImage = {
        let image = WorkTypeIconProvider.loadIcon("ic_work_type_photos", size: cornerMarkSize)
        let filteredImage = grayscaleToColor(image, fromColorInt: 0xFF000000, toColorInt: 0xFFFFFFFF)
        return UIImage(cgImage: filteredImage)
    }()

    init() {
        bitmapLength = 48 + 2 * shadowRadius
        bitmapSize = CGSizeMake(bitmapLength, bitmapLength)
        let centerOffset = bitmapLength * 0.5
        bitmapCenterOffset = (centerOffset, centerOffset)
        iconOffset = bitmapCenterOffset

        cornerMarkLength = bitmapLength * 0.4
        cornerMarkSize = CGSizeMake(cornerMarkLength, cornerMarkLength)
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
        _ hasMultipleWorkTypes: Bool,
        isFavorite: Bool,
        isImportant: Bool,
        isFilteredOut: Bool,
        isDuplicate: Bool,
        isVisited: Bool,
        hasPhotos: Bool,
    ) -> UIImage? {
        let cacheKey = CacheKey(
            statusClaim,
            workType,
            hasMultipleWorkTypes,
            isFavorite: isFavorite,
            isImportant: isImportant,
            isFilteredOut: isFilteredOut,
            isDuplicate: isDuplicate,
            isVisited: isVisited,
            hasPhotos: hasPhotos,
        )
        let existing = cacheLock.withLock { cache.value(forKey: cacheKey) }
        guard existing == nil else { return existing }

        return cacheIconBitmap(cacheKey)
    }

    func getIcon(
        _ statusClaim: WorkTypeStatusClaim,
        _ workType: WorkTypeType,
        _ hasMultipleWorkTypes: Bool,
        isFilteredOut: Bool,
        isDuplicate: Bool,
        isVisited: Bool,
        hasPhotos: Bool,
    ) -> UIImage? {
        getIcon(
            statusClaim,
            workType,
            hasMultipleWorkTypes,
            isFavorite: false,
            isImportant: false,
            isFilteredOut: isFilteredOut,
            isDuplicate: isDuplicate,
            isVisited: isVisited,
            hasPhotos: hasPhotos,
        )
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
            let baseImage = WorkTypeIconProvider.loadIcon(iconName, size: bitmapSize)
            bwCache.setValue(bwImage, forKey: iconName)
            bwImage = baseImage
        }

        let colors = getMapMarkerColors(
            cacheKey.statusClaim,
            isDuplicate: cacheKey.isDuplicate,
            isFilteredOut: cacheKey.isFilteredOut,
            isVisited: cacheKey.isVisited
        )

        let filteredImage = grayscaleToColor(
            bwImage!,
            fromColorInt: colors.fillInt64,
            toColorInt: colors.strokeInt64
        )
        let filteredUiImage = UIImage(cgImage: filteredImage)

        let shadowImage = cacheKey.isFilteredOut
        ? filteredUiImage
        : filteredUiImage.withShadow(blur: 6)

        func drawImageMark(
            baseImage: UIImage,
            imageMark: UIImage,
            isLeftAligned: Bool,
            isFiltered: Bool,
            bottomOffset: CGFloat = 0.0,
            markScale: CGFloat = 1.2,
            padding: CGFloat = 1.0,
        ) -> UIImage {
            let markImageSize = imageMark.size

            let size = baseImage.size
            let markWidth = markImageSize.width * markScale
            let markHeight = markImageSize.height * markScale
            let rightBounds = isLeftAligned ? padding + markWidth : size.width - padding
            let bottomBounds = size.height - padding
            let x = rightBounds - markWidth
            let y = bottomBounds - markHeight - bottomOffset
            let offsetRect = CGRectMake(x, y, markWidth, markHeight)

            UIGraphicsBeginImageContextWithOptions(size, false, 1)

            let context = UIGraphicsGetCurrentContext()!
            context.interpolationQuality = .high
            context.setShouldAntialias(true)

            baseImage.draw(in: CGRect(origin: .zero, size: size))
            if isFiltered {
                imageMark.draw(in: offsetRect, blendMode: .normal, alpha: filteredOutMarkerAlpha)
            } else {
                imageMark.draw(in: offsetRect)
            }
            let markedImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return markedImage
        }

        let plussedImage = cacheKey.hasMultipleWorkTypes
        ? drawImageMark(
            baseImage: shadowImage,
            imageMark: plusImageLazy,
            isLeftAligned: false,
            isFiltered: cacheKey.isFilteredOut
        )
        : shadowImage

        let photodImage = cacheKey.hasPhotos
        ? drawImageMark(
            baseImage: plussedImage,
            imageMark: cameraImageLazy,
            isLeftAligned: true,
            isFiltered: cacheKey.isFilteredOut,
            bottomOffset: 4.0,
        )
        : plussedImage

        let scaledImage = photodImage.scaleImage(imageSize: bitmapLength, offset: shadowRadius, scaleToScreen: true)
        return scaledImage.cgImage!
    }
}

// Keep hashable properties synced with map marker reuse identifier
private struct CacheKey: Hashable {
    let statusClaim: WorkTypeStatusClaim
    let workType: WorkTypeType
    let hasMultipleWorkTypes: Bool
    let isFavorite: Bool
    let isImportant: Bool
    let isFilteredOut: Bool
    let isDuplicate: Bool
    let isVisited: Bool
    let hasPhotos: Bool

    init(
        _ statusClaim: WorkTypeStatusClaim,
        _ workType: WorkTypeType,
        _ hasMultipleWorkTypes: Bool,
        isFavorite: Bool = false,
        isImportant: Bool = false,
        isFilteredOut: Bool = false,
        isDuplicate: Bool = false,
        isVisited: Bool = false,
        hasPhotos: Bool = false,
    ) {
        self.statusClaim = statusClaim
        self.workType = workType
        self.hasMultipleWorkTypes = hasMultipleWorkTypes
        self.isFavorite = isFavorite
        self.isImportant = isImportant
        self.isFilteredOut = isFilteredOut
        self.isDuplicate = isDuplicate
        self.isVisited = isVisited
        self.hasPhotos = hasPhotos
    }
}
