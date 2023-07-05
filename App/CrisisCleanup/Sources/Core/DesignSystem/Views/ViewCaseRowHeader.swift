//
//  SwiftUIView.swift
//
//  Created by Anthony Aguilar on 7/5/23.
//

import SwiftUI

struct ViewCaseRowHeader: View {

    var rowNum: Int64
    var rowTitle: String

    var body: some View {
        HStack {
            Text(rowNum.description)
                .padding()
                .clipShape(Circle())
                .frame(width:50, height:50)
                .background(Color.yellow)
                .foregroundColor(Color.black)
                .cornerRadius(40)
            Text(rowTitle)

            if(rowNum != 3)
            {
                Spacer()
            }

        }
        .padding(.leading)
    }
}
