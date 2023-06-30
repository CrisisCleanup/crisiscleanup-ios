import CoreImage
import Foundation
import SwiftUI

class LerpGrayscaleToColor: CIFilter {
    var inputImage: CIImage?
    var zeroColorInt: Int64 = 0
    var oneColorInt: Int64 = -1

    static var kernel: CIKernel = { () -> CIColorKernel in
        guard let url = Bundle.main.url(
            forResource: "LerpGrayscaleToColorKernel.ci",
            withExtension: "metallib"
        ),
              let data = try? Data(contentsOf: url)
        else {
            fatalError("Unable to load metallib")
        }

        guard let kernel = try? CIColorKernel(
            functionName: "lerpGrayscaleToColorKernel",
            fromMetalLibraryData: data) else {
            fatalError("Unable to create color kernel")
        }

        return kernel
    }()

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else { return nil }
        let zeroColorVector = zeroColorInt.vector4
        let oneColorVector = oneColorInt.vector4
        return LerpGrayscaleToColor.kernel.apply(
            extent: inputImage.extent,
            roiCallback: { _, rect in
                return rect
            },
            arguments: [
                inputImage,
                zeroColorVector,
                oneColorVector,
            ]
        )
    }
}

private extension Int64 {
    private func shiftMaskNormalizeClampColorValue(_ shiftAmount: Int) -> Double {
        let normalized = Double((self >> shiftAmount) & 0xFF) / 255.0
        return normalized < 0.0 ? 0 : (normalized > 1.0 ? 1.0 : normalized)
    }

    var vector4: CIVector {
        let a = shiftMaskNormalizeClampColorValue(24)
        let r = shiftMaskNormalizeClampColorValue(16)
        let g = shiftMaskNormalizeClampColorValue(8)
        let b = shiftMaskNormalizeClampColorValue(0)
        return CIVector(x: r, y: g, z: b, w: a)
    }
}
