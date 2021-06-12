//
//  Photos.swift
//  OldOS
//
//  Created by Zane Kleinberg on 5/10/21.
//

import SwiftUI
import Photos
import AVKit
import AVFoundation
import MapKit

struct Photos: View {
    @State var current_nav_view: String = "Main"
    @State var switcher_current_nav_view: String = "Main"
    @State var forward_or_backward: Bool = false
    @State var selectedTab = "Albums"
    @State var last_photo: UIImage = UIImage()
    @State var selected_photo: PHAsset = PHAsset()
    @State var hide_bars: Bool = false
    @ObservedObject var photos_obsever = PhotosObserver()
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing:0) {
                    switch switcher_current_nav_view {
                    case "Main":
                        PhotosTabView(selectedTab: $selectedTab, current_nav_view: $current_nav_view, switcher_current_nav_view: $switcher_current_nav_view, forward_or_backward: $forward_or_backward, last_photo: $last_photo, selected_photo: $selected_photo, photos_obsever: photos_obsever).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing))).clipped()
                    case "Destination":
                        if selected_photo.mediaType.rawValue == 1 {
                            photo_destination(selected_photo: $selected_photo, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, hide_bars: $hide_bars, photos_obsever: photos_obsever).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing))).clipped()
                        } else {
                            photo_destination(selected_photo: $selected_photo, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, hide_bars: $hide_bars, photos_obsever: photos_obsever).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing))).clipped()//
                        }//This might seme weird, but it lets is refresh the view (which recreates our AVPlayer)
                    default:
                        PhotosTabView(selectedTab: $selectedTab, current_nav_view: $current_nav_view, switcher_current_nav_view: $switcher_current_nav_view, forward_or_backward: $forward_or_backward, last_photo: $last_photo, selected_photo: $selected_photo, photos_obsever: photos_obsever).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing))).clipped()
                    }
                }
                VStack(spacing:0) {
                    status_bar().frame(minHeight: 24, maxHeight:24).zIndex(1)
                    photos_title_bar(title: selectedTab == "Albums" ? current_nav_view == "Main" ? selectedTab : switcher_current_nav_view == "Main" ? current_nav_view : "\(Int(photos_obsever.assets.firstIndex(of: selected_photo) ?? 0 + 1)) of \(photos_obsever.assets.count)" : selectedTab, back_action:{forward_or_backward = true;  withAnimation(.linear(duration: 0.28)) {current_nav_view = "Main"}}, destination_back_action: {forward_or_backward = true;  withAnimation(.linear(duration: 0.28)) {switcher_current_nav_view = "Main"}}, show_albums_back: (current_nav_view != "Main" && selectedTab == "Albums" && switcher_current_nav_view != "Destination") ? true : false, show_destination_back: switcher_current_nav_view == "Destination" ? true : false,forward_or_backward: $forward_or_backward).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 60, maxHeight:60).zIndex(2)
                    Spacer()
                }.opacity(hide_bars == true ? 0 : 1).disabled(hide_bars)
            }.compositingGroup().clipped()
        }.onAppear() {
            UIScrollView.appearance().bounces = true
            LastPhotoRetriever().queryLastPhoto(resizeTo: nil) {photo in
                last_photo = photo ?? UIImage()
            }
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
        }
    }
}

struct PlacesMapView: UIViewControllerRepresentable {
    
