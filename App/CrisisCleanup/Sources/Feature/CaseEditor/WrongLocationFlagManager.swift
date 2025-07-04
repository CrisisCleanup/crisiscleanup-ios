import Combine
import Foundation

class WrongLocationFlagManager {
    private let addressSearchRepository: AddressSearchRepository

    let isProcessingLocation: any Publisher<Bool, Never>

    let wrongLocationText = CurrentValueSubject<String, Never>("")

    let validCoordinates: any Publisher<LocationAddress?, Never>

    init(
        _ addressSearchRepository: AddressSearchRepository,
        _ logger: AppLogger
    ) {
        self.addressSearchRepository = addressSearchRepository

        let isParsingCoordinates = CurrentValueSubject<Bool, Never>(false)
        let isVerifyingCoordinates = CurrentValueSubject<Bool, Never>(false)

        isProcessingLocation = Publishers.CombineLatest(
            isParsingCoordinates.eraseToAnyPublisher(),
            isVerifyingCoordinates.eraseToAnyPublisher()
        )
        .map { (b0, b1) in b0 || b1 }

        let coordinatesRegex = #/(-?\d{1,2}(?:\.\d+)?),\s*(-?\d{1,3}(?:\.\d+)?)\b/#
        let wrongLocationCoordinatesParse = wrongLocationText
            .throttle(
                for: .seconds(0.15),
                scheduler: RunLoop.current,
                latest: true
            )
            .map { s in
                var latLng: LatLng? = nil

                isParsingCoordinates.value = true
                do {
                    defer { isParsingCoordinates.value = false }

                    if let match = try? coordinatesRegex.wholeMatch(in: s) {
                        let latitudeS = match.output.1
                        let longitudeS = match.output.2
                        if let latitude = Double(latitudeS),
                           let longitude = Double(longitudeS),
                           abs(latitude) <= 90.0,
                           abs(longitude) < 180.0
                        {
                            latLng = LatLng(latitude, longitude)
                        }
                    }
                }
                return latLng
            }
            .eraseToAnyPublisher()

        validCoordinates = wrongLocationCoordinatesParse.asyncMap {
            if let latLng = $0 {
                isVerifyingCoordinates.value = true
                do {
                    defer { isVerifyingCoordinates.value = false }

                    return await addressSearchRepository.getAddress(latLng)
                }
            }

            return nil
        }
    }
}
