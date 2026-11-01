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
            }.synchronizedAppGeometry().if(relative_app != "HS"){$0.transition(.scale)}.onAppear(perform: {
                UIScrollView.appearance().bounces = false
            })
        }
    }
}

private enum HomeAppTransition {
    static func canPresentSwitcher(from app: String, folderOpen: Bool) -> Bool {
        app != "LS" && (app != "HS" || !folderOpen)
    }
    static func usesIconFlight(for app: String, layout:HomeLayout) -> Bool {
        !layout.isInsideFolder(app)
    }
}

struct Controller: View {
    @ObservedObject private var passcode = OldOSPasscodeStore.shared

    @StateObject var oldOSKeyboard = OldOSKeyboardController()
    @StateObject private var homeEditing = HomeEditingController()
    @State var current_view: String = "HS"
    @State var multitasking_apps: [String] = []
    @State var apps_scale: CGFloat = 4
    @State var dock_offset: CGFloat = 100
    @State var apps_scale_height: CGFloat = 1 
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
                            switch passcode.isLocked ? "LS" : current_view {
                            case "LS":
                                LockScreen(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, apps_scale_height: $apps_scale_height).id(passcode.lockGeneration).padding([.leading, .trailing])
                            case "HS":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "HS")
                                HomeScreen(apps_scale: $apps_scale, apps_scale_height: $apps_scale_height, dock_offset: $dock_offset, selectedPage: $selected_page, search_width: $search_width, search_height:$search_height, current_view: $current_view, show_multitasking: $show_multitasking, instant_multitasking_change: $instant_multitasking_change, folder_offset: $folder_offset, show_folder: $show_folder).padding([.leading, .trailing]).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "HS") 
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
                                Maps(instant_multitasking_change: $instant_multitasking_change, show_multitasking: $show_multitasking, should_show: current_multitasking_app == "Maps").padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking(show_multitasking, instant_multitasking_change, current_multitasking_app == "Maps")
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
                            case "Calculator":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Calculator")
                                Calculator().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Calculator")
                            case "Clock":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Clock")
                                Clock().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Clock")
                            case "Voice Memos":
                                multitasking_controller(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, multitasking_apps: $multitasking_apps, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, show_multitasking: $show_multitasking, relative_app: "Voice Memos")
                                VoiceMemos().padding([.leading, .trailing]).transition(.scale).modifiedForMultitasking2(show_multitasking, instant_multitasking_change, current_multitasking_app == "Voice Memos")
                            default:
                                LockScreen(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, apps_scale_height: $apps_scale_height).id(passcode.lockGeneration).padding([.leading, .trailing])
                            }
                        }
                    }.overlay(RetroClockAlertOverlay())
                    Spacer().frame(height:1)
                    home_bar(selectedPage: $selected_page, current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, show_multitasking: $show_multitasking, instant_multitasking_change: $instant_multitasking_change, current_multitasking_app: $current_multitasking_app, should_update: $should_update, show_remove: $show_remove, folder_offset: $folder_offset, show_folder: $show_folder).padding(.top).frame(height: 100)
                }
            }
        }.overlay { if passcode.inactive { Color.black.ignoresSafeArea() } }
        .onChange(of: passcode.lockGeneration) { _ in
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                homeEditing.finishEditing(); homeEditing.openFolderID = nil; homeEditing.clearClosedFolder()
                current_view = "LS"
                apps_scale = 4
                dock_offset = 100
                show_multitasking = false
                instant_multitasking_change = false
                folder_offset = 0
                show_folder = false
            }
            oldOSKeyboard.hide()
        }.oldOSKeyboardHost(oldOSKeyboard, horizontalInset: 16, bottomInset: 100).ignoresSafeArea(.keyboard).onAppear() {
            withAnimation(.linear(duration:0)) {
                current_view = "LS"
            } 
            withAnimation(.linear(duration: 0.01)) {
                apps_scale = 4
                dock_offset = 100
            }
        }.onChange(of: current_view) {_ in

            if current_view != "HS" { homeEditing.finishEditing() }
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
        }.environmentObject(homeEditing).ifButtonShapesEnabledLive { view in
            view.buttonStyle(buttonShapesOverride())
        }
    }
}

