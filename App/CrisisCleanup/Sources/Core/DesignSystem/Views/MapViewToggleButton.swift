import SwiftUI

struct MapViewToggleButton: View {
    var isMapSatelliteView: Bool
    var onToggle: () -> Void

    var body: some View {
        let buttonIconName = isMapSatelliteView ? "map.fill" : "mountain.2.fill"
        Button {
            onToggle()
        } label: {
            Image(systemName: buttonIconName)
                .resizable()
                .scaledToFit()
            // TODO: Common dimensions
                .padding(12)
                .frame(width: 48, height: 48)
                .background(.white.disabledAlpha())
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        // TODO: Common dimensions
        .padding(8)
    }
}
