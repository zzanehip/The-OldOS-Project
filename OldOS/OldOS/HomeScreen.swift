////
////  ContentView.swift
////  OldOS
////
////  Created by Zane Kleinberg on 1/9/21.
////
//
//import SwiftUI
//import CoreTelephony
//import PureSwiftUITools
//import Network
//import Combine
//
//extension View where Self: Equatable {
//    public func equatable() -> EquatableView<Self> {
//        return EquatableView(content: self)
//    }
//}
//
//struct multitasking_controller: View {
//    @Binding var current_view: String
//    @Binding var apps_scale: CGFloat
//    @Binding var dock_offset: CGFloat
//    @Binding var multitasking_apps: [String]
//    @Binding var instant_multitasking_change: Bool
//    @Binding var current_multitasking_app: String
//    @Binding var should_update: Bool
//    @Binding var show_remove: Bool
//    @Binding var show_multitasking: Bool
//    var relative_app: String
//    var body: some View {
//        if instant_multitasking_change, relative_app == current_multitasking_app {
//            VStack(spacing: 0) {
//                Spacer()
//                multitasking_view(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, should_update: $should_update, show_remove: $show_remove, instant_multitasking_change: $instant_multitasking_change, show_multitasking: $show_multitasking, apps: $multitasking_apps).frame(height:UIScreen.main.bounds.width/(390/85) + 20).padding([.leading, .trailing])
//            }.if(relative_app != "HS"){$0.transition(.scale)}.onAppear(perform: {
//                UIScrollView.appearance().bounces = false
//            })
//        }
//    }
//}
//
//
//
////Here's how our view hierarchy works: we manage everything in a view I've deemed "Controller." It's super simple, we change the current view string, and the entire screen changes. Simple, elegant, and the way I like doing it.
//struct Controller: View {
//    
//    @State var current_view: String = "HS"
//    @State var multitasking_apps: [String] = []
//    @State var apps_scale: CGFloat = 4
//    @State var dock_offset: CGFloat = 100
//    @State var apps_scale_height: CGFloat = 1 //12.75
//    @State var selected_page = 1
//    @State var search_width: CGFloat = 0.0
//    @State var search_height: CGFloat = 0.0
//    @State var show_multitasking: Bool = false
//    @State var instant_multitasking_change: Bool = false
//    @State var current_multitasking_app: String = "HS"
//    @State var should_update: Bool = false
//    @State var show_remove: Bool = false
//    @State var folder_offset: CGFloat = 0
//    @State var show_folder: Bool = false
//    @EnvironmentObject var MusicObserver: MusicObserver
//    @EnvironmentObject var EmailManager: EmailManager
//    var body: some View {
//        ZStack {
//            Color.black.edgesIgnoringSafeArea(.all)
//            GeometryReader {geometry in
//                VStack {
//                    Spacer()
//                    ZStack {
//                        ZStack {
//                            switch current_view {
//                            case "LS":
//                                LockScreen(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, apps_scale_height: $apps_scale_height).padding([.leading, .trailing])
//                            case "HS":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "HS")
//                                HomeScreen(apps_scale: $apps_scale, apps_scale_height: $apps_scale_height, dock_offset: $dock_offset, selectedPage: $selected_page, search_width: $search_width, search_height:$search_height, current_view: $current_view, show_multitasking: $show_multitasking, instant_multitasking_change: $instant_multitasking_change, folder_offset: $folder_offset, show_folder: $show_folder).padding([.leading, .trailing]).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "HS") //.compositingGroup() -> maybe
//                            case "Settings":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Settings")
//                                Settings(show_multitasking: $instant_multitasking_change).equatable().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Settings").environmentObject(EmailManager)
//                            case "iPod":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "iPod")
//                                iPod().padding([.leading, .trailing]).transition(.scale).environmentObject(MusicObserver).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "iPod")
//                            case "Safari":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Safari")
//                                Safari(instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Safari")
//                            case "Mail":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Mail")
//                                Mail().padding([.leading, .trailing]).transition(.scale).environmentObject(EmailManager).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Mail")
//                            case "Phone":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Phone")
//                                Phone(instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Phone")
//                            case "Game Center":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Game Center")
//                                GameCenter(instant_multitasking_change: $instant_multitasking_change).equatable().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Game Center")
//                            case "App Store":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "App Store")
//                                AppStore(instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "App Store")
//                            case "iTunes":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "iTunes")
//                                iTunes(instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "iTunes")
//                            case "Notes":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Notes")
//                                Notes(instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Notes")
//                            case "Weather":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Weather")
//                                Weather(show_multitasking: $show_multitasking).equatable().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Weather")
//                            case "Maps":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Maps")
//                                Maps(instant_multitasking_change: $instant_multitasking_change, show_multitasking: $show_multitasking, should_show: current_multitasking_app == "Maps").padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking(show_multitasking, instant_multitasking_change, current_multitasking_app == "Maps")//.modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Maps")
//                            case "YouTube":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "YouTube")
//                                Youtube(instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "YouTube")
//                            case "Camera":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Camera")
//                                Camera(instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Camera")
//                            case "Contacts":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Contacts")
//                                Contacts().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Contacts")
//                            case "Messages":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Messages")
//                                Messages().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Messages")
//                            case "Photos":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Photos")
//                                Photos(instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Photos")
//                            case "Stocks":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Stocks")
//                                Stocks(show_multitasking: $show_multitasking).equatable().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Stocks")
//                            case "Calendar":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Calendar")
//                                CalendarView().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Calendar")
//                            case "Compass":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Compass")
//                                Compass(current_view: $current_view).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Compass")
//                            case "Voice Memos":
//                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Voice Memos")
//                                VoiceMemos().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Voice Memos")
//                            default:
//                                LockScreen(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, apps_scale_height: $apps_scale_height).padding([.leading, .trailing])
//                            }
//                        }//.disabled(show_multitasking)
//                    }
//                    Spacer().frame(height:1)
//                    home_bar(selectedPage: $selected_page, current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, show_multitasking: $show_multitasking, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, folder_offset: $folder_offset, show_folder: $show_folder).padding(.top).frame(height: 100)
//                }
//            }
//        }.ignoresSafeArea(.keyboard).onAppear() {
//            withAnimation(.linear(duration:0)) {
//                current_view = "LS"
//            } //-> It's an interesting solution, but if we set the view first to the HomeScreen, let it render, and then immediately switch to the lock-screen, we'll get a much smoother animation.
//            withAnimation(.linear(duration: 0.01)) {
//                apps_scale = 4
//                dock_offset = 100
//            }
//        }.onChange(of: current_view) {_ in
//            if instant_multitasking_change {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                    show_multitasking = false
//                    instant_multitasking_change = false
//                }
//            }
//            if current_view != "HS" && current_view != "LS" {
//                if let index = multitasking_apps.firstIndex(of: current_view) {
//                    multitasking_apps.remove(at: index)
//                }
//                multitasking_apps.insert(current_view, at: 0)
//            }
//        } .ifButtonShapesEnabledLive { view in
//            view.buttonStyle(buttonShapesOverride())
//        }//.buttonStyle(buttonShapesOverride())
//    }
//}
//
//extension View {
//    func modifiedForMultitasking(_ show_multitasking: Bool, _ instant_multitasking_change: Bool, _ should_show: Bool) -> some View {
//        self.offset(y: (show_multitasking == true && should_show == true) ? -(UIScreen.main.bounds.width/(390/85) + 20) : 0).clipped().disabled((show_multitasking == true && should_show == true))//.shadow(color: Color.black.opacity((instant_multitasking_change == true && should_show == true) ? 0.85 : 0), radius: 6, x: 0, y: 4).disabled((show_multitasking == true && should_show == true))
//    }
//    func modifiedForMultitasking2(_ show_multitasking: Bool, _ instant_multitasking_change: Bool, _ should_show: Bool) -> some View {
//        self.offset(y: (show_multitasking == true && should_show == true) ? -(UIScreen.main.bounds.width/(390/85) + 20) : 0).clipped().shadow(color: Color.black.opacity((instant_multitasking_change == true && should_show == true) ? 0.85 : 0), radius: 6, x: 0, y: 4).disabled((show_multitasking == true && should_show == true))
//    }
//}
//
//extension Array {
//    func chunked(into size: Int) -> [[Element]] {
//        return stride(from: 0, to: count, by: size).map {
//            Array(self[$0 ..< Swift.min($0 + size, count)])
//        }
//    }
//}
//
//struct multitasking_view: View {
//    @State var selectedPage: Int = 2
//    @State var dual_angle: Double = 0.0
//    var timer = Timer.publish(every: 0.000625, on: .main, in: .common).autoconnect()
//    @Binding var current_view: String
//    @Binding var apps_scale: CGFloat
//    @Binding var dock_offset: CGFloat
//    @Binding var should_update: Bool
//    @Binding var show_remove: Bool
//    @Binding var instant_multitasking_change: Bool
//    @Binding var show_multitasking: Bool
//    @Binding var apps: [String]
//    var body: some View {
//        GeometryReader {geometry in
//            ZStack {
//                Image("FolderSwitcherBG").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).frame(width:geometry.size.width, height: geometry.size.height)
//                TabView(selection: $selectedPage.animation()) {
//                    multitasking_audio_controls().tag(0)
//                    multitasking_music_controls(current_view: $current_view, should_update: $should_update, show_remove: $show_remove, instant_multitasking_change: $instant_multitasking_change, show_multitasking: $show_multitasking, apps_scale: $apps_scale, dock_offset: $dock_offset).tag(1)
//                    if apps.filter({$0 != current_view}).count == 0 {
//                        Spacer().tag(2)
//                    } else {
//                    ForEach(Array(apps.filter({$0 != current_view}).chunked(into: 4).enumerated()), id:\.element) {(i, app_section) in
//                        multitasking_app_section(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, dual_angle: $dual_angle, should_update: $should_update, show_remove: $show_remove, apps_main_array: $apps, apps: app_section).frame(width:geometry.size.width, height: geometry.size.height).tag((apps.chunked(into:4).firstIndex(of: app_section) ?? 0) + 2)
//                    }
//                    }
//                }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)).frame(width:geometry.size.width, height: geometry.size.height)
//                
//            }
//        }.onReceive(timer) { _ in
//            withAnimation(.linear(duration: 0.2)) {
//            if should_update {
//                    dual_angle += 1
//                print(dual_angle)
//            } else {
//                dual_angle = 0
//            }
//            }
//        }
//    }
//}
//func deg2rad(_ number: Double) -> Double {
//    return number * .pi / 180
//}
//
//struct multitasking_app_section: View {
//    @State var icon_scaler: CGFloat = 1.0
//    @State var switcher: Bool = false
//    @Binding var current_view: String
//    @Binding var apps_scale: CGFloat
//    @Binding var dock_offset: CGFloat
//    @Binding var dual_angle: Double
//    @Binding var should_update: Bool
//    @Binding var show_remove: Bool
//    @Binding var apps_main_array: [String]
//    @State var apps: [String]
//    var body: some View {
//        VStack(spacing: 0) {
//            Spacer()
//            LazyVGrid(columns: [
//                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
//                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
//                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
//                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1)
//            ], alignment: .center, spacing: UIScreen.main.bounds.height/(844/40)*icon_scaler) {
//                ForEach(Array(apps.enumerated()), id:\.element) { (i, r_app) in
//                    multitasking_app(image_name: r_app == "Weather" ? "Weather Fahrenheit" : r_app, app_name: r_app, current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, show_remove: $show_remove, should_update: $should_update, apps: $apps, apps_main_array: $apps_main_array).rotationEffect(.degrees(sin(deg2rad(dual_angle))*Double.random(in: 1...3)*1.25)).offset(x: -CGFloat(sin(deg2rad(dual_angle))*Double.random(in: -2...2)*0.75), y: 0).transition(.asymmetric(insertion: .slide, removal: .scale))
//                }
//                    
//            }
//        }.onAppear() {
//            //MARK — iPhone 8
//            if UIScreen.main.bounds.width == 375 && UIScreen.main.bounds.height == 667 {
//                icon_scaler = 0.55
//            }
//            //MARK — iPhone 8 Plus
//            if UIScreen.main.bounds.width == 414 && UIScreen.main.bounds.height == 736 {
//                icon_scaler = 0.8
//            }
//        }
//    }
//}
//
//struct multitasking_audio_controls: View {
//    @ObservedObject private var volObserver = VolumeObserver()
//    var body: some View {
//        HStack {
//            LazyVGrid(columns: [
//                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)*3), spacing: 1),
//                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
//            ], alignment: .center, spacing: UIScreen.main.bounds.height/(844/40)) {
//                CustomSlider(type: "Volume", value: $volObserver.volume.double,  range: (0, 100)) { modifiers in
//                    ZStack {
//                        RoundedRectangle(cornerRadius: 8.5/2).fill(Color.white.opacity(0.4)).brightness(-0.02).innerShadowSliderMultiDiffed(color: Color.black, radius: 0.75).frame(height: 8.5).cornerRadius(8.5/2).padding(.leading, 4).clipShape(RoundedRectangle(cornerRadius: 8.5/2)).shadow(color: Color(red: 183/255, green: 183/255, blue: 184/255).opacity(0.5), radius: 0, x: 0, y: 1).modifier(modifiers.barLeft)
//                        RoundedRectangle(cornerRadius: 8.5/2).fill(Color.black.opacity(0.4)).brightness(-0.1).innerShadowSliderMulti(color: Color.black.opacity(0.75), radius: 0.75).frame(height: 8.5).cornerRadius(8.5/2).padding(.trailing, 4).clipShape(RoundedRectangle(cornerRadius: 8.5/2)).shadow(color: Color(red: 183/255, green: 183/255, blue: 184/255).opacity(0.5), radius: 0, x: 0, y: 1).modifier(modifiers.barRight)
//                        ZStack {
//                            Image("SwitcherSliderThumb").resizable().scaledToFill()
//                            
//                        }.modifier(modifiers.knob)
//                    }
//                }.frame(height: 25).padding([.leading], 30)
//                Image("SwitcherAirPlayNowPlayingButton")
//            }
//        }.overlay(VStack {
//            Spacer()
//            Image("SwitcherVolumeIcon").offset(y: 10)
//        })
//    }
//}
//
//struct home_bar: View {
//    @State var momentary_disable: Bool = false
//    @Binding var selectedPage: Int
//    @Binding var current_view: String
//    @Binding var apps_scale: CGFloat
//    @Binding var dock_offset: CGFloat
//    @Binding var show_multitasking: Bool
//    @Binding var instant_multitasking_change: Bool
//    @Binding var current_multitasking_app: String
//    @Binding var should_update: Bool
//    @Binding var show_remove: Bool
//    @Binding var folder_offset: CGFloat
//    @Binding var show_folder: Bool
//    
//    @State private var isPressed: Bool = false
//    @State private var pressCount = 0
//    @State private var actionWorkItem: DispatchWorkItem?
//
//    var body: some View {
//        ZStack {
//            ZStack {
//                Circle().fill(Color.black).frame(width: 65, height:65).overlay(
//                    Circle()
//                        .stroke(Color.gray.opacity(0.35), lineWidth: 1)
//                )
//                Circle().fill(LinearGradient(gradient: Gradient(colors: [.black, .black, .black, Color.gray.opacity(0.35)]), startPoint: .top, endPoint: .bottom)).frame(width: 65, height:65).scaleEffect(isPressed ? 0.90 : 0.93)
//                    .shadow(color: isPressed ? Color.gray.opacity(0.2) : Color.gray.opacity(0.3), radius: 4, x: 0, y: 1).offset(y: isPressed ? 0.75 : 0)
//                    
//                RoundedRectangle(cornerRadius: 4).fill(Color.black).frame(width: 20, height:20).overlay(
//                    RoundedRectangle(cornerRadius: 4)
//                        .stroke(Color.gray.opacity(0.65), lineWidth: 1.75)
//                )
//            }
//            ForceTouchGestureView(onStateChange: { isPressedDown in
//                handlePress(isDown: isPressedDown)
//            })
//            .frame(width: 65, height: 65)
//        }
//        .padding()
//    }
//        
//    private func handlePress(isDown: Bool) {
//        // Always update visual state and haptics
//        self.isPressed = isDown
//        
//        if isDown {
//            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
//            
//            // Cancel any pending single-press action from a previous tap
//            actionWorkItem?.cancel()
//            
//            pressCount += 1
//            
//            if pressCount == 2 {
//                // This is a confirmed double-press, fire the action immediately
//                performDoubleHomeAction()
//            }
//            
//        } else {
//            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
//            
//            if pressCount == 1 {
//                // The user has lifted their finger after one press.
//                // Schedule the single-press action to happen after a short delay.
//                actionWorkItem = DispatchWorkItem {
//                    performHomeAction()
//                    pressCount = 0 // Reset after action is performed
//                }
//                // The 0.3s delay gives the user time to initiate a second press.
//                // If they do, the `cancel()` above will stop this from running.
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: actionWorkItem!)
//                
//            } else if pressCount >= 2 {
//                // If it was a double-press or more, just reset the count immediately on release.
//                pressCount = 0
//            }
//        }
//    }
//    
//    private func performHomeAction() {
//        if show_multitasking == false {
//            if current_view != "LS" && current_view != "HS" {
//                withAnimation(.linear(duration: 0.35)) {
//                    self.current_view = "HS"
//                }
//            } else {
//                withAnimation() {
//                    if show_folder && folder_offset == 150 {
//                        withAnimation(.linear(duration: 0.32)) {
//                            folder_offset = 0
//                        }
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
//                            show_folder = false
//                        }
//                    } else {
//                        if selectedPage == 1 {
//                            selectedPage = 0
//                        } else {
//                            selectedPage = 1
//                        }
//                    }
//                }
//            }
//        } else {
//            if should_update, show_remove {
//                should_update = false
//                show_remove = false
//            } else {
//                withAnimation {
//                    show_multitasking = false
//                }
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
//                    instant_multitasking_change = false
//                }
//            }
//        }
//    }
//    
//    private func performDoubleHomeAction() {
//        if current_view != "LS" && !show_folder {
//            current_multitasking_app = current_view
//            if !momentary_disable {
//                if !show_multitasking {
//                    instant_multitasking_change = true
//                    momentary_disable = true
//                    withAnimation {
//                        show_multitasking = true
//                    }
//                } else {
//                    momentary_disable = true
//                    withAnimation {
//                        show_multitasking = false
//                    }
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
//                        instant_multitasking_change = false
//                    }
//                }
//            }
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                momentary_disable = false
//            }
//        }
//    }
//}
////Thanks to https://stackoverflow.com/questions/66430942/handle-single-click-and-double-click-while-updating-the-view/66432412#66432412 for this solution. SwiftUI causes a delay in tapGestures...which is really annoying.
//
//struct TapRecognizerViewModifier: ViewModifier {
//    
//    @State private var singleTapIsTaped: Bool = Bool()
//    
//    var tapSensitivity: Double
//    var singleTapAction: () -> Void
//    var doubleTapAction: () -> Void
//    
//    init(tapSensitivity: Double, singleTapAction: @escaping () -> Void, doubleTapAction: @escaping () -> Void) {
//        self.tapSensitivity = tapSensitivity
//        self.singleTapAction = singleTapAction
//        self.doubleTapAction = doubleTapAction
//    }
//    
//    func body(content: Content) -> some View {
//        
//        return content
//            .gesture(simultaneouslyGesture)
//        
//    }
//    
//    private var singleTapGesture: some Gesture { TapGesture(count: 1).onEnded{
//        
//        singleTapIsTaped = true
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + tapSensitivity) { if singleTapIsTaped { singleTapAction() } }
//        
//    } }
//    
//    private var doubleTapGesture: some Gesture { TapGesture(count: 2).onEnded{ singleTapIsTaped = false; doubleTapAction() } }
//    
//    private var simultaneouslyGesture: some Gesture { singleTapGesture.simultaneously(with: doubleTapGesture) }
//    
//}
//
//
//extension View {
//    
//    func tapRecognizer(tapSensitivity: Double, singleTapAction: @escaping () -> Void, doubleTapAction: @escaping () -> Void) -> some View {
//        
//        return self.modifier(TapRecognizerViewModifier(tapSensitivity: tapSensitivity, singleTapAction: singleTapAction, doubleTapAction: doubleTapAction))
//        
//    }
//    
//}
//
//
//struct HomeScreen: View {
//    @Binding var apps_scale: CGFloat
//    @Binding var apps_scale_height: CGFloat
//    @Binding var dock_offset: CGFloat
//    @Binding var selectedPage: Int
//    @Binding var search_width: CGFloat
//    @Binding var search_height: CGFloat
//    @State var show_searchField: Bool = false
//    @State var icon_spacing_horizontal_resize: CGFloat = 0.0
//    @State var icon_spacing_vertical_resize: CGFloat = 0.0
//    @State var bottom_indicator_offset: CGFloat = 0.0
//    @State var icon_scaler: CGFloat = 1.0
//    @State private var flyAnimatedIn: Bool = false
//    @Binding var current_view: String
//    @Binding var show_multitasking: Bool
//    @Binding var instant_multitasking_change: Bool
//    @Binding var folder_offset: CGFloat
//    @Binding var show_folder: Bool
//    @GestureState  var dragOffset: CGFloat = 0
//    var userDefaults = UserDefaults.standard
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack {
//                WallpaperBackground(geometry: geometry).onTapGesture {
//                    if folder_offset == 150 && show_folder {
//                        withAnimation(.linear(duration: 0.32)) { folder_offset = 0 }
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) { show_folder = false }
//                    }
//                }
//                
//                if show_folder {
//                    VStack(spacing: 0) {
//                        // whatever sits above...
//                        Spacer().frame(height: 3*(UIScreen.main.bounds.width/(390/85)
//                                                  + UIScreen.main.bounds.height/(844/40) * icon_scaler))
//                        
//                        ZStack(alignment: .top) {
//                            Image("FolderSwitcherBG")
//                                .resizable()
//                                .scaledToFill()
//                                .frame(height: 150, alignment: .top)
//                                .clipped()
//                                .mask(
//                                    FolderIsoscelesMask(triangleHeight: 18, baseWidth: 24, triangleCenterX: 10 + 1.5*UIScreen.main.bounds.width / (390/85))
//                                )
//                                .overlay(
//                                    FolderIsoscelesTopBottomBorder(triangleHeight: 18, baseWidth: 24, triangleCenterX: 10 + 1.5*UIScreen.main.bounds.width / (390/85), lineWidth: 1)
//                                        .stroke(.white.opacity(0.6), style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter, miterLimit: 2))
//                                )
//                                .folderInnerShadow(
//                                    using: FolderIsoscelesMask(triangleHeight: 18, baseWidth: 24, triangleCenterX: 10 + 1.5*UIScreen.main.bounds.width / (390/85)),
//                                    color: .black.opacity(0.4),
//                                    lineWidth: 8,
//                                    blur: 6,
//                                    offset: CGPoint(x: 0, y: 4)
//                                )
//                            
//                                
//                            VStack(spacing: 0) {
//                                Spacer().frame(height: 18)
//                                Spacer()
//                                HStack(spacing: 0) {
//                                    Text("Utilities").foregroundColor(.white).font(.custom("Helvetica Neue Bold", fixedSize: 20)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).padding(.leading, 24)
//                                    Spacer()
//                                }//.padding(.top, 28)
//                                Spacer().frame(height: 10)
//                                folder_apps(apps_scale:$apps_scale, apps_scale_height: $apps_scale_height, icon_scaler: $icon_scaler, current_view: $current_view, dock_offset: $dock_offset, folder_offset: $folder_offset, show_folder: $show_folder).zIndex(10)
//                                Spacer()
//                                
//                            }
//                        }.allowsHitTesting(folder_offset > 0)
//                        .frame(height: 150, alignment: .top)
//                        
//                        // This is a rather obscure solution, I will admit. Our problem is we need a tappable region below the folder. Using Color.clear with a content shape instead of a spacer gives us a such a region.
//                        Color.clear
//                            .contentShape(Rectangle())  // real hit area
//                            .onTapGesture {
//                                if folder_offset == 150 && show_folder {
//                                    withAnimation(.linear(duration: 0.32)) { folder_offset = 0 }
//                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) { show_folder = false }
//                                }
//                            }
//                    }
//                    WallpaperBackgroundFolderOffset(
//                        folder_offset: folder_offset,
//                        icon_scaler: icon_scaler
//                    ).allowsHitTesting(false)
//                }
//                VStack {
//                    Spacer()
//                    if userDefaults.string(forKey: "Home_Wallpaper") == "Wallpaper_1" {
//                        LinearGradient(gradient:Gradient(colors: [Color(red: 158/255, green: 158/255, blue: 158/255).opacity(0.0), Color(red: 34/255, green: 34/255, blue: 34/255)]), startPoint: .top, endPoint: .bottom).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: geometry.size.height/3.75, maxHeight: geometry.size.height/3.75, alignment: .center).clipped()
//                    }else {
//                        LinearGradient(gradient:Gradient(colors: [Color(red: 34/255, green: 34/255, blue: 34/255).opacity(0.0), Color(red: 24/255, green: 24/255, blue: 24/255).opacity(0.85)]), startPoint: .top, endPoint: .bottom).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: geometry.size.height/4.25, maxHeight: geometry.size.height/4.25, alignment: .center).clipped()
//                    }
//                }.allowsHitTesting(false)
//                Color.black.opacity(selectedPage == 0 ? 0.65 : 0).padding(.top, 24).animation(.easeInOut, value: selectedPage)
//                VStack(spacing: 0) {
//                    status_bar().frame(minHeight: 24, maxHeight:24).zIndex(1)
//                    Spacer().frame(height: 30)
////                    Spacer().frame(height: folder_offset)
//                    TabView(selection: $selectedPage) {
//                        search(width: $search_width, height: $search_height, show_searchField: $show_searchField, apps_scale: $apps_scale, current_view: $current_view, dock_offset: $dock_offset).frame(maxWidth: geometry.size.width, maxHeight:geometry.size.height).zIndex(0).clipped().tag(0)
//                        apps(apps_scale:$apps_scale, apps_scale_height: $apps_scale_height, show_searchField: $show_searchField, icon_scaler: $icon_scaler, current_view: $current_view, dock_offset: $dock_offset, folder_offset: $folder_offset, show_folder: $show_folder, flyAnimatedIn: $flyAnimatedIn, isActivePage: selectedPage == 1, width: geometry.size.width, height: geometry.size.height).frame(maxWidth: geometry.size.width, maxHeight:geometry.size.height).zIndex(0).tag(1)    .overlay(
//                            GeometryReader { proxy in
//                                Color.clear.hidden().onAppear() {
//                                    search_width = proxy.size.width
//                                    search_height = proxy.size.height
//                                }
//                            }
//                        )
//                        apps_second(apps_scale:$apps_scale, apps_scale_height: $apps_scale_height, show_searchField: $show_searchField, icon_scaler: $icon_scaler, current_view: $current_view, dock_offset: $dock_offset, folder_offset: $folder_offset, flyAnimatedIn: $flyAnimatedIn, isActivePage: selectedPage == 2, width: geometry.size.width, height: geometry.size.height).frame(maxWidth: geometry.size.width, maxHeight:geometry.size.height).zIndex(0).tag(2).frame(width:search_width, height: search_height)
//                    }.layoutPriority(1).tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)).animation(.easeInOut, value: selectedPage).onAppear() {
//                        UIScrollView.appearance().bounces = false
//                    }.opacity(1/(Double(dock_offset) + 1)).grayscale(show_multitasking == true ? 0.99 : 0).opacity(show_multitasking == true ? 0.3 : 1)
//                    //added layout up there
//                    dock2(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, show_multitasking: $show_multitasking, folder_offset: $folder_offset).frame(maxWidth:geometry.size.width, maxHeight: 150 - folder_offset).offset(y:dock_offset).offset(y:folder_offset/1.5).clipped()
//                }.allowsHitTesting(folder_offset == 0)
//                VStack {
//                    Spacer()
//                    HStack() {
//                        Button {
//                            withAnimation {
//                                selectedPage = max(selectedPage - 1, 0)
//                            }
//                        } label: {
//                            Color.clear.frame(width: geometry.size.width/2.4, height:7.9)
//                        }
//                        Button {
//                            withAnimation {
//                                selectedPage = 0
//                            }
//                        } label: {
//                            Image(systemName: "magnifyingglass").resizable().font(Font.title.weight(.heavy)).foregroundColor(selectedPage == 0 ? Color.white : Color.init(red: 146/255, green: 146/255, blue: 146/255)).frame(width: 7.9, height:7.9).padding(0)
//                        }
//                        Button {
//                            withAnimation {
//                                selectedPage = 1
//                            }
//                        } label: {
//                            Circle().fill(selectedPage == 1 ? Color.white : Color.init(red: 146/255, green: 146/255, blue: 146/255)).frame(height:7.9).padding(0)
//                        }
//                        Button {
//                            withAnimation {
//                                selectedPage = 2
//                            }
//                        } label: {
//                            Circle().fill(selectedPage == 2 ? Color.white : Color.init(red: 146/255, green: 146/255, blue: 146/255)).frame(height:7.9).padding(0)
//                        }
//                        Button {
//                            withAnimation {
//                                selectedPage = min(selectedPage + 1, 2)
//                            }
//                        } label: {
//                            Color.clear.frame(width: geometry.size.width/2.4, height:7.9)
//                        }
//                    }.padding(.bottom, 110).offset(y:dock_offset).offset(y:bottom_indicator_offset).offset(y:folder_offset).allowsHitTesting(folder_offset == 0)
//                }.opacity(show_multitasking == true ? 0 : 1).allowsHitTesting(folder_offset == 0)
//            }
//            // App pages may overflow their TabView page while flying, but the
//            // complete HomeScreen remains clipped to the simulated-phone bounds.
//            .clipped()
//            .onAppear() {
//                // Preserve the known-good explicit fly state. When Utilities is
//                // open, return directly to the expanded folder without running the
//                // HomeScreen fly-in. Otherwise, icons and dock enter together.
//                if show_folder {
//                    flyAnimatedIn = true
//                    apps_scale = 1
//                    dock_offset = 0
//                } else {
//                    flyAnimatedIn = false
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
//                        guard current_view == "HS", !show_folder else { return }
//                        withAnimation(.linear(duration: 0.42)) {
//                            flyAnimatedIn = true
//                            apps_scale = 1
//                            dock_offset = 0
//                        }
//                    }
//                }
//
//                //MARK — iPhone 8
//                if UIScreen.main.bounds.width == 375 && UIScreen.main.bounds.height == 667 {
//                    bottom_indicator_offset = 17.5
//                    icon_scaler = 0.55
//                }
//                //MARK — iPhone 8 Plus
//                if UIScreen.main.bounds.width == 414 && UIScreen.main.bounds.height == 736 {
//                    bottom_indicator_offset = 10
//                    icon_scaler = 0.8
//                }
//                //MARK — iPhone 12 Mini
//                if UIScreen.main.bounds.width == 375 && UIScreen.main.bounds.height == 812 {
//                    bottom_indicator_offset = 8
//                }
//            }
//            .onChange(of: apps_scale) { newScale in
//                // apps_scale changes before current_view when an app launches.
//                // Watching it here works regardless of which TabView page is visible.
//                if current_view == "HS" && !show_folder && newScale > 1.0 && flyAnimatedIn {
//                    withAnimation(.linear(duration: 0.32)) {
//                        flyAnimatedIn = false
//                    }
//                }
//            }
//        }
//    }
//}
//
//extension View {
//    func `HSif`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
//        condition ? AnyView(transform(self)) : AnyView(self)
//    }
//}
////
//
//import SwiftUI
//
//struct WallpaperBackground: View {
//    let geometry: GeometryProxy
//    @State private var cachedWallpaper: UIImage?
//    private let userDefaults = UserDefaults.standard
//    
//    private let wallpaperChangePublisher = NotificationCenter.default.publisher(
//        for: UserDefaults.didChangeNotification
//    )
//
//    var body: some View {
//        ZStack {
//            if userDefaults.bool(forKey: "Camera_Wallpaper_Home") == false {
//                // Regular wallpaper from assets or filename
//                Image(userDefaults.string(forKey: "Home_Wallpaper") ?? "Wallpaper_1")
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .frame(height: geometry.size.height)
//                    .frame(minWidth: geometry.size.width,
//                           maxWidth: geometry.size.width,
//                           minHeight: geometry.size.height,
//                           maxHeight: geometry.size.height,
//                           alignment: .center)
//                    .cornerRadius(0)
//                    .clipped()
//            } else {
//                // Cached data-based wallpaper (decoded once)
//                if let ui = cachedWallpaper {
//                    Image(uiImage: ui)
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .frame(height: geometry.size.height)
//                        .frame(minWidth: geometry.size.width,
//                               maxWidth: geometry.size.width,
//                               minHeight: geometry.size.height,
//                               maxHeight: geometry.size.height,
//                               alignment: .center)
//                        .cornerRadius(0)
//                        .clipped()
//                } else {
//                    // Fallback image while cache loads
//                    Image("Wallpaper_1")
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .frame(height: geometry.size.height)
//                        .frame(minWidth: geometry.size.width,
//                               maxWidth: geometry.size.width,
//                               minHeight: geometry.size.height,
//                               maxHeight: geometry.size.height,
//                               alignment: .center)
//                        .cornerRadius(0)
//                        .clipped()
//                }
//            }
//        }
//        .onAppear(perform: loadWallpaperOnce)
//        .onReceive(wallpaperChangePublisher) { _ in
//                  loadWallpaperOnce()
//              }
//    }
//
//    // Decode once and match screen scale
//    private func loadWallpaperOnce() {
//        guard userDefaults.bool(forKey: "Camera_Wallpaper_Home") == true else { return }
//        if let data = userDefaults.data(forKey: "Home_Wallpaper"),
//           let ui = UIImage(data: data, scale: UIScreen.main.scale)?
//                .preparingForDisplay() {
//            cachedWallpaper = ui
//        } else {
//            cachedWallpaper = UIImage(named: "Wallpaper_1")?.preparingForDisplay()
//        }
//    }
//}
//
//
//struct WallpaperBackgroundFolderOffset: View {
//    let folder_offset: CGFloat
//    let icon_scaler: CGFloat
//    @State private var cachedWallpaper: UIImage?
//    let userDefaults = UserDefaults.standard
//    
//    private let wallpaperChangePublisher = NotificationCenter.default.publisher(
//        for: UserDefaults.didChangeNotification
//    )
//
//    var body: some View {
//        ZStack {
//            if userDefaults.bool(forKey: "Camera_Wallpaper_Home") == false {
//                wallpaperImage(
//                    Image(userDefaults.string(forKey: "Home_Wallpaper") ?? "Wallpaper_1")
//                )
//            } else {
//                if let ui = cachedWallpaper {
//                    wallpaperImage(Image(uiImage: ui))
//                } else {
//                    wallpaperImage(Image("Wallpaper_1"))
//                }
//            }
//        }
//        .onAppear(perform: loadWallpaperOnce)
//        .onReceive(wallpaperChangePublisher) { _ in
//                  loadWallpaperOnce()
//              }
//    }
//
//    @ViewBuilder
//    private func wallpaperImage(_ img: Image) -> some View {
//        GeometryReader { geometry in
//            img
//                .renderingMode(.original)
//                .resizable()
//                .interpolation(.high)
//                .antialiased(true)
//                .aspectRatio(contentMode: .fill)
//                .frame(height: geometry.size.height)
//                .frame(minWidth: geometry.size.width, maxWidth: geometry.size.width,
//                       minHeight: geometry.size.height, maxHeight: geometry.size.height)
//                .offset(y: folder_offset > 50 ? -18 : 0)
//                .compositingGroup()
//                .mask(
//                    VStack(spacing: 0) {
//                        Spacer().frame(height: 3*(UIScreen.main.bounds.width/(390/85)
//                                                  + UIScreen.main.bounds.height/(844/40) * icon_scaler))
//                        FolderIsoscelesMask(
//                            triangleHeight: folder_offset > 50 ? 0 : 18,
//                            baseWidth: 24,
//                            triangleCenterX: 10 + 1.5*UIScreen.main.bounds.width / (390/85)
//                        )
//                        .frame(
//                            width: geometry.size.width,
//                            height: geometry.size.height
//                                   - 3*(UIScreen.main.bounds.width/(390/85)
//                                   + UIScreen.main.bounds.height/(844/40) * icon_scaler),
//                            alignment: .top
//                        )
//                    }
//                )
//                .allowsHitTesting(false)
//                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: -4)
//        }
//        .clipped()
//        .offset(y: folder_offset)
//    }
//
//    private func loadWallpaperOnce() {
//        guard userDefaults.bool(forKey: "Camera_Wallpaper_Home") == true else { return }
//        if let data = userDefaults.data(forKey: "Home_Wallpaper"),
//           let ui = UIImage(data: data, scale: UIScreen.main.scale)?
//                .preparingForDisplay() {
//            cachedWallpaper = ui
//        } else {
//            cachedWallpaper = UIImage(named: "Wallpaper_1")?.preparingForDisplay()
//        }
//    }
//}
//
//
//struct NoButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//    }
//}
//extension View {
//    func delayTouches() -> some View {
//        Button(action: {}) {
//            highPriorityGesture(TapGesture())
//        }
//        .buttonStyle(NoButtonStyle())
//    }
//}
//
//struct app_search_id_ext: Identifiable {
//    let id = UUID()
//    var name: String
//}
//struct search: View {
//    var apps = [app_search_id_ext(name:"Messages"), app_search_id_ext(name:"Calendar"), app_search_id_ext(name:"Photos"), app_search_id_ext(name:"Camera"), app_search_id_ext(name:"YouTube"), app_search_id_ext(name:"Stocks"), app_search_id_ext(name:"Maps"), app_search_id_ext(name:"Weather"), app_search_id_ext(name:"Notes"), app_search_id_ext(name:"iTunes"), app_search_id_ext(name:"App Store"),  app_search_id_ext(name:"Game Center"), app_search_id_ext(name:"Settings"), app_search_id_ext(name:"Phone"), app_search_id_ext(name:"Mail"), app_search_id_ext(name:"Safari" ), app_search_id_ext(name:"iPod" ), app_search_id_ext(name:"Contacts")]
//    @Binding var width: CGFloat
//    @Binding var height: CGFloat
//    @State var search = ""
//    @State var place_holder = ""
//    @Binding var show_searchField: Bool
//    @Binding var apps_scale: CGFloat
//    @Binding var current_view: String
//    @Binding var dock_offset: CGFloat
//    private let gradient = LinearGradient([.white, .white], to: .trailing)
//    var body: some View {
//        ZStack {
//            VStack {
//                
//                HStack {
//                    Spacer(minLength: 5)
//                    HStack (alignment: .center,
//                            spacing: 10) {
//                        Image(systemName: "magnifyingglass").resizable().font(Font.title.weight(.medium)).frame(width: 15, height: 15).padding(.leading, 5)
//                            .foregroundColor(.gray)
//                        
//                        TextField ("Search iPhone", text: $search)
//                        
//                    }
//                    
//                    .padding([.top,.bottom], 5)
//                    .padding(.leading, 5)
//                    .cornerRadius(40)
//                    Spacer(minLength: 20)
//                } .ps_innerShadow(.capsule(gradient), radius:2).padding([.leading, .trailing])
//                Spacer().frame(height: 10)
//                search_results_view(apps: apps, search: $search, apps_scale: $apps_scale, current_view: $current_view, dock_offset: $dock_offset).padding([.leading, .trailing]).cornerRadius(12)
//            }
//        }.frame(width:width, height: height)
//    }
//}
//
//struct search_results_view: View {
//    var apps: [app_search_id_ext]
//    @Binding var search: String
//    @Binding var apps_scale: CGFloat
//    @Binding var current_view: String
//    @Binding var dock_offset: CGFloat
//    var body: some View {
//        GeometryReader { geometry in
//            VStack(spacing:0) {
//                ScrollView(showsIndicators: true) {
//                    VStack(spacing: 0)  {
//                        ForEach(apps.filter{$0.name.localizedCaseInsensitiveContains(search)}.sorted(by: {$0.name > $1.name}), id:\.id) { application in
//                            search_result_item(apps: apps, search: $search, apps_scale: $apps_scale, current_view: $current_view, dock_offset: $dock_offset, application: application)
//                            
//                        }
//                    }
//                }.frame(height: geometry.size.height - 40).background(Color(red: 228/255, green: 229/255, blue: 230/255)).cornerRadius(12)
//            }
//        }.onAppear() {
//            //UIScrollView.appearance().bounces = true -> There's something weird going on where we can't readily modify the bounce value of our scrollviews in the TabView. Therefore, our app pages bounce, when they shouldn't. For now, we'll compromise and have the search not bounce, instead of the apps bouncing.
//        }.onDisappear() {
//            UIScrollView.appearance().bounces = false
//        }
//    }
//}
//
//struct search_result_item: View {
//    var apps: [app_search_id_ext]
//    @Binding var search: String
//    @Binding var apps_scale: CGFloat
//    @Binding var current_view: String
//    @Binding var dock_offset: CGFloat
//    var application: app_search_id_ext
//    var body: some View {
//        Button(action:{
//            
//            withAnimation(.linear(duration: 0.32)) {
//                apps_scale = 4
//                dock_offset = 100
//            }
//            DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
//                withAnimation(.linear(duration: 0.32)) {
//                    current_view = application.name
//                }
//            }
//        }) {
//            VStack(spacing: 0) {
//                HStack {
//                    Image(application.name == "Weather" ? "Weather Fahrenheit" : application.name).resizable().scaledToFit().frame(width: 35, height: 35).padding(.leading, 5)
//                    Rectangle().fill(Color(red: 250/255, green: 250/255, blue: 250/255)).frame(width: 1, height: 48).offset(x: -2)
//                    Text(application.name).font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.black).offset(x: -2)
//                    Spacer()
//                }.frame(height: 48)
//                Rectangle().fill((apps.filter({ search.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(search) }).sorted(by: {$0.name > $1.name}).firstIndex(where: {$0.name == application.name}) ?? 0) % 2  == 0 ? Color(red: 182/255, green: 183/255, blue: 184/255) : Color(red: 182/255, green: 183/255, blue: 184/255)).frame(height:1)
//                Rectangle().fill((apps.filter({ search.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(search) }).sorted(by: {$0.name > $1.name}).firstIndex(where: {$0.name == application.name}) ?? 0) % 2  == 0 ? Color(red: 250/255, green: 250/255, blue: 250/255) : Color(red: 250/255, green: 250/255, blue: 250/255)).frame(height:1)
//            }.frame(height: 50).background((apps.filter({ search.isEmpty ? true : $0.name.localizedCaseInsensitiveContains(search) }).sorted(by: {$0.name > $1.name}).firstIndex(where: {$0.name == application.name}) ?? 0) % 2  == 0 ? Color(red: 228/255, green: 229/255, blue: 230/255) : Color(red: 208/255, green: 209/255, blue: 213/255))
//        }.frame(height: 50)
//    }
//}
//
//
////
//////Our app pages are built on a LazyVGrid. This should be beneficial in the future...wink wink.
////struct apps: View {
////    @Binding var apps_scale: CGFloat
////    @Binding var apps_scale_height: CGFloat
////    @Binding var show_searchField:Bool
////    @Binding var icon_scaler: CGFloat
////    @Binding var current_view: String
////    @Binding var dock_offset: CGFloat
////    @Binding var folder_offset: CGFloat
////    @Binding var show_folder: Bool
////    var width: CGFloat
////    var height: CGFloat
////
////    var userDefaults = UserDefaults.standard
////
////    var body: some View {
////        VStack {
////            LazyVGrid(columns: [
////                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
////                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
////                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
////                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1)
////            ], spacing: UIScreen.main.bounds.height / (844 / 40) * icon_scaler) {
////                app(image_name: "Messages", app_name: "Messages", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
////                app_calendar(image_name: "Calendar", app_name: "Calendar", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
////                app(image_name: "Photos", app_name: "Photos", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
////                app(image_name: "Camera", app_name: "Camera", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
////                app(image_name: "YouTube", app_name: "YouTube", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
////                app(image_name: "Stocks", app_name: "Stocks", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
////                app(image_name: "Maps", app_name: "Maps", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
////                app(image_name: "Weather Fahrenheit", app_name: "Weather", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
////                app(image_name: "Notes", app_name: "Notes", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
////                folder(image_name: "Utilities", folder_name: "Utilities", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset, show_folder: $show_folder)
////                app(image_name: "iTunes", app_name: "iTunes", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
////                app(image_name: "App Store", app_name: "App Store", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
////                app(image_name: "Game Center", app_name: "Game Center", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset).offset(y: folder_offset > 50 ? folder_offset / (folder_offset - folder_offset * (folder_offset - 19) / (folder_offset - 18)) : folder_offset)
////                app(image_name: "Settings", app_name: "Settings", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset).offset(y: folder_offset > 50 ? folder_offset / (folder_offset - folder_offset * (folder_offset - 19) / (folder_offset - 18)) : folder_offset)
////            }
////            Spacer()
////        }.onAppear() {
////            UIApplication.shared.endEditing()
////        }//.offset(y:-15)
////    }
////}
//
//// ═══════════════════════════════════════════════════════════════════════
//// HOW TO APPLY:
////   1. Delete IOS6AnimationState, IOS6Quadrant, IOS6FlyInModifier,
////      RowHeightKey — everything from the previous two attempts.
////   2. Replace `struct apps` with the one below.
////   3. Replace `struct app` with the one below.
////   4. Replace `struct app_calendar` with the one below.
////   5. Replace `struct folder` with the one below.
////
//// WHAT CHANGED AND WHY:
////   The LazyVGrid is kept EXACTLY as the original — it handles all layout.
////   The only new thing: each icon receives a `quadrantOffset: CGPoint`
////   parameter (defaults to .zero so every other call site is unaffected —
////   dock, folder interior, multitasking switcher, search results, all
////   untouched).
////   `apps` owns a single @State animatedIn. It computes four CGPoints
////   (one per quadrant) and passes them down. When animatedIn flips inside
////   a withAnimation, SwiftUI re-renders every icon in the same transaction.
////   One state, one animation call, perfect lockstep. No per-icon state.
//// ═══════════════════════════════════════════════════════════════════════
//
//
//// Allows app icons to move beyond their individual TabView page while
//// preserving clipping at HomeScreen's full simulated-phone boundary.
//private struct PagingContainerOverflowBridge: UIViewRepresentable {
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView(frame: .zero)
//        view.isUserInteractionEnabled = false
//        configure(from: view)
//        return view
//    }
//
//    func updateUIView(_ uiView: UIView, context: Context) {
//        configure(from: uiView)
//    }
//
//    private func configure(from view: UIView) {
//        DispatchQueue.main.async {
//            var ancestor = view.superview
//            while let current = ancestor {
//                if let scrollView = current as? UIScrollView {
//                    scrollView.clipsToBounds = false
//                    return
//                }
//                ancestor = current.superview
//            }
//        }
//    }
//}
//
//private extension View {
//    func allowOverflowFromPagingContainer() -> some View {
//        background(PagingContainerOverflowBridge().frame(width: 0, height: 0))
//    }
//}
//
//// ─────────────────────────────────────────────────────────────────────
//// APPS — the only struct that knows about the animation
//// ─────────────────────────────────────────────────────────────────────
//struct apps: View {
//    @Binding var apps_scale: CGFloat
//    @Binding var apps_scale_height: CGFloat
//    @Binding var show_searchField: Bool
//    @Binding var icon_scaler: CGFloat
//    @Binding var current_view: String
//    @Binding var dock_offset: CGFloat
//    @Binding var folder_offset: CGFloat
//    @Binding var show_folder: Bool
//    @Binding var flyAnimatedIn: Bool                         // shared across every app page
//    var isActivePage: Bool
//    var width: CGFloat
//    var height: CGFloat
//
//    var userDefaults = UserDefaults.standard
//
//    // ── fly magnitudes ───────────────────────────────────────────────
//    private let flyX: CGFloat = UIScreen.main.bounds.width  * 0.6
//    private let flyY: CGFloat = UIScreen.main.bounds.height * 0.45
//
//    // ── the four offsets, computed from the single Bool ──────────────
//    private var tlOff: CGPoint { flyAnimatedIn ? .zero : CGPoint(x: -flyX, y: -flyY) }
//    private var trOff: CGPoint { flyAnimatedIn ? .zero : CGPoint(x:  flyX, y: -flyY) }
//    private var blOff: CGPoint { flyAnimatedIn ? .zero : CGPoint(x: -flyX, y:  flyY) }
//    private var brOff: CGPoint { flyAnimatedIn ? .zero : CGPoint(x:  flyX, y:  flyY) }
//
//    var body: some View {
//        VStack {
//            LazyVGrid(columns: [
//                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
//                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
//                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
//                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1)
//            ], spacing: UIScreen.main.bounds.height / (844 / 40) * icon_scaler) {
//
//                // ── Row 0 ──────────────────────────────────────────────
//                app(image_name: "Messages", app_name: "Messages",
//                    current_view: $current_view, apps_scale: $apps_scale,
//                    dock_offset: $dock_offset, folder_offset: $folder_offset,
//                    quadrantOffset: tlOff)
//
//                app_calendar(image_name: "Calendar", app_name: "Calendar",
//                             current_view: $current_view, apps_scale: $apps_scale,
//                             dock_offset: $dock_offset, folder_offset: $folder_offset,
//                             quadrantOffset: tlOff)
//
//                app(image_name: "Photos", app_name: "Photos",
//                    current_view: $current_view, apps_scale: $apps_scale,
//                    dock_offset: $dock_offset, folder_offset: $folder_offset,
//                    quadrantOffset: trOff)
//
//                app(image_name: "Camera", app_name: "Camera",
//                    current_view: $current_view, apps_scale: $apps_scale,
//                    dock_offset: $dock_offset, folder_offset: $folder_offset,
//                    quadrantOffset: trOff)
//
//                // ── Row 1 ──────────────────────────────────────────────
//                app(image_name: "YouTube", app_name: "YouTube",
//                    current_view: $current_view, apps_scale: $apps_scale,
//                    dock_offset: $dock_offset, folder_offset: $folder_offset,
//                    quadrantOffset: tlOff)
//
//                app(image_name: "Stocks", app_name: "Stocks",
//                    current_view: $current_view, apps_scale: $apps_scale,
//                    dock_offset: $dock_offset, folder_offset: $folder_offset,
//                    quadrantOffset: tlOff)
//
//                app(image_name: "Maps", app_name: "Maps",
//                    current_view: $current_view, apps_scale: $apps_scale,
//                    dock_offset: $dock_offset, folder_offset: $folder_offset,
//                    quadrantOffset: trOff)
//
//                app(image_name: "Weather Fahrenheit", app_name: "Weather",
//                    current_view: $current_view, apps_scale: $apps_scale,
//                    dock_offset: $dock_offset, folder_offset: $folder_offset,
//                    quadrantOffset: trOff)
//
//                // ── Row 2 ──────────────────────────────────────────────
//                app(image_name: "Notes", app_name: "Notes",
//                    current_view: $current_view, apps_scale: $apps_scale,
//                    dock_offset: $dock_offset, folder_offset: $folder_offset,
//                    quadrantOffset: blOff)
//
//                folder(image_name: "Utilities", folder_name: "Utilities",
//                       current_view: $current_view, apps_scale: $apps_scale,
//                       dock_offset: $dock_offset, folder_offset: $folder_offset,
//                       show_folder: $show_folder,
//                       quadrantOffset: blOff)
//
//                app(image_name: "iTunes", app_name: "iTunes",
//                    current_view: $current_view, apps_scale: $apps_scale,
//                    dock_offset: $dock_offset, folder_offset: $folder_offset,
//                    quadrantOffset: brOff)
//
//                app(image_name: "App Store", app_name: "App Store",
//                    current_view: $current_view, apps_scale: $apps_scale,
//                    dock_offset: $dock_offset, folder_offset: $folder_offset,
//                    quadrantOffset: brOff)
//
//                // ── Row 3 ──────────────────────────────────────────────
//                app(image_name: "Game Center", app_name: "Game Center",
//                    current_view: $current_view, apps_scale: $apps_scale,
//                    dock_offset: $dock_offset, folder_offset: $folder_offset,
//                    quadrantOffset: blOff)
//                    .offset(y: folder_offset > 50 ? folder_offset / (folder_offset - folder_offset * (folder_offset - 19) / (folder_offset - 18)) : folder_offset)
//
//                app(image_name: "Settings", app_name: "Settings",
//                    current_view: $current_view, apps_scale: $apps_scale,
//                    dock_offset: $dock_offset, folder_offset: $folder_offset,
//                    quadrantOffset: blOff)
//                    .offset(y: folder_offset > 50 ? folder_offset / (folder_offset - folder_offset * (folder_offset - 19) / (folder_offset - 18)) : folder_offset)
//            }
//            Spacer()
//        }
//        // Disabling the paging scroll view's clipping exposes adjacent pages.
//        // Keep only the selected page visible until the fly transition completes.
//        .opacity(isActivePage || apps_scale <= 1.001 ? 1 : 0)
//        .allowOverflowFromPagingContainer()
//        .onAppear() {
//            UIApplication.shared.endEditing()
//        }
//    }
//}
//
//
//
//// ─────────────────────────────────────────────────────────────────────
//// APP — only change from original: added quadrantOffset param (default
//// .zero) and one .offset call at the very end of the button chain.
//// ─────────────────────────────────────────────────────────────────────
//struct app: View {
//    var image_name: String
//    var app_name: String
//    @State var pressed = false
//    @Binding var current_view: String
//    @Binding var apps_scale: CGFloat
//    @Binding var dock_offset: CGFloat
//    @Binding var folder_offset: CGFloat
//    var is_folder_app: Bool = false
//    var quadrantOffset: CGPoint = .zero                     // ← NEW (default .zero = no effect)
//
//    var body: some View {
//        Button(action: {
//            if !["Clock", "Calculator"].contains(app_name) {
//                if !is_folder_app {
//                    withAnimation(.linear(duration: 0.32)) {
//                        apps_scale = 4
//                        dock_offset = 100
//                    }
//                }
//                DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
//                    withAnimation(.linear(duration: 0.32)) {
//                        current_view = app_name
//                    }
//                }
//            }
//        }) {
//            VStack {
//                ZStack {
//                    if pressed {
//                        Rectangle().fill(Color.gray).frame(width: UIScreen.main.bounds.width/(390/60), height: UIScreen.main.bounds.width/(390/60)).cornerRadius(14)
//                    }
//                    Image(image_name).resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
//                }
//                Text(app_name).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 13)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).offset(y: -4)
//            }
//        }.background(returnedBK(for: app_name != "Phone" && app_name != "Mail" && app_name != "Safari" && app_name != "iPod" ? true : false)).compositingGroup().grayscale((folder_offset > 0 && !is_folder_app) ? 0.99 : 0).opacity((folder_offset > 0 && !is_folder_app) ? 0.3 : 1)
//         .offset(x: quadrantOffset.x, y: quadrantOffset.y)  // ← NEW
//    }
//    private func returnedBK(for app: Bool) -> some View {
//        if app {
//            return AnyView(Image("WallpaperIconShadow").resizable().scaledToFit().frame(width:UIScreen.main.bounds.width/(390/104)).offset(y:6))
//        } else {
//            return AnyView(EmptyView())
//        }
//    }
//}
//
//
//// ─────────────────────────────────────────────────────────────────────
//// APP_CALENDAR — only change: added quadrantOffset param and .offset call
//// ─────────────────────────────────────────────────────────────────────
//struct app_calendar: View {
//    var image_name: String
//    var app_name: String
//    @Binding var current_view: String
//    @Binding var apps_scale: CGFloat
//    @Binding var dock_offset: CGFloat
//    @Binding var folder_offset: CGFloat
//    var quadrantOffset: CGPoint = .zero                     // ← NEW
//    @State var date = Date()
//    var timeFormat: DateFormatter {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "d"
//        return formatter
//    }
//    var body: some View {
//        Button(action: {
//                withAnimation(.linear(duration: 0.32)) {
//                    apps_scale = 4
//                    dock_offset = 100
//                }
//                DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
//                    withAnimation(.linear(duration: 0.32)) {
//                        current_view = app_name
//                    }
//                }}) {
//            VStack {
//                ZStack {
//                    Image(image_name).resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
//                    VStack {
//                        Text(getDayOfWeek(date: date)).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 10)).padding(.top, 6).shadow(color: Color.black, radius: 0.2, x: 0, y: 0.75).offset(y: -4).frame(maxWidth: 54).lineLimit(0).minimumScaleFactor(0.8)
//                        Spacer()
//                    }
//                    HStack {
//                        Spacer()
//                        Text(timeString(date: date)).lineLimit(nil).foregroundColor(.black).font(.custom("Helvetica Neue Bold", fixedSize: 35)).multilineTextAlignment(.center).padding(.top, 10).frame(alignment:.center)
//                        Spacer()
//                    }
//                }
//                Text(app_name).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 13)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).offset(y: -4)
//            }
//        }.background(Image("WallpaperIconShadow").resizable().scaledToFit().frame(width:UIScreen.main.bounds.width/(390/104)).offset(y:6)).compositingGroup().grayscale(folder_offset > 0 ? 0.99 : 0).opacity(folder_offset > 0 ? 0.3 : 1)
//         .offset(x: quadrantOffset.x, y: quadrantOffset.y)  // ← NEW
//    }
//    func timeString(date: Date) -> String {
//        let time = timeFormat.string(from: date)
//        return time
//    }
//    func getDayOfWeek(date:Date) -> String {
//        let index = Calendar.current.component(.weekday, from: date)
//        return Calendar.current.weekdaySymbols[index - 1]
//    }
//}
//
//
//// ─────────────────────────────────────────────────────────────────────
//// FOLDER — only change: added quadrantOffset param and .offset call
//// ─────────────────────────────────────────────────────────────────────
//struct folder: View {
//    var image_name: String
//    var folder_name: String
//    @State var pressed = false
//    @Binding var current_view: String
//    @Binding var apps_scale: CGFloat
//    @Binding var dock_offset: CGFloat
//    @Binding var folder_offset: CGFloat
//    @Binding var show_folder: Bool
//    var quadrantOffset: CGPoint = .zero                     // ← NEW
//    var body: some View {
//        Button(action: {
//            DispatchQueue.main.asyncAfter(deadline:.now() + 0.01) {
//                if folder_offset == 150 {
//                    withAnimation(.linear(duration: 0.32)) {
//                        folder_offset = 0
//                    }
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
//                        show_folder = false
//                    }
//                } else {
//                    show_folder = true
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
//                        withAnimation(.linear(duration: 0.32)) {
//                            folder_offset = 150
//                        }
//                    }
//                }
//            }
//        }) {
//            VStack {
//                ZStack {
//                    if pressed {
//                        Rectangle().fill(Color.gray).frame(width: UIScreen.main.bounds.width/(390/60), height: UIScreen.main.bounds.width/(390/60)).cornerRadius(14)
//                    }
//                    Image("Folder").resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
//                    VStack(alignment: .center) {
//                        // Do not use a LazyVGrid here. When the home screen returns,
//                        // the folder starts off-screen, so a lazy container can defer
//                        // creating these preview icons until the fly-in is almost over.
//                        // Keeping the exact folder open/close behavior untouched, this
//                        // eager layout makes all four previews exist before the parent
//                        // folder's quadrantOffset animation begins.
//                        VStack(alignment: .leading, spacing: UIScreen.main.bounds.width/(390/60) / (844/40)) {
//                            HStack(spacing: UIScreen.main.bounds.width/(390/60) / (844/40)) {
//                                app_folder(image_name: "Clock-Small", app_name: "Clock", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
//                                    .frame(width: UIScreen.main.bounds.width / (390/85*6.5))
//                                app_folder(image_name: "Calculator-Small", app_name: "Calculator", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
//                                    .frame(width: UIScreen.main.bounds.width / (390/85*6.5))
//                                app_folder(image_name: "Compass-Small", app_name: "Compass", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
//                                    .frame(width: UIScreen.main.bounds.width / (390/85*6.5))
//                            }
//                            HStack(spacing: UIScreen.main.bounds.width/(390/60) / (844/40)) {
//                                app_folder(image_name: "Voice Memos-Small", app_name: "Voice Memos", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
//                                    .frame(width: UIScreen.main.bounds.width / (390/85*6.5))
//                            }
//                        }.frame(width: UIScreen.main.bounds.width/(390/60), alignment: .center).padding([.top], UIScreen.main.bounds.width/(390/60) / (844/40)*2.65).padding(.leading, UIScreen.main.bounds.width/(390/60) / (844/40*100))
//                        Spacer()
//                    }
//                }
//                Text(folder_name).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 13)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).offset(y: -4)
//            }
//        }.background(returnedBK(for: true)).compositingGroup()
//         .offset(x: quadrantOffset.x, y: quadrantOffset.y)  // ← NEW
//    }
//    private func returnedBK(for app: Bool) -> some View {
//        if app {
//            return AnyView(Image("WallpaperIconShadow").resizable().scaledToFit().frame(width:UIScreen.main.bounds.width/(390/104)).offset(y:6))
//        } else {
//            return AnyView(EmptyView())
//        }
//    }
//}
//
//struct folder_apps: View {
//    @Binding var apps_scale: CGFloat
//    @Binding var apps_scale_height: CGFloat
//    @Binding var icon_scaler: CGFloat
//    @Binding var current_view: String
//    @Binding var dock_offset: CGFloat
//    @Binding var folder_offset: CGFloat
//    @Binding var show_folder: Bool
//    
//    var userDefaults = UserDefaults.standard
//    
//    var body: some View {
//            LazyVGrid(columns: [
//                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
//                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
//                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
//                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1)
//            ], spacing: UIScreen.main.bounds.height / (844 / 40) * icon_scaler) {
//                app(image_name: "Clock", app_name: "Clock", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset, is_folder_app: true)
//                app(image_name: "Calculator", app_name: "Calculator", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset, is_folder_app: true)
//                app(image_name: "Compass", app_name: "Compass", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset, is_folder_app: true)
//                app(image_name: "Voice Memos", app_name: "Voice Memos", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset, is_folder_app: true)
//            }.onAppear() {
//            UIApplication.shared.endEditing()
//        }//.offset(y:-15)
//    }
//}
//
//@inline(__always)
//private func equilateralHalfBase(forHeight h: CGFloat) -> CGFloat {
//    h / CGFloat(sqrt(3))
//}
//
//struct FolderIsoscelesMask: Shape {
//    var triangleHeight: CGFloat = 22
//    var baseWidth: CGFloat = 22
//    var triangleCenterX: CGFloat = 0
//
//    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
//        get { .init(triangleHeight, .init(baseWidth, triangleCenterX)) }
//        set { triangleHeight = newValue.first
//              baseWidth = newValue.second.first
//              triangleCenterX = newValue.second.second }
//    }
//
//    func path(in rect: CGRect) -> Path {
//        var p = Path()
//        let h = max(0, min(triangleHeight, rect.height))
//        let halfBase = max(0, baseWidth / 2)
//        let cx = triangleCenterX
//
//        p.move(to: CGPoint(x: cx, y: 0))                // apex
//        p.addLine(to: CGPoint(x: cx + halfBase, y: h))  // base right
//        p.addLine(to: CGPoint(x: cx - halfBase, y: h))  // base left
//        p.closeSubpath()
//
//        p.addRect(CGRect(x: 0, y: h, width: rect.width, height: rect.height - h))
//        return p
//    }
//}
//
//struct FolderIsoscelesTopBottomBorder: Shape {
//    var triangleHeight: CGFloat = 22
//    var baseWidth: CGFloat = 22
//    var triangleCenterX: CGFloat = 0
//    var lineWidth: CGFloat = 2
//
//    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
//        get { .init(triangleHeight, .init(baseWidth, triangleCenterX)) }
//        set { triangleHeight = newValue.first
//              baseWidth = newValue.second.first
//              triangleCenterX = newValue.second.second }
//    }
//
//    func path(in rect: CGRect) -> Path {
//        var p = Path()
//        let h = max(0, min(triangleHeight, rect.height))
//        let halfBase = max(0, baseWidth / 2)
//        let cx = triangleCenterX
//
//        let oddAdjust: CGFloat = (Int(lineWidth) % 2 == 1) ? 0.5 : 0.0
//        let topY    = h + oddAdjust
//        let bottomY = rect.maxY - oddAdjust
//
//        let leftBase  = CGPoint(x: cx - halfBase, y: topY)
//        let rightBase = CGPoint(x: cx + halfBase, y: topY)
//        let apex      = CGPoint(x: cx,            y: 0 + oddAdjust)
//
//        if leftBase.x > 0 {
//            p.move(to: CGPoint(x: 0, y: topY))
//            p.addLine(to: leftBase)
//        }
//
//        p.move(to: leftBase)
//        p.addLine(to: apex)
//        p.addLine(to: rightBase)
//
//        if rightBase.x < rect.maxX {
//            p.move(to: rightBase)
//            p.addLine(to: CGPoint(x: rect.maxX, y: topY))
//        }
//
//        p.move(to: CGPoint(x: 0, y: bottomY))
//        p.addLine(to: CGPoint(x: rect.maxX, y: bottomY))
//
//        return p
//    }
//}
//
//
//extension View {
//    func folderInnerShadow<S: Shape>(
//        using shape: S,
//        color: Color = .black,
//        lineWidth: CGFloat = 4,
//        blur: CGFloat = 6,
//        offset: CGPoint = .init(x: 0, y: 2)
//    ) -> some View {
//        self
//            .overlay(
//                shape
//                    .stroke(color, lineWidth: lineWidth)
//                    .offset(x: offset.x, y: offset.y)
//                    .blur(radius: blur)
//                    .mask(shape)
//            )
//    }
//}
//
//
//
//struct apps_second: View {
//    @Binding var apps_scale: CGFloat
//    @Binding var apps_scale_height: CGFloat
//    @Binding var show_searchField:Bool
//    @Binding var icon_scaler: CGFloat
//    @Binding var current_view: String
//    @Binding var dock_offset: CGFloat
//    @Binding var folder_offset: CGFloat
//    @Binding var flyAnimatedIn: Bool
//    var isActivePage: Bool
//    var width: CGFloat
//    var height: CGFloat
//
//    private let flyX: CGFloat = UIScreen.main.bounds.width * 0.6
//    private let flyY: CGFloat = UIScreen.main.bounds.height * 0.45
//    private var tlOff: CGPoint {
//        flyAnimatedIn ? .zero : CGPoint(x: -flyX, y: -flyY)
//    }
//    
//    var body: some View {
//        VStack {
//            LazyVGrid(columns: [
//                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
//                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
//                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
//                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1)
//            ], alignment: .center, spacing: UIScreen.main.bounds.height/(844/40)*icon_scaler) {
//                app(image_name: "Contacts", app_name: "Contacts", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset, quadrantOffset: tlOff)
//                
//            }
//            Spacer().frame(height:UIScreen.main.bounds.height/(844/40)*icon_scaler)
//            Spacer()
//        }
//        .opacity(isActivePage || apps_scale <= 1.001 ? 1 : 0)
//        .allowOverflowFromPagingContainer()
//        .onAppear() {
//            UIApplication.shared.endEditing()
//        }
//    }
//}
//
//struct multitasking_app: View {
//    var image_name: String
//    var app_name: String
//    @State var pressed = false
//    @State var date = Date()
//    @Binding var current_view: String
//    @Binding var apps_scale: CGFloat
//    @Binding var dock_offset: CGFloat
//    @Binding var show_remove: Bool
//    @Binding var should_update: Bool
//    @Binding var apps: [String]
//    @Binding var apps_main_array: [String]
//    var timeFormat: DateFormatter {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "d"
//        return formatter
//    }
//    var body: some View {
//        if app_name == "Calendar" {
//            Button(action: {
//                    if !should_update {
//                        withAnimation(.linear(duration: 0.32)) {
//                            apps_scale = 4
//                            dock_offset = 100
//                        }
//                        DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
//                            withAnimation(.linear(duration: 0.32)) {
//                                current_view = app_name
//                            }
//                        }}}) {
//                VStack {
//                    ZStack {
//                        Image(image_name).resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
//                        VStack {
//                            Text(getDayOfWeek(date: date)).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 10)).padding(.top, 6).shadow(color: Color.black, radius: 0.2, x: 0, y: 0.75).offset(y: -4).frame(maxWidth: 54).lineLimit(0).minimumScaleFactor(0.8)
//                            Spacer()
//                        }
//                        HStack {
//                            Spacer()
//                            Text(timeString(date: date)).lineLimit(nil).foregroundColor(.black).font(.custom("Helvetica Neue Bold", fixedSize: 35)).multilineTextAlignment(.center).padding(.top, 10).frame(alignment:.center)
//                            Spacer()
//                        }
//                        VStack {
//                            HStack {
//                                Button(action:{
//                                    withAnimation {
//                                    if show_remove {
//                                        if let index = apps.firstIndex(where: {$0 == app_name}) {
//                                                apps.remove(at: index)
//                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
//                                            if let index2 = apps_main_array.firstIndex(where: {$0 == app_name}) {
//                                                apps_main_array.remove(at: index2)
//                                            }
//                                            }
//                                            }
//                                        }
//                                    }
//                                }) {
//                                Image("SwitcherQuitBox").offset(x: 0, y: -10)
//                                }
//                                Spacer()
//                            }
//                            Spacer()
//                        }.opacity(show_remove ? 1 : 0).animationsDisabled()
//                    }
//                    Text(app_name).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 13)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).offset(y: -4)
//                }.onTapGesture {
//                    if !should_update {
//                        withAnimation(.linear(duration: 0.32)) {
//                            apps_scale = 4
//                            dock_offset = 100
//                        }
//                        DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
//                            withAnimation(.linear(duration: 0.32)) {
//                                current_view = app_name
//                            }
//                        }
//                    }
//                }
//                .onLongPressGesture() {
//                    if !should_update, !show_remove {
//                    should_update = true
//                    show_remove = true
//                    }
//                }
//            }
//        } else {
//            Button(action: {
//                    if !should_update {
//                        withAnimation(.linear(duration: 0.32)) {
//                            apps_scale = 4
//                            dock_offset = 100
//                        }
//                        DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
//                            withAnimation(.linear(duration: 0.32)) {
//                                current_view = app_name
//                            }
//                        }}}) {
//                VStack {
//                    ZStack {
//                        if pressed {
//                            Rectangle().fill(Color.gray).frame(width: UIScreen.main.bounds.width/(390/60), height: UIScreen.main.bounds.width/(390/60)).cornerRadius(14)
//                        }
//                        Image(image_name).resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
//                        //  if wiggle {
//                 
//                        VStack {
//                            HStack {
//                                Button(action:{
//                                    withAnimation {
//                                    if show_remove {
//                                        if let index = apps.firstIndex(where: {$0 == app_name}) {
//                                                apps.remove(at: index)
//                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
//                                            if let index2 = apps_main_array.firstIndex(where: {$0 == app_name}) {
//                                                apps_main_array.remove(at: index2)
//                                            }
//                                            }
//                                            }
//                                        }
//                                    }
//                                }) {
//                                Image("SwitcherQuitBox").offset(x: 0, y: -10)
//                                }
//                                Spacer()
//                            }
//                            Spacer()
//                        }.opacity(show_remove ? 1 : 0).animationsDisabled()
//                        // }
//                    }
//                    Text(app_name).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 13)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).offset(y: -4)
//                }.onTapGesture {
//                    if !should_update {
//                        withAnimation(.linear(duration: 0.32)) {
//                            apps_scale = 4
//                            dock_offset = 100
//                        }
//                        DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
//                            withAnimation(.linear(duration: 0.32)) {
//                                current_view = app_name
//                            }
//                        }
//                    }
//                }
//                .onLongPressGesture() {
//                    if !should_update, !show_remove {
//                    should_update = true
//                    show_remove = true
//                    }
//                }
//            }
//        }
//    }
//    func timeString(date: Date) -> String {
//        let time = timeFormat.string(from: date)
//        return time
//    }
//    func getDayOfWeek(date:Date) -> String {
//        let index = Calendar.current.component(.weekday, from: date)
//        return Calendar.current.weekdaySymbols[index - 1]
//    }
//}
////
////struct folder: View {
////    var image_name: String
////    var folder_name: String
////    @State var pressed = false
////    @Binding var current_view: String
////    @Binding var apps_scale: CGFloat
////    @Binding var dock_offset: CGFloat
////    @Binding var folder_offset: CGFloat
////    @Binding var show_folder: Bool
////    var body: some View {
////        Button(action: {
////            DispatchQueue.main.asyncAfter(deadline:.now() + 0.01) {
////                if folder_offset == 150 {
////                    withAnimation(.linear(duration: 0.32)) {
////                        folder_offset = 0
////                    }
////                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
////                        show_folder = false
////                    }
////                } else {
////                    show_folder = true
////                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
////                        withAnimation(.linear(duration: 0.32)) {
////                            folder_offset = 150
////                        }
////                    }
////                }
////            }
////        }) {
////            VStack {
////                ZStack {
////                    if pressed {
////                        Rectangle().fill(Color.gray).frame(width: UIScreen.main.bounds.width/(390/60), height: UIScreen.main.bounds.width/(390/60)).cornerRadius(14)
////                    }
////                    Image("Folder").resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
////                    VStack(alignment: .center) {
////                        LazyVGrid(columns: [
////                            GridItem(.fixed(UIScreen.main.bounds.width / (390/85*6.5)), spacing: UIScreen.main.bounds.width/(390/60) / (844/40)),
////                            GridItem(.fixed(UIScreen.main.bounds.width / (390/85*6.5)), spacing: UIScreen.main.bounds.width/(390/60) / (844/40)),
////                            GridItem(.fixed(UIScreen.main.bounds.width / (390/85*6.5)), spacing: UIScreen.main.bounds.width/(390/60) / (844/40))
////                        ], spacing: UIScreen.main.bounds.width/(390/60) / (844/40)) {
////                            app_folder(image_name: "Clock-Small", app_name: "Clock", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
////                            app_folder(image_name: "Calculator-Small", app_name: "Calculator", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
////                            app_folder(image_name: "Compass-Small", app_name: "Compass", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
////                            app_folder(image_name: "Voice Memos-Small", app_name: "Voice Memos", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
////                        }.frame(width: UIScreen.main.bounds.width/(390/60)).padding([.top], UIScreen.main.bounds.width/(390/60) / (844/40)*2.65).padding(.leading, UIScreen.main.bounds.width/(390/60) / (844/40*100))
////                        Spacer()
////                    }
////                }
////                Text(folder_name).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 13)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).offset(y: -4)
////            }
////        }.background(returnedBK(for: true))
////    }
////    private func returnedBK(for app: Bool) -> some View {
////        if app {
////            return AnyView(Image("WallpaperIconShadow").resizable().scaledToFit().frame(width:UIScreen.main.bounds.width/(390/104)).offset(y:6))
////        } else {
////            return AnyView(EmptyView())
////        }
////    }
////}
//
////
////struct app: View {
////    var image_name: String
////    var app_name: String
////    @State var pressed = false
////    @Binding var current_view: String
////    @Binding var apps_scale: CGFloat
////    @Binding var dock_offset: CGFloat
////    @Binding var folder_offset: CGFloat
////    var is_folder_app: Bool = false
////
////    var body: some View {
////        Button(action: {
////            if !["Clock", "Calculator"].contains(app_name) {
////                if !is_folder_app {
////                    withAnimation(.linear(duration: 0.32)) {
////                        apps_scale = 4
////                        dock_offset = 100
////                    }
////                }
////                DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
////                    withAnimation(.linear(duration: 0.32)) {
////                        current_view = app_name
////                    }
////                }
////            }
////        }) {
////            VStack {
////                ZStack {
////                    if pressed {
////                        Rectangle().fill(Color.gray).frame(width: UIScreen.main.bounds.width/(390/60), height: UIScreen.main.bounds.width/(390/60)).cornerRadius(14)
////                    }
////                    Image(image_name).resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
////                }
////                Text(app_name).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 13)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).offset(y: -4)
////            }
////        }.background(returnedBK(for: app_name != "Phone" && app_name != "Mail" && app_name != "Safari" && app_name != "iPod" ? true : false)).grayscale((folder_offset > 0 && !is_folder_app) ? 0.99 : 0).opacity((folder_offset > 0 && !is_folder_app) ? 0.3 : 1)
////    }
////    private func returnedBK(for app: Bool) -> some View {
////        if app {
////            return AnyView(Image("WallpaperIconShadow").resizable().scaledToFit().frame(width:UIScreen.main.bounds.width/(390/104)).offset(y:6))
////        } else {
////            return AnyView(EmptyView())
////        }
////    }
////}
////struct app_calendar: View {
////    var image_name: String
////    var app_name: String
////    @Binding var current_view: String
////    @Binding var apps_scale: CGFloat
////    @Binding var dock_offset: CGFloat
////    @Binding var folder_offset: CGFloat
////    @State var date = Date()
////    var timeFormat: DateFormatter {
////        let formatter = DateFormatter()
////        formatter.dateFormat = "d"
////        return formatter
////    }
////    var body: some View {
////        Button(action: {
////                withAnimation(.linear(duration: 0.32)) {
////                    apps_scale = 4
////                    dock_offset = 100
////                }
////                DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
////                    withAnimation(.linear(duration: 0.32)) {
////                        current_view = app_name
////                    }
////                }}) {
////            VStack {
////                ZStack {
////                    Image(image_name).resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
////                    VStack {
////                        Text(getDayOfWeek(date: date)).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 10)).padding(.top, 6).shadow(color: Color.black, radius: 0.2, x: 0, y: 0.75).offset(y: -4).frame(maxWidth: 54).lineLimit(0).minimumScaleFactor(0.8)
////                        Spacer()
////                    }
////                    HStack {
////                        Spacer()
////                        Text(timeString(date: date)).lineLimit(nil).foregroundColor(.black).font(.custom("Helvetica Neue Bold", fixedSize: 35)).multilineTextAlignment(.center).padding(.top, 10).frame(alignment:.center)
////                        Spacer()
////                    }
////                }
////                Text(app_name).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 13)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).offset(y: -4)
////            }
////        }.background(Image("WallpaperIconShadow").resizable().scaledToFit().frame(width:UIScreen.main.bounds.width/(390/104)).offset(y:6)).grayscale(folder_offset > 0 ? 0.99 : 0).opacity(folder_offset > 0 ? 0.3 : 1)
////    }
////    func timeString(date: Date) -> String {
////        let time = timeFormat.string(from: date)
////        return time
////    }
////    func getDayOfWeek(date:Date) -> String {
////        let index = Calendar.current.component(.weekday, from: date)
////        return Calendar.current.weekdaySymbols[index - 1]
////    }
////}
////
//struct app_folder: View {
//    var image_name: String
//    var app_name: String
//    @Binding var current_view: String
//    @Binding var apps_scale: CGFloat
//    @Binding var dock_offset: CGFloat
//    var body: some View {
//            VStack {
//                ZStack {
//                    Image(image_name).resizable().scaledToFit()
//                }
//            }
//        }
//}
//
//struct app_reflection: View {
//    var image_name: String
//    var app_name: String
//    var body: some View {
//        VStack {
//            Image(image_name).resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60), height: UIScreen.main.bounds.width/(390/65))
//        }
//    }
//}
//func configureNetworkMonitor(completion: @escaping (Bool)->()) {
//    let monitor = NWPathMonitor()
//    
//    monitor.pathUpdateHandler = { path in
//        
//        if path.status != .satisfied {
//            completion(false)
//        }
//        else if path.usesInterfaceType(.cellular) {
//            completion(false)
//        }
//        else if path.usesInterfaceType(.wifi) {
//            completion(true)
//        }
//        else if path.usesInterfaceType(.wiredEthernet) {
//            completion(false)
//        }
//        else if path.usesInterfaceType(.other){
//            completion(false)
//        }else if path.usesInterfaceType(.loopback){
//            completion(false)
//        }
//    }
//    
//    monitor.start(queue: DispatchQueue.global(qos: .background))
//}
//
//struct status_bar: View {
//    @State var date = Date()
//    var locked = false
//    var timeFormat: DateFormatter {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "h:mm a"
//        return formatter
//    }
//    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
//    @State var battery_level = UIDevice.current.batteryLevel * 100
//    @State var carrier_id: String = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.first?.value.carrierName ?? ""
//    @State var charging: Bool = false
//    @State var wifi_connected : Bool = true
//    var body: some View {
//        ZStack {
//            Color.black.opacity(0.65)
//            HStack {
//                Text(carrier_id == "" ? "No SIM" : carrier_id == "--" ? "eSIM" : carrier_id).foregroundColor(Color.init(red: 200/255, green: 200/255, blue: 200/255)).font(.custom("Helvetica Neue Medium", fixedSize: 15)).onAppear() {
//                    let networkInfo = CTTelephonyNetworkInfo()
//                    let carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value
//                    
//                    // Get carrier name
//                    let carrierName = carrier?.carrierName
//                    carrier_id = carrierName ?? ""
//                }
//                Image(systemName: "wifi").foregroundColor(Color.init(red: 190/255, green: 190/255, blue: 190/255)).opacity(wifi_connected ? 1 : 0)
//                Spacer()
//                Text("\(Int(battery_level))%").isHidden(charging).foregroundColor(Color.init(red: 190/255, green: 190/255, blue: 190/255)).font(.custom("Helvetica Neue Medium", fixedSize: 15)).offset(x: 10)
//                battery(battery: Float(battery_level/100), charging: charging)
//                    .onReceive(timer) { input in
//                        if (UIDevice.current.batteryState != .unplugged) {
//                            battery_level = 100
//                            charging = true
//                        } else {
//                            battery_level = UIDevice.current.batteryLevel * 100
//                            charging = false
//                        }
//                        date = Date()
//                        if carrier_id == "" {
//                            let networkInfo = CTTelephonyNetworkInfo()
//                            let carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value
//                            
//                            // Get carrier name
//                            let carrierName = carrier?.carrierName
//                            carrier_id = carrierName ?? ""
//                        }
//                        configureNetworkMonitor(completion: {result in
//                            wifi_connected = result
//                        })
//                    }.offset(x: 5)
//                //Spacer()
//            }.padding([.leading, .trailing], 4)
//            HStack {
//                Spacer()
//                if locked {
//                    Image(systemName: "lock.fill").resizable().foregroundColor(Color.init(red: 190/255, green: 190/255, blue: 190/255)).frame(width: 10, height: 14)
//                } else {
//                    Text(timeString(date: date).uppercased()).foregroundColor(Color.init(red: 190/255, green: 190/255, blue: 190/255)).font(.custom("Helvetica Neue Medium", fixedSize: 15))
//                }
//                Spacer()
//            }
//        }.onAppear() {
//            print(CTTelephonyNetworkInfo().serviceSubscriberCellularProviders) //CTCarrier has been depricated. As a result, for now, we will say something generic like "ESIM". I'm optimistic that this change is largely due to iPhones replacing physical SIMS with ESIMS, hence the introduction of CTCellularPlanProperties with iOS 26, which could provide a gateway back into this.
//            if carrier_id == "" {
//                let networkInfo = CTTelephonyNetworkInfo()
//                let carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value
//                let carrierName = carrier?.carrierName
//                carrier_id = carrierName ?? ""
//                if carrier_id == "--" {
//                    carrier_id = "ESIM"
//                }
//            }
//            configureNetworkMonitor(completion: {result in
//                wifi_connected = result
//            })
//            UIDevice.current.isBatteryMonitoringEnabled = true
//            if (UIDevice.current.batteryState != .unplugged) {
//                battery_level = 100
//                charging = true
//            } else {
//                battery_level = UIDevice.current.batteryLevel * 100
//            }
//        }
//    }
//    func timeString(date: Date) -> String {
//        timeFormat.string(from: date)
//    }
//}
//
//struct dock2: View {
//    @Binding var current_view: String
//    @Binding var apps_scale: CGFloat
//    @Binding var dock_offset: CGFloat
//    @Binding var show_multitasking: Bool
//    @Binding var folder_offset: CGFloat
//    var columns: [GridItem] = [
//        GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
//        GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
//        GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
//        GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1)
//    ]
//    var body: some View {
//        ZStack {
//            VStack {
//                Spacer()//SB Dock avail
//                Image("SBDockBG 2").resizable().opacity(0.85).frame(height:UIScreen.main.bounds.height/(844/50))
//            }
//            VStack {
//                Spacer()
//                ZStack {
//                    LazyVGrid(columns: columns, alignment: .center, spacing: UIScreen.main.bounds.height/(844/40)) {
//                        app_reflection(image_name: "Phone", app_name: "Phone")
//                            .scaleEffect(x: 1, y: -1, anchor: .center)
//                            .opacity(0.25)
//                            .offset(y: 35)
//                            .clipped()
//                            .offset(y: 15)
//                        app_reflection(image_name: "Mail", app_name: "Mail")
//                            .scaleEffect(x: 1, y: -1, anchor: .center)
//                            .opacity(0.25)
//                            .offset(y: 35)
//                            .clipped()
//                            .offset(y: 15)
//                        app_reflection(image_name: "Safari", app_name: "Safari")
//                            .scaleEffect(x: 1, y: -1, anchor: .center)
//                            .opacity(0.25)
//                            .offset(y: 35)
//                            .clipped()
//                            .offset(y: 15)
//                        app_reflection(image_name: "iPod", app_name: "iPod")
//                            .scaleEffect(x: 1, y: -1, anchor: .center)
//                            .opacity(0.25)
//                            .offset(y: 35)
//                            .clipped()
//                            .offset(y: 15)
//                    }
//                    LazyVGrid(columns: columns, alignment: .center, spacing: UIScreen.main.bounds.height/(844/40)) {
//                        app(image_name: "Phone", app_name: "Phone", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
//                        app(image_name: "Mail", app_name: "Mail", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
//                        app(image_name: "Safari", app_name: "Safari", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
//                        app(image_name: "iPod", app_name: "iPod", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
//                    }.offset(y: 0) .compositingGroup() .drawingGroup()
//                }
//            }.grayscale(show_multitasking == true ? 0.99 : 0).opacity(show_multitasking == true ? 0.3 : 1)
//        }
//    }
//}
//struct battery: View {
//    var battery = Float()
//    var charging = Bool()
//    let rect = CGRect(x: 0, y: 0, width: 17, height: 6.5)
//    var body: some View {
//        HStack {
//            ZStack {
//                Rectangle().overlay(RoundedRectangle(cornerRadius:0.25).stroke(Color.init(red: 190/255, green: 190/255, blue: 190/255), lineWidth: 1.25)).foregroundColor(.clear).frame(width: 23.0, height: 12.25)
//                Rectangle().frame(width: 18.5*CGFloat(battery), height: 8).foregroundColor(battery <= 0.20 ? .red : Color.init(red: 190/255, green: 190/255, blue: 190/255)).offset(x:(-18.5/2)+(18.5/2)*CGFloat(battery)) .applyModifier(charging) {  AnyView($0.mask(ZStack {Image(systemName:"bolt.fill").resizable().frame(width: 8, height: 7)}.frame(width: 18.5*CGFloat(battery), height: 8).foregroundColor(.black).background(Color.white)                .compositingGroup().luminanceToAlpha()))
//                }
//            }
//            Rectangle().overlay(RoundedRectangle(cornerRadius:0.25).stroke(Color.init(red: 190/255, green: 190/255, blue: 190/255), lineWidth: 1)).foregroundColor(.clear).frame(width: 3, height: 5).offset(x:-7.95)
//        }
//    }
//}
//
//private struct IfButtonShapesEnabledModifier<S: View>: ViewModifier {
//    let style: (AnyView) -> S
//    @State private var enabled: Bool = {
//        if #available(iOS 15.0, *) { return UIAccessibility.buttonShapesEnabled }
//        return false
//    }()
//
//    func body(content: Content) -> some View {
//        let base = AnyView(content)
//        Group {
//            if enabled {
//                style(base)
//            } else {
//                base
//            }
//        }
//        .onReceive(NotificationCenter.default.publisher(
//            for: UIAccessibility.buttonShapesEnabledStatusDidChangeNotification
//        )) { _ in
//            if #available(iOS 15.0, *) {
//                enabled = UIAccessibility.buttonShapesEnabled
//            }
//        }
//    }
//}
//
//public extension View {
//    /// Apply a style only when the user has "Button Shapes" enabled (updates live).
//    func ifButtonShapesEnabledLive<S: View>(
//        _ style: @escaping (AnyView) -> S
//    ) -> some View {
//        modifier(IfButtonShapesEnabledModifier(style: style))
//    }
//}
//
//struct buttonShapesOverride: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//    }
//}
//
//struct Controller_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//            Controller()
//            Controller()
//                .previewDevice("iPhone 12 Pro Max")
//            Controller()
//                .previewDevice("iPhone 8 Plus")
//        }
//    }
//}
//extension View {
//    
//    func applyModifier(_ condition:Bool, apply:(AnyView) -> (AnyView)) -> AnyView {
//        if condition {
//            return apply(AnyView(self))
//        }
//        else {
//            return AnyView(self)
//        }
//    }
//    @ViewBuilder func isHidden(_ hidden: Bool, remove: Bool = false) -> some View {
//        if hidden {
//            if !remove {
//                self.hidden()
//            }
//        } else {
//            self
//        }
//    }
//}
//extension UIApplication {
//    func endEditing() {
//        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//    }
//    func startEditing() {
//        sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
//    }
//}
//
//
///// Wrapper view to detect force touch press states and report pressed changes.
///// This version is now universal and works for all devices.
//struct ForceTouchGestureView: UIViewRepresentable {
//    var onStateChange: (Bool) -> Void // (isPressedDown: Bool)
//    var minimumForce: CGFloat = 0.25
//
//    func makeUIView(context: Context) -> some UIView {
//        let view = TouchForwardingView()
//        view.onStateChange = onStateChange
//        view.minimumForce = minimumForce
//        view.isUserInteractionEnabled = true
//        view.backgroundColor = .clear
//        return view
//    }
//
//    func updateUIView(_ uiView: UIViewType, context: Context) {}
//}
//
//private class TouchForwardingView: UIView {
//    var onStateChange: ((Bool) -> Void)?
//    var minimumForce: CGFloat = 0.25
//    private var isPressed: Bool = false
//
//    // This method now handles both 3D Touch and standard devices
//    private func handleTouch(_ touch: UITouch?) {
//        guard let touch = touch else { return }
//        
//        // Check if the device supports Force Touch
//        let hasForceTouch = touch.maximumPossibleForce > 0
//        
//        let isNowPressed = hasForceTouch
//            ? (touch.force / touch.maximumPossibleForce > minimumForce) // 3D Touch logic
//            : true // Standard device: any touch-down is a "press"
//        
//        if self.isPressed != isNowPressed {
//            self.isPressed = isNowPressed
//            self.onStateChange?(self.isPressed)
//        }
//    }
//
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesBegan(touches, with: event)
//        handleTouch(touches.first)
//    }
//
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesMoved(touches, with: event)
//        handleTouch(touches.first)
//    }
//
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesEnded(touches, with: event)
//        if isPressed {
//            isPressed = false
//            onStateChange?(false)
//        }
//    }
//
//    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesCancelled(touches, with: event)
//        if isPressed {
//            isPressed = false
//            onStateChange?(false)
//        }
//    }
//}

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
import Combine

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
    
    @StateObject var oldOSKeyboard = OldOSKeyboardController()
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
    @State var folder_offset: CGFloat = 0
    @State var show_folder: Bool = false
    @EnvironmentObject var MusicObserver: MusicObserver
    @EnvironmentObject var EmailManager: EmailManager
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
                                HomeScreen(apps_scale: $apps_scale, apps_scale_height: $apps_scale_height, dock_offset: $dock_offset, selectedPage: $selected_page, search_width: $search_width, search_height:$search_height, current_view: $current_view, show_multitasking: $show_multitasking, instant_multitasking_change: $instant_multitasking_change, folder_offset: $folder_offset, show_folder: $show_folder).padding([.leading, .trailing]).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "HS") //.compositingGroup() -> maybe
                            case "Settings":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Settings")
                                Settings(show_multitasking: $instant_multitasking_change).equatable().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Settings").environmentObject(EmailManager)
                            case "iPod":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "iPod")
                                iPod().padding([.leading, .trailing]).transition(.scale).environmentObject(MusicObserver).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "iPod")
                            case "Safari":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Safari")
                                Safari(instant_multitasking_change: $instant_multitasking_change).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Safari")
                            case "Mail":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Mail")
                                Mail().padding([.leading, .trailing]).transition(.scale).environmentObject(EmailManager).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Mail")
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
                            case "Compass":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Compass")
                                Compass(current_view: $current_view).padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Compass")
                            case "Voice Memos":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Voice Memos")
                                VoiceMemos().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Voice Memos")
                            default:
                                LockScreen(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, apps_scale_height: $apps_scale_height).padding([.leading, .trailing])
                            }
                        }//.disabled(show_multitasking)
                    }
                    Spacer().frame(height:1)
                    home_bar(selectedPage: $selected_page, current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, show_multitasking: $show_multitasking, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, folder_offset: $folder_offset, show_folder: $show_folder).padding(.top).frame(height: 100)
                }
            }
        }.oldOSKeyboardHost(oldOSKeyboard, horizontalInset: 16, bottomInset: 100).ignoresSafeArea(.keyboard).onAppear() {
            withAnimation(.linear(duration:0)) {
                current_view = "LS"
            } //-> It's an interesting solution, but if we set the view first to the HomeScreen, let it render, and then immediately switch to the lock-screen, we'll get a much smoother animation.
            withAnimation(.linear(duration: 0.01)) {
                apps_scale = 4
                dock_offset = 100
            }
        }.onChange(of: current_view) {_ in
            // The OldOS keyboard host lives above the app switch, so a WebKit
            // editor can remain logically active even after Safari is replaced
            // by the Home/Lock screen. Treat leaving an app like real iOS does:
            // resign the active text input and dismiss our keyboard immediately.
            if current_view == "HS" || current_view == "LS" {
                oldOSKeyboard.hide()
            }

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
        } .ifButtonShapesEnabledLive { view in
            view.buttonStyle(buttonShapesOverride())
        }//.buttonStyle(buttonShapesOverride())
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
    @Binding var folder_offset: CGFloat
    @Binding var show_folder: Bool
    
    @State private var isPressed: Bool = false
    @State private var pressCount = 0
    @State private var actionWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            ZStack {
                Circle().fill(Color.black).frame(width: 65, height:65).overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                )
                Circle().fill(LinearGradient(gradient: Gradient(colors: [.black, .black, .black, Color.gray.opacity(0.35)]), startPoint: .top, endPoint: .bottom)).frame(width: 65, height:65).scaleEffect(isPressed ? 0.90 : 0.93)
                    .shadow(color: isPressed ? Color.gray.opacity(0.2) : Color.gray.opacity(0.3), radius: 4, x: 0, y: 1).offset(y: isPressed ? 0.75 : 0)
                    
                RoundedRectangle(cornerRadius: 4).fill(Color.black).frame(width: 20, height:20).overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.65), lineWidth: 1.75)
                )
            }
            ForceTouchGestureView(onStateChange: { isPressedDown in
                handlePress(isDown: isPressedDown)
            })
            .frame(width: 65, height: 65)
        }
        .padding()
    }
        
    private func handlePress(isDown: Bool) {
        // Always update visual state and haptics
        self.isPressed = isDown
        
        if isDown {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            
            // Cancel any pending single-press action from a previous tap
            actionWorkItem?.cancel()
            
            pressCount += 1
            
            if pressCount == 2 {
                // This is a confirmed double-press, fire the action immediately
                performDoubleHomeAction()
            }
            
        } else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            
            if pressCount == 1 {
                // The user has lifted their finger after one press.
                // Schedule the single-press action to happen after a short delay.
                actionWorkItem = DispatchWorkItem {
                    performHomeAction()
                    pressCount = 0 // Reset after action is performed
                }
                // The 0.3s delay gives the user time to initiate a second press.
                // If they do, the `cancel()` above will stop this from running.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: actionWorkItem!)
                
            } else if pressCount >= 2 {
                // If it was a double-press or more, just reset the count immediately on release.
                pressCount = 0
            }
        }
    }
    
    private func performHomeAction() {
        if show_multitasking == false {
            if current_view != "LS" && current_view != "HS" {
                withAnimation(.linear(duration: 0.35)) {
                    self.current_view = "HS"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    withAnimation(.linear(duration: 0.42)) {
                        apps_scale = 1
                        dock_offset = 0
                    }
                }
            } else {
                withAnimation() {
                    if show_folder && folder_offset == 150 {
                        withAnimation(.linear(duration: 0.32)) {
                            folder_offset = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                            show_folder = false
                        }
                    } else {
                        if selectedPage == 1 {
                            selectedPage = 0
                        } else {
                            selectedPage = 1
                        }
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
    }
    
    private func performDoubleHomeAction() {
        if current_view != "LS" && !show_folder {
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
    @Binding var folder_offset: CGFloat
    @Binding var show_folder: Bool
    @GestureState  var dragOffset: CGFloat = 0
    var userDefaults = UserDefaults.standard
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                WallpaperBackground(geometry: geometry).onTapGesture {
                    if folder_offset == 150 && show_folder {
                        withAnimation(.linear(duration: 0.32)) { folder_offset = 0 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) { show_folder = false }
                    }
                }
                
                if show_folder {
                    VStack(spacing: 0) {
                        // whatever sits above...
                        Spacer().frame(height: 3*(UIScreen.main.bounds.width/(390/85)
                                                  + UIScreen.main.bounds.height/(844/40) * icon_scaler))
                        
                        ZStack(alignment: .top) {
                            Image("FolderSwitcherBG")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150, alignment: .top)
                                .clipped()
                                .mask(
                                    FolderIsoscelesMask(triangleHeight: 18, baseWidth: 24, triangleCenterX: 10 + 1.5*UIScreen.main.bounds.width / (390/85))
                                )
                                .overlay(
                                    FolderIsoscelesTopBottomBorder(triangleHeight: 18, baseWidth: 24, triangleCenterX: 10 + 1.5*UIScreen.main.bounds.width / (390/85), lineWidth: 1)
                                        .stroke(.white.opacity(0.6), style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter, miterLimit: 2))
                                )
                                .folderInnerShadow(
                                    using: FolderIsoscelesMask(triangleHeight: 18, baseWidth: 24, triangleCenterX: 10 + 1.5*UIScreen.main.bounds.width / (390/85)),
                                    color: .black.opacity(0.4),
                                    lineWidth: 8,
                                    blur: 6,
                                    offset: CGPoint(x: 0, y: 4)
                                )
                            
                                
                            VStack(spacing: 0) {
                                Spacer().frame(height: 18)
                                Spacer()
                                HStack(spacing: 0) {
                                    Text("Utilities").foregroundColor(.white).font(.custom("Helvetica Neue Bold", fixedSize: 20)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).padding(.leading, 24)
                                    Spacer()
                                }//.padding(.top, 28)
                                Spacer().frame(height: 10)
                                folder_apps(apps_scale:$apps_scale, apps_scale_height: $apps_scale_height, icon_scaler: $icon_scaler, current_view: $current_view, dock_offset: $dock_offset, folder_offset: $folder_offset, show_folder: $show_folder).zIndex(10)
                                Spacer()
                                
                            }
                        }.allowsHitTesting(folder_offset > 0)
                        .frame(height: 150, alignment: .top)
                        
                        // This is a rather obscure solution, I will admit. Our problem is we need a tappable region below the folder. Using Color.clear with a content shape instead of a spacer gives us a such a region.
                        Color.clear
                            .contentShape(Rectangle())  // real hit area
                            .onTapGesture {
                                if folder_offset == 150 && show_folder {
                                    withAnimation(.linear(duration: 0.32)) { folder_offset = 0 }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) { show_folder = false }
                                }
                            }
                    }
                    WallpaperBackgroundFolderOffset(
                        folder_offset: folder_offset,
                        icon_scaler: icon_scaler
                    ).allowsHitTesting(false)
                }
                VStack {
                    Spacer()
                    if userDefaults.string(forKey: "Home_Wallpaper") == "Wallpaper_1" {
                        LinearGradient(gradient:Gradient(colors: [Color(red: 158/255, green: 158/255, blue: 158/255).opacity(0.0), Color(red: 34/255, green: 34/255, blue: 34/255)]), startPoint: .top, endPoint: .bottom).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: geometry.size.height/3.75, maxHeight: geometry.size.height/3.75, alignment: .center).clipped()
                    }else {
                        LinearGradient(gradient:Gradient(colors: [Color(red: 34/255, green: 34/255, blue: 34/255).opacity(0.0), Color(red: 24/255, green: 24/255, blue: 24/255).opacity(0.85)]), startPoint: .top, endPoint: .bottom).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: geometry.size.height/4.25, maxHeight: geometry.size.height/4.25, alignment: .center).clipped()
                    }
                }.allowsHitTesting(false)
                Color.black.opacity(selectedPage == 0 ? 0.65 : 0).padding(.top, 24).animation(.easeInOut, value: selectedPage)
                VStack(spacing: 0) {
                    status_bar().frame(minHeight: 24, maxHeight:24).zIndex(1)
                    Spacer().frame(height: 30)
//                    Spacer().frame(height: folder_offset)
                    TabView(selection: $selectedPage) {
                        search(width: $search_width, height: $search_height, show_searchField: $show_searchField, apps_scale: $apps_scale, current_view: $current_view, dock_offset: $dock_offset).frame(maxWidth: geometry.size.width, maxHeight:geometry.size.height).zIndex(0).clipped().tag(0)
                        apps(apps_scale:$apps_scale, apps_scale_height: $apps_scale_height, show_searchField: $show_searchField, icon_scaler: $icon_scaler, current_view: $current_view, dock_offset: $dock_offset, folder_offset: $folder_offset, show_folder: $show_folder, isActivePage: selectedPage == 1, width: geometry.size.width, height: geometry.size.height).frame(maxWidth: geometry.size.width, maxHeight:geometry.size.height).zIndex(0).tag(1)    .overlay(
                            GeometryReader { proxy in
                                Color.clear.hidden().onAppear() {
                                    search_width = proxy.size.width
                                    search_height = proxy.size.height
                                }
                            }
                        )
                        apps_second(apps_scale:$apps_scale, apps_scale_height: $apps_scale_height, show_searchField: $show_searchField, icon_scaler: $icon_scaler, current_view: $current_view, dock_offset: $dock_offset, folder_offset: $folder_offset, isActivePage: selectedPage == 2, width: geometry.size.width, height: geometry.size.height).frame(maxWidth: geometry.size.width, maxHeight:geometry.size.height).zIndex(0).tag(2).frame(width:search_width, height: search_height)
                    }.layoutPriority(1).tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)).animation(.easeInOut, value: selectedPage).onAppear() {
                        UIScrollView.appearance().bounces = false
                    }.opacity(1/(Double(dock_offset) + 1)).grayscale(show_multitasking == true ? 0.99 : 0).opacity(show_multitasking == true ? 0.3 : 1)
                    //added layout up there
                    dock2(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, show_multitasking: $show_multitasking, folder_offset: $folder_offset).frame(maxWidth:geometry.size.width, maxHeight: 150 - folder_offset).offset(y:dock_offset).offset(y:folder_offset/1.5).clipped()
                }.allowsHitTesting(folder_offset == 0)
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
                    }.padding(.bottom, 110).offset(y:dock_offset).offset(y:bottom_indicator_offset).offset(y:folder_offset).allowsHitTesting(folder_offset == 0)
                }.opacity(show_multitasking == true ? 0 : 1).allowsHitTesting(folder_offset == 0)
            }
            .clipped() // Clip only at the full simulated-phone boundary.
            .onAppear() {
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

extension View {
    func `HSif`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        condition ? AnyView(transform(self)) : AnyView(self)
    }
}
//

