import AVKit
import Combine
import SwiftUI
import VisionKit

class ScanQrCodeJoinOrgViewModel: ObservableObject {
    private let translator: KeyTranslator

    private let isSeekingAccessSubject = CurrentValueSubject<Bool, Never>(true)
    @Published private(set) var isSeekingAccess = true

    private let isCameraDeniedSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isCameraDenied = false

    private let errorMessageSubject = CurrentValueSubject<String, Never>("")
    @Published private(set) var errorMessage = ""

    private let captureSession = AVCaptureSession()
    private let captureOutput = AVCaptureVideoDataOutput()

    @Published private(set) var frameImage: CGImage?

    let videoOutputQueue = DispatchQueue(
      label: "com.crisiscleanup.ScanQRCodeVideoOutput",
      qos: .userInitiated,
      attributes: [],
      autoreleaseFrequency: .workItem
    )

    private let frameManager = FrameManager()

    private var subscriptions = Set<AnyCancellable>()

    init(
        translator: KeyTranslator
    ) {
        self.translator = translator
    }

    func onViewAppear() {
        subscribeToViewState()
        subscribeToCamera()

        checkCameraPermissions()
        startCamera()
    }

    func onViewDisappear() {
        stopCamera()
        subscriptions = cancelSubscriptions(subscriptions)
    }

    private func subscribeToViewState() {
        errorMessageSubject
            .receive(on: RunLoop.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &subscriptions)
    }

    private func subscribeToCamera() {
        isSeekingAccessSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isSeekingAccess, on: self)
            .store(in: &subscriptions)

        isCameraDeniedSubject
            .receive(on: RunLoop.main)
            .assign(to: \.isCameraDenied, on: self)
            .store(in: &subscriptions)

        $isSeekingAccess
            .receive(on: RunLoop.main)
            .sink { hasAccess in
                if hasAccess {
                    self.configureVideoCapture()
                }
            }
            .store(in: &subscriptions)

        frameManager.cameraFrameSubject
            .compactMap { buffer in
                if let buffer = buffer {
                    let ciContext = CIContext()
                    let ciImage = CIImage(cvImageBuffer: buffer)
                    return ciContext.createCGImage(ciImage, from: ciImage.extent)
                }
                return nil
            }
            .receive(on: RunLoop.main)
            .assign(to: \.frameImage, on: self)
            .store(in: &subscriptions)
    }

    private func startCamera() {
        if captureSession.inputs.isNotEmpty,
           captureSession.outputs.isNotEmpty,
           !captureSession.isRunning {
            Task {
                captureSession.startRunning()
            }
        }
    }

    private func stopCamera() {
        captureSession.stopRunning()
    }

    private func requestCameraAccess() {
        isSeekingAccessSubject.value = true
        AVCaptureDevice.requestAccess(for: .video) { granted in
            self.isCameraDeniedSubject.value = !granted
            self.isSeekingAccessSubject.value = false
        }
    }

    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            requestCameraAccess()
            return

        case .denied, .restricted:
            isCameraDeniedSubject.value = true

        default:
            break
        }

        isSeekingAccessSubject.value = false
    }

    private func configureVideoCapture() {
        captureSession.beginConfiguration()

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let deviceInput = try? AVCaptureDeviceInput(device: device),
           captureSession.canAddInput(deviceInput) {
            captureSession.sessionPreset = .high
            captureSession.addInput(deviceInput)
        } else if captureSession.inputs.isEmpty {
            errorMessageSubject.value = translator.t("~~Camera could not be found. Retry on a device with a camera.")
        }

        if captureSession.inputs.isNotEmpty,
           captureSession.outputs.isEmpty {
            captureSession.addOutput(captureOutput)
            captureOutput.setSampleBufferDelegate(frameManager, queue: self.videoOutputQueue)

            if let videoConnection = captureOutput.connection(with: .video) {
                videoConnection.videoOrientation = .portrait
            }
        }

        captureSession.commitConfiguration()

        startCamera()
    }
}

fileprivate class FrameManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    fileprivate let cameraFrameSubject = CurrentValueSubject<CVPixelBuffer?, Never>(nil)

    /// AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let buffer = sampleBuffer.imageBuffer {
            self.cameraFrameSubject.value = buffer
        }
    }
}
