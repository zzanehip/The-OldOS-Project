  
                       
          
  
                                             
                                                            
  

import Foundation
import Combine
import AVFoundation
import Photos
import UIKit
import CoreImage
import CoreVideo

                                                                                            
public struct Photo: Identifiable, Equatable {
    public var id: String
    public var originalData: Data
    
    public init(id: String = UUID().uuidString, originalData: Data) {
        self.id = id
        self.originalData = originalData
    }
}

public struct AlertError {
    public var title: String = ""
    public var message: String = ""
    public var primaryButtonTitle = "Accept"
    public var secondaryButtonTitle: String?
    public var primaryAction: (() -> ())?
    public var secondaryAction: (() -> ())?
    
    public init(title: String = "", message: String = "", primaryButtonTitle: String = "Accept", secondaryButtonTitle: String? = nil, primaryAction: (() -> ())? = nil, secondaryAction: (() -> ())? = nil) {
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryAction = secondaryAction
    }
}

extension Photo {
    public var compressedData: Data? {
        ImageResizer(targetWidth: 800).resize(data: originalData)?.jpegData(compressionQuality: 0.5)
    }
    public var thumbnailData: Data? {
        ImageResizer(targetWidth: 100).resize(data: originalData)?.jpegData(compressionQuality: 0.5)
    }
    public var thumbnailImage: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }
    public var image: UIImage? {
        guard let data = compressedData else { return nil }
        return UIImage(data: data)
    }
}

extension CameraService : AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard error == nil else { return }
        UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)

                                                                                   
                                                                                  
                                                                                  
        let asset = AVAsset(url: outputFileURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        let requestedTime = CMTime(seconds: 0.05, preferredTimescale: 600)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let cgImage = try generator.copyCGImage(at: requestedTime, actualTime: nil)
                let image = UIImage(cgImage: cgImage)
                guard let data = image.jpegData(compressionQuality: 0.92) else { return }
                DispatchQueue.main.async {
                    self.capturedVideoPreviewPhoto = Photo(originalData: data)
                    self.capturedVideoPreviewRequest += 1
                }
            } catch {
                print("Could not generate video poster frame: \(error)")
            }
        }
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!){
                                    
        if error == nil {
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
        }
    }
}

public class CameraService: NSObject, Identifiable {
    typealias PhotoCaptureSessionID = String
    
                                                    
    
    @Published public var flashMode: AVCaptureDevice.FlashMode = .auto
    @Published public var videoFlashMode: AVCaptureDevice.FlashMode = .off
    @Published public var hdrEnabled = false
    @Published public var isFlashAvailable = true
    private var photoFlashModeBeforeHDR: AVCaptureDevice.FlashMode = .auto
    @Published public var shouldShowAlertView = false
    @Published public var shouldShowSpinner = false
    
    @Published public var willCapturePhoto = false
    @Published public var irisCloseRequest = 0
    @Published public var irisOpenRequest = 0
    @Published public var sessionDidStartRequest = 0
    @Published public var capturedPreviewPhoto: Photo?
    @Published public var capturedPreviewRequest = 0
    @Published public var capturedVideoPreviewPhoto: Photo?
    @Published public var capturedVideoPreviewRequest = 0
    @Published public var isCameraButtonDisabled = false
    @Published public var isCameraUnavailable = false
    @Published public var photo: Photo?
    
                                
    public var alertError: AlertError = AlertError()
    
                                          
    
    public let session = AVCaptureSession()
    
    var isSessionRunning = false
    var isConfigured = false
    var setupResult: SessionSetupResult = .success
    
                                                                            
    let sessionQueue = DispatchQueue(label: "session queue")
    
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!

