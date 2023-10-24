import SwiftUI
import CoreImage.CIFilterBuiltins

public protocol QrCodeGenerator {
    func generate(_ payload: String) -> UIImage?
}

class CoreImageQrCodeGenerator: QrCodeGenerator {
    func generate(_ payload: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)

        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }

        return nil
    }
}
