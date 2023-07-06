//
//  SwiftUIView.swift
//
//  Created by Anthony Aguilar on 7/5/23.
//

import SwiftUI

struct WorkTypeRow: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Tree work")
                HStack {
                    Circle()
                        .foregroundColor(Color.green)
                        .frame(width: 25, height: 25)
                    Text("Closed, completed")
                    Spacer()

                    Text("Release")
                        .lineLimit(1)
                        .padding()
                        .background(Color.white)
                        .border(.black, width: 2)
                        .cornerRadius(appTheme.cornerRadius)


                }

            }
            .padding()
            .background(Color.white)
            .cornerRadius(appTheme.cornerRadius)
            .shadow(radius: 2)
            .padding()
        }
    }
}
