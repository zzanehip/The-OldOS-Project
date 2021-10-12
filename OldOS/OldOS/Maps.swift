//
//  Maps.swift
//  OldOS
//
//  Created by Zane Kleinberg on 4/16/21.
//

import SwiftUI
import MapKit
import CoreLocation
import UIKit
import LocationProvider

struct Maps: View {
    @State var current_nav_view: String = "Main"
    @State var forward_or_backward: Bool = false
    @State var selected_segment: Int = 0
    @State var editing_state: String = "None"
    var locationManager = CLLocationManager()
    @State private var region = MKCoordinateRegion()
    @State var mapView = MapView()
    @State var did_present: Bool = false
    @State var search: String = ""
    @State var destination_search: String = ""
    @State var poly_overlay: MKOverlay?
    @State var directions_annotations: [MKAnnotation]?
    @State var search_annotations: [MKAnnotation]?
    @State var did_calculate_directions: Bool = false
    @State var directions_mode: Int = 0
    @ObservedObject var mapType: map_type_observer = map_type_observer()
    @ObservedObject var locationProvider : LocationProvider
    @Binding var instant_multitasking_change: Bool
    @Binding var show_multitasking: Bool
    var should_show: Bool
    init(instant_multitasking_change: Binding<Bool>, show_multitasking: Binding<Bool>, should_show: Bool) {
        _instant_multitasking_change = instant_multitasking_change
        _show_multitasking = show_multitasking
        self.should_show = should_show
        locationProvider = LocationProvider()
        do {try locationProvider.start()}
        catch {
            print("No location access.")
            locationProvider.requestAuthorization()
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing:0) {
                    Spacer().frame(height: 24+60)
                    mapView.onAppear() {
                        mapView.geometry = geometry
                        mapView.curl_view = XBCurlView(frame: CGRect(geometry.size.width, geometry.size.height-129), antialiasing: true)
                        mapView.mapType = mapType
                    }
                    maps_tool_bar(selected_segment: $selected_segment, did_present: $did_present, instant_multitasking_change: $instant_multitasking_change, mapType: mapType, settings_action: {
                                    if !did_present {
                                        mapView.present()
                                        did_present = true
                                    } else {
                                        mapView.unpresent()
                                        did_present = false
                                    }}, location_action: {
                                        withAnimation() {
                                            mapType.location_selected.toggle()
                                            if mapType.location_selected {
                                                mapView.go_to_user_location()
                                            }
                                        }
                                    }).frame(height: 45)
                }
                if editing_state == "Active" || editing_state == "Active_Empty" {
                    Color.black.opacity(0.9).edgesIgnoringSafeArea(.all)
                }
                VStack(spacing:0) {
                    status_bar_in_app().frame(minHeight: 24, maxHeight:24).zIndex(1)
                    if selected_segment == 0 {
                        if editing_state != "None" {
                            generic_title_bar_clear_cancel(title: "Search", done_action: {hideKeyboard()}, clear_action: {search = ""}, show_done: true, show_clear: true).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 60, maxHeight:60).transition(.asymmetric(insertion: .move(edge:.top), removal: .move(edge:.top)))
                        }
                        maps_title_bar(title: "", selected_segment: $selected_segment, forward_or_backward: $forward_or_backward, search: $search, editing_state: $editing_state, show_edit: false, show_plus: false, search_action: {
                            search_for_location()
                        }).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 60, maxHeight:60).zIndex(2)
                    } else {
                        if did_calculate_directions == false {
                        if editing_state != "None" {
                            generic_title_bar_clear_cancel(title: "Directions", done_action: {hideKeyboard()}, clear_action: {search = ""}, show_done: true, show_clear: true).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 60, maxHeight:60).transition(.asymmetric(insertion: .move(edge:.top), removal: .move(edge:.top)))
                        }
                        maps_directions_bar(title: "", selected_segment: $selected_segment, forward_or_backward: $forward_or_backward, search: $destination_search, editing_state: $editing_state, show_edit: false, show_plus: false, search_action: {
                            var localSearchRequest = MKLocalSearch.Request()
                            localSearchRequest.naturalLanguageQuery = destination_search
                            var localSearch = MKLocalSearch(request: localSearchRequest)
                            localSearch.start { (localSearchResponse, error) -> Void in
                                if localSearchResponse == nil{
                                    return
                                }
                                let response = localSearchResponse?.mapItems.first
                                if mapView.mapView.annotations.count != 0 {
                                    mapView.mapView.removeAnnotations(mapView.mapView.annotations)
                                }
                                for overlay in mapView.mapView.overlays {
                                    if let polyline = overlay as? MKPolyline {
                                        mapView.mapView.removeOverlay(polyline)
                                    }
                                  }
                                mapView.calculate_route(start: locationManager.location?.coordinate ?? CLLocationCoordinate2D(), end: response?.placemark.coordinate ?? CLLocationCoordinate2D(), destination_title: response?.name ?? "", transport_type: .automobile)
                                did_calculate_directions = true
                            }
                        }).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 90, maxHeight:90).zIndex(2)
                        } else {
                            maps_directions_mode_title_bar(title: "", selected_segment: $directions_mode, forward_or_backward: $forward_or_backward, instant_multitasking_change: $instant_multitasking_change, show_edit: true, show_start: true, edit_action: {
                                did_calculate_directions = false
                            }).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 60, maxHeight:60).zIndex(2)
                            maps_directions_mode_title_bar_footer(mapType: mapType).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 62, maxHeight:62).zIndex(2)
                        }
                    }
                    Spacer()
                }
            }
        }
        .onAppear() {
            UIScrollView.appearance().bounces = true
            region = MKCoordinateRegion(center: locationManager.location?.coordinate ?? CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25))
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
        }.onChange(of: mapType.type, perform: {_ in
            mapView.update_map()
        }).onChange(of: selected_segment, perform: {_ in
            if selected_segment == 0 {
                if let polyline = mapView.mapView.overlays.filter({$0 is MKPolyline}).first as? MKOverlay {
                    poly_overlay = polyline
                    directions_annotations = mapView.mapView.annotations
                    mapView.mapView.removeOverlay(polyline)
                    mapView.mapView.removeAnnotations(mapView.mapView.annotations)
                    if let searches = search_annotations {
                    mapView.mapView.addAnnotations(searches)
                    }
                }
            } else {
                search_annotations = mapView.mapView.annotations
                mapView.mapView.removeAnnotations(mapView.mapView.annotations)
                if poly_overlay != nil, let polyline = poly_overlay, let annotations = directions_annotations {
                    mapView.mapView.addOverlay(polyline, level: .aboveLabels)
                    mapView.mapView.addAnnotations(annotations)
                }
            }
        }).onChange(of: directions_mode, perform: {_ in
            var localSearchRequest = MKLocalSearch.Request()
            localSearchRequest.naturalLanguageQuery = destination_search
            var localSearch = MKLocalSearch(request: localSearchRequest)
            localSearch.start { (localSearchResponse, error) -> Void in
                if localSearchResponse == nil{
                    return
                }
                let response = localSearchResponse?.mapItems.first
                if mapView.mapView.annotations.count != 0 {
                    mapView.mapView.removeAnnotations(mapView.mapView.annotations)
                }
                for overlay in mapView.mapView.overlays {
                    if let polyline = overlay as? MKPolyline {
                        mapView.mapView.removeOverlay(polyline)
                    }
                  }
                mapView.calculate_route(start: locationManager.location?.coordinate ?? CLLocationCoordinate2D(), end: response?.placemark.coordinate ?? CLLocationCoordinate2D(), destination_title: response?.name ?? "", transport_type: easy_int_to_transport(directions_mode))
            }
        }).clipped().onChange(of: mapType.type, perform: {_ in
            if mapType.type == .mutedStandard {
                mapView.add_legal_view()
            } else {
                mapView.remove_legal_view()
            }
        }).shadow(color: Color.black.opacity((instant_multitasking_change == true && should_show == true) ? 0.85 : 0), radius: 6, x: 0, y: 4).disabled((show_multitasking == true && should_show == true))
    }
    
    func easy_int_to_transport(_ val:Int) -> MKDirectionsTransportType {
        switch val {
        case 0:
            return .automobile
        case 1:
            return .transit
        case 2:
            return .walking
        default:
            return .automobile
        }
    }
    
    func search_for_location() {
        if mapView.mapView.annotations.count != 0 {
            var annotation = mapView.mapView.annotations[0]
            mapView.mapView.removeAnnotation(annotation)
        }
        var localSearchRequest = MKLocalSearch.Request()
        localSearchRequest.naturalLanguageQuery = search
        var localSearch = MKLocalSearch(request: localSearchRequest)
        localSearch.start { (localSearchResponse, error) -> Void in
            mapView.mapView.removeAnnotations(mapView.mapView.annotations)
            if localSearchResponse == nil{
                return
            }
            
            for item in localSearchResponse?.mapItems ?? []{
                
                
                print("Name = \(String(describing: item.name))")
                
                print("Phone = \(String(describing: item.phoneNumber))")
                
                
                let annotation = MKPointAnnotation()
                
                annotation.title = item.name
                
                annotation.coordinate = item.placemark.coordinate
                
                annotation.subtitle = item.phoneNumber
                mapView.mapView.centerCoordinate = item.placemark.coordinate
                mapView.mapView.addAnnotation(annotation)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                    mapView.mapView.selectAnnotation(annotation, animated: true)
                }
            }
            
        }
    }
}

