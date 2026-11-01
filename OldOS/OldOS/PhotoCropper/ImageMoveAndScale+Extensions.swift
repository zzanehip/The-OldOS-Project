import SwiftUI
import UIKit

struct OldOSWallpaperCropGeometry {
    let imageSize: CGSize
    let viewport: CGSize
    let zoom: CGFloat
    let translation: CGSize
    var isValid: Bool {
        [imageSize.width,imageSize.height,viewport.width,viewport.height,zoom,translation.width,translation.height]
            .allSatisfy(\.isFinite) && imageSize.width > 0 && imageSize.height > 0 && viewport.width > 0 && viewport.height > 0
    }
    var drawSize: CGSize {
        guard isValid else { return .zero }
        let scale = max(viewport.width/imageSize.width,viewport.height/imageSize.height)*min(4,max(1,zoom))
        return CGSize(width:imageSize.width*scale,height:imageSize.height*scale)
    }
    var clampedTranslation: CGSize {
        guard isValid else { return .zero }
        let x = max(0,(drawSize.width-viewport.width)/2), y = max(0,(drawSize.height-viewport.height)/2)
        return CGSize(width:min(x,max(-x,translation.width)),height:min(y,max(-y,translation.height)))
    }
    var imageRect: CGRect {
        CGRect(x:(viewport.width-drawSize.width)/2+clampedTranslation.width,
               y:(viewport.height-drawSize.height)/2+clampedTranslation.height,width:drawSize.width,height:drawSize.height)
    }
    func outputSize(scale:CGFloat,maximumEdge:CGFloat=2560) -> CGSize {
        guard isValid, scale.isFinite, scale > 0 else { return .zero }
        let factor = min(scale,maximumEdge/max(viewport.width,viewport.height))
        return CGSize(width:max(1,(viewport.width*factor).rounded()),height:max(1,(viewport.height*factor).rounded()))
    }
}

enum OldOSWallpaperSaveError: LocalizedError {
    case missingPhoto, encodingFailed
    var errorDescription: String? {
        switch self {
        case .missingPhoto: return "The photo could not be prepared. Please select it again."
        case .encodingFailed: return "The wallpaper could not be saved. Your existing wallpapers have not changed."
        }
    }
}

enum OldOSWallpaperStorage {
    static func commit(_ data:Data,targets:[String],defaults:UserDefaults = .standard) throws {
        guard !data.isEmpty, !targets.isEmpty, targets.allSatisfy({$0 == "Lock" || $0 == "Home"}) else { throw OldOSWallpaperSaveError.encodingFailed }
        for target in Set(targets) {
            defaults.set(data,forKey:"\(target)_Wallpaper")
            defaults.set(true,forKey:"Camera_Wallpaper_\(target)")
        }
        NotificationCenter.default.post(name:UserDefaults.didChangeNotification,object:defaults)
    }
}

extension ImageMoveAndScale {
    func processImage() {
        guard let image = inputImage ?? originalImage else { onComplete?(.failure(OldOSWallpaperSaveError.missingPhoto)); return }
        let geometry = OldOSWallpaperCropGeometry(imageSize:image.size,viewport:geometryProxy.size,
                                                  zoom:zoomAmount+currentAmount,translation:currentPosition)
        let size = geometry.outputSize(scale:UIScreen.main.scale)
        guard geometry.isValid, size.width > 0, size.height > 0 else { onComplete?(.failure(OldOSWallpaperSaveError.missingPhoto)); return }
        let token = UUID(); processingID = token
        let targets = to_set
        DispatchQueue.global(qos:.userInitiated).async {
            let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
            let renderer = UIGraphicsImageRenderer(size:size,format:format)
            let crop = geometry.imageRect
            let xScale = size.width/geometry.viewport.width, yScale = size.height/geometry.viewport.height
            let rendered = renderer.image { context in
                UIColor.black.setFill(); context.fill(CGRect(origin:.zero,size:size))
                image.draw(in:CGRect(x:crop.minX*xScale,y:crop.minY*yScale,width:crop.width*xScale,height:crop.height*yScale))
            }
            let data = rendered.jpegData(compressionQuality:0.95)
            DispatchQueue.main.async {
                guard processingID == token else { return }
                do {
                    guard let data, !data.isEmpty else { throw OldOSWallpaperSaveError.encodingFailed }
                    try OldOSWallpaperStorage.commit(data,targets:targets)
                    processedImage = rendered; onComplete?(.success(()))
                } catch { onComplete?(.failure(error)) }
            }
        }
    }
}
