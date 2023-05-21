import SwiftUI
import Combine

protocol MainViewModelProtocol: ObservableObject {

}

class MainViewModel: MainViewModelProtocol {
    let logger: AppLogger

    init(
        logger: AppLogger
    ) {
        self.logger = logger
    }
}