struct maps_callout_view: View {
    var text: String
    var body: some View {
        ZStack {
            HStack(spacing:0) {
                Image("UICalloutViewLeftCap").frame(height: 114/2)
                Image("UICalloutViewBottomAnchor").offset(y: 6.5)
                Image("UICalloutViewRightCap").frame(height: 114/2)
            }
            HStack {
                Text(text).foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 16))  .shadow(color: Color.black.opacity(0.51), radius: 0, x: 0.0, y: -2/3).lineLimit(0).offset(y: -6.5)
                Image("ABTableNextButton").offset(y: -6.5)
            }.padding([.leading, .trailing], 20)
        }.fixedSize(horizontal: true, vertical: false).frame(height: 70)
    }
}

struct maps_background: View {
    @State var selected_view: String = "Map"
    @ObservedObject var mapType: map_type_observer = map_type_observer()
    var options = ["Map", "Satellite", "Hybrid", "List"]
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("SettingsTexture").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).frame(width:geometry.size.width, height: geometry.size.height)
                VStack {
                    Spacer()
                    Button(action: {}) {
                        ZStack {
                            Image("UITexturedButton").resizable().scaledToFill().frame(width: geometry.size.width - 35, height: 45)
                            Text("Drop Pin").font(.custom("Helvetica Neue Bold", fixedSize: 18)).gradientForeground(colors: [Color(red: 36/255, green: 38/255, blue: 52/255), Color(red: 52/255, green: 55/255, blue: 78/255)], startPoint: .top, endPoint: .bottom).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                        }
                    }.frame(width: geometry.size.width - 35, height: 45)
                    Spacer().frame(height: 22.5)
                    Button(action: {}) {
                        ZStack {
                            Image("UITexturedButton").resizable().scaledToFill().frame(width: geometry.size.width - 35, height: 45)
                            Text("Show Traffic").font(.custom("Helvetica Neue Bold", fixedSize: 18)).gradientForeground(colors: [Color(red: 36/255, green: 38/255, blue: 52/255), Color(red: 52/255, green: 55/255, blue: 78/255)], startPoint: .top, endPoint: .bottom).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                        }
                    }.frame(width: geometry.size.width - 35, height: 45)
                    Spacer().frame(height: 22.5)
                    
                    ZStack {
                        Image("UITexturedButton").resizable().scaledToFill().frame(width: geometry.size.width - 35, height: 45)
                        HStack(spacing: 0) {
                            ForEach(0..<options.count) {index in
                                if selected_view == options[index] {
                                    selected_textured_segment(text: options[index], geometry: geometry, index: index, selected_view: $selected_view)
                                } else {
                                    unselected_textured_segment(text: options[index], geometry: geometry, index: index, options: options, selected_view: $selected_view)
                                }
                            }
                        }
                        
                    }.frame(width: geometry.size.width - 35, height: 45).padding(.bottom, 20)
                    
                    
                    
                    
                }.frame(width:geometry.size.width, height: geometry.size.height)
            }.frame(width:geometry.size.width, height: geometry.size.height)
        }.onChange(of: selected_view, perform: {_ in
            switch selected_view {
            case "Map":
                mapType.type = .standard
            case "Satellite":
                mapType.type = .satellite
            case "Hybrid":
                mapType.type = .hybrid
            case "List":
                mapType.type = .mutedStandard //We never use the mutedStandard type, so let's just designate it as a list...
            default:
                mapType.type = .standard
            }
        })
    }
}