    var mapView = MKMapView()
    var view = UIView()
    var view_controller = UIViewController()
    var view_controller2 = UIViewController()
    var curl_view: XBCurlView?
    var geometry: GeometryProxy?
    var legal_hosting = UIHostingController(rootView: legal_view())
    var tileRenderer: MKTileOverlayRenderer?
    @ObservedObject var mapType: map_type_observer = map_type_observer()
    func makeUIViewController(context: Context) -> UIViewControllerType {
        context.coordinator.setupTileRenderer()
        view_controller.view.addSubview(mapView)
        view_controller2.view.backgroundColor = UIColor.white
        mapView.frame = CGRect(geometry?.size.width ?? 0, (geometry?.size.height ?? 0))
        mapView.delegate = context.coordinator
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        view_controller.presentationController?.delegate = context.coordinator
        let viewRegion = MKCoordinateRegion(center: CLLocationManager().location?.coordinate ?? CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.0125, longitudeDelta: 0.0125))
        mapView.setRegion(viewRegion, animated: false)
        mapView.showsUserLocation = false
        return view_controller
    }
    
    func go_to_user_location() {
        let viewRegion = MKCoordinateRegion(center: CLLocationManager().location?.coordinate ?? CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.0125, longitudeDelta: 0.0125))
        mapView.setRegion(viewRegion, animated: true)
    }
    
    func update_map() {
        print("update map")
        mapView.mapType = mapType.type
        mapView.setCenter(mapView.centerCoordinate, animated: false)
        tileRenderer?.alpha = 0.0
        let overlays = mapView.overlays
        if mapView.mapType == .standard {
            let template = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
            let overlay = MKTileOverlay(urlTemplate: template)
            overlay.canReplaceMapContent = true
            if overlays.contains(where: {$0 is MKPolyline}) {
                mapView.addOverlay(overlay, level: .aboveLabels)
                if let poly_overlay = overlays.filter({$0 is MKPolyline}).first {
                mapView.addOverlay(poly_overlay, level: .aboveLabels)
                }
            } else {
            mapView.addOverlay(overlay, level: .aboveLabels)
            }
        } else {
            for overlay in overlays {
                if let ove = overlay as? MKTileOverlay {
                mapView.removeOverlay(ove)
                }
            }
        }
        
        mapView.setNeedsDisplay(mapView.frame)
    }
    
    func updateUIViewController(_ viewController: UIViewController, context: Context) {
        mapView.frame = CGRect(geometry?.size.width ?? 0, (geometry?.size.height ?? 0) - 72)
        _ = UIHostingController(rootView: google_logo_view())
        let google_image = UIImageView(image: UIImage(named: "GoogleBadge"))
        google_image.isUserInteractionEnabled = false
        google_image.frame = CGRect(10, mapView.frame.size.height - google_image.frame.size.height - 10 , google_image.frame.size.width, google_image.frame.size.height)
        google_image.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        mapView.addSubview(google_image)
    }
    

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, UIAdaptivePresentationControllerDelegate {
        var parent: PlacesMapView
        
        init(_ parent: PlacesMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
            
            let visibleRect = mapView.annotationVisibleRect
            for view: MKAnnotationView in views {
                let endFrame:CGRect = view.frame
                var startFrame:CGRect = endFrame
                startFrame.origin.y = visibleRect.origin.y - startFrame.size.height
                view.frame = startFrame
                UIView.animate(withDuration: 0.5, animations: {
                    view.frame = endFrame
                }, completion: nil)
            }
        }
        
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            view.subviews.forEach {
                $0.removeFromSuperview()
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let viewRegion = MKCoordinateRegion(center: CLLocationManager().location?.coordinate ?? CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.0125, longitudeDelta: 0.0125))
            if mapView.region != viewRegion {
                parent.mapType.location_selected = false
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            
            guard !annotation.isKind(of: MKUserLocation.self) else {
                let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "userLocation")
                annotationView.image = UIImage(named: "TrackingDot")
                return annotationView
            }
            
            let annotationIdentifier = "AnnotationIdentifier"
            
            var annotationView: MKAnnotationView?
            if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) {
                annotationView = dequeuedAnnotationView
                annotationView?.annotation = annotation
            }
            else {
                let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
                av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                annotationView = av
            }
            
            if let annotationView = annotationView {
                annotationView.canShowCallout = false
                annotationView.image = UIImage(named: "Pin")
                annotationView.centerOffset = CGPoint(6.5, -11.5)
            }
            
            if let anno = annotation as? SourcePointAnnotation, anno.identifier == "green" {
                annotationView?.image = UIImage(named: "PinGreen")
                annotationView?.centerOffset = CGPoint(6.5, -11.5)
                annotationView?.zPriority = .max
            }
            
            annotationView?.isEnabled = false
            
            return annotationView
            
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            switch overlay {
            case let polyline as MKPolyline:
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(red: 171/255, green: 119/255, blue: 238/255, alpha: 0.8)
                renderer.lineWidth = 8
                return renderer
            
            case is MKTileOverlay:
                return parent.tileRenderer ?? MKOverlayRenderer()

            default:
                fatalError("Unexpected MKOverlay type")
            }
        }
        
        
        func setupTileRenderer() {
            let template = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
            let overlay = MKTileOverlay(urlTemplate: template)
            overlay.canReplaceMapContent = true
            parent.mapView.addOverlay(overlay, level: .aboveLabels)
            parent.tileRenderer = MKTileOverlayRenderer(tileOverlay: overlay)
        }
        
    }
    
}

