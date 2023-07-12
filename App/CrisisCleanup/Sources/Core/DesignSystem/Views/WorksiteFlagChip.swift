//  Created by Anthony Aguilar on 7/11/23.

import SwiftUI

struct WorksiteFlagChip: View {
    @EnvironmentObject var editableView: EditableView
    @Environment(\.translator) var t: KeyAssetTranslator

    private let worksiteFlag: WorksiteFlag
    private let action: () -> Void

    private let flagColorFallback = Color(hex: 0xFF000000)
    private let flagColors = [
        WorksiteFlagType.highPriority: Color(hex: 0xFF367bc3),
        WorksiteFlagType.upsetClient: Color(hex: 0xFF00b3bf),
        WorksiteFlagType.reportAbuse: Color(hex: 0xFFd79425),
        WorksiteFlagType.wrongLocation: Color(hex: 0xFFf77020),
        WorksiteFlagType.wrongIncident: Color(hex: 0xFFc457e7),
    ]

    init(
        _ worksiteFlag: WorksiteFlag,
        _ action: @escaping () -> Void
    ) {
        self.worksiteFlag = worksiteFlag
        self.action = action
    }

    var body: some View {
        if let flagType = worksiteFlag.flagType {
            let isDisabled = editableView.disabled
            Button {
                action()
            } label: {
                if isDisabled {
                    HStack {
                        Image(systemName: "xmark")
                            .bold()
                        Text(t.t(flagType.literal))
                            .bold()
                    }
                    .padding()
                    .background(.gray)
                    .foregroundColor(.white)
                    .cornerRadius(40)
                } else {
                    let backgroundColor = flagColors.keys.contains(flagType) ? flagColors[flagType] : flagColorFallback
                    HStack {
                        Image(systemName: "xmark")
                            .bold()
                        Text(t.t(flagType.literal))
                            .bold()
                    }
                    .padding()
                    .background(backgroundColor)
                    .foregroundColor(.white)
                    .cornerRadius(40)
                }



            }
            .disabled(isDisabled)
        }
    }
}
