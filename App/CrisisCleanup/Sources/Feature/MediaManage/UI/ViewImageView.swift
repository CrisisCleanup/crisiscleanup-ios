import SwiftUI
import CachedAsyncImage

struct ViewImageView: View {
    @Environment(\.translator) var t: KeyAssetTranslator
    @EnvironmentObject var router: NavigationRouter

    @ObservedObject var viewModel: ViewImageViewModel

    var imageUri: String = ""
    @State private var scale: CGFloat = 1.0
    @State var offset = CGPoint(x: 0, y: 0)
    @State var offsetCache = CGPoint(x: 0, y: 0)
    @State var imgSize: CGSize = CGSizeZero
    @State var screenSize: CGSize = CGSizeZero
    @State var showNavBar: Bool = true

    var body: some View {
        ZStack {
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
                            image
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
                        // TODO: Show error
                        Color.red // Indicates an error.
                    } else {
                        // TODO: Show loading
                        Color.blue // Acts as a placeholder.
                    }
                }
                .edgesIgnoringSafeArea(.all)
            }

            if(showNavBar) {
                ImageNav(
                    deleteImage: { viewModel.deleteImage() }
                )
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
            // TODO: Animate
            showNavBar.toggle()
        }
    }
}

struct ImageNav: View {
    @Environment(\.dismiss) var dismiss

    let deleteImage: () -> Void

    var body: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.white)
                }

                Spacer()

                Button {
                    deleteImage()
                } label: {
                    Image(systemName: "trash.fill")
                        .foregroundColor(Color.white)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.5), .black.opacity(0.0)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            Spacer()
        }
    }
}