struct photo_video_share_view: View {
    var media_type: PHAssetMediaType
    @Binding var show_share: Bool
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                VStack(spacing:0) {
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 101/255, green: 100/255, blue: 100/255).opacity(0.88), Color.init(red: 31/255, green: 30/255, blue: 30/255).opacity(0.88)]), startPoint: .top, endPoint: .bottom)).innerShadowBottom(color: Color.white.opacity(0.98), radius: 0.1).border_top(width: 1, edges:[.top], color: Color.black).frame(height:30)
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 21/255, green: 20/255, blue: 20/255).opacity(0.88), Color.black.opacity(0.9)]), startPoint: .top, endPoint: .bottom))
                }
                VStack {
                    Button(action:{
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5))
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 235/255, green: 235/255, blue: 236/255), location: 0), .init(color: Color(red: 208/255, green: 209/255, blue: 211/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Email \(media_type.rawValue == 1 ? "Photo" : media_type.rawValue == 2 ? "Video" : "Other")").font(.custom("Helvetica Neue Bold", size: 18)).foregroundColor(Color.black).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.bottom], 2.5).padding(.top, 28)
                    Button(action:{
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5))
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 235/255, green: 235/255, blue: 236/255), location: 0), .init(color: Color(red: 208/255, green: 209/255, blue: 211/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("MMS").font(.custom("Helvetica Neue Bold", size: 18)).foregroundColor(Color.black).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.top, .bottom], 2.5)
                    Button(action:{
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5))
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 235/255, green: 235/255, blue: 236/255), location: 0), .init(color: Color(red: 208/255, green: 209/255, blue: 211/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Send to YouTube").font(.custom("Helvetica Neue Bold", size: 18)).foregroundColor(Color.black).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.top, .bottom], 2.5)
                    Spacer()
                    Button(action:{
                        withAnimation(.linear(duration: 0.4)) {
                            show_share = false
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5)).opacity(0.6)
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 124/255, green: 124/255, blue: 124/255), location: 0), .init(color: Color(red: 26/255, green: 26/255, blue: 26/255), location: 0.50), .init(color: Color(red: 0/255, green: 0/255, blue: 0/255), location: 0.53), .init(color: Color(red: 0/255, green: 0/255, blue: 0/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.gray.opacity(0.9), Color.gray.opacity(0.35)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3).opacity(0.6)
                            Text("Cancel").font(.custom("Helvetica Neue Bold", size: 18)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0.0, y: -0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.bottom], 25)
                }
            }
        }
    }
}