import SwiftUI

struct WallpaperBackground: View {
    let geometry: GeometryProxy
    @State private var cachedWallpaper: UIImage?
    private let userDefaults = UserDefaults.standard
    
    private let wallpaperChangePublisher = NotificationCenter.default.publisher(
        for: UserDefaults.didChangeNotification
    )

    var body: some View {
        ZStack {
            if userDefaults.bool(forKey: "Camera_Wallpaper_Home") == false {
                // Regular wallpaper from assets or filename
                Image(userDefaults.string(forKey: "Home_Wallpaper") ?? "Wallpaper_1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: geometry.size.height)
                    .frame(minWidth: geometry.size.width,
                           maxWidth: geometry.size.width,
                           minHeight: geometry.size.height,
                           maxHeight: geometry.size.height,
                           alignment: .center)
                    .cornerRadius(0)
                    .clipped()
            } else {
                // Cached data-based wallpaper (decoded once)
                if let ui = cachedWallpaper {
                    Image(uiImage: ui)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: geometry.size.height)
                        .frame(minWidth: geometry.size.width,
                               maxWidth: geometry.size.width,
                               minHeight: geometry.size.height,
                               maxHeight: geometry.size.height,
                               alignment: .center)
                        .cornerRadius(0)
                        .clipped()
                } else {
                    // Fallback image while cache loads
                    Image("Wallpaper_1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: geometry.size.height)
                        .frame(minWidth: geometry.size.width,
                               maxWidth: geometry.size.width,
                               minHeight: geometry.size.height,
                               maxHeight: geometry.size.height,
                               alignment: .center)
                        .cornerRadius(0)
                        .clipped()
                }
            }
        }
        .onAppear(perform: loadWallpaperOnce)
        .onReceive(wallpaperChangePublisher) { _ in
                  loadWallpaperOnce()
              }
    }

    // Decode once and match screen scale
    private func loadWallpaperOnce() {
        guard userDefaults.bool(forKey: "Camera_Wallpaper_Home") == true else { return }
        if let data = userDefaults.data(forKey: "Home_Wallpaper"),
           let ui = UIImage(data: data, scale: UIScreen.main.scale)?
                .preparingForDisplay() {
            cachedWallpaper = ui
        } else {
            cachedWallpaper = UIImage(named: "Wallpaper_1")?.preparingForDisplay()
        }
    }
}


struct WallpaperBackgroundFolderOffset: View {
    let folder_offset: CGFloat
    let icon_scaler: CGFloat
    @State private var cachedWallpaper: UIImage?
    let userDefaults = UserDefaults.standard
    
