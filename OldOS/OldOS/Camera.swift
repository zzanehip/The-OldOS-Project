  
                
         
  
                                         
  

import SwiftUI
import Camera_SwiftUI
import Combine
import AVKit
import Photos
import UIKit
import QuartzCore
import MetalKit

struct Camera: View {
    @State var camera_state: camera_state = .photo
    @State var is_recording: Bool = false
    @State var recording_timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @StateObject var model = CameraModel()
    
    @State var currentZoomFactor: CGFloat = 1.0
    @State private var livePreviewOpacity: Double = 1.0
    @State private var pendingCameraState: camera_state?
    @Binding var instant_multitasking_change: Bool
    var body: some View {
        GeometryReader{ geometry in
            ZStack {
                CameraPreview(session: model.session,
                              flipPrepareRequest: model.cameraFlipPrepareRequest,
                              flipRequest: model.cameraFlipRequest,
                              flipCancelRequest: model.cameraFlipCancelRequest,
                              flipFromRight: model.cameraFlipFromRight,
                              flipFrontImage: model.cameraFlipFrontImage)
                    .opacity(livePreviewOpacity)
                    .onAppear {
                        model.configure()
                    }

                                                                                      
                                                                                       
                                                                               
                if let capturedImage = model.capturedPreviewImage,
                   model.capturedPreviewRequest > model.captureBounceRequest {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width,
                               height: max(0.0, geometry.size.height - 60.0))
                        .clipped()
                        .frame(width: geometry.size.width,
                               height: geometry.size.height,
                               alignment: .top)
                        .allowsHitTesting(false)
                }

                                                                                  
                                                                                 
                                                                                  
                                                    
                VStack(spacing: 0) {
                    camera_header(model: model, camera_state: $camera_state, is_recording: $is_recording, recording_timer: $recording_timer).padding(.top, 10)
                    Spacer()
                }

                OldOSCameraIrisOverlay(closeRequest: model.irisCloseRequest,
                                         openRequest: model.irisOpenRequest,
                                         startsClosed: true,
                                         closeCompletion: { request in
                    guard let target = pendingCameraState,
                          model.consumeModeSwitchClose(request) else { return }
                    camera_state = target
                    pendingCameraState = nil
                    model.openIrisAfterModeSwitch()
                },
                                         openCompletion: { request in
                    model.irisDidFinishOpening(request)
                })
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    Spacer()
                    camera_tool_bar(camera_state: $camera_state,
                                    is_recording: $is_recording,
                                    recording_timer: $recording_timer,
                                    model: model,
                                    instant_multitasking_change: $instant_multitasking_change,
                                    requestCameraState: { target in
                        guard target != camera_state, pendingCameraState == nil else { return }
                        pendingCameraState = target
                        model.closeIrisForModeSwitch()
                    })
                        .frame(height: 60)
                }

                                                                                  
                                                                                  
                                                                                    
                OldOSCameraCaptureBounceOverlay(image: model.capturedPreviewImage,
                                                request: model.captureBounceRequest,
                                                onFinished: { request in
                    model.captureBounceDidFinish(request: request)
                })
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .allowsHitTesting(false)
                
            }
            .alert(isPresented: $model.showAlertError) {
                Alert(title: Text(model.alertError?.title ?? "Camera Error"),
                      message: Text(model.alertError?.message ?? "Unable to start camera."),
                      dismissButton: .default(Text(model.alertError?.primaryButtonTitle ?? "OK"),
                                              action: { model.alertError?.primaryAction?() }))
            }
            .onChange(of: model.captureBounceRequest) { request in
                guard request > 0 else { return }

                                                                                   
                                                                                 
                                                                                 
                                                                  
                livePreviewOpacity = 0.0
                DispatchQueue.main.async {
                    withAnimation(.linear(duration: 0.4)) {
                        livePreviewOpacity = 1.0
                    }
                }
            }
        }.onDisappear() {
            model.end_session()
        }
    }
}

                                           
                                      
                  
       
   

enum camera_state {
    case photo, video
}
struct camera_flipper: View {
    @Binding var state: camera_state
    let requestState: (camera_state) -> Void
    @State var offset: CGPoint = CGPoint(0,0)
    let gradient = LinearGradient([(Color(red: 103/255, green: 104/255, blue: 107/255), location: 0), (Color(red: 141/255, green: 143/255, blue: 148/255), location: 0.65)], to: .bottom)
    var body: some View {
        ZStack {
            GeometryReader {geometry in
                VStack(spacing: 1) {
                    HStack {
                        Image("PLCameraSwitchIcon")
                        Spacer()
                        Image("PLVideo")
                    }
                    ZStack {
                        Button(action:{}){}.frame(width: geometry.size.width, height: 15).ps_innerShadow(.capsule(gradient), radius:0.8, offset: CGPoint(0, 2/3), intensity: 0.45).shadow(color: Color.white.opacity(0.48), radius: 0, x: 0, y: 0.8).strokeCapsule(Color(red: 73/255, green: 74/255, blue: 76/255), lineWidth: 0.33)
                        Capsule().fill(LinearGradient([(Color(red: 227/255, green: 229/255, blue: 232/255)), (Color(red: 119/255, green: 121/255, blue: 126/255))], from: .top, to:.bottom)).shadow(color: Color.black.opacity(0.25), radius: 1, x: offset.x > geometry.size.width/2 ? -1 : 1, y: 1).strokeCapsule(Color(red: 114/255, green: 113/255, blue: 113/255), lineWidth: 0.7).frame(width: geometry.size.width/3, height: 14) .offset(x: -geometry.size.width/2 + offset.x + geometry.size.width/6, y: 0)
                    }
                } .simultaneousGesture(DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            if self.offset.x >= 0 && self.offset.x <= geometry.size.width - geometry.size.width/3 {
                                                self.offset = CGPoint(value.translation.asCGPoint.x + value.startLocation.x, 0)
                                                if self.offset.x < 0 {
                                                    self.offset.x = 0
                                                }
                                                if self.offset.x > geometry.size.width - geometry.size.width/3 {
                                                    self.offset.x = geometry.size.width - geometry.size.width/3
                                                }
                                            }
                                            print(offset.x, "moving")
                                        }.onEnded { value in
                                            if self.offset.x > geometry.size.width/2 {
                                                withAnimation(.linear(duration: 0.1)) {
                                                    self.offset.x = geometry.size.width - geometry.size.width/3
                                                    requestState(.video)
                                                }
                                            } else {
                                                withAnimation(.linear(duration: 0.1)) {
                                                    self.offset.x = 0
                                                    requestState(.photo)
                                                }
                                            }
                                        })
            }
        }
    }
}

struct camera_header: View {
    @StateObject var model: CameraModel
    @Binding var camera_state: camera_state
    @Binding var is_recording: Bool
    @Binding var recording_timer: Publishers.Autoconnect<Timer.TimerPublisher>
    @State var current_time = TimeInterval(0)
    @State private var flashExpanded = false

    private var currentFlashMode: AVCaptureDevice.FlashMode {
        camera_state == .photo ? model.flashMode : model.videoFlashMode
    }

