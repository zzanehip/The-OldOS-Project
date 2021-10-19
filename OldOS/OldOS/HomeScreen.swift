//
//  ContentView.swift
//  OldOS
//
//  Created by Zane Kleinberg on 1/9/21.
//

import SwiftUI
import CoreTelephony
import PureSwiftUITools
import Network

extension View where Self: Equatable {
    public func equatable() -> EquatableView<Self> {
        return EquatableView(content: self)
    }
}

struct multitasking_controller: View {
    @Binding var current_view: String
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var multitasking_apps: [String]
    @Binding var instant_multitasking_change: Bool
    @Binding var current_multitasking_app: String
    @Binding var should_update: Bool
    @Binding var show_remove: Bool
    @Binding var show_multitasking: Bool
    var relative_app: String
    var body: some View {
        if instant_multitasking_change, relative_app == current_multitasking_app {
            VStack(spacing: 0) {
                Spacer()
                multitasking_view(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, should_update: $should_update, show_remove: $show_remove, instant_multitasking_change: $instant_multitasking_change, show_multitasking: $show_multitasking, apps: $multitasking_apps).frame(height:UIScreen.main.bounds.width/(390/85) + 20).padding([.leading, .trailing])
            }.if(relative_app != "HS"){$0.transition(.scale)}.onAppear(perform: {
                UIScrollView.appearance().bounces = false
            })
        }
    }
}

//Here's how our view hierarchy works: we manage everything in a view I've deemed "Controller." It's super simple, we change the current view string, and the entire screen changes. Simple, elegant, and the way I like doing it.
struct Controller: View {
    
    @State var current_view: String = "HS"
    @State var multitasking_apps: [String] = []
    @State var apps_scale: CGFloat = 4
    @State var dock_offset: CGFloat = 100
    @State var apps_scale_height: CGFloat = 1 //12.75
    @State var selected_page = 1
    @State var search_width: CGFloat = 0.0
    @State var search_height: CGFloat = 0.0
    @State var show_multitasking: Bool = false
    @State var instant_multitasking_change: Bool = false
    @State var current_multitasking_app: String = "HS"
    @State var should_update: Bool = false
    @State var show_remove: Bool = false
    @EnvironmentObject var MusicObserver: MusicObserver
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            GeometryReader {geometry in
                VStack {
                    Spacer()
                    ZStack {
                        ZStack {
                            switch current_view {
                            case "LS":
                                LockScreen(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, apps_scale_height: $apps_scale_height).padding([.leading, .trailing])
                            case "HS":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "HS")
                                HomeScreen(apps_scale: $apps_scale, apps_scale_height: $apps_scale_height, dock_offset: $dock_offset, selectedPage: $selected_page, search_width: $search_width, search_height:$search_height, current_view: $current_view, show_multitasking: $show_multitasking, instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "HS") //.compositingGroup() -> maybe
                            case "Settings":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Settings")
                                Settings(show_multitasking: $instant_multitasking_change).equatable().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Settings")
                            case "iPod":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "iPod")
                                iPod().padding([.leading, .trailing]).transition(.scale).environmentObject(MusicObserver).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "iPod")
                            case "Safari":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Safari")
                                Safari(instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Safari")
                            case "Mail":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Mail")
                                Mail().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Mail")
                            case "Phone":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Phone")
                                Phone(instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Phone")
                            case "Game Center":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Game Center")
                                GameCenter(instant_multitasking_change: $instant_multitasking_change).equatable().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Game Center")
                            case "App Store":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "App Store")
                                AppStore(instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "App Store")
                            case "iTunes":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "iTunes")
                                iTunes(instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "iTunes")
                            case "Notes":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Notes")
                                Notes(instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Notes")
                            case "Weather":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Weather")
                                Weather(show_multitasking: $show_multitasking).equatable().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Weather")
                            case "Maps":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Maps")
                                Maps(instant_multitasking_change: $instant_multitasking_change, show_multitasking: $show_multitasking, should_show: current_multitasking_app == "Maps").padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking(show_multitasking, instant_multitasking_change, current_multitasking_app == "Maps")//.modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Maps")
                            case "YouTube":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "YouTube")
                                Youtube(instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "YouTube")
                            case "Camera":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Camera")
                                Camera(instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Camera")
                            case "Contacts":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Contacts")
                                Contacts().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Contacts")
                            case "Messages":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Messages")
                                Messages().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Messages")
                            case "Photos":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Photos")
                                Photos(instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Photos")
                            case "Stocks":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Stocks")
                                Stocks(show_multitasking: $show_multitasking).equatable().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Stocks")
                            case "Calendar":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Calendar")
                                CalendarView().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Calendar")
                            default:
                                LockScreen(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, apps_scale_height: $apps_scale_height).padding([.leading, .trailing])
                            }
                        }//.disabled(show_multitasking)
                    }
                    Spacer().frame(height:1)
                    home_bar(selectedPage: $selected_page, current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, show_multitasking: $show_multitasking, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove).padding(.top).frame(height: 100)
                }
            }
        }.ignoresSafeArea(.keyboard).onAppear() {
            withAnimation(.linear(duration:0)) {
                current_view = "LS"
            } //-> It's an interesting solution, but if we set the view first to the HomeScreen, let it render, and then immediately switch to the lock-screen, we'll get a much smoother animation.
            withAnimation(.linear(duration: 0.01)) {
                apps_scale = 4
                dock_offset = 100
            }
        }.onChange(of: current_view) {_ in
            if instant_multitasking_change {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    show_multitasking = false
                    instant_multitasking_change = false
                }
            }
            if current_view != "HS" && current_view != "LS" {
                if let index = multitasking_apps.firstIndex(of: current_view) {
                    multitasking_apps.remove(at: index)
                }
                multitasking_apps.insert(current_view, at: 0)
            }
        }
    }
}

