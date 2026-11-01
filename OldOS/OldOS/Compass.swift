//
//  Messages.swift
//  OldOS
//
//  Created by Zane on 6/30/25.
//

import SwiftUI
import Foundation
import CoreMotion
import CoreLocation
import Combine
struct Compass: View {
    @StateObject private var compass = MotionCompass()
    @Binding var current_view: String
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                StretchBottomOnlyImage("Compass Background", stretchStartRatio: 838/960).frame(width: geometry.size.width, height: geometry.size.height).clipped()
                VStack(spacing:0) {
                    status_bar().frame(minHeight: 24, maxHeight:24).zIndex(1)
                    VStack(spacing: 0) {
                        Image("DeviceArrow").resizable().scaledToFill().frame(width: 44, height: 32).padding(.top, 24)
                        Text(compass.headingText).font(.custom("Helvetica Neue Regular", fixedSize: 48)).foregroundColor(.white).shadow(color: Color.black.opacity(0.8), radius: 0, x: 0.0, y: -1).multilineTextAlignment(.center).lineLimit(1).padding(.top, 6)
                        Spacer()
                    }
                    Spacer()
                    compass_tool_bar(compass:compass, current_view: $current_view).frame(height: 45)
                }
                VStack(spacing: 0) {
                    Spacer().frame(height: geometry.size.height*433/2007) //This number comes from introspectively figuring out the top pixel offset
                    compass_face(compass:compass).frame(width: geometry.size.width*586/640, height: geometry.size.width*586/640)
                    Spacer()
                }
            }
        }
    }
}

struct compass_face: View {
    @ObservedObject var compass: MotionCompass
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("CompassBezel").resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height)
                Image("CompassFace").resizable().scaledToFill().frame(width: geometry.size.width*500/586, height: geometry.size.height*500/586)
                Image("CompassFaceHighlight").resizable().scaledToFill().frame(width: geometry.size.width*320/586*640/586, height: geometry.size.width*204/586*640/586).offset(y:-geometry.size.width*130/586*640/586)
                Image("CompassFaceRim").resizable().scaledToFill().padding(12).frame(width: geometry.size.width*488/586*640/586, height: geometry.size.height*488/586*640/586).rotationEffect(.degrees(-compass.heading))
                Image("CompassFaceDirection").resizable().scaledToFill().frame(width: geometry.size.width*375/586*640/586, height: geometry.size.width*375/586*640/586).offset(x: (200.0 - 198.0)  * (geometry.size.width * (375.0/586.0) * (640.0/586.0) / 400.0), y: -(200.0 - 192.0) * (geometry.size.width * (375.0/586.0) * (640.0/586.0) / 400.0)).rotationEffect(.degrees(-compass.heading))
                Image("CompassPivot").resizable().scaledToFill().frame(width: geometry.size.width*100/586*640/586, height: geometry.size.width*100/586*640/586)
                   // .offset(x: -1, y:geometry.size.width*100/586*640/586*0.15)
                Image("CompassFaceShadow").resizable().scaledToFill().frame(width: geometry.size.width*500/586, height: geometry.size.height*500/586)
            }.onAppear() {
                print(geometry.size.width*488/586*640/586)
            }
        }
            
    }
}

struct compass_tool_bar: View {
    @ObservedObject var compass: MotionCompass
    @Binding var current_view: String
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.005), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025).border_bottom(width: 0.95, edges: [.top], color: Color(red: 0/255, green: 0/255, blue: 0/255)).opacity(0.65)
            HStack {
                tool_bar_rectangle_button_larger_image(action: {
                    DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
                        withAnimation(.linear(duration: 0.32)) {
                            current_view = "Maps"
                        }
                    }
                }, button_type: .black, content: "CompassLocateRing", use_image: true).padding(.leading, 5)
                Spacer()
                Text(compass.coordinateText).font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.white).shadow(color: Color.black.opacity(0.8), radius: 0, x: 0.0, y: -1).multilineTextAlignment(.center).lineLimit(1)
                Spacer()
                tool_bar_rectangle_button_smaller_image(action: {}, button_type: .black, content: "CompassInfo", use_image: true).padding(.trailing, 5)
            }.transition(.opacity)
        }
    }
}

struct StretchBottomOnlyImage: View {
    let imageName: String
    let stretchStartRatio: CGFloat
    private let uiImage: UIImage?
    private let imgW: CGFloat
    private let imgH: CGFloat
    private let topCropH: CGFloat
    private let bottomCropH: CGFloat

