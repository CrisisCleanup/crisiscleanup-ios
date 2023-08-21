import Combine
import _PhotosUI_SwiftUI
import Foundation
import LRUCache

public protocol LocalFileCache {
    func cachePicked(
        _ incidentId: Int64,
        _ worksiteId: Int64,
        _ picked: [PhotosPickerItem]
    ) async throws -> [String: String]

    func cacheImage(
        _ incidentId: Int64,
        _ worksiteId: Int64,
        _ image: UIImage
    ) async throws -> [String: String]

    func getImage(
        _ imageFileName: String
    ) -> UIImage?
}

class MemoryLocalFileCache: LocalFileCache {
    private let logger: AppLogger

    private var imageCache = LRUCache<String, UIImage>(countLimit: 8)

    private var cacheDir: URL? = nil

    init(
        loggerFactory: AppLoggerFactory
    ) {
        logger = loggerFactory.getLogger("local-file-cache")
    }

    private func imageFileName(
        _ incidentId: Int64,
        _ worksiteId: Int64,
        _ millis: Int64,
        _ index: Int = 0
    ) -> String
    {
        "\(incidentId)-\(worksiteId)-\(millis)-\(index).jpg"
    }

    private func cacheFileUrl(_ fileName: String) throws -> URL {
        if cacheDir == nil {
            cacheDir = try FileManager.default.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }
        return cacheDir!.appendingPathComponent(fileName)
    }

    private func cacheImage(
        _ fileUrl: URL,
        _ image: UIImage
    ) throws -> Bool {
        if let jpegData = image.jpegData(compressionQuality: 0.9),
           let _ = try? jpegData.write(to: fileUrl, options: [.atomic, .completeFileProtection]) {
            return true
        }
        return false
    }

    func cachePicked(
        _ incidentId: Int64,
        _ worksiteId: Int64,
        _ picked: [PhotosPickerItem]
    ) async throws -> [String: String] {
        let timestamp = Date.now
        let millis = Int64(timestamp.timeIntervalSince1970)

        var cachedImages = [String: String]()
        do {
            for (index, item) in picked.enumerated() {
                let fileName = imageFileName(incidentId, worksiteId, millis, index)
                let fileUrl = try cacheFileUrl(fileName)

                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   try cacheImage(fileUrl, image)
                {
                    imageCache.setValue(image, forKey: fileName)
                    cachedImages[fileName] = fileUrl.absoluteString
                }
            }
        }

        return cachedImages
    }

    func cacheImage(
        _ incidentId: Int64,
        _ worksiteId: Int64,
        _ image: UIImage
    ) async throws -> [String: String] {
        let timestamp = Date.now
        let millis = Int64(timestamp.timeIntervalSince1970)

        var cachedImages = [String: String]()
        do {
            let fileName = imageFileName(incidentId, worksiteId, millis)
            let fileUrl = try cacheFileUrl(fileName)

            if try cacheImage(fileUrl, image) {
                imageCache.setValue(image, forKey: fileName)
                cachedImages[fileName] = fileUrl.absoluteString
            }

            return cachedImages
        }
    }

    func getImage(_ imageFileName: String) -> UIImage? {
        do {
            if let cached = imageCache.value(forKey: imageFileName) {
                return cached
            }

            let imagePath = try cacheFileUrl(imageFileName)
            if let image = UIImage(contentsOfFile: imagePath.path()),
               image.size != .zero {
                imageCache.setValue(image, forKey: imageFileName)
            }
        } catch {
            logger.logError(error)
        }
        return nil
    }
}