extension View {
    func modifiedForMultitasking(_ show_multitasking: Bool, _ instant_multitasking_change: Bool, _ should_show: Bool) -> some View {
        self.offset(y: (show_multitasking == true && should_show == true) ? -(UIScreen.main.bounds.width/(390/85) + 20) : 0).clipped().disabled((show_multitasking == true && should_show == true))//.shadow(color: Color.black.opacity((instant_multitasking_change == true && should_show == true) ? 0.85 : 0), radius: 6, x: 0, y: 4).disabled((show_multitasking == true && should_show == true))
    }
    func modifiedForMultitasking2(_ show_multitasking: Bool, _ instant_multitasking_change: Bool, _ should_show: Bool) -> some View {
        self.offset(y: (show_multitasking == true && should_show == true) ? -(UIScreen.main.bounds.width/(390/85) + 20) : 0).clipped().shadow(color: Color.black.opacity((instant_multitasking_change == true && should_show == true) ? 0.85 : 0), radius: 6, x: 0, y: 4).disabled((show_multitasking == true && should_show == true))
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

struct multitasking_view: View {
    @State var selectedPage: Int = 2
    @State var dual_angle: Double = 0.0
    var timer = Timer.publish(every: 0.000625, on: .main, in: .common).autoconnect()
    @Binding var current_view: String
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var should_update: Bool
    @Binding var show_remove: Bool
    @Binding var instant_multitasking_change: Bool
    @Binding var show_multitasking: Bool
    @Binding var apps: [String]
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                Image("FolderSwitcherBG").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).frame(width:geometry.size.width, height: geometry.size.height)
                TabView(selection: $selectedPage.animation()) {
                    multitasking_audio_controls().tag(0)
                    multitasking_music_controls(current_view: $current_view, should_update: $should_update, show_remove: $show_remove, instant_multitasking_change: $instant_multitasking_change, show_multitasking: $show_multitasking, apps_scale: $apps_scale, dock_offset: $dock_offset).tag(1)
                    if apps.filter({$0 != current_view}).count == 0 {
                        Spacer().tag(2)
                    } else {
                    ForEach(Array(apps.filter({$0 != current_view}).chunked(into: 4).enumerated()), id:\.element) {(i, app_section) in
                        multitasking_app_section(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, dual_angle: $dual_angle, should_update: $should_update, show_remove: $show_remove, apps_main_array: $apps, apps: app_section).frame(width:geometry.size.width, height: geometry.size.height).tag((apps.chunked(into:4).firstIndex(of: app_section) ?? 0) + 2)
                    }
                    }
                }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)).frame(width:geometry.size.width, height: geometry.size.height)
                
            }
        }.onReceive(timer) { _ in
            withAnimation(.linear(duration: 0.2)) {
            if should_update {
                    dual_angle += 1
                print(dual_angle)
            } else {
                dual_angle = 0
            }
            }
        }
    }
}
func deg2rad(_ number: Double) -> Double {
    return number * .pi / 180
}

struct multitasking_app_section: View {
    @State var icon_scaler: CGFloat = 1.0
    @State var switcher: Bool = false
    @Binding var current_view: String
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var dual_angle: Double
    @Binding var should_update: Bool
    @Binding var show_remove: Bool
    @Binding var apps_main_array: [String]
    @State var apps: [String]
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            LazyVGrid(columns: [
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1)
            ], alignment: .center, spacing: UIScreen.main.bounds.height/(844/40)*icon_scaler) {
                ForEach(Array(apps.enumerated()), id:\.element) { (i, r_app) in
                    multitasking_app(image_name: r_app == "Weather" ? "Weather Fahrenheit" : r_app, app_name: r_app, current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, show_remove: $show_remove, should_update: $should_update, apps: $apps, apps_main_array: $apps_main_array).rotationEffect(.degrees(sin(deg2rad(dual_angle))*Double.random(in: 1...3)*1.25)).offset(x: -CGFloat(sin(deg2rad(dual_angle))*Double.random(in: -2...2)*0.75), y: 0).transition(.asymmetric(insertion: .slide, removal: .scale))
                }
                    
            }
        }.onAppear() {
            //MARK — iPhone 8
            if UIScreen.main.bounds.width == 375 && UIScreen.main.bounds.height == 667 {
                icon_scaler = 0.55
            }
            //MARK — iPhone 8 Plus
            if UIScreen.main.bounds.width == 414 && UIScreen.main.bounds.height == 736 {
                icon_scaler = 0.8
            }
        }
    }
}

struct multitasking_audio_controls: View {
    @ObservedObject private var volObserver = VolumeObserver()
    var body: some View {
        HStack {
            LazyVGrid(columns: [
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)*3), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
            ], alignment: .center, spacing: UIScreen.main.bounds.height/(844/40)) {
                CustomSlider(type: "Volume", value: $volObserver.volume.double,  range: (0, 100)) { modifiers in
                    ZStack {
                        RoundedRectangle(cornerRadius: 8.5/2).fill(Color.white.opacity(0.4)).brightness(-0.02).innerShadowSliderMultiDiffed(color: Color.black, radius: 0.75).frame(height: 8.5).cornerRadius(8.5/2).padding(.leading, 4).clipShape(RoundedRectangle(cornerRadius: 8.5/2)).shadow(color: Color(red: 183/255, green: 183/255, blue: 184/255).opacity(0.5), radius: 0, x: 0, y: 1).modifier(modifiers.barLeft)
                        RoundedRectangle(cornerRadius: 8.5/2).fill(Color.black.opacity(0.4)).brightness(-0.1).innerShadowSliderMulti(color: Color.black.opacity(0.75), radius: 0.75).frame(height: 8.5).cornerRadius(8.5/2).padding(.trailing, 4).clipShape(RoundedRectangle(cornerRadius: 8.5/2)).shadow(color: Color(red: 183/255, green: 183/255, blue: 184/255).opacity(0.5), radius: 0, x: 0, y: 1).modifier(modifiers.barRight)
                        ZStack {
                            Image("SwitcherSliderThumb").resizable().scaledToFill()
                            
                        }.modifier(modifiers.knob)
                    }
                }.frame(height: 25).padding([.leading], 30)
                Image("SwitcherAirPlayNowPlayingButton")
            }
        }.overlay(VStack {
            Spacer()
            Image("SwitcherVolumeIcon").offset(y: 10)
        })
    }
}

