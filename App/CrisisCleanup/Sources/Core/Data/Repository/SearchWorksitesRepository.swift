import Foundation
import LRUCache

public protocol SearchWorksitesRepository {
    func searchWorksites(
        _ incidentId: Int64,
        _ q: String
    ) async -> [WorksiteSummary]

    func locationSearchWorksites(
        _ incidentId: Int64,
        _ q: String
    ) async -> [WorksiteSummary]

    func getMatchingLocalWorksites(
        _ incidentId: Int64,
        _ q: String
    ) -> [WorksiteSummary]

    func getWorksiteByCaseNumber(
        _ incidentId: Int64,
        _ caseNumber: String
    ) -> WorksiteSummary?

    func getWorksiteByTrailingCaseNumber(
        _ incidentId: Int64,
        _ caseNumber: String
    ) -> WorksiteSummary?
}

class MemorySearchWorksitesRepository: SearchWorksitesRepository {
    private let networkDataSource: CrisisCleanupNetworkDataSource
    private let worksiteDao: WorksiteDao
    private let logger: AppLogger

    init(
        _ networkDataSource: CrisisCleanupNetworkDataSource,
        _ worksiteDao: WorksiteDao,
        _ loggerFactory: AppLoggerFactory
    ) {
        self.networkDataSource = networkDataSource
        self.worksiteDao = worksiteDao
        logger = loggerFactory.getLogger("search-source")
    }

    private let searchCache =
    LRUCache<IncidentQuery, (Date, [WorksiteSummary])>(countLimit: 30)

    private let staleResultDuration = 30.minutes

    private func getCacheResults(
        _ incidentId: Int64,
        _ q: String
    ) -> (IncidentQuery, Date, [WorksiteSummary]?) {
        let incidentQuery = IncidentQuery(incidentId, q)

        let now = Date.now

        // TODO: Search local on device data. Will need to change the method of data delivery.

        var cacheResults: [WorksiteSummary]? = nil
        if let cached = searchCache.value(forKey: incidentQuery),
           cached.0.addingTimeInterval(staleResultDuration) > now {
            cacheResults = cached.1
        }

        return (incidentQuery, now, cacheResults)
    }

    func searchWorksites(
        _ incidentId: Int64,
        _ q: String
    ) async -> [WorksiteSummary] {
        let (incidentQuery, now, cacheResults) = getCacheResults(incidentId, q)
        if let cached = cacheResults {
            return cached
        }

        do {
            let results = try await networkDataSource.getSearchWorksites(incidentId, q)
            if results.isNotEmpty {
                let searchResult = results.map { networkWorksite in
                    var workType: WorkType? = nil
                    if let keyWorkType = networkWorksite.newestKeyWorkType {            workType = WorkType(
                            id: 0,
                            statusLiteral: keyWorkType.status,
                            workTypeLiteral: keyWorkType.workType
                        )
                    }
                    return WorksiteSummary(
                        id: 0,
                        networkId: networkWorksite.id,
                        name: networkWorksite.name,
                        address: networkWorksite.address,
                        city: networkWorksite.city,
                        state: networkWorksite.state,
                        zipCode: networkWorksite.postalCode ?? "",
                        county: networkWorksite.county,
                        caseNumber: networkWorksite.caseNumber,
                        workType: workType
                    )
                }
                searchCache.setValue((now, searchResult), forKey: incidentQuery)
                return searchResult
            }
        } catch {
            logger.logError(error)
        }

        return []
    }

    func locationSearchWorksites(
        _ incidentId: Int64,
        _ q: String
    ) async -> [WorksiteSummary] {
        let (incidentQuery, now, cacheResults) = getCacheResults(incidentId, q)
        if let cached = cacheResults {
            return cached
        }

        // TODO: Search local as well

        do {
            let results = try await networkDataSource.getLocationSearchWorksites(incidentId, q, 5)
            if results.isNotEmpty {
                let searchResult = results.map { networkWorksite in
                    let workType: WorkType?
                    let keyWorkType = networkWorksite.keyWorkType
                    workType = WorkType(
                        id: 0,
                        statusLiteral: keyWorkType.status,
                        workTypeLiteral: keyWorkType.workType
                    )
                    return WorksiteSummary(
                        id: 0,
                        networkId: networkWorksite.id,
                        name: networkWorksite.name,
                        address: networkWorksite.address,
                        city: networkWorksite.city,
                        state: networkWorksite.state,
                        zipCode: networkWorksite.postalCode ?? "",
                        county: networkWorksite.county,
                        caseNumber: networkWorksite.caseNumber,
                        workType: workType
                    )
                }

                searchCache.setValue((now, searchResult), forKey: incidentQuery)
                return searchResult
            }
        } catch {
            logger.logError(error)
        }

        return []
    }

    func getMatchingLocalWorksites(_ incidentId: Int64, _ q: String) -> [WorksiteSummary] {
        worksiteDao.getMatchingWorksites(incidentId, q)
    }

    func getWorksiteByCaseNumber(_ incidentId: Int64, _ caseNumber: String) -> WorksiteSummary? {
        guard caseNumber.isNotBlank else {
            return nil
        }

        return worksiteDao.getWorksiteByCaseNumber(incidentId, caseNumber)
    }

    func getWorksiteByTrailingCaseNumber(_ incidentId: Int64, _ number: String) -> WorksiteSummary? {
        guard number.isNotBlank else {
            return nil
        }

        return worksiteDao.getWorksiteByTrailingCaseNumber(incidentId, number)
    }
}

fileprivate struct IncidentQuery: Hashable {
    let incidentId: Int64
    let q: String

    init(_ incidentId: Int64, _ q: String) {
        self.incidentId = incidentId
        self.q = q
    }
}
