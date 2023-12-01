import CoreLocation

extension EditableWorksiteProvider {
    func getOutOfBoundsMessage(
        _ coordinates: CLLocationCoordinate2D,
        _ t: (String) -> String
    ) -> String {
        let latLng = LatLng(coordinates.latitude, coordinates.longitude)
        let isInBounds = incidentBounds.containsLocation(latLng)
        return isInBounds ? "" : t("caseForm.case_outside_incident_name")
            .replacingOccurrences(of: "{incident_name}", with: incident.name)
    }
}