    public var currentCameraPosition: AVCaptureDevice.Position {
        videoDeviceInput?.device.position ?? .unspecified
    }
    
                                            
    let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: .video, position: .unspecified)
    
                             
    
    let photoOutput = AVCapturePhotoOutput()

                                                                                
                                                                        
                                                                             
    private let flipFrameOutput = AVCaptureVideoDataOutput()
    private let flipFrameQueue = DispatchQueue(label: "camera flip frame queue")
    private let flipFrameLock = NSLock()
    private let flipFrameContext = CIContext(options: [.cacheIntermediates: false])
    private var latestFlipPixelBuffer: CVPixelBuffer?
    private var pendingCameraSwitchFrameCompletion: ((Bool) -> Void)?
                                                                                           
    private var cameraSwitchFrameToken = 0
    
    var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
                                                                                   
                                                                          
    private var latestPhotoUIID: Int64?
    private var photoIrisAwaitingResult = false
    
                                             
    
    var keyValueObservations = [NSKeyValueObservation]()
    private var systemPressureObservation: NSKeyValueObservation?
    private var focusAdjustmentObservation: NSKeyValueObservation?
    private var deviceObservationEpoch = 0                                         
    private var activeFocusUIEpoch = 0                                          
    
                    
    
    override public init() {
        super.init()
        
                                                                                          
        DispatchQueue.main.async {
            self.isCameraButtonDisabled = true
            self.isCameraUnavailable = true
        }
    }
    
                                                                               
                                                                              
    public func configure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            enqueueCameraStart()
        case .notDetermined:
                                                                            
                                                                             
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self = self else { return }
                if granted {
                    self.enqueueCameraStart()
                } else {
                    self.showCameraAuthorizationFailure()
                }
            }
        case .denied, .restricted:
            showCameraAuthorizationFailure()
        @unknown default:
            showCameraAuthorizationFailure()
        }
    }

                                                                      
    public func checkForPermissions() {
        configure()
    }

    private func enqueueCameraStart() {
        sessionQueue.async {
                                                                                
            if self.setupResult == .notAuthorized &&
               AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                self.setupResult = .success
            }
            if self.isConfigured {
                self.startOnSessionQueue()
            } else {
                self.configureSession()
            }
        }
    }

    private func showCameraAuthorizationFailure() {
        sessionQueue.async { self.setupResult = .notAuthorized }
        DispatchQueue.main.async {
            self.alertError = AlertError(
                title: "Camera Access",
                message: "OldOS needs Camera access to show the live preview and take photos. Allow Camera in iOS Settings.",
                primaryButtonTitle: "Settings",
                secondaryButtonTitle: nil,
                primaryAction: {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                    }
                }, secondaryAction: nil)
            self.shouldShowAlertView = true
            self.isCameraUnavailable = true
            self.isCameraButtonDisabled = true
        }
    }

    private func showCameraConfigurationFailure() {
        DispatchQueue.main.async {
            self.alertError = AlertError(
                title: "Camera Error",
                message: "Camera capture session could not start. Close any other app using the camera, then reopen Camera.",
                primaryButtonTitle: "OK", secondaryButtonTitle: nil,
                primaryAction: nil, secondaryAction: nil)
            self.shouldShowAlertView = true
            self.isCameraUnavailable = true
            self.isCameraButtonDisabled = true
        }
    }

                               
    
                                      
                               
    private func configureSession() {
        guard !isConfigured, setupResult == .success else { return }
        defer {
            if setupResult == .configurationFailed {
                showCameraConfigurationFailure()
            }
        }
        
        session.beginConfiguration()
        
          
                                                                                      
                                                                                           
           
        session.sessionPreset = .photo
        
                           
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                                                                                                 
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                                                                                                         
                defaultVideoDevice = frontCameraDevice
            }
            
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                let flashAvailable = self.oldOSFlashControlAvailable(for: videoDevice)
                DispatchQueue.main.async {
                    self.isFlashAvailable = flashAvailable
                }
                
            } else {
                print("Couldn't add video device input to the session.")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        do {
            if let audioInput = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified) {
                let audioDevice = try AVCaptureDeviceInput(device: audioInput)
                if session.canAddInput(audioDevice) {
                session.addInput(audioDevice)
                }
            } else {
                print("Could not add audio output to the session")
            }
        } catch {
            print("Couldn't create audio device input: \(error)")
        }
        
        
                                
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.maxPhotoQualityPrioritization = .quality
            
        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        } else {
            print("Could not add video output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }

        flipFrameOutput.alwaysDiscardsLateVideoFrames = true
        flipFrameOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        flipFrameOutput.setSampleBufferDelegate(self, queue: flipFrameQueue)
        if session.canAddOutput(flipFrameOutput) {
            session.addOutput(flipFrameOutput)
            configureFlipFrameConnection()
        } else {
            print("Could not add camera-flip frame output to the session")
        }
        
        session.commitConfiguration()
        if let device = self.videoDeviceInput?.device {
            self.configureContinuousAutoFocus(for: device)
        }
        self.isConfigured = true

        self.startOnSessionQueue()
    }
    
    private func resumeInterruptedSession() {
        sessionQueue.async {
              
                                                                                                       
                                                                                        
                                                                                          
                                                                               
                                          
               
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
            if !self.session.isRunning {
                DispatchQueue.main.async {
                    self.alertError = AlertError(title: "Camera Error", message: "Unable to resume camera", primaryButtonTitle: "Accept", secondaryButtonTitle: nil, primaryAction: nil, secondaryAction: nil)
                    self.shouldShowAlertView = true
                    self.isCameraUnavailable = true
                    self.isCameraButtonDisabled = true
                }
            } else {
                DispatchQueue.main.async {
                    self.isCameraUnavailable = false
                    self.isCameraButtonDisabled = false
                }
            }
        }
    }
    
                                  
    
                           
    public func currentPreviewFrameImage() -> UIImage? {
        flipFrameLock.lock()
        let pixelBuffer = latestFlipPixelBuffer
        flipFrameLock.unlock()

        guard let pixelBuffer = pixelBuffer else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = flipFrameContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
    }

    private func oldOSFlashControlAvailable(for device: AVCaptureDevice) -> Bool {
        device.position == .back && (device.isFlashAvailable || device.hasTorch)
    }

    private func configureFlipFrameConnection() {
        guard let connection = flipFrameOutput.connection(with: .video) else { return }
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = videoDeviceInput?.device.position == .front
        }
    }

    public func changeCamera(onFirstFrame: ((Bool) -> Void)? = nil) {
                                                                                                                                      
        DispatchQueue.main.async {
            self.isCameraButtonDisabled = true
        }
          
        
        sessionQueue.async {
            guard self.isConfigured, self.session.isRunning,
                  let currentInput = self.videoDeviceInput,
                  !self.movieOutput.isRecording,
                  self.inProgressPhotoCaptureDelegates.isEmpty else {
                DispatchQueue.main.async {
                    self.isCameraButtonDisabled = false
                    onFirstFrame?(false)
                }
                return
            }
            let currentVideoDevice = currentInput.device
            let currentPosition = currentVideoDevice.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInWideAngleCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInWideAngleCamera
                
            @unknown default:
                print("Unknown capture position. Defaulting to back, dual-camera.")
                preferredPosition = .back
                preferredDeviceType = .builtInWideAngleCamera
            }
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil
            
                                                                                                                                                
            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                newVideoDevice = device
            } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }
            
            var didSwitchDevice = false
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                                                                                            
                                                                                                  
                                                                                               
                                                     
                    self.removeDeviceObservations()
                    NotificationCenter.default.removeObserver(self,
                                                              name: .AVCaptureDeviceSubjectAreaDidChange,
                                                              object: currentVideoDevice)

                    self.session.beginConfiguration()
                    
                                                                                    
                    if currentVideoDevice.hasTorch && currentVideoDevice.isTorchActive {
                        do {
                            try currentVideoDevice.lockForConfiguration()
                            currentVideoDevice.torchMode = .off
                            currentVideoDevice.unlockForConfiguration()
                        } catch {
                            print("Could not release old camera torch: \(error)")
                        }
                    }

                                                                                                       
                                                                      
                    self.session.removeInput(currentInput)
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange), name: .AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput.device)
                        
                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                        didSwitchDevice = true
                        let flashAvailable = self.oldOSFlashControlAvailable(for: videoDevice)
                        DispatchQueue.main.async {
                            self.isFlashAvailable = flashAvailable
                        }
                        DispatchQueue.main.async {
                            if !flashAvailable {
                                self.flashMode = .off
                                self.videoFlashMode = .off
                            } else if !self.hdrEnabled && self.flashMode == .off && self.photoFlashModeBeforeHDR != .off {
                                self.flashMode = self.photoFlashModeBeforeHDR
                            }
                        }
                    } else {
                        self.session.addInput(currentInput)
                        NotificationCenter.default.addObserver(self,
                                                               selector: #selector(self.subjectAreaDidChange),
                                                               name: .AVCaptureDeviceSubjectAreaDidChange,
                                                               object: currentVideoDevice)
                    }
                    
                    if let connection = self.photoOutput.connection(with: .video) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    
                    self.photoOutput.maxPhotoQualityPrioritization = .quality
                    
                    self.session.commitConfiguration()

                                                                                               
                                                                                                 
                                                                                
                    let activeDevice = self.videoDeviceInput.device
                    self.configureContinuousAutoFocus(for: activeDevice)
                    self.installDeviceObservations(for: activeDevice)
                    self.configureFlipFrameConnection()

                    if didSwitchDevice, let onFirstFrame = onFirstFrame {
                                                                                         
                        self.flipFrameQueue.async { [weak self] in
                            guard let self = self else { return }
                            self.cameraSwitchFrameToken += 1
                            let token = self.cameraSwitchFrameToken
                            self.pendingCameraSwitchFrameCompletion = onFirstFrame
                                                                               
                                                                             
                            self.flipFrameQueue.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                                guard let self = self,
                                      self.cameraSwitchFrameToken == token,
                                      let completion = self.pendingCameraSwitchFrameCompletion else { return }
                                self.pendingCameraSwitchFrameCompletion = nil
                                DispatchQueue.main.async { completion(false) }
                            }
                        }
                    }
                } catch {
                    print("Error occurred while creating video device input: \(error)")
                }
            }

            if !didSwitchDevice {
                DispatchQueue.main.async { onFirstFrame?(false) }
            }
            DispatchQueue.main.async {
                                                                                                                
                self.isCameraButtonDisabled = false
            }
        }
    }
    
    private func installDeviceObservations(for device: AVCaptureDevice) {
        removeDeviceObservations()
        let epoch = deviceObservationEpoch
        DispatchQueue.main.async { self.activeFocusUIEpoch = epoch }

        systemPressureObservation = device.observe(\.systemPressureState, options: [.new]) { [weak self, weak device] _, change in
            guard let self = self,
                  let device = device,
                  let state = change.newValue else { return }
            self.sessionQueue.async { [weak self, weak device] in
                guard let self = self,
                      let device = device,
                      let activeDevice = self.videoDeviceInput?.device,
                      device === activeDevice else { return }
                self.setRecommendedFrameRateRangeForPressureState(systemPressureState: state, device: device)
            }
        }

        focusAdjustmentObservation = device.observe(\.isAdjustingFocus, options: [.new]) { [weak self, weak device] _, change in
            guard let self = self,
                  let device = device,
                  let adjusting = change.newValue else { return }
            self.sessionQueue.async { [weak self, weak device] in
                guard let self = self,
                      let device = device,
                      let activeDevice = self.videoDeviceInput?.device,
                      device === activeDevice else { return }
                let point = device.focusPointOfInterest
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, self.activeFocusUIEpoch == epoch else { return }
                    NotificationCenter.default.post(name: .init(adjusting ? "OldOSCameraAutoFocusDidBegin" : "OldOSCameraAutoFocusDidEnd"),
                                                    object: nil,
                                                    userInfo: ["devicePoint": point])
                }
            }
        }
    }

    private func removeDeviceObservations() {
        deviceObservationEpoch += 1
        let epoch = deviceObservationEpoch
        DispatchQueue.main.async { self.activeFocusUIEpoch = epoch }
        focusAdjustmentObservation?.invalidate()
        focusAdjustmentObservation = nil
        systemPressureObservation?.invalidate()
        systemPressureObservation = nil
    }

    private func configureContinuousAutoFocus(for device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.isSubjectAreaChangeMonitoringEnabled = true
            device.unlockForConfiguration()
        } catch {
            print("Could not configure continuous autofocus: \(error)")
        }
    }

    public func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        sessionQueue.async {
            guard let device = self.videoDeviceInput?.device else { return }
            do {
                try device.lockForConfiguration()
                
                  
                                                                                                              
                                                                                   
                   
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    
    public func focus(at focusPoint: CGPoint){
        sessionQueue.async {
            let device = self.videoDeviceInput.device
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = focusPoint
                }
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = focusPoint
                }
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                device.isSubjectAreaChangeMonitoringEnabled = true
                device.unlockForConfiguration()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @objc public func stop(completion: (() -> ())? = nil) {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
            self.isSessionRunning = self.session.isRunning
            self.removeObservers()
            self.flipFrameQueue.async { [weak self] in
                guard let self = self else { return }
                let pending = self.pendingCameraSwitchFrameCompletion
                self.cameraSwitchFrameToken += 1
                self.pendingCameraSwitchFrameCompletion = nil
                if let pending = pending {
                    DispatchQueue.main.async { pending(false) }
                }
            }
            DispatchQueue.main.async {
                self.isCameraButtonDisabled = true
                self.isCameraUnavailable = true
                completion?()
            }
        }
    }
    
    @objc public func start() {
        sessionQueue.async { self.startOnSessionQueue() }
    }

                                                     
    private func startOnSessionQueue() {
        guard isConfigured, setupResult == .success else { return }
        if !session.isRunning {
            addObservers()
            session.startRunning()
        }
        isSessionRunning = session.isRunning
        if isSessionRunning {
            print("CAMERA RUNNING")
            DispatchQueue.main.async {
                self.isCameraButtonDisabled = false
                self.isCameraUnavailable = false
                self.sessionDidStartRequest += 1
            }
        } else {
            print("CAMERA FAILED TO START")
            showCameraConfigurationFailure()
        }
    }

    public func setPhotoFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        let requested = (videoDeviceInput != nil && oldOSFlashControlAvailable(for: videoDeviceInput.device)) ? mode : .off

        if hdrEnabled && requested != .off {
            photoFlashModeBeforeHDR = requested
            DispatchQueue.main.async {
                self.hdrEnabled = false
                self.flashMode = requested
            }
            return
        }

        if !hdrEnabled {
            photoFlashModeBeforeHDR = requested
        }
        DispatchQueue.main.async {
            self.flashMode = requested
        }
    }

    public func setVideoFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        let requested: AVCaptureDevice.FlashMode
        if videoDeviceInput != nil && oldOSFlashControlAvailable(for: videoDeviceInput.device) {
            requested = (mode == .on) ? .on : .off
        } else {
            requested = .off
        }

        DispatchQueue.main.async {
            self.videoFlashMode = requested
        }
        applyVideoTorchMode(requested)
    }

    public func activateVideoFlashMode() {
        applyVideoTorchMode(videoFlashMode)
    }

    public func deactivateVideoTorch() {
        applyVideoTorchMode(.off)
    }

    private func applyVideoTorchMode(_ mode: AVCaptureDevice.FlashMode) {
        sessionQueue.async {
            guard let device = self.videoDeviceInput?.device,
                  self.oldOSFlashControlAvailable(for: device), device.hasTorch else { return }

            let torchMode: AVCaptureDevice.TorchMode = (mode == .on) ? .on : .off

            do {
                try device.lockForConfiguration()
                if device.isTorchModeSupported(torchMode) {
                    device.torchMode = torchMode
                } else if device.isTorchModeSupported(.off) {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    public func setHDREnabled(_ enabled: Bool) {
        guard enabled != hdrEnabled else { return }

        if enabled {
            photoFlashModeBeforeHDR = flashMode
            DispatchQueue.main.async {
                self.hdrEnabled = true
                self.flashMode = .off
            }
        } else {
            let restored = (videoDeviceInput != nil && oldOSFlashControlAvailable(for: videoDeviceInput.device)) ? photoFlashModeBeforeHDR : .off
            DispatchQueue.main.async {
                self.hdrEnabled = false
                self.flashMode = restored
            }
        }
    }

    public func set(zoom: CGFloat){
        sessionQueue.async {
            guard let device = self.videoDeviceInput?.device else { return }
            let maximum = min(device.activeFormat.videoMaxZoomFactor, 5.0)
            let factor = min(max(zoom, 1.0), maximum)
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = factor
                device.unlockForConfiguration()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
                             
    
                           
    public func capturePhoto() {
          
                                                                                      
                                                                                     
                                                                                
           
        
        let videoPreviewLayerOrientation: AVCaptureVideoOrientation = .portrait
        DispatchQueue.main.async { self.isCameraButtonDisabled = true }
        sessionQueue.async {
                                                                                  
            guard self.inProgressPhotoCaptureDelegates.isEmpty else {
                print("CAMERA PHOTO ignored overlapping capture")
                return
            }
            guard self.isConfigured, self.session.isRunning,
                  self.videoDeviceInput != nil,
                  self.photoOutput.connection(with: .video) != nil else {
                print("CAMERA CAPTURE CANCELLED: no active photo/video connection")
                DispatchQueue.main.async { self.isCameraButtonDisabled = false }
                return
            }
                if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                    photoOutputConnection.videoOrientation = videoPreviewLayerOrientation
                }
                let wantsHDR = self.hdrEnabled && self.photoOutput.maxBracketedCapturePhotoCount >= 3
                var photoSettings: AVCapturePhotoSettings

                if wantsHDR {
                    let processedFormat: [String: Any]
                    if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                        processedFormat = [AVVideoCodecKey: AVVideoCodecType.hevc]
                    } else {
                        processedFormat = [AVVideoCodecKey: AVVideoCodecType.jpeg]
                    }
                    let brackets: [AVCaptureBracketedStillImageSettings] = [
                        AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(exposureTargetBias: -1.0),
                        AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(exposureTargetBias: 0.0),
                        AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(exposureTargetBias: 1.0)
                    ]
                    photoSettings = AVCapturePhotoBracketSettings(
                        rawPixelFormatType: 0,
                        processedFormat: processedFormat,
                        bracketedSettings: brackets
                    )
                } else if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                } else {
                    photoSettings = AVCapturePhotoSettings()
                }

                if !wantsHDR && self.oldOSFlashControlAvailable(for: self.videoDeviceInput.device) {
                    photoSettings.flashMode = self.flashMode
                }

                photoSettings.isHighResolutionPhotoEnabled = true
                if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                    photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
                }

                photoSettings.photoQualityPrioritization = .speed
                
                let captureID = photoSettings.uniqueID
                DispatchQueue.main.async {
                    self.latestPhotoUIID = captureID
                    self.photoIrisAwaitingResult = false
                                                                                      
                                                                                     
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
                        guard let self = self,
                              self.latestPhotoUIID == captureID,
                              self.photoIrisAwaitingResult else { return }
                        print("CAMERA PHOTO watchdog: no processing result id=\(captureID)")
                        self.photoIrisAwaitingResult = false
                        self.willCapturePhoto = false
                        self.irisOpenRequest += 1
                        self.isCameraButtonDisabled = false
                        self.alertError = AlertError(
                            title: "Camera Capture Timed Out",
                            message: "The camera did not finish processing this photo. No photo has been confirmed saved. Try again.",
                            primaryButtonTitle: "OK", secondaryButtonTitle: nil,
                            primaryAction: nil, secondaryAction: nil)
                        self.shouldShowAlertView = true
                    }
                }
                let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings,
                                                                  hdrEnabled: wantsHDR,
                                                                  keepNormalHDRPhoto: true,
                                                                  willCapturePhotoAnimation: {
                                                                                         
                                                                                            
                    guard self.latestPhotoUIID == captureID else { return }
                    self.photoIrisAwaitingResult = true
                    self.willCapturePhoto = true
                    self.irisCloseRequest += 1
                }, didFinishProcessingPhotoAnimation: { data in
                                                                                       
                                                                                         
                                                                                  
                    guard self.latestPhotoUIID == captureID else { return }
                    if let data = data {
                        self.capturedPreviewPhoto = Photo(originalData: data)
                        self.capturedPreviewRequest += 1
                    } else {
                        print("CAMERA PHOTO processing produced no data id=\(captureID)")
                        self.alertError = AlertError(
                            title: "Photo Capture Failed",
                            message: "The camera did not return an image. Nothing was added to the camera roll.",
                            primaryButtonTitle: "OK", secondaryButtonTitle: nil,
                            primaryAction: nil, secondaryAction: nil)
                        self.shouldShowAlertView = true
                    }
                    if self.photoIrisAwaitingResult {
                        self.photoIrisAwaitingResult = false
                        self.willCapturePhoto = false
                        self.irisOpenRequest += 1
                    }
                }, completionHandler: { (photoCaptureProcessor) in
                                                                                                                               
                    if let data = photoCaptureProcessor.photoData {
                        self.photo = Photo(originalData: data)
                        print("CAMERA PHOTO completed bytes=\(data.count) id=\(captureID)")
                    } else {
                        print("CAMERA PHOTO completed without image id=\(captureID)")
                    }
                    
                    self.isCameraButtonDisabled = false
                    
                    self.sessionQueue.async {
                        self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                    }
                }, photoProcessingHandler: { animate in
                                                                   
                    if animate {
                        self.shouldShowSpinner = true
                    } else {
                        self.shouldShowSpinner = false
                    }
                })
                
                                                                                                                                                  
                self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
                self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
        }
    }
    
    
                             
    
                                  
    private func addObservers() {
        if let device = videoDeviceInput?.device {
            installDeviceObservations(for: device)
        }
        
                                                                                                                                                                   
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(subjectAreaDidChange),
                                               name: .AVCaptureDeviceSubjectAreaDidChange,
                                               object: videoDeviceInput.device)
        
        NotificationCenter.default.addObserver(self, selector: #selector(uiRequestedNewFocusArea), name: .init(rawValue: "UserDidRequestNewFocusPoint"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(uiRequestedZoomFactor), name: .init(rawValue: "UserDidRequestZoomFactor"), object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionRuntimeError),
                                               name: .AVCaptureSessionRuntimeError,
                                               object: session)
        
          
                                                                                   
                                                                                  
                                                                                  
                                                                                  
                                                                                      
           
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionWasInterrupted),
                                               name: .AVCaptureSessionWasInterrupted,
                                               object: session)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterruptionEnded),
                                               name: .AVCaptureSessionInterruptionEnded,
                                               object: session)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        removeDeviceObservations()
        
        for keyValueObservation in keyValueObservations {
            keyValueObservation.invalidate()
        }
        keyValueObservations.removeAll()
    }
    
    @objc private func uiRequestedNewFocusArea(notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String: Any], let devicePoint = userInfo["devicePoint"] as? CGPoint else { return }
        self.focus(at: devicePoint)
    }

    @objc private func uiRequestedZoomFactor(notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String: Any] else { return }
        if let zoomFactor = userInfo["zoomFactor"] as? CGFloat {
            self.set(zoom: zoomFactor)
        } else if let zoomNumber = userInfo["zoomFactor"] as? NSNumber {
            self.set(zoom: CGFloat(truncating: zoomNumber))
        }
    }
    
    @objc
    private func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: true)
    }
    
                                 
    @objc
    private func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        
        print("Capture session runtime error: \(error)")
                                                                                           
        if error.code == .mediaServicesWereReset {
            sessionQueue.async {
                if self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                } else {
                    DispatchQueue.main.async {
                                                            
                    }
                }
            }
        } else {
                                           
        }
    }
    
                                   
    private func setRecommendedFrameRateRangeForPressureState(systemPressureState: AVCaptureDevice.SystemPressureState,
                                                               device: AVCaptureDevice) {
          
                                                                       
                                                                                                  
           
        let pressureLevel = systemPressureState.level
        if pressureLevel == .serious || pressureLevel == .critical {
            do {
                try device.lockForConfiguration()
                print("WARNING: Reached elevated system pressure level: \(pressureLevel). Throttling frame rate.")
                device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 20)
                device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 15)
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        } else if pressureLevel == .shutdown {
            print("Session stopped running due to shutdown system pressure level.")
        }
    }
    
                                 
    @objc
    private func sessionWasInterrupted(notification: NSNotification) {
          
                                                                             
                                                                              
                                                          
                                                                                
                                                                                    
                                                                                               
           
        DispatchQueue.main.async {
            self.isCameraUnavailable = true
        }
        
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
            let reasonIntegerValue = userInfoValue.integerValue,
            let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
            
            if reason == .audioDeviceInUseByAnotherClient || reason == .videoDeviceInUseByAnotherClient {
                print("Session stopped running due to video devies in use by another client.")
            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                                                                                     
                print("Session stopped running due to video devies is not available with multiple foreground apps.")
            } else if reason == .videoDeviceNotAvailableDueToSystemPressure {
                print("Session stopped running due to shutdown system pressure level.")
            }
        }
    }
    
    @objc
    private func sessionInterruptionEnded(notification: NSNotification) {
        print("Capture session interruption ended")
        DispatchQueue.main.async {
            self.isCameraUnavailable = false
        }
    }
    
    var movieOutput = AVCaptureMovieFileOutput()
   public func record() {
                                                                               
                                                                                  
        sessionQueue.async {
            guard self.isConfigured, self.session.isRunning else { return }
            if self.movieOutput.isRecording {
                self.movieOutput.stopRecording()
            } else {
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let fileUrl = paths[0].appendingPathComponent("output.mov")
                try? FileManager.default.removeItem(at: fileUrl)
                self.movieOutput.startRecording(to: fileUrl, recordingDelegate: self)
            }
        }
    }
    
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        guard output === flipFrameOutput,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        flipFrameLock.lock()
        latestFlipPixelBuffer = pixelBuffer
        flipFrameLock.unlock()

        if let completion = pendingCameraSwitchFrameCompletion {
            pendingCameraSwitchFrameCompletion = nil
            DispatchQueue.main.async { completion(true) }
        }
    }
}
