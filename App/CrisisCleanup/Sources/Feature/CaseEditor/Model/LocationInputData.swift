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
    @Published private(set) var isLocationAddressFound = false

    var addressSummary: [String] {
        summarizeAddress(
            streetAddress: streetAddress,
            city: city,
            county: county,
            state: state,
            zipCode: zipCode
        )
    }

    @Published var isEditingAddress = false

    @Published private(set) var streetAddressError = ""
    @Published private(set) var cityError = ""
    @Published private(set) var countyError = ""
    @Published private(set) var stateError = ""
    @Published private(set) var zipCodeError = ""

    private var isIncompleteAddress: Bool {
        streetAddress.isBlank ||
        city.isBlank ||
        county.isBlank ||
        state.isBlank ||
        zipCode.isBlank
    }

    private var subscriptions = Set<AnyCancellable>()

    init() {
        let isBlankAddress1 = Publishers.CombineLatest3(
            $streetAddress,
            $city,
            $county
        )
            .map { s0, s1, s2 in s0.isBlank && s1.isBlank && s2.isBlank }
        Publishers.CombineLatest3(
            isBlankAddress1.eraseToAnyPublisher(),
            $state,
            $zipCode
        )
        .map { isBlank, s3, s4 in isBlank && s3.isBlank && s4.isBlank }
        .receive(on: RunLoop.main)
        .assign(to: \.isBlankAddress, on: self)
        .store(in: &subscriptions)

        Publishers.CombineLatest4(
            $wasGeocodeAddressSelected,
            $isEditingAddress,
            $isBlankAddress,
            $isLocationAddressFound
        )
        .map { selected, editing, blank, found in !(selected || editing || found) || blank }
        .receive(on: RunLoop.main)
        .assign(to: \.isSearchSuggested, on: self)
        .store(in: &subscriptions)
    }

    private func summarizeAddress(
        streetAddress: String,
        city: String,
        county: String,
        state: String,
        zipCode: String
    ) -> [String] {
        [
            streetAddress,
            [city, state].combineTrimText(),
            county,
            zipCode,
        ]
            .filter { $0.isNotBlank }
    }

    func load(
        _ worksite: Worksite,
        _ wasAddressSelected: Bool = false
    ) {
        resetValidity()

        coordinates = worksite.coordinates
        if worksite.address.isNotBlank ||
            worksite.city.isNotBlank ||
            worksite.county.isNotBlank ||
            worksite.state.isNotBlank ||
            worksite.postalCode.isNotBlank {
            streetAddress = worksite.address
            city = worksite.city
            county = worksite.county
            state = worksite.state
            zipCode = worksite.postalCode
        }

        wasGeocodeAddressSelected = wasAddressSelected
        if wasAddressSelected {
            isEditingAddress = isIncompleteAddress
        }
    }

    func setSearchedLocationAddress(_ address: LocationAddress) {
        streetAddress = address.address
        city = address.city
        county = address.county
        state = address.state
        zipCode = address.zipCode

        isLocationAddressFound = true
        isEditingAddress = isIncompleteAddress
    }

    func clearAddress() {
        streetAddress = ""
        city = ""
        county = ""
        state = ""
        zipCode = ""
    }

    func resetValidity() {
        streetAddressError = ""
        cityError = ""
        countyError = ""
        stateError = ""
        zipCodeError = ""
    }

    func validate(
        _ t: (String) -> String
    ) -> Bool {
        resetValidity()

        if streetAddress.isBlank {
            streetAddressError = t("caseForm.address_required")
            return false
        }

        if city.isBlank {
            cityError = t("caseForm.city_required")
            return false
        }

        if county.isBlank {
            countyError = t("caseForm.county_required")
            return false
        }

        if state.isBlank {
            stateError = t("caseForm.state_required")
            return false
        }

        if zipCode.isBlank {
            zipCodeError = t("caseForm.postal_code_required")
            return false
        }

        return true
    }

    func updateCase(
        _ worksite: Worksite,
        _ t: (String) -> String
    ) -> Worksite? {
        if !validate(t) {
            return nil
        }

        return worksite.copy {
            $0.latitude = coordinates.latitude
            $0.longitude = coordinates.longitude
            $0.address = streetAddress.trim()
            $0.city = city.trim()
            $0.county = county.trim()
            $0.state = state.trim()
            $0.postalCode = zipCode.trim()
        }
        .copyModifiedFlag(hasWrongLocation) {
            $0.isWrongLocationFlag
        } _: {
            WorksiteFlag.wrongLocation()
        }
    }

    func getInvalidSection(
        _ t: (String) -> String
    ) -> InvalidWorksiteInfo {
        var focusElements = [CaseEditorElement]()
        var translationKeys = [String]()

        if coordinates == zeroCoordinates {
            focusElements.append(.location)
            translationKeys.append("caseForm.no_lat_lon_error")
        }
        if streetAddress.isBlank {
            focusElements.append(.address)
            translationKeys.append("caseForm.address_required")
        }
        if city.isBlank {
            focusElements.append(.city)
            translationKeys.append("caseForm.city_required")
        }
        if county.isBlank {
            focusElements.append(.county)
            translationKeys.append("caseForm.county_required")
        }
        if state.isBlank {
            focusElements.append(.state)
            translationKeys.append("caseForm.state_required")
        }
        if zipCode.isBlank {
            focusElements.append(.zipCode)
            translationKeys.append("caseForm.postal_code_required")
        }

        let message = translationKeys
            .map(t)
            .joined(separator: "\n")
        var focusElement = focusElements.firstOrNil ?? .none
        if message.isNotBlank,
           focusElement != .location,
           isSearchSuggested {
            focusElement = .location
        }
        return InvalidWorksiteInfo(focusElement, message)
    }

    func assumeLocationAddressChanges(_ worksite: Worksite) {
        wasGeocodeAddressSelected = true
        coordinates = worksite.coordinates
        streetAddress = worksite.address
        city = worksite.city
        county = worksite.county
        zipCode = worksite.postalCode
        state = worksite.state

        if isIncompleteAddress {
            isEditingAddress = true
        }
    }
}
