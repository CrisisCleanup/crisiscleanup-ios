//  Created by Anthony Aguilar on 6/30/23.

import SwiftUI

struct ViewCaseView: View {
    @Environment(\.isPresented) var isPresented

    @State var viewModel: ViewCaseViewModel

    var body: some View {
        ZStack {
            VStack {
                // placeholder text
                Text("Incident \(viewModel.incidentIdIn) Worksite \(viewModel.worksiteIdIn)")
            }
        }
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}
