// For dev purposes

import SwiftUI

internal struct WorkTypeIconsView: View {
    private let iconImages: [UIImage]

    init(_ iconImages: [UIImage] = []) {
        self.iconImages = iconImages
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]) {
                if iconImages.isEmpty {
                    ForEach(WorkTypeType.allCases) { workTypeType in
                        if let imageName = workTypeIconLookup[workTypeType] {
                            Image(imageName, bundle: .module)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .padding([.vertical], 8)
                        }
                    }
                } else {
                    ForEach(iconImages, id: \.self) { image in
                        Image(uiImage: image)
                    }
                }
            }
        }
        .background(.gray)
    }
}

class WorkTypeIconImageGenerator {
    private static func generateVariants(
        _ statusIndex: Int,
        _ iconProvider: MapCaseIconProvider,
        _ workType: WorkTypeType,
        isFavorite: Bool = false,
        isImportant: Bool = false,
        isFilteredOut: Bool = false,
        isDuplicate: Bool = false,
        isMarkedForDelete: Bool = false,
        isVisited: Bool = false,
        hasPhotos: Bool = false,
    ) -> [UIImage] {
        var images: [UIImage] = []
        var statusIndex = statusIndex
        let statuses = WorkTypeStatus.allCases
        for o in 0..<2 {
            let orgId: Int64? = o > 0 ? 341 : nil
            for i in 0..<2 {
                let status = statuses[statusIndex % statuses.count]
                let statusClaim = WorkTypeStatusClaim.make(status.literal, orgId)
                let image = iconProvider.getIcon(
                    statusClaim,
                    workType,
                    i>0,
                    isFavorite: isFavorite,
                    isImportant: isImportant,
                    isFilteredOut: isFilteredOut,
                    isDuplicate: isDuplicate,
                    isMarkedForDelete: isMarkedForDelete,
                    isVisited: isVisited,
                    hasPhotos: hasPhotos,
                )
                images.append(image ?? UIImage(named: "cases")!)
                statusIndex += 1
            }
        }
        return images
    }

    static func generate(_ iconProvider: MapCaseIconProvider) -> [UIImage] {
        var allImages: [UIImage] = []
        var statusIndex = 0
        for workType in WorkTypeType.allCases {
            let variants = generateVariants(statusIndex, iconProvider, workType)
            statusIndex += variants.count + 1
            allImages = allImages + variants
        }
        for i in 0..<2 {
            let isFavorite = i == 0
            let isImportant = !isFavorite
            let variants = generateVariants(
                statusIndex,
                iconProvider,
                WorkTypeType.animalServices,
                isFavorite: isFavorite,
                isImportant: isImportant
            )
            statusIndex += variants.count
            allImages += variants
        }

        return allImages
    }
}
