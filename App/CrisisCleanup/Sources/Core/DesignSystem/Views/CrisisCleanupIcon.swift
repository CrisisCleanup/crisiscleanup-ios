import SwiftUI

struct DropDownIcon: View {
    var body: some View {
        Image(systemName: "arrowtriangle.down.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 10, height: 8)
    }
}