    private let wallpaperChangePublisher = NotificationCenter.default.publisher(
        for: UserDefaults.didChangeNotification
    )

    var body: some View {
        ZStack {
            if userDefaults.bool(forKey: "Camera_Wallpaper_Home") == false {
                wallpaperImage(
                    Image(userDefaults.string(forKey: "Home_Wallpaper") ?? "Wallpaper_1")
                )
            } else {
                if let ui = cachedWallpaper {
                    wallpaperImage(Image(uiImage: ui))
                } else {
                    wallpaperImage(Image("Wallpaper_1"))
                }
            }
        }
        .onAppear(perform: loadWallpaperOnce)
        .onReceive(wallpaperChangePublisher) { _ in
                  loadWallpaperOnce()
              }
    }

    @ViewBuilder
    private func wallpaperImage(_ img: Image) -> some View {
        GeometryReader { geometry in
            img
                .renderingMode(.original)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .aspectRatio(contentMode: .fill)
                .frame(height: geometry.size.height)
                .frame(minWidth: geometry.size.width, maxWidth: geometry.size.width,
                       minHeight: geometry.size.height, maxHeight: geometry.size.height)
                .offset(y: folder_offset > 50 ? -18 : 0)
                .compositingGroup()
                .mask(
                    VStack(spacing: 0) {
                        Spacer().frame(height: 3*(UIScreen.main.bounds.width/(390/85)
                                                  + UIScreen.main.bounds.height/(844/40) * icon_scaler))
                        FolderIsoscelesMask(
                            triangleHeight: folder_offset > 50 ? 0 : 18,
                            baseWidth: 24,
                            triangleCenterX: 10 + 1.5*UIScreen.main.bounds.width / (390/85)
                        )
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                                   - 3*(UIScreen.main.bounds.width/(390/85)
                                   + UIScreen.main.bounds.height/(844/40) * icon_scaler),
                            alignment: .top
                        )
                    }
                )
                .allowsHitTesting(false)
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: -4)
        }
        .clipped()
        .offset(y: folder_offset)
    }

    private func loadWallpaperOnce() {
        guard userDefaults.bool(forKey: "Camera_Wallpaper_Home") == true else { return }
        if let data = userDefaults.data(forKey: "Home_Wallpaper"),
           let ui = UIImage(data: data, scale: UIScreen.main.scale)?
                .preparingForDisplay() {
            cachedWallpaper = ui
        } else {
            cachedWallpaper = UIImage(named: "Wallpaper_1")?.preparingForDisplay()
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
                        
                        OldOSTextField("Search iPhone", text: $search, configuration: OldOSKeyboardConfiguration.standard, height: 20)
                        
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


//
////Our app pages are built on a LazyVGrid. This should be beneficial in the future...wink wink.
//struct apps: View {
//    @Binding var apps_scale: CGFloat
//    @Binding var apps_scale_height: CGFloat
//    @Binding var show_searchField:Bool
//    @Binding var icon_scaler: CGFloat
//    @Binding var current_view: String
//    @Binding var dock_offset: CGFloat
//    @Binding var folder_offset: CGFloat
//    @Binding var show_folder: Bool
//    var width: CGFloat
//    var height: CGFloat
//
//    var userDefaults = UserDefaults.standard
//
//    var body: some View {
//        VStack {
//            LazyVGrid(columns: [
//                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
//                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
//                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
//                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1)
//            ], spacing: UIScreen.main.bounds.height / (844 / 40) * icon_scaler) {
//                app(image_name: "Messages", app_name: "Messages", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
//                app_calendar(image_name: "Calendar", app_name: "Calendar", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
//                app(image_name: "Photos", app_name: "Photos", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
//                app(image_name: "Camera", app_name: "Camera", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
//                app(image_name: "YouTube", app_name: "YouTube", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
//                app(image_name: "Stocks", app_name: "Stocks", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
//                app(image_name: "Maps", app_name: "Maps", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
//                app(image_name: "Weather Fahrenheit", app_name: "Weather", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
//                app(image_name: "Notes", app_name: "Notes", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
//                folder(image_name: "Utilities", folder_name: "Utilities", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset, show_folder: $show_folder)
//                app(image_name: "iTunes", app_name: "iTunes", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
//                app(image_name: "App Store", app_name: "App Store", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
//                app(image_name: "Game Center", app_name: "Game Center", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset).offset(y: folder_offset > 50 ? folder_offset / (folder_offset - folder_offset * (folder_offset - 19) / (folder_offset - 18)) : folder_offset)
//                app(image_name: "Settings", app_name: "Settings", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset).offset(y: folder_offset > 50 ? folder_offset / (folder_offset - folder_offset * (folder_offset - 19) / (folder_offset - 18)) : folder_offset)
//            }
//            Spacer()
//        }.onAppear() {
//            UIApplication.shared.endEditing()
//        }//.offset(y:-15)
//    }
//}

// ═══════════════════════════════════════════════════════════════════════
// HOW TO APPLY:
//   1. Delete IOS6AnimationState, IOS6Quadrant, IOS6FlyInModifier,
//      RowHeightKey — everything from the previous two attempts.
//   2. Replace `struct apps` with the one below.
//   3. Replace `struct app` with the one below.
//   4. Replace `struct app_calendar` with the one below.
//   5. Replace `struct folder` with the one below.
//
// WHAT CHANGED AND WHY:
//   The LazyVGrid is kept EXACTLY as the original — it handles all layout.
//   The only new thing: each icon receives a `quadrantOffset: CGPoint`
//   parameter (defaults to .zero so every other call site is unaffected —
//   dock, folder interior, multitasking switcher, search results, all
//   untouched).
//   `apps` owns a single @State animatedIn. It computes four CGPoints
//   (one per quadrant) and passes them down. When animatedIn flips inside
//   a withAnimation, SwiftUI re-renders every icon in the same transaction.
//   One state, one animation call, perfect lockstep. No per-icon state.
// ═══════════════════════════════════════════════════════════════════════


// Allows icons to travel outside the app-page rectangle while the outer
// HomeScreen still clips everything at the simulated-phone boundary.
private struct PagingContainerOverflowBridge: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        configure(from: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        configure(from: uiView)
    }

    private func configure(from view: UIView) {
        DispatchQueue.main.async {
            var ancestor = view.superview
            while let current = ancestor {
                if let scrollView = current as? UIScrollView {
                    scrollView.clipsToBounds = false
                    return
                }
                ancestor = current.superview
            }
        }
    }
}

private extension View {
    func allowOverflowFromPagingContainer() -> some View {
        background(PagingContainerOverflowBridge().frame(width: 0, height: 0))
    }
}

// ─────────────────────────────────────────────────────────────────────
// APPS — the only struct that knows about the animation
// ─────────────────────────────────────────────────────────────────────
struct apps: View {
    @Binding var apps_scale: CGFloat
    @Binding var apps_scale_height: CGFloat
    @Binding var show_searchField: Bool
    @Binding var icon_scaler: CGFloat
    @Binding var current_view: String
    @Binding var dock_offset: CGFloat
    @Binding var folder_offset: CGFloat
    @Binding var show_folder: Bool
    var isActivePage: Bool
    var width: CGFloat
    var height: CGFloat

    var userDefaults = UserDefaults.standard

    // ── fly magnitudes ───────────────────────────────────────────────
    private let flyX: CGFloat = UIScreen.main.bounds.width  * 0.6
    private let flyY: CGFloat = UIScreen.main.bounds.height * 0.45

    // apps_scale and dock_offset are changed in the same withAnimation block.
    // Deriving icon travel from apps_scale guarantees the icons and dock finish together.
    private var flyProgress: CGFloat {
        min(max((apps_scale - 1.0) / 3.0, 0.0), 1.0)
    }
    private var tlOff: CGPoint { CGPoint(x: -flyX * flyProgress, y: -flyY * flyProgress) }
    private var trOff: CGPoint { CGPoint(x:  flyX * flyProgress, y: -flyY * flyProgress) }
    private var blOff: CGPoint { CGPoint(x: -flyX * flyProgress, y:  flyY * flyProgress) }
    private var brOff: CGPoint { CGPoint(x:  flyX * flyProgress, y:  flyY * flyProgress) }

    var body: some View {
        VStack {
            LazyVGrid(columns: [
                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1)
            ], spacing: UIScreen.main.bounds.height / (844 / 40) * icon_scaler) {

                // ── Row 0 ──────────────────────────────────────────────
                app(image_name: "Messages", app_name: "Messages",
                    current_view: $current_view, apps_scale: $apps_scale,
                    dock_offset: $dock_offset, folder_offset: $folder_offset,
                    quadrantOffset: tlOff)

                app_calendar(image_name: "Calendar", app_name: "Calendar",
                             current_view: $current_view, apps_scale: $apps_scale,
                             dock_offset: $dock_offset, folder_offset: $folder_offset,
                             quadrantOffset: tlOff)

                app(image_name: "Photos", app_name: "Photos",
                    current_view: $current_view, apps_scale: $apps_scale,
                    dock_offset: $dock_offset, folder_offset: $folder_offset,
                    quadrantOffset: trOff)

                app(image_name: "Camera", app_name: "Camera",
                    current_view: $current_view, apps_scale: $apps_scale,
                    dock_offset: $dock_offset, folder_offset: $folder_offset,
                    quadrantOffset: trOff)

                // ── Row 1 ──────────────────────────────────────────────
                app(image_name: "YouTube", app_name: "YouTube",
                    current_view: $current_view, apps_scale: $apps_scale,
                    dock_offset: $dock_offset, folder_offset: $folder_offset,
                    quadrantOffset: tlOff)

                app(image_name: "Stocks", app_name: "Stocks",
                    current_view: $current_view, apps_scale: $apps_scale,
                    dock_offset: $dock_offset, folder_offset: $folder_offset,
                    quadrantOffset: tlOff)

                app(image_name: "Maps", app_name: "Maps",
                    current_view: $current_view, apps_scale: $apps_scale,
                    dock_offset: $dock_offset, folder_offset: $folder_offset,
                    quadrantOffset: trOff)

                app(image_name: "Weather Fahrenheit", app_name: "Weather",
                    current_view: $current_view, apps_scale: $apps_scale,
                    dock_offset: $dock_offset, folder_offset: $folder_offset,
                    quadrantOffset: trOff)

                // ── Row 2 ──────────────────────────────────────────────
                app(image_name: "Notes", app_name: "Notes",
                    current_view: $current_view, apps_scale: $apps_scale,
                    dock_offset: $dock_offset, folder_offset: $folder_offset,
                    quadrantOffset: blOff)

                folder(image_name: "Utilities", folder_name: "Utilities",
                       current_view: $current_view, apps_scale: $apps_scale,
                       dock_offset: $dock_offset, folder_offset: $folder_offset,
                       show_folder: $show_folder,
                       quadrantOffset: blOff)

                app(image_name: "iTunes", app_name: "iTunes",
                    current_view: $current_view, apps_scale: $apps_scale,
                    dock_offset: $dock_offset, folder_offset: $folder_offset,
                    quadrantOffset: brOff)

                app(image_name: "App Store", app_name: "App Store",
                    current_view: $current_view, apps_scale: $apps_scale,
                    dock_offset: $dock_offset, folder_offset: $folder_offset,
                    quadrantOffset: brOff)

                // ── Row 3 ──────────────────────────────────────────────
                app(image_name: "Game Center", app_name: "Game Center",
                    current_view: $current_view, apps_scale: $apps_scale,
                    dock_offset: $dock_offset, folder_offset: $folder_offset,
                    quadrantOffset: blOff)
                    .offset(y: folder_offset > 50 ? folder_offset / (folder_offset - folder_offset * (folder_offset - 19) / (folder_offset - 18)) : folder_offset)

                app(image_name: "Settings", app_name: "Settings",
                    current_view: $current_view, apps_scale: $apps_scale,
                    dock_offset: $dock_offset, folder_offset: $folder_offset,
                    quadrantOffset: blOff)
                    .offset(y: folder_offset > 50 ? folder_offset / (folder_offset - folder_offset * (folder_offset - 19) / (folder_offset - 18)) : folder_offset)
            }
            Spacer()
        }
        .opacity(isActivePage || apps_scale <= 1.001 ? 1 : 0)
        .allowOverflowFromPagingContainer()
        .onAppear() {
            UIApplication.shared.endEditing()
        }
    }
}



