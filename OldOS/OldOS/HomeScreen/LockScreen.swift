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
    @ObservedObject private var passcode = OldOSPasscodeStore.shared
    @Binding var current_view: String
    @State private var passcodeActive = false
    @State private var passcodeProgress: CGFloat = 0
    @State private var departure: CGFloat = 0
    @State private var finishingPasscodeUnlock = false
    @State private var animationID = UUID()
    @State var out_slides: CGFloat = 0
    @State var charging = false
    @State var battery_level = UIDevice.current.batteryLevel*100
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var apps_scale_height: CGFloat
    let battery_observer = NotificationCenter.default.publisher(for:UIDevice.batteryStateDidChangeNotification)
    let battery_level_observer = NotificationCenter.default.publisher(for:UIDevice.batteryLevelDidChangeNotification)
    var userDefaults = UserDefaults.standard
    var body: some View {
        GeometryReader { geometry in
            let keyboardHeight = geometry.size.width/320*216
            ZStack {
                if !userDefaults.bool(forKey:"Camera_Wallpaper_Lock") {
                    Image(userDefaults.string(forKey:"Lock_Wallpaper") ?? "Wallpaper_1").resizable().aspectRatio(contentMode:.fill)
                        .frame(width:geometry.size.width,height:geometry.size.height).clipped()
                } else {
                    Image(uiImage:(UIImage(data:userDefaults.object(forKey:"Lock_Wallpaper") as? Data ?? Data()) ?? UIImage(named:"Wallpaper_1"))!)
                        .resizable().aspectRatio(contentMode:.fill).frame(width:geometry.size.width,height:geometry.size.height).clipped()
                }
                VStack {
                    Spacer()
                    if userDefaults.string(forKey:"Home_Wallpaper") == "Wallpaper_1" {
                        LinearGradient(colors:[Color(red:158/255,green:158/255,blue:158/255).opacity(0),Color(red:34/255,green:34/255,blue:34/255)],startPoint:.top,endPoint:.bottom)
                            .frame(height:geometry.size.height/3.75)
                    } else {
                        LinearGradient(colors:[Color(red:34/255,green:34/255,blue:34/255).opacity(0),Color(red:24/255,green:24/255,blue:24/255).opacity(0.85)],startPoint:.top,endPoint:.bottom)
                            .frame(height:geometry.size.height/4.25)
                    }
                }.allowsHitTesting(false)
                if charging {
                    lock_battery_view(moded_battery_level:abs(Int(battery_level/(100/17))))
                        .opacity(1-passcodeProgress).allowsHitTesting(false)
                }
                VStack(spacing:0) {
                    Color.clear.frame(height:24)
                    lock_header(passcodeProgress:passcodeProgress).frame(height:110)
                        .offset(y:-out_slides*1.1-110*departure)
                    Spacer(minLength:0)
                    lock_footer(current_view:$current_view,out_slides:$out_slides,apps_scale:$apps_scale,dock_offset:$dock_offset,
                                apps_scale_height:$apps_scale_height,passcodeProgress:passcodeProgress)
                        .frame(height:110)
                        .offset(y:out_slides-keyboardHeight*passcodeProgress+(keyboardHeight+110)*departure)
                        .allowsHitTesting(!passcodeActive && !finishingPasscodeUnlock)
                }
                OldOSUnlockPasscodeView(active:passcodeActive,unlocked:finishPasscodeUnlock)
                    .modifier(OldOSPasscodeReveal(progress:passcodeProgress,departure:departure))
                    .allowsHitTesting(passcodeActive && passcode.presentingUnlock && !finishingPasscodeUnlock)
                    .accessibilityHidden(!passcodeActive)
                VStack { status_bar(locked:true).frame(height:24); Spacer(minLength:0) }.allowsHitTesting(false)
            }.frame(width:geometry.size.width,height:geometry.size.height).clipped()
        }
        .onChange(of:passcode.presentingUnlock) { showing in
            if showing { showPasscode() }
            else if !finishingPasscodeUnlock { dismissPasscode() }
        }
        .onReceive(battery_observer) { _ in charging = UIDevice.current.batteryState != .unplugged }
        .onReceive(battery_level_observer) { _ in battery_level = UIDevice.current.batteryLevel*100 }
        .onAppear {
            battery_level = UIDevice.current.batteryLevel*100
            charging = UIDevice.current.batteryState != .unplugged
            if passcode.presentingUnlock { showPasscode() }
        }
    }
    private func showPasscode() {
        animationID = UUID(); passcodeActive = true; finishingPasscodeUnlock = false; departure = 0
        withAnimation(.easeInOut(duration:0.5)) { passcodeProgress = 1 }
    }
    private func dismissPasscode() {
        let id = UUID(), generation = passcode.lockGeneration
        animationID = id
        withAnimation(.easeInOut(duration:0.5)) { passcodeProgress = 0 }
        DispatchQueue.main.asyncAfter(deadline:.now()+0.5) {
            guard animationID == id, passcode.lockGeneration == generation, !passcode.presentingUnlock else { return }
            restoreLockedChrome()
        }
    }
    private func restoreLockedChrome() {
        var transaction = Transaction(); transaction.disablesAnimations = true
        withTransaction(transaction) {
            passcodeActive = false; passcodeProgress = 0; departure = 0
            finishingPasscodeUnlock = false; out_slides = 0
        }
    }
    private func finishPasscodeUnlock() {
        guard !finishingPasscodeUnlock else { return }
        let id = UUID(), generation = passcode.lockGeneration
        animationID = id; finishingPasscodeUnlock = true
        let duration = 0.42
        withAnimation(.easeInOut(duration:duration)) { departure = 1 }
        DispatchQueue.main.asyncAfter(deadline:.now()+duration) {
            guard animationID == id, passcode.lockGeneration == generation else { return }
            guard !passcode.inactive else { passcode.cancelUnlock(); restoreLockedChrome(); return }
            var transaction = Transaction(); transaction.disablesAnimations = true
            withTransaction(transaction) {
                passcode.completeUnlock(); apps_scale = 4; dock_offset = 100; current_view = "HS"
            }
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
    var passcodeProgress: CGFloat = 0
    @ObservedObject private var status = OldOSStatusState.shared
    private var date:Date { status.date }
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }
    private let text_color = LinearGradient([.white, .white], to: .trailing)
    var body: some View {
        ZStack {
            Color.black.opacity(0.65).overlay(Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.21), Color.white.opacity(0.085)]), startPoint: .top, endPoint: .bottom)).frame(height:55).offset(y: -27)).border_top(width: 0.75, edges:[.top, .bottom], color: Color.black) .innerShadow(color: Color.white.opacity(0.24), radius: 0.03)
            HStack {
                Spacer()
                VStack() {
                    Text(timeString(date: date)).ps_innerShadow(Color.white, radius: 0.5, offset: 1, angle: .bottom).font(.custom("Helvetica Neue Light", fixedSize: 60))
                    Text("\(getDayOfWeek(date: date)), \(Calendar.current.monthSymbols[date.get(.month)-1]) \(date.get(.day))").ps_innerShadow(Color.white, radius: 0.5, offset: 1, angle: .bottom,intensity: 0.2).foregroundColor(.white).font(.custom("Helvetica Neue", fixedSize: 18))
                    
                }
                Spacer()
                
            }.padding([.leading, .trailing], 4).opacity(1-passcodeProgress)
        }   .onAppear { status.refresh() }
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
    @State var offset = CGPoint(x: 0, y: 0)
    @Binding var current_view: String
    @Binding var out_slides: CGFloat
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var apps_scale_height: CGFloat
    var passcodeProgress: CGFloat = 0
    @ObservedObject private var passcode = OldOSPasscodeStore.shared
    var body: some View {
        GeometryReader {geometry in
        ZStack {
            VStack(spacing:0) {
                Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 41/255, green: 40/255, blue: 40/255).opacity(0.6), Color.init(red: 21/255, green: 20/255, blue: 20/255).opacity(0.65)]), startPoint: .top, endPoint: .bottom)).innerShadowBottom(color: Color.white.opacity(0.6), radius: 0.05).border_top(width: 1, edges:[.top], color: Color.black)
                Rectangle().fill(Color.black.opacity(0.835))
            }.opacity(1-passcodeProgress)
            ZStack {
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
                        Text("⮕").font(.custom("Helvetica Neue", fixedSize: 39)).ps_innerShadow(LinearGradient(gradient: Gradient(stops: [.init(color: Color.init(red: 166/255, green: 166/255, blue: 166/255), location: 0.5),.init(color: Color.init(red: 134/255, green: 134/255, blue: 134/255), location: 0.5)]), startPoint: .top, endPoint: .bottom), radius: 0.25, offset: CGPoint(1), intensity: 0.15)
                                                                                                                                    
                    }
                }.zIndex(1)
                .clipShape(RoundedRectangle(cornerRadius: 10)).draggable(offset: $offset, current_view: $current_view, out_slides: $out_slides, apps_scale: $apps_scale, dock_offset: $dock_offset, apps_scale_height: $apps_scale_height, width: geometry.size.width)
                .padding([.top, .bottom], 30.5).frame(width: 75).padding(.leading, 27.5)
                Spacer()
                UnlockShimmerText().padding(.trailing, 28)
                    .opacity(max(0, 1 - Double(offset.x/85))).zIndex(0)
                Spacer()
            }
            }.offset(x:geometry.size.width*passcodeProgress)
        }.clipped().coordinateSpace(name:"OldOSLockSlider")
    }.onChange(of:passcode.presentingUnlock) { showing in
        if !showing {
            withAnimation(.easeInOut(duration:0.5)) { offset = .zero }
        }
    }
    }
}

