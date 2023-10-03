import SwiftUI

struct VolunteerOrgView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: VolunteerOrgViewModel

    var body: some View {
        ScrollView {
            VStack {
                Text("Volunteer")
            }
        }
        .navigationTitle(t.t("~~Signup"))
        .onAppear { viewModel.onViewAppear() }
        .onDisappear { viewModel.onViewDisappear() }
    }
}
