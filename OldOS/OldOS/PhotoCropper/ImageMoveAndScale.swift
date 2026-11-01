import SwiftUI
import UIKit

public struct ImageMoveAndScale: View {
    @Binding public var originalImage: UIImage?
    @Binding public var originalPosition: CGSize?
    @Binding public var originalZoom: CGFloat?
    @Binding public var processedImage: UIImage?
    @Binding public var inputImage: UIImage?
    @Binding public var execute_process: Bool
    @Binding var to_set: [String]
    var geometryProxy: GeometryProxy
    var onComplete: ((Result<Void,Error>)->Void)? = nil
    @State var zoomAmount: CGFloat = 1
    @State var currentAmount: CGFloat = 0
    @State var currentPosition: CGSize = .zero
    @State var newPosition: CGSize = .zero
    @State var processingID = UUID()
    public var body: some View {
        let image = inputImage ?? originalImage
        let geometry = OldOSWallpaperCropGeometry(imageSize:image?.size ?? .zero,viewport:geometryProxy.size,
                                                  zoom:zoomAmount+currentAmount,translation:currentPosition)
        ZStack {
            Color.black
            if let image, geometry.isValid {
                Image(uiImage:image).resizable()
                    .frame(width:geometry.drawSize.width,height:geometry.drawSize.height)
                    .offset(geometry.clampedTranslation)
            }
        }.frame(width:geometryProxy.size.width,height:geometryProxy.size.height).clipped()
            .gesture(MagnificationGesture().onChanged { amount in
                guard !execute_process else { return }
                currentAmount = zoomAmount*(amount-1)
            }.onEnded { _ in
                guard !execute_process else { return }
                zoomAmount = min(4,max(1,zoomAmount+currentAmount)); currentAmount = 0; clampPosition()
            })
            .simultaneousGesture(DragGesture().onChanged { value in
                guard !execute_process else { return }
                currentPosition = CGSize(width:newPosition.width+value.translation.width,height:newPosition.height+value.translation.height)
            }.onEnded { _ in
                guard !execute_process else { return }
                clampPosition()
            })
            .simultaneousGesture(TapGesture(count:2).onEnded {
                guard !execute_process else { return }
                withAnimation(.easeInOut) { zoomAmount = 1; currentAmount = 0; currentPosition = .zero; newPosition = .zero }
            })
            .onAppear {
                zoomAmount = min(4,max(1,originalZoom ?? 1))
                currentPosition = originalPosition ?? .zero; clampPosition()
            }
            .onChange(of:execute_process) { execute in if execute { processImage() } }
            .onDisappear { processingID = UUID() }
    }
    private func clampPosition() {
        let geometry = OldOSWallpaperCropGeometry(imageSize:(inputImage ?? originalImage)?.size ?? .zero,
                                                  viewport:geometryProxy.size,zoom:zoomAmount,translation:currentPosition)
        currentPosition = geometry.clampedTranslation; newPosition = currentPosition
    }
}