    private var flashModes: [AVCaptureDevice.FlashMode] {
        camera_state == .photo ? [.off, .auto, .on] : [.off, .on]
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack {
                if model.isFlashAvailable {
                    OldOSCameraFlashControl(selection: currentFlashMode,
                                            modes: flashModes,
                                            expanded: $flashExpanded,
                                            onSelect: { mode in
                        model.setFlashMode(mode, cameraState: camera_state)
                    })
                    .padding(.leading, 8)
                } else {
                    Spacer().frame(width: 88)
                }

                Spacer()

                if is_recording == true {
                    ZStack {
                        RoundedRectangle(cornerRadius:6)
                            .fill(Color.black.opacity(0.35))
                            .strokeRoundedRectangle(6, Color.white.opacity(0.25), lineWidth: 0.95)
                            .frame(width: 95, height: 64/120*55)
                        Text(String(format: "%02d:%02d:%02d", Int(current_time) / 3600 , (Int(current_time) % 3600)/60, (Int(current_time) % 3600) % 60))
                            .font(.custom("Helvetica Neue Regular", fixedSize: 19))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 8)
                } else {
                    Button(action: {
                        flashExpanded = false
                        model.flipCamera()
                    }) {
                        Image("PLCameraToggle-2x")
                            .resizable()
                            .frame(width: 65, height: 65/120*62)
                            .padding(.trailing, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            if camera_state == .photo && model.isFlashAvailable && !is_recording && !flashExpanded {
                HStack {
                    Spacer()
                    Button(action: {
                        model.toggleHDR()
                    }) {
                        camera_capsule(content:
                            Text(model.hdrEnabled ? "HDR On" : "HDR Off")
                                .font(.custom("Helvetica Neue Bold", fixedSize: 14))
                                .foregroundColor(Color(red: 21/255, green: 21/255, blue: 21/255))
                                .opacity(0.85)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 95, height: 64/120*62)
                    Spacer()
                }
            }
        }
        .onReceive(recording_timer, perform: {_ in
            if is_recording == false {
                current_time = TimeInterval(0)
            } else {
                current_time = current_time + TimeInterval(recording_timer.upstream.interval)
            }
            print(current_time)
        })
        .onChange(of: is_recording, perform: {_ in
            if is_recording == false {
                current_time = TimeInterval(0)
            }
            flashExpanded = false
        })
        .onChange(of: camera_state, perform: { state in
            flashExpanded = false
            model.cameraModeDidChange(state)
        })
    }
}

private struct OldOSCameraFlashControl: View {
    let selection: AVCaptureDevice.FlashMode
    let modes: [AVCaptureDevice.FlashMode]
    @Binding var expanded: Bool
    let onSelect: (AVCaptureDevice.FlashMode) -> Void
    @State private var collapsingSelection: AVCaptureDevice.FlashMode?

    private let collapsedWidth: CGFloat = 80
    private let controlHeight: CGFloat = 31.5
    private let leftCapWidth: CGFloat = 24.5

    private var expandedWidth: CGFloat {
        modes.count == 3 ? 176 : 119
    }

    private var controlWidth: CGFloat {
        expanded ? expandedWidth : collapsedWidth
    }

    private var dividerPositions: [CGFloat] {
        modes.count == 3 ? [63, 119] : [63]
    }

    var body: some View {
        ZStack(alignment: .leading) {
            flashBackground(width: controlWidth)

            expandedContent
                .mask(
                    Rectangle()
                        .frame(width: controlWidth, height: controlHeight, alignment: .leading)
                        .offset(x: controlWidth / 2 - expandedWidth / 2)
                )

            interactiveLayer
        }
        .frame(width: controlWidth, height: controlHeight, alignment: .leading)
        .clipped()
    }

    private func flashBackground(width: CGFloat) -> some View {
        HStack(spacing: 0) {
            Image("PLCameraFlashBackgroundLeft")
                .resizable()
                .frame(width: leftCapWidth, height: controlHeight)
            Image("PLCameraFlashBackgroundRight")
                .resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 15.5), resizingMode: .tile)
                .frame(width: max(width - leftCapWidth, 0), height: controlHeight)
        }
        .frame(width: width, height: controlHeight, alignment: .leading)
    }

    private var expandedContent: some View {
        ZStack(alignment: .leading) {
            ForEach(Array(dividerPositions.enumerated()), id: \.offset) { _, x in
                Rectangle()
                    .fill(Color.black.opacity(0.55))
                    .frame(width: 1, height: controlHeight)
                    .offset(x: x)
                    .opacity(expanded ? 1 : 0)
            }

            ForEach(modes, id: \.self) { mode in
                let activeMode = collapsingSelection ?? selection
                Text(title(for: mode))
                    .font(.custom("Helvetica Neue Bold", fixedSize: 14))
                    .foregroundColor(Color(red: 21/255, green: 21/255, blue: 21/255))
                    .opacity(expanded ? 0.85 : (mode == activeMode ? 0.85 : 0))
                    .position(x: expanded ? expandedCenterX(for: mode) : (mode == activeMode ? collapsedCenterX(for: mode) : expandedCenterX(for: mode)),
                              y: 14.5)
            }
        }
        .frame(width: expandedWidth, height: controlHeight, alignment: .leading)
        .animation(.easeInOut(duration: 0.15), value: expanded)
    }

    @ViewBuilder
    private var interactiveLayer: some View {
        if expanded {
            HStack(spacing: 0) {
                ForEach(Array(segmentWidths().enumerated()), id: \.offset) { index, width in
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: width, height: controlHeight)
                        .onTapGesture {
                            let mode = modes[index]
                            collapsingSelection = mode
                            onSelect(mode)
                            withAnimation(.easeInOut(duration: 0.15)) {
                                expanded = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                                if collapsingSelection == mode {
                                    collapsingSelection = nil
                                }
                            }
                        }
                }
            }
            .frame(width: expandedWidth, height: controlHeight, alignment: .leading)
        } else {
            Color.clear
                .contentShape(Rectangle())
                .frame(width: collapsedWidth, height: controlHeight)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        expanded = true
                    }
                }
        }
    }

    private func title(for mode: AVCaptureDevice.FlashMode) -> String {
        switch mode {
        case .off:
            return "Off"
        case .auto:
            return "Auto"
        case .on:
            return "On"
        @unknown default:
            return "Off"
        }
    }

    private func expandedCenterX(for mode: AVCaptureDevice.FlashMode) -> CGFloat {
        if modes.count == 2 {
            switch mode {
            case .off:
                return 47
            case .on:
                return 91
            case .auto:
                return 91
            @unknown default:
                return 43
            }
        }

        switch mode {
        case .off:
            return 47
        case .auto:
            return 91
        case .on:
            return 147.5
        @unknown default:
            return 43
        }
    }

    private func collapsedCenterX(for mode: AVCaptureDevice.FlashMode) -> CGFloat {
        return 47.0
    }

    private func segmentWidths() -> [CGFloat] {
        let stops = [0] + dividerPositions + [expandedWidth]
        return zip(stops, stops.dropFirst()).map { $1 - $0 }
    }
}

struct camera_capsule<Content: View>: View {
    var content: Content
    var body: some View {
        ZStack {
            Capsule().fill(Color(red: 255/255, green: 255/255, blue: 255/255).opacity(0.25*0.8)).strokeCapsule(Color(red: 21/255, green: 21/255, blue: 21/255).opacity(0.85), lineWidth: 0.95)
            content
        }
    }
}
struct camera_tool_bar: View {
    @Binding var camera_state: camera_state
    @Binding var is_recording: Bool
    @Binding var recording_timer: Publishers.Autoconnect<Timer.TimerPublisher>
    @State var flash: Bool = false
    @State var c_image: UIImage?
    @State var thumbnailOpacity: Double = 1.0
    @State var audioPlayer: AVAudioPlayer!
    @StateObject var model: CameraModel
    @Binding var instant_multitasking_change: Bool
    let requestCameraState: (camera_state) -> Void
    private let gradient = LinearGradient([Color.clear, Color.clear], to: .trailing)
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient([(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 0), (color: Color(red: 123/255, green: 125/255, blue: 131/255), location: 1)], from: .top, to: .bottom)
                HStack {
                    HStack {
                        if c_image != nil {
                           Image(uiImage: (c_image ?? UIImage(named: "PLCameraPreviewPlaceholder"))!).resizedToFill(82/2).ps_innerShadow(.roundedRectangle(3), radius:0.8, offset: CGPoint(0, 2/3), intensity: 0.65).clipShape(RoundedRectangle(3)).shadow(color: Color.white.opacity(0.48), radius: 0, x: 0, y: 0.8).strokeRoundedRectangle(3, Color(red: 73/255, green: 74/255, blue: 76/255), lineWidth: 0.33).opacity(thumbnailOpacity)
                        }
                        else {
                        Image("PLCameraPreviewPlaceholder").resizedToFill(82/2).ps_innerShadow(.roundedRectangle(3), radius:0.8, offset: CGPoint(0, 2/3), intensity: 0.65).clipShape(RoundedRectangle(3)).shadow(color: Color.white.opacity(0.48), radius: 0, x: 0, y: 0.8).strokeRoundedRectangle(3, Color(red: 73/255, green: 74/255, blue: 76/255), lineWidth: 0.33).opacity(thumbnailOpacity)
                        }
                        Spacer()
                    }.frame(width: geometry.size.width/4.5).padding(.leading, 8)
                    Spacer()
                    Button(action: {
                        if camera_state == .photo {
                            model.capturePhoto()
                        }
                        if camera_state == .video {
                            is_recording.toggle()
                            model.record()
                            if is_recording {
                                playSounds("begin_video_record.caf")
                                recording_timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                playSounds("end_video_record.caf")
                                }
                                recording_timer.upstream.connect().cancel()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    LastPhotoRetriever().queryLastPhoto(resizeTo: nil) {photo in
                                        c_image = photo
                                    }
                                }
                            }
                        }
                    }) {
                    ZStack {
                        Image("PLCameraButtonSilver").frame(width: geometry.size.width/3.25, height: 82/2)
                        Image(camera_state == .photo ? "PLCameraButtonIcon" : (is_recording == true && flash == true) ? "PLCameraButtonRecordOn" :  "PLCameraButtonRecordOff").animation(instant_multitasking_change == true ? .default : .none).onReceive(timer, perform: {_ in
                            flash.toggle()
                        })
                    }
                    }
                    Spacer()
                    camera_flipper(state: $camera_state, requestState: requestCameraState).frame(width:geometry.size.width/4.75, height: 82/2).padding(.trailing, 8)
                }
            }
            .onAppear() {
                LastPhotoRetriever().queryLastPhoto(resizeTo: nil) {photo in
                    c_image = photo
                }
            }
            .onChange(of: model.captureBounceRequest) { request in
                guard request > 0 else { return }

                                                                                  
                                                                                  
                                                                                
                                                             
                thumbnailOpacity = 1.0
            }
            .onChange(of: model.captureWellUpdateRequest) { request in
                guard request > 0 else { return }
                if let image = model.finalThumbnailImage {
                    c_image = image
                }
                thumbnailOpacity = 1.0
            }
        }
        
    }
    func playSounds(_ soundFileName : String) {
        guard let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: nil) else {
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
        } catch {
            print(error.localizedDescription)
        }
        audioPlayer.play()
    }
}