struct home_bar: View {
    @State var momentary_disable: Bool = false
    @Binding var selectedPage: Int
    @Binding var current_view: String
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var show_multitasking: Bool
    @Binding var instant_multitasking_change: Bool
    @Binding var current_multitasking_app: String
    @Binding var should_update: Bool
    @Binding var show_remove: Bool
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            HStack {
                Spacer()
                ZStack {
                    Circle().fill(Color.black).frame(width: 65, height:65).overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                    )
                    Circle().fill(LinearGradient(gradient: Gradient(colors: [.black, .black, .black, Color.gray.opacity(0.35)]), startPoint: .top, endPoint: .bottom)).frame(width: 65, height:65)
                    RoundedRectangle(cornerRadius: 4).fill(Color.black).frame(width: 20, height:20).overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.65), lineWidth: 1.75)
                    )
                } .tapRecognizer(tapSensitivity: 0.2, singleTapAction: {
                    let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                    impactHeavy.impactOccurred()
                    if show_multitasking == false {
                        if current_view != "LS" && current_view != "HS" {
                            withAnimation(.linear(duration: 0.35)) {
                                self.current_view = "HS"
                            }
                            DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
                                withAnimation(.linear(duration: 0.42)) {
                                    apps_scale = 1
                                    dock_offset = 0
                                }
                            }
                        } else {
                            withAnimation() {
                                // when on the first page, pressing the home button shows the spotlight search
                                // https://www.youtube.com/watch?v=hMZXnyk2SJA
                                if selectedPage == 1 {
                                    selectedPage = 0
                                } else {
                                    selectedPage = 1
                                }
                            }
                        }
                    } else {
                        if should_update, show_remove {
                            should_update = false
                            show_remove = false
                        } else {
                        withAnimation {
                            show_multitasking = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
                            instant_multitasking_change = false
                        }
                        }
                    }
                    
                }, doubleTapAction: {
                    let generator = UINotificationFeedbackGenerator()
                              generator.notificationOccurred(.success)
                    if current_view != "LS" {
                        current_multitasking_app = current_view
                        if !momentary_disable {
                            if !show_multitasking {
                                instant_multitasking_change = true
                                momentary_disable = true
                                withAnimation {
                                    show_multitasking = true
                                }
                            } else {
                                momentary_disable = true
                                withAnimation {
                                    show_multitasking = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
                                    instant_multitasking_change = false
                                }
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            momentary_disable = false
                        }
                    }
                })
                Spacer()
            }.padding()
        }
    }
}

//Thanks to https://stackoverflow.com/questions/66430942/handle-single-click-and-double-click-while-updating-the-view/66432412#66432412 for this solution. SwiftUI causes a delay in tapGestures...which is really annoying.

struct TapRecognizerViewModifier: ViewModifier {
    
    @State private var singleTapIsTaped: Bool = Bool()
    
    var tapSensitivity: Double
    var singleTapAction: () -> Void
    var doubleTapAction: () -> Void
    
    init(tapSensitivity: Double, singleTapAction: @escaping () -> Void, doubleTapAction: @escaping () -> Void) {
        self.tapSensitivity = tapSensitivity
        self.singleTapAction = singleTapAction
        self.doubleTapAction = doubleTapAction
    }
    
    func body(content: Content) -> some View {
        
        return content
            .gesture(simultaneouslyGesture)
        
    }
    
    private var singleTapGesture: some Gesture { TapGesture(count: 1).onEnded{
        
        singleTapIsTaped = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + tapSensitivity) { if singleTapIsTaped { singleTapAction() } }
        
    } }
    
    private var doubleTapGesture: some Gesture { TapGesture(count: 2).onEnded{ singleTapIsTaped = false; doubleTapAction() } }
    
    private var simultaneouslyGesture: some Gesture { singleTapGesture.simultaneously(with: doubleTapGesture) }
    
}


extension View {
    
    func tapRecognizer(tapSensitivity: Double, singleTapAction: @escaping () -> Void, doubleTapAction: @escaping () -> Void) -> some View {
        
        return self.modifier(TapRecognizerViewModifier(tapSensitivity: tapSensitivity, singleTapAction: singleTapAction, doubleTapAction: doubleTapAction))
        
    }
    
}