class map_type_observer: ObservableObject {
    @Published var type: MKMapType = .standard
    @Published var location_selected: Bool = false
    @Published var distance: String = ""
    @Published var time: String = ""
}

struct selected_textured_segment: View {
    var text: String
    var geometry: GeometryProxy
    var index: Int
    @Binding var selected_view: String
    var body: some View {
        if index == 0 {
            Button(action:{selected_view = text}) {
                ZStack {
                    HStack(spacing: 0) {
                        Image("UISegmentTexturedButtonSelectedLeftCap").frame(width: 18, height: 49.5)
                        Image("UISegmentTexturedButtonSelectedCenter").frame(width: (geometry.size.width - 35 - 3)/4 - 18, height: 49)
                        Image("UISegmentTexturedSelectedDivider").frame(width: 1, height: 49)
                        
                    }
                    Text(text).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0, y: -0.66)
                }
            }
        }
        else if index == 3 {
            Button(action:{selected_view = text}) {
                ZStack {
                    HStack(spacing: 0) {
                        Image("UISegmentTexturedButtonSelectedCenter").frame(width: (geometry.size.width - 35 - 2)/4 - 18, height: 49)
                        Image("UISegmentTexturedButtonSelectedLeftCap").frame(width: 18, height: 49.5).rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        
                    }
                    Text(text).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0, y: -0.66)
                }
            }
        }
        else {
            Button(action:{selected_view = text}) {
                ZStack {
                    HStack(spacing: 0) {
                        Image("UISegmentTexturedButtonSelectedCenter").frame(width: (geometry.size.width - 35 - 3)/4, height: 49)
                        Image("UISegmentTexturedSelectedDivider").frame(width: 1, height: 49)
                        
                    }
                    Text(text).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0, y: -0.66)
                }
            }
        }
    }
}

