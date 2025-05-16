import Foundation
import SwiftUI

struct IncidentWorksitesCacheView: View {
    @ObservedObject var viewModel: IncidentWorksitesCacheViewModel

    var body: some View {
        ZStack {
            Text("Incident caching")
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
        .environmentObject(viewModel)
    }
}