// ─────────────────────────────────────────────────────────────────────
// APP — only change from original: added quadrantOffset param (default
// .zero) and one .offset call at the very end of the button chain.
// ─────────────────────────────────────────────────────────────────────
struct app: View {
    var image_name: String
    var app_name: String
    @State var pressed = false
    @Binding var current_view: String
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var folder_offset: CGFloat
    var is_folder_app: Bool = false
    var quadrantOffset: CGPoint = .zero                     // ← NEW (default .zero = no effect)

    var body: some View {
        Button(action: {
            if !["Clock", "Calculator"].contains(app_name) {
                if !is_folder_app {
                    withAnimation(.linear(duration: 0.32)) {
                        apps_scale = 4
                        dock_offset = 100
                    }
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
        }.background(returnedBK(for: app_name != "Phone" && app_name != "Mail" && app_name != "Safari" && app_name != "iPod" ? true : false)).compositingGroup().grayscale((folder_offset > 0 && !is_folder_app) ? 0.99 : 0).opacity((folder_offset > 0 && !is_folder_app) ? 0.3 : 1)
         .offset(x: quadrantOffset.x, y: quadrantOffset.y)  // ← NEW
    }
    private func returnedBK(for app: Bool) -> some View {
        if app {
            return AnyView(Image("WallpaperIconShadow").resizable().scaledToFit().frame(width:UIScreen.main.bounds.width/(390/104)).offset(y:6))
        } else {
            return AnyView(EmptyView())
        }
    }
}


// ─────────────────────────────────────────────────────────────────────
// APP_CALENDAR — only change: added quadrantOffset param and .offset call
// ─────────────────────────────────────────────────────────────────────
struct app_calendar: View {
    var image_name: String
    var app_name: String
    @Binding var current_view: String
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var folder_offset: CGFloat
    var quadrantOffset: CGPoint = .zero                     // ← NEW
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
        }.background(Image("WallpaperIconShadow").resizable().scaledToFit().frame(width:UIScreen.main.bounds.width/(390/104)).offset(y:6)).compositingGroup().grayscale(folder_offset > 0 ? 0.99 : 0).opacity(folder_offset > 0 ? 0.3 : 1)
         .offset(x: quadrantOffset.x, y: quadrantOffset.y)  // ← NEW
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


// ─────────────────────────────────────────────────────────────────────
// FOLDER — only change: added quadrantOffset param and .offset call
// ─────────────────────────────────────────────────────────────────────
struct folder: View {
    var image_name: String
    var folder_name: String
    @State var pressed = false
    @Binding var current_view: String
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var folder_offset: CGFloat
    @Binding var show_folder: Bool
    var quadrantOffset: CGPoint = .zero                     // ← NEW
    var body: some View {
        Button(action: {
            DispatchQueue.main.asyncAfter(deadline:.now() + 0.01) {
                if folder_offset == 150 {
                    withAnimation(.linear(duration: 0.32)) {
                        folder_offset = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                        show_folder = false
                    }
                } else {
                    show_folder = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        withAnimation(.linear(duration: 0.32)) {
                            folder_offset = 150
                        }
                    }
                }
            }
        }) {
            VStack {
                ZStack {
                    if pressed {
                        Rectangle().fill(Color.gray).frame(width: UIScreen.main.bounds.width/(390/60), height: UIScreen.main.bounds.width/(390/60)).cornerRadius(14)
                    }
                    Image("Folder").resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
                    VStack(alignment: .center) {
                        // Do not use a LazyVGrid here. When the home screen returns,
                        // the folder starts off-screen, so a lazy container can defer
                        // creating these preview icons until the fly-in is almost over.
                        // Keeping the exact folder open/close behavior untouched, this
                        // eager layout makes all four previews exist before the parent
                        // folder's quadrantOffset animation begins.
                        VStack(alignment: .leading, spacing: UIScreen.main.bounds.width/(390/60) / (844/40)) {
                            HStack(spacing: UIScreen.main.bounds.width/(390/60) / (844/40)) {
                                app_folder(image_name: "Clock-Small", app_name: "Clock", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                                    .frame(width: UIScreen.main.bounds.width / (390/85*6.5))
                                app_folder(image_name: "Calculator-Small", app_name: "Calculator", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                                    .frame(width: UIScreen.main.bounds.width / (390/85*6.5))
                                app_folder(image_name: "Compass-Small", app_name: "Compass", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                                    .frame(width: UIScreen.main.bounds.width / (390/85*6.5))
                            }
                            HStack(spacing: UIScreen.main.bounds.width/(390/60) / (844/40)) {
                                app_folder(image_name: "Voice Memos-Small", app_name: "Voice Memos", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
                                    .frame(width: UIScreen.main.bounds.width / (390/85*6.5))
                            }
                        }.frame(width: UIScreen.main.bounds.width/(390/60), alignment: .center).padding([.top], UIScreen.main.bounds.width/(390/60) / (844/40)*2.65).padding(.leading, UIScreen.main.bounds.width/(390/60) / (844/40*100))
                        Spacer()
                    }
                }
                Text(folder_name).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 13)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).offset(y: -4)
            }
        }.background(returnedBK(for: true)).compositingGroup()
         .offset(x: quadrantOffset.x, y: quadrantOffset.y)  // ← NEW
    }
    private func returnedBK(for app: Bool) -> some View {
        if app {
            return AnyView(Image("WallpaperIconShadow").resizable().scaledToFit().frame(width:UIScreen.main.bounds.width/(390/104)).offset(y:6))
        } else {
            return AnyView(EmptyView())
        }
    }
}

struct folder_apps: View {
    @Binding var apps_scale: CGFloat
    @Binding var apps_scale_height: CGFloat
    @Binding var icon_scaler: CGFloat
    @Binding var current_view: String
    @Binding var dock_offset: CGFloat
    @Binding var folder_offset: CGFloat
    @Binding var show_folder: Bool
    
    var userDefaults = UserDefaults.standard
    
    var body: some View {
            LazyVGrid(columns: [
                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width / (390/85)), spacing: 1)
            ], spacing: UIScreen.main.bounds.height / (844 / 40) * icon_scaler) {
                app(image_name: "Clock", app_name: "Clock", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset, is_folder_app: true)
                app(image_name: "Calculator", app_name: "Calculator", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset, is_folder_app: true)
                app(image_name: "Compass", app_name: "Compass", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset, is_folder_app: true)
                app(image_name: "Voice Memos", app_name: "Voice Memos", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset, is_folder_app: true)
            }.onAppear() {
            UIApplication.shared.endEditing()
        }//.offset(y:-15)
    }
}

@inline(__always)
private func equilateralHalfBase(forHeight h: CGFloat) -> CGFloat {
    h / CGFloat(sqrt(3))
}

struct FolderIsoscelesMask: Shape {
    var triangleHeight: CGFloat = 22
    var baseWidth: CGFloat = 22
    var triangleCenterX: CGFloat = 0

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { .init(triangleHeight, .init(baseWidth, triangleCenterX)) }
        set { triangleHeight = newValue.first
              baseWidth = newValue.second.first
              triangleCenterX = newValue.second.second }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let h = max(0, min(triangleHeight, rect.height))
        let halfBase = max(0, baseWidth / 2)
        let cx = triangleCenterX

        p.move(to: CGPoint(x: cx, y: 0))                // apex
        p.addLine(to: CGPoint(x: cx + halfBase, y: h))  // base right
        p.addLine(to: CGPoint(x: cx - halfBase, y: h))  // base left
        p.closeSubpath()

        p.addRect(CGRect(x: 0, y: h, width: rect.width, height: rect.height - h))
        return p
    }
}

struct FolderIsoscelesTopBottomBorder: Shape {
    var triangleHeight: CGFloat = 22
    var baseWidth: CGFloat = 22
    var triangleCenterX: CGFloat = 0
    var lineWidth: CGFloat = 2

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { .init(triangleHeight, .init(baseWidth, triangleCenterX)) }
        set { triangleHeight = newValue.first
              baseWidth = newValue.second.first
              triangleCenterX = newValue.second.second }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let h = max(0, min(triangleHeight, rect.height))
        let halfBase = max(0, baseWidth / 2)
        let cx = triangleCenterX