import AVKit
struct photo_destination: View {
    @StateObject var model: PlayerViewModel = PlayerViewModel()
    @State var selected_photo_image: UIImage = UIImage()
    @State var is_playing: Bool = false
    @State var is_mid_play: Bool = false
    @State var player_backup: AVPlayer? //We create what I'm calling a backup player. This avoids traditional issues with AVPlayer where resizing the view results in a new AVPlayer instance being needed.
    @Binding var selected_photo: PHAsset
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var hide_bars: Bool
    @ObservedObject var photos_obsever: PhotosObserver
    @State var pervent_delta: Bool = false
    @State var unhide_video: Bool = false
    @State var show_share: Bool = false
    @GestureState var scale: CGFloat = 1.0
    @GestureState var dragAmount = CGSize.zero
    let pub = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    Image(uiImage: selected_photo_image).resizable().scaledToFill().frame(width: geometry.size.width, height:geometry.size.height).if(selected_photo.mediaType == .video) {
                        $0.overlay(ZStack {
                            if unhide_video {
                                PlayerContainerView(player: model.player, gravity: .fit).frame(width: geometry.size.width, height:geometry.size.height).fixedSize().disabled(true).onReceive(pub) { (output) in
                                    is_playing = false
                                    model.restart()
                                    is_mid_play = false
                                    model.player = player_backup ?? AVPlayer()
                                }
                            }
                            if !is_playing {
                                Button(action: {
                                    if !is_mid_play {
                                        model.player = player_backup ?? AVPlayer()
                                        model.restart()
                                        model.play()
                                        is_playing.toggle()
                                        is_mid_play.toggle()
                                    } else {
                                        model.play()
                                        is_playing.toggle()
                                        is_mid_play = true
                                    }
                                }) {
                                    Image("PLVideoOverlayPlay")
                                }
                            }
                        })
                    }.onAppear() {
                        selected_photo.getMainImage(completionHandler: {image in
                            selected_photo_image = image ?? UIImage()
                        })
                    }
                    .onTapGesture() {
                        if pervent_delta == false {
                            pervent_delta = true
                            withAnimation(.linear(duration: hide_bars == false ? 0.25 : 0.1)) {
                                hide_bars.toggle()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                pervent_delta = false
                            }
                        }
                    }
                    .scaleEffect(selected_photo.mediaType == .video ? 1.0 : scale).offset(selected_photo.mediaType == .video ? CGSize.zero : dragAmount).gesture(MagnificationGesture()
                                                                                                                                                                    .updating($scale, body: { (value, scale, trans) in
                                                                                                                                                                        scale = value.magnitude
                                                                                                                                                                        
                                                                                                                                                                    }).simultaneously(with: DragGesture().updating($dragAmount, body: { value, state, transaction in
                                                                                                                                                                        state = value.translation
                                                                                                                                                                    }))
                    )
                    VStack {
                        Spacer()
                        photo_destination_tool_bar(share_action: { withAnimation(.linear(duration: 0.4)) {show_share = true}},back_action: {
                            if let index = photos_obsever.assets.firstIndex(of: selected_photo) {
                                selected_photo = photos_obsever.assets[index-1]
                                selected_photo.getMainImage(completionHandler: {image in
                                    selected_photo_image = image ?? UIImage()
                                })
                            }
                        }, forward_action: {
                            if let index = photos_obsever.assets.firstIndex(of: selected_photo) {
                                selected_photo = photos_obsever.assets[index+1]
                                selected_photo.getMainImage(completionHandler: {image in
                                    selected_photo_image = image ?? UIImage()
                                })
                            }
                        }, play_pause_action: {
                            if is_playing {
                                model.pause()
                                is_playing.toggle()
                            } else {
                                model.play()
                                is_playing.toggle()
                                is_mid_play = true
                            }
                        }, is_playing: $is_playing, backward_enabled: selected_photo == photos_obsever.assets.first ? false : true, forward_enabled: selected_photo == photos_obsever.assets.last ? false : true).frame(height: 45) //It's counter intuitive, but the first photo is the last and last photo is the first. We reverse show the array (bottom to top)
                    }.opacity(hide_bars == true ? 0 : 1).disabled(hide_bars)
                    if show_share {
                        VStack(spacing:0) {
                            Spacer().foregroundColor(.clear).zIndex(0)
                            photo_video_share_view(media_type: selected_photo.mediaType, show_share: $show_share).frame(minHeight: geometry.size.height/2, maxHeight: geometry.size.height/2).zIndex(1)
                        }.transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom))).zIndex(1)
                    }
                }
            }
        }.onAppear() {
            if selected_photo.mediaType == .video {
                let options = PHVideoRequestOptions()
                options.isNetworkAccessAllowed = true
                
                PHCachingImageManager().requestPlayerItem(forVideo: selected_photo, options: options) { (playerItem, info) in
                    DispatchQueue.main.async {
                        if let playerItem = playerItem {
                            player_backup = AVPlayer(playerItem: playerItem)
                            model.player = player_backup ?? AVPlayer()
                            unhide_video = true
                        }
                    }
                }
            }
        }
    }
}

