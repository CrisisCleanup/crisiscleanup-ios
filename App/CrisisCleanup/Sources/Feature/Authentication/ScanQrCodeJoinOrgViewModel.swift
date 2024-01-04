import Atomics
import AVKit
import Combine
import SwiftUI
import Vision

class ScanQrCodeJoinOrgViewModel: ObservableObject {
    private let externalEventBus: ExternalEventBus
    private let translator: KeyTranslator
    private let logger: AppLogger

    private let isSeekingAccessSubject = CurrentValueSubject<Bool, Never>(true)
    @Published private(set) var isSeekingAccess = true

    private let isCameraDeniedSubject = CurrentValueSubject<Bool, Never>(false)
    @Published private(set) var isCameraDenied = false

    private let errorMessageSubject = CurrentValueSubject<String, Never>("")
    @Published private(set) var errorMessage = ""

    private let guardConfigureCamera = ManagedAtomic(false)
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

    lazy var detectBarcodeRequest = VNDetectBarcodesRequest { request, error in
        guard error == nil else {
            self.errorMessageSubject.value = error?.localizedDescription ?? "Detection error"
            return
        }

        self.onBarcodeResult(request)
    }

    private let qrCodeResultSubject = CurrentValueSubject<String, Never>("")

    private var subscriptions = Set<AnyCancellable>()

    init(
        externalEventBus: ExternalEventBus,
        translator: KeyTranslator,
        loggerFactory: AppLoggerFactory
    ) {
        self.externalEventBus = externalEventBus
        self.translator = translator
        logger = loggerFactory.getLogger("onboarding")
    }

    func onViewAppear() {
        qrCodeResultSubject.value = ""

        subscribeToViewState()
        subscribeToCamera()
        subscribeToQrCode()

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

        frameManager.cameraFrameSubject
            .sink(receiveValue: { buffer in
                if let buffer = buffer {
                    let imageRequestHandler = VNImageRequestHandler(
                        cvPixelBuffer: buffer,
                        orientation: .up
                    )
                    do {
                        try imageRequestHandler.perform([self.detectBarcodeRequest])
                    } catch {
                        self.logger.logError(error)
                    }
                }
            })
            .store(in: &subscriptions)
    }

    private func subscribeToQrCode() {
        qrCodeResultSubject.value = ""

        qrCodeResultSubject
            .filter { $0.isNotBlank }
            .compactMap { URL(string: $0) }
            .receive(on: RunLoop.main)
            .sink { url in self.onQrCodeUrl(url) }
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
        let isConfiguring = guardConfigureCamera.compareExchange(
            expected: false,
            desired: true,
            ordering: .sequentiallyConsistent
        )
        if isConfiguring.original {
            return
        }

        captureSession.beginConfiguration()

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let deviceInput = try? AVCaptureDeviceInput(device: device),
           captureSession.canAddInput(deviceInput) {
            captureSession.sessionPreset = .medium
            captureSession.addInput(deviceInput)
        } else if captureSession.inputs.isEmpty {
            errorMessageSubject.value = translator.t("info.camera_not_found")
        }

        if captureSession.inputs.isNotEmpty,
           captureSession.outputs.isEmpty {
            captureSession.addOutput(captureOutput)
            captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            captureOutput.setSampleBufferDelegate(frameManager, queue: self.videoOutputQueue)

            if let videoConnection = captureOutput.connection(with: .video) {
                videoConnection.videoOrientation = .portrait
            }
        }

        captureSession.commitConfiguration()

        startCamera()
    }

    private func onBarcodeResult(_ request: VNRequest) {
        guard qrCodeResultSubject.value.isBlank else {
            return
        }

        request.results?.forEach({ observation in
            if let qrCode = observation as? VNBarcodeObservation {
                qrCodeResultSubject.value = qrCode.payloadStringValue ?? ""
            }
        })
    }

    private func onQrCodeUrl(_ url: URL) {
        if let lastPath = url.pathComponents.last,
           // TODO: Move into and read from application constants
           lastPath == "mobile_app_user_invite",
           let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
           let query = components.queryItems {
            // TODO: Should this be allowed if tokens expired?
            _ = externalEventBus.onOrgPersistentInvite(query)
        }
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
