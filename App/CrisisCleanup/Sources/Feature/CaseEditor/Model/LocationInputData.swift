import Combine

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

    @Published var streetAddressError = ""
    @Published var zipCodeError = ""
    @Published var cityError = ""
    @Published var countyError = ""
    @Published var stateError = ""

    private var isIncompleteAddress: Bool {
        streetAddress.isBlank ||
        zipCode.isBlank ||
        city.isBlank ||
        county.isBlank ||
        state.isBlank
    }

    private var isBlankAddress: Bool {
        streetAddress.isBlank &&
        zipCode.isBlank &&
        city.isBlank &&
        county.isBlank &&
        state.isBlank
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