struct HomeScreen: View {
    @Binding var apps_scale: CGFloat
    @Binding var apps_scale_height: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var selectedPage: Int
    @Binding var search_width: CGFloat
    @Binding var search_height: CGFloat
    @State var show_searchField: Bool = false
    @State var icon_spacing_horizontal_resize: CGFloat = 0.0
    @State var icon_spacing_vertical_resize: CGFloat = 0.0
    @State var bottom_indicator_offset: CGFloat = 0.0
    @State var icon_scaler: CGFloat = 1.0
    @Binding var current_view: String
    @Binding var show_multitasking: Bool
    @Binding var instant_multitasking_change: Bool
    @GestureState  var dragOffset: CGFloat = 0
    var userDefaults = UserDefaults.standard
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if userDefaults.bool(forKey: "Camera_Wallpaper_Home") == false {
                    Image(userDefaults.string(forKey: "Home_Wallpaper") ?? "Wallpaper_1").resizable().aspectRatio(contentMode: .fill).frame(height:geometry.size.height).cornerRadius(0).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: geometry.size.height, maxHeight: geometry.size.height, alignment: .center).clipped()
                } else {
                    Image(uiImage: (UIImage(data: userDefaults.object(forKey: "Home_Wallpaper") as? Data ?? Data()) ?? UIImage(named: "Wallpaper_1"))!).resizable().aspectRatio(contentMode: .fill).frame(height:geometry.size.height).cornerRadius(0).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: geometry.size.height, maxHeight: geometry.size.height, alignment: .center).clipped()
                }
                VStack {
                    Spacer()
                    if userDefaults.string(forKey: "Home_Wallpaper") == "Wallpaper_1" {
                        LinearGradient(gradient:Gradient(colors: [Color(red: 158/255, green: 158/255, blue: 158/255).opacity(0.0), Color(red: 34/255, green: 34/255, blue: 34/255)]), startPoint: .top, endPoint: .bottom).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: geometry.size.height/3.75, maxHeight: geometry.size.height/3.75, alignment: .center).clipped()
                    }else {
                        LinearGradient(gradient:Gradient(colors: [Color(red: 34/255, green: 34/255, blue: 34/255).opacity(0.0), Color(red: 24/255, green: 24/255, blue: 24/255).opacity(0.85)]), startPoint: .top, endPoint: .bottom).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: geometry.size.height/4.25, maxHeight: geometry.size.height/4.25, alignment: .center).clipped()
                    }
                }
                Color.black.opacity(selectedPage == 0 ? 0.65 : 0).padding(.top, 24)
                VStack {
                    status_bar().frame(minHeight: 24, maxHeight:24).zIndex(1)
                    Spacer().frame(height: 30)
                    TabView(selection: $selectedPage.animation()) {
                        search(width: $search_width, height: $search_height, show_searchField: $show_searchField, apps_scale: $apps_scale, current_view: $current_view, dock_offset: $dock_offset).frame(maxWidth: geometry.size.width, maxHeight:geometry.size.height).zIndex(0).clipped().tag(0)
                        apps(apps_scale:$apps_scale, apps_scale_height: $apps_scale_height, show_searchField: $show_searchField, icon_scaler: $icon_scaler, current_view: $current_view, dock_offset: $dock_offset, width: geometry.size.width, height: geometry.size.height).scaleEffect(apps_scale)   .animation(.easeIn).frame(maxWidth: geometry.size.width, maxHeight:geometry.size.height).zIndex(0).clipped().tag(1)    .overlay(
                            GeometryReader { proxy in
                                Color.clear.hidden().onAppear() {
                                    search_width = proxy.size.width
                                    search_height = proxy.size.height
                                }
                            }
                        )
                        apps_second(apps_scale:$apps_scale, apps_scale_height: $apps_scale_height, show_searchField: $show_searchField, icon_scaler: $icon_scaler, current_view: $current_view, dock_offset: $dock_offset, width: geometry.size.width, height: geometry.size.height).frame(maxWidth: geometry.size.width, maxHeight:geometry.size.height).zIndex(0).clipped().tag(2).frame(width:search_width, height: search_height)
                    }.layoutPriority(1).scale(apps_scale).tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)).onAppear() {
                        UIScrollView.appearance().bounces = false
                    }.opacity(1/(Double(dock_offset) + 1)).clipped().grayscale(show_multitasking == true ? 0.99 : 0).opacity(show_multitasking == true ? 0.3 : 1)
                    //added layout up there
                    dock2(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, show_multitasking: $show_multitasking).frame(width:geometry.size.width).offset(y:dock_offset).clipped()
                }
                VStack {
                    Spacer()
                    HStack() {
                        Button {
                            withAnimation {
                                selectedPage = max(selectedPage - 1, 0)
                            }
                        } label: {
                            Color.clear.frame(width: geometry.size.width/2.4, height:7.9)
                        }
                        Button {
                            withAnimation {
                                selectedPage = 0
                            }
                        } label: {
                            Image(systemName: "magnifyingglass").resizable().font(Font.title.weight(.heavy)).foregroundColor(selectedPage == 0 ? Color.white : Color.init(red: 146/255, green: 146/255, blue: 146/255)).frame(width: 7.9, height:7.9).padding(0)
                        }
                        Button {
                            withAnimation {
                                selectedPage = 1
                            }
                        } label: {
                            Circle().fill(selectedPage == 1 ? Color.white : Color.init(red: 146/255, green: 146/255, blue: 146/255)).frame(height:7.9).padding(0)
                        }
                        Button {
                            withAnimation {
                                selectedPage = 2
                            }
                        } label: {
                            Circle().fill(selectedPage == 2 ? Color.white : Color.init(red: 146/255, green: 146/255, blue: 146/255)).frame(height:7.9).padding(0)
                        }
                        Button {
                            withAnimation {
                                selectedPage = min(selectedPage + 1, 2)
                            }
                        } label: {
                            Color.clear.frame(width: geometry.size.width/2.4, height:7.9)
                        }
                    }.padding(.bottom, 110).offset(y:dock_offset).offset(y:bottom_indicator_offset)
                }.opacity(show_multitasking == true ? 0 : 1)
            }.onAppear() {
                //MARK — iPhone 8
                if UIScreen.main.bounds.width == 375 && UIScreen.main.bounds.height == 667 {
                    bottom_indicator_offset = 17.5
                    icon_scaler = 0.55
                }
                //MARK — iPhone 8 Plus
                if UIScreen.main.bounds.width == 414 && UIScreen.main.bounds.height == 736 {
                    bottom_indicator_offset = 10
                    icon_scaler = 0.8
                }
                //MARK — iPhone 12 Mini
                if UIScreen.main.bounds.width == 375 && UIScreen.main.bounds.height == 812 {
                    bottom_indicator_offset = 8
                }
            }
        }
    }
}
struct NoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
extension View {
    func delayTouches() -> some View {
        Button(action: {}) {
            highPriorityGesture(TapGesture())
        }
        .buttonStyle(NoButtonStyle())
    }
}

