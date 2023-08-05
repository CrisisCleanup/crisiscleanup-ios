import Combine

class SingleWorksiteProvider: WorksiteProvider {
    let editableWorksite = CurrentValueSubject<Worksite, Never>(EmptyWorksite)
    var workTypeTranslationLookup = [String: String]()

    func translate(_ key: String) -> String? {
        workTypeTranslationLookup[key]
    }
}
