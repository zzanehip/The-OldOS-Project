  
                       
          
  
                                             
                                                            
  

import UIKit
import AVFoundation
import SwiftUI
import QuartzCore

public struct CameraPreview: UIViewRepresentable {
    public class VideoPreviewView: UIView, UIGestureRecognizerDelegate {
        public override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
        
        private let focusView: UIImageView = {
            let view = UIImageView(image: UIImage(named: "PLFocusCrosshairsSmall0"))
            view.frame = CGRect(x: 0, y: 0, width: 73, height: 73)
            view.contentMode = .scaleAspectFit
            view.alpha = 0
            view.isUserInteractionEnabled = false
            return view
        }()

        private final class OldOSZoomSliderControl: UIControl {
            var normalizedValue: CGFloat = 0 {
                didSet {
                    normalizedValue = min(max(normalizedValue, 0), 1)
                    setNeedsLayout()
                }
            }
            var onValueChanged: ((CGFloat) -> Void)?

            private let leftCap = UIImageView(image: UIImage(named: "PLCameraZoomTrackMin"))
            private let centerTrack = UIImageView()
            private let rightCap = UIImageView(image: UIImage(named: "PLCameraZoomTrackMax"))
            private let minusView = UIImageView(image: UIImage(named: "PLCameraZoomMin"))
            private let plusView = UIImageView(image: UIImage(named: "PLCameraZoomMax"))
            private let thumbView = UIImageView(image: UIImage(named: "PLCameraZoomThumb"))

            override init(frame: CGRect) {
                super.init(frame: frame)
                commonInit()
            }

            required init?(coder: NSCoder) {
                super.init(coder: coder)
                commonInit()
            }

            private func commonInit() {
                backgroundColor = .clear
                isExclusiveTouch = true
                clipsToBounds = false

                leftCap.contentMode = .scaleToFill
                rightCap.contentMode = .scaleToFill
                minusView.contentMode = .center
                plusView.contentMode = .center
                thumbView.contentMode = .center

                if let center = UIImage(named: "PLCameraZoomTrack") {
                    centerTrack.image = center.resizableImage(withCapInsets: UIEdgeInsets(top: 0,
                                                                                         left: 7.5,
                                                                                         bottom: 0,
                                                                                         right: 7.5),
                                                             resizingMode: .stretch)
                }
                centerTrack.contentMode = .scaleToFill

                addSubview(leftCap)
                addSubview(centerTrack)
                addSubview(rightCap)
                addSubview(minusView)
                addSubview(plusView)
                addSubview(thumbView)
            }

            override func layoutSubviews() {
                super.layoutSubviews()

                let h: CGFloat = 23.0
                let capW: CGFloat = 31.0
                let symbolSize: CGFloat = 13.0
                let thumbSize: CGFloat = 15.0
                let y = (bounds.height - h) * 0.5

                leftCap.frame = CGRect(x: 0, y: y, width: capW, height: h)
                centerTrack.frame = CGRect(x: capW,
                                           y: y,
                                           width: max(0, bounds.width - 2.0 * capW),
                                           height: h)
                rightCap.frame = CGRect(x: max(0, bounds.width - capW), y: y, width: capW, height: h)

                minusView.frame = CGRect(x: capW * 0.5 - symbolSize * 0.5,
                                         y: bounds.midY - symbolSize * 0.5,
                                         width: symbolSize,
                                         height: symbolSize)
                plusView.frame = CGRect(x: bounds.width - capW * 0.5 - symbolSize * 0.5,
                                        y: bounds.midY - symbolSize * 0.5,
                                        width: symbolSize,
                                        height: symbolSize)

                let minimumThumbX: CGFloat = 39.5
                let maximumThumbX = max(minimumThumbX, bounds.width - 39.5)
                let thumbX = minimumThumbX + normalizedValue * (maximumThumbX - minimumThumbX)
                thumbView.frame = CGRect(x: thumbX - thumbSize * 0.5,
                                         y: bounds.midY - thumbSize * 0.5,
                                         width: thumbSize,
                                         height: thumbSize)
            }

            private func updateValue(for touch: UITouch, sendAction: Bool) {
                let x = touch.location(in: self).x
                let minimumThumbX: CGFloat = 39.5
                let maximumThumbX = max(minimumThumbX + 1.0, bounds.width - 39.5)
                normalizedValue = (x - minimumThumbX) / (maximumThumbX - minimumThumbX)
                if sendAction {
                    onValueChanged?(normalizedValue)
                }
            }

            override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
                updateValue(for: touch, sendAction: true)
                return true
            }

