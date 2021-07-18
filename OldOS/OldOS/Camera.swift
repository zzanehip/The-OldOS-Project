//
//  Camera.swift
//  OldOS
//
//  Created by Zane Kleinberg on 5/24/21.
//

import SwiftUI
import Camera_SwiftUI
import Combine
import AVKit
import Photos

struct Camera: View {
    @State var camera_state: camera_state = .photo
    @State var is_recording: Bool = false
    @State var recording_timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @StateObject var model = CameraModel()
    
    @State var currentZoomFactor: CGFloat = 1.0
    @Binding var instant_multitasking_change: Bool
    var body: some View {
        GeometryReader{ geometry in
            ZStack {
                CameraPreview(session: model.session) .onAppear {
                    model.configure()
                }
                VStack(spacing: 0) {
                    camera_header(model: model, camera_state: $camera_state, is_recording: $is_recording, recording_timer: $recording_timer).padding(.top, 10)
                    Spacer()
                    camera_tool_bar(camera_state: $camera_state, is_recording: $is_recording, recording_timer: $recording_timer, model: model, instant_multitasking_change: $instant_multitasking_change).frame(height: 60)
                }
                
            }
        }.onDisappear() {
            model.end_session()
        }
    }
}

//struct Camera_Previews: PreviewProvider {
//    static var previews: some View {
//        Camera()
//    }
//}

enum camera_state {
    case photo, video
}
struct camera_flipper: View {
    @Binding var state: camera_state
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
                                                    state = .video
                                                }
                                            } else {
                                                withAnimation(.linear(duration: 0.1)) {
                                                    self.offset.x = 0
                                                    state = .photo
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
    var body: some View {
        HStack {
            camera_capsule(content: HStack {
                Image("PLCameraFlashIcon_2only_")
                Text("Auto").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(Color(red: 21/255, green: 21/255, blue: 21/255)).opacity(0.85)
            }).frame(width: 80, height: 64/120*62).padding(.leading, 8)
            Spacer()
            if is_recording == true {
                ZStack {
                    RoundedRectangle(cornerRadius:6).fill(Color.black.opacity(0.35)).strokeRoundedRectangle(6, Color(red: 255/255, green: 255/255, blue: 255/255).opacity(0.25), lineWidth: 0.95).frame(width: 95, height: 64/120*55)
                    Text(String(format: "%02d:%02d:%02d", Int(current_time) / 3600 , (Int(current_time) % 3600)/60,  (Int(current_time) % 3600) % 60)).font(.custom("Helvetica Neue Regular", size: 19)).foregroundColor(.white)
                }.padding(.trailing, 8)
            } else {
            Button(action: {model.flipCamera()}) {
            Image("PLCameraToggle-2x").resizable().frame(width: 65, height: 65/120*62).padding(.trailing, 8)
            }
            }
        }.overlay(HStack {
            Spacer()
            camera_capsule(content: HStack {
                Text("HDR On").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(Color(red: 21/255, green: 21/255, blue: 21/255)).opacity(0.85)
            }).frame(width: 95, height: 64/120*62).opacity(camera_state == .photo ? 1 : 0)
            Spacer()
        }).onReceive(recording_timer, perform: {_ in
            if is_recording == false {
                current_time = TimeInterval(0)
            } else {
            current_time = current_time + TimeInterval(recording_timer.upstream.interval)
            }
            print(current_time)
        }).onChange(of: is_recording, perform: {_ in
            if is_recording == false {
                current_time = TimeInterval(0)
            }
        })
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
    @State var audioPlayer: AVAudioPlayer!
    @StateObject var model: CameraModel
    @Binding var instant_multitasking_change: Bool
    private let gradient = LinearGradient([Color.clear, Color.clear], to: .trailing)
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient([(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 0), (color: Color(red: 123/255, green: 125/255, blue: 131/255), location: 1)], from: .top, to: .bottom)
                HStack {
                    HStack {
                        if c_image != nil {
                           Image(uiImage: (c_image ?? UIImage(named: "PLCameraPreviewPlaceholder"))!).resizedToFill(82/2).ps_innerShadow(.roundedRectangle(3), radius:0.8, offset: CGPoint(0, 2/3), intensity: 0.65).clipShape(RoundedRectangle(3)).shadow(color: Color.white.opacity(0.48), radius: 0, x: 0, y: 0.8).strokeRoundedRectangle(3, Color(red: 73/255, green: 74/255, blue: 76/255), lineWidth: 0.33)
                        }
                        else {
                        Image("PLCameraPreviewPlaceholder").resizedToFill(82/2).ps_innerShadow(.roundedRectangle(3), radius:0.8, offset: CGPoint(0, 2/3), intensity: 0.65).clipShape(RoundedRectangle(3)).shadow(color: Color.white.opacity(0.48), radius: 0, x: 0, y: 0.8).strokeRoundedRectangle(3, Color(red: 73/255, green: 74/255, blue: 76/255), lineWidth: 0.33)
                        }
                        Spacer()
                    }.frame(width: geometry.size.width/4.5).padding(.leading, 8)
                    Spacer()
                    Button(action: {
                        if camera_state == .photo {
                            model.capturePhoto()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                                LastPhotoRetriever().queryLastPhoto(resizeTo: nil) {photo in
                                    print("called it here")
                                    c_image = photo
                                }
                            }
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
                    camera_flipper(state: $camera_state).frame(width:geometry.size.width/4.75, height: 82/2).padding(.trailing, 8)
                }
            }.onAppear() {
                LastPhotoRetriever().queryLastPhoto(resizeTo: nil) {photo in
                    c_image = photo
                }
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
    
    @Published var willCapturePhoto = false
    
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
            self?.isFlashOn = mode == .on
        }
        .store(in: &self.subscriptions)
        
        service.$willCapturePhoto.sink { [weak self] (val) in
            self?.willCapturePhoto = val
        }
        .store(in: &self.subscriptions)
    }
    
    func configure() {
        service.checkForPermissions()
        service.configure()
    }
    
    func capturePhoto() {
        service.capturePhoto()
    }
    
    func flipCamera() {
        service.changeCamera()
    }
    
    func zoom(with factor: CGFloat) {
        service.set(zoom: factor)
    }
    
    func switchFlash() {
        service.flashMode = service.flashMode == .on ? .off : .on
    }
    func record() {
        service.record()
    }
    func end_session() {
        service.session.stopRunning()
    }
}
