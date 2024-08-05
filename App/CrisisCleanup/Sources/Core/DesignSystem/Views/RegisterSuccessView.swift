import SwiftUI

internal struct RegisterSuccessView: View {
    let title: String
    let message: String
    var actionText = ""
    var onAction = {}

    var body: some View {
        Spacer()

        Image(systemName: "checkmark.circle.fill")
            .resizable()
            .frame(width: 64, height: 64)
            .foregroundColor(statusClosedColor)

        Text(title)
            .fontHeader1()
            .padding()
            .accessibilityIdentifier("registerSuccessTitle")

        Text(message)
            .padding(.horizontal)
            .accessibilityIdentifier("registerSuccessText")

        if actionText.isNotBlank {
            // TODO: Scan join QR code and join.
            //       No padding on smallest screen.
            Button(actionText) {
                onAction()
            }
            .stylePrimary()
            .padding()
        }

        Spacer()

        Image("worker_wheelbarrow_world_background", bundle: .module)
            .offset(CGSize(width: 90.0, height: 0.0))

        Spacer()
    }
}

struct RegisterSuccessView_Previews: PreviewProvider {
    struct Preview: View {
        var body: some View {
            RegisterSuccessView(
                title: "A long wrapping title stretching beyond the thin screen",
                message: "An even longer message unfit for single line display so must spill onto the untouched space below."
            )
        }
    }
    static var previews: some View {
        Preview()
    }
}
