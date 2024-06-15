import SwiftUI

struct PhoneCallDialog: View {
    @Environment(\.translator) var t: KeyAssetTranslator

    private let phoneNumbers: [(Int, ParsedPhoneNumber)]
    private let dismissDialog: () -> Void

    init(
        phoneNumbers: [ParsedPhoneNumber],
        dismissDialog: @escaping () -> Void
    ) {
        self.phoneNumbers = phoneNumbers.enumerated()
            .map{ i, v in
                (i, v)
            }
        self.dismissDialog = dismissDialog
    }

    var body: some View {
        AlertDialog(
            title: t.t("workType.phone"),
            positiveActionText: t.t("actions.close"),
            negativeActionText: "",
            dismissDialog: dismissDialog,
            positiveAction: dismissDialog
        ) {
            VStack(alignment: .leading, spacing: appTheme.gridItemSpacing) {
                ForEach(phoneNumbers, id: \.0) { _, parsedNumber in
                    if parsedNumber.parsedNumbers.isNotEmpty {
                        ForEach(parsedNumber.parsedNumbers, id: \.self) { phoneNumber in
                            if let phoneUri = URL(string: "tel:\(phoneNumber)") {
                                Link(phoneNumber, destination: phoneUri)
                                    .listItemModifier()
                            } else {
                                Text(phoneNumber)
                                    .listItemModifier()
                            }
                        }
                    } else {
                        Text(parsedNumber.source)
                            .listItemModifier()
                    }
                }
            }
        }
    }
}
