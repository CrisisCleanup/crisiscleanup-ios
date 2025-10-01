import Combine
import Foundation

public protocol CasesFiltersDataSource {
    var filters: any Publisher<CasesFilter, Never> { get }

    func updateFilters(_ filters: CasesFilter)
}

fileprivate let jsonDecoder = JsonDecoderFactory().decoder()
fileprivate let jsonEncoder = JsonEncoderFactory().encoder()

class CasesFiltersUserDefaults: CasesFiltersDataSource {
    let filters: any Publisher<CasesFilter, Never>

    private func update(_ preferences: CasesFilter) {
        UserDefaults.standard.casesFilters = preferences
    }

    init() {
        filters = UserDefaults.standard.publisher(for: \.casesFilterData)
            .map { filterData in
                if let data = filterData,
                   let decodedData = try? jsonDecoder.decode(CasesFilter.self, from: data) {
                    return decodedData
                }
                return CasesFilter()
            }
    }

    func updateFilters(_ filters: CasesFilter) {
        UserDefaults.standard.casesFilters = filters
    }
}

fileprivate let CasesFilterKey = "cases_filters"
extension UserDefaults {
    @objc dynamic fileprivate(set) var casesFilterData: Data? {
        get { data(forKey: CasesFilterKey) }
        set { set(newValue, forKey: CasesFilterKey) }
    }

    var casesFilters: CasesFilter {
        get {
            if let data = casesFilterData,
               let filters = try? jsonDecoder.decode(CasesFilter.self, from: data) {
                return filters
            }
            return CasesFilter()
        }
        set {
            if let data = try? jsonEncoder.encode(newValue) {
                casesFilterData = data
            }
        }
    }
}