extension View {
    @ViewBuilder func synchronizedAppGeometry() -> some View {
        if #available(iOS 17.0, macOS 14.0, *) { self.geometryGroup() }
        else { self }
    }
    func modifiedForMultitasking(_ show_multitasking: Bool, _ instant_multitasking_change: Bool, _ should_show: Bool) -> some View {
        self.synchronizedAppGeometry().offset(y: (show_multitasking == true && should_show == true) ? -(UIScreen.main.bounds.width/(390/85) + 20) : 0).clipped().disabled((show_multitasking == true && should_show == true))
    }
    func modifiedForMultitasking2(_ show_multitasking: Bool, _ instant_multitasking_change: Bool, _ should_show: Bool) -> some View {
        self.synchronizedAppGeometry().offset(y: (show_multitasking == true && should_show == true) ? -(UIScreen.main.bounds.width/(390/85) + 20) : 0).clipped().shadow(color: Color.black.opacity((instant_multitasking_change == true && should_show == true) ? 0.85 : 0), radius: 6, x: 0, y: 4).disabled((show_multitasking == true && should_show == true))
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
    private let timer = Timer.publish(every: 1.0/30.0, on: .main, in: .common).autoconnect()
    @State private var wiggleStartedAt: Date?
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
                        multitasking_app_section(current_view: $current_view, apps_scale: $apps_scale, dock_offset: $dock_offset, dual_angle: $dual_angle, should_update: $should_update, show_remove: $show_remove, apps_main_array: $apps, apps: app_section).frame(width:geometry.size.width, height: geometry.size.height).tag(i + 2)
                    }
                    }
                }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)).frame(width:geometry.size.width, height: geometry.size.height)

            }
        }.onChange(of: should_update) { editing in
            wiggleStartedAt = editing ? Date() : nil
            if !editing { withAnimation(.linear(duration: 0.2)) { dual_angle = 0 } }
        }.onReceive(timer) { instant in
            guard should_update else { return }
            if wiggleStartedAt == nil { wiggleStartedAt = instant }
            let angle = instant.timeIntervalSince(wiggleStartedAt ?? instant) * 1600
            withAnimation(.linear(duration: 1.0/30.0)) { dual_angle = angle }
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

            if UIScreen.main.bounds.width == 375 && UIScreen.main.bounds.height == 667 {
                icon_scaler = 0.55
            }

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
    @EnvironmentObject private var home:HomeEditingController
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

        self.isPressed = isDown

        if isDown {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

            actionWorkItem?.cancel()

            pressCount += 1

            if pressCount == 2 {

                performDoubleHomeAction()
            }

        } else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            if pressCount == 1 {

                actionWorkItem = DispatchWorkItem {
                    performHomeAction()
                    pressCount = 0 
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: actionWorkItem!)

            } else if pressCount >= 2 {

                pressCount = 0
            }
        }
    }

    private func performHomeAction() {
        guard !OldOSPasscodeStore.shared.isLocked else { return }
        if current_view == "HS", home.isEditing {
            home.finishEditing()
            if show_folder { home.openFolderID = nil }
            return
        }
        if show_multitasking == false {
            if current_view != "LS" && current_view != "HS" {
                let fliesIn = HomeAppTransition.usesIconFlight(for:current_view,layout:home.layout)
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    apps_scale = fliesIn ? 4 : 1
                    dock_offset = fliesIn ? 100 : 0
                }
                withAnimation(.linear(duration: 0.35)) {
                    self.current_view = "HS"
                }
            } else {
                withAnimation() {
                    if show_folder && folder_offset > 0 {
                        home.openFolderID = nil
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
        guard !OldOSPasscodeStore.shared.isLocked else { return }
        if home.isEditing { home.finishEditing(); return }
        if HomeAppTransition.canPresentSwitcher(from: current_view, folderOpen: show_folder) {
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

struct HomeIconEntranceDriver: UIViewRepresentable {
    let isActive: Bool
    let action: () -> Void
    func makeUIView(context: Context) -> EntranceView { EntranceView() }
    func updateUIView(_ view: EntranceView, context: Context) {
        view.action = action
        view.isActive = isActive
        view.armIfReady()
    }
    static func dismantleUIView(_ view: EntranceView, coordinator: ()) { view.stop() }
    final class EntranceView: UIView {
        var action: (() -> Void)?
        var isActive = false {
            didSet { if !isActive { finished = false; stop() } }
        }
        private var finished = false
        private var frames = 0
        private var displayLink: CADisplayLink?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window == nil { stop() } else { armIfReady() }
        }
        override func layoutSubviews() { super.layoutSubviews(); armIfReady() }
        func armIfReady() {
            guard isActive, !finished, displayLink == nil, window != nil,
                  bounds.width > 0, bounds.height > 0 else { return }
            frames = 0
            let link = CADisplayLink(target: self, selector: #selector(presentedFrame))
            displayLink = link
            link.add(to: .main, forMode: .common)
        }
        @objc private func presentedFrame() {
            guard isActive, window != nil else { stop(); return }
            frames += 1
            guard frames >= 2 else { return }
            finished = true
            stop()
            action?()
        }
        func stop() { displayLink?.invalidate(); displayLink = nil; frames = 0 }
    }
}

struct HomeScreen: View {
    @EnvironmentObject private var home:HomeEditingController
    @EnvironmentObject private var keyboard:OldOSKeyboardController
    private struct PageSlide {
        let id=UUID()
        let from:Int
        let to:Int
        var direction:CGFloat { to > from ? 1:-1 }
    }
    @State private var pageSlide:PageSlide?
    @State private var pageSlideProgress:CGFloat=0
    @State private var folderAnimationID = UUID()
    @State private var folderHighlightOpacity:Double=0
    @State private var folderWallpaperImage:UIImage?
    @Binding var apps_scale: CGFloat
    @Binding var apps_scale_height: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var selectedPage: Int
    @Binding var search_width: CGFloat
    @Binding var search_height: CGFloat
    @State var show_searchField: Bool = false
    @State var bottom_indicator_offset: CGFloat = 0.0
    @State var icon_scaler: CGFloat = 1.0
    @Binding var current_view: String
    @Binding var show_multitasking: Bool
    @Binding var instant_multitasking_change: Bool
    @Binding var folder_offset: CGFloat
    @Binding var show_folder: Bool
    var userDefaults = UserDefaults.standard
    var body: some View {
        GeometryReader { geometry in
            folderScene(geometry:geometry)
            .animation(nil,value:home.isEditing)
            .coordinateSpace(name:"HomeCanvas")
            .background(HomeGestureHost(controller:home,active:current_view == "HS" && selectedPage > 0 && !show_multitasking && !keyboard.isVisible && apps_scale <= 1.001 && (home.lift != nil || home.displayedFolderID == nil || home.openFolderID != nil)))
            .onPreferenceChange(HomeFramesKey.self) { home.updateFrames($0.relative(to:geometry.frame(in:.global).origin)) }
            .onChange(of:selectedPage) { selected in if selected > 0 { home.selectPage(selected-1) } }
            .onChange(of:home.page) { page in
                guard selectedPage != page+1 else { return }
                if home.lift != nil, selectedPage > 0 {
                    let slide=PageSlide(from:selectedPage-1,to:page)
                    var transaction=Transaction();transaction.disablesAnimations=true
                    withTransaction(transaction) { pageSlide=slide;pageSlideProgress=0;selectedPage=page+1 }
                    DispatchQueue.main.asyncAfter(deadline:.now()+0.016) {
                        guard pageSlide?.id == slide.id else { return }
                        withAnimation(.easeInOut(duration:0.3)) { pageSlideProgress=1 }
                        DispatchQueue.main.asyncAfter(deadline:.now()+0.3) {
                            guard pageSlide?.id == slide.id else { return }
                            var end=Transaction();end.disablesAnimations=true
                            withTransaction(end) { pageSlide=nil }
                        }
                    }
                } else { withAnimation(.easeInOut(duration:0.3)) { selectedPage=page+1 } }
            }
            .onChange(of:home.folderPanelHeight) { height in
                if home.openFolderID != nil, show_folder, folder_offset > 0 {
                    withAnimation(.easeInOut(duration:HomeFolderPresentation.duration)) { folder_offset = height }
                }
            }
            .onChange(of:home.openFolderID) { id in
                let token = UUID(); folderAnimationID = token
                if id != nil {
                    show_folder = true
                    DispatchQueue.main.async {
                        guard folderAnimationID == token else { return }
                        withAnimation(.easeInOut(duration:HomeFolderPresentation.duration)) { folder_offset = home.folderPanelHeight }
                        animateFolderHighlight(true,token:token)
                    }
                } else {
                    keyboard.hide()
                    animateFolderHighlight(false,token:token)
                    withAnimation(.easeInOut(duration:HomeFolderPresentation.duration)) { folder_offset = 0 }
                    DispatchQueue.main.asyncAfter(deadline:.now()+HomeFolderPresentation.duration) {
                        guard folderAnimationID == token, home.openFolderID == nil else { return }
                        show_folder = false; home.clearClosedFolder()
                    }
                }
            }
            .clipped() 
            .background(HomeIconEntranceDriver(isActive: current_view == "HS" && selectedPage == 0) {
                guard current_view == "HS", apps_scale > 1.001 else { return }
                withAnimation(.easeInOut(duration: 0.5)) {
                    apps_scale = 1
                    dock_offset = 0
                    apps_scale_height = 1
                }
            }.allowsHitTesting(false).accessibilityHidden(true))
            .onAppear() {
                home.page = min(max(0,selectedPage-1),home.displayPageCount-1)
                home.configure(size:geometry.size,columnWidth:UIScreen.main.bounds.width/(390/85),rowGap:UIScreen.main.bounds.height/(844/40)*icon_scaler)
                if home.openFolderID != nil { show_folder = true; folder_offset = home.folderPanelHeight; folderHighlightOpacity=1 }
                if UIScreen.main.bounds.width == 375 && UIScreen.main.bounds.height == 667 {
                    bottom_indicator_offset = 17.5
                    icon_scaler = 0.55
                }

                if UIScreen.main.bounds.width == 414 && UIScreen.main.bounds.height == 736 {
                    bottom_indicator_offset = 10
                    icon_scaler = 0.8
                }

                if UIScreen.main.bounds.width == 375 && UIScreen.main.bounds.height == 812 {
                    bottom_indicator_offset = 8
                }
                home.configure(size:geometry.size,columnWidth:UIScreen.main.bounds.width/(390/85),rowGap:UIScreen.main.bounds.height/(844/40)*icon_scaler)
            }
        }
    }
    private func animateFolderHighlight(_ visible:Bool,token:UUID) {
        let update = {
            guard folderAnimationID == token else { return }
            withAnimation(.easeInOut(duration:HomeFolderPresentation.highlightFadeDuration)) { folderHighlightOpacity = visible ? 1:0 }
        }
        if visible { update() }
        else { DispatchQueue.main.asyncAfter(deadline:.now()+HomeFolderPresentation.highlightCloseDelay,execute:update) }
    }
    private func folderScene(geometry:GeometryProxy) -> some View {
            HomeAnimationProgress(progress:folder_offset) { reveal in
            let motion=home.folderPresentation(reveal:reveal)
            ZStack {
                if home.displayedFolderID != nil {
                    VStack(spacing:0) {
                        Color.clear.frame(height:max(0,motion.panelTop))
                        HomeFolderPanel(current_view:$current_view,apps_scale:$apps_scale,dock_offset:$dock_offset,
                                        folder_offset:.constant(reveal),iconScaler:icon_scaler,motion:motion)
                        Spacer(minLength:0)
                    }.frame(width:geometry.size.width,height:geometry.size.height,alignment:.top)
                }
                wallpaperSurface(geometry:geometry,primary:true)
                    .mask(HomeFolderWallpaperMask(splitY:home.displayedFolderID == nil ? geometry.size.height:motion.splitY,
                                                   notchHeight:home.displayedFolderID == nil ? 0:(motion.pointsDown ? -motion.wallpaperNotchHeight:motion.notchHeight),triangleX:motion.triangleX,upper:true,overlap:0))
                    .offset(y:motion.upperShift).allowsHitTesting(false)
                if home.displayedFolderID != nil {
                    wallpaperSurface(geometry:geometry,primary:false)
                        .mask(HomeFolderWallpaperMask(splitY:motion.splitY,notchHeight:motion.pointsDown ? motion.notchHeight:-motion.wallpaperNotchHeight,
                                                       triangleX:motion.triangleX,upper:false,overlap:0))
                        .offset(y:motion.lowerShift).allowsHitTesting(false)
                    Color.clear.contentShape(HomeFolderOutsideHitShape(panelTop:motion.panelTop,panelHeight:motion.panelHeight),eoFill:true)
                        .onTapGesture { home.openFolderID=nil }
                }
                wallpaperShade(geometry:geometry).mask(wallpaperCoverage(geometry:geometry,motion:motion)).allowsHitTesting(false)
                if home.displayedFolderID != nil { HomeFolderWallpaperHighlights(motion:motion).opacity(folderHighlightOpacity).transition(.identity) }
                Color.black.opacity(selectedPage == 0 ? 0.65 : 0).padding(.top, 24).animation(.easeInOut, value: selectedPage)
                homeContents(geometry:geometry,motion:motion,reveal:reveal)
                pageIndicators(geometry:geometry,motion:motion)
                HomeDragImage(current_view:$current_view,apps_scale:$apps_scale,dock_offset:$dock_offset,folder_offset:$folder_offset).zIndex(100)
            }.frame(width:geometry.size.width,height:geometry.size.height)
            }
    }
    private func homeContents(geometry:GeometryProxy,motion:HomeFolderPresentation,reveal:CGFloat) -> some View {
                VStack(spacing: 0) {
                    status_bar().frame(minHeight: 24, maxHeight:24).zIndex(1)
                    Spacer().frame(height: 30)

                    ZStack {
                    TabView(selection: $selectedPage) {
                        search(width: $search_width, height: $search_height, show_searchField: $show_searchField, apps_scale: $apps_scale, current_view: $current_view, dock_offset: $dock_offset).frame(maxWidth: geometry.size.width, maxHeight:geometry.size.height).zIndex(0).clipped().tag(0)
                        ForEach(0..<home.layout.pages.count,id:\.self) { page in
                            HomePageIcons(apps_scale:$apps_scale,apps_scale_height:$apps_scale_height,show_searchField:$show_searchField,icon_scaler:$icon_scaler,
                                          current_view:$current_view,dock_offset:$dock_offset,folder_offset:.constant(reveal),page:page,isActivePage:selectedPage == page+1)
                                .frame(maxWidth:geometry.size.width,maxHeight:geometry.size.height).tag(page+1)
                                .background(GeometryReader { proxy in Color.clear.onAppear { search_width = proxy.size.width; search_height = proxy.size.height } })
                        }
                    }.layoutPriority(1).tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)).animation(.easeInOut, value: selectedPage).onAppear() {
                        UIScrollView.appearance().bounces = false
                    }.opacity(1/(Double(dock_offset) + 1)).grayscale(show_multitasking == true ? 0.99 : 0).opacity(show_multitasking == true ? 0.3 : 1)
                        .opacity(pageSlide == nil ? 1:0)
                    if let slide=pageSlide {
                        HomeAnimationProgress(progress:pageSlideProgress) { progress in
                        ZStack {
                        dragPage(geometry:geometry,reveal:reveal,page:slide.from)
                            .offset(x:-slide.direction*geometry.size.width*progress)
                        dragPage(geometry:geometry,reveal:reveal,page:slide.to)
                            .offset(x:slide.direction*geometry.size.width*(1-progress))
                        }
                        }
                    }
                    }

                    HomeDockIcons(current_view:$current_view,apps_scale:$apps_scale,dock_offset:$dock_offset,show_multitasking:$show_multitasking,folder_offset:.constant(reveal))
                        .frame(maxWidth:geometry.size.width,maxHeight:150).offset(y:dock_offset+motion.lowerShift).clipped()
                }.allowsHitTesting(home.displayedFolderID == nil)
    }
    private func dragPage(geometry:GeometryProxy,reveal:CGFloat,page:Int) -> some View {
        HomePageIcons(apps_scale:$apps_scale,apps_scale_height:$apps_scale_height,show_searchField:$show_searchField,icon_scaler:$icon_scaler,
                      current_view:$current_view,dock_offset:$dock_offset,folder_offset:.constant(reveal),page:page,isActivePage:true)
            .frame(maxWidth:geometry.size.width,maxHeight:geometry.size.height).allowsHitTesting(false)
    }
    private func wallpaperCoverage(geometry:GeometryProxy,motion:HomeFolderPresentation) -> some View {
        ZStack {
            Color.white.mask(HomeFolderWallpaperMask(splitY:home.displayedFolderID == nil ? geometry.size.height:motion.splitY,
                notchHeight:home.displayedFolderID == nil ? 0:(motion.pointsDown ? -motion.wallpaperNotchHeight:motion.notchHeight),triangleX:motion.triangleX,upper:true,
                overlap:0)).offset(y:motion.upperShift)
            if home.displayedFolderID != nil {
                Color.white.mask(HomeFolderWallpaperMask(splitY:motion.splitY,notchHeight:motion.pointsDown ? motion.notchHeight:-motion.wallpaperNotchHeight,
                    triangleX:motion.triangleX,upper:false,overlap:0))
                    .offset(y:motion.lowerShift)
            }
        }.frame(width:geometry.size.width,height:geometry.size.height)
    }
    private func pageIndicators(geometry:GeometryProxy,motion:HomeFolderPresentation) -> some View {
                VStack {
                    Spacer()
                    HStack() {
                        Button {
                            withAnimation {
                                selectedPage = max(selectedPage - 1, 0)
                            }
                        } label: {
                            Color.clear.frame(width:max(0,geometry.size.width/2.4-CGFloat(home.displayPageCount-2)*7.95),height:7.9)
                        }
                        Button {
                            withAnimation {
                                selectedPage = 0
                            }
                        } label: {
                            Image(systemName: "magnifyingglass").resizable().font(Font.title.weight(.heavy)).foregroundColor(selectedPage == 0 ? Color.white : Color.init(red: 146/255, green: 146/255, blue: 146/255)).frame(width: 7.9, height:7.9).padding(0)
                        }
                        ForEach(1...max(1,home.displayPageCount),id:\.self) { page in
                            Button { withAnimation { selectedPage = page } } label: {
                                Circle().fill(selectedPage == page ? Color.white:Color(red:146/255,green:146/255,blue:146/255)).frame(height:7.9).padding(0)
                            }
                        }
                        Button {
                            withAnimation {
                                selectedPage = min(selectedPage+1,home.displayPageCount)
                            }
                        } label: {
                            Color.clear.frame(width:max(0,geometry.size.width/2.4-CGFloat(home.displayPageCount-2)*7.95),height:7.9)
                        }
                    }.padding(.bottom, 110).offset(y:dock_offset).offset(y:bottom_indicator_offset).offset(y:motion.pointsDown ? motion.upperShift:motion.lowerShift).allowsHitTesting(home.displayedFolderID == nil)
                }.opacity(show_multitasking == true ? 0 : 1).allowsHitTesting(home.displayedFolderID == nil)
    }
    private func wallpaperSurface(geometry:GeometryProxy,primary:Bool) -> some View {
        WallpaperBackground(geometry:geometry,sourceImage:primary ? nil:folderWallpaperImage,
                            onImageLoaded:primary ? { folderWallpaperImage=$0 }:nil)
    }
    private func wallpaperShade(geometry:GeometryProxy) -> some View {

                VStack {
                    Spacer()
                    if userDefaults.string(forKey: "Home_Wallpaper") == "Wallpaper_1" {
                        LinearGradient(gradient:Gradient(colors: [Color(red: 158/255, green: 158/255, blue: 158/255).opacity(0.0), Color(red: 34/255, green: 34/255, blue: 34/255)]), startPoint: .top, endPoint: .bottom).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: geometry.size.height/3.75, maxHeight: geometry.size.height/3.75, alignment: .center).clipped()
                    }else {
                        LinearGradient(gradient:Gradient(colors: [Color(red: 34/255, green: 34/255, blue: 34/255).opacity(0.0), Color(red: 24/255, green: 24/255, blue: 24/255).opacity(0.85)]), startPoint: .top, endPoint: .bottom).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: geometry.size.height/4.25, maxHeight: geometry.size.height/4.25, alignment: .center).clipped()
                    }
                }.allowsHitTesting(false)

    }

}

struct HomeFolderPanel:View {
    @EnvironmentObject private var home:HomeEditingController
    @Binding var current_view:String
    @Binding var apps_scale:CGFloat
    @Binding var dock_offset:CGFloat
    @Binding var folder_offset:CGFloat
    let iconScaler:CGFloat
    let motion:HomeFolderPresentation
    var body:some View {
        GeometryReader { geometry in
        let layout=HomeFolderArtworkLayout(width:geometry.size.width,bodyHeight:motion.bodyHeight,triangleX:motion.triangleX,pointsDown:motion.pointsDown)
        let editing=home.isEditing || home.folderEditingDuringClose
        let titleInset=HomeFolderArtworkLayout.titleLeadingInset(panelWidth:geometry.size.width,screenWidth:UIScreen.main.bounds.width)
        ZStack(alignment:.top) {
            Image("FolderSwitcherBG").resizable().scaledToFill().frame(height:motion.bodyHeight+HomeFolderPresentation.notchHeight,alignment:.top).clipped()
                .mask(FolderIsoscelesMask(triangleHeight:motion.notchHeight,baseWidth:24,triangleCenterX:motion.triangleX,pointsDown:motion.pointsDown))
                .overlay(alignment:.topLeading) { HomeFolderShadows(layout:layout) }
            VStack(spacing:0) {
                Color.clear.frame(height:motion.contentTopInset)
                HomeFolderTitle(textLeadingInset:max(0,titleInset-8)).frame(maxWidth:.infinity,alignment:.leading).frame(height:29)
                    .padding(.leading,editing ? 8:titleInset)
                    .padding(.trailing,editing ? 8:titleInset)
                Color.clear.frame(height:8)
                HomeFolderApps(current_view:$current_view,apps_scale:$apps_scale,dock_offset:$dock_offset,folder_offset:$folder_offset,iconScaler:iconScaler)
                Spacer(minLength:0)
            }
        }
        }.frame(height:motion.panelHeight,alignment:.top)
            .allowsHitTesting(motion.progress >= 0.999)
            .background(GeometryReader { proxy in Color.clear.preference(key:HomeFramesKey.self,value:HomeFrames(folder:proxy.frame(in:.global))) })
    }
}

struct HomeFolderWallpaperMask:Shape {
    let splitY:CGFloat
    let notchHeight:CGFloat
    let triangleX:CGFloat
    let upper:Bool
    var overlap:CGFloat=0
    func path(in rect:CGRect)->Path {
        let cut=min(rect.height,max(0,splitY+(upper ? overlap:-overlap))),x=min(rect.width-12,max(12,triangleX)),n=notchHeight,halfBase=notchHeight<0 ? min(12,-notchHeight):12
        var p=Path()
        if upper {
            p.move(to:.zero);p.addLine(to:CGPoint(x:rect.width,y:0));p.addLine(to:CGPoint(x:rect.width,y:cut))
            p.addLine(to:CGPoint(x:x+halfBase,y:cut));p.addLine(to:CGPoint(x:x,y:cut-n));p.addLine(to:CGPoint(x:x-halfBase,y:cut));p.addLine(to:CGPoint(x:0,y:cut))
        } else {
            p.move(to:CGPoint(x:0,y:cut));p.addLine(to:CGPoint(x:x-halfBase,y:cut));p.addLine(to:CGPoint(x:x,y:cut+n));p.addLine(to:CGPoint(x:x+halfBase,y:cut))
            p.addLine(to:CGPoint(x:rect.width,y:cut));p.addLine(to:CGPoint(x:rect.width,y:rect.height));p.addLine(to:CGPoint(x:0,y:rect.height))
        }
        p.closeSubpath()
        return p
    }
}

struct HomeFolderOutsideHitShape:Shape {
    let panelTop:CGFloat
    let panelHeight:CGFloat
    func path(in rect:CGRect)->Path {
        var p=Path(rect)
        p.addRect(CGRect(x:0,y:panelTop,width:rect.width,height:panelHeight))
        return p
    }
}

extension View {
    func `HSif`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        condition ? AnyView(transform(self)) : AnyView(self)
    }
}