struct LastPhotoRetriever {
    func queryLastPhoto(resizeTo size: CGSize?, queryCallback:  @escaping ((UIImage?) -> Void)) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        fetchOptions.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d",
                                             PHAssetMediaType.image.rawValue,
                                             PHAssetMediaType.video.rawValue)
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        if let asset = fetchResult.firstObject {
                let manager = PHImageManager.default()
                let targetSize = size == nil ? CGSize(width: asset.pixelWidth, height: asset.pixelHeight) : size!
                manager.requestImage(for: asset,
                    targetSize: targetSize,
                    contentMode: .aspectFit,
                    options: nil,
                    resultHandler: { image, info in

                    queryCallback(image)
                })
        }
    }
}

final class CameraModel: ObservableObject {
    private let service = CameraService()
    
    @Published var photo: Photo!
    
    @Published var showAlertError = false
    
    @Published var isFlashOn = false
    @Published var flashMode: AVCaptureDevice.FlashMode = .auto
    @Published var videoFlashMode: AVCaptureDevice.FlashMode = .off
    @Published var hdrEnabled = false
    @Published var isFlashAvailable = true
    
    @Published var willCapturePhoto = false

                                                                         
                                                                
    @Published var irisCloseRequest = 0
    @Published var irisOpenRequest = 0
    private var modeSwitchCloseRequest: Int?

                                                                            
                                                                            
                                                  
    @Published var cameraFlipPrepareRequest = 0
    @Published var cameraFlipRequest = 0
    @Published var cameraFlipCancelRequest = 0
    @Published var cameraFlipFromRight = true
    @Published var cameraFlipFrontImage: UIImage?
    private var cameraFlipSwitchInFlight = 0

                                                                               
                                                                                   
                                                                                  
    @Published var capturedPreviewImage: UIImage?
    @Published var capturedPreviewRequest = 0
    @Published var captureBounceRequest = 0
                                                                            
                                                                     
    private var completedIrisOpenRequest = 0
    private var photoIrisWaitingToOpen = false
                                                                               
                                                                                 
                                                                                 
                                                                           
    private var lastServiceIrisCloseRequest = 0
    private var lastServiceIrisOpenRequest = 0
    @Published var captureWellUpdateRequest = 0
    @Published var finalThumbnailImage: UIImage?
    
    var alertError: AlertError!
    
    var session: AVCaptureSession
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        self.session = service.session
        
        service.$photo.sink { [weak self] (photo) in
            guard let pic = photo else { return }
            self?.photo = pic
        }
        .store(in: &self.subscriptions)
        
        service.$shouldShowAlertView.sink { [weak self] (val) in
            self?.alertError = self?.service.alertError
            self?.showAlertError = val
        }
        .store(in: &self.subscriptions)
        
        service.$flashMode.sink { [weak self] (mode) in
            self?.flashMode = mode
            self?.isFlashOn = mode == .on
        }
        .store(in: &self.subscriptions)

        service.$videoFlashMode.sink { [weak self] mode in
            self?.videoFlashMode = mode
        }
        .store(in: &self.subscriptions)

        service.$hdrEnabled.sink { [weak self] enabled in
            self?.hdrEnabled = enabled
        }
        .store(in: &self.subscriptions)

        service.$isFlashAvailable.sink { [weak self] available in
            self?.isFlashAvailable = available
        }
        .store(in: &self.subscriptions)
        
        service.$willCapturePhoto.sink { [weak self] (val) in
            self?.willCapturePhoto = val
        }
        .store(in: &self.subscriptions)

        service.$irisCloseRequest.sink { [weak self] value in
            guard let self = self, value > self.lastServiceIrisCloseRequest else { return }
            self.lastServiceIrisCloseRequest = value
            self.photoIrisWaitingToOpen = true
            self.irisCloseRequest += 1
        }
        .store(in: &self.subscriptions)

        service.$irisOpenRequest.sink { [weak self] value in
            guard let self = self, value > self.lastServiceIrisOpenRequest else { return }
            self.lastServiceIrisOpenRequest = value
            self.photoIrisWaitingToOpen = false
            self.irisOpenRequest += 1
        }
        .store(in: &self.subscriptions)

        service.$sessionDidStartRequest.sink { [weak self] value in
            guard value > 0 else { return }
                                                                                   
                                                                   
            self?.irisOpenRequest += 1
        }
        .store(in: &self.subscriptions)

        service.$capturedPreviewPhoto.sink { [weak self] photo in
            guard let self = self, let photo = photo else { return }
            guard let image = UIImage(data: photo.originalData) else {
                print("CAMERA PHOTO could not decode image for thumbnail")
                return
            }
            self.capturedPreviewImage = image
            self.capturedPreviewRequest += 1
            if !self.photoIrisWaitingToOpen,
               self.completedIrisOpenRequest == self.irisOpenRequest,
               self.irisOpenRequest > 0 {
                                                                              
                                                                               
                self.captureBounceRequest = self.capturedPreviewRequest
            }
        }
        .store(in: &self.subscriptions)

        service.$capturedVideoPreviewPhoto.sink { [weak self] photo in
            guard let self = self, let photo = photo,
                  let image = UIImage(data: photo.originalData) else { return }
            self.capturedPreviewImage = image
            self.capturedPreviewRequest += 1
                                                                                 
                                                                                   
            self.captureBounceRequest = self.capturedPreviewRequest
        }
        .store(in: &self.subscriptions)