struct app_search_id_ext: Identifiable {
    let id = UUID()
    var name: String
}
struct search: View {
    var apps = [app_search_id_ext(name:"Messages"), app_search_id_ext(name:"Calendar"), app_search_id_ext(name:"Photos"), app_search_id_ext(name:"Camera"), app_search_id_ext(name:"YouTube"), app_search_id_ext(name:"Stocks"), app_search_id_ext(name:"Maps"), app_search_id_ext(name:"Weather"), app_search_id_ext(name:"Notes"), app_search_id_ext(name:"iTunes"), app_search_id_ext(name:"App Store"),  app_search_id_ext(name:"Game Center"), app_search_id_ext(name:"Settings"), app_search_id_ext(name:"Phone"), app_search_id_ext(name:"Mail"), app_search_id_ext(name:"Safari" ), app_search_id_ext(name:"iPod" ), app_search_id_ext(name:"Contacts")]
    @Binding var width: CGFloat
    @Binding var height: CGFloat
    @State var search = ""
    @State var place_holder = ""
    @Binding var show_searchField: Bool
    @Binding var apps_scale: CGFloat
    @Binding var current_view: String
    @Binding var dock_offset: CGFloat
    private let gradient = LinearGradient([.white, .white], to: .trailing)
    var body: some View {
        ZStack {
            VStack {
                
                HStack {
                    Spacer(minLength: 5)
                    HStack (alignment: .center,
                            spacing: 10) {
                        Image(systemName: "magnifyingglass").resizable().font(Font.title.weight(.medium)).frame(width: 15, height: 15).padding(.leading, 5)
                            .foregroundColor(.gray)
                        
                        TextField ("Search iPhone", text: $search)
                        
                    }
                    
                    .padding([.top,.bottom], 5)
                    .padding(.leading, 5)
                    .cornerRadius(40)
                    Spacer(minLength: 20)
                } .ps_innerShadow(.capsule(gradient), radius:2).padding([.leading, .trailing])
                Spacer().frame(height: 10)
                search_results_view(apps: apps, search: $search, apps_scale: $apps_scale, current_view: $current_view, dock_offset: $dock_offset).padding([.leading, .trailing]).cornerRadius(12)
            }
        }.frame(width:width, height: height)
    }
}

struct search_results_view: View {
    var apps: [app_search_id_ext]
    @Binding var search: String
    @Binding var apps_scale: CGFloat
    @Binding var current_view: String
    @Binding var dock_offset: CGFloat
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing:0) {
                ScrollView(showsIndicators: true) {
                    VStack(spacing: 0)  {
                        ForEach(apps.filter{$0.name.localizedCaseInsensitiveContains(search)}.sorted(by: {$0.name > $1.name}), id:\.id) { application in
                            search_result_item(apps: apps, search: $search, apps_scale: $apps_scale, current_view: $current_view, dock_offset: $dock_offset, application: application)
                            
                        }
                    }
                }.frame(height: geometry.size.height - 40).background(Color(red: 228/255, green: 229/255, blue: 230/255)).cornerRadius(12)
            }
        }.onAppear() {
            //UIScrollView.appearance().bounces = true -> There's something weird going on where we can't readily modify the bounce value of our scrollviews in the TabView. Therefore, our app pages bounce, when they shouldn't. For now, we'll compromise and have the search not bounce, instead of the apps bouncing.
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
        }
    }
}

struct search_result_item: View {
    var apps: [app_search_id_ext]
    @Binding var search: String
    @Binding var apps_scale: CGFloat
    @Binding var current_view: String
    @Binding var dock_offset: CGFloat
    var application: app_search_id_ext
    var body: some View {
        Button(action:{
            
            withAnimation(.linear(duration: 0.32)) {
                apps_scale = 4
                dock_offset = 100
            }
            DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
                withAnimation(.linear(duration: 0.32)) {
                    current_view = application.name
                }
            }
        }) {
            VStack(spacing: 0) {
                HStack {
                    Image(application.name == "Weather" ? "Weather Fahrenheit" : application.name).resizable().scaledToFit().frame(width: 35, height: 35).padding(.leading, 5)
                    Rectangle().fill(Color(red: 250/255, green: 250/255, blue: 250/255)).frame(width: 1, height: 48).offset(x: -2)
                    Text(application.name).font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.black).offset(x: -2)
                    Spacer()
                }.frame(height: 48)
                Rectangle().fill((apps.filter({ search.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(search) }).sorted(by: {$0.name > $1.name}).firstIndex(where: {$0.name == application.name}) ?? 0) % 2  == 0 ? Color(red: 182/255, green: 183/255, blue: 184/255) : Color(red: 182/255, green: 183/255, blue: 184/255)).frame(height:1)
                Rectangle().fill((apps.filter({ search.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(search) }).sorted(by: {$0.name > $1.name}).firstIndex(where: {$0.name == application.name}) ?? 0) % 2  == 0 ? Color(red: 250/255, green: 250/255, blue: 250/255) : Color(red: 250/255, green: 250/255, blue: 250/255)).frame(height:1)
            }.frame(height: 50).background((apps.filter({ search.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(search) }).sorted(by: {$0.name > $1.name}).firstIndex(where: {$0.name == application.name}) ?? 0) % 2  == 0 ? Color(red: 228/255, green: 229/255, blue: 230/255) : Color(red: 208/255, green: 209/255, blue: 213/255))
        }.frame(height: 50)
    }
}