struct unselected_textured_segment: View {
    var text: String
    var geometry: GeometryProxy
    var index: Int
    var options: [String]
    @Binding var selected_view: String
    var body: some View {
        if index != 3 {
            Button(action:{selected_view = text}) {
                ZStack {
                    HStack(spacing: 0) {
                        Spacer().frame(width: (geometry.size.width - 35 - 3)/4)
                        Image(options[optional: index + 1] == selected_view ? "UISegmentTexturedSelectedDivider" : "UISegmentTexturedDivider").frame(width: 1, height: 49)
                        
                    }
                    Text(text).font(.custom("Helvetica Neue Bold", fixedSize: 14)).gradientForeground(colors: [Color(red: 36/255, green: 38/255, blue: 52/255), Color(red: 52/255, green: 55/255, blue: 78/255)], startPoint: .top, endPoint: .bottom).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                }
            }
        } else {
            Button(action:{selected_view = text; print(text, "ZL")}) {
                ZStack {
                    HStack(spacing: 0) {
                        Spacer().frame(width: (geometry.size.width - 35 - 3)/4)
                        Image("UISegmentTexturedDivider").frame(width: 1, height: 49).opacity(0)
                    }
                    Text(text).font(.custom("Helvetica Neue Bold", fixedSize: 14)).gradientForeground(colors: [Color(red: 36/255, green: 38/255, blue: 52/255), Color(red: 52/255, green: 55/255, blue: 78/255)], startPoint: .top, endPoint: .bottom).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                }
            }
        }
    }
}

struct legal_view: View {
    var body: some View {
        ZStack {
            settings_main_list()
            VStack {
                Spacer()
            HStack {
                Spacer()
                Text("Legal Notices...").underline().foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                Spacer()
            }
                Spacer()
            }
        }
    }
}

struct google_logo_view: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Image("GoogleBadge")
                Spacer()
            }
        }
    }
}

struct MapView: UIViewControllerRepresentable {
    