        NotificationCenter.default.publisher(for: .init("OldOSCameraFlipAnimationDidFinish"))
            .sink { [weak self] notification in
                guard let self = self,
                      let request = notification.userInfo?["request"] as? Int,
                      request == self.cameraFlipSwitchInFlight else { return }
                self.cameraFlipSwitchInFlight = 0
                self.cameraFlipFrontImage = nil                                               
            }
            .store(in: &self.subscriptions)
    }

    func closeIrisForModeSwitch() {
        guard modeSwitchCloseRequest == nil else { return }
        irisCloseRequest += 1
        modeSwitchCloseRequest = irisCloseRequest
    }

    func consumeModeSwitchClose(_ request: Int) -> Bool {
        guard modeSwitchCloseRequest == request else { return false }
        modeSwitchCloseRequest = nil
        return true
    }

    func openIrisAfterModeSwitch() {
        irisOpenRequest += 1
    }

    func irisDidFinishOpening(_ request: Int) {
        guard request == irisOpenRequest else { return }
        completedIrisOpenRequest = request
        guard capturedPreviewImage != nil,
              capturedPreviewRequest > captureBounceRequest else { return }
        captureBounceRequest = capturedPreviewRequest
    }

    func captureBounceDidFinish(request: Int) {
        guard request == captureBounceRequest,
              let image = capturedPreviewImage else { return }
        finalThumbnailImage = image
        captureWellUpdateRequest += 1
        capturedPreviewImage = nil
    }
    
    func configure() {
                                                                              
        service.configure()
    }
    
    func capturePhoto() {
        service.capturePhoto()
    }
    
    func flipCamera() {
        guard cameraFlipSwitchInFlight == 0,
              let outgoingFrame = service.currentPreviewFrameImage() else { return }

        let currentPosition = service.currentCameraPosition
        cameraFlipFromRight = currentPosition != .front
        cameraFlipFrontImage = outgoingFrame
        cameraFlipPrepareRequest += 1
        let request = cameraFlipPrepareRequest
        cameraFlipSwitchInFlight = request

                                                                                  
                                                                                 
                                                                                 
                                                                              
        service.changeCamera { [weak self] didSwitch in
            guard let self = self, request == self.cameraFlipSwitchInFlight else { return }
            if didSwitch {
                self.cameraFlipRequest = request
            } else {
                self.cameraFlipCancelRequest = request
                self.cameraFlipFrontImage = nil
                self.cameraFlipSwitchInFlight = 0
            }
        }
    }
    
    func zoom(with factor: CGFloat) {
        service.set(zoom: factor)
    }
    
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode, cameraState: camera_state) {
        if cameraState == .video {
            service.setVideoFlashMode(mode)
        } else {
            service.setPhotoFlashMode(mode)
        }
    }

    func cameraModeDidChange(_ state: camera_state) {
        if state == .video {
            service.activateVideoFlashMode()
        } else {
            service.deactivateVideoTorch()
        }
    }

    func toggleHDR() {
        service.setHDREnabled(!service.hdrEnabled)
    }
    func record() {
        service.record()
    }
    func end_session() {
        service.deactivateVideoTorch()
        service.stop()
    }
}



                                        
  
                                          
                                                                                  
                                                                                 
                                                                      
                                                                                  
                                                                   
                                                                                  
                                                                    
                                                                                    
                                                                                  
                                                                            
                                                           
private struct OldOSCameraCaptureBounceOverlay: UIViewRepresentable {
    let image: UIImage?
    let request: Int
    let onFinished: (Int) -> Void

    func makeUIView(context: Context) -> OldOSCameraCaptureBounceUIView {
        let view = OldOSCameraCaptureBounceUIView(frame: .zero)
        view.onFinished = onFinished
        return view
    }

    func updateUIView(_ uiView: OldOSCameraCaptureBounceUIView, context: Context) {
        uiView.onFinished = onFinished
        uiView.accept(image: image, request: request)
    }
}

private final class OldOSCameraCaptureBounceUIView: UIView {
    private static let toolbarHeight: CGFloat = 60.0
    private static let wellSize: CGFloat = 41.0
    private static let wellLeading: CGFloat = 8.0
    private static let travelDuration: CFTimeInterval = 0.4
    private static let settleDuration: TimeInterval = 0.2
    private static let pathSampleCount = 192

    var onFinished: ((Int) -> Void)?

    private var pendingImage: UIImage?
    private var pendingRequest = 0
    private var lastStartedRequest = 0
    private var activeRequest = 0
    private var bouncingImageView: UIImageView?
    private var wellClipView: UIView?
    private var intermediateFrame = CGRect.zero
    private var destinationWellFrame = CGRect.zero
    private var bounceAspectRatio: CGFloat = 1.0