//Our app pages are built on a LazyVGrid. This should be beneficial in the future...wink wink.
struct apps: View {
    @Binding var apps_scale: CGFloat
    @Binding var apps_scale_height: CGFloat
    @Binding var show_searchField:Bool
    @Binding var icon_scaler: CGFloat
    @Binding var current_view: String
    @Binding var dock_offset: CGFloat
    var width: CGFloat
    var height: CGFloat
    
    var body: some View {
        VStack {
            LazyVGrid(columns: [
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1)
            ], alignment: .center, spacing: UIScreen.main.bounds.height/(844/40)*icon_scaler) {
                app(image_name: "Messages", app_name: "Messages", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                app_calendar(image_name: "Calendar", app_name: "Calendar", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                app(image_name: "Photos", app_name: "Photos", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                app(image_name: "Camera", app_name: "Camera", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                app(image_name: "YouTube", app_name: "YouTube", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                app(image_name: "Stocks", app_name: "Stocks", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                app(image_name: "Maps", app_name: "Maps", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                app(image_name: "Weather Fahrenheit", app_name: "Weather", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                
            }
            Spacer().frame(height:UIScreen.main.bounds.height/(844/40)*icon_scaler)
            LazyVGrid(columns: [
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1)
            ], alignment: .center, spacing: UIScreen.main.bounds.height/(844/40)*icon_scaler) {
                app(image_name: "Notes", app_name: "Notes", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                app(image_name: "Utilities", app_name: "Utilities", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                app(image_name: "iTunes", app_name: "iTunes", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                app(image_name: "App Store", app_name: "App Store", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                app(image_name: "Game Center", app_name: "Game Center", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                app(image_name: "Settings", app_name: "Settings", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                
                
            }
            Spacer()
        }.onAppear() {
            UIApplication.shared.endEditing()
        }//.offset(y:-15)
    }
}

struct apps_second: View {
    @Binding var apps_scale: CGFloat
    @Binding var apps_scale_height: CGFloat
    @Binding var show_searchField:Bool
    @Binding var icon_scaler: CGFloat
    @Binding var current_view: String
    @Binding var dock_offset: CGFloat
    var width: CGFloat
    var height: CGFloat
    
    var body: some View {
        VStack {
            LazyVGrid(columns: [
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1)
            ], alignment: .center, spacing: UIScreen.main.bounds.height/(844/40)*icon_scaler) {
                app(image_name: "Contacts", app_name: "Contacts", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                
            }
            Spacer().frame(height:UIScreen.main.bounds.height/(844/40)*icon_scaler)
            Spacer()
        }.onAppear() {
            UIApplication.shared.endEditing()
        }
    }
}

struct multitasking_app: View {
    var image_name: String
    var app_name: String
    @State var pressed = false
    @State var date = Date()
    @Binding var current_view: String
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var show_remove: Bool
    @Binding var should_update: Bool
    @Binding var apps: [String]
    @Binding var apps_main_array: [String]
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
    var body: some View {
        if app_name == "Calendar" {
            Button(action: {
                    if !should_update {
                        withAnimation(.linear(duration: 0.32)) {
                            apps_scale = 4
                            dock_offset = 100
                        }
                        DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
                            withAnimation(.linear(duration: 0.32)) {
                                current_view = app_name
                            }
                        }}}) {
                VStack {
                    ZStack {
                        Image(image_name).resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
                        VStack {
                            Text(getDayOfWeek(date: date)).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 10)).padding(.top, 6).shadow(color: Color.black, radius: 0.2, x: 0, y: 0.75).offset(y: -4).frame(maxWidth: 54).lineLimit(0).minimumScaleFactor(0.8)
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            Text(timeString(date: date)).lineLimit(nil).foregroundColor(.black).font(.custom("Helvetica Neue Bold", fixedSize: 35)).multilineTextAlignment(.center).padding(.top, 10).frame(alignment:.center)
                            Spacer()
                        }
                        VStack {
                            HStack {
                                Button(action:{
                                    withAnimation {
                                    if show_remove {
                                        if let index = apps.firstIndex(where: {$0 == app_name}) {
                                                apps.remove(at: index)
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
                                            if let index2 = apps_main_array.firstIndex(where: {$0 == app_name}) {
                                                apps_main_array.remove(at: index2)
                                            }
                                            }
                                            }
                                        }
                                    }
                                }) {
                                Image("SwitcherQuitBox").offset(x: 0, y: -10)
                                }
                                Spacer()
                            }
                            Spacer()
                        }.opacity(show_remove ? 1 : 0).animationsDisabled()
                    }
                    Text(app_name).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 13)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).offset(y: -4)
                }.onTapGesture {
                    if !should_update {
                        withAnimation(.linear(duration: 0.32)) {
                            apps_scale = 4
                            dock_offset = 100
                        }
                        DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
                            withAnimation(.linear(duration: 0.32)) {
                                current_view = app_name
                            }
                        }
                    }
                }
                .onLongPressGesture() {
                    if !should_update, !show_remove {
                    should_update = true
                    show_remove = true
                    }
                }
            }
        } else {
            Button(action: {
                    if !should_update {
                        withAnimation(.linear(duration: 0.32)) {
                            apps_scale = 4
                            dock_offset = 100
                        }
                        DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
                            withAnimation(.linear(duration: 0.32)) {
                                current_view = app_name
                            }
                        }}}) {
                VStack {
                    ZStack {
                        if pressed {
                            Rectangle().fill(Color.gray).frame(width: UIScreen.main.bounds.width/(390/60), height: UIScreen.main.bounds.width/(390/60)).cornerRadius(14)
                        }
                        Image(image_name).resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
                        //  if wiggle {
                 
                        VStack {
                            HStack {
                                Button(action:{
                                    withAnimation {
                                    if show_remove {
                                        if let index = apps.firstIndex(where: {$0 == app_name}) {
                                                apps.remove(at: index)
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
                                            if let index2 = apps_main_array.firstIndex(where: {$0 == app_name}) {
                                                apps_main_array.remove(at: index2)
                                            }
                                            }
                                            }
                                        }
                                    }
                                }) {
                                Image("SwitcherQuitBox").offset(x: 0, y: -10)
                                }
                                Spacer()
                            }
                            Spacer()
                        }.opacity(show_remove ? 1 : 0).animationsDisabled()
                        // }
                    }
                    Text(app_name).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 13)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).offset(y: -4)
                }.onTapGesture {
                    if !should_update {
                        withAnimation(.linear(duration: 0.32)) {
                            apps_scale = 4
                            dock_offset = 100
                        }
                        DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
                            withAnimation(.linear(duration: 0.32)) {
                                current_view = app_name
                            }
                        }
                    }
                }
                .onLongPressGesture() {
                    if !should_update, !show_remove {
                    should_update = true
                    show_remove = true
                    }
                }
            }
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


struct app: View {
    var image_name: String
    var app_name: String
    @State var pressed = false
    @Binding var current_view: String
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    var body: some View {
        Button(action: {
            if app_name != "Utilities" {
                withAnimation(.linear(duration: 0.32)) {
                    apps_scale = 4
                    dock_offset = 100
                }
                DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
                    withAnimation(.linear(duration: 0.32)) {
                        current_view = app_name
                    }
                }
            }
        }) {
            VStack {
                ZStack {
                    if pressed {
                        Rectangle().fill(Color.gray).frame(width: UIScreen.main.bounds.width/(390/60), height: UIScreen.main.bounds.width/(390/60)).cornerRadius(14)
                    }
                    Image(image_name).resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
                }
                Text(app_name).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 13)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).offset(y: -4)
            }
        }
    }
}
struct app_calendar: View {
    var image_name: String
    var app_name: String
    @Binding var current_view: String
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @State var date = Date()
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
    var body: some View {
        Button(action: {
                withAnimation(.linear(duration: 0.32)) {
                    apps_scale = 4
                    dock_offset = 100
                }
                DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
                    withAnimation(.linear(duration: 0.32)) {
                        current_view = app_name
                    }
                }}) {
            VStack {
                ZStack {
                    Image(image_name).resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
                    VStack {
                        Text(getDayOfWeek(date: date)).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 10)).padding(.top, 6).shadow(color: Color.black, radius: 0.2, x: 0, y: 0.75).offset(y: -4).frame(maxWidth: 54).lineLimit(0).minimumScaleFactor(0.8)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Text(timeString(date: date)).lineLimit(nil).foregroundColor(.black).font(.custom("Helvetica Neue Bold", fixedSize: 35)).multilineTextAlignment(.center).padding(.top, 10).frame(alignment:.center)
                        Spacer()
                    }
                }
                Text(app_name).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 13)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).offset(y: -4)
            }
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
struct app_reflection: View {
    var image_name: String
    var app_name: String
    var body: some View {
        VStack {
            Image(image_name).resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60), height: UIScreen.main.bounds.width/(390/65))
        }
    }
}
func configureNetworkMonitor(completion: @escaping (Bool)->()) {
    let monitor = NWPathMonitor()
    
    monitor.pathUpdateHandler = { path in
        
        if path.status != .satisfied {
            completion(false)
        }
        else if path.usesInterfaceType(.cellular) {
            completion(false)
        }
        else if path.usesInterfaceType(.wifi) {
            completion(true)
        }
        else if path.usesInterfaceType(.wiredEthernet) {
            completion(false)
        }
        else if path.usesInterfaceType(.other){
            completion(false)
        }else if path.usesInterfaceType(.loopback){
            completion(false)
        }
    }
    
    monitor.start(queue: DispatchQueue.global(qos: .background))
}