    var mapView = MKMapView()
    var view = UIView()
    var view_controller = UIViewController()
    var view_controller2 = UIViewController()
    var curl_view: XBCurlView?
    var geometry: GeometryProxy?
    var background_hosting = UIHostingController(rootView: maps_background())
    var legal_hosting = UIHostingController(rootView: legal_view())
    var tileRenderer: MKTileOverlayRenderer?
    @ObservedObject var mapType: map_type_observer = map_type_observer()
    func makeUIViewController(context: Context) -> UIViewControllerType {
        context.coordinator.setupTileRenderer()
        background_hosting.rootView.mapType = mapType
        view_controller.view.addSubview(background_hosting.view)
        view_controller.view.addSubview(mapView)
        view_controller2.view.backgroundColor = UIColor.white
        mapView.frame = CGRect(geometry?.size.width ?? 0, (geometry?.size.height ?? 0) - 129)
        mapView.delegate = context.coordinator
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        view_controller.presentationController?.delegate = context.coordinator
        let viewRegion = MKCoordinateRegion(center: CLLocationManager().location?.coordinate ?? CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.0125, longitudeDelta: 0.0125))
        mapView.setRegion(viewRegion, animated: false)
        mapView.showsUserLocation = true
        curl_view?.draw(onFrontOfPage: mapView)
        return view_controller
    }
    
    func go_to_user_location() {
        let viewRegion = MKCoordinateRegion(center: CLLocationManager().location?.coordinate ?? CLLocationCoordinate2D(), span: MKCoordinateSpan(latitudeDelta: 0.0125, longitudeDelta: 0.0125))
        mapView.setRegion(viewRegion, animated: true)
    }
    
    func add_legal_view() {
        print("called add legal")
        legal_hosting.view.frame = mapView.frame
        mapView.addSubview(legal_hosting.view)
    }
    func remove_legal_view() {
        if legal_hosting.view.isDescendant(of: mapView) {
            legal_hosting.view.removeFromSuperview()
        }
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
        mapView.frame = CGRect(geometry?.size.width ?? 0, (geometry?.size.height ?? 0) - 129)
        let google_view = UIHostingController(rootView: google_logo_view())
        var google_image = UIImageView(image: UIImage(named: "GoogleBadge"))
        google_image.isUserInteractionEnabled = false
        google_image.frame = CGRect(10, mapView.frame.size.height - google_image.frame.size.height - 10 , google_image.frame.size.width, google_image.frame.size.height)
        google_image.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        mapView.addSubview(google_image)
        background_hosting.view.frame = CGRect(geometry?.size.width ?? 0, (geometry?.size.height ?? 0) - 129)
        background_hosting.rootView.mapType = mapType
    }
    
    func calculate_route(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, destination_title: String, transport_type: MKDirectionsTransportType) {
        mapView.showRouteOnMap(pickupCoordinate: start, destinationCoordinate: end, destination_title: destination_title, transport_type: transport_type, completion: { (time, distance) in
            mapType.time = time
            mapType.distance = distance
        })
    }
    
    func present() {
        curl_view?.isOpaque = false
        curl_view?.pageOpaque = false
        curl_view?.curl(mapView, cylinderPosition: CGPoint((geometry?.size.width ?? 0) - 5, ((geometry?.size.height ?? 0) - 129)/7.5), cylinderAngle: CGFloat(.pi-0.23), cylinderRadius: 130, animatedWithDuration: 0.6)
    }
    
    func unpresent() {
        curl_view?.uncurlAnimated(withDuration: 0.6)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, UIAdaptivePresentationControllerDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
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
            let calloutView = UIHostingController(rootView: maps_callout_view(text: (view.annotation?.title ?? "") ?? ""))
            calloutView.view.translatesAutoresizingMaskIntoConstraints = false
            calloutView.view.backgroundColor = .clear
            view.backgroundColor = .clear
            guard !(view.annotation?.isKind(of: MKUserLocation.self) ?? false) else {
                view.addSubview(calloutView.view)
                NSLayoutConstraint.activate([
                    calloutView.view.bottomAnchor.constraint(equalTo: view.topAnchor, constant: 4.5),
                    calloutView.view.heightAnchor.constraint(equalToConstant: 70),
                    calloutView.view.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: view.calloutOffset.x)
                ])
                return
            }
            UIView.transition(with: mapView, duration: 0.25, options: [.transitionCrossDissolve], animations: {
                view.addSubview(calloutView.view)
            }, completion: nil)
            NSLayoutConstraint.activate([
                calloutView.view.bottomAnchor.constraint(equalTo: view.topAnchor, constant: 4),
                calloutView.view.heightAnchor.constraint(equalToConstant: 70),
                calloutView.view.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: view.calloutOffset.x - 8.5)
            ])
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
                //return nil
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
            
            return annotationView
            
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            switch overlay {
            case let polyline as MKPolyline:
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(red: 171/255, green: 119/255, blue: 238/255, alpha: 0.8)
                renderer.lineWidth = 8
                return renderer
            
            case let tile as MKTileOverlay:
                return parent.tileRenderer ?? MKOverlayRenderer()
            // you can add more `case`s for other overlay types as needed

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

extension MKCoordinateRegion: Equatable
{
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool
    {
        if lhs.center.latitude != rhs.center.latitude || lhs.center.longitude != rhs.center.longitude
        {
            return false
        }
        if lhs.span.latitudeDelta != rhs.span.latitudeDelta || lhs.span.longitudeDelta != rhs.span.longitudeDelta
        {
            return false
        }
        return true
    }
}

struct maps_tool_bar: View {
    @Binding var selected_segment: Int
    @Binding var did_present: Bool
    @Binding var instant_multitasking_change: Bool
    @ObservedObject var mapType: map_type_observer
    var settings_action: (() -> Void)?
    var location_action: (() -> Void)?
    var body: some View {
        ZStack {
            LinearGradient([(color: Color(red: 230/255, green: 230/255, blue: 230/255), location: 0), (color: Color(red: 180/255, green: 191/255, blue: 206/255), location: 0.04), (color: Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.51), (color: Color(red: 126/255, green: 148/255, blue: 176/255), location: 0.51), (color: Color(red: 110/255, green: 132/255, blue: 162/255), location: 1)], from: .top, to: .bottom).border_bottom(width: 1, edges: [.top], color: Color(red: 45/255, green: 48/255, blue: 51/255))//I just discovered it was much easier to do this...duh
            HStack {
                tool_bar_rectangle_button_larger_image(action: {location_action?()}, button_type: mapType.location_selected == false ? .blue_gray : .blue, content: "TrackingLocation", use_image: true, height_modifier: -2).padding(.leading, 6)
                Spacer()
                dual_segmented_control(selected: $selected_segment, instant_multitasking_change: $instant_multitasking_change, first_text: "Search", second_text: "Directions", should_animate: false).frame(width: 220, height: 30)
                Spacer()
                Button(action: {settings_action?()}) {
                    Image(did_present ? "UIButtonBarPageCurlSelected" : "UIButtonBarPageCurlDefault")
                }.padding(.trailing, 6)
            }.transition(.opacity)
        }
        
    }
}




struct maps_title_bar : View {
    var title:String
    @Binding var selected_segment: Int
    @Binding var forward_or_backward: Bool
    @Binding var search: String
    @State var place_holder = ""
    @State var show_bk: Bool = true
    var no_right_padding: Bool?
    @Binding var editing_state: String
    private let gradient = LinearGradient([.white, .white], to: .trailing)
    private let cancel_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    var show_edit: Bool
    var show_plus: Bool
    public var edit_action: (() -> Void)?
    public var plus_action: (() -> Void)?
    public var search_action: (() -> Void)?
    var body :some View {
        GeometryReader {geometry in
            ZStack {
                LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.49), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.49), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            HStack {
                                HStack {
                                    Spacer(minLength: 5)
                                    HStack (alignment: .center,
                                            spacing: 10) {
                                        Image("search_icon").resizable().font(Font.title.weight(.medium)).frame(width: 15, height: 15).padding(.leading, 5)
                                        
                                        TextField ("Search or Address", text: $search, onEditingChanged: { (changed) in
                                            if changed  {
                                                withAnimation() {
                                                    editing_state = "Active_Empty"
                                                }
                                            } else {
                                                withAnimation() {
                                                    editing_state = "None"
                                                }
                                            }
                                        }) {
                                            search_action?()
                                        }.onChange(of: search) { _ in
                                            if search != "" {
                                                editing_state = "Active"
                                            } else {
                                                if editing_state != "None" {
                                                    editing_state = "Active_Empty"
                                                }
                                            }
                                        }.keyboardType(.alphabet).disableAutocorrection(true)
                                        if search.count != 0, editing_state != "None" {
                                            Button(action:{search = ""}) {
                                                Image("UITextFieldClearButton").animationsDisabled()
                                            }.fixedSize()
                                        }
                                    }
                                    
                                    .padding([.top,.bottom], 5)
                                    .padding(.leading, 5)
                                    .cornerRadius(40)
                                    Spacer(minLength: 8)
                                } .ps_innerShadow(.capsule(gradient), radius:1.6, offset: CGPoint(0, 1), intensity: 0.7).strokeCapsule(Color(red: 166/255, green: 166/255, blue: 166/255), lineWidth: 0.33).padding(.leading, 5.5).padding(.trailing, 5.5).overlay(HStack {
                                    Spacer()
                                    if editing_state != "Active" {
                                    Image("Bookmarks_Maps").padding(.trailing, 8).padding(.top, 1.5)
                                    }
                                })
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    Spacer()
                }
                
            }
        }
    }
}