    private var displayLink: CADisplayLink?
    private var travelStartTime: CFTimeInterval = 0.0
    private var travelStartFrame = CGRect.zero
    private var travelStartCenter = CGPoint.zero
    private var travelControlPoint = CGPoint.zero
    private var travelDestinationCenter = CGPoint.zero
    private var pathCumulativeLengths: [CGFloat] = []
    private var pathTotalLength: CGFloat = 0.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    deinit {
        displayLink?.invalidate()
    }

    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
        clipsToBounds = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        startPendingBounceIfPossible()
    }

    func accept(image: UIImage?, request: Int) {
        guard request > 0,
              request != lastStartedRequest,
              let image = image else { return }
        pendingImage = image
        pendingRequest = request
        startPendingBounceIfPossible()
    }

    private func startPendingBounceIfPossible() {
        guard pendingRequest > 0,
              pendingRequest != lastStartedRequest,
              let image = pendingImage,
              bounds.width > 0.0,
              bounds.height > Self.toolbarHeight else { return }

        let request = pendingRequest
        pendingRequest = 0
        pendingImage = nil
        lastStartedRequest = request
        activeRequest = request
        removeBounceViews()

        let previewFrame = CGRect(x: 0.0,
                                  y: 0.0,
                                  width: bounds.width,
                                  height: bounds.height - Self.toolbarHeight)
        destinationWellFrame = CGRect(x: Self.wellLeading,
                                      y: bounds.height - Self.toolbarHeight +
                                         (Self.toolbarHeight - Self.wellSize) * 0.5,
                                      width: Self.wellSize,
                                      height: Self.wellSize)

        bounceAspectRatio = previewFrame.width / max(previewFrame.height, 1.0)

                                                                                 
                                                                                    
                                                                                  
                                                                                    
        let firstHeight = destinationWellFrame.height - 4.0
        let firstWidth = roundedSourceCGFloat(bounceAspectRatio * firstHeight)
        let firstX = destinationWellFrame.minX +
                     roundedSourceCGFloat(0.5 * (destinationWellFrame.width - firstWidth))
        intermediateFrame = CGRect(x: firstX,
                                   y: destinationWellFrame.minY + 2.0,
                                   width: firstWidth,
                                   height: firstHeight)

        let imageView = UIImageView(image: image)
        imageView.frame = previewFrame
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = false
        imageView.alpha = 1.0
        addSubview(imageView)
        bouncingImageView = imageView

        travelStartFrame = previewFrame
        travelStartCenter = CGPoint(x: previewFrame.midX, y: previewFrame.midY)
        travelDestinationCenter = CGPoint(x: intermediateFrame.midX, y: intermediateFrame.midY)
        travelControlPoint = CGPoint(x: roundedSourceCGFloat(previewFrame.minX + 0.25 * previewFrame.width),
                                     y: previewFrame.midY)

        buildPacedPathLookup()
        travelStartTime = CACurrentMediaTime()

                                                                                    
                                                                                   
                                                                                    
                                                                                
        let link = CADisplayLink(target: self, selector: #selector(stepPreviewDown(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func stepPreviewDown(_ link: CADisplayLink) {
        guard let imageView = bouncingImageView else {
            stopDisplayLink()
            return
        }

        let elapsed = max(0.0, CACurrentMediaTime() - travelStartTime)
        let linearProgress = min(1.0, CGFloat(elapsed / Self.travelDuration))
        let pathT = pacedPathParameter(for: linearProgress)
        let center = quadraticPoint(t: pathT,
                                    start: travelStartCenter,
                                    control: travelControlPoint,
                                    end: travelDestinationCenter)

                                                                                   
                                                         
        let sizeProgress = cubicBezierProgress(linearProgress,
                                                x1: 0.0, y1: 0.0,
                                                x2: 0.58, y2: 1.0)
        let width = interpolate(travelStartFrame.width, intermediateFrame.width, sizeProgress)
        let height = interpolate(travelStartFrame.height, intermediateFrame.height, sizeProgress)

        imageView.center = center
        imageView.bounds = CGRect(x: 0.0, y: 0.0, width: width, height: height)

                                                                              
                                                                                  
                                  

        if linearProgress >= 1.0 {
            stopDisplayLink()
            imageView.center = travelDestinationCenter
            imageView.bounds = CGRect(origin: .zero, size: intermediateFrame.size)
            imageView.alpha = 1.0
            startFinalBounce()
        }
    }

    private func buildPacedPathLookup() {
        pathCumulativeLengths = Array(repeating: 0.0, count: Self.pathSampleCount + 1)
        var previous = travelStartCenter
        var total: CGFloat = 0.0

        for index in 1...Self.pathSampleCount {
            let t = CGFloat(index) / CGFloat(Self.pathSampleCount)
            let point = quadraticPoint(t: t,
                                       start: travelStartCenter,
                                       control: travelControlPoint,
                                       end: travelDestinationCenter)
            total += hypot(point.x - previous.x, point.y - previous.y)
            pathCumulativeLengths[index] = total
            previous = point
        }

        pathTotalLength = total
    }

    private func pacedPathParameter(for progress: CGFloat) -> CGFloat {
        guard pathTotalLength > 0.0,
              pathCumulativeLengths.count == Self.pathSampleCount + 1 else {
            return progress
        }

        let target = min(max(progress, 0.0), 1.0) * pathTotalLength
        var low = 0
        var high = Self.pathSampleCount

        while low < high {
            let mid = (low + high) / 2
            if pathCumulativeLengths[mid] < target {
                low = mid + 1
            } else {
                high = mid
            }
        }

        let upper = max(1, min(low, Self.pathSampleCount))
        let lower = upper - 1
        let d0 = pathCumulativeLengths[lower]
        let d1 = pathCumulativeLengths[upper]
        let fraction = d1 > d0 ? (target - d0) / (d1 - d0) : 0.0
        return (CGFloat(lower) + fraction) / CGFloat(Self.pathSampleCount)
    }

    private func quadraticPoint(t: CGFloat,
                                start: CGPoint,
                                control: CGPoint,
                                end: CGPoint) -> CGPoint {
        let inverse = 1.0 - t
        let a = inverse * inverse
        let b = 2.0 * inverse * t
        let c = t * t
        return CGPoint(x: a * start.x + b * control.x + c * end.x,
                       y: a * start.y + b * control.y + c * end.y)
    }

    private func cubicBezierProgress(_ x: CGFloat,
                                     x1: CGFloat, y1: CGFloat,
                                     x2: CGFloat, y2: CGFloat) -> CGFloat {
        let clampedX = min(max(x, 0.0), 1.0)
        var lower: CGFloat = 0.0
        var upper: CGFloat = 1.0

                                                                                
                                                                              
        for _ in 0..<14 {
            let t = 0.5 * (lower + upper)
            let value = cubicBezierCoordinate(t, c1: x1, c2: x2)
            if value < clampedX {
                lower = t
            } else {
                upper = t
            }
        }

        return cubicBezierCoordinate(0.5 * (lower + upper), c1: y1, c2: y2)
    }

    private func cubicBezierCoordinate(_ t: CGFloat, c1: CGFloat, c2: CGFloat) -> CGFloat {
        let inverse = 1.0 - t
        return 3.0 * inverse * inverse * t * c1 +
               3.0 * inverse * t * t * c2 +
               t * t * t
    }

    private func interpolate(_ start: CGFloat, _ end: CGFloat, _ progress: CGFloat) -> CGFloat {
        return start + (end - start) * progress
    }

    private func startFinalBounce() {
        guard let imageView = bouncingImageView else { return }

                                                                               
                                                                                    
        let clipView = UIView(frame: destinationWellFrame)
        clipView.backgroundColor = .clear
        clipView.isOpaque = false
        clipView.clipsToBounds = true
        clipView.isUserInteractionEnabled = false
        addSubview(clipView)
        wellClipView = clipView

        imageView.removeFromSuperview()
        let localStartFrame = intermediateFrame.offsetBy(dx: -destinationWellFrame.minX,
                                                          dy: -destinationWellFrame.minY)
        imageView.frame = localStartFrame
        clipView.addSubview(imageView)

                                                                                 
                                                                                  
                                                                                
        let finalHeight = destinationWellFrame.height
        let finalWidth = roundedSourceCGFloat(finalHeight / max(bounceAspectRatio, 0.0001))
        let finalX = roundedSourceCGFloat(0.5 * (destinationWellFrame.width - finalWidth))
        let finalFrame = CGRect(x: finalX,
                                y: 0.0,
                                width: finalWidth,
                                height: finalHeight)

        UIView.animate(withDuration: Self.settleDuration,
                       delay: 0.0,
                       options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction],
                       animations: {
            imageView.frame = finalFrame
        }, completion: { [weak self] finished in
            guard let self = self, finished else { return }
            let request = self.activeRequest
            self.removeBounceViews()
            self.activeRequest = 0
            self.onFinished?(request)
        })
    }

    private func roundedSourceCGFloat(_ value: CGFloat) -> CGFloat {
        return CGFloat(rintf(Float(value)))
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    private func removeBounceViews() {
        stopDisplayLink()
        bouncingImageView?.layer.removeAllAnimations()
        bouncingImageView?.removeFromSuperview()
        bouncingImageView = nil
        wellClipView?.removeFromSuperview()
        wellClipView = nil
        pathCumulativeLengths.removeAll(keepingCapacity: false)
        pathTotalLength = 0.0
    }
}

                              
  
                                                     
                                                                       
                                                                
                                                                
                                   
                                                                           
                                                                                 
                                                                                
                                                                              
                                                                             
                                              
  
                                                                             
                                                                                  
                                                                               
                                                                 
private struct OldOSCameraIrisOverlay: UIViewRepresentable {
    let closeRequest: Int
    let openRequest: Int
    let startsClosed: Bool
    let closeCompletion: (Int) -> Void
    let openCompletion: (Int) -> Void

    func makeUIView(context: Context) -> OldOSCameraIrisUIView {
        let view = OldOSCameraIrisUIView(frame: .zero)
        view.closeCompletion = closeCompletion
        view.openCompletion = openCompletion
        view.seedRequestIDs(close: closeRequest, open: openRequest)
        if startsClosed {
            view.prepareInitialClosedState()
        }
        return view
    }

    func updateUIView(_ uiView: OldOSCameraIrisUIView, context: Context) {
        uiView.closeCompletion = closeCompletion
        uiView.openCompletion = openCompletion
        uiView.acceptRequestIDs(close: closeRequest, open: openRequest)
    }
}

private final class OldOSCameraIrisUIView: UIView, MTKViewDelegate {
    private enum Motion {
        case idle
        case closing
        case holdingClosed
        case opening
    }

    private enum EdgeSide {
        case outward
        case inward
    }

    private struct IrisVertex {
        var position: SIMD2<Float>
        var padding: SIMD2<Float> = .zero
        var color: SIMD4<Float>
    }

                                                                        
    private static let canonicalSize = CGSize(width: 320.0, height: 480.0)
    private static let irisCenter = CGPoint(x: 160.0, y: 220.0)
    private static let bladeCount = 8
    private static let bladeStepDegrees: CGFloat = 45.0
    private static let staticBladeOffsetDegrees: CGFloat = -55.0
    private static let dynamicBladeTravelDegrees: CGFloat = 67.0
    private static let fullAnimationDuration: CFTimeInterval = 0.20

                                                  
    private static let meshSampleCount = 14
    private static let meshIntervals: CGFloat = 13.0
    private static let meshRadialFactor: CGFloat = 0.003467406379058957
    private static let meshRadialMultiplier: CGFloat = 378.0

    var closeCompletion: ((Int) -> Void)?
    var openCompletion: ((Int) -> Void)?

    private let closedIrisImage = UIImage(named: "PLCameraClosedIrisSmall-Portrait-Original")
    private let staticIrisImageView = UIImageView(frame: .zero)
    private var metalView: MTKView?
    private var commandQueue: MTLCommandQueue?
    private var opaquePipeline: MTLRenderPipelineState?
    private var blendedPipeline: MTLRenderPipelineState?
    private var metalInitializationError: Error?

    private var progress: CGFloat = 0.0                                    
    private var motion: Motion = .idle
    private var pendingOpen = false
                                                                               
                                                                                 
                                                                               
