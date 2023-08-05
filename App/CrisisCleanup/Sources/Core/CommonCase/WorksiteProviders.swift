import Combine

public protocol WorksiteProvider {
    var editableWorksite: CurrentValueSubject<Worksite, Never> { get }
    var workTypeTranslationLookup: [String: String] { get set }

    func translate(_ key: String) -> String?
}

extension WorksiteProvider {
    func reset(_ incidentId: Int64) {
        editableWorksite.value = EmptyWorksite.copy {
            $0.incidentId = incidentId
        }
    }
}