// Paint the highlight from time instead of relying on animation of UnitPoint.
// This also restarts correctly whenever the lock screen is presented again.
struct UnlockShimmerText: View {
    @State private var epoch = Date()
    private var label: some View {
        Text("slide to unlock").font(.custom("Helvetica Neue", fixedSize: 25))
    }
    var body: some View {
        label.foregroundColor(Color(white: 78 / 255))
            .overlay {
                GeometryReader { geometry in
                    TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                        let phase = max(0, timeline.date.timeIntervalSince(epoch)).truncatingRemainder(dividingBy: 3.6)
                        let progress = min(phase / 2.4, 1)
                        LinearGradient(colors: [.clear, .white.opacity(0.95), .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: 82, height: geometry.size.height)
                            .offset(x: -82 + (geometry.size.width + 82) * progress)
                    }
                }
                .mask(label.foregroundColor(.white))
                .allowsHitTesting(false)
            }
            .onAppear { epoch = Date() }
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
enum OldOSLockSliderTravel {
    static func position(origin:CGFloat,translation:CGFloat,width:CGFloat) -> CGFloat {
        min(max(0,origin+translation),max(0,width-131))
    }
}

struct DraggableView: ViewModifier {
    @State private var dragOrigin: CGFloat?
    @State var audioPlayer: AVAudioPlayer!
    @Binding var offset: CGPoint
    @Binding var current_view: String
    @Binding var out_slides: CGFloat
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var apps_scale_height: CGFloat
    var width: CGFloat
  func body(content: Content) -> some View {
    content
      .gesture(DragGesture(minimumDistance:0,coordinateSpace:.named("OldOSLockSlider"))
        .onChanged { value in
            if dragOrigin == nil { dragOrigin = offset.x }
            var transaction = Transaction(); transaction.disablesAnimations = true
            withTransaction(transaction) {
                offset.x = OldOSLockSliderTravel.position(origin:dragOrigin ?? 0,translation:value.translation.width,width:width)
            }
        }.onEnded { value in
            dragOrigin = nil
            if self.offset.x >= width - (50+81) {
                if OldOSPasscodeStore.shared.requiresPasscode() {
                    OldOSPasscodeStore.shared.presentingUnlock = true
                    return
                }
                playSounds("unlock.aiff")
                self.offset.x = width - (50+81)
                withAnimation(.easeIn(duration: 0.15)) {
                    out_slides = 120
                }
                let unlockGeneration = OldOSPasscodeStore.shared.lockGeneration
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.17) {
                    guard OldOSPasscodeStore.shared.lockGeneration == unlockGeneration,
                          !OldOSPasscodeStore.shared.inactive else {
                        offset = .zero
                        out_slides = 0
                        return
                    }
                    // The mounted icon grid starts the entrance after its first
                    // presented frame; a fixed delay can race the page host.
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        OldOSPasscodeStore.shared.completeUnlock()
                        apps_scale = 4
                        dock_offset = 100
                        self.current_view = "HS"
                    }
                }
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