            override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
                updateValue(for: touch, sendAction: true)
                return true
            }
        }

        private let zoomControl = OldOSZoomSliderControl()
        private var zoomControlVisible = false
        private var hasInstalledCameraChrome = false
        private var hasInstalledGestureRecognizer = false
        private var focusHideWorkItem: DispatchWorkItem?

        override init(frame: CGRect) {
            super.init(frame: frame)
            commonInit()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            commonInit()
        }

        deinit {
            focusHideWorkItem?.cancel()
            NotificationCenter.default.removeObserver(self)
        }

        private func commonInit() {
            isMultipleTouchEnabled = true
            zoomControl.alpha = 0
            zoomControl.isHidden = true
            zoomControl.normalizedValue = 0
            zoomControl.onValueChanged = { value in
                let zoomFactor = CGFloat(1.0 + value * 4.0)
                NotificationCenter.default.post(.init(name: .init("UserDidRequestZoomFactor"),
                                                      object: nil,
                                                      userInfo: ["zoomFactor": zoomFactor]))
            }

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(autoFocusDidBegin(_:)),
                                                   name: .init("OldOSCameraAutoFocusDidBegin"),
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(autoFocusDidEnd(_:)),
                                                   name: .init("OldOSCameraAutoFocusDidEnd"),
                                                   object: nil)
        }

        private func focusLayerPoint(from notification: Notification) -> CGPoint {
            if let devicePoint = notification.userInfo?["devicePoint"] as? CGPoint {
                return videoPreviewLayer.layerPointConverted(fromCaptureDevicePoint: devicePoint)
            }
            return CGPoint(x: bounds.midX, y: max(0, (bounds.height - 60.0) * 0.5))
        }

        private func showFocusIndicator(at point: CGPoint) {
            focusHideWorkItem?.cancel()
            focusHideWorkItem = nil
            focusView.layer.removeAllAnimations()
            focusView.image = UIImage(named: "PLFocusCrosshairsSmall0")
            focusView.bounds = CGRect(x: 0, y: 0, width: 73, height: 73)
            focusView.center = point
            focusView.alpha = 1.0
            bringSubviewToFront(focusView)
        }

        private func scheduleFocusFallbackHide(after delay: TimeInterval = 1.0) {
            focusHideWorkItem?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.settleAndHideFocusIndicator()
            }
            focusHideWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        }

        private func settleAndHideFocusIndicator() {
            focusHideWorkItem?.cancel()
            focusView.layer.removeAllAnimations()
            focusView.image = UIImage(named: "PLFocusCrosshairsSmall1")
            focusView.alpha = 1.0

            let work = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.20,
                               delay: 0,
                               options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
                               animations: {
                    self.focusView.alpha = 0
                })
            }
            focusHideWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: work)
        }

        @objc private func autoFocusDidBegin(_ notification: Notification) {
            let point = focusLayerPoint(from: notification)
            showFocusIndicator(at: point)
            scheduleFocusFallbackHide(after: 1.2)
        }

        @objc private func autoFocusDidEnd(_ notification: Notification) {
            if focusView.alpha == 0 {
                focusView.center = focusLayerPoint(from: notification)
                focusView.alpha = 1
            }
            settleAndHideFocusIndicator()
        }

        @objc func focusAndExposeTap(gestureRecognizer: UITapGestureRecognizer) {
            let layerPoint = gestureRecognizer.location(in: self)

            guard layerPoint.y < bounds.height - 60.0 else { return }

            showFocusIndicator(at: layerPoint)

            let devicePoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: layerPoint)
            NotificationCenter.default.post(.init(name: .init("UserDidRequestNewFocusPoint"),
                                                  object: nil,
                                                  userInfo: ["devicePoint": devicePoint] as [AnyHashable: Any]))
            scheduleFocusFallbackHide(after: 1.0)

            setZoomControlVisible(!zoomControlVisible, animated: true)
        }

        private func setZoomControlVisible(_ visible: Bool, animated: Bool) {
            zoomControlVisible = visible
            if visible {
                zoomControl.isHidden = false
                bringSubviewToFront(zoomControl)
                bringSubviewToFront(focusView)
            }
            let changes = { self.zoomControl.alpha = visible ? 1.0 : 0.0 }
            let completion: (Bool) -> Void = { _ in
                if !visible { self.zoomControl.isHidden = true }
            }
            if animated {
                UIView.animate(withDuration: 0.20,
                               delay: 0,
                               options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction],
                               animations: changes,
                               completion: completion)
            } else {
                changes()
                completion(true)
            }
        }

        public override func layoutSubviews() {
            super.layoutSubviews()
            if !hasInstalledCameraChrome {
                addSubview(focusView)
                addSubview(zoomControl)
                hasInstalledCameraChrome = true
            }
            if !hasInstalledGestureRecognizer {
                let recognizer = UITapGestureRecognizer(target: self, action: #selector(VideoPreviewView.focusAndExposeTap(gestureRecognizer:)))
                recognizer.cancelsTouchesInView = false
                recognizer.delegate = self
                addGestureRecognizer(recognizer)
                hasInstalledGestureRecognizer = true
            }

            let horizontalInset: CGFloat = 17.0
            let zoomHeight: CGFloat = 23.0
            let toolbarHeight: CGFloat = 60.0
            let bottomGap: CGFloat = 13.0
            zoomControl.frame = CGRect(x: horizontalInset,
                                       y: bounds.height - toolbarHeight - bottomGap - zoomHeight,
                                       width: max(0, bounds.width - 2.0 * horizontalInset),
                                       height: zoomHeight)
        }

        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let touchedView = touch.view else { return true }
            return !touchedView.isDescendant(of: zoomControl)
        }
    }

    public final class FlipContainerView: UIView {
        let livePreviewView = VideoPreviewView()
        private let frontFaceImageView = UIImageView()
        private var pendingFlipRequest = 0
        private var cancelledFlipRequest = 0
        private var activeFlipRequest = 0
        private var isFlipAnimating = false

        override init(frame: CGRect) {
            super.init(frame: frame)
            commonInit()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            commonInit()
        }

        private func commonInit() {
            backgroundColor = .black
            clipsToBounds = true

            var perspective = CATransform3DIdentity
            perspective.m34 = -1.0 / 700.0
            layer.sublayerTransform = perspective

            livePreviewView.layer.isDoubleSided = false
            frontFaceImageView.layer.isDoubleSided = false
            frontFaceImageView.clipsToBounds = true
            frontFaceImageView.contentMode = .scaleAspectFill
            frontFaceImageView.isHidden = true

            addSubview(livePreviewView)
            addSubview(frontFaceImageView)
        }

        override public func layoutSubviews() {
            super.layoutSubviews()
            livePreviewView.frame = bounds
            frontFaceImageView.frame = bounds
        }

        func configure(session: AVCaptureSession) {
            livePreviewView.backgroundColor = .black
            livePreviewView.videoPreviewLayer.cornerRadius = 0
            livePreviewView.videoPreviewLayer.videoGravity = .resizeAspectFill

                                                                                            
                                                                                              
                                                                                                
                                                                                           
            if livePreviewView.videoPreviewLayer.session !== session {
                livePreviewView.videoPreviewLayer.session = session
                livePreviewView.videoPreviewLayer.connection?.videoOrientation = .portrait
            }
        }

        func cancelPreparedFlip(request: Int) {
            guard request > cancelledFlipRequest else { return }
            cancelledFlipRequest = request
            if isFlipAnimating {
                finishFlipImmediately()
            } else {
                frontFaceImageView.isHidden = true
                frontFaceImageView.image = nil
                bringSubviewToFront(livePreviewView)
            }
        }

        func prepareFrontFace(image: UIImage) {
            guard !isFlipAnimating else { return }
            frontFaceImageView.layer.removeAllAnimations()
            livePreviewView.layer.removeAllAnimations()
            frontFaceImageView.layer.transform = CATransform3DIdentity
            livePreviewView.layer.transform = CATransform3DIdentity
            frontFaceImageView.image = image
            frontFaceImageView.isHidden = false
            bringSubviewToFront(frontFaceImageView)
        }

        func startFlip(request: Int, fromRight: Bool) {
            guard request > 0,
                  request != pendingFlipRequest,
                  frontFaceImageView.image != nil,
                  !isFlipAnimating else { return }
            pendingFlipRequest = request
            activeFlipRequest = request
            isFlipAnimating = true

                                                                               
                                                                                  
                                                                                 
                                                                                    
                                                                                
                                                            
            let direction: CGFloat = fromRight ? -1.0 : 1.0
            let outgoingEdge = perspectiveRotation(direction * (.pi / 2.0))
            let incomingEdge = perspectiveRotation(-direction * (.pi / 2.0))

            frontFaceImageView.layer.removeAllAnimations()
            livePreviewView.layer.removeAllAnimations()
            frontFaceImageView.layer.transform = CATransform3DIdentity
            frontFaceImageView.layer.opacity = 1.0
            frontFaceImageView.isHidden = false

                                                                                   
                                                                                    
                                                                                    
                            
            livePreviewView.isHidden = false
            livePreviewView.layer.transform = incomingEdge
            livePreviewView.layer.opacity = 1.0
            bringSubviewToFront(frontFaceImageView)

            UIView.animate(withDuration: 0.25,
                           delay: 0.0,
                           options: [.curveEaseIn, .beginFromCurrentState, .allowUserInteraction],
                           animations: {
                self.frontFaceImageView.layer.transform = outgoingEdge
                self.frontFaceImageView.layer.opacity = 0.82
            }, completion: { [weak self] finished in
                guard let self = self, finished else {
                    self?.finishFlipImmediately()
                    return
                }

                self.frontFaceImageView.isHidden = true
                self.bringSubviewToFront(self.livePreviewView)
                self.livePreviewView.layer.transform = incomingEdge
                self.livePreviewView.layer.opacity = 0.82

                UIView.animate(withDuration: 0.25,
                               delay: 0.0,
                               options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
                               animations: {
                    self.livePreviewView.layer.transform = CATransform3DIdentity
                    self.livePreviewView.layer.opacity = 1.0
                }, completion: { [weak self] _ in
                    self?.finishFlipImmediately()
                })
            })
        }

        private func perspectiveRotation(_ angle: CGFloat) -> CATransform3D {
            var transform = CATransform3DIdentity
            transform.m34 = -1.0 / 700.0
            return CATransform3DRotate(transform, angle, 0.0, 1.0, 0.0)
        }

        private func finishFlipImmediately() {
            let completedRequest = activeFlipRequest
            activeFlipRequest = 0

            frontFaceImageView.layer.removeAllAnimations()
            livePreviewView.layer.removeAllAnimations()
            frontFaceImageView.isHidden = true
            frontFaceImageView.image = nil
            frontFaceImageView.layer.transform = CATransform3DIdentity
            frontFaceImageView.layer.opacity = 1.0
            livePreviewView.isHidden = false
            livePreviewView.layer.transform = CATransform3DIdentity
            livePreviewView.layer.opacity = 1.0
            bringSubviewToFront(livePreviewView)
            isFlipAnimating = false

            if completedRequest > 0 {
                NotificationCenter.default.post(name: .init("OldOSCameraFlipAnimationDidFinish"),
                                                object: nil,
                                                userInfo: ["request": completedRequest])
            }
        }
    }
    
    public let session: AVCaptureSession
    public let flipPrepareRequest: Int
    public let flipRequest: Int
    public let flipCancelRequest: Int
    public let flipFromRight: Bool
    public let flipFrontImage: UIImage?

    public final class Coordinator {
        var lastFlipPrepareRequest = 0
        var lastFlipRequest = 0
        var lastFlipCancelRequest = 0
    }
    
    public init(session: AVCaptureSession,
                flipPrepareRequest: Int = 0,
                flipRequest: Int = 0,
                flipCancelRequest: Int = 0,
                flipFromRight: Bool = true,
                flipFrontImage: UIImage? = nil) {
        self.session = session
        self.flipPrepareRequest = flipPrepareRequest
        self.flipRequest = flipRequest
        self.flipCancelRequest = flipCancelRequest
        self.flipFromRight = flipFromRight
        self.flipFrontImage = flipFrontImage
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public func makeUIView(context: Context) -> FlipContainerView {
        let viewFinder = FlipContainerView()
        viewFinder.configure(session: session)
        return viewFinder
    }
    
    public func updateUIView(_ uiView: FlipContainerView, context: Context) {
        uiView.configure(session: session)

        if flipPrepareRequest > 0,
           flipPrepareRequest != context.coordinator.lastFlipPrepareRequest,
           let flipFrontImage = flipFrontImage {
            context.coordinator.lastFlipPrepareRequest = flipPrepareRequest
            uiView.prepareFrontFace(image: flipFrontImage)
        }

        if flipCancelRequest > 0,
           flipCancelRequest != context.coordinator.lastFlipCancelRequest {
            context.coordinator.lastFlipCancelRequest = flipCancelRequest
            uiView.cancelPreparedFlip(request: flipCancelRequest)
        }

        if flipRequest > 0, flipRequest != context.coordinator.lastFlipRequest {
            context.coordinator.lastFlipRequest = flipRequest
            uiView.startFlip(request: flipRequest, fromRight: flipFromRight)
        }
    }
}

struct CameraPreview_Previews: PreviewProvider {
    static var previews: some View {
        CameraPreview(session: AVCaptureSession())
            .frame(height: 300)
    }
}
