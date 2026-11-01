  
                               
          
  
                                            
  

import Foundation
import Photos
import UIKit
import CoreImage

class PhotoCaptureProcessor: NSObject {
    private(set) var requestedPhotoSettings: AVCapturePhotoSettings
    
    private let hdrEnabled: Bool
    private let keepNormalHDRPhoto: Bool
    private let willCapturePhotoAnimation: () -> Void

    private let didFinishProcessingPhotoAnimation: (Data?) -> Void
                                                                                 
                                                                              
    private var didSendFinishProcessingAnimation = false
    private var processedBracketData: [Data] = []
    private var normalHDRPhotoData: Data?
        
    lazy var context = CIContext()
    
    private let completionHandler: (PhotoCaptureProcessor) -> Void
    
    private let photoProcessingHandler: (Bool) -> Void
    
    var photoData: Data?
    
    private var maxPhotoProcessingTime: CMTime?
        
    init(with requestedPhotoSettings: AVCapturePhotoSettings,
         hdrEnabled: Bool = false,
         keepNormalHDRPhoto: Bool = false,
         willCapturePhotoAnimation: @escaping () -> Void,
         didFinishProcessingPhotoAnimation: @escaping (Data?) -> Void,
         completionHandler: @escaping (PhotoCaptureProcessor) -> Void,
         photoProcessingHandler: @escaping (Bool) -> Void) {
        self.requestedPhotoSettings = requestedPhotoSettings
        self.hdrEnabled = hdrEnabled
        self.keepNormalHDRPhoto = keepNormalHDRPhoto
        self.willCapturePhotoAnimation = willCapturePhotoAnimation
        self.didFinishProcessingPhotoAnimation = didFinishProcessingPhotoAnimation
        self.completionHandler = completionHandler
        self.photoProcessingHandler = photoProcessingHandler
    }
}

extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {
      
                                                                                     
       
    
                               
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        maxPhotoProcessingTime = resolvedSettings.photoProcessingTimeRange.start + resolvedSettings.photoProcessingTimeRange.duration
    }
    
                               
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("CAMERA PHOTO willCapture id=\(requestedPhotoSettings.uniqueID)")
        DispatchQueue.main.async {
            self.willCapturePhotoAnimation()
        }
        
        guard let maxPhotoProcessingTime = maxPhotoProcessingTime else {
            return
        }
        
                                                                
        let oneSecond = CMTime(seconds: 2, preferredTimescale: 1)
        if maxPhotoProcessingTime > oneSecond {
            DispatchQueue.main.async {
                self.photoProcessingHandler(true)
            }
        }
    }
    
                                       
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("CAMERA PHOTO didProcess id=\(requestedPhotoSettings.uniqueID) error=\(String(describing: error))")
        if let error = error {
            print("Error capturing photo: \(error)")
            if !hdrEnabled { photoData = nil }
        } else if let data = photo.fileDataRepresentation() {
            if hdrEnabled {
                processedBracketData.append(data)
            } else {
                photoData = data
            }
        }

        DispatchQueue.main.async {
            self.photoProcessingHandler(false)
            if !self.hdrEnabled {
                self.sendFinishProcessingAnimationIfNeeded()
            }
        }
    }

    private func buildHDRResultIfNeeded() {
        guard hdrEnabled, photoData == nil, !processedBracketData.isEmpty else { return }

                                                                                    
                                                                                    
                                                                    
        let middleIndex = min(processedBracketData.count - 1, processedBracketData.count / 2)
        normalHDRPhotoData = processedBracketData[middleIndex]

        guard processedBracketData.count >= 3,
              let dark = CIImage(data: processedBracketData[0], options: [.applyOrientationProperty: true]),
              let normal = CIImage(data: processedBracketData[middleIndex], options: [.applyOrientationProperty: true]),
              let bright = CIImage(data: processedBracketData[processedBracketData.count - 1], options: [.applyOrientationProperty: true]) else {
            photoData = normalHDRPhotoData
            return
        }

        let extent = normal.extent
        let darkImage = dark.cropped(to: extent)
        let normalImage = normal.cropped(to: extent)
        let brightImage = bright.cropped(to: extent)

        func weighted(_ image: CIImage, _ weight: CGFloat) -> CIImage {
            image.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: weight, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: weight, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: weight, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
            ])
        }

        let weightedDark = weighted(darkImage, 0.28)
        let weightedNormal = weighted(normalImage, 0.44)
        let weightedBright = weighted(brightImage, 0.28)
        let firstPass = weightedDark.applyingFilter("CIAdditionCompositing", parameters: [kCIInputBackgroundImageKey: weightedNormal])
        let merged = weightedBright
            .applyingFilter("CIAdditionCompositing", parameters: [kCIInputBackgroundImageKey: firstPass])
            .applyingFilter("CIHighlightShadowAdjust", parameters: ["inputHighlightAmount": 0.78, "inputShadowAmount": 0.32])

        guard let cgImage = context.createCGImage(merged, from: extent),
              let jpeg = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.96) else {
            photoData = normalHDRPhotoData
            return
        }
        photoData = jpeg
    }

                                                                                  
    private func sendFinishProcessingAnimationIfNeeded() {
        guard !didSendFinishProcessingAnimation else { return }
        didSendFinishProcessingAnimation = true
        print("CAMERA PHOTO deliverUI id=\(requestedPhotoSettings.uniqueID) bytes=\(photoData?.count ?? 0)")
        didFinishProcessingPhotoAnimation(photoData)
    }

    fileprivate func saveToPhotoLibrary(_ photoData: Data) {
                                                      
        
        let finishSave: (PHAuthorizationStatus) -> Void = { status in
                                                                          
                                                                              
                                                                      
            var maySave = status == .authorized
            if #available(iOS 14, *) {
                maySave = maySave || status == .limited
            }
            if maySave {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    options.uniformTypeIdentifier = self.requestedPhotoSettings.processedFileType.map { $0.rawValue }
                    creationRequest.addResource(with: .photo, data: photoData, options: options)

                    if self.hdrEnabled, self.keepNormalHDRPhoto, let normalData = self.normalHDRPhotoData {
                        let normalRequest = PHAssetCreationRequest.forAsset()
                        let normalOptions = PHAssetResourceCreationOptions()
                        normalOptions.uniformTypeIdentifier = self.requestedPhotoSettings.processedFileType.map { $0.rawValue }
                        normalRequest.addResource(with: .photo, data: normalData, options: normalOptions)
                    }

                }, completionHandler: { success, error in
                    if let error = error {
                        print("CAMERA PHOTO library save failed: \(error)")
                    } else {
                        print("CAMERA PHOTO library save success=\(success)")
                    }
                    
                                                                                  
                                                                                 
                                                               
                }
                )
            } else {
                print("CAMERA PHOTO save denied by Photo Library authorization")
            }
        }
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly, handler: finishSave)
        } else {
            PHPhotoLibrary.requestAuthorization(finishSave)
        }
    }
    
                               
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        print("CAMERA PHOTO terminal id=\(requestedPhotoSettings.uniqueID) error=\(String(describing: error))")
        if hdrEnabled && error == nil {
            buildHDRResultIfNeeded()
        }

                                                                              
                                                                                
                                                                               
                                                                           
        DispatchQueue.main.async {
            self.photoProcessingHandler(false)
            self.sendFinishProcessingAnimationIfNeeded()
            self.completionHandler(self)
        }

        if error == nil, let data = photoData {
            saveToPhotoLibrary(data)
        } else {
            print("CAMERA PHOTO no image to save id=\(requestedPhotoSettings.uniqueID)")
        }
    }
}