    private var irisIsClosed = false
                                                                               
                                                                                 
                                                                               
                                                                
    private var closedEndpointNeedsPresentationFrame = false
                                                                                 
                                                                                 
                                                                               
                                                                                   
    private var terminalCloseFrameAwaitingHandoff = false

    private var animationStartProgress: CGFloat = 0.0
    private var animationTargetProgress: CGFloat = 0.0
    private var animationStartTime: CFTimeInterval = 0.0
    private var animationDuration: CFTimeInterval = OldOSCameraIrisUIView.fullAnimationDuration
    private var displayLink: CADisplayLink?

    private var lastCloseRequest = 0
    private var lastOpenRequest = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    deinit {
        displayLink?.invalidate()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        metalView?.frame = bounds
        staticIrisImageView.frame = bounds
    }

    private func commonInit() {
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        clipsToBounds = true
        isHidden = true

        primeStaticClosedIris()
        configureMetalRenderer()
        verifyIrisViewOrdering()
    }

    func prepareInitialClosedState() {
        stopDisplayLink()
        progress = 1.0
        motion = .holdingClosed
        irisIsClosed = true
        pendingOpen = false
        closedEndpointNeedsPresentationFrame = false
        terminalCloseFrameAwaitingHandoff = false
        isHidden = false
        metalView?.isHidden = true
        staticIrisImageView.frame = bounds
        staticIrisImageView.isHidden = false
        staticIrisImageView.alpha = 1.0
        verifyIrisViewOrdering()
    }

