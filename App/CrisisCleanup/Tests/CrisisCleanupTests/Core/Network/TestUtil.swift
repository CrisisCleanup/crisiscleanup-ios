import Foundation

extension Bundle {
    func loadTestResource(_ resourceFileName: String) -> Data {
        let resourcePath = "CrisisCleanup_CrisisCleanupTests.bundle/TestResources/\(resourceFileName).json"
        if let path = self.path(forResource: resourcePath, ofType: nil) {
            return try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        }
        fatalError("Unable to load test resource \(resourceFileName)")
    }

    func loadJson<T: Decodable>(
        _ resourceFileName: String,
        _ type: T.Type
    ) -> T {
        let data = self.loadTestResource(resourceFileName)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(type, from: data)
    }
}