struct photo_destination_tool_bar: View {
    public var share_action: (() -> Void)?
    public var back_action: (() -> Void)?
    public var forward_action: (() -> Void)?
    var play_pause_action: (() -> Void)?
    @Binding var is_playing: Bool
    var backward_enabled: Bool?
    var forward_enabled: Bool?
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.005), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025).border_bottom(width: 0.95, edges: [.top], color: Color(red: 0/255, green: 0/255, blue: 0/255)).opacity(0.65)
            HStack {
                tool_bar_button(image:"UIButtonBarAction", action: {
                    share_action?()
                })
                Spacer()
                tool_bar_button(image:"UIButtonBarPreviousSlide", action: {
                    if backward_enabled == true {
                        back_action?()
                    }
                }).opacity(backward_enabled == true ? 1 : 0.25)
                tool_bar_button(image: is_playing == false ? "UIButtonBarPlay" : "UIButtonBarPause", action: {
                    play_pause_action?()
                })
                tool_bar_button(image:"UIButtonBarNextSlide") {
                    if forward_enabled == true {
                        forward_action?()
                    }
                }.opacity(forward_enabled == true ? 1 : 0.25)
                Spacer()
                tool_bar_button(image:"UIButtonBarTrash", action: {
                    withAnimation() {
                    }
                })
            }.transition(.opacity)
        }
    }
}


struct camera_roll: View {
    @Binding var current_nav_view: String
    @Binding var switcher_current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var selected_photo: PHAsset
    @ObservedObject var photos_obsever: PhotosObserver
    let columns = [
        GridItem(.flexible(minimum: 60)),
        GridItem(.flexible(minimum: 60)),
        GridItem(.flexible(minimum: 60)),
        GridItem(.flexible(minimum: 60))
    ]
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                ScrollView {
                    ScrollViewReader { value in
                        LazyVGrid(columns: columns, spacing: 5) {
                            ForEach(photos_obsever.assets, id: \.self) { asset in
                                GeometryReader { proxy in
                                    Button(action: {
                                        selected_photo = asset; forward_or_backward = false; withAnimation(.linear(duration: 0.28)){switcher_current_nav_view = "Destination"}
                                    }) {
                                        PhotoLibraryImageView(asset: asset, proxy: proxy).if(asset.mediaType == .video) {
                                            $0.overlay(
                                                VStack {
                                                    Spacer()
                                                    ZStack {
                                                        Rectangle().fill(Color.black.opacity(0.5)).frame(width: proxy.size.width, height: proxy.size.height/5)
                                                        HStack {
                                                            Image("PLVideoCameraPreview").padding(.leading, 4)
                                                            Spacer()
                                                            Text(String(format: "%01d:%02d", (Int(asset.duration) % 3600)/60,  (Int(asset.duration) % 3600) % 60)).font(.custom("Helvetica Neue Bold", size: 11)).foregroundColor(.white).padding(.trailing, 4)
                                                        }
                                                    }
                                                }
                                            )
                                        }
                                    }.onAppear() {}
                                } .clipped().innerShadowFull(color: Color.gray.opacity(0.8), radius: 0.02)
                                .aspectRatio(1, contentMode: .fit).id(asset)
                            }
                        }.padding(8).padding(.top, 84).onAppear {
                            value.scrollTo("bottom_info", anchor: .bottom)
                        }  .onChange(of: photos_obsever.assets.count) { _ in
                            value.scrollTo("bottom_info")
                        }
                        HStack {
                            Spacer()
                            Text("\(photos_obsever.photo_count) Photos, \(photos_obsever.video_count) Videos").font(.custom("Helvetica Neue Regular", size: 20)).foregroundColor(.cgLightGray).lineLimit(1)
                            Spacer()
                        }.padding(.bottom, 12).id("bottom_info")
                    }
                }
            }
        }
    }
}

