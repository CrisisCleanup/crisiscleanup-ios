import SwiftUI
import CachedAsyncImage

struct ViewImageView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter

        @ObservedObject var viewModel: ViewImageViewModel
    var imageUri: String
    @State private var scale: CGFloat = 1.0
    @State var offset = CGPoint(x: 0, y: 0)
    @State var offsetCache = CGPoint(x: 0, y: 0)
    @State var imgSize: CGSize = CGSizeZero
    @State var screenSize: CGSize = CGSizeZero
    @State var showNavBar: Bool = false

    var body: some View {

        ZStack{
            Color.black.ignoresSafeArea(.all)
                .overlay(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                screenSize = proxy.size
                            }
                    }.ignoresSafeArea(.all)
                )

            VStack {
                CachedAsyncImage(url: URL(string: imageUri)) { phase in
                    if let image = phase.image {
                        VStack
                        {
                            image // Displays the loaded image.
                                .resizable()
                                .scaledToFit()
                                .onTapGesture(count: 2) {
                                    if(scale > 1) {
                                        scale = 1
                                        offset = CGPointZero
                                    } else {
                                        scale = screenSize.height/imgSize.height
                                    }
                                }
                                .onTapGesture(count: 1) {
                                    showNavBar.toggle()
                                }
                                .overlay(
                                    GeometryReader { proxy in
                                        Color.clear
                                            .onAppear {
                                                imgSize = proxy.size
                                            }
                                    }
                                )
                                .scaleEffect(scale)
                                .offset(x: offset.x, y: offset.y)
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in

                                            if(imgSize.height*scale > screenSize.height)
                                            {
                                                let maxYOffset = (imgSize.height*scale - screenSize.height)/2
                                                print(maxYOffset)
                                                let addedYOffset = offsetCache.y + value.translation.height
                                                if(abs(addedYOffset) > maxYOffset) {
                                                    offset.y = addedYOffset > 0 ? maxYOffset : -maxYOffset
                                                } else {
                                                    offset.y = addedYOffset
                                                }
                                            }
                                            let maxXOffset = (imgSize.width*scale - imgSize.width)/2
                                            if(abs(offset.x) <= maxXOffset)
                                            {
                                                let addedXOffset = offsetCache.x + value.translation.width
                                                if(abs(addedXOffset) > maxXOffset) {
                                                    offset.x = addedXOffset > 0 ? maxXOffset : -maxXOffset
                                                } else {
                                                    offset.x = addedXOffset
                                                }
                                            }
                                        }
                                        .onEnded({ value in
                                            offsetCache = offset
                                        })
                                )


                        }
                        .simultaneousGesture(
                            MagnificationGesture()
                                .onChanged { newScale in
                                    if(newScale >= 1)
                                    {
                                        scale = newScale > 5 ? 5: newScale.magnitude
                                    } else if (scale > 1 && newScale < 1) {
                                        if (newScale.magnitude < 1) {
                                            scale = 1 // limits scaling to 1
                                        } else {
                                            scale = newScale.magnitude
                                        }
                                    }
                                }
                        )

                    } else if phase.error != nil {
                        Color.red // Indicates an error.
                    } else {
                        Color.blue // Acts as a placeholder.
                    }
                }
            }


            if(showNavBar) {
                ImageNav()
            }
        }
        .onTapGesture(count: 2) {
            if(scale > 1) {
                scale = 1
                offset = CGPointZero
            } else {
                scale = screenSize.height/imgSize.height
            }
        }
        .onTapGesture(count: 1) {
            showNavBar.toggle()
        }

    }
}

struct ImageNav: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            HStack {
                Button {
                    dismiss.callAsFunction()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title)
                        .foregroundColor(Color.white)
                        .padding(.leading)
                }
                Spacer()

                Button {

                } label: {
                    Image(systemName: "trash.fill")
                        .font(.title)
                        .foregroundColor(Color.white)
                        .padding(.trailing)
                }
            }
            .background(
                LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .top, endPoint: .bottom)
            )
            Spacer()
        }
    }
}
