//
//  LockScreen.swift
//  OldOS
//
//  Created by Zane Kleinberg on 1/10/21.
//

import SwiftUI
import CoreTelephony
import PureSwiftUITools
import AVKit

struct LockScreen: View {
    @Binding var current_view: String
    @State var out_slides: CGFloat = 0.0
    @State var charging: Bool = false
    @State var battery_level = UIDevice.current.batteryLevel * 100
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var apps_scale_height: CGFloat
    let battery_observer = NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)
    let battery_level_observer = NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
    var userDefaults = UserDefaults.standard
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if userDefaults.bool(forKey: "Camera_Wallpaper_Lock") == false {
                Image(userDefaults.string(forKey: "Lock_Wallpaper") ?? "Wallpaper_1").resizable().aspectRatio(contentMode: .fill).frame(height:geometry.size.height).cornerRadius(0).frame(width: geometry.size.width, height: geometry.size.height, alignment: .center).clipped()
                } else {
                    Image(uiImage: (UIImage(data: userDefaults.object(forKey: "Lock_Wallpaper") as? Data ?? Data()) ?? UIImage(named: "Wallpaper_1"))!).resizable().aspectRatio(contentMode: .fill).frame(height:geometry.size.height).cornerRadius(0).frame(width: geometry.size.width, height: geometry.size.height, alignment: .center).clipped()
                }
                VStack {
                    Spacer()
                    if userDefaults.string(forKey: "Home_Wallpaper") == "Wallpaper_1" {
                   LinearGradient(gradient:Gradient(colors: [Color(red: 158/255, green: 158/255, blue: 158/255).opacity(0.0), Color(red: 34/255, green: 34/255, blue: 34/255)]), startPoint: .top, endPoint: .bottom).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: geometry.size.height/3.75, maxHeight: geometry.size.height/3.75, alignment: .center).clipped()
                    } else {
                    LinearGradient(gradient:Gradient(colors: [Color(red: 34/255, green: 34/255, blue: 34/255).opacity(0.0), Color(red: 24/255, green: 24/255, blue: 24/255).opacity(0.85)]), startPoint: .top, endPoint: .bottom).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: geometry.size.height/4.25, maxHeight: geometry.size.height/4.25, alignment: .center).clipped()
                    }
                }
                if charging {
                  lock_battery_view(moded_battery_level: abs(Int(battery_level/(100/17))))
                }
                VStack(spacing:0) {
                    status_bar(locked: true).frame(minHeight: 24, maxHeight:24).zIndex(1)
                    lock_header().frame(minHeight: 110, maxHeight:110).transition(.move(edge: .top)).offset(y:-out_slides*1.1).zIndex(0).clipped()
                    Spacer()
                    lock_footer(current_view: $current_view, out_slides: $out_slides, apps_scale: $apps_scale, dock_offset: $dock_offset, apps_scale_height: $apps_scale_height).frame(minHeight: 110, maxHeight:110).offset(y:out_slides).clipped()
                }
            }
        } .onReceive(battery_observer) { _ in
            if (UIDevice.current.batteryState != .unplugged) {
                charging = true
            } else {
                charging = false
            }
        } .onReceive(battery_level_observer) { _ in
            battery_level = UIDevice.current.batteryLevel * 100
        }.onAppear() {
            battery_level = UIDevice.current.batteryLevel * 100
            if (UIDevice.current.batteryState != .unplugged) {
                charging = true
            } else {
                charging = false
            }
            print(charging, battery_level, Int(battery_level/(100/17)), "ZK1")
        }
    }
}

struct lock_battery_view: View {
    var moded_battery_level: Int
    var body: some View {
        GeometryReader { geometry in
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            Image("BatteryBG_\(moded_battery_level)").clipped().mask(LinearGradient([(color: Color.clear, location: 0), (color: Color.clear, location: 0.60), (color: Color.white.opacity(0.4), location: 1)], from: .top, to: .bottom)).rotationEffect(.degrees(-180)).offset(y:129).rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
           Image("BatteryBG_\(moded_battery_level)")
        }
        }
    }
}

struct lock_header: View {
    @State var date = Date()
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var battery_level = UIDevice.current.batteryLevel * 100
    @State var carrier_id: String = ""
    @State var charging: Bool = false
    private let text_color = LinearGradient([.white, .white], to: .trailing)
    var body: some View {
        ZStack {
            Color.black.opacity(0.65).overlay(Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.21), Color.white.opacity(0.085)]), startPoint: .top, endPoint: .bottom)).frame(height:55).offset(y: -27)).border_top(width: 0.75, edges:[.top, .bottom], color: Color.black) .innerShadow(color: Color.white.opacity(0.24), radius: 0.03)
            HStack {
                Spacer()
                VStack() {
                    Text(timeString(date: date)).ps_innerShadow(Color.white, radius: 0.5, offset: 1, angle: .bottom).font(.custom("Helvetica Neue Light", size: 60))
                    Text("\(getDayOfWeek(date: date)), \(Calendar.current.monthSymbols[date.get(.month)-1]) \(date.get(.day))").ps_innerShadow(Color.white, radius: 0.5, offset: 1, angle: .bottom,intensity: 0.2).foregroundColor(.white).font(.custom("Helvetica Neue", size: 18))
                    
                }
                Spacer()
                
            }.padding([.leading, .trailing], 4)
        }   .onReceive(timer) { input in
            date = Date()
        }
    }
    func timeString(date: Date) -> String {
        let time = timeFormat.string(from: date)
        return time
    }
    func getDayOfWeek(date:Date) -> String {
        let index = Calendar.current.component(.weekday, from: date)
        return Calendar.current.weekdaySymbols[index - 1]
    }
}