        let oddAdjust: CGFloat = (Int(lineWidth) % 2 == 1) ? 0.5 : 0.0
        let topY    = h + oddAdjust
        let bottomY = rect.maxY - oddAdjust

        let leftBase  = CGPoint(x: cx - halfBase, y: topY)
        let rightBase = CGPoint(x: cx + halfBase, y: topY)
        let apex      = CGPoint(x: cx,            y: 0 + oddAdjust)

        if leftBase.x > 0 {
            p.move(to: CGPoint(x: 0, y: topY))
            p.addLine(to: leftBase)
        }

        p.move(to: leftBase)
        p.addLine(to: apex)
        p.addLine(to: rightBase)

        if rightBase.x < rect.maxX {
            p.move(to: rightBase)
            p.addLine(to: CGPoint(x: rect.maxX, y: topY))
        }

        p.move(to: CGPoint(x: 0, y: bottomY))
        p.addLine(to: CGPoint(x: rect.maxX, y: bottomY))

        return p
    }
}


extension View {
    func folderInnerShadow<S: Shape>(
        using shape: S,
        color: Color = .black,
        lineWidth: CGFloat = 4,
        blur: CGFloat = 6,
        offset: CGPoint = .init(x: 0, y: 2)
    ) -> some View {
        self
            .overlay(
                shape
                    .stroke(color, lineWidth: lineWidth)
                    .offset(x: offset.x, y: offset.y)
                    .blur(radius: blur)
                    .mask(shape)
            )
    }
}



