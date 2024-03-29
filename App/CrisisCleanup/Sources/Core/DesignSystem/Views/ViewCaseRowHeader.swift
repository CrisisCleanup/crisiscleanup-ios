//  Created by Anthony Aguilar on 7/5/23.

import SwiftUI

struct ViewCaseRowHeader: View {

    var rowNum: Int
    var rowTitle: String

    private let shapeSize = 32.0

    var body: some View {
        HStack {
            Text(rowNum.description)
                .frame(width: shapeSize, height: shapeSize)
                .foregroundColor(Color.black)
                .background(appTheme.colors.attentionBackgroundColor)
                .clipShape(Circle())
                .fontHeader3()
            Text(rowTitle)
                .fontHeader3()
        }
    }
}