struct PhotoLibraryImageView: View {
    var asset: PHAsset
    var proxy: GeometryProxy
    @State var displayedImage: UIImage? = nil
    
    var body: some View {
        
        Image(uiImage: displayedImage ?? UIImage())
            .resizable().scaledToFill().frame(height: proxy.size.width).position(x: proxy.frame(in: .local).midX, y: proxy.frame(in: .local).midY)
            .onAppear(perform: {
                DispatchQueue.global(qos: .background).async {
                    
                    asset.getImageData(0, completionHandler: { num, image in
                        displayedImage = image
                    })
                }
            })
    }
    
}

class PhotosObserver: ObservableObject {
    @Published var assets = [PHAsset]()
    @Published var photo_count: Int = 0
    @Published var video_count: Int = 0
    init() {
        fetch_photos()
    }
    func fetch_photos() {
        DispatchQueue.global(qos: .background).async() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d",
                                             PHAssetMediaType.image.rawValue,
                                             PHAssetMediaType.video.rawValue)
        let assets = PHAsset.fetchAssets(with: fetchOptions)
        assets.enumerateObjects({ (object, count, stop) in
             DispatchQueue.main.async() {
            self.assets.append(object)
            if object.mediaType == .image { self.photo_count += 1 }
            if object.mediaType == .video { self.video_count += 1 }
              }
        })
          }
    }
}

extension PHAsset {
    func getImageData(_ index: Int, completionHandler: @escaping((_ index: Int, _ image: UIImage?)->Void)) {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(for: self, targetSize: CGSize(170, 170), contentMode: .aspectFill, options: options, resultHandler: { (image, info) in
            completionHandler(index, image)
        })
    }
    func getMainImage(completionHandler: @escaping((_ image: UIImage?)->Void)) {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(for: self, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options, resultHandler: { (image, info) in
            completionHandler(image)
        })
    }
}

struct photos_title_bar : View {
    var title: String
    public var back_action: (() -> Void)?
    public var destination_back_action: (() -> Void)?
    var show_albums_back: Bool?
    var show_destination_back: Bool?
    @Binding var forward_or_backward: Bool
    var body :some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.005), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 0.95, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025).opacity(0.65).shadow(color: Color.black.opacity(0.25), radius: 0.25, x: 0, y: -0.5) //Correct border width for added shadow
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(title).ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", size: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)).combined(with: .opacity)).id(title).frame(maxWidth: show_destination_back == true ? 140 : .infinity)
                    Spacer()
                }
                Spacer()
            }
            
            if show_albums_back == true {
                VStack {
                    Spacer()
                    HStack {
                        Button(action:{back_action?()}) {
                            ZStack {
                                Image("UINavigationBarBlackTranslucentBack").frame(width: 70, height: 33).scaledToFill().animation(.none)
                                HStack(alignment: .center) {
                                    Text("Albums").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", size: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                                }
                            }.padding(.leading, 8)
                        }
                        Spacer()
                    }
                    Spacer()
                }.animation(.none).animationsDisabled()
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        tool_bar_rectangle_button_larger_image_wide(button_type: .black, content: "UIButtonBarAction", use_image: true).padding(.trailing, 8)
                    }
                    Spacer()
                }.animation(.none).animationsDisabled()
                
            }
            
            if show_destination_back == true {
                VStack {
                    Spacer()
                    HStack {
                        Button(action:{destination_back_action?()}) {
                            ZStack {
                                Image("UINavigationBarBlackTranslucentBack").frame(width: 95, height: 33).scaledToFill().animation(.none)
                                HStack(alignment: .center) {
                                    Text("Camera Roll").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", size: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                                }
                            }.padding(.leading, 8)
                        }
                        Spacer()
                    }
                    Spacer()
                }.animation(.none).animationsDisabled()
                
            }
        }
    }
}

