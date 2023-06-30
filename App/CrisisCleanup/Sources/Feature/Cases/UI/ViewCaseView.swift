//
//  ViewCaseView.swift
//
//  Created by Anthony Aguilar on 6/30/23.
//

import SwiftUI

struct ViewCaseView: View {

    @State var viewModel: CasesViewModel

    var body: some View {
        VStack {

            // placeholder text
            Text(viewModel.selectedCaseAnnotation.source.debugDescription)

        }
    }
}
