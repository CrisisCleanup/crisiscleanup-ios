import XCTest
@testable import CrisisCleanup

final class FloatStringOptionalTests: XCTestCase {
    private let jsonDecoder = JsonDecoderFactory().decoder()
    private let jsonEncoder = JsonEncoderFactory().encoder()

    // This case would be defer to the containing model
    func optionalCoding() throws {
        let sviContent = #"{"s":"s","n":51}"#
        let sviData = Data(sviContent.utf8)
        let svi = try? jsonDecoder.decode(OnlySvi.self, from: sviData)
        XCTAssertEqual(OnlySvi(), svi)
    }

    func testNullCoding() throws {
        let sviContent = #"{"s":"s","n":51,"svi":null}"#
        let sviData = Data(sviContent.utf8)
        let svi = try? jsonDecoder.decode(OnlySvi.self, from: sviData)
        XCTAssertEqual(OnlySvi(), svi)

        // let sviJsonData = try! jsonEncoder.encode(svi)
        // let sviJsonContent = String(decoding: sviJsonData, as: UTF8.self)
        // Object property ordering is not guaranteed
        // XCTAssertTrue(sviContent == sviJsonContent)

        let decodedSviData = Data(sviContent.utf8)
        let decodedSvi = try? jsonDecoder.decode(OnlySvi.self, from: decodedSviData)
        XCTAssertEqual(OnlySvi(), decodedSvi)
    }

    func testValueCoding() throws {
        let sviContent = #"{"s":"s","n":51,"svi":0.124}"#
        let sviData = Data(sviContent.utf8)
        let svi = try? jsonDecoder.decode(OnlySvi.self, from: sviData)
        XCTAssertEqual(OnlySvi(svi: 0.124), svi)

        let sviJsonData = try! jsonEncoder.encode(svi)
        let sviJsonContent = String(decoding: sviJsonData, as: UTF8.self)

        let decodedSviData = Data(sviJsonContent.utf8)
        let decodedSvi = try? jsonDecoder.decode(OnlySvi.self, from: decodedSviData)
        XCTAssertEqual(OnlySvi(svi: 0.124), decodedSvi)
    }
}

struct OnlySvi: Codable, Equatable {
    let s: String
    let n: Int
    @FloatStringOptional
    var svi: Float?

    init(
        s: String = "s",
        n: Int = 51,
        svi: Float? = nil
    ) {
        self.s = s
        self.n = n
        _svi = FloatStringOptional(value: svi)
    }
}
