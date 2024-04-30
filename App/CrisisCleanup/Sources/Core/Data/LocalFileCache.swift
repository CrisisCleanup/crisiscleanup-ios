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

    func deleteFile(
        _ fileName: String
    )

    func deleteUnspecifiedFiles(
        _ fileNames: Set<String>
    )
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
    ) -> String {
        "\(incidentId)-\(worksiteId)-\(millis)-\(index).jpg"
    }

    private func getCacheDir() throws -> URL {
        if cacheDir == nil {
            let fileManager = FileManager.default
            cacheDir = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            .appending(path: "upload-files-cache")

            try fileManager.createDirectory(at: cacheDir!, withIntermediateDirectories: true)
        }
        return cacheDir!
    }

    private func cacheFileUrl(_ fileName: String) throws -> URL {
        try getCacheDir().resolvingSymlinksInPath().appendingPathComponent(fileName)
    }

    private func cacheImage(
        _ fileUrl: URL,
        _ image: UIImage
    ) throws -> Bool {
        if let jpegData = image.jpegData(compressionQuality: 1.0),
           let _ = try? jpegData.write(to: fileUrl, options: [.atomic, .completeFileProtection]) {
            return true
        }
        return false
    }

    private var nowMillis: Int64 { Int64(Date.now.timeIntervalSince1970 * 1000) }

    func cachePicked(
        _ incidentId: Int64,
        _ worksiteId: Int64,
        _ picked: [PhotosPickerItem]
    ) async throws -> [String: String] {
        let millis = nowMillis

        var cachedImages = [String: String]()
        do {
            for (index, item) in picked.enumerated() {
                let fileName = imageFileName(incidentId, worksiteId, millis, index)
                let fileUrl = try cacheFileUrl(fileName)

                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   try cacheImage(fileUrl, image)
                {
                    let imageId = item.itemIdentifier ?? fileName
                    imageCache.setValue(image, forKey: imageId)
                    cachedImages[imageId] = fileUrl.path()
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
        let millis = nowMillis

        var cachedImages = [String: String]()
        do {
            let fileName = imageFileName(incidentId, worksiteId, millis)
            let fileUrl = try cacheFileUrl(fileName)

            if try cacheImage(fileUrl, image) {
                imageCache.setValue(image, forKey: fileName)
                cachedImages[fileName] = fileUrl.path()
            }

            return cachedImages
        }
    }

    func getImage(_ imageFileName: String) -> UIImage? {
        do {
            if let cached = imageCache.value(forKey: imageFileName) {
                return cached
            }

            let imagePath = try cacheFileUrl(imageFileName).path(percentEncoded: false)
            if let image = UIImage(contentsOfFile: imagePath),
               image.size != .zero {
                imageCache.setValue(image, forKey: imageFileName)
                return image
            }
        } catch {
            logger.logError(error)
        }
        return nil
    }

    func deleteFile(_ fileName: String) {
        do {
            imageCache.removeValue(forKey: fileName)

            let fileUrl = try cacheFileUrl(fileName)
            try FileManager.default.removeItem(at: fileUrl)
        } catch {
            logger.logError(error)
        }
    }

    func deleteUnspecifiedFiles(_ fileNames: Set<String>) {
        // TODO: Review and update when non-image files are supported. Write tests.

        do {
            if fileNames.isEmpty {
                let fileManager = FileManager.default
                let files = try fileManager.contentsOfDirectory(at: getCacheDir(), includingPropertiesForKeys: nil)

                for file in files {
                    imageCache.removeValue(forKey: file.lastPathComponent)
                    try fileManager.removeItem(at: file)
                }
            } else {
                logger.logDebug("Not deleting cached files when there are pending files.")
            }
        } catch {
            logger.logError(error)
        }
    }
}
