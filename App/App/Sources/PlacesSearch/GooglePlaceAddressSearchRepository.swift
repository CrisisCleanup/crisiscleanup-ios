import CrisisCleanup
import Foundation
import GooglePlaces
import LRUCache

class GooglePlaceAddressSearchRepository: AddressSearchRepository {
    private lazy var placeClient: GMSPlacesClient = GMSPlacesClient.shared()
    private lazy var geocoder = CLGeocoder()

    private let staleResultDuration = 1.hours

    // TODO: Use configurable maxSize
    private let placeAutocompleteResultCache =
    LRUCache<String, (Date, [GMSAutocompletePrediction])>(countLimit: 30)
    private let addressResultCache =
    LRUCache<String, (Date, [KeyLocationAddress])>(countLimit: 30)

    func clearCache() {
        placeAutocompleteResultCache.removeAllValues()
        addressResultCache.removeAllValues()
    }

    func getAddress(_ coordinates: LatLng) async -> LocationAddress? {
        let location = coordinates.location
        return await withCheckedContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                var placemark: CLPlacemark? = nil
                if let geocodeError = error {
                    // TODO: Report
                    print(geocodeError)
                } else {
                    placemark = placemarks?.first
                }
                continuation.resume(returning: placemark?.asLocationAddress(location.coordinate))
            }
        }
    }

    private var sessionToken: GMSAutocompleteSessionToken? = nil
    func startSearchSession() {
        // Initialize client (on main thread)
        print(placeClient.description)
        sessionToken =  GMSAutocompleteSessionToken.init()
    }

    func searchAddresses(
        _ query: String,
        countryCodes: [String],
        center: LatLng?,
        southwest: LatLng?,
        northeast: LatLng?,
        maxResults: Int
    ) async -> [KeyLocationAddress] {
        let now = Date.now

        if let cached = addressResultCache.value(forKey: query),
           cached.0.addingTimeInterval(staleResultDuration) > now {
            return cached.1
        }

        if let cached = placeAutocompleteResultCache.value(forKey: query) {
            if cached.0.addingTimeInterval(staleResultDuration) > now {
                do {
                    let addresses = try await mapPredictionsToAddress(cached.1)
                    let sorted = addresses.sort(center)
                    addressResultCache.setValue((now, sorted), forKey: query)
                    return sorted
                } catch {
                    if !(error is CancellationError) {
                        // TODO: Report
                    }
                }
            }
        }

        let token = sessionToken ??  GMSAutocompleteSessionToken.init()

        let hasBounds = southwest != nil && northeast != nil
        let bounds = hasBounds
        ? GMSPlaceRectangularLocationOption(
            southwest!.location.coordinate,
            northeast!.location.coordinate)
        : nil
        let filter = GMSAutocompleteFilter()
        filter.locationBias = bounds
        filter.origin = center?.location
        filter.countries = countryCodes
        filter.types = ["address"]

        let placePredictions = await withCheckedContinuation { continuation in
            placeClient.findAutocompletePredictions(
                fromQuery: query,
                filter: filter,
                sessionToken: token,
                callback: { predictions, error in
                    if let predictionError = error {
                        // TODO: Report
                        print("prediction error \(predictionError)")
                    } else {
                        self.placeAutocompleteResultCache.setValue((now, predictions ?? []), forKey: query)
                    }
                    continuation.resume(returning: predictions)
                }
            )
        }

        do {
            try Task.checkCancellation()

            if let predictions = placePredictions {
                let sorted = try await mapPredictionsToAddress(predictions)
                    .sort(center)
                addressResultCache.setValue((now, sorted), forKey: query)
                return sorted
            }
        } catch {
            if !(error is CancellationError) {
                // TODO: Report
            }
        }

        return []
    }

    private func mapPredictionsToAddress(_ predictions: [GMSAutocompletePrediction]) async throws -> [KeyLocationAddress] {
        var keyLocationAddresses = [KeyLocationAddress]()

        for prediction in predictions {
            let placeText = prediction.attributedFullText.string
            let addresses = await withCheckedContinuation { continuation in
                geocoder.geocodeAddressString(placeText) { placemarks, error in
                    if let geocodeError = error {
                        // TODO: Report
                        print(geocodeError)
                    }
                    continuation.resume(returning: placemarks)
                }
            }

            try Task.checkCancellation()

            if let firstAddress = addresses?.filterLatLng().first {
                let coordinates = firstAddress.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
                let keyLocationAddress = firstAddress.asKeyLocationAddress(prediction.placeID, coordinates)
                keyLocationAddresses.append(keyLocationAddress)
            }
        }

        return keyLocationAddresses
    }
}
