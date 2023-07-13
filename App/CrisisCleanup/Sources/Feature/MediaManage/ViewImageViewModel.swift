import Combine
import Foundation
import SwiftUI

class ViewImageViewModel: ObservableObject {
    private let imageId: Int64

    init(
        imageId: Int64
    ) {
        self.imageId = imageId
    }
}