import SwiftUI

struct WallpaperBackground: View {
    let geometry: GeometryProxy
    var sourceImage:UIImage? = nil
    var onImageLoaded:((UIImage?)->Void)? = nil
    @State private var cachedWallpaper: UIImage?
    private let userDefaults = UserDefaults.standard

    private let wallpaperChangePublisher = NotificationCenter.default.publisher(
        for: UserDefaults.didChangeNotification
    )

    var body: some View {
        ZStack {
            if userDefaults.bool(forKey: "Camera_Wallpaper_Home") == false {

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

                if let ui = sourceImage ?? cachedWallpaper {
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

    private func loadWallpaperOnce() {
        guard userDefaults.bool(forKey:"Camera_Wallpaper_Home") else { cachedWallpaper=nil; onImageLoaded?(nil); return }
        guard sourceImage == nil else { return }
        if let data = userDefaults.data(forKey: "Home_Wallpaper"),
           let ui = UIImage(data: data, scale: UIScreen.main.scale)?
                .preparingForDisplay() {
            cachedWallpaper = ui
            onImageLoaded?(ui)
        } else {
            cachedWallpaper = UIImage(named: "Wallpaper_1")?.preparingForDisplay()
            onImageLoaded?(cachedWallpaper)
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
    var id: String { name }
    var name: String
}
struct search: View {
    var apps = HomeApplication.all.map { app_search_id_ext(name: $0.id) }
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

extension View {
    func allowOverflowFromPagingContainer() -> some View {
        background(PagingContainerOverflowBridge().frame(width: 0, height: 0))
    }
}

struct app: View {
    var image_name: String
    var app_name: String
    @State var pressed = false
    @Binding var current_view: String
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var folder_offset: CGFloat
    var is_folder_app: Bool = false
    var canLaunch = true
    var launchAllowed:()->Bool = { true }
    var shadowOverride:Bool? = nil
    var quadrantOffset: CGPoint = .zero                     

    var body: some View {
        Button(action: {
            guard canLaunch && launchAllowed() else { return }
            do {
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
        }.background(returnedBK(for:shadowOverride ?? (app_name != "Phone" && app_name != "Mail" && app_name != "Safari" && app_name != "iPod"))).compositingGroup().grayscale((folder_offset > 0 && !is_folder_app) ? 0.99 : 0).opacity((folder_offset > 0 && !is_folder_app) ? 0.3 : 1)
         .offset(x: quadrantOffset.x, y: quadrantOffset.y)  
    }
    private func returnedBK(for app: Bool) -> some View {
        if app {
            return AnyView(Image("WallpaperIconShadow").resizable().scaledToFit().frame(width:UIScreen.main.bounds.width/(390/104)).offset(y:6))
        } else {
            return AnyView(EmptyView())
        }
    }
}

struct app_calendar: View {
    var image_name: String
    var app_name: String
    @Binding var current_view: String
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @Binding var folder_offset: CGFloat
    var is_folder_app = false
    var canLaunch = true
    var launchAllowed:()->Bool = { true }
    var shadowOverride:Bool? = nil
    var quadrantOffset: CGPoint = .zero
    @State var date = Date()
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
    var body: some View {
        Button(action: {
                guard canLaunch && launchAllowed() else { return }
                if !is_folder_app {
                    withAnimation(.linear(duration:0.32)) { apps_scale = 4; dock_offset = 100 }
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
        }.background {
            if shadowOverride ?? true { Image("WallpaperIconShadow").resizable().scaledToFit().frame(width:UIScreen.main.bounds.width/(390/104)).offset(y:6) }
        }.compositingGroup().grayscale(folder_offset > 0 && !is_folder_app ? 0.99:0).opacity(folder_offset > 0 && !is_folder_app ? 0.3:1)
         .offset(x: quadrantOffset.x, y: quadrantOffset.y)  
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

struct FolderIsoscelesMask: Shape {
    var triangleHeight: CGFloat = 22
    var baseWidth: CGFloat = 22
    var triangleCenterX: CGFloat = 0
    var pointsDown = false

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

        p.move(to: CGPoint(x: cx, y: 0))                
        p.addLine(to: CGPoint(x: cx + halfBase, y: h))  
        p.addLine(to: CGPoint(x: cx - halfBase, y: h))  
        p.closeSubpath()

        p.addRect(CGRect(x: 0, y: h, width: rect.width, height: rect.height - h))
        return pointsDown ? p.applying(CGAffineTransform(a:1,b:0,c:0,d:-1,tx:0,ty:rect.height)):p
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

struct ForceTouchGestureView: UIViewRepresentable {
    var onStateChange: (Bool) -> Void 
    var minimumForce: CGFloat = 0.25

    func makeUIView(context: Context) -> some UIView {
        let view = TouchForwardingView()
        view.onStateChange = onStateChange
        view.minimumForce = minimumForce
        view.isUserInteractionEnabled = true
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        guard let view = uiView as? TouchForwardingView else { return }
        view.onStateChange = onStateChange
        view.minimumForce = minimumForce
    }
}

private class TouchForwardingView: UIView {
    var onStateChange: ((Bool) -> Void)?
    var minimumForce: CGFloat = 0.25
    private var isPressed: Bool = false

    private func handleTouch(_ touch: UITouch?) {
        guard let touch = touch else { return }

        let hasForceTouch = touch.maximumPossibleForce > 0

        let isNowPressed = hasForceTouch
            ? (touch.force / touch.maximumPossibleForce > minimumForce) 
            : true 

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
