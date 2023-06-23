import Foundation

class FakeDataLoader {
    private let bundle: Bundle
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
        let fakeData = worksiteShortResults.map { $0.count }
        print("Fake data \(fakeData)")
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
