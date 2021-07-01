import SwiftUI

extension ImageMoveAndScale {
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        let w = inputImage.size.width
        let h = inputImage.size.height
        displayImage = inputImage
        inputImageAspectRatio = w / h
        resetImageOriginAndScale()
    }
    
    func setCurrentImage() {
        guard let currentImage = originalImage else { return }
        let w = currentImage.size.width
        let h = currentImage.size.height
        inputImage = currentImage
        inputImageAspectRatio = w / h
        currentPosition = originalPosition!
        newPosition = originalPosition!
        zoomAmount = originalZoom!
        displayImage = currentImage
        repositionImage()
    }
        
    private func getAspect() -> CGFloat {
        let screenAspectRatio = geometryProxy.size.width / geometryProxy.size.height
        return screenAspectRatio
    }
    
    func resetImageOriginAndScale() {
        let screenAspect: CGFloat = getAspect()

        withAnimation(.easeInOut){
            if inputImageAspectRatio >= screenAspect {
                displayW = geometryProxy.size.width
                displayH = displayW / inputImageAspectRatio
            } else {
                displayH = geometryProxy.size.height
                displayW = displayH * inputImageAspectRatio
            }
            currentAmount = 0
            zoomAmount = 1
            currentPosition = .zero
            newPosition = .zero
        }
    }
    
    func repositionImage() {
        
        ///Setting the display width and height so the imputImage fits the screen
        ///orientation.
        let screenAspect: CGFloat = getAspect()
        let diameter = min(geometryProxy.size.width, geometryProxy.size.height)
        
        if screenAspect <= 1.0 {
            if inputImageAspectRatio > screenAspect {
                displayW = diameter * zoomAmount
                displayH = displayW / inputImageAspectRatio
            } else {
                displayH = geometryProxy.size.height * zoomAmount
                displayW = displayH * inputImageAspectRatio
            }
        } else {
            if inputImageAspectRatio < screenAspect {
                displayH = diameter * zoomAmount
                displayW = displayH * inputImageAspectRatio
            } else {
                displayW = geometryProxy.size.width * zoomAmount
                displayH = displayW / inputImageAspectRatio
            }
        }
        
        horizontalOffset = (displayW - diameter ) / 2
        verticalOffset = ( displayH - diameter) / 2
        if zoomAmount > 4.0 {
                zoomAmount = 4.0
        }
        
        let adjust: CGFloat = 4.0
        if displayH >= diameter {
            if newPosition.height > verticalOffset {
                    newPosition = CGSize(width: newPosition.width, height: verticalOffset - adjust + inset)
                    currentPosition = CGSize(width: newPosition.width, height: verticalOffset - adjust + inset)
            }
            
            if newPosition.height < ( verticalOffset * -1) {
                    newPosition = CGSize(width: newPosition.width, height: ( verticalOffset * -1) - adjust - inset)
                    currentPosition = CGSize(width: newPosition.width, height: ( verticalOffset * -1) - adjust - inset)
            }
            
        } else {
                newPosition = CGSize(width: newPosition.width, height: 0)
                currentPosition = CGSize(width: newPosition.width, height: 0)
        }
        
        if displayW >= diameter {
            if newPosition.width > horizontalOffset {
                    newPosition = CGSize(width: horizontalOffset + inset, height: newPosition.height)
                    currentPosition = CGSize(width: horizontalOffset + inset, height: currentPosition.height)
            }
            
            if newPosition.width < ( horizontalOffset * -1) {
                    newPosition = CGSize(width: ( horizontalOffset * -1) - inset, height: newPosition.height)
                    currentPosition = CGSize(width: ( horizontalOffset * -1) - inset, height: currentPosition.height)

            }
            
        } else {
                newPosition = CGSize(width: 0, height: newPosition.height)
                currentPosition = CGSize(width: 0, height: newPosition.height)
        }
        
        if displayW < diameter - inset && displayH < diameter - inset {
            resetImageOriginAndScale()
        }
    }
    
    
    func processImage() {
        
        let scalew = (inputImage?.size.width)! / displayW
        let scaleh = (inputImage?.size.height)! / displayH
        let originAdjustment = min(geometryProxy.size.width, geometryProxy.size.height)
        let diameter_w = ( geometryProxy.size.width - inset * 2 ) * scalew
        let diameter_h = ( geometryProxy.size.height - inset * 2 ) * scaleh
        let xPos = ( ( ( displayW - originAdjustment ) / 2 ) + inset + ( currentPosition.width * -1 ) ) * scalew
        let yPos = ( ( ( displayH - geometryProxy.size.height ) / 2 ) + inset + ( currentPosition.height * -1 ) ) * scaleh
        processedImage = croppedImage(from: inputImage!, croppedTo: CGRect(x: xPos, y: yPos, width: diameter_w, height: diameter_h)) //maybe dw, dh
        let image_jpeg_data = processedImage?.jpegData(compressionQuality: 1.0)
        if to_set.contains("Lock") {
        UserDefaults.standard.set(image_jpeg_data, forKey: "Lock_Wallpaper")
        UserDefaults.standard.set(true, forKey: "Camera_Wallpaper_Lock")
        }
        if to_set.contains("Home") {
        UserDefaults.standard.set(image_jpeg_data, forKey: "Home_Wallpaper")
        UserDefaults.standard.set(true, forKey: "Camera_Wallpaper_Home")
        }
    }
}