struct maps_directions_bar : View {
    var title:String
    @Binding var selected_segment: Int
    @Binding var forward_or_backward: Bool
    @Binding var search: String
    @State var place_holder = ""
    var no_right_padding: Bool?
    @Binding var editing_state: String
    private let gradient = LinearGradient([.white, .white], to: .trailing)
    private let cancel_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    var show_edit: Bool
    var show_plus: Bool
    public var edit_action: (() -> Void)?
    public var plus_action: (() -> Void)?
    public var search_action: (() -> Void)?
    var body :some View {
        GeometryReader {geometry in
            ZStack {
                LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.29), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.29), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.015)
                VStack {
                    Spacer()
                    HStack {
                    tool_bar_rectangle_button_larger_image(action: {}, button_type: .blue_gray, content: "DirectionsSwap", use_image: true, height_modifier: -2).padding(.leading, 6)
                        VStack {
                    HStack {
                        Spacer()
                        VStack {
                            HStack {
                                HStack {
                                    Spacer(minLength: 5)
                                    HStack (alignment: .center,
                                            spacing: 10) {
                                        Text("Start:").foregroundColor(Color(red: 143/255, green: 143/255, blue: 143/255)).font(.custom("Helvetica Neue Regular", fixedSize: 16))
                                        // .foregroundColor(.gray)
                                        ZStack {
                                        TextField ("Current Location", text: $search, onEditingChanged: { (changed) in
                                            if changed  {
                                                withAnimation() {
                                                    editing_state = "Active_Empty"
                                                }
                                            } else {
                                                withAnimation() {
                                                    editing_state = "None"
                                                }
                                            }
                                        }) {
                                            search_action?()
                                        }.onChange(of: search) { _ in
                                            if search != "" {
                                                editing_state = "Active"
                                            } else {
                                                if editing_state != "None" {
                                                    editing_state = "Active_Empty"
                                                }
                                            }
                                        }.keyboardType(.alphabet).disableAutocorrection(true).opacity(0).disabled(true)
                                            //I'm too lazy to figure out the proper size of this text field, so let's just leave it here and avoid any unnecesary calculations that will slow down the rendering of the view.
                                            HStack {
                                                Text("Current Location").foregroundColor(Color(red: 53/255, green: 86/255, blue: 246/255)).font(.custom("Helvetica Neue Regular", fixedSize: 16)).offset(x: -2, y: 0.5)
                                                Spacer()
                                        }
                                        }
                                        if search.count != 0, editing_state != "None" {
                                            Button(action:{search = ""}) {
                                                Image("UITextFieldClearButton").animationsDisabled()
                                            }.fixedSize().disabled(true).opacity(0)
                                        }
                                    }
                                    
                                    .padding([.top,.bottom], 5)
                                    .padding(.leading, 5)
                                    .cornerRadius(6)
                                    Spacer(minLength: 8)
                                } .ps_innerShadow(.roundedRectangle(6, LinearGradient([(color: Color.white, location: 0), (color: Color.white, location: 1)], from: .leading, to: .trailing)), radius:1.8, offset: CGPoint(0, 1), intensity: 0.5).strokeRoundedRectangle(6, Color(red: 84/255, green: 108/255, blue: 138/255), lineWidth: 0.65).padding(.leading, 2.5).padding(.trailing, 1)
                            }
                        }
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        VStack {
                            HStack {
                                HStack {
                                    Spacer(minLength: 5)
                                    HStack (alignment: .center,
                                            spacing: 10) {
                                        Text("End:").foregroundColor(Color(red: 143/255, green: 143/255, blue: 143/255)).font(.custom("Helvetica Neue Regular", fixedSize: 16))
                                        
                                        TextField ("", text: $search, onEditingChanged: { (changed) in
                                            if changed  {
                                                withAnimation() {
                                                    editing_state = "Active_Empty"
                                                }
                                            } else {
                                                withAnimation() {
                                                    editing_state = "None"
                                                }
                                            }
                                        }) {
                                            search_action?()
                                        }.onChange(of: search) { _ in
                                            if search != "" {
                                                editing_state = "Active"
                                            } else {
                                                if editing_state != "None" {
                                                    editing_state = "Active_Empty"
                                                }
                                            }
                                        }.keyboardType(.alphabet).disableAutocorrection(true)
                                        if search.count != 0, editing_state != "None" {
                                            Button(action:{search = ""}) {
                                                Image("UITextFieldClearButton").animationsDisabled()
                                            }.fixedSize()
                                        }
                                    }
                                    
                                    .padding([.top,.bottom], 5)
                                    .padding(.leading, 5)
                                    .cornerRadius(6)
                                    Spacer(minLength: 8)
                                }.ps_innerShadow(.roundedRectangle(6, LinearGradient([(color: Color.white, location: 0), (color: Color.white, location: 1)], from: .leading, to: .trailing)), radius:1.8, offset: CGPoint(0, 1), intensity: 0.5).strokeRoundedRectangle(6, Color(red: 84/255, green: 108/255, blue: 138/255), lineWidth: 0.65).padding(.leading, 2.5).padding(.trailing, 1)
                            }
                        }
                        Spacer()
                    }
                        }
                    }
                    Spacer()
                
                }
            }
        }
    }
}

