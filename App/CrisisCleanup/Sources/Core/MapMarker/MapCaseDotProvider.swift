import LRUCache
import SwiftUI

protocol MapCaseDotProvider : MapCaseIconProvider {
    func setDotProperties(_ dotDrawProperties: DotDrawProperties)
}

class InMemoryDotProvider: MapCaseDotProvider {

    private let cacheLock = NSRecursiveLock()
    private let cache = LRUCache<DotCacheKey, UIImage>(countLimit: 32)

    private var cacheDotDrawProperties: DotDrawProperties
    private var dotOffsetPx = (0.0, 0.0)

    var iconOffset: (Double, Double) { dotOffsetPx }

    init() {
        cacheDotDrawProperties = DotDrawProperties()
        setIconOffset()
    }

    func setDotProperties(_ dotDrawProperties: DotDrawProperties) {
        cacheLock.withLock {
            if cacheDotDrawProperties != dotDrawProperties {
                cache.removeAllValues()
            }
            cacheDotDrawProperties = dotDrawProperties
            setIconOffset()
        }
    }

    private func setIconOffset() {
        let centerSize = cacheDotDrawProperties.centerSize
        dotOffsetPx = (centerSize, centerSize)
    }

    private func cacheDotImage(
        _ cacheKey: DotCacheKey,
        _ dotDrawProperties: DotDrawProperties
    ) -> UIImage? {
        let colors = getMapMarkerColors(
            cacheKey.statusClaim,
            isDuplicate: cacheKey.isDuplicate,
            isFilteredOut: cacheKey.isFilteredOut,
            isVisited: false,
            isDot: true
        )
        let image = drawDot(colors, dotDrawProperties)
        return cacheLock.withLock {
            if cacheDotDrawProperties != dotDrawProperties {
                return nil
            }

            cache.setValue(image, forKey: cacheKey)
            return image
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
        isVisited: Bool
    ) -> UIImage? {
        getIcon(
            statusClaim,
            workType,
            hasMultipleWorkTypes,
            isFilteredOut: isFilteredOut,
            isDuplicate: isDuplicate
        )
    }

    func getIcon(
        _ statusClaim: WorkTypeStatusClaim,
        _ workType: WorkTypeType,
        _ hasMultipleWorkTypes: Bool,
        isFilteredOut: Bool,
        isDuplicate: Bool,
        isVisited: Bool
    ) -> UIImage? {
        let cacheKey = DotCacheKey(statusClaim, isDuplicate: isDuplicate, isFilteredOut: isFilteredOut)
        let cachedIcon = cacheLock.withLock {
            return cache.value(forKey: cacheKey)
        }
        if let cached = cachedIcon {
            return cached
        }

        let dotDrawProperties = cacheDotDrawProperties
        _ = cacheDotImage(cacheKey, dotDrawProperties)
        return cacheLock.withLock {
            return cacheDotDrawProperties == dotDrawProperties ? cache.value(forKey: cacheKey) : nil
        }
    }

    private func drawDot(
        _ colors: MapMarkerColor,
        _ dotDrawProperties: DotDrawProperties
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: dotDrawProperties.imageSize).image { context in
            let c = context.cgContext
            c.interpolationQuality = .high
            c.setShouldAntialias(true)

            c.setLineWidth(dotDrawProperties.strokeWidth)
            c.setStrokeColor(colors.stroke.cgColor!)
            c.strokeEllipse(in: dotDrawProperties.dotRect)

            c.setFillColor(colors.fill.cgColor!)
            c.fillEllipse(in: dotDrawProperties.fillRect)
        }
        let data = renderer.pngData()!

        return UIImage(data: data)!
    }
}

struct DotDrawProperties: Equatable {
    let strokeWidth: Double
    let centerSize: Double
    let imageSize: CGSize
    private let dotOffset: Double
    let dotRect: CGRect
    let fillRect: CGRect

    init (
        bitmapSize: Double = 8.0,
        dotDiameter: Double = 5.0,
        strokeWidth: Double = 0.5
    ) {
        self.strokeWidth = strokeWidth
        self.centerSize = bitmapSize * 0.5

        imageSize = CGSize(width: bitmapSize, height: bitmapSize)

        dotOffset = (bitmapSize - dotDiameter) * 0.5

        let dotPoint = CGPoint(x: dotOffset, y: dotOffset)
        let dotSize = CGSize(width: dotDiameter, height: dotDiameter)
        dotRect = CGRect(origin: dotPoint, size: dotSize)

        let fillOffset = dotOffset + strokeWidth
        let fillPoint = CGPoint(x: fillOffset, y: fillOffset)
        let fillDiameter = dotDiameter - 2 * strokeWidth
        let fillSize = CGSize(width: fillDiameter, height: fillDiameter)
        fillRect = CGRect(origin: fillPoint, size: fillSize)
    }
}

private struct DotCacheKey: Hashable {
    let statusClaim: WorkTypeStatusClaim
    let isDuplicate: Bool
    let isFilteredOut: Bool

    init(
        _ statusClaim: WorkTypeStatusClaim,
        isDuplicate: Bool = false,
        isFilteredOut: Bool = false
    ) {
        self.statusClaim = statusClaim
        self.isDuplicate = isDuplicate
        self.isFilteredOut = isFilteredOut
    }
}