struct photos_select_view: View {
    @Binding var last_photo: UIImage
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @ObservedObject var photos_obsever: PhotosObserver
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                ScrollView {
                    Button(action: {
                        forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Camera Roll"}
                    }){
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Image(uiImage: last_photo).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95).clipped()
                                Group {
                                    Text("Camera Roll ").font(.custom("Helvetica Neue Bold", size: 16)).foregroundColor(.black)
                                        + Text("(\(photos_obsever.assets.count))").font(.custom("Helvetica Neue Regular", size: 16)).foregroundColor(Color(red: 127/255, green: 127/255, blue: 127/255))
                                }
                                .lineLimit(0).padding(.leading, 6).padding(.trailing, 40)
                                Spacer()
                                Image("UITableNext").padding(.trailing, 12)
                            }
                            Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                        }
                    }.padding(.top, 84)
                    Spacer()
                }
            }
        }
    }
}

extension Array {
    func unique<T:Hashable>(map: ((Element) -> (T)))  -> [Element] {
        var set = Set<T>()
        var arrayOrdered = [Element]()
        for value in self {
            if !set.contains(map(value)) {
                set.insert(map(value))
                arrayOrdered.append(value)
            }
        }

        return arrayOrdered
    }
}


var photos_tabs = ["Albums", "Places"]
struct PhotosTabView : View {
    @State var mapView = PlacesMapView()
    @Binding var selectedTab:String
    @Binding var current_nav_view: String
    @Binding var switcher_current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var last_photo: UIImage
    @Binding var selected_photo: PHAsset
    @ObservedObject var photos_obsever: PhotosObserver
    var body: some View{
        GeometryReader {geometry in
            VStack(spacing:0) {
                
                ScrollView([], showsIndicators: false) {
                    switch selectedTab {
                    case "Albums":
                    switch current_nav_view {
                    case "Main":
                        photos_select_view(last_photo: $last_photo, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, photos_obsever: photos_obsever).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Camera Roll":
                        camera_roll(current_nav_view: $current_nav_view, switcher_current_nav_view: $switcher_current_nav_view, forward_or_backward: $forward_or_backward, selected_photo: $selected_photo, photos_obsever: photos_obsever).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    default:
                        photos_select_view(last_photo: $last_photo, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, photos_obsever: photos_obsever).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    }
                    case "Places":
                        VStack(spacing: 0) {
                            Rectangle().fill(Color.black).frame(width: geometry.size.width, height: 24)
                        mapView.onAppear() {
                            mapView.geometry = geometry
                            let place_assets = photos_obsever.assets
                            for asset in place_assets.unique(map: {($0 as PHAsset).location}) {
                                
                                let annotation = MKPointAnnotation()
                                annotation.coordinate = asset.location?.coordinate ?? CLLocationCoordinate2D()
                                mapView.mapView.addAnnotation(annotation)
                            }
                        }
                        }
                    default:
                        Spacer()
                    }
                }.background(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0), .init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0.5), .init(color: Color.white, location: 0.5), .init(color: Color.white, location: 1)]), startPoint: .top, endPoint: .bottom))
                // for bottom overflow...
                ZStack {
                    Rectangle().fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.02), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom)).frame(height:57)
                    HStack(spacing: 0){
                        
                        ForEach(photos_tabs,id: \.self){image in
                            TabButton_Photos(image: image, selectedTab: $selectedTab, geometry: geometry)
                            
                            // equal spacing...
                            
                            if image != tabs.last{
                                
                                Spacer(minLength: 0)
                            }
                        }
                    }.frame(height:55)
                }.padding(.bottom, 0)
            }
        }
    }
    
}

struct TabButton_Photos : View {
    
