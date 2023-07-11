//  Created by Anthony Aguilar on 7/5/23.

import SwiftUI


struct WorkTypeRow: View {
    @Binding var showPicker: Bool

    var workType: WorkType

    var body: some View {
        ZStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text(workType.workTypeLiteral)

                        HStack {

                            HStack {
                                Text("closed, completed")
                                Spacer()
                                Image(systemName: "circle.fill")
                                    .foregroundColor(Color.blue)
                            }
                            .padding()
                            .background(Color.white)
                            .onTapGesture {
                                showPicker.toggle()
                            }

                            Spacer()

                            if(workType.statusClaim.isClaimed)
                            {
                                Text("Request")
                                    .lineLimit(1)
                                    .padding()
                                    .background(Color.white)
                                    .border(.black, width: 2)
                                    .cornerRadius(appTheme.cornerRadius)
                            } else if workType.isReleaseEligible {
                                Text("Release")
                                    .lineLimit(1)
                                    .padding()
                                    .background(Color.white)
                                    .border(.black, width: 2)
                                    .cornerRadius(appTheme.cornerRadius)
                            } else {
                                Text("Claim")
                                    .lineLimit(1)
                                    .padding()
                                    .background(appTheme.colors.attentionBackgroundColor)
                                    .cornerRadius(appTheme.cornerRadius)
                            }

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
}
