import SwiftUI

public struct ImageMoveAndScale: View {
    
    @Environment(\.presentationMode) public var presentationMode
    @Environment(\.verticalSizeClass) public var sizeClass
    
    @State  public var isShowingImagePicker = false
    
    @Binding public var originalImage: UIImage?
    @Binding public var originalPosition: CGSize?
    @Binding public var originalZoom: CGFloat?
    
    @Binding public var processedImage: UIImage?
    
    @Binding public var inputImage: UIImage?
    @State public var inputImageAspectRatio: CGFloat = 0.0
    
    @Binding public var execute_process: Bool
    @Binding var to_set:[String]
    
    @State public var displayImage: UIImage?
    @State public var displayW: CGFloat = 0.0
    @State public var displayH: CGFloat = 0.0
    
    @State public var currentAmount: CGFloat = 0
    @State public var zoomAmount: CGFloat = 1.0
    @State public var currentPosition: CGSize = .zero
    @State public var newPosition: CGSize = .zero
    @State public var horizontalOffset: CGFloat = 0.0
    @State public var verticalOffset: CGFloat = 0.0
    var geometryProxy: GeometryProxy
    let inset: CGFloat = 0
    
    public var body: some View {
        GeometryReader {geometry in
        ZStack {
            ZStack {
                Color.black.opacity(0.8)
                Image(uiImage: displayImage ?? inputImage ?? UIImage())
                        .resizable()
                        .scaleEffect(zoomAmount + currentAmount)
                        .scaledToFill()
                        .aspectRatio(contentMode: .fit)
                        .offset(x: self.currentPosition.width, y: self.currentPosition.height)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                
            }
        }
        .edgesIgnoringSafeArea(.all)
        
        .gesture(
            MagnificationGesture()
                .onChanged { amount in
                    if !execute_process {
                    self.currentAmount = amount - 1
                    }
                }
                .onEnded { amount in
                    if !execute_process {
                    self.zoomAmount += self.currentAmount
                    if zoomAmount > 4.0 {
                        withAnimation {
                            zoomAmount = 4.0
                        }
                    }
                    self.currentAmount = 0
                    withAnimation {
                        repositionImage()
                    }
                    }
                }
        )
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    if !execute_process {
                    self.currentPosition = CGSize(width: value.translation.width + self.newPosition.width, height: value.translation.height + self.newPosition.height)
                    }
                }
                .onEnded { value in
                    if !execute_process {
                    self.currentPosition = CGSize(width: value.translation.width + self.newPosition.width, height: value.translation.height + self.newPosition.height)
                    self.newPosition = self.currentPosition
                    withAnimation {
                        repositionImage()
                    }
                    }
                }
        )
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded(  { if !execute_process {resetImageOriginAndScale() } })
        )
        .onAppear(perform: setCurrentImage ).onAppear() {
            loadImage()
        }
        }.onChange(of: execute_process, perform: {_ in
            processImage()
        })
}
    
}

import UIKit

func croppedImage(from image: UIImage, croppedTo rect: CGRect) -> UIImage {
    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()
    let drawRect = CGRect(x: -rect.origin.x, y: -rect.origin.y, width: image.size.width, height: image.size.height)
    let rect = CGRect(x: 0, y: 0, width: rect.size.width+1, height: rect.size.height+1)
    context?.clip(to: CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height))
    UIColor.black.setFill()
    context?.fill(rect)
    image.draw(in: drawRect)
    let subImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return subImage!
}

