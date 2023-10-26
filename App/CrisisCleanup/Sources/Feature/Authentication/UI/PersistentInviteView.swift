import SwiftUI

struct PersistentInviteView: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    @ObservedObject var viewModel: PersistentInviteViewModel

    var body: some View {
        Text("Persistent invite")
    }
}
