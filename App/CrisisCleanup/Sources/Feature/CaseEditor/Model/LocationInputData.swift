import Combine
import Foundation

private let zeroCoordinates = LatLng(0.0, 0.0)

class LocationInputData: ObservableObject {
    @Published var coordinates = zeroCoordinates
    @Published var streetAddress = ""
    @Published var zipCode = ""
    @Published var city = ""
    @Published var county = ""
    @Published var state = ""
    @Published var hasWrongLocation = false
    @Published var crossStreetNearbyLandmark = ""

    @Published private(set) var isBlankAddress = false
    @Published private(set) var wasGeocodeAddressSelected = false
    @Published private(set) var isSearchSuggested = false

    var addressSummary: [String] {
        summarizeAddress(
            streetAddress,
            zipCode,
            county,
            city,
            state
        )
    }

    @Published var isEditingAddress = false

    @Published private(set) var streetAddressError = ""
    @Published private(set) var zipCodeError = ""
    @Published private(set) var cityError = ""
    @Published private(set) var countyError = ""
    @Published private(set) var stateError = ""

    private var isIncompleteAddress: Bool {
        streetAddress.isBlank ||
        zipCode.isBlank ||
        city.isBlank ||
        county.isBlank ||
        state.isBlank
    }

    private var subscriptions = Set<AnyCancellable>()

    init() {
        let isBlankAddress1 = Publishers.CombineLatest3(
            $streetAddress,
            $zipCode,
            $city
        )
            .map { s0, s1, s2 in s0.isBlank && s1.isBlank && s2.isBlank }
        Publishers.CombineLatest3(
            isBlankAddress1.eraseToAnyPublisher(),
            $county,
            $state
        )
        .map { isBlank, s3, s4 in isBlank && s3.isBlank && s4.isBlank }
        .receive(on: RunLoop.main)
        .assign(to: \.isBlankAddress, on: self)
        .store(in: &subscriptions)

        Publishers.CombineLatest3(
            $wasGeocodeAddressSelected,
            $isEditingAddress,
            $isBlankAddress
        )
        .map { selected, editing, blank in !(selected || editing) || blank }
        .receive(on: RunLoop.main)
        .assign(to: \.isSearchSuggested, on: self)
        .store(in: &subscriptions)
    }

    private func summarizeAddress(
        _ streetAddress: String,
        _ zipCode: String,
        _ county: String,
        _ city: String,
        _ state: String
    ) -> [String] {
        [
            streetAddress,
            [city, state].combineTrimText(),
            county,
            zipCode,
        ]
            .filter { $0.isNotBlank }
    }

    func load(_ worksite: Worksite) {
        coordinates = worksite.coordinates
        streetAddress = worksite.address
        zipCode = worksite.postalCode
        city = worksite.city
        county = worksite.county
        state = worksite.state
    }

    func clearAddress() {
        streetAddress = ""
        city = ""
        zipCode = ""
        county = ""
        state = ""
    }

    func resetValidity() {
        streetAddressError = ""
        zipCodeError = ""
        cityError = ""
        countyError = ""
        stateError = ""
    }

    func validate(
        _ t: (String) -> String
    ) -> Bool {
        resetValidity()

        if streetAddress.isBlank {
            streetAddressError = t("caseForm.address_required")
            return false
        }
        if zipCode.isBlank {
            zipCodeError = t("caseForm.postal_code_required")
            return false
        }
        if county.isNotBlank {
            countyError = t("caseForm.county_required")
            return false
        }

        if city.isNotBlank {
            cityError = t("caseForm.city_required")
            return false
        }

        if state.isNotBlank {
            stateError = t("caseForm.state_required")
            return false
        }

        return true
    }

    func getUserErrorMessage(
        _ t: (String) -> String
) -> (Bool, String) {
        var translationKeys = [String]()
        var isAddressError = true

        if coordinates == zeroCoordinates {
            isAddressError = false
            translationKeys.append("caseForm.no_lat_lon_error")
        }
        if streetAddress.isBlank {
            translationKeys.append("caseForm.address_required")
        }
        if zipCode.isBlank {
            translationKeys.append("caseForm.postal_code_required")
        }
        if county.isBlank {
            translationKeys.append("caseForm.county_required")
        }
        if city.isBlank {
            translationKeys.append("caseForm.city_required")
        }
        if state.isBlank {
            translationKeys.append("caseForm.state_required")
        }

        let message = translationKeys
            .map { t($0) }
            .joined(separator: "\n")
        return (isAddressError, message)
    }
}
