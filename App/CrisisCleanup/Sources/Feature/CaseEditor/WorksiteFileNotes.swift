import Combine

internal func processWorksiteFilesNotes(
    editableWorksite: any Publisher<Worksite, Never>,
    viewState: any Publisher<CaseEditorViewState, Never>
) -> any Publisher<CaseImagesNotes, Never> {
    return Publishers.CombineLatest(
        editableWorksite.eraseToAnyPublisher(),
        viewState.eraseToAnyPublisher()
    )
    .filter { (_, state) in
        return if case .caseData = state {
            true
        } else {
            false
        }
    }
    .map { (worksite, state) in
        let fileImages = worksite.files.map { $0.asCaseImage() }
        var localImages = [CaseImage]()
        if case .caseData(let caseData) = state {
            localImages = caseData.localWorksite?.localImages.map { $0.asCaseImage() } ?? []
        }
        return CaseImagesNotes(
            networkImages: fileImages,
            localImages: localImages,
            notes: worksite.notes
        )
    }
}

extension Publisher<CaseImagesNotes, Never> {
    func organizeBeforeAfterPhotos() -> any Publisher<[ImageCategory: [CaseImage]], Never> {
        map { data in
            let files = data.networkImages
            let localFiles = data.localImages
            let beforeImages = Array([
                localFiles.filter { !$0.isAfter },
                files.filter { !$0.isAfter }
            ].joined())
            let afterImages = Array([
                localFiles.filter { $0.isAfter },
                files.filter { $0.isAfter }
            ].joined())
            return [
                ImageCategory.before: beforeImages,
                ImageCategory.after: afterImages
            ]
        }
    }
}

extension Publisher<[CaseImage], Never> {
    func mapToCategoryLookup() -> any Publisher<[ImageCategory: [CaseImage]], Never> {
        map { images in
            var lookup = [
                ImageCategory.before: [CaseImage](),
                ImageCategory.after: [CaseImage](),
            ]
            for image in images {
                let isBefore = image.tag == ImageCategory.before.literal
                let category = isBefore ? ImageCategory.before : ImageCategory.after
                lookup[category]!.append(image)
            }
            return lookup
        }
    }
}
