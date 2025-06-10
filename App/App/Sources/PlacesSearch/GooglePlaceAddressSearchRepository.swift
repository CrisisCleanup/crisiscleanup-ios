import CrisisCleanup
import Foundation
import GooglePlaces
import LRUCache

class GooglePlaceAddressSearchRepository: AddressSearchRepository {
    private lazy var placeClient: GMSPlacesClient = GMSPlacesClient.shared()
    private lazy var geocoder = CLGeocoder()

    private let logger: AppLogger

    private let staleResultDuration = 1.hours

    // TODO: Use configurable maxSize
    private let placeAutocompleteResultCache =
    LRUCache<String, (Date, [GMSAutocompletePrediction])>(countLimit: 30)

    init(
        loggerFactory: AppLoggerFactory
    ) {
        logger = loggerFactory.getLogger("search")
    }

    func clearCache() {
        placeAutocompleteResultCache.removeAllValues()
    }

    func getAddress(_ coordinates: LatLng) async -> LocationAddress? {
        let location = coordinates.location
        return await withCheckedContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                var placemark: CLPlacemark? = nil
                if let geocodeError = error {
                    self.logger.logError(geocodeError)
                } else {
                    placemark = placemarks?.first
                }
                let locationAddress = placemark?.asLocationAddress(location.coordinate)
                continuation.resume(returning: locationAddress)
            }
        }
    }

    private var sessionToken: GMSAutocompleteSessionToken? = nil
    func startSearchSession() {
        // Initialize client (on main thread)
        sessionToken =  GMSAutocompleteSessionToken.init()
    }

    @MainActor func searchAddresses(
        _ query: String,
        countryCodes: [String],
        center: LatLng?,
        southwest: LatLng?,
        northeast: LatLng?,
        maxResults: Int
    ) async -> [KeySearchAddress] {
        let now = Date.now

        if let cached = placeAutocompleteResultCache.value(forKey: query) {
            if cached.0.addingTimeInterval(staleResultDuration) > now {
                return mapPredictionsToAddress(cached.1)
            }
        }

        let token = sessionToken ??  GMSAutocompleteSessionToken.init()

        let hasBounds = southwest != nil && northeast != nil
        let bounds = hasBounds
        ? GMSPlaceRectangularLocationOption(
            northeast!.location.coordinate,
            southwest!.location.coordinate
        )
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
                        self.logger.logError(predictionError)
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
                return mapPredictionsToAddress(predictions)
            }
        } catch {
            if !(error is CancellationError) {
                // TODO: Report
            }
        }

        return []
    }

    private func mapPredictionsToAddress(_ predictions: [GMSAutocompletePrediction]) -> [KeySearchAddress] {
        predictions.map {
            return KeySearchAddress(
                key: $0.placeID,
                addressLine1: $0.attributedPrimaryText.string,
                addressLine2: $0.attributedSecondaryText?.string ?? "",
                fullAddress: $0.attributedFullText.string
            )
        }
    }

    private func getGeocoderCoordinates(_ placeText: String) async throws -> CLLocationCoordinate2D? {
        let addresses = await withCheckedContinuation { continuation in
            geocoder.geocodeAddressString(placeText) { placemarks, error in
                if let geocodeError = error {
                    self.logger.logError(geocodeError)
                }
                continuation.resume(returning: placemarks)
            }
        }

        try Task.checkCancellation()

        return addresses?.compactMap { $0.location }.first?.coordinate
    }

    func getPlaceAddress(_ placeId: String) async throws -> LocationAddress? {
        if let place = await withCheckedContinuation({ continuation in
            let placeRequest = GMSFetchPlaceRequest(
                placeID: placeId,
                placeProperties: [
                    GMSPlaceProperty.name,
                    GMSPlaceProperty.coordinate,
                    GMSPlaceProperty.addressComponents,
                    GMSPlaceProperty.placeID
                ].map { $0.rawValue },
                sessionToken: sessionToken
            )
            placeClient.fetchPlace(with: placeRequest) { place, error in
                if let error = error {
                    self.logger.logError(error)
                }
                continuation.resume(returning: place)
            }
        }) {
            let coordinates = place.coordinate
            let addressTypeKeys = Set([
                "street_number",
                "route",
                "subpremise",
                "locality",
                "administrative_area_level_2",
                "administrative_area_level_1",
                "country",
                "postal_code",
            ])
            var addressComponentLookup = [String: String]()
            place.addressComponents?.forEach {
                for t in $0.types {
                    if addressTypeKeys.contains(t) {
                        addressComponentLookup[t] = $0.name
                    }
                }
            }

            startSearchSession()

            return LocationAddress(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude,
                address: [
                    addressComponentLookup["street_number"],
                    addressComponentLookup["route"],
                    addressComponentLookup["subpremise"],
                ].combineTrimText(),
                city: addressComponentLookup["locality"] ?? "",
                county: addressComponentLookup["administrative_area_level_2"] ?? "",
                state: addressComponentLookup["administrative_area_level_1"] ?? "",
                country: addressComponentLookup["country"] ?? "",
                zipCode: addressComponentLookup["postal_code"] ?? ""
            )
        }

        return nil
    }
}
