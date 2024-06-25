import Foundation
@testable import CrisisCleanup

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

private let dateFormatter = ISO8601DateFormatter()
internal func fillNetworkIncident(
    _ id: Int64,
    _ startAt: String,
    _ name: String,
    _ shortName: String,
    _ caseLabel: String,
    _ incidentType: String,
    _ locations: [NetworkIncidentLocation],
    activePhone: [String]? = nil,
    turnOnRelease: Bool = false,
    isArchived: Bool = false,
    fields: [NetworkIncidentFormField]? = nil
) -> NetworkIncident {
    return NetworkIncident(
        id: id,
        startAt: dateFormatter.date(from: startAt)!,
        name: name,
        shortName: shortName,
        caseLabel: caseLabel,
        locations: locations,
        type: incidentType,
        activePhoneNumber: activePhone,
        turnOnRelease: turnOnRelease,
        isArchived: isArchived,
        fields: fields
    )
}