struct lock_footer: View {
    @State var startPoint = UnitPoint(x: -2, y: 0)
       @State var endPoint = UnitPoint(x: 1, y: 0)
    @State var offset = CGPoint(x: 0, y: 0)
    @Binding var current_view: String
    @Binding var out_slides: CGFloat
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var apps_scale_height: CGFloat
    var body: some View {
        GeometryReader {geometry in
        ZStack {
            VStack(spacing:0) {
                Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 41/255, green: 40/255, blue: 40/255).opacity(0.6), Color.init(red: 21/255, green: 20/255, blue: 20/255).opacity(0.65)]), startPoint: .top, endPoint: .bottom)).innerShadowBottom(color: Color.white.opacity(0.6), radius: 0.05).border_top(width: 1, edges:[.top], color: Color.black)
                Rectangle().fill(Color.black.opacity(0.835))
            }
            RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5)).padding([.leading, .trailing], 25).padding([.top, .bottom], 28)
            HStack {
                ZStack {
                    ZStack (alignment: .topLeading) {
                        
                        RoundedRectangle(cornerRadius: 10,
                                         style: .continuous)
                            .fill(LinearGradient(gradient: Gradient(colors:[Color.init(red: 208/255, green: 208/255, blue: 208/255), Color.init(red: 168/255, green: 168/255, blue: 168/255)]), startPoint: .top, endPoint: .bottom))
                        GeometryReader {geometry in
                            Rectangle()
                                .fill(LinearGradient(gradient: Gradient(colors:[Color.init(red: 243/255, green: 243/255, blue: 243/255), Color.init(red: 225/255, green: 225/255, blue: 225/255)]), startPoint: .top, endPoint: .bottom))
                                .frame(minWidth: 75, maxWidth: 75, minHeight: geometry.size.height/2, maxHeight: geometry.size.height/2, alignment: .top)
                                .clipped()
                            
                        }
                    }
                    ZStack(alignment: .topLeading) {
                        Text("⮕").font(.custom("Helvetica Neue", size: 39)).ps_innerShadow(LinearGradient(gradient: Gradient(stops: [.init(color: Color.init(red: 166/255, green: 166/255, blue: 166/255), location: 0.5),.init(color: Color.init(red: 134/255, green: 134/255, blue: 134/255), location: 0.5)]), startPoint: .top, endPoint: .bottom), radius: 0.25, offset: CGPoint(1), intensity: 0.15)
                                                                                                                                    
                    }
                }.zIndex(1)
                .clipShape(RoundedRectangle(cornerRadius: 10)).draggable(offset: $offset, current_view: $current_view, out_slides: $out_slides, apps_scale: $apps_scale, dock_offset: $dock_offset, apps_scale_height: $apps_scale_height, width: geometry.size.width)
                .padding([.top, .bottom], 30.5).frame(width: 75).padding(.leading, 27.5)
                Spacer()
                Text("slide to unlock").font(.custom("Helvetica Neue", size: 25)).gradientForeground(colors: [Color.init(red: 78/255, green: 78/255, blue: 78/255), .white], startPoint: startPoint, endPoint: endPoint).padding(.trailing, 28)   .onAppear() {
                    withAnimation (Animation.easeInOut(duration: 3.6).repeatForever(autoreverses: false)){
                        if offset.x == 0 {
                        self.endPoint = UnitPoint(x: 2, y: 0)
                        self.startPoint = UnitPoint(x: 1, y: 0)
                        }
                    }
                }.opacity(1 - Double(offset.x/85)).zIndex(0)
                Spacer()
            }
        }
    }
    }
}

struct LockScreen_Previews: PreviewProvider {
    static var previews: some View {
        Controller()
    }
}

struct ContainerRelativeShapeSpecificCorner: Shape {
    
    private let corners: [UIRectCorner]
    
    init(corner: UIRectCorner...) {
        self.corners = corner
    }
    