    var image : String
    @Binding var selectedTab : String
    var geometry: GeometryProxy
    var body: some View{
        Button(action: {
            selectedTab = image
        }) {
            ZStack {
                if selectedTab == image {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.1)).frame(width: geometry.size.width/2 - 5, height: 51).blendMode(.screen)
                    VStack(spacing: 2) {
                        ZStack {
                            Image("\(image)_Photos").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Keypad" ? 25 : image == "Voicemail" ? 37.5 : 30.5, height: 30.5).overlay(
                                LinearGradient(gradient: Gradient(colors: [Color(red: 205/255, green: 233/255, blue: 249/255), Color(red: 75/255, green: 220/255, blue: 251/255)]), startPoint: .top, endPoint: .bottom)
                            ).mask(Image("\(image)_Photos").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Keypad" ? 25 : image == "Voicemail" ? 37.5 : 30.5, height: 30.5)).offset(y:-0.5)
                            
                            Image("\(image)_Photos").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Keypad" ? 25 : image == "Voicemail" ? 37.5 : 30, height: 30).overlay(
                                ZStack {
                                    LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 197/255, green: 210/255, blue: 229/255), location: 0), .init(color: Color(red: 99/255, green: 162/255, blue: 216/255), location: 0.47), .init(color: Color(red: 0/255, green: 145/255, blue: 230/255), location: 0.49), .init(color: Color(red: 21/255, green: 197/255, blue: 252/255), location: 1)]), startPoint: .top, endPoint: .bottom).rotationEffect(Angle(degrees: image == "More" ? 0 : -15)).frame(width: image == "More" ? 40 : 40, height: image == "Keypad" ? 38 : image == "Contacts" ? 34 : 30).brightness(0.095).offset(y: image == "Artists" ? 2 : 0)
                                }
                            ).mask(Image("\(image)_Photos").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Keypad" ? 25 : image == "Voicemail" ? 37.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.6), radius:2.5, x: 0, y:2.5)
                        }
                        HStack {
                            Spacer()
                            Text(image).foregroundColor(.white).font(.custom("Helvetica Neue Bold", size: 11))
                            Spacer()
                        }
                    }
                } else {
                    VStack(spacing: 2) {
                        Image("\(image)_Photos").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Keypad" ? 25 : image == "Voicemail" ? 37.5 : 30, height: 30).overlay(
                            LinearGradient(gradient: Gradient(colors: [Color(red: 157/255, green: 157/255, blue: 157/255), Color(red: 89/255, green: 89/255, blue: 89/255)]), startPoint: .top, endPoint: .bottom)
                        ).mask(Image("\(image)_Photos").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Keypad" ? 25 : image == "Voicemail" ? 37.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.75), radius: 0, x: 0, y: -1)
                        HStack {
                            Spacer()
                            Text(image).foregroundColor(Color(red: 168/255, green: 168/255, blue: 168/255)).font(.custom("Helvetica Neue Bold", size: 11))
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

enum PlayerGravity {
    case aspectFill
    case resize
    case fit
}

class PlayerView: UIView {
    
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    let gravity: PlayerGravity
    
    init(player: AVPlayer, gravity: PlayerGravity) {
        self.gravity = gravity
        super.init(frame: .zero)
        self.player = player
        self.backgroundColor = .black
        setupLayer()
    }
    
    func setupLayer() {
        switch gravity {
        
        case .aspectFill:
            playerLayer.contentsGravity = .resizeAspectFill
            playerLayer.videoGravity = .resizeAspectFill
            
        case .resize:
            playerLayer.contentsGravity = .resize
            playerLayer.videoGravity = .resize
            
        case .fit:
            playerLayer.contentsGravity = .resizeAspect
            playerLayer.videoGravity = .resizeAspect
            
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    // Override UIView property
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}

final class PlayerContainerView: UIViewRepresentable {
    typealias UIViewType = PlayerView
    
    let player: AVPlayer
    let gravity: PlayerGravity
    
    init(player: AVPlayer, gravity: PlayerGravity) {
        self.player = player
        self.gravity = gravity
    }
    
    func makeUIView(context: Context) -> PlayerView {
        return PlayerView(player: player, gravity: gravity)
    }
    
    func updateUIView(_ uiView: PlayerView, context: Context) { }
}

class PlayerViewModel: ObservableObject {
    
    @Published var player: AVPlayer = AVPlayer()
    @Published var player_time: CMTime?
    @Published var isPlaying: Bool = false {
        didSet {
            if isPlaying {
                play()
            } else {
                pause()
            }
        }
    }
    
    func restart() {
        self.player.seek(to: CMTime.zero)
    }
    
    func play() {
        self.player.play()
        
    }
    
    func pause() {
        player.pause()
    }
}

enum PlayerAction {
    case play
    case pause
}