struct status_bar: View {
    @State var date = Date()
    var locked = false
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var battery_level = UIDevice.current.batteryLevel * 100
    @State var carrier_id: String = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.first?.value.carrierName ?? ""
    @State var charging: Bool = false
    @State var wifi_connected : Bool = true
    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
            HStack {
                Text(carrier_id == "" ? "No SIM" : carrier_id).foregroundColor(Color.init(red: 200/255, green: 200/255, blue: 200/255)).font(.custom("Helvetica Neue Medium", fixedSize: 15)).onAppear() {
                    let networkInfo = CTTelephonyNetworkInfo()
                    let carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value
                    
                    // Get carrier name
                    let carrierName = carrier?.carrierName
                    carrier_id = carrierName ?? ""
                }
                Image(systemName: "wifi").foregroundColor(Color.init(red: 190/255, green: 190/255, blue: 190/255)).opacity(wifi_connected ? 1 : 0)
                Spacer()
                Text("\(Int(battery_level))%").isHidden(charging).foregroundColor(Color.init(red: 190/255, green: 190/255, blue: 190/255)).font(.custom("Helvetica Neue Medium", fixedSize: 15)).offset(x: 10)
                battery(battery: Float(battery_level/100), charging: charging)
                    .onReceive(timer) { input in
                        if (UIDevice.current.batteryState != .unplugged) {
                            battery_level = 100
                            charging = true
                        } else {
                            battery_level = UIDevice.current.batteryLevel * 100
                            charging = false
                        }
                        date = Date()
                        if carrier_id == "" {
                            let networkInfo = CTTelephonyNetworkInfo()
                            let carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value
                            
                            // Get carrier name
                            let carrierName = carrier?.carrierName
                            carrier_id = carrierName ?? ""
                        }
                        configureNetworkMonitor(completion: {result in
                            wifi_connected = result
                        })
                    }.offset(x: 5)
                //Spacer()
            }.padding([.leading, .trailing], 4)
            HStack {
                Spacer()
                if locked {
                    Image(systemName: "lock.fill").resizable().foregroundColor(Color.init(red: 190/255, green: 190/255, blue: 190/255)).frame(width: 10, height: 14)
                } else {
                    Text(timeString(date: date).uppercased()).foregroundColor(Color.init(red: 190/255, green: 190/255, blue: 190/255)).font(.custom("Helvetica Neue Medium", fixedSize: 15))
                }
                Spacer()
            }
        }.onAppear() {
            if carrier_id == "" {
                let networkInfo = CTTelephonyNetworkInfo()
                let carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value
                let carrierName = carrier?.carrierName
                carrier_id = carrierName ?? ""
            }
            configureNetworkMonitor(completion: {result in
                wifi_connected = result
            })
            UIDevice.current.isBatteryMonitoringEnabled = true
            if (UIDevice.current.batteryState != .unplugged) {
                battery_level = 100
                charging = true
            } else {
                battery_level = UIDevice.current.batteryLevel * 100
            }
        }
    }
    func timeString(date: Date) -> String {
        timeFormat.string(from: date)
    }
}