    func path(in rect: CGRect) -> Path {
        var p = ContainerRelativeShape().path(in: rect)
        
        if corners.contains(.allCorners) {
            return p
        }
        
        if !corners.contains(.topLeft) {
            p.addPath(Rectangle().path(in: CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width / 2, height: rect.height / 2)))
        }
        if !corners.contains(.topRight) {
            p.addPath(Rectangle().path(in: CGRect(x: rect.origin.x + rect.width / 2, y: rect.origin.y, width: rect.width / 2, height: rect.height / 2)))
        }
        if !corners.contains(.bottomLeft) {
            p.addPath(Rectangle().path(in: CGRect(x: rect.origin.x, y: rect.origin.y + rect.height / 2, width: rect.width / 2, height: rect.height / 2)))
        }
        if !corners.contains(.bottomRight) {
            p.addPath(Rectangle().path(in: CGRect(x: rect.origin.x + rect.width / 2, y: rect.origin.y + rect.height / 2, width: rect.width / 2, height: rect.height / 2)))
        }
        return p
    }
}

struct CustomShape: Shape {
    func path(in rect: CGRect) -> Path {
        return Path(roundedRect: rect, cornerSize: CGSize(width: 10, height: 10))
    }
}

extension View {
    public func gradientForeground(colors: [Color], startPoint: UnitPoint, endPoint: UnitPoint) -> some View {
        self.overlay(LinearGradient(gradient: Gradient(stops: [ .init(color: colors[0], location: 0.33),.init(color: colors[1], location: 0.475),
                                                                  .init(color: colors[0], location: 0.525)]),
                                    startPoint: startPoint,
                                    endPoint: endPoint))
            .mask(self)
    }
    public func gradientForeground_midway(colors: [Color], startPoint: UnitPoint, endPoint: UnitPoint) -> some View {
        self.overlay(LinearGradient(gradient: Gradient(stops: [ .init(color: colors[0], location: 0.0),.init(color: colors[1], location: 0.49),
                                                                  .init(color: colors[2], location: 0.49),.init(color: colors[3], location: 1)]),
                                    startPoint: startPoint,
                                    endPoint: endPoint))
            .mask(self)
    }
    public func gradientForeground_shadow(colors: [Color], startPoint: UnitPoint, endPoint: UnitPoint) -> some View {
        self.overlay(LinearGradient(gradient: Gradient(stops: [ .init(color: colors[0], location: 0.0),.init(color: colors[1], location: 0.2)]),
                                    startPoint: startPoint,
                                    endPoint: endPoint))
            .mask(self)
    }
    public func clipped_shadow(colors: [Color], startPoint: UnitPoint, endPoint: UnitPoint) -> some View {
        self.border_gradient(width: 1, edges: [.top, .bottom, .leading, .trailing], color: LinearGradient(gradient: Gradient(colors: [Color.black]), startPoint: .top, endPoint: .bottom))
            .mask(self)
    }
}
extension View {
    func draggable(offset: Binding<CGPoint>, current_view: Binding<String>, out_slides: Binding<CGFloat>, apps_scale: Binding<CGFloat>, dock_offset: Binding<CGFloat>, apps_scale_height: Binding<CGFloat>, width: CGFloat) -> some View {
        return modifier(DraggableView(offset: offset, current_view: current_view, out_slides: out_slides, apps_scale: apps_scale, dock_offset: dock_offset, apps_scale_height: apps_scale_height, width: width))
  }
}
struct DraggableView: ViewModifier {
    @State   var audioPlayer: AVAudioPlayer!
    @Binding var offset: CGPoint
    @Binding var current_view: String
    @Binding var out_slides: CGFloat
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var apps_scale_height: CGFloat
    var width: CGFloat
  func body(content: Content) -> some View {
    content
      .gesture(DragGesture(minimumDistance: 0)
        .onChanged { value in
            if self.offset.x >= 0 && self.offset.x <= width - (50+81) {
          self.offset.x += value.location.x - value.startLocation.x
            }
            if self.offset.x < 0 {
                self.offset.x = 0
            }
            if self.offset.x > width - (50+81) {
                self.offset.x = width - (50+81)
            }
            print(offset.x, width - (50+81.5))
        }.onEnded { value in
            if self.offset.x >= width - (50+81) {
                //unlock
                playSounds("unlock.aiff")
                self.offset.x = width - (50+81)
                withAnimation(.easeIn(duration: 0.15)) {
                    out_slides = 120
                }
                DispatchQueue.main.asyncAfter(deadline:.now()+0.17) {
                    self.current_view = "HS"
                }
                DispatchQueue.main.asyncAfter(deadline:.now()+0.17) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        apps_scale = 1
                        dock_offset = 0
                        apps_scale_height = 1
                    }
                }
                print("unlocked")
            } else {
                withAnimation(.linear(duration: 0.15)) {
                    self.offset.x = 0
                }
            }
        })
        .offset(x: offset.x > 0 ? offset.x : 0, y: 0)
  }
    
    func playSounds(_ soundFileName : String) {
        DispatchQueue.global(qos: .background).async {
        guard let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: nil) else {
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
        } catch {
            print(error.localizedDescription)
        }
            audioPlayer.setVolume(0.05, fadeDuration: 1.0)
        audioPlayer.play()
        }
    }
}
