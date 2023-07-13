import MapKit
import SwiftUI

struct CaseMoveOnMapView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: CaseMoveOnMapViewModel

    @State var map = MKMapView()
    // TODO: Read initial coordinates from view model
    @State var caseCoordinates = CLLocationCoordinate2D(
        latitude: -81.0,
        longitude: 24.0
    )
    @State var temp = ""

    var body: some View {
        VStack {
            TextField(t.t("caseView.full_address"), text: $temp)
                .textFieldBorder()
                .padding(.horizontal)

            CreateEditCaseMapView(
                map: $map,
                caseCoordinates: caseCoordinates,
                toggled: true
            )

            Button {
                map.showsUserLocation = true
                map.userTrackingMode
                map.centerCoordinate = map.userLocation.coordinate
            } label: {
                Image(systemName: "location.circle")
                Text(t.t("caseForm.use_my_location"))
            }

            Text(map.centerCoordinate.latLng.description)

            Text(caseCoordinates.latLng.description)

            HStack{
                Button {
                    dismiss()
                } label: {
                    Text(t.t("actions.cancel"))
                }.buttonStyle(PrimaryButtonStyle())

                Button {
                    caseCoordinates = map.centerCoordinate
                } label: {
                    Text(t.t("actions.save"))
                }.buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal)

        }
    }
}