    private func configureMetalRenderer() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }

        let view = MTKView(frame: bounds, device: device)
        view.translatesAutoresizingMaskIntoConstraints = true
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.isOpaque = false
        view.layer.isOpaque = false
        view.backgroundColor = .clear
        view.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .invalid
        view.sampleCount = 1
        view.framebufferOnly = true
        view.isPaused = true
        view.enableSetNeedsDisplay = false
        view.delegate = self
        view.isHidden = true
                                                                                  
                                                                                   
        insertSubview(view, aboveSubview: staticIrisImageView)
        metalView = view

        commandQueue = device.makeCommandQueue()

        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;

        struct IrisVertex {
            float2 position;
            float2 padding;
            float4 color;
        };

        struct IrisVertexOut {
            float4 position [[position]];
            float4 color;
        };

        vertex IrisVertexOut oldOSCameraIrisVertex(
            const device IrisVertex *vertices [[buffer(0)]],
            uint vertexID [[vertex_id]]) {
            IrisVertexOut out;
            out.position = float4(vertices[vertexID].position, 0.0, 1.0);
            out.color = vertices[vertexID].color;
            return out;
        }

        fragment float4 oldOSCameraIrisFragment(IrisVertexOut in [[stage_in]]) {
            return in.color;
        }
        """

        do {
            let library = try device.makeLibrary(source: shaderSource, options: nil)
            guard let vertexFunction = library.makeFunction(name: "oldOSCameraIrisVertex"),
                  let fragmentFunction = library.makeFunction(name: "oldOSCameraIrisFragment") else {
                return
            }

            let opaqueDescriptor = MTLRenderPipelineDescriptor()
            opaqueDescriptor.vertexFunction = vertexFunction
            opaqueDescriptor.fragmentFunction = fragmentFunction
            opaqueDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            opaqueDescriptor.colorAttachments[0].isBlendingEnabled = false
            opaquePipeline = try device.makeRenderPipelineState(descriptor: opaqueDescriptor)

            let blendedDescriptor = MTLRenderPipelineDescriptor()
            blendedDescriptor.vertexFunction = vertexFunction
            blendedDescriptor.fragmentFunction = fragmentFunction
            blendedDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            let attachment = blendedDescriptor.colorAttachments[0]!
            attachment.isBlendingEnabled = true
                                                                                
                                                                                 
                                              
            attachment.rgbBlendOperation = .add
            attachment.alphaBlendOperation = .add
            attachment.sourceRGBBlendFactor = .one
            attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
            attachment.sourceAlphaBlendFactor = .one
            attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            blendedPipeline = try device.makeRenderPipelineState(descriptor: blendedDescriptor)
        } catch {
            metalInitializationError = error
            print("OldOS camera iris Metal renderer failed to initialize: \(error)")
        }
    }

    func seedRequestIDs(close: Int, open: Int) {
        lastCloseRequest = close
        lastOpenRequest = open
    }

    func acceptRequestIDs(close: Int, open: Int) {
        if close != lastCloseRequest {
            lastCloseRequest = close
            requestClose()
        }
        if open != lastOpenRequest {
            lastOpenRequest = open
            requestOpen()
        }
    }

    private func requestClose() {
        pendingOpen = false
        closedEndpointNeedsPresentationFrame = false
        terminalCloseFrameAwaitingHandoff = false

        switch motion {
        case .closing, .holdingClosed:
            return
        case .idle, .opening:
            beginCloseTransition()
        }
    }

    private func requestOpen() {
        switch motion {
        case .closing:
                                                                                   
                                                                                 
            pendingOpen = true
        case .holdingClosed:
            if closedEndpointNeedsPresentationFrame {
                pendingOpen = true
                ensureDisplayLink()
            } else {
                pendingOpen = false
                beginOpenTransition()
            }
        case .opening:
            break
        case .idle:
            if progress > 0.0001 || irisIsClosed {
                beginOpenTransition()
            }
        }
    }

    private func beginCloseTransition() {
                                                                                   
                                                                                  
                                                                                   
                                                                                    
                                                                                 
        showStaticClosedIrisTransitionTarget()
        metalView?.isHidden = false
        verifyIrisViewOrdering()
        startAnimation(to: 1.0, motion: .closing)
    }

    private func beginOpenTransition() {
                                                                                 
                                                                              
                                                              
        terminalCloseFrameAwaitingHandoff = false
        hideStaticClosedIris()
        metalView?.isHidden = false
        verifyIrisViewOrdering()
        startAnimation(to: 0.0, motion: .opening)
    }

    private func startAnimation(to target: CGFloat, motion newMotion: Motion) {
        animationStartProgress = progress
        animationTargetProgress = target
        animationStartTime = CACurrentMediaTime()

        let distance = max(0.001, abs(target - progress))
        animationDuration = Self.fullAnimationDuration * Double(distance)
        motion = newMotion
        isHidden = false
        ensureDisplayLink()
        renderCurrentFrame()
    }

    private func ensureDisplayLink() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(displayLinkDidFire(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func displayLinkDidFire(_ link: CADisplayLink) {
                                                                                   
                                                                                    
                                                                                  
                                              
        if motion == .closing && terminalCloseFrameAwaitingHandoff {
            terminalCloseFrameAwaitingHandoff = false
            motion = .holdingClosed
            presentStaticClosedIrisEndpoint()
            closedEndpointNeedsPresentationFrame = true
            closeCompletion?(lastCloseRequest)
            return
        }

                                                                               
                                                                                 
                                                                             
        if motion == .holdingClosed {
            if closedEndpointNeedsPresentationFrame {
                closedEndpointNeedsPresentationFrame = false
                if pendingOpen {
                    pendingOpen = false
                    beginOpenTransition()
                } else {
                    stopDisplayLink()
                }
            } else if pendingOpen {
                pendingOpen = false
                beginOpenTransition()
            } else {
                stopDisplayLink()
            }
            return
        }

                                                                                   
                                                                                 
                                                                                   
                                                                               
        let presentationTime = link.targetTimestamp > 0.0 ? link.targetTimestamp : CACurrentMediaTime()
        let elapsed = presentationTime - animationStartTime
        let linear = min(max(elapsed / animationDuration, 0.0), 1.0)

        if linear >= 1.0 {
            progress = animationTargetProgress
            switch motion {
            case .closing:
                                                                                  
                                                                                   
                                                                                   
                terminalCloseFrameAwaitingHandoff = true
                renderCurrentFrame()
            case .opening:
                motion = .idle
                progress = 0.0
                irisIsClosed = false
                pendingOpen = false
                closedEndpointNeedsPresentationFrame = false
                terminalCloseFrameAwaitingHandoff = false
                stopDisplayLink()
                staticIrisImageView.isHidden = true
                staticIrisImageView.alpha = 1.0
                metalView?.isHidden = true
                isHidden = true
                openCompletion?(lastOpenRequest)
            case .idle:
                stopDisplayLink()
            case .holdingClosed:
                break
            }
            return
        }

        let eased = Self.easeInOut(CGFloat(linear))
        progress = animationStartProgress + (animationTargetProgress - animationStartProgress) * eased
        renderCurrentFrame()
    }

    private func primeStaticClosedIris() {
        staticIrisImageView.image = closedIrisImage
        staticIrisImageView.contentMode = .scaleToFill
        staticIrisImageView.isUserInteractionEnabled = false
        staticIrisImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        staticIrisImageView.isHidden = true
        staticIrisImageView.alpha = 1.0
        addSubview(staticIrisImageView)
    }

    private func showStaticClosedIrisTransitionTarget() {
        irisIsClosed = true
        staticIrisImageView.frame = bounds
        staticIrisImageView.isHidden = false
                                                                                
                                                                                    
                                                                          
        staticIrisImageView.alpha = 0.0
        verifyIrisViewOrdering()
    }

    private func presentStaticClosedIrisEndpoint() {
        irisIsClosed = true
        metalView?.isHidden = true
        staticIrisImageView.frame = bounds
        staticIrisImageView.isHidden = false
        staticIrisImageView.alpha = 1.0
        verifyIrisViewOrdering()
        setNeedsLayout()
        layoutIfNeeded()
        staticIrisImageView.layer.setNeedsDisplay()
                                                                           
        CATransaction.flush()
    }

    private func hideStaticClosedIris() {
        irisIsClosed = false
        staticIrisImageView.isHidden = true
        staticIrisImageView.alpha = 1.0
    }

    private func verifyIrisViewOrdering() {
                                                                       
                                                                                 
                                                                                  
        if staticIrisImageView.superview === self {
            bringSubviewToFront(staticIrisImageView)
        }
        if let metalView, metalView.superview === self {
            bringSubviewToFront(metalView)
        }
    }

    private func renderCurrentFrame() {
        guard !isHidden else { return }

        switch motion {
        case .holdingClosed:
            if progress >= 0.9999 {
                presentStaticClosedIrisEndpoint()
            }
        case .closing:
                                                                                  
                                                                                   
            staticIrisImageView.isHidden = false
            staticIrisImageView.alpha = 0.0
            metalView?.isHidden = false
            verifyIrisViewOrdering()
            metalView?.draw()
        case .opening:
                                                                                     
            staticIrisImageView.isHidden = true
            staticIrisImageView.alpha = 1.0
            metalView?.isHidden = false
            verifyIrisViewOrdering()
            metalView?.draw()
        case .idle:
            break
        }
    }

                              

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandQueue,
              let opaquePipeline,
              let blendedPipeline else {
            return
        }

        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 0.0,
            green: 0.0,
            blue: 0.0,
            alpha: 0.0
        )

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        let p = min(max(progress, 0.0), 1.0)

        if p > 0.0001 {
                                                
            let baseVertices = Self.makeOpaqueBaseVertices(progress: p)
            Self.drawEightBladeStrips(
                baseVertices,
                encoder: encoder,
                device: view.device,
                pipeline: opaquePipeline
            )

                                                                               
                                                                              
            let faceVertices = Self.makeOpaqueFaceVertices(progress: p)
            Self.drawEightBladeStrips(
                faceVertices,
                encoder: encoder,
                device: view.device,
                pipeline: opaquePipeline
            )

                                                                                    
                                                                                 
                                                                             
            let washVertices = Self.makeWashVertices(progress: p)
            Self.drawSingleStrip(
                washVertices,
                encoder: encoder,
                device: view.device,
                pipeline: blendedPipeline
            )

            let edgeSpan = max(0.25, Self.recoveredEdgeSpan(progress: p))

                                                                                 
                                                                                 
            let shadowVertices = Self.makeShadowVertices(progress: p, span: edgeSpan)
            Self.drawEightBladeStrips(
                shadowVertices,
                encoder: encoder,
                device: view.device,
                pipeline: blendedPipeline
            )

                                                                                 
                                                                                 
            let highlightVertices = Self.makeHighlightVertices(progress: p, span: edgeSpan)
            Self.drawEightBladeStrips(
                highlightVertices,
                encoder: encoder,
                device: view.device,
                pipeline: blendedPipeline
            )
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private static func drawEightBladeStrips(
        _ vertices: [IrisVertex],
        encoder: MTLRenderCommandEncoder,
        device: MTLDevice?,
        pipeline: MTLRenderPipelineState
    ) {
        guard let device,
              vertices.count == bladeCount * meshSampleCount * 2,
              let buffer = device.makeBuffer(
                bytes: vertices,
                length: MemoryLayout<IrisVertex>.stride * vertices.count,
                options: .storageModeShared
              ) else { return }

        encoder.setRenderPipelineState(pipeline)
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)

        let verticesPerBlade = meshSampleCount * 2
        for blade in 0..<bladeCount {
            encoder.drawPrimitives(
                type: .triangleStrip,
                vertexStart: blade * verticesPerBlade,
                vertexCount: verticesPerBlade
            )
        }
    }

    private static func drawSingleStrip(
        _ vertices: [IrisVertex],
        encoder: MTLRenderCommandEncoder,
        device: MTLDevice?,
        pipeline: MTLRenderPipelineState
    ) {
        guard let device,
              !vertices.isEmpty,
              let buffer = device.makeBuffer(
                bytes: vertices,
                length: MemoryLayout<IrisVertex>.stride * vertices.count,
                options: .storageModeShared
              ) else { return }

        encoder.setRenderPipelineState(pipeline)
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertices.count)
    }

                                                  

    private static func makeOpaqueBaseVertices(progress: CGFloat) -> [IrisVertex] {
        let gray = normalizedByte(quantizedByte(0.08))
        let color = SIMD4<Float>(gray, gray, gray, 1.0)
        var output: [IrisVertex] = []
        output.reserveCapacity(bladeCount * meshSampleCount * 2)

        for blade in 0..<bladeCount {
            let geometry = stripGeometry(
                blade: blade,
                progress: progress,
                span: 0.50,
                width: 250.0,
                taper: 0.0,
                edgeSide: .outward,
                edgeMode: 0
            )
            for pair in geometry {
                output.append(vertex(point: pair.0, color: color))
                output.append(vertex(point: pair.1, color: color))
            }
        }
        return output
    }

    private static func makeOpaqueFaceVertices(progress: CGFloat) -> [IrisVertex] {
        let firstEdgeBytes = recoveredFaceFirstEdgeBytes()
        let secondGray = normalizedByte(quantizedByte(0.08))
        let secondColor = SIMD4<Float>(secondGray, secondGray, secondGray, 1.0)
        var output: [IrisVertex] = []
        output.reserveCapacity(bladeCount * meshSampleCount * 2)

        for blade in 0..<bladeCount {
            let geometry = stripGeometry(
                blade: blade,
                progress: progress,
                span: 0.25,
                width: 250.0,
                taper: 1.0,
                edgeSide: .outward,
                edgeMode: 0
            )

            for sample in 0..<meshSampleCount {
                let firstGray = normalizedByte(firstEdgeBytes[sample])
                let firstColor = SIMD4<Float>(firstGray, firstGray, firstGray, 1.0)
                output.append(vertex(point: geometry[sample].0, color: firstColor))
                output.append(vertex(point: geometry[sample].1, color: secondColor))
            }
        }
        return output
    }

    private static func makeShadowVertices(progress: CGFloat, span: CGFloat) -> [IrisVertex] {
        var output: [IrisVertex] = []
        output.reserveCapacity(bladeCount * meshSampleCount * 2)
        let clear = SIMD4<Float>(0.0, 0.0, 0.0, 0.0)

        for blade in 0..<bladeCount {
            let geometry = stripGeometry(
                blade: blade,
                progress: progress,
                span: span,
                width: 5.0,
                taper: 0.5,
                edgeSide: .inward,
                edgeMode: 1
            )
            let factor = recoveredEdgeFactor(blade: blade, mode: 1)
            let alphaByte = truncatedByte(factor * 255.0)
            let firstColor = SIMD4<Float>(0.0, 0.0, 0.0, normalizedByte(alphaByte))

            for pair in geometry {
                output.append(vertex(point: pair.0, color: firstColor))
                output.append(vertex(point: pair.1, color: clear))
            }
        }
        return output
    }

    private static func makeHighlightVertices(progress: CGFloat, span: CGFloat) -> [IrisVertex] {
        var output: [IrisVertex] = []
        output.reserveCapacity(bladeCount * meshSampleCount * 2)
        let clear = SIMD4<Float>(0.0, 0.0, 0.0, 0.0)
        let baseGrayByte = quantizedByte(0.27)                                 

        for blade in 0..<bladeCount {
            let geometry = stripGeometry(
                blade: blade,
                progress: progress,
                span: span,
                width: 3.0,
                taper: 0.5,
                edgeSide: .outward,
                edgeMode: 2
            )
            let factor = recoveredEdgeFactor(blade: blade, mode: 2)
                                                                               
                                                                            
            let alphaByte = truncatedByte(factor * 255.0)
            let grayByte = truncatedByte(factor * Float(baseGrayByte))
            let gray = normalizedByte(grayByte)
            let firstColor = SIMD4<Float>(gray, gray, gray, normalizedByte(alphaByte))

            for pair in geometry {
                output.append(vertex(point: pair.0, color: firstColor))
                output.append(vertex(point: pair.1, color: clear))
            }
        }
        return output
    }

    private static func makeWashVertices(progress: CGFloat) -> [IrisVertex] {
                                                                                 
                                                                                 
                                                                                  
                                                                                 
                                                                    
        let gByte = quantizedByte(Float(progress) * 51.0 / 255.0)
        let g = normalizedByte(gByte)
        let topColor = SIMD4<Float>(g, g, g, g)
        let clear = SIMD4<Float>(0.0, 0.0, 0.0, 0.0)
        return [
            vertex(point: CGPoint(x: 0.0, y: 0.0), color: topColor),
            vertex(point: CGPoint(x: canonicalSize.width, y: 0.0), color: topColor),
            vertex(point: CGPoint(x: 0.0, y: canonicalSize.height), color: clear),
            vertex(point: CGPoint(x: canonicalSize.width, y: canonicalSize.height), color: clear)
        ]
    }

    private static func stripGeometry(
        blade: Int,
        progress: CGFloat,
        span: CGFloat,
        width: CGFloat,
        taper: CGFloat,
        edgeSide: EdgeSide,
        edgeMode: Int
    ) -> [(CGPoint, CGPoint)] {
        let halfWidth = canonicalSize.width * 0.5
        let halfHeight = canonicalSize.height * 0.5
        let halfDiagonal = (halfWidth * halfWidth + halfHeight * halfHeight).squareRoot()
                                                                               
                                                                                  
                                                           
        let sourceUnitScale = halfDiagonal * meshRadialFactor
        let radius = sourceUnitScale * meshRadialMultiplier
        let direction: CGFloat = edgeSide == .inward ? -1.0 : 1.0

        var result: [(CGPoint, CGPoint)] = []
        result.reserveCapacity(meshSampleCount)

        for sample in 0..<meshSampleCount {
            let t = CGFloat(sample) / meshIntervals
            let theta = .pi * span * t
            let sinTheta = sin(theta)
            let cosTheta = cos(theta)

            let firstLocal = CGPoint(
                x: radius * sinTheta,
                y: radius * (cosTheta - 1.0)
            )

            var sourceWidth = sourceUnitScale * width
                                                                                
                                                                                 
                                                                             
                                                            
            if edgeMode == 1 {
                sourceWidth *= (2.0 - t)
            }
            let secondRadius = radius + direction * sourceWidth * (1.0 - taper * t)
            let secondLocal = CGPoint(
                x: secondRadius * sinTheta,
                y: secondRadius * cosTheta - radius
            )

            result.append((
                sourcePosePoint(firstLocal, blade: blade, progress: progress, halfDiagonal: halfDiagonal),
                sourcePosePoint(secondLocal, blade: blade, progress: progress, halfDiagonal: halfDiagonal)
            ))
        }
        return result
    }

    private static func sourcePosePoint(
        _ local: CGPoint,
        blade: Int,
        progress: CGFloat,
        halfDiagonal: CGFloat
    ) -> CGPoint {
                                                                         
                                                                        
        let dynamic = rotate(local, degrees: -dynamicBladeTravelDegrees * progress)
        let hinged = CGPoint(x: dynamic.x, y: dynamic.y + halfDiagonal)
        let staticDegrees = CGFloat(blade) * bladeStepDegrees + staticBladeOffsetDegrees
        let oriented = rotate(hinged, degrees: staticDegrees)
        return CGPoint(
            x: irisCenter.x + oriented.x,
            y: irisCenter.y + oriented.y
        )
    }

    private static func recoveredFaceFirstEdgeBytes() -> [UInt8] {
                                                                                   
                                                             
                                                          
        var current = Float(0.15)
        let end = Float(0.08)
        var result: [UInt8] = []
        result.reserveCapacity(meshSampleCount)

        for sample in 0..<meshSampleCount {
            let t = Float(sample) / Float(meshSampleCount - 1)
            current = (1.0 - t) * current + t * end
            result.append(quantizedByte(current))
        }
        return result
    }

    private static func recoveredEdgeSpan(progress: CGFloat) -> CGFloat {
        let p = min(max(progress, 0.0), 1.0)
        let u = 1.0 - p
        return -0.04
             + 0.25 * p
             + 0.465 * u
             - 0.05 * u * u * u
             - 0.20 * u * u * u * u
    }

    private static func recoveredEdgeFactor(blade: Int, mode: Int) -> Float {
        let b = Float(normalizedBladeIndex(blade)) / 7.0
        let q = 4.0 * b * (1.0 - b)
        let q3 = q * q * q
        if mode == 2 {
            return 0.25 + 0.75 * q3
        }
        return 1.0 - 0.75 * q3
    }

    private static func quantizedByte(_ normalized: Float) -> UInt8 {
        let value = Int(normalized * 255.0 + 0.5)
        return UInt8(max(0, min(255, value)))
    }

    private static func truncatedByte(_ value: Float) -> UInt8 {
        return UInt8(max(0, min(255, Int(value))))
    }

    private static func normalizedByte(_ value: UInt8) -> Float {
        Float(value) / 255.0
    }

    private static func vertex(point: CGPoint, color: SIMD4<Float>) -> IrisVertex {
        let x = Float((point.x / canonicalSize.width) * 2.0 - 1.0)
        let y = Float(1.0 - (point.y / canonicalSize.height) * 2.0)
        return IrisVertex(position: SIMD2<Float>(x, y), color: color)
    }

    private static func normalizedBladeIndex(_ index: Int) -> Int {
        let value = index % bladeCount
        return value >= 0 ? value : value + bladeCount
    }

    private static func rotate(_ point: CGPoint, degrees: CGFloat) -> CGPoint {
        let angle = radians(degrees)
        let c = cos(angle)
        let s = sin(angle)
        return CGPoint(
            x: c * point.x - s * point.y,
            y: s * point.x + c * point.y
        )
    }

    private static func radians(_ degrees: CGFloat) -> CGFloat {
        degrees * .pi / 180.0
    }

    private static func easeInOut(_ x: CGFloat) -> CGFloat {
        let target = min(max(x, 0.0), 1.0)
        var low: CGFloat = 0.0
        var high: CGFloat = 1.0
        var t = target

        for _ in 0..<12 {
            t = (low + high) * 0.5
            let estimate = cubicBezier(t, p1: 0.42, p2: 0.58)
            if estimate < target {
                low = t
            } else {
                high = t
            }
        }

        let oneMinusT = 1.0 - t
        return 3.0 * oneMinusT * t * t + t * t * t
    }

    private static func cubicBezier(_ t: CGFloat, p1: CGFloat, p2: CGFloat) -> CGFloat {
        let oneMinusT = 1.0 - t
        return 3.0 * oneMinusT * oneMinusT * t * p1
             + 3.0 * oneMinusT * t * t * p2
             + t * t * t
    }
}