struct apps_second: View {
    @Binding var apps_scale: CGFloat
    @Binding var apps_scale_height: CGFloat
    @Binding var show_searchField:Bool
    @Binding var icon_scaler: CGFloat
    @Binding var current_view: String
    @Binding var dock_offset: CGFloat
    @Binding var folder_offset: CGFloat
    var isActivePage: Bool
    var width: CGFloat
    var height: CGFloat

    private let flyX: CGFloat = UIScreen.main.bounds.width * 0.6
    private let flyY: CGFloat = UIScreen.main.bounds.height * 0.45
    private var flyProgress: CGFloat {
        min(max((apps_scale - 1.0) / 3.0, 0.0), 1.0)
    }
    private var tlOff: CGPoint {
        CGPoint(x: -flyX * flyProgress, y: -flyY * flyProgress)
    }
    
    var body: some View {
        VStack {
            LazyVGrid(columns: [
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1)
            ], alignment: .center, spacing: UIScreen.main.bounds.height/(844/40)*icon_scaler) {
                app(image_name: "Contacts", app_name: "Contacts", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset, quadrantOffset: tlOff)
                
            }
            Spacer().frame(height:UIScreen.main.bounds.height/(844/40)*icon_scaler)
            Spacer()
        }
        .opacity(isActivePage || apps_scale <= 1.001 ? 1 : 0)
        .allowOverflowFromPagingContainer()
        .onAppear() {
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
//
//struct folder: View {
//    var image_name: String
//    var folder_name: String
//    @State var pressed = false
//    @Binding var current_view: String
//    @Binding var apps_scale: CGFloat
//    @Binding var dock_offset: CGFloat
//    @Binding var folder_offset: CGFloat
//    @Binding var show_folder: Bool
//    var body: some View {
//        Button(action: {
//            DispatchQueue.main.asyncAfter(deadline:.now() + 0.01) {
//                if folder_offset == 150 {
//                    withAnimation(.linear(duration: 0.32)) {
//                        folder_offset = 0
//                    }
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
//                        show_folder = false
//                    }
//                } else {
//                    show_folder = true
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
//                        withAnimation(.linear(duration: 0.32)) {
//                            folder_offset = 150
//                        }
//                    }
//                }
//            }
//        }) {
//            VStack {
//                ZStack {
//                    if pressed {
//                        Rectangle().fill(Color.gray).frame(width: UIScreen.main.bounds.width/(390/60), height: UIScreen.main.bounds.width/(390/60)).cornerRadius(14)
//                    }
//                    Image("Folder").resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
//                    VStack(alignment: .center) {
//                        LazyVGrid(columns: [
//                            GridItem(.fixed(UIScreen.main.bounds.width / (390/85*6.5)), spacing: UIScreen.main.bounds.width/(390/60) / (844/40)),
//                            GridItem(.fixed(UIScreen.main.bounds.width / (390/85*6.5)), spacing: UIScreen.main.bounds.width/(390/60) / (844/40)),
//                            GridItem(.fixed(UIScreen.main.bounds.width / (390/85*6.5)), spacing: UIScreen.main.bounds.width/(390/60) / (844/40))
//                        ], spacing: UIScreen.main.bounds.width/(390/60) / (844/40)) {
//                            app_folder(image_name: "Clock-Small", app_name: "Clock", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
//                            app_folder(image_name: "Calculator-Small", app_name: "Calculator", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
//                            app_folder(image_name: "Compass-Small", app_name: "Compass", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
//                            app_folder(image_name: "Voice Memos-Small", app_name: "Voice Memos", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset)
//                        }.frame(width: UIScreen.main.bounds.width/(390/60)).padding([.top], UIScreen.main.bounds.width/(390/60) / (844/40)*2.65).padding(.leading, UIScreen.main.bounds.width/(390/60) / (844/40*100))
//                        Spacer()
//                    }
//                }
//                Text(folder_name).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 13)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).offset(y: -4)
//            }
//        }.background(returnedBK(for: true))
//    }
//    private func returnedBK(for app: Bool) -> some View {
//        if app {
//            return AnyView(Image("WallpaperIconShadow").resizable().scaledToFit().frame(width:UIScreen.main.bounds.width/(390/104)).offset(y:6))
//        } else {
//            return AnyView(EmptyView())
//        }
//    }
//}

//
//struct app: View {
//    var image_name: String
//    var app_name: String
//    @State var pressed = false
//    @Binding var current_view: String
//    @Binding var apps_scale: CGFloat
//    @Binding var dock_offset: CGFloat
//    @Binding var folder_offset: CGFloat
//    var is_folder_app: Bool = false
//
//    var body: some View {
//        Button(action: {
//            if !["Clock", "Calculator"].contains(app_name) {
//                if !is_folder_app {
//                    withAnimation(.linear(duration: 0.32)) {
//                        apps_scale = 4
//                        dock_offset = 100
//                    }
//                }
//                DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
//                    withAnimation(.linear(duration: 0.32)) {
//                        current_view = app_name
//                    }
//                }
//            }
//        }) {
//            VStack {
//                ZStack {
//                    if pressed {
//                        Rectangle().fill(Color.gray).frame(width: UIScreen.main.bounds.width/(390/60), height: UIScreen.main.bounds.width/(390/60)).cornerRadius(14)
//                    }
//                    Image(image_name).resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
//                }
//                Text(app_name).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 13)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).offset(y: -4)
//            }
//        }.background(returnedBK(for: app_name != "Phone" && app_name != "Mail" && app_name != "Safari" && app_name != "iPod" ? true : false)).grayscale((folder_offset > 0 && !is_folder_app) ? 0.99 : 0).opacity((folder_offset > 0 && !is_folder_app) ? 0.3 : 1)
//    }
//    private func returnedBK(for app: Bool) -> some View {
//        if app {
//            return AnyView(Image("WallpaperIconShadow").resizable().scaledToFit().frame(width:UIScreen.main.bounds.width/(390/104)).offset(y:6))
//        } else {
//            return AnyView(EmptyView())
//        }
//    }
//}
//struct app_calendar: View {
//    var image_name: String
//    var app_name: String
//    @Binding var current_view: String
//    @Binding var apps_scale: CGFloat
//    @Binding var dock_offset: CGFloat
//    @Binding var folder_offset: CGFloat
//    @State var date = Date()
//    var timeFormat: DateFormatter {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "d"
//        return formatter
//    }
//    var body: some View {
//        Button(action: {
//                withAnimation(.linear(duration: 0.32)) {
//                    apps_scale = 4
//                    dock_offset = 100
//                }
//                DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
//                    withAnimation(.linear(duration: 0.32)) {
//                        current_view = app_name
//                    }
//                }}) {
//            VStack {
//                ZStack {
//                    Image(image_name).resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
//                    VStack {
//                        Text(getDayOfWeek(date: date)).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 10)).padding(.top, 6).shadow(color: Color.black, radius: 0.2, x: 0, y: 0.75).offset(y: -4).frame(maxWidth: 54).lineLimit(0).minimumScaleFactor(0.8)
//                        Spacer()
//                    }
//                    HStack {
//                        Spacer()
//                        Text(timeString(date: date)).lineLimit(nil).foregroundColor(.black).font(.custom("Helvetica Neue Bold", fixedSize: 35)).multilineTextAlignment(.center).padding(.top, 10).frame(alignment:.center)
//                        Spacer()
//                    }
//                }
//                Text(app_name).foregroundColor(.white).font(.custom("Helvetica Neue Medium", fixedSize: 13)).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).offset(y: -4)
//            }
//        }.background(Image("WallpaperIconShadow").resizable().scaledToFit().frame(width:UIScreen.main.bounds.width/(390/104)).offset(y:6)).grayscale(folder_offset > 0 ? 0.99 : 0).opacity(folder_offset > 0 ? 0.3 : 1)
//    }
//    func timeString(date: Date) -> String {
//        let time = timeFormat.string(from: date)
//        return time
//    }
//    func getDayOfWeek(date:Date) -> String {
//        let index = Calendar.current.component(.weekday, from: date)
//        return Calendar.current.weekdaySymbols[index - 1]
//    }
//}
//
struct app_folder: View {
    var image_name: String
    var app_name: String
    @Binding var current_view: String
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    var body: some View {
            VStack {
                ZStack {
                    Image(image_name).resizable().scaledToFit()
                }
            }
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
                Text(carrier_id == "" ? "No SIM" : carrier_id == "--" ? "eSIM" : carrier_id).foregroundColor(Color.init(red: 200/255, green: 200/255, blue: 200/255)).font(.custom("Helvetica Neue Medium", fixedSize: 15)).onAppear() {
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
            print(CTTelephonyNetworkInfo().serviceSubscriberCellularProviders) //CTCarrier has been depricated. As a result, for now, we will say something generic like "ESIM". I'm optimistic that this change is largely due to iPhones replacing physical SIMS with ESIMS, hence the introduction of CTCellularPlanProperties with iOS 26, which could provide a gateway back into this.
            if carrier_id == "" {
                let networkInfo = CTTelephonyNetworkInfo()
                let carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value
                let carrierName = carrier?.carrierName
                carrier_id = carrierName ?? ""
                if carrier_id == "--" {
                    carrier_id = "ESIM"
                }
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
    @Binding var folder_offset: CGFloat
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
                        app_reflection(image_name: "Phone", app_name: "Phone")
                            .scaleEffect(x: 1, y: -1, anchor: .center)
                            .opacity(0.25)
                            .offset(y: 35)
                            .clipped()
                            .offset(y: 15)
                        app_reflection(image_name: "Mail", app_name: "Mail")
                            .scaleEffect(x: 1, y: -1, anchor: .center)
                            .opacity(0.25)
                            .offset(y: 35)
                            .clipped()
                            .offset(y: 15)
                        app_reflection(image_name: "Safari", app_name: "Safari")
                            .scaleEffect(x: 1, y: -1, anchor: .center)
                            .opacity(0.25)
                            .offset(y: 35)
                            .clipped()
                            .offset(y: 15)
                        app_reflection(image_name: "iPod", app_name: "iPod")
                            .scaleEffect(x: 1, y: -1, anchor: .center)
                            .opacity(0.25)
                            .offset(y: 35)
                            .clipped()
                            .offset(y: 15)
                    }
                    LazyVGrid(columns: columns, alignment: .center, spacing: UIScreen.main.bounds.height/(844/40)) {
                        app(image_name: "Phone", app_name: "Phone", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
                        app(image_name: "Mail", app_name: "Mail", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
                        app(image_name: "Safari", app_name: "Safari", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
                        app(image_name: "iPod", app_name: "iPod", current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, folder_offset: $folder_offset)
                    }.offset(y: 0) .compositingGroup() .drawingGroup()
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

private struct IfButtonShapesEnabledModifier<S: View>: ViewModifier {
    let style: (AnyView) -> S
    @State private var enabled: Bool = {
        if #available(iOS 15.0, *) { return UIAccessibility.buttonShapesEnabled }
        return false
    }()

    func body(content: Content) -> some View {
        let base = AnyView(content)
        Group {
            if enabled {
                style(base)
            } else {
                base
            }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIAccessibility.buttonShapesEnabledStatusDidChangeNotification
        )) { _ in
            if #available(iOS 15.0, *) {
                enabled = UIAccessibility.buttonShapesEnabled
            }
        }
    }
}

public extension View {
    /// Apply a style only when the user has "Button Shapes" enabled (updates live).
    func ifButtonShapesEnabledLive<S: View>(
        _ style: @escaping (AnyView) -> S
    ) -> some View {
        modifier(IfButtonShapesEnabledModifier(style: style))
    }
}

struct buttonShapesOverride: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
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


/// Wrapper view to detect force touch press states and report pressed changes.
/// This version is now universal and works for all devices.
struct ForceTouchGestureView: UIViewRepresentable {
    var onStateChange: (Bool) -> Void // (isPressedDown: Bool)
    var minimumForce: CGFloat = 0.25

    func makeUIView(context: Context) -> some UIView {
        let view = TouchForwardingView()
        view.onStateChange = onStateChange
        view.minimumForce = minimumForce
        view.isUserInteractionEnabled = true
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

private class TouchForwardingView: UIView {
    var onStateChange: ((Bool) -> Void)?
    var minimumForce: CGFloat = 0.25
    private var isPressed: Bool = false

    // This method now handles both 3D Touch and standard devices
    private func handleTouch(_ touch: UITouch?) {
        guard let touch = touch else { return }
        
        // Check if the device supports Force Touch
        let hasForceTouch = touch.maximumPossibleForce > 0
        
        let isNowPressed = hasForceTouch
            ? (touch.force / touch.maximumPossibleForce > minimumForce) // 3D Touch logic
            : true // Standard device: any touch-down is a "press"
        
        if self.isPressed != isNowPressed {
            self.isPressed = isNowPressed
            self.onStateChange?(self.isPressed)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        handleTouch(touches.first)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        handleTouch(touches.first)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if isPressed {
            isPressed = false
            onStateChange?(false)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if isPressed {
            isPressed = false
            onStateChange?(false)
        }
    }
}