struct maps_directions_mode_title_bar : View {
    var title:String
    @Binding var selected_segment: Int
    @Binding var forward_or_backward: Bool
    @Binding var instant_multitasking_change: Bool
    private let gradient = LinearGradient([.white, .white], to: .trailing)
    private let cancel_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    var show_edit: Bool
    var show_start: Bool
    public var edit_action: (() -> Void)?
    public var start_action: (() -> Void)?
    public var search_action: (() -> Void)?
    var body :some View {
        GeometryReader {geometry in
            ZStack {
                LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.49), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.49), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
                VStack {
                    Spacer()
                    HStack {
                        tool_bar_rectangle_button(action: {edit_action?()}, button_type: .blue_gray, content: " Edit ").padding(.leading, 5).padding(.trailing, 12)
                        Spacer()
                        tri_segmented_control_image(selected: $selected_segment, instant_multitasking_change: $instant_multitasking_change, first_image: "Driving", second_image: "Transit", third_image: "Walking", should_animate: false).frame(height: 30)
                        Spacer()
                        tool_bar_rectangle_button(action: {start_action?()}, button_type: .blue, content: "Start").padding(.trailing, 5).padding(.leading, 12)
                    }
                    Spacer()
                }
            }
        }
    }
}

struct maps_directions_mode_title_bar_footer: View {
    @ObservedObject var mapType: map_type_observer
    var body :some View {
        GeometryReader {geometry in
            ZStack {
                LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 110/255, green: 133/255, blue: 162/255).opacity(0.9), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255))
                VStack {
                    Spacer()
                    HStack(spacing: 2) {
                        Spacer()
                        Group {
                        Text(mapType.distance).font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.white)
                            + Text(" \(mapType.time)").font(.custom("Helvetica Neue Regular", fixedSize: 16)).foregroundColor(.white)
                        }.shadow(color: Color.black.opacity(0.61), radius: 0, x: 0.0, y: -1).lineLimit(0)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
}


class SourcePointAnnotation : MKPointAnnotation {
    var identifier: String?
}

extension MKMapView {