    init(_ imageName: String, stretchStartRatio: CGFloat = 0.90) {
        self.imageName = imageName
        self.stretchStartRatio = stretchStartRatio

        let ui = UIImage(named: imageName)
        self.uiImage = ui
        self.imgW = ui?.size.width ?? 1
        self.imgH = ui?.size.height ?? 1
        self.topCropH = (ui?.size.height ?? 1) * stretchStartRatio
        self.bottomCropH = (ui?.size.height ?? 1) * (1 - stretchStartRatio)
    }

    var body: some View {
        GeometryReader { geo in
            if let ui = uiImage,
               let topCG = ui.cgImage?.cropping(to: CGRect(x: 0,
                                                           y: 0,
                                                           width: ui.scale * imgW,
                                                           height: ui.scale * topCropH).integralScaled(scale: ui.scale)),
               let bottomCG = ui.cgImage?.cropping(to: CGRect(x: 0,
                                                              y: ui.scale * topCropH,
                                                              width: ui.scale * imgW,
                                                              height: ui.scale * bottomCropH).integralScaled(scale: ui.scale)) {

                let topImg = Image(decorative: topCG, scale: ui.scale)
                let bottomImg = Image(decorative: bottomCG, scale: ui.scale)

                let scale = geo.size.width / imgW
                let displayedTopH = topCropH * scale
                let remainingH = max(0, geo.size.height - displayedTopH)

                VStack(spacing: 0) {
                    topImg
                        .resizable()
                        .interpolation(.high)
                        .frame(width: geo.size.width, height: displayedTopH, alignment: .top)
                        .clipped()

                    bottomImg
                        .resizable(resizingMode: .stretch)
                        .interpolation(.high)
                        .frame(width: geo.size.width, height: remainingH, alignment: .top)
                        .clipped()
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                .clipped()

            } else {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
        }
    }
}

final class MotionCompass: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var heading: Double = 0

    @Published private(set) var headingText: String = "–"
    @Published private(set) var coordinateText: String = "–"

    private let motion = CMMotionManager()
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 5
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        startMotion()
    }

    deinit {
        motion.stopDeviceMotionUpdates()
        locationManager.stopUpdatingLocation()
    }

    private func startMotion() {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] data, _ in
            guard let self, let att = data?.attitude else { return }
            let yawDeg = att.yaw * 180.0 / .pi
            var h = yawDeg + 90.0
            h = Self.wrap(h)
            h = 360.0 - h
            h = Self.wrap(h)

            self.heading = h
            self.headingText = Self.formatHeading(h)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let c = locations.last?.coordinate else { return }
        let latStr = Self.formatDMS(c.latitude, isLatitude: true)
        let lonStr = Self.formatDMS(c.longitude, isLatitude: false)
        coordinateText = "\(latStr), \(lonStr)"
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    @inline(__always) private static func wrap(_ x: Double) -> Double {
        var v = x.truncatingRemainder(dividingBy: 360)
        if v < 0 { v += 360 }
        return v
    }

    private static func formatHeading(_ deg: Double) -> String {
        let d = wrap(deg).rounded() // nearest degree
        let dirs = ["N","NE","E","SE","S","SW","W","NW","N"]
        let idx = Int(((d + 22.5) / 45.0).rounded(.down))
        let label = dirs[min(max(idx, 0), 8)]
        return "\(Int(d))° \(label)"
    }

    private static func formatDMS(_ decimalDegrees: Double, isLatitude: Bool) -> String {
        let hemi = isLatitude
            ? (decimalDegrees >= 0 ? "N" : "S")
            : (decimalDegrees >= 0 ? "E" : "W")

        var absVal = abs(decimalDegrees)
        let degrees = Int(absVal.rounded(.towardZero))
        absVal = (absVal - Double(degrees)) * 60
        let minutes = Int(absVal.rounded(.towardZero))
        let seconds = Int(((absVal - Double(minutes)) * 60).rounded())

        return "\(degrees)°\(minutes)'\(seconds)\" \(hemi)"
    }
}

@inline(__always) private func wrap(_ x: Double) -> Double {
    var v = x.truncatingRemainder(dividingBy: 360)
    if v < 0 { v += 360 }
    return v
}

private extension CGRect {
    func integralScaled(scale: CGFloat) -> CGRect {
        CGRect(x: (origin.x).rounded(),
               y: (origin.y).rounded(),
               width: (size.width).rounded(),
               height: (size.height).rounded())
    }
}