struct dock2: View {
    @Binding var current_view: String
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var show_multitasking: Bool
    var columns: [GridItem] = [
        GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
        GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
        GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
        GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1)
    ]
    var body: some View {
        ZStack {
            VStack {
                Spacer()//SB Dock avail
                Image("SBDockBG 2").resizable().opacity(0.85).frame(height:UIScreen.main.bounds.height/(844/50))
            }
            VStack {
                Spacer()
                ZStack {
                    LazyVGrid(columns: columns, alignment: .center, spacing: UIScreen.main.bounds.height/(844/40)) {
                        app_reflection(image_name: "Phone", app_name: "Phone").rotationEffect(.degrees(180)).opacity(0.3) .offset(y:35) .clipped().offset(y:12)
                        app_reflection(image_name: "Mail", app_name: "Mail").rotationEffect(.degrees(180)).opacity(0.3) .offset(y:35) .clipped().offset(y:12)
                        app_reflection(image_name: "Safari", app_name: "Safari").rotationEffect(.degrees(180)).opacity(0.3) .offset(y:35) .clipped().offset(y:12)
                        app_reflection(image_name: "iPod", app_name: "iPod").rotationEffect(.degrees(180)).opacity(0.4) .offset(y:35) .clipped().offset(y:12)
                    }
                    LazyVGrid(columns: columns, alignment: .center, spacing: UIScreen.main.bounds.height/(844/40)) {
                        app(image_name: "Phone", app_name: "Phone", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                        app(image_name: "Mail", app_name: "Mail", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                        app(image_name: "Safari", app_name: "Safari", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                        app(image_name: "iPod", app_name: "iPod", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                    }.offset(y: 0)
                }
            }.grayscale(show_multitasking == true ? 0.99 : 0).opacity(show_multitasking == true ? 0.3 : 1)
        }
    }
}
struct battery: View {
    var battery = Float()
    var charging = Bool()
    let rect = CGRect(x: 0, y: 0, width: 17, height: 6.5)
    var body: some View {
        HStack {
            ZStack {
                Rectangle().overlay(RoundedRectangle(cornerRadius:0.25).stroke(Color.init(red: 190/255, green: 190/255, blue: 190/255), lineWidth: 1.25)).foregroundColor(.clear).frame(width: 23.0, height: 12.25)
                Rectangle().frame(width: 18.5*CGFloat(battery), height: 8).foregroundColor(battery <= 0.20 ? .red : Color.init(red: 190/255, green: 190/255, blue: 190/255)).offset(x:(-18.5/2)+(18.5/2)*CGFloat(battery)) .applyModifier(charging) {  AnyView($0.mask(ZStack {Image(systemName:"bolt.fill").resizable().frame(width: 8, height: 7)}.frame(width: 18.5*CGFloat(battery), height: 8).foregroundColor(.black).background(Color.white)                .compositingGroup().luminanceToAlpha()))
                }
            }
            Rectangle().overlay(RoundedRectangle(cornerRadius:0.25).stroke(Color.init(red: 190/255, green: 190/255, blue: 190/255), lineWidth: 1)).foregroundColor(.clear).frame(width: 3, height: 5).offset(x:-7.95)
        }
    }
}

struct Controller_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Controller()
            Controller()
                .previewDevice("iPhone 12 Pro Max")
            Controller()
                .previewDevice("iPhone 8 Plus")
        }
    }
}
extension View {
    
    func applyModifier(_ condition:Bool, apply:(AnyView) -> (AnyView)) -> AnyView {
        if condition {
            return apply(AnyView(self))
        }
        else {
            return AnyView(self)
        }
    }
    @ViewBuilder func isHidden(_ hidden: Bool, remove: Bool = false) -> some View {
        if hidden {
            if !remove {
                self.hidden()
            }
        } else {
            self
        }
    }
}
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    func startEditing() {
        sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
    }
}