    func showRouteOnMap(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D, destination_title: String, transport_type: MKDirectionsTransportType, completion: @escaping (String, String) -> Void) {
    let sourcePlacemark = MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil)
    let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil)
    
    let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
    let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
    
    let sourceAnnotation = SourcePointAnnotation()
    
    if let location = sourcePlacemark.location {
        sourceAnnotation.coordinate = location.coordinate
        sourceAnnotation.title = String("\(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude))")
        sourceAnnotation.identifier = "green"
    }
    
    let destinationAnnotation = MKPointAnnotation()
    
    if let location = destinationPlacemark.location {

        destinationAnnotation.coordinate = location.coordinate
        destinationAnnotation.title = destination_title
    }
        self.showAnnotations([sourceAnnotation,destinationAnnotation], animated: true )
    
    let directionRequest = MKDirections.Request()
    directionRequest.source = sourceMapItem
    directionRequest.destination = destinationMapItem
    directionRequest.transportType = transport_type
    
    // Calculate the direction
    let directions = MKDirections(request: directionRequest)
    
    directions.calculate {
        (response, error) -> Void in
        
        guard let response = response else {
            if let error = error {
                print("Error: \(error)")
            }
            
            return
        }
        let route = response.routes[0]
        let time = route.expectedTravelTime
        let distance = route.distance
        let df = MKDistanceFormatter()
        df.unitStyle = .full
    self.addOverlay((route.polyline), level: MKOverlayLevel.aboveLabels)
        let rect = route.polyline.boundingMapRect
        destinationAnnotation.coordinate = route.polyline.points()[route.polyline.pointCount - 1].coordinate
        let adjusted_rect = self.regionThatFits(MKCoordinateRegion(rect))
        completion(ti_format(duration: time), df.string(fromDistance: distance))
    }
        
}
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        let latidude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude

        return CLLocation(latitude: latidude, longitude: longitude)
    }

}

func ti_format(duration: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.day, .hour, .minute]
    formatter.unitsStyle = .full
    formatter.maximumUnitCount = 2

    return (formatter.string(from: duration) ?? "").replacingOccurrences(of: ",", with: "")
}
