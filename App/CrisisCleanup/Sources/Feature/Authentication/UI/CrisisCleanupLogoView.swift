import SwiftUI

internal struct CrisisCleanupLogoView: View {
    var body: some View {
        HStack {
            Image("crisis_cleanup_logo", bundle: .module)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 180)
                .overlay {
                    Image("worker_wheelbarrow_world_background", bundle: .module)
                        .padding(.leading, 360)
                        .padding(.top, 176)
                }
                .padding(.top, 32)
                .padding(.bottom, 128)
                .padding(.leading, 24)
            Spacer()
        }
    }
}
