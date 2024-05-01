import Foundation
import GRDB

struct PopulatedWorksiteFiles: Equatable, Decodable, FetchableRecord {
    let worksiteRoot: WorksiteRootRecord
    let worksite: WorksiteRecord
    let networkFiles: [NetworkFileInfo]
    let worksiteLocalImages: [WorksiteLocalImageRecord]

    func toCaseImages() -> [CaseImage] {
        let localFileImageLookup = networkFiles
            .compactMap { $0.networkFileLocalImage }
            .associateBy { $0.id }
        let networkImages = networkFiles
            .map { $0.networkFile }
            .filter { localFileImageLookup[$0.id]?.isDeleted != true }
            .filter { $0.fullUrl?.isNotBlank == true }
            .map {
                let rotateDegrees = localFileImageLookup[$0.id]?.rotateDegrees ?? 0
                return $0.asImageModel(rotateDegrees).asCaseImage()
            }

        let localImages = worksiteLocalImages.map { $0.asExternalModel().asCaseImage() }
        var caseImages = localImages.filter { !$0.isAfter }
        caseImages.append(contentsOf: networkImages.filter { !$0.isAfter })
        caseImages.append(contentsOf: localImages.filter { $0.isAfter })
        caseImages.append(contentsOf: networkImages.filter { $0.isAfter })
        return caseImages
    }
}
