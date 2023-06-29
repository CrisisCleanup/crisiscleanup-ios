import Foundation

class FakeDataLoader {
    private let bundle: Bundle

    private var worksiteIndex = 0
    private var worksitesData: [[Worksite]] = []

    init() {
        bundle = Bundle(for: FakeDataLoader.self)
    }

    func loadData() {
        let worksiteShortFiles = [
            "SmallTornado",
            "Pandemic",
            "MediumStorm"
        ]
        let worksiteShortResults = worksiteShortFiles.map { fileName in
            bundle.loadFakeDataJson(fileName, NetworkWorksitesShortResult.self)
        }
        var worksiteId = Int64(0)
        worksitesData = worksiteShortResults.map { worksiteShorts in
            return worksiteShorts.results!.map { worksiteShort in
                worksiteId += 1
                return worksiteShort.asExternalModel(worksiteId)
            }
        }
        print("Fake data is loaded")
    }

    func worksites() -> [Worksite] {
        worksitesData.count == 0 ? [] : worksitesData[worksiteIndex % worksitesData.count]
    }

    func cycleWorksites() -> [Worksite] {
        worksiteIndex += 1
        return worksites()
    }
}

private extension Bundle {
    func loadFakeDataJson<T: Decodable>(
        _ resourceFileName: String,
        _ type: T.Type
    ) -> T {
        let resourcePath = "CrisisCleanup_CrisisCleanup.bundle/FakeData/\(resourceFileName).json"
        let data = self.loadJsonResource(resourcePath)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(type, from: data)
    }

    func loadJsonResource(_ resourcePath: String) -> Data {
        if let path = self.path(forResource: resourcePath, ofType: nil) {
            return try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        }
        fatalError("Unable to load test resource \(resourcePath)")
    }

    func loadJson<T: Decodable>(
        _ resourceFileName: String,
        _ type: T.Type
    ) -> T {
        let data = self.loadJsonResource(resourceFileName)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(type, from: data)
    }
}

extension NetworkWorksiteShort {
    fileprivate func asExternalModel(_ id: Int64) -> Worksite {
        let keyWorkType = getNewestKeyWorkType()
        return Worksite(
            id: id,
            address: address,
            autoContactFrequencyT: AutoContactFrequency.never.literal,
            caseNumber: caseNumber,
            city: city,
            county: county,
            createdAt: createdAt,
            email: "",
            favoriteId: favoriteId,
            incidentId: incident,
            keyWorkType: WorkType(
                id: 0,
                createdAt: nil,
                orgClaim: nil,
                nextRecurAt: nil,
                phase: nil,
                recur: nil,
                statusLiteral: keyWorkType?.status ?? "",
                workTypeLiteral: keyWorkType?.workType ?? ""
            ),
            latitude: location.coordinates[0],
            longitude: location.coordinates[1],
            name: name,
            networkId: id,
            phone1: "",
            phone2: "",
            plusCode: "",
            postalCode: postalCode ?? "",
            reportedBy: nil,
            state: state,
            svi: svi == nil ? nil : svi!,
            updatedAt: updatedAt,
            what3Words: nil,
            workTypes: getNewestWorkTypes().map { workType in
                WorkType(
                    id: 0,
                    createdAt: nil,
                    orgClaim: nil,
                    nextRecurAt: nil,
                    phase: nil,
                    recur: nil,
                    statusLiteral: workType.status,
                    workTypeLiteral: workType.workType
                )
            }
        )
    }
}
