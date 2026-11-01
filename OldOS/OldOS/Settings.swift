//
//  Settings.swift
//  OldOS
//
//  Created by Zane Kleinberg on 1/11/21.
//
import SwiftUI
import CoreTelephony
import PureSwiftUITools
import Foundation
import SystemConfiguration.CaptiveNetwork
import LocationProvider
import AVKit
import MediaPlayer
import Photos
struct Settings: View, Equatable {
    static func == (lhs: Settings, rhs: Settings) -> Bool {
        //Our views will want to redraw when we activate multitasking. The easiest solution is to make our views equatable and not have them redraw when changing it.
        return lhs.show_multitasking != rhs.show_multitasking
    }
    
    @ObservedObject private var passcodeStore = OldOSPasscodeStore.shared
    @StateObject private var passcodeSession = OldOSPasscodeSettingsSession()
    @State var selectedPage = 1
    @ObservedObject var locationProvider : LocationProvider
    @StateObject var photos_obsever = SettingsPhotosObserver()
    @State var show_wallpaper_select: Bool = false
    @State var show_wallpaper_select_camera_roll: Bool = false
    @State var wallpaper: String = ""
    @State var wallpaper_camera_roll: UIImage?
    @State var last_photo: UIImage = UIImage()
    @Binding var show_multitasking: Bool
    init(show_multitasking: Binding<Bool>) {
        _show_multitasking = show_multitasking
        locationProvider = LocationProvider()
        do {try locationProvider.start()}
        catch {
            print("No location access.")
            locationProvider.requestAuthorization()
        }
    }
    var usage_section = [list_row(title: "Airplane Mode", image: "Settings-Airplane Mode", content: AnyView(airplane_content()), destination: nil), list_row(title: "Wi-Fi", image: "Settings-Wifi", content: AnyView(wifi_content()), destination: "Wi-Fi Networks"), list_row(title: "Notifications", image: "Settings-Notifications", content: AnyView(notification_content()), destination: "Notifications"), list_row(title: "Location Services", image: "Settings-Location", content: AnyView(location_content()), destination: "Location Services"), list_row(title: "Carrier", image: "Settings-Carrier", content: AnyView(carrier_content()), destination: "Carrier")]
    var display_section = [list_row(title: "Sounds", image: "Settings-Sound", content: AnyView(sounds_content()), destination: "Sounds"), list_row(title: "Brightness", image: "Settings-Brightness", content: AnyView(brightness_content()), destination: "Brightness"), list_row(title: "Wallpaper", image: "Settings-Wallpaper", content: AnyView(wallpaper_content()), destination: "Wallpaper")]
    var apps_section = [list_row(title: "General", image: "Settings-General", content: AnyView(general_content()), destination: "General"), list_row(title: "Mail, Contacts, Calendars", image: "Settings-MCC", content: AnyView(mail_contacts_calendars_content()), destination: "Mail, Contacts, Calendars"), list_row(title: "Phone", image: "Settings-Phone", content: AnyView(generic_content()), destination: "Phone"),list_row(title: "Safari", image: "Settings-Safari", content: AnyView(generic_content()), destination: "Safari"),list_row(title: "Messages", image: "Settings-Messages", content: AnyView(generic_content()), destination: "Messages"),list_row(title: "iPod", image: "Settings-iPod", content: AnyView(generic_content()), destination: "iPod"), list_row(title: "Photos", image: "Settings-Photos", content: AnyView(generic_content()), destination: "Photos"), list_row(title: "Notes", image: "Settings-Notes", content: AnyView(generic_content()), destination: "Notes"), list_row(title: "Store", image: "Settings-App Store", content: AnyView(generic_content()), destination: "Store")]
    var nike_section = [list_row(title: "Nike + iPod", image: "Settings-Nike", content: AnyView(general_content()), destination: "General")]
    @State var current_nav_view: String = "Settings"
    @State var forward_or_backward = false
    @EnvironmentObject var EmailManager: EmailManager
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing:0) {
                    status_bar_in_app(selected_page:selectedPage).frame(minHeight: 24, maxHeight:24).zIndex(1)
                    title_bar(forward_or_backward: $forward_or_backward, current_nav_view: Binding(get:{ current_nav_view == "General_Passcode Authenticate" ? "General" : current_nav_view },set:{current_nav_view = $0}), title: current_nav_view == "General_Passcode Authenticate" ? "General" : current_nav_view == "General_Passcode Require" ? "Require Passcode" : current_nav_view == "Location Services" ? "  \(current_nav_view)" : current_nav_view == "Wallpaper_Select" ? "" : current_nav_view == "Wallpaper_Grid" ? "Wallpaper" : current_nav_view == "Wallpaper_Grid_Camera_Roll" ? "Camera Roll" : current_nav_view.contains("General_") ? current_nav_view.replacingOccurrences(of: "General_", with: "") : current_nav_view == "Mail, Contacts, Calendars" ? "           Mail, Contacts, Calen..." : current_nav_view == "MCC_Action" ? EmailManager.account_name : current_nav_view, general_back_title:current_nav_view == "General_Passcode Require" ? "Passcode Lock" : "General", general_back_destination:current_nav_view == "General_Passcode Require" ? "General_Passcode Lock" : "General").frame(minHeight: 60, maxHeight: 60).zIndex(1) //For lo
                    switch current_nav_view {
                    case "Settings":
                        settings_home(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, usage_section: usage_section, display_section: display_section, apps_section: apps_section).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Wi-Fi Networks":
                        wifi_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Notifications":
                        notifications_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Location Services":
                        location_services_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Carrier":
                        carrier_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Sounds":
                        sounds_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Brightness":
                        brightness_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Wallpaper":
                        wallpaper_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, photos_obsever: photos_obsever).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Wallpaper_Select":
                        wallpaper_select_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, last_photo: $last_photo).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Wallpaper_Grid":
                        wallpaper_grid_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, wallpaper:$wallpaper, show_wallpaper_select: $show_wallpaper_select).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Wallpaper_Grid_Camera_Roll":
                        wallpaper_grid_view_camera_roll(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, wallpaper_camera_roll: $wallpaper_camera_roll, show_wallpaper_select_camera_roll: $show_wallpaper_select_camera_roll, photos_obsever: photos_obsever).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "General", "General_Passcode Authenticate":
                        general_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "General_About":
                        general_about_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "General_Usage":
                        general_usage_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "General_Network":
                        general_network_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "General_Bluetooth":
                        general_bluetooth_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "General_Passcode Lock":
                        OldOSPasscodeSettingsView(session:passcodeSession) {
                            forward_or_backward = false
                            withAnimation(.linear(duration:0.28)) { current_nav_view = "General_Passcode Require" }
                        }.transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "General_Passcode Require":
                        OldOSPasscodeGraceView {
                            forward_or_backward = true
                            withAnimation(.linear(duration:0.28)) { current_nav_view = "General_Passcode Lock" }
                        }.transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "General_Autolock":
                        general_autolock_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "General_Date":
                        general_date_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "General_Keyboard":
                        general_keyboard_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "General_International":
                        general_international_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "General_Accessibility":
                        general_accessibility_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Mail, Contacts, Calendars":
                        mcc_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "MCC_Action":
                        mail_account_action_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Phone":
                        phone_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Safari":
                        safari_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Messages":
                        messages_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "iPod":
                        ipod_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Photos":
                        photos_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Notes":
                        notes_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Store":
                        store_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    default:
                        settings_home(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, usage_section: usage_section, display_section: display_section, apps_section: apps_section).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    }
                }.clipped()
                if show_wallpaper_select {
                    VStack(spacing:0) {
                        wallpaper_set_view(wallpaper:$wallpaper, show_wallpaper_select: $show_wallpaper_select).compositingGroup()
                    }.clipped().transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom))).zIndex(1)
                }
                if show_wallpaper_select_camera_roll {
                    VStack(spacing:0) {
                wallpaper_set_view_camera_roll(wallpaper_camera_roll:$wallpaper_camera_roll, show_wallpaper_select_camera_roll: $show_wallpaper_select_camera_roll).compositingGroup()
                    }.clipped().transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom))).zIndex(1)
                }
            }.overlay {
                VStack(spacing:0) {
                    Color.clear.frame(height:24).allowsHitTesting(false)
                    ZStack {
                        if let request = passcodeSession.request {
                            OldOSPasscodeSettingsSheet(session:passcodeSession,request:request,gateAccepted:{
                                guard current_nav_view == "General_Passcode Authenticate" else { return }
                                var transaction = Transaction(); transaction.disablesAnimations = true
                                withTransaction(transaction) { current_nav_view = "General_Passcode Lock" }
                            }) {
                                guard current_nav_view == "General_Passcode Authenticate" || current_nav_view == "General_Passcode Lock" else { return }
                                var transaction = Transaction(); transaction.disablesAnimations = true
                                withTransaction(transaction) { current_nav_view = "General" }
                            }.id(request.id).transition(.move(edge:.bottom)).zIndex(10)
                        }
                    }.frame(maxWidth:.infinity,maxHeight:.infinity)
                }.clipped().allowsHitTesting(passcodeSession.request != nil)
            }.onChange(of:current_nav_view) { route in
                if route == "General_Passcode Authenticate" { passcodeSession.enter() }
                else if route != "General_Passcode Lock" && route != "General_Passcode Require" { passcodeSession.reset() }
            }.onChange(of:passcodeStore.inactive) { inactive in
                if !inactive && current_nav_view == "General_Passcode Authenticate" { passcodeSession.enter() }
            }.onAppear() {
                UIScrollView.appearance().bounces = true
                UITableView.appearance().backgroundColor = .clear
            }.onDisappear() {
                passcodeSession.reset()
                UIScrollView.appearance().bounces = false
            }
        }.onAppear() {
            DispatchQueue.global(qos: .background).async {
                LastPhotoRetriever().queryLastPhoto(resizeTo: nil) {photo in
                    last_photo = photo ?? UIImage()
                }
            }
        }
    }
}

struct settings_home: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var usage_section: [list_row]
    var display_section: [list_row]
    var apps_section: [list_row]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack {
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: usage_section)
                        Spacer().frame(height: 25)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: display_section)
                        Spacer().frame(height: 25)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: apps_section)
                        Spacer().frame(height: 15)
                    }
                }
                
            }
        }
    }
}

//** MARK: Wifi Views
struct wifi_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var wifi_top_section = [list_row(title: "Wi-Fi", image: nil, content: AnyView(wifi_top_content()), destination: nil)]
    var ask_to_join = [list_row(title: "Ask to Join Networks", image: nil, content: AnyView(join_content()), destination: nil)]
    @State var wifi_networks = [list_row(title: "Other...", image: "", content: AnyView(wifi_other_content()), destination:nil)]
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack {
                        Spacer().frame(height:20)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: wifi_top_section)
                        Spacer().frame(height:15)
                        HStack {
                            Text("Choose a Network...").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        Spacer().frame(height:4)
                        list_section_blue(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: wifi_networks)
                        Spacer().frame(height:20)
                        list_section_oversize(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: ask_to_join)
                        Text("Known networks will be joined\n automatically. If no known networks are available, you will we asked before joining \na new network.").multilineTextAlignment(.center).lineLimit(nil).fixedSize(horizontal: false, vertical: true).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Regular", fixedSize: 15)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24).frame(maxHeight: .infinity)
                    }
                }
            }.onAppear() {
                if getWiFiSsid() != nil {
                    wifi_networks.insert(list_row(title: getWiFiSsid() ?? "", image: "TWPickerTableCellChecked", content: AnyView(connected_content()), destination:nil, selected: true), at: 0)
                }
            }  .onReceive(timer) { _ in
                if getWiFiSsid() != nil {
                    if wifi_networks.count == 1 {
                        wifi_networks.insert(list_row(title: getWiFiSsid() ?? "", image: "TWPickerTableCellChecked", content: AnyView(connected_content()), destination:nil, selected: true), at: 0)
                    }
                } else {
                    if wifi_networks.count == 2 {
                        wifi_networks.remove(at: 0)
                    }
                }
            }
        }
    }
}

struct wifi_top_content: View {
    var body: some View {
        HStack {
            Spacer()
            toggle().padding(.trailing, 12)
        }
    }
}

struct join_content: View {
    var body: some View {
        HStack {
            toggle().padding(.trailing, 0)
        }
    }
}

struct connected_content: View {
    var body: some View {
        HStack {
            Spacer()
            Image("Lock").padding([.leading], 2)
            Image("Wi-Fi Blue 3").padding([.trailing], 1)
            Image("ABTableNextButton").padding(.trailing, 12)
        }
    }
}

struct wifi_content: View {
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var connection_status: String? = "Not Connected"
    var body: some View {
        HStack {
            Spacer()
            Text(connection_status ?? "Not Connected").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255))
            Image("UITableNext").padding(.trailing, 12)
        }.onAppear() {
            connection_status = getWiFiSsid() ?? nil
        }  .onReceive(timer) { _ in
            connection_status = getWiFiSsid() ?? nil
        }
    }
}
struct wifi_other_content: View {
    var body: some View {
        HStack {
            Spacer()
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}

struct generic_content: View {
    var body: some View {
        HStack {
            Spacer()
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}


//**MARK: Notifications Views

struct notification_content: View {
    @State var notification_access: Bool = true
    var body: some View {
        HStack {
            Text(notification_access ? "On" : "Off").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255))
            // Image(systemName: "chevron.right").foregroundColor(Color(red: 127/255, green: 127/255, blue: 127/255)).padding(.trailing, 12)
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}

struct notifications_view: View {
    @State var notification_access: Bool = true
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var notification_top_section = [list_row(title: "Notifications", image: nil, content: AnyView(notifications_top_content()), destination: nil)]
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack {
                        Spacer().frame(height:20)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: notification_top_section)
                        Text("Turn off Notifications to disable Sounds,\n Alerts and Home Screen Badges for the\n applications below.").multilineTextAlignment(.center).lineLimit(nil).fixedSize(horizontal: false, vertical: true).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Regular", fixedSize: 15)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24).frame(maxHeight: .infinity)
                    }
                }
            }
        }
    }
}

struct notifications_top_content: View {
    var body: some View {
        HStack {
            Spacer()
            toggle().padding(.trailing, 12)
        }
    }
}

//**MARK: Location Services Views

struct location_services_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var location_services_top_section = [list_row(title: "Location Services", image: nil, content: AnyView(location_services_top_content()), destination: nil)]
    var location_access_section = [list_row(title: "Camera", image: "Settings-Camera", content: AnyView(location_services_top_content()), destination: nil)]
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack {
                        Spacer().frame(height:20)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: location_services_top_section)
                        Text("Allow the apps below to determine your\n approximate location.").multilineTextAlignment(.center).lineLimit(nil).fixedSize(horizontal: false, vertical: true).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Regular", fixedSize: 15)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24).frame(maxHeight: .infinity)
                        Spacer().frame(height:15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: location_access_section)
                    }
                }
            }
        }
    }
}

struct location_services_top_content: View {
    var body: some View {
        HStack {
            toggle().padding(.trailing, 12)
        }
    }
}

struct location_content: View {
    @ObservedObject var locationProvider : LocationProvider
    @State var location_access: Bool
    init() {
        _location_access = State(initialValue:true)
        locationProvider = LocationProvider()
        do {try locationProvider.start();}
        catch {
            print("No location access.")
            _location_access = State(initialValue: false)
            locationProvider.requestAuthorization()
        }
    }
    var body: some View {
        HStack {
            Text(location_access ? "On" : "Off").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255))
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}


//**MARK: Carrier Views

struct carrier_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var carrier_top_section = [list_row(title: "Automatic", image: nil, content: AnyView(carrier_top_content()), destination:nil, selected: true)]
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack {
                        Spacer().frame(height:20)
                        HStack {
                            Text("Carriers").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section_blue(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: carrier_top_section)
                    }
                }
            }
        }
    }
}

struct carrier_top_content: View {
    var body: some View {
        HStack {
            Image("TWPickerTableCellChecked").resizable().frame(width:15, height: 15).padding(.trailing, 12)
        }
    }
}

struct carrier_content: View {
    var body: some View {
        HStack {
            Spacer()
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}

//**MARK: Sounds Views
struct sounds_view : View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var sounds_top_section = [list_row(title: "Vibrate", image: nil, content: AnyView(sounds_top_content()), destination:nil, selected: true)]
    var sounds_slider_section = [list_row(title: "", image: nil, content: AnyView(sounds_slider_content()), destination:nil, selected: true),list_row(title: "Change with Buttons", image: nil, content: AnyView(sounds_slider_toggle_content()), destination:nil, selected: true)]
    var sounds_bottom_section = [list_row(title: "Vibrate", image: nil, content: AnyView(sounds_top_content()), destination:nil, selected: true), list_row(title: "Ringtone", image: nil, content: AnyView(ringtone_content()), destination:nil, selected: true), list_row(title: "Text Tone", image: nil, content: AnyView(texttone_content()), destination:nil, selected: true), list_row(title: "New Voicemail", image: nil, content: AnyView(sounds_top_content()), destination:nil, selected: true), list_row(title: "New Mail", image: nil, content: AnyView(sounds_top_content()), destination:nil, selected: true), list_row(title: "Sent Mail", image: nil, content: AnyView(sounds_top_content()), destination:nil, selected: true), list_row(title: "Calendar Alerts", image: nil, content: AnyView(sounds_top_content()), destination:nil, selected: true),list_row(title: "Lock Sounds", image: nil, content: AnyView(sounds_top_content()), destination:nil, selected: true), list_row(title: "Keyboard Clicks", image: nil, content: AnyView(sounds_top_content()), destination:nil, selected: true)]
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack {
                        Spacer().frame(height:20)
                        HStack {
                            Text("Silent").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: sounds_top_section)
                        Spacer().frame(height:20)
                        HStack {
                            Text("Ringer and Alerts").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: sounds_slider_section)
                        Text("The volume of the ringer and alerts can\n be adjusted using the volume buttons.").multilineTextAlignment(.center).lineLimit(nil).fixedSize(horizontal: false, vertical: true).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Regular", fixedSize: 15)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24).frame(maxHeight: .infinity)
                        Spacer().frame(height:15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: sounds_bottom_section)
                        Spacer().frame(height: 15)
                    }
                }
            }
        }
    }
}

struct sounds_content: View {
    var body: some View {
        HStack {
            Spacer()
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}

struct sounds_top_content: View {
    var body: some View {
        HStack {
            toggle().padding(.trailing, 12)
        }
    }
}

struct ringtone_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text("Marimba").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255))
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}

struct texttone_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text("Tri-tone").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255))
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}

struct sounds_slider_content: View {
    @ObservedObject private var volObserver = VolumeObserver()
    var body: some View {
        HStack {
            Image("SpeakerMute").padding([.top, .bottom, .leading])
            CustomSlider(type: "Volume", value: $volObserver.volume.double,  range: (0, 100)) { modifiers in
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [Color(red: 47/255, green: 100/255, blue: 183/255), Color(red: 119/255, green: 173/255, blue: 246/255)]), startPoint: .top, endPoint: .bottom).innerShadowSlider(color: Color(red: 17/255, green: 63/255, blue: 139/255).opacity(0.67), radius: 0.2).innerShadowBottomView(color: Color(red: 70/255, green: 124/255, blue: 192/255), radius: 0.2).frame(height: 8.5).cornerRadius(4.25).overlay(RoundedRectangle(cornerRadius: 4.25).stroke(Color.gray, lineWidth: 0.25).frame(height:8.5)).modifier(modifiers.barLeft)
                    LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 180/255, green: 180/255, blue: 180/255), location: 0), .init(color: Color(red: 250/255, green: 250/255, blue: 250/255), location: 0.55)]), startPoint: .top, endPoint: .bottom).innerShadowSliderRight(color: Color.black.opacity(0.28), radius: 0.2).innerShadowBottomView(color: Color.black.opacity(0.2), radius: 0.15).frame(height: 8.5).cornerRadius(4.25).overlay(RoundedRectangle(cornerRadius: 4.25)    .stroke(Color.gray, lineWidth: 0.25).frame(height:8.5)).modifier(modifiers.barRight)
                    ZStack {
                        Circle().fill(LinearGradient(gradient: Gradient(colors: [Color(red: 166/255, green: 166/255, blue: 166/255), Color(red: 252/255, green: 252/255, blue: 252/255)]), startPoint: .top, endPoint: .bottom)).shadow(color: Color.black.opacity(0.56), radius: 1, x: 0, y: 1).overlay(Circle().trim(from: 0.05, to: 0.45).stroke(Color.white.opacity(0.8), lineWidth:0.4).scaleEffect(0.96) .rotationEffect(.degrees(-180)).blur(0.35))
                        Circle().stroke(Color.gray, lineWidth: 0.25)
                    }.modifier(modifiers.knob)
                }
            }.frame(height: 21).padding([.top, .bottom]).padding([.leading, .trailing], 2)
            Image("SpeakerMax").padding([.top, .bottom, .trailing])
        }
        
    }
}

struct sounds_slider_toggle_content: View {
    var body: some View {
        HStack {
            toggle().padding(.trailing, 12)
        }
    }
}

//**MARK: Brightness Views

struct brightness_view : View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var brightness_slider_section = [list_row(title: "", image: nil, content: AnyView(brightness_slider_content()), destination:nil, selected: true),list_row(title: "Auto-Brightness", image: nil, content: AnyView(brightness_slider_toggle_content()), destination:nil, selected: true)]
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack {
                        Spacer().frame(height:20)
                        list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: brightness_slider_section)
                    }
                }
            }
        }
    }
}

struct brightness_content: View {
    var body: some View {
        HStack {
            Spacer()
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}


struct brightness_slider_toggle_content: View {
    var body: some View {
        HStack {
            toggle().padding(.trailing, 12)
        }
    }
}

struct brightness_slider_content: View {
    @ObservedObject private var briObserver = BrightnessObserver()
    var body: some View {
        HStack {
            Image("LessBright").padding([.top, .bottom, .leading])
            CustomSlider(type: "Brightness", value: $briObserver.brightness.double, range: (0, 100)) { modifiers in
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [Color(red: 47/255, green: 100/255, blue: 183/255), Color(red: 119/255, green: 173/255, blue: 246/255)]), startPoint: .top, endPoint: .bottom).innerShadowSlider(color: Color(red: 17/255, green: 63/255, blue: 139/255).opacity(0.67), radius: 0.2).innerShadowBottomView(color: Color(red: 70/255, green: 124/255, blue: 192/255), radius: 0.2).frame(height: 8.5).cornerRadius(4.25).overlay(RoundedRectangle(cornerRadius: 4.25).stroke(Color.gray, lineWidth: 0.25).frame(height:8.5)).modifier(modifiers.barLeft)
                    LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 180/255, green: 180/255, blue: 180/255), location: 0), .init(color: Color(red: 250/255, green: 250/255, blue: 250/255), location: 0.55)]), startPoint: .top, endPoint: .bottom).innerShadowSliderRight(color: Color.black.opacity(0.28), radius: 0.2).innerShadowBottomView(color: Color.black.opacity(0.2), radius: 0.15).frame(height: 8.5).cornerRadius(4.25).overlay(RoundedRectangle(cornerRadius: 4.25)    .stroke(Color.gray, lineWidth: 0.25).frame(height:8.5)).modifier(modifiers.barRight)
                    ZStack {
                        Circle().fill(LinearGradient(gradient: Gradient(colors: [Color(red: 166/255, green: 166/255, blue: 166/255), Color(red: 252/255, green: 252/255, blue: 252/255)]), startPoint: .top, endPoint: .bottom)).shadow(color: Color.black.opacity(0.56), radius: 1, x: 0, y: 1).overlay(Circle().trim(from: 0.05, to: 0.45).stroke(Color.white.opacity(0.8), lineWidth:0.4).scaleEffect(0.96) .rotationEffect(.degrees(-180)).blur(0.35))
                        Circle().stroke(Color.gray, lineWidth: 0.25)
                    }.modifier(modifiers.knob)
                }
            }.frame(height: 21).padding([.top, .bottom]).padding([.leading, .trailing], 2)
            Image("MoreBright").padding([.top, .bottom, .trailing])
        }
        
    }
}

//**MARK: Wallpaper Views

struct wallpaper_content: View {
    var body: some View {
        HStack {
            Spacer()
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}


struct wallpaper_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @ObservedObject var photos_obsever: SettingsPhotosObserver
    var userDefaults = UserDefaults.standard
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack {
                        Spacer().frame(height: 20)
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                            .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25))
                            VStack(spacing:0) {
                                Button(action: {forward_or_backward = false; DispatchQueue.main.asyncAfter(deadline:.now()+0.3){ withAnimation(.linear(duration: 0.28)) {current_nav_view = "Wallpaper_Select"}}}) {
                                    ZStack {
                                        HStack {
                                            ZStack {
                                                if userDefaults.bool(forKey: "Camera_Wallpaper_Lock") == false {
                                                Image(userDefaults.string(forKey: "Lock_Wallpaper") ?? "Wallpaper_1").resizable().aspectRatio(contentMode: .fill).frame(width: 113, height: 164).clipped()
                                                } else {
                                                    Image(uiImage: (UIImage(data: userDefaults.object(forKey: "Lock_Wallpaper") as? Data ?? Data()) ?? UIImage(named: "Wallpaper_1"))!).resizable().aspectRatio(contentMode: .fill).frame(width: 113, height: 164).clipped()
                                                }
                                                Image("lockScreenOverlay")
                                            }.padding(.leading, 32)
                                            Spacer()
                                            ZStack {
                                                if userDefaults.bool(forKey: "Camera_Wallpaper_Home") == false {
                                                Image(userDefaults.string(forKey: "Home_Wallpaper") ?? "Wallpaper_1").resizable().aspectRatio(contentMode: .fill).frame(width: 113, height: 164).clipped()
                                                } else {
                                                    Image(uiImage: (UIImage(data: userDefaults.object(forKey: "Home_Wallpaper") as? Data ?? Data()) ?? UIImage(named: "Wallpaper_1"))!).resizable().aspectRatio(contentMode: .fill).frame(width: 113, height: 164).clipped()
                                                }
                                                Image("homeScreenOverlay")
                                            }.padding(.trailing, 32)
                                        }
                                        HStack {
                                            Spacer()
                                            Image("UITableNext").padding(.trailing, 12)
                                        }
                                    }.padding([.top, .bottom], 20)
                                }
                            }
                            
                        }
                        .padding([.leading, .trailing], 12)
                    }
                    
                }
            }
        }.onAppear() {
            if photos_obsever.photo_count == 0 {
                photos_obsever.fetch_photos()
            }
        }
    }
}

struct wallpaper_select_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var last_photo: UIImage
    var userDefaults = UserDefaults.standard
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack {
                        Spacer().frame(height: 20)
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                            .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25))
                            VStack(spacing:0) {
                                Button(action: {forward_or_backward = false; DispatchQueue.main.asyncAfter(deadline:.now()+0.3){ withAnimation(.linear(duration: 0.28)) {current_nav_view = "Wallpaper_Grid"}}}) {
                                    ZStack {
                                        HStack {
                                            Image("Wallpaper_21").resizable().aspectRatio(contentMode: .fill).frame(width: 60, height: 60).cornerRadiusSpecific(radius: 10, corners: [.topLeft, .bottomLeft]).scaleEffect(0.985)
                                            Text("Wallpaper").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black)
                                            Spacer()
                                            Image("UITableNext").padding(.trailing, 12)
                                        }                                        }
                                }
                            }
                        }
                        
                        .frame(height: 60) .padding([.leading, .trailing], 12)
                        Spacer().frame(height:25)
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                            .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25))
                            VStack(spacing:0) {
                                Button(action: {forward_or_backward = false; DispatchQueue.main.asyncAfter(deadline:.now()+0.3){ withAnimation(.linear(duration: 0.28)) {current_nav_view = "Wallpaper_Grid_Camera_Roll"}}}) {
                                    ZStack {
                                        HStack {
                                            Image(uiImage: last_photo).resizable().aspectRatio(contentMode: .fill).frame(width: 60, height: 60).cornerRadiusSpecific(radius: 10, corners: [.topLeft, .bottomLeft]).scaleEffect(0.985)
                                            Text("Camera Roll").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black)
                                            Spacer()
                                            Image("UITableNext").padding(.trailing, 12)
                                        }                                        }
                                }
                            }
                        }
                        
                        .frame(height: 60) .padding([.leading, .trailing], 12)
                    }
                    
                }
            }
        }
    }
}

class SettingsPhotosObserver: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    @Published private(set) var photo_count = 0
    private var isLoadingPage = false
    private(set) var isLoadingSelection = false
    private(set) var selectionProgress: Double = 0
    @Published var message: String?
    let imageManager = PHCachingImageManager()
    let thumbnails = NSCache<NSString,UIImage>()
    private let queue = DispatchQueue(label:"OldOS.Wallpaper.Photos",qos:.userInitiated)
    private var result: PHFetchResult<PHAsset>?
    private var fetched = false
    private var observing = false
    private var requestingAccess = false
    private var refreshPending = false
    private var generation = UUID()
    private var selectionToken = UUID()
    private var selectionRequest = PHInvalidImageRequestID
    override init() {
        super.init()
        thumbnails.countLimit = 256; thumbnails.totalCostLimit = 32*1024*1024
        imageManager.allowsCachingHighQualityImages = false
    }
    deinit {
        if observing { PHPhotoLibrary.shared().unregisterChangeObserver(self) }
        if selectionRequest != PHInvalidImageRequestID { imageManager.cancelImageRequest(selectionRequest) }
    }
    func fetch_photos(force:Bool=false) {
        if isLoadingPage { refreshPending = refreshPending || force; return }
        guard force || !fetched else { return }
        let authorization = PHPhotoLibrary.authorizationStatus(for:.readWrite)
        if authorization == .notDetermined {
            guard !requestingAccess else { return }
            requestingAccess = true
            PHPhotoLibrary.requestAuthorization(for:.readWrite) { [weak self] _ in
                DispatchQueue.main.async { self?.requestingAccess = false; self?.fetch_photos(force:true) }
            }
            return
        }
        guard authorization == .authorized || authorization == .limited else {
            message = "Allow OldOS access to Photos in your iPhone’s Settings to choose a wallpaper."
            return
        }
        if !observing { PHPhotoLibrary.shared().register(self); observing = true }
        isLoadingPage = true
        let token = UUID(); generation = token
        queue.async { [weak self] in
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key:"creationDate",ascending:true)]
            let result = PHAsset.fetchAssets(with:.image,options:options)
            DispatchQueue.main.async {
                guard let self, self.generation == token else { return }
                self.result = result; self.photo_count = result.count
                self.fetched = true; self.isLoadingPage = false
                if self.refreshPending { self.refreshPending = false; self.fetch_photos(force:true) }
            }
        }
    }
    func asset(at index:Int) -> PHAsset? {
        guard let result, index >= 0, index < result.count else { return nil }
        return result.object(at:index)
    }
    func photoLibraryDidChange(_ changeInstance:PHChange) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.thumbnails.removeAllObjects(); self.imageManager.stopCachingImagesForAllAssets()
            self.fetch_photos(force:true)
        }
    }
    func cancelSelection() {
        selectionToken = UUID()
        if selectionRequest != PHInvalidImageRequestID { imageManager.cancelImageRequest(selectionRequest) }
        selectionRequest = PHInvalidImageRequestID; isLoadingSelection = false; selectionProgress = 0
    }
    func select(_ asset:PHAsset,completion:@escaping(UIImage)->Void) {
        cancelSelection(); message = nil
        isLoadingSelection = true
        let token = selectionToken
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true; options.isSynchronous = false
        options.deliveryMode = .highQualityFormat; options.resizeMode = .exact; options.version = .current
        options.progressHandler = { [weak self] progress,_,_,_ in
            DispatchQueue.main.async {
                guard let self, self.selectionToken == token else { return }
                self.selectionProgress = progress
            }
        }
        let longest = max(1,max(asset.pixelWidth,asset.pixelHeight))
        let scale = min(1,4096/Double(longest))
        let target = CGSize(width:max(1,Double(asset.pixelWidth)*scale),height:max(1,Double(asset.pixelHeight)*scale))
        selectionRequest = imageManager.requestImage(for:asset,targetSize:target,contentMode:.aspectFit,options:options) { [weak self] image,info in
            DispatchQueue.main.async {
                guard let self, self.selectionToken == token else { return }
                let failed = (info?[PHImageCancelledKey] as? Bool) == true || info?[PHImageErrorKey] != nil
                guard failed || (info?[PHImageResultIsDegradedKey] as? Bool) != true else { return }
                self.selectionToken = UUID(); self.selectionRequest = PHInvalidImageRequestID; self.isLoadingSelection = false
                guard !failed, let image, image.size.width > 0, image.size.height > 0 else {
                    self.message = "This photo could not be loaded. If it is stored in iCloud, check your connection and try again."
                    return
                }
                completion(image)
            }
        }
    }
}

private struct SettingsWallpaperThumbnail: View {
    let asset: PHAsset
    @ObservedObject var library: SettingsPhotosObserver
    @State private var image: UIImage?
    @State private var request = PHInvalidImageRequestID
    @State private var token = UUID()
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(white:0.9)
                if let image { Image(uiImage:image).resizable().scaledToFill() }
            }.frame(width:geometry.size.width,height:geometry.size.height).clipped()
                .onAppear { load(width:geometry.size.width) }
                .onChange(of:asset.localIdentifier) { _ in cancel(); load(width:geometry.size.width) }
                .onChange(of:asset.modificationDate) { _ in cancel(); load(width:geometry.size.width) }
                .onDisappear(perform:cancel)
        }
    }
    private func load(width:CGFloat) {
        let pixels = min(512,max(48,Int(ceil(width*UIScreen.main.scale))))
        let key = "\(asset.localIdentifier)-\(asset.modificationDate?.timeIntervalSince1970 ?? 0)-\(pixels)" as NSString
        if let cached = library.thumbnails.object(forKey:key) { image = cached; return }
        let activeToken = UUID(); token = activeToken
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true; options.isSynchronous = false
        options.deliveryMode = .opportunistic; options.resizeMode = .fast
        request = library.imageManager.requestImage(for:asset,targetSize:CGSize(width:pixels,height:pixels),contentMode:.aspectFill,options:options) { loaded,info in
            DispatchQueue.main.async {
                guard token == activeToken, let loaded else { return }
                image = loaded
                if (info?[PHImageResultIsDegradedKey] as? Bool) != true {
                    library.thumbnails.setObject(loaded,forKey:key,cost:loaded.cgImage.map{$0.bytesPerRow*$0.height} ?? pixels*pixels*4)
                    request = PHInvalidImageRequestID
                }
            }
        }
    }
    private func cancel() {
        token = UUID()
        if request != PHInvalidImageRequestID { library.imageManager.cancelImageRequest(request) }
        request = PHInvalidImageRequestID; image = nil
    }
}

struct wallpaper_grid_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var wallpaper: String
    @Binding var show_wallpaper_select: Bool
    var userDefaults = UserDefaults.standard
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
                    LazyVGrid(columns: columns, spacing: 5) {
                        ForEach(1...27, id: \.self) { num in
                            GeometryReader { proxy in
                                Button(action: {
                                    wallpaper = "Wallpaper_\(num)"
                                    withAnimation() {
                                        show_wallpaper_select = true
                                    }
                                }) {
                                    Image("Wallpaper_\(num)").resizable().scaledToFill().frame(height: proxy.size.width).position(x: proxy.frame(in: .local).midX, y: proxy.frame(in: .local).midY)
                                }
                            } .clipped().innerShadowFull(color: Color.gray.opacity(0.8), radius: 0.02)
                            .aspectRatio(1, contentMode: .fit)
                        }
                    }.padding(8)
                    
                }
            }
        }
    }
}

private struct SettingsWallpaperAssetCell: View {
    let index: Int
    @ObservedObject var library: SettingsPhotosObserver
    let select: (PHAsset)->Void
    var body: some View {
        GeometryReader { proxy in
            if let asset = library.asset(at:index) {
                Button { select(asset) } label: {
                    SettingsWallpaperThumbnail(asset:asset,library:library)
                        .frame(width:proxy.size.width,height:proxy.size.width)
                        .id(asset.localIdentifier)
                }.buttonStyle(NoButtonStyle())
            }
        }.clipped().innerShadowFull(color:Color.gray.opacity(0.8),radius:0.02)
            .aspectRatio(1,contentMode:.fit)
    }
}

struct wallpaper_grid_view_camera_roll: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var wallpaper_camera_roll: UIImage?
    @Binding var show_wallpaper_select_camera_roll: Bool
    @ObservedObject var photos_obsever: SettingsPhotosObserver
    @State private var positionedInitially = false
    private let columns = Array(repeating:GridItem(.flexible(minimum:60)),count:4)
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            ScrollViewReader { reader in
                ScrollView {
                    VStack(spacing:0) {
                        LazyVGrid(columns:columns,spacing:5) {
                            ForEach(0..<photos_obsever.photo_count,id:\.self) { index in
                                SettingsWallpaperAssetCell(index:index,library:photos_obsever) { asset in
                                    photos_obsever.select(asset) { image in
                                        wallpaper_camera_roll = image
                                        withAnimation { show_wallpaper_select_camera_roll = true }
                                    }
                                }
                            }
                        }.padding(8)
                        HStack {
                            Spacer()
                            Text("\(photos_obsever.photo_count) Photos")
                                .font(.custom("Helvetica Neue Regular",fixedSize:20)).foregroundColor(.cgLightGray).lineLimit(1)
                            Spacer()
                        }.padding(.bottom,12).id("wallpaper_camera_roll_bottom")
                    }
                }
                .onAppear { positionAtRecentPhotos(reader) }
                .onChange(of:photos_obsever.photo_count) { _ in positionAtRecentPhotos(reader) }
            }
        }.onAppear { photos_obsever.fetch_photos() }
            .onDisappear { photos_obsever.cancelSelection() }
    }
    private func positionAtRecentPhotos(_ reader:ScrollViewProxy) {
        guard !positionedInitially, photos_obsever.photo_count > 0 else { return }
        DispatchQueue.main.async {
            guard !positionedInitially, photos_obsever.photo_count > 0 else { return }
            var transaction = Transaction(); transaction.disablesAnimations = true
            withTransaction(transaction) { reader.scrollTo("wallpaper_camera_roll_bottom",anchor:.bottom) }
            positionedInitially = true
        }
    }
}

struct wallpaper_set_view : View {
    @Binding var wallpaper: String
    @Binding var show_wallpaper_select: Bool
    @State var show_select_final: Bool = false
    @State var show_overlay: Bool = false
    @State var show_check: Bool = false
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(wallpaper).resizable().aspectRatio(contentMode: .fill).frame(height:geometry.size.height).cornerRadius(0).frame(width: geometry.size.width, height: geometry.size.height, alignment: .center).clipped()
                VStack {
                    Spacer()
                    if wallpaper == "Wallpaper_1" {
                        LinearGradient(gradient:Gradient(colors: [Color(red: 158/255, green: 158/255, blue: 158/255).opacity(0.0), Color(red: 34/255, green: 34/255, blue: 34/255)]), startPoint: .top, endPoint: .bottom).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: geometry.size.height/3.75, maxHeight: geometry.size.height/3.75, alignment: .center).clipped()
                    }else {
                        LinearGradient(gradient:Gradient(colors: [Color(red: 34/255, green: 34/255, blue: 34/255).opacity(0.0), Color(red: 24/255, green: 24/255, blue: 24/255).opacity(0.85)]), startPoint: .top, endPoint: .bottom).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: geometry.size.height/4.25, maxHeight: geometry.size.height/4.25, alignment: .center).clipped()
                    }
                }
                VStack(spacing:0) {
                    status_bar(locked: false).frame(minHeight: 24, maxHeight:24).zIndex(1)
                    wallpaper_header().frame(minHeight: 110, maxHeight:110).zIndex(0).clipped()
                    Spacer()
                    wallpaper_footer(wallpaper: wallpaper, show_wallpaper_select: $show_wallpaper_select, show_select_final: $show_select_final).frame(minHeight: 110, maxHeight:110).clipped().clipped()
                }
                if show_select_final {
                    VStack(spacing:0) {
                        Spacer().foregroundColor(.clear).zIndex(0)
                        wallpaper_select_final(wallpaper: wallpaper, show_wallpaper_select: $show_wallpaper_select, show_select_final: $show_select_final, show_overlay: $show_overlay, show_check: $show_check).frame(minHeight: geometry.size.height/2, maxHeight: geometry.size.height/2).zIndex(1)
                    }.transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom))).zIndex(1)
                }
            } .if(show_overlay) { content in
                content.overlay(
                    ZStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.65))
                            VStack {
                                if show_check {
                                    Image(systemName: "checkmark").foregroundColor(.white).font(.system(size: 26, weight: .bold)).padding(.top, 9)
                                } else {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).padding([.bottom], 5).padding(.top, 10).scaleEffect(1.75, anchor: .center)
                                }
                                Text("Saving Photo").foregroundColor(.white).font(.custom("Helvetica Neue Bold", fixedSize: 24)).padding(.bottom, 2.5).padding(.top, 8)
                            }
                        }.padding([.leading, .trailing], 95).frame(height: 115)
                    }
                )
            }.disabled(show_overlay)
        }
    }
}

struct wallpaper_set_view_camera_roll : View {
    var wallpaper = "" //Fix later -> too lazy now
    @Binding var wallpaper_camera_roll: UIImage?
    @Binding var show_wallpaper_select_camera_roll: Bool
    @State var show_wallpaper_select: Bool = false
    @State  var originalImage: UIImage?
    @State  var zoom: CGFloat?
    @State  var position: CGSize?
    @State  var finalImage: UIImage?
    @State  var inputImage: UIImage?
    @State var show_select_final: Bool = false
    @State var show_overlay: Bool = false
    @State var show_check: Bool = false
    @State var execute_process: Bool = false
    @State var to_set:[String] = []
    @State private var saveError: String?
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ImageMoveAndScale(originalImage: $originalImage, originalPosition: $position, originalZoom: $zoom, processedImage: $finalImage, inputImage: $wallpaper_camera_roll, execute_process: $execute_process, to_set: $to_set, geometryProxy: geometry,onComplete:wallpaperSaved)
                VStack {
                    Spacer()
                    if wallpaper == "Wallpaper_1" {
                        LinearGradient(gradient:Gradient(colors: [Color(red: 158/255, green: 158/255, blue: 158/255).opacity(0.0), Color(red: 34/255, green: 34/255, blue: 34/255)]), startPoint: .top, endPoint: .bottom).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: geometry.size.height/3.75, maxHeight: geometry.size.height/3.75, alignment: .center).clipped()
                    }else {
                        LinearGradient(gradient:Gradient(colors: [Color(red: 34/255, green: 34/255, blue: 34/255).opacity(0.0), Color(red: 24/255, green: 24/255, blue: 24/255).opacity(0.85)]), startPoint: .top, endPoint: .bottom).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: geometry.size.height/4.25, maxHeight: geometry.size.height/4.25, alignment: .center).clipped()
                    }
                }
                VStack(spacing:0) {
                    status_bar(locked: false).frame(minHeight: 24, maxHeight:24).zIndex(1)
                    wallpaper_header_camera_roll().frame(minHeight: 110, maxHeight:110).zIndex(0).clipped()
                    Spacer()
                    wallpaper_footer(wallpaper: wallpaper, show_wallpaper_select: $show_wallpaper_select_camera_roll, show_select_final: $show_select_final).frame(minHeight: 110, maxHeight:110).clipped().clipped()
                }
                if show_select_final {
                    VStack(spacing:0) {
                        Spacer().foregroundColor(.clear).zIndex(0)
                        wallpaper_select_final_camera_roll(wallpaper: wallpaper, show_wallpaper_select: $show_wallpaper_select_camera_roll, show_select_final: $show_select_final, show_overlay: $show_overlay, show_check: $show_check, execute_process: $execute_process, to_set: $to_set).frame(minHeight: geometry.size.height/2, maxHeight: geometry.size.height/2).zIndex(1)
                    }.transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom))).zIndex(1)
                }
                if show_overlay {
                    ZStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.65))
                            VStack {
                                if show_check {
                                    Image(systemName: "checkmark").foregroundColor(.white).font(.system(size: 26, weight: .bold)).padding(.top, 9)
                                } else {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).padding([.bottom], 5).padding(.top, 10).scaleEffect(1.75, anchor: .center)
                                }
                                Text("Saving Photo").foregroundColor(.white).font(.custom("Helvetica Neue Bold", fixedSize: 24)).padding(.bottom, 2.5).padding(.top, 8)
                            }
                        }.padding([.leading, .trailing], 95).frame(height: 115)
                    }
                }
            }.disabled(show_overlay)
                .overlay {
                    if let saveError {
                        ZStack { Color.black.opacity(0.35); skeumorphic_alert(title:"Wallpaper",subtitle:saveError,dismiss_action:{self.saveError=nil}) }
                    }
                }
        }.onDisappear { show_overlay = false; show_check = false; execute_process = false }
    }
    private func wallpaperSaved(_ result:Result<Void,Error>) {
        switch result {
        case .success:
            show_check = true
            DispatchQueue.main.asyncAfter(deadline:.now()+0.35) {
                withAnimation { show_wallpaper_select_camera_roll = false }
            }
        case .failure(let error):
            show_overlay = false; show_check = false; execute_process = false; saveError = error.localizedDescription
        }
    }
}

struct wallpaper_header: View {
    private let text_color = LinearGradient([.white, .white], to: .trailing)
    var body: some View {
        ZStack {
            Color.black.opacity(0.65).overlay(Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.21), Color.white.opacity(0.085)]), startPoint: .top, endPoint: .bottom)).frame(height:55).offset(y: -27)).border_top(width: 0.75, edges:[.top, .bottom], color: Color.black) .innerShadow(color: Color.white.opacity(0.24), radius: 0.03)
            HStack {
                Spacer()
                VStack() {
                    Text("Wallpaper Preview").foregroundColor(.white).font(.custom("Helvetica Neue Bold", fixedSize: 24)).shadow(color: Color.black.opacity(0.92), radius: 0, x: 0.0, y: -1.2)
                }
                Spacer()
                
            }.padding([.leading, .trailing], 4)
        }
    }
}

struct wallpaper_header_camera_roll: View {
    private let text_color = LinearGradient([.white, .white], to: .trailing)
    var body: some View {
        ZStack {
            Color.black.opacity(0.65).overlay(Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.21), Color.white.opacity(0.085)]), startPoint: .top, endPoint: .bottom)).frame(height:55).offset(y: -27)).border_top(width: 0.75, edges:[.top, .bottom], color: Color.black) .innerShadow(color: Color.white.opacity(0.24), radius: 0.03)
            HStack {
                Spacer()
                VStack() {
                    Text("Move and Scale").foregroundColor(.white).font(.custom("Helvetica Neue Bold", fixedSize: 22)).shadow(color: Color.black.opacity(0.92), radius: 0, x: 0.0, y: -1.2)
                }
                Spacer()
                
            }.padding([.leading, .trailing], 4)
        }
    }
}

struct wallpaper_footer: View {
    var wallpaper: String
    var userDefaults = UserDefaults.standard
    @Binding var show_wallpaper_select: Bool
    @Binding var show_select_final: Bool
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                VStack(spacing:0) {
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 41/255, green: 40/255, blue: 40/255).opacity(0.6), Color.init(red: 21/255, green: 20/255, blue: 20/255).opacity(0.65)]), startPoint: .top, endPoint: .bottom)).innerShadowBottom(color: Color.white.opacity(0.6), radius: 0.05).border_top(width: 1, edges:[.top], color: Color.black)
                    Rectangle().fill(Color.black.opacity(0.835))
                }
                HStack(spacing: 20) {
                    Button(action:{
                        withAnimation() {
                            show_wallpaper_select = false
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5))
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 124/255, green: 124/255, blue: 124/255), location: 0), .init(color: Color(red: 26/255, green: 26/255, blue: 26/255), location: 0.50), .init(color: Color(red: 0/255, green: 0/255, blue: 0/255), location: 0.53), .init(color: Color(red: 0/255, green: 0/255, blue: 0/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.gray.opacity(0.9), Color.gray.opacity(0.35)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Cancel").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0.0, y: -0.9)
                        }.padding([.leading], 25).padding([.top, .bottom], 28)
                    }
                    Button(action:{
                        withAnimation(.linear(duration: 0.4)) {
                            show_select_final = true
                        }
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5))
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 235/255, green: 235/255, blue: 236/255), location: 0), .init(color: Color(red: 208/255, green: 209/255, blue: 211/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Set").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.black).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.padding([.trailing], 25).padding([.top, .bottom], 28)
                    }
                }
            }
        }
    }
}

struct wallpaper_select_final: View {
    var wallpaper: String
    var userDefaults = UserDefaults.standard
    @Binding var show_wallpaper_select: Bool
    @Binding var show_select_final: Bool
    @Binding var show_overlay: Bool
    @Binding var show_check: Bool
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                VStack(spacing:0) {
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 101/255, green: 100/255, blue: 100/255).opacity(0.88), Color.init(red: 31/255, green: 30/255, blue: 30/255).opacity(0.88)]), startPoint: .top, endPoint: .bottom)).innerShadowBottom(color: Color.white.opacity(0.98), radius: 0.1).border_top(width: 1, edges:[.top], color: Color.black).frame(height:30)
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 21/255, green: 20/255, blue: 20/255).opacity(0.88), Color.black.opacity(0.9)]), startPoint: .top, endPoint: .bottom))
                }
                VStack {
                    Button(action:{
                        userDefaults.set(wallpaper, forKey: "Lock_Wallpaper")
                        UserDefaults.standard.set(false, forKey: "Camera_Wallpaper_Lock")
                        show_overlay = true
                        withAnimation(.linear(duration: 0.4)) {
                            show_select_final = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now()+1.25) {
                            show_check = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now()+2) {
                            withAnimation() {
                                show_wallpaper_select = false
                            }
                        }
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5))
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 235/255, green: 235/255, blue: 236/255), location: 0), .init(color: Color(red: 208/255, green: 209/255, blue: 211/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Set Lock Screen").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.black).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.bottom], 2.5).padding(.top, 28)
                    Button(action:{
                        userDefaults.set(wallpaper, forKey: "Home_Wallpaper")
                        UserDefaults.standard.set(false, forKey: "Camera_Wallpaper_Home")
                        show_overlay = true
                        withAnimation(.linear(duration: 0.4)) {
                            show_select_final = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now()+1.25) {
                            show_check = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now()+2) {
                            withAnimation() {
                                show_wallpaper_select = false
                            }
                        }
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5))
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 235/255, green: 235/255, blue: 236/255), location: 0), .init(color: Color(red: 208/255, green: 209/255, blue: 211/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Set Home Screen").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.black).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.top, .bottom], 2.5)
                    Button(action:{
                        userDefaults.set(wallpaper, forKey: "Lock_Wallpaper")
                        userDefaults.set(wallpaper, forKey: "Home_Wallpaper")
                        UserDefaults.standard.set(false, forKey: "Camera_Wallpaper_Lock")
                        UserDefaults.standard.set(false, forKey: "Camera_Wallpaper_Home")
                        show_overlay = true
                        withAnimation(.linear(duration: 0.4)) {
                            show_select_final = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now()+1.25) {
                            show_check = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now()+2) {
                            withAnimation() {
                                show_wallpaper_select = false
                            }
                        }
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5))
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 235/255, green: 235/255, blue: 236/255), location: 0), .init(color: Color(red: 208/255, green: 209/255, blue: 211/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Set Both").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.black).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.top, .bottom], 2.5)
                    Spacer()
                    Button(action:{
                        withAnimation(.linear(duration: 0.4)) {
                            show_select_final = false
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5)).opacity(0.6)
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 124/255, green: 124/255, blue: 124/255), location: 0), .init(color: Color(red: 26/255, green: 26/255, blue: 26/255), location: 0.50), .init(color: Color(red: 0/255, green: 0/255, blue: 0/255), location: 0.53), .init(color: Color(red: 0/255, green: 0/255, blue: 0/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.gray.opacity(0.9), Color.gray.opacity(0.35)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3).opacity(0.6)
                            Text("Cancel").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0.0, y: -0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.bottom], 25)
                }
            }
        }
    }
}

struct wallpaper_select_final_camera_roll: View {
    var wallpaper: String
    var userDefaults = UserDefaults.standard
    @Binding var show_wallpaper_select: Bool
    @Binding var show_select_final: Bool
    @Binding var show_overlay: Bool
    @Binding var show_check: Bool
    @Binding var execute_process: Bool
    @Binding var to_set:[String]
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                VStack(spacing:0) {
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 101/255, green: 100/255, blue: 100/255).opacity(0.88), Color.init(red: 31/255, green: 30/255, blue: 30/255).opacity(0.88)]), startPoint: .top, endPoint: .bottom)).innerShadowBottom(color: Color.white.opacity(0.98), radius: 0.1).border_top(width: 1, edges:[.top], color: Color.black).frame(height:30)
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 21/255, green: 20/255, blue: 20/255).opacity(0.88), Color.black.opacity(0.9)]), startPoint: .top, endPoint: .bottom))
                }
                VStack {
                    Button(action:{
                      //  userDefaults.set(wallpaper, forKey: "Lock_Wallpaper")
                        to_set = ["Lock"]
                        show_check = false
                        execute_process = true
                        show_overlay = true
                        withAnimation(.linear(duration: 0.4)) {
                            show_select_final = false
                        }
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5))
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 235/255, green: 235/255, blue: 236/255), location: 0), .init(color: Color(red: 208/255, green: 209/255, blue: 211/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Set Lock Screen").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.black).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.bottom], 2.5).padding(.top, 28)
                    Button(action:{
                        to_set = ["Home"]
                        show_check = false
                        execute_process = true
                        show_overlay = true
                        withAnimation(.linear(duration: 0.4)) {
                            show_select_final = false
                        }
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5))
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 235/255, green: 235/255, blue: 236/255), location: 0), .init(color: Color(red: 208/255, green: 209/255, blue: 211/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Set Home Screen").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.black).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.top, .bottom], 2.5)
                    Button(action:{
                        to_set = ["Lock", "Home"]
                        show_check = false
                        execute_process = true
                        show_overlay = true
                        withAnimation(.linear(duration: 0.4)) {
                            show_select_final = false
                        }
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5))
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 235/255, green: 235/255, blue: 236/255), location: 0), .init(color: Color(red: 208/255, green: 209/255, blue: 211/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Set Both").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.black).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.top, .bottom], 2.5)
                    Spacer()
                    Button(action:{
                        withAnimation(.linear(duration: 0.4)) {
                            show_select_final = false
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5)).opacity(0.6)
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 124/255, green: 124/255, blue: 124/255), location: 0), .init(color: Color(red: 26/255, green: 26/255, blue: 26/255), location: 0.50), .init(color: Color(red: 0/255, green: 0/255, blue: 0/255), location: 0.53), .init(color: Color(red: 0/255, green: 0/255, blue: 0/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.gray.opacity(0.9), Color.gray.opacity(0.35)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3).opacity(0.6)
                            Text("Cancel").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0.0, y: -0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.bottom], 25)
                }
            }
        }
    }
}

//** Mark: General Views

struct general_content: View {
    var body: some View {
        HStack {
            Spacer()
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}

struct general_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var about_usage = [list_row(title: "About", content: AnyView(general_content()), destination: "General_About"), list_row(title: "Usage", content: AnyView(general_content()), destination: "General_Usage")]
    var network_bluetooth = [list_row(title: "Network", content: AnyView(general_content()), destination: "General_Network"), list_row(title: "Bluetooth", content: AnyView(general_content()), destination: "General_Bluetooth")]
    var spotlight = [list_row(title: "Spotlight Search", content: AnyView(general_content()), destination: nil)]
    var autolock = [list_row(title: "Auto-Lock", content: AnyView(general_content()), destination: "General_Autolock"), list_row(title: "Passcode Lock", content: AnyView(OldOSPasscodeStatus()), destination: OldOSPasscodeStore.shared.enabled ? "General_Passcode Authenticate" : "General_Passcode Lock")]
    var date_accessibility = [list_row(title: "Date & Time", content: AnyView(general_content()), destination: "General_Date"), list_row(title: "Keyboard", content: AnyView(general_content()), destination: "General_Keyboard"), list_row(title: "International", content: AnyView(general_content()), destination: "General_International"), list_row(title: "Accessibility", content: AnyView(general_content()), destination: "General_Accessibility")]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: about_usage)
                        Spacer().frame(height: 25)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: network_bluetooth)
                        Spacer().frame(height: 25)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: spotlight)
                        Spacer().frame(height: 25)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: autolock)
                        Spacer().frame(height: 25)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: date_accessibility)
                    }
                    Spacer().frame(height: 15)
                }
                
            }
        }
    }
}

struct general_about_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var about_top = [list_row(title: "Network", content: AnyView(network_content()), destination: nil), list_row(title: "Songs", content: AnyView(songs_videos_photos_content()), destination: nil), list_row(title: "Videos", content: AnyView(songs_videos_photos_content()), destination: nil), list_row(title: "Photos", content: AnyView(songs_videos_photos_content()), destination: nil), list_row(title: "Applications", content: AnyView(applications_content()), destination: nil), list_row(title: "Capacity", content: AnyView(capacity_content()), destination: nil), list_row(title: "Available", content: AnyView(available_content()), destination: nil), list_row(title: "Version", content: AnyView(version_content()), destination: nil), list_row(title: "Carrier", content: AnyView(carrier_about_content()), destination: nil), list_row(title: "Model", content: AnyView(model_content()), destination: nil), list_row(title: "Serial Number", content: AnyView(serial_content()), destination: nil), list_row(title: "Wi-Fi Address", content: AnyView(wifi_bluetooth_address_content()), destination: nil), list_row(title: "Bluetooth", content: AnyView(wifi_bluetooth_address_content()), destination: nil), list_row(title: "IMEI", content: AnyView(imei_content()), destination: nil), list_row(title: "ICCID", content: AnyView(iccid_content()), destination: nil),list_row(title: "Modem Firmware", content: AnyView(modem_content()), destination: nil)]
    var about_bottom = [list_row(title: "Legal", content: AnyView(general_content()), destination: nil), list_row(title: "Regulatory", content: AnyView(general_content()), destination: nil)]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        HStack {
                            Text(UIDevice.current.name).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: about_top)
                        Spacer().frame(height:25)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: about_bottom)
                        Spacer().frame(height: 15)
                    }
                }
                
            }
        }
    }
}

struct general_usage_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var usage_top = [list_row(title: "Battery Percentage", content: AnyView(usage_battery_content()), destination: nil)]
    var usage_mid1 = [list_row(title: "Usage", content: AnyView(usage_sub_content2()), destination: nil), list_row(title: "Standby", content: AnyView(usage_sub_content2()), destination: nil)]
    var usage_mid2 = [list_row(title: "Current Period", content: AnyView(usage_sub_content2()), destination: nil), list_row(title: "Lifetime", content: AnyView(usage_sub_content2()), destination: nil)]
    var usage_bottom = [list_row(title: "Sent", content: AnyView(usage_sub_content2()), destination: nil), list_row(title: "Recieved", content: AnyView(usage_sub_content2()), destination: nil)]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: usage_top)
                        Spacer().frame(height:25)
                        HStack {
                            Text("Time since last full charge").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: usage_mid1)
                        Spacer().frame(height:25)
                        HStack {
                            Text("Call Time").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: usage_mid2)
                        Spacer().frame(height:25)
                    }
                    VStack {
                        HStack {
                            Text("Cellular Network Data").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: usage_bottom)
                        Spacer().frame(height: 15)
                    }
                }
                
            }
        }
    }
}

struct general_network_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var network_top = [list_row(title: "Enable 3G", content: AnyView(usage_battery_content()), destination: nil)]
    var network_data = [list_row(title: "Cellular Data", content: AnyView(usage_battery_content()), destination: nil)]
    var network_data_net = [list_row(title: "Cellular Data Network", content: AnyView(general_network_content()), destination: nil)]
    var network_roaming = [list_row(title: "Data Roaming", content: AnyView(usage_battery_content()), destination: nil)]
    var network_vpn = [list_row(title: "VPN", content: AnyView(general_network_content()), destination: nil)]
    var network_wifi = [list_row(title: "Wi-Fi", content: AnyView(wifi_content()), destination: nil)]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: network_top)
                        Text("Using 3G loads data faster, but may\n decrease battery life.").multilineTextAlignment(.center).lineLimit(nil).fixedSize(horizontal: false, vertical: true).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Regular", fixedSize: 15)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24).frame(maxHeight: .infinity)
                        Spacer().frame(height:15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: network_data)
                        Spacer().frame(height:20)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: network_data_net)
                        Spacer().frame(height:20)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: network_roaming)
                        Text("Turn data roaming off when abroad\n to avoid susbtantial roaming charges\n when using email, web browsing, and\n other data services.").multilineTextAlignment(.center).lineLimit(nil).fixedSize(horizontal: false, vertical: true).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Regular", fixedSize: 15)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24).frame(maxHeight: .infinity)
                    }
                    VStack {
                        Spacer().frame(height:20)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: network_vpn)
                        Spacer().frame(height:20)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: network_wifi)
                        Spacer().frame(height: 15)
                    }
                }
                
            }
        }
    }
}

struct general_bluetooth_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var bluetooth_top = [list_row(title: "Bluetooth", content: AnyView(usage_battery_content()), destination: nil)]
    var bluetooth_search = [list_row(title: "Searching...", content: AnyView(general_bluetooth_serach_content()), destination: nil)]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: bluetooth_top)
                        Spacer().frame(height:15)
                        HStack {
                            Text("Devices").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: bluetooth_search)
                        Spacer().frame(height: 15)
                    }
                    
                }
                
            }
        }
    }
}

struct general_autolock_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var autolock = [list_row(title: "1 Minute", content: AnyView(Spacer()), destination: nil),list_row(title: "2 Minutes", content: AnyView(Spacer()), destination: nil),list_row(title: "3 Minutes", content: AnyView(Spacer()), destination: nil),list_row(title: "4 Minutes", content: AnyView(Spacer()), destination: nil),list_row(title: "5 Minutes", content: AnyView(Spacer()), destination: nil),list_row(title: "Never", content: AnyView(general_autolock_never_content()), destination: nil, selected: true)]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        list_section_blue(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: autolock)
                        Spacer().frame(height: 15)
                    }
                    
                }
                
            }
        }
    }
}

struct general_date_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var date_top = [list_row(title: "24-Hour Time", content: AnyView(date_24hour_content()), destination: nil)]
    var date_bottom = [list_row(title: "Set Automatically", content: AnyView(usage_battery_content()), destination: nil)]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: date_top)
                        Spacer().frame(height:15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: date_bottom)
                        Spacer().frame(height: 15)
                    }
                    
                }
                
            }
        }
    }
}

struct general_keyboard_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var keyboard_top = [list_row(title: "Auto-Capitalization", content: AnyView(usage_battery_content()), destination: nil),list_row(title: "Auto-Correction", content: AnyView(usage_battery_content()), destination: nil),list_row(title: "Check Spelling", content: AnyView(usage_battery_content()), destination: nil),list_row(title: "Enable Caps Lock", content: AnyView(usage_battery_content()), destination: nil),list_row(title: "\".\" Shortcut", content: AnyView(usage_battery_content()), destination: nil)]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: keyboard_top)
                        Text("Double tapping the space bar will\n insert a period followed by a space.").multilineTextAlignment(.center).lineLimit(nil).fixedSize(horizontal: false, vertical: true).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Regular", fixedSize: 15)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24).frame(maxHeight: .infinity)
                        Spacer().frame(height:15)
                    }
                    
                }
                
            }
        }
    }
}

struct general_international_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var international_top = [list_row(title: "Language", content: AnyView(international_content()), destination: nil),list_row(title: "Voice Control", content: AnyView(international_content()), destination: nil),list_row(title: "Keyboards", content: AnyView(international_keyboard_content()), destination: nil)]
    var international_bottom = [list_row(title: "Region Format", content: AnyView(international_region_content()), destination: nil),list_row(title: "Calendar", content: AnyView(international_calendar_content()), destination: nil)]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: international_top)
                        Spacer().frame(height:25)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: international_bottom)
                        Spacer().frame(height:25)
                        Text("Region Format Example").multilineTextAlignment(.center).lineLimit(nil).fixedSize(horizontal: false, vertical: true).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 18)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24).frame(maxHeight: .infinity)
                        Spacer().frame(height:10)
                        Text("Tuesday, January 5, 2021\n 12:34 AM\n (408) 555-1212").multilineTextAlignment(.center).lineLimit(nil).fixedSize(horizontal: false, vertical: true).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Regular", fixedSize: 18)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24).frame(maxHeight: .infinity)
                        Spacer().frame(height:15)
                    }
                    
                }
                
            }
        }
    }
}

struct general_accessibility_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var acb_top = [list_row(title: "VoiceOver", content: AnyView(acb_content()), destination: nil),list_row(title: "Zoom", content: AnyView(acb_content()), destination: nil),list_row(title: "Large Text", content: AnyView(acb_content()), destination: nil),list_row(title: "White on Black", content: AnyView(date_24hour_content()), destination: nil)]
    var acb_mid = [list_row(title: "Mono audio", content: AnyView(date_24hour_content()), destination: nil),list_row(title: "Speak Auto-text", content: AnyView(date_24hour_content()), destination: nil)]
    var acb_bottom = [list_row(title: "Triple-click Home", content: AnyView(acb_content()), destination: nil)]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: acb_top)
                        Spacer().frame(height:25)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: acb_mid)
                        Text("Automatically speak auto-corrections\n and auto-capitalizations.").multilineTextAlignment(.center).lineLimit(nil).fixedSize(horizontal: false, vertical: true).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Regular", fixedSize: 15)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24).frame(maxHeight: .infinity)
                        Spacer().frame(height:25)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: acb_bottom)
                        Spacer().frame(height: 15)
                    }
                    
                }
                
            }
        }
    }
}

struct acb_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text("Off").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255))
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}

struct international_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text("English").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255))
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}

struct international_keyboard_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text("1").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255))
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}

struct international_region_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text("United States").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255))
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}

struct international_calendar_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text("Gregorian").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255))
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}

struct date_24hour_content: View {
    var body: some View {
        HStack {
            toggle(on: false).padding(.trailing, 12)
        }
    }
}

struct general_autolock_never_content: View {
    var body: some View {
        HStack {
            Spacer()
            Image("TWPickerTableCellChecked").resizable().font(Font.title.weight(.bold)).frame(width:15, height: 15).padding(.trailing, 12)
        }
    }
}

struct general_bluetooth_serach_content: View {
    var body: some View {
        HStack {
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .gray)).padding(.trailing, 12).scaleEffect(1, anchor: .center)
        }
    }
}


struct general_network_content: View {
    var body: some View {
        HStack {
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}

struct usage_battery_content: View {
    var body: some View {
        HStack {
            toggle().padding(.trailing, 12)
        }
    }
}

struct network_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text(CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.first?.value.carrierName ?? "Not Available").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.trailing, 12)
        }
    }
}

struct usage_sub_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text("0 Minutes").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.trailing, 12)
        }
    }
}

struct usage_sub_content2: View {
    var body: some View {
        HStack {
            Spacer()
            Text("0 bytes").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.trailing, 12)
        }
    }
}

struct songs_videos_photos_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text("0").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.trailing, 12)
        }
    }
}

struct applications_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text("19").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.trailing, 12)
        }
    }
}

struct capacity_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text(DiskStatus.totalDiskSpace).font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.trailing, 12)
        }
    }
}

struct available_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text(DiskStatus.freeDiskSpace).font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.trailing, 12)
        }
    }
}

struct version_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text("4.3 (8F190)").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.trailing, 12)
        }
    }
}

struct carrier_about_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text("Carrier 10.0").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.trailing, 12)
        }
    }
}


struct model_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text(UIDevice.current.model).font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.trailing, 12)
        }
    }
}

struct serial_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text(randomString(length: 11)).font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.trailing, 12)
        }
    }
}

struct wifi_bluetooth_address_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text("\(randomString(length: 2)):\(randomString(length: 2)):\(randomString(length: 2)):\(randomString(length: 2)):\(randomString(length: 2)):\(randomString(length: 2))").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.trailing, 12)
        }
    }
}

struct imei_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text("\(randomNumberString(length: 2)) \(randomNumberString(length: 6)) \(randomNumberString(length: 6)) \(randomNumberString(length: 1))").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.trailing, 12)
        }
    }
}

struct iccid_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text("\(randomNumberString(length: 18))").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.trailing, 12)
        }
    }
}

struct modem_content: View {
    var body: some View {
        HStack {
            Spacer()
            Text("04.10.01").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.trailing, 12)
        }
    }
}


//**Mark: Mail, Contacts, Calendar


struct mcc_view: View {
    @EnvironmentObject var EmailManager: EmailManager
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @State var account = [list_row(title: "Add Account...", content: AnyView(general_content()), destination: nil)]
    var new_data = [list_row(title: "Fetch New Data", content: AnyView(mcc_content(text: "Push")), destination: nil)]
    var show_organize = [list_row(title: "Show", content: AnyView(mcc_content(text: "50 Recent Messages")), destination: nil), list_row(title: "Preview", content: AnyView(mcc_content(text: "2 Lines")), destination: nil), list_row(title: "Minimum Font Size", content: AnyView(mcc_content(text: "Medium")), destination: nil), list_row(title: "Show to/Cc Label", content: AnyView(mcc_content_toggle(on:false)), destination: nil), list_row(title: "Ask Before Deleting", content: AnyView(mcc_content_toggle(on: false)), destination: nil), list_row(title: "Load Remote Images", content: AnyView(mcc_content_toggle(on:true)), destination: nil),list_row(title: "Organize by Thread", content: AnyView(mcc_content_toggle(on: true)), destination: nil)]
    var bss_sig = [list_row(title: "Always Bcc Myself", content: AnyView(mcc_content_toggle(on: false)), destination: nil), list_row(title: "Signature", content: AnyView(mcc_content(text: "Sent from my iPhone")), destination: nil)]
    var contacts = [list_row(title: "Sort Order", content: AnyView(mcc_content(text: "Last, First")), destination: nil), list_row(title: "Display Order", content: AnyView(mcc_content(text: "First, Last")), destination: nil)]
    var sim_contacts = [list_row(title: "", content: AnyView(mcc_sim()))]
    var calendars = [list_row(title: "New Invitation Alerts", content: AnyView(mcc_content_toggle(on: true)), destination: nil), list_row(title: "Time Zone Support", content: AnyView(mcc_content(text: "")), destination:nil)]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        HStack {
                            Text("Accounts").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: account)
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: new_data)
                        Spacer().frame(height: 15)
                        HStack {
                            Text("Mail").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: show_organize)
                        Spacer().frame(height:15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: bss_sig)
                    }
                    VStack {
                        Spacer().frame(height:15)
                        HStack {
                            Text("Contacts").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: contacts)
                        Spacer().frame(height:15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: sim_contacts)
                        Spacer().frame(height:15)
                        HStack {
                            Text("Calendars").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: calendars)
                        Spacer().frame(height:15)
                    }
                    Spacer().frame(height: 15)
                }
                
            }
        }.onAppear() {
            if EmailManager.account_email != "" {
                var account_row = list_row(title: EmailManager.account_email.components(separatedBy: "@").first ?? "", content: AnyView(general_content()), destination: "MCC_Action")
                account.insert(account_row, at: 0)
            }
        }
    }
}

struct mail_account_action_view: View {
    @EnvironmentObject var EmailManager: EmailManager
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @State var account_content: [list_row] = []
    var configs = [list_row(title: "Mail", image: "Settings-MCC", content: AnyView(mcc_content_toggle(on: true))), list_row(title: "Notes", image: "Settings-Notes", content: AnyView(mcc_content_toggle(on: false)))]
    var body: some View {
        VStack(spacing:0) {
        
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        HStack {
                            Text("IMAP").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: account_content)
                        Spacer().frame(height: 15)
                       list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: configs)
                        Spacer().frame(height: 15)
                        Button(action: {
                            DispatchQueue.global(qos: .background).async {
                                EmailManager.signOut()
                            }
                            withAnimation() {
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)){current_nav_view = "Mail, Contacts, Calendars"}
                            }
                        }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9.15).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 9.15).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5)).padding(2.65).offset(y: -0.25)
                            RoundedRectangle(cornerRadius: 9).fill(returnLinearGradient(.red)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Delete Account").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0.0, y: -0.6)
                        }.padding([.leading, .trailing], 9.35).frame(minHeight: 50, maxHeight:50)
                        }
                    }
                    Spacer().frame(height: 15)
                }
                
            }
        }.onAppear() {
            account_content = [list_row(title: "Account", content: AnyView(mcc_action_content(text: EmailManager.account_email)), destination: nil)]
        }
    }
}

struct mcc_content: View {
    var text: String
    var body: some View {
        Text(text).font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255))
        Image("UITableNext").padding(.trailing, 12)
    }
}

struct mcc_action_content: View {
    var text: String
    var body: some View {
        Text(text).font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).lineLimit(0)
        Image("UITableNext").padding(.trailing, 12)
    }
}

struct mail_contacts_calendars_content: View {
    var body: some View {
        HStack {
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}

struct mcc_content_toggle: View {
    var on: Bool
    var body: some View {
        toggle(on: on).padding(.trailing, 12)
    }
}

struct mcc_sim: View {
    var body: some View {
        Spacer()
        Text("Import SIM Contacts        ").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black)
        Spacer()
    }
}

//**Mark:Phone

struct phone_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var number = [list_row(title: "My Number", content: AnyView(mcc_content(text: "Unknown")), destination: nil)]
    var facetime = [list_row(title: "FaceTime", content: AnyView(mcc_content_toggle(on:true)), destination: nil)]
    var calls_tty = [list_row(title: "Call Forwarding", content: AnyView(mcc_content(text: "")), destination: nil), list_row(title: "Call Waiting", content: AnyView(mcc_content(text: "")), destination: nil), list_row(title: "Show My Caller ID", content: AnyView(mcc_content(text: "")), destination: nil), list_row(title: "TTY", content: AnyView(mcc_content_toggle(on:false)), destination: nil)]
    var international = [list_row(title: "International Assist", content: AnyView(mcc_content_toggle(on: true)), destination: nil)]
    var simpin = [list_row(title: "SIM PIN", content: AnyView(mcc_content(text: "")))]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: number)
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: facetime)
                        Spacer().frame(height: 15)
                        HStack {
                            Text("Calls").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: calls_tty)
                        Text("International Assist automatically\n adds the correct prefix to US\n numbers when dialing from abroad.").multilineTextAlignment(.center).lineLimit(nil).fixedSize(horizontal: false, vertical: true).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Regular", fixedSize: 15)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24).frame(maxHeight: .infinity)
                        Spacer().frame(height:15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: simpin)
                    }
                    Spacer().frame(height: 15)
                }
                
            }
        }
    }
}

//**Mark:Safari

struct safari_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var search_engine = [list_row(title: "Search Engine", content: AnyView(mcc_content(text: "Google")), destination: nil)]
    var autofill = [list_row(title: "AutoFill", content: AnyView(mcc_content(text: "Off")), destination: nil)]
    var calls_tty = [list_row(title: "Call Forwarding", content: AnyView(mcc_content(text: "")), destination: nil), list_row(title: "Call Waiting", content: AnyView(mcc_content(text: "")), destination: nil), list_row(title: "Show My Caller ID", content: AnyView(mcc_content(text: "")), destination: nil), list_row(title: "TTY", content: AnyView(mcc_content_toggle(on:false)), destination: nil)]
    var fraud = [list_row(title: "Fraud Warning", content: AnyView(mcc_content_toggle(on: true)), destination: nil)]
    var java_cookies = [list_row(title: "JavaScript", content: AnyView(mcc_content_toggle(on: true)), destination: nil), list_row(title: "Block Pop-ups", content: AnyView(mcc_content_toggle(on: true)), destination: nil), list_row(title: "Accept Cookies", content: AnyView(mcc_content(text: "From visited")), destination: nil)]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        HStack {
                            Text("General").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: search_engine)
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: autofill)
                        Spacer().frame(height: 15)
                        HStack {
                            Text("Security").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: fraud)
                        Text("Warn when visiting fradulent websites.").multilineTextAlignment(.center).lineLimit(nil).fixedSize(horizontal: false, vertical: true).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Regular", fixedSize: 15)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24).frame(maxHeight: .infinity)
                        Spacer().frame(height:15)
                    }
                    VStack {
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: java_cookies)
                        Spacer().frame(height: 15)
                    }
                }
                
            }
        }
    }
}

//**Mark: Messages

struct messages_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var preview = [list_row(title: "Show Preview", content: AnyView(mcc_content_toggle(on: true)), destination: nil)]
    var tone = [list_row(title: "Play Alert Tone", content: AnyView(mcc_content(text: "Twice")), destination: nil)]
    var mms_subject = [list_row(title: "MMS Messaging", content: AnyView(mcc_content_toggle(on: true)), destination: nil), list_row(title: "Group Messaging", content: AnyView(mcc_content_toggle(on: false)), destination: nil), list_row(title: "Show Subject Field", content: AnyView(mcc_content_toggle(on: false)), destination: nil)]
    var calls_tty = [list_row(title: "Call Forwarding", content: AnyView(mcc_content(text: "")), destination: nil), list_row(title: "Call Waiting", content: AnyView(mcc_content(text: "")), destination: nil), list_row(title: "Show My Caller ID", content: AnyView(mcc_content(text: "")), destination: nil), list_row(title: "TTY", content: AnyView(mcc_content_toggle(on:false)), destination: nil)]
    var character_count = [list_row(title: "Character Count", content: AnyView(mcc_content_toggle(on: false)), destination: nil)]
    var java_cookies = [list_row(title: "JavaScript", content: AnyView(mcc_content_toggle(on: true)), destination: nil), list_row(title: "Block Pop-ups", content: AnyView(mcc_content_toggle(on: true)), destination: nil), list_row(title: "Accept Cookies", content: AnyView(mcc_content(text: "From visited")), destination: nil)]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: preview)
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: tone)
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: mms_subject)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: character_count)
                        Spacer().frame(height:15)
                    }
                }
                
            }
        }
    }
}

//**Mark: iPod

struct ipod_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var shake_lyrics = [list_row(title: "Shake to Shuffle", content: AnyView(mcc_content_toggle(on: false)), destination: nil), list_row(title: "Sound Check", content: AnyView(mcc_content_toggle(on: false)), destination: nil), list_row(title: "EQ", content: AnyView(mcc_content(text: "Off")), destination: nil), list_row(title: "Volume Limit", content: AnyView(mcc_content(text: "Off")), destination: nil), list_row(title: "Lyrics & Podcast Info", content: AnyView(mcc_content_toggle(on: true)), destination: nil)]
    var start_captioning = [list_row(title: "Start Playing", content: AnyView(mcc_content(text: "Where Left Off")), destination: nil), list_row(title: "Closed Captioning", content: AnyView(mcc_content_toggle(on: false)), destination: nil)]
    var widescreen_signal = [list_row(title: "Widescreen", content: AnyView(mcc_content_toggle(on: false)), destination: nil), list_row(title: "TV Signal", content: AnyView(mcc_content(text: "NTSC")), destination: nil)]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        HStack {
                            Text("Music").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: shake_lyrics)
                        Spacer().frame(height: 15)
                        HStack {
                            Text("Video").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: start_captioning)
                        Spacer().frame(height: 15)
                        HStack {
                            Text("TV Out").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: widescreen_signal)
                    }
                    Spacer().frame(height: 15)
                }
                
            }
        }
    }
}

//**Mark: Photos

struct photos_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var play_shuffle = [list_row(title: "Play Each Slide For", content: AnyView(mcc_content(text: "3 Seconds")), destination: nil), list_row(title: "Repeat", content: AnyView(mcc_content_toggle(on: false)), destination: nil), list_row(title: "Shuffle", content: AnyView(mcc_content_toggle(on: false)), destination: nil)]
    var keep_normal = [list_row(title: "Keep Normal Photo", content: AnyView(mcc_content_toggle(on: true)), destination: nil), list_row(title: "Closed Captioning", content: AnyView(mcc_content_toggle(on: false)), destination: nil)]
    var widescreen_signal = [list_row(title: "Widescreen", content: AnyView(mcc_content_toggle(on: false)), destination: nil), list_row(title: "TV Signal", content: AnyView(mcc_content(text: "NTSC")), destination: nil)]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        HStack {
                            Text("Slideshow").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: play_shuffle)
                        Spacer().frame(height: 15)
                        HStack {
                            Text("HDR (High Dynamic Range)").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        Spacer().frame(height:15)
                        HStack {
                            Text("HDR blends the best parts of three\nseparate exposures into a single photo.").multilineTextAlignment(.leading).lineLimit(nil).fixedSize(horizontal: false, vertical: true).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Regular", fixedSize: 15)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24).frame(maxHeight: .infinity)
                            Spacer()
                        }
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: keep_normal)
                        Text("Save the normal exposed photo in\n addition to the HDR version.").multilineTextAlignment(.center).lineLimit(nil).fixedSize(horizontal: false, vertical: true).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Regular", fixedSize: 15)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24).frame(maxHeight: .infinity)
                    }
                    Spacer().frame(height: 15)
                }
                
            }
        }
    }
}

//**Mark: Notes

struct notes_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var font = [list_row(title: "Noteworthy", content: AnyView(general_autolock_never_content()), destination: nil, selected: true), list_row(title: "Helvetica", content: AnyView(Spacer()), destination: nil), list_row(title: "Marker Felt", content: AnyView(Spacer()), destination: nil)] //I reused it...so what I should be using generics
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        HStack {
                            Text("Font").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        list_section_blue(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: font)
                        Spacer().frame(height: 15)
                    }
                }
                
            }
        }
    }
}

//**Mark: Store

struct store_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var sign_in = [list_row(title: "", content: AnyView(storec_sign_in()), destination: nil)]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: sign_in)
                        Spacer().frame(height: 15)
                    }
                }
                
            }
        }
    }
}

struct storec_sign_in: View {
    var body: some View {
        Spacer()
        Text("Sign In               ").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black)
        Spacer()
    }
}

//**Mark: Nike + iPod

struct nike_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var nike = [list_row(title: "Nike + iPod", content: AnyView(mcc_content_toggle(on:false)), destination: nil)]
    var body: some View {
        VStack(spacing:0) {
            
            ZStack {
                settings_main_list()
                ScrollView {
                    VStack() {
                        Spacer().frame(height: 15)
                        list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: nike)
                        Spacer().frame(height: 15)
                    }
                }
                
            }
        }
    }
}



struct airplane_content: View {
    var body: some View {
        HStack {
            Spacer()
            toggle_orange().padding(.trailing, 12)
        }
    }
}


extension View {
    public func addBorder<S>(_ content: S, width: CGFloat = 1, cornerRadius: CGFloat) -> some View where S : ShapeStyle {
        let roundedRect = RoundedRectangle(cornerRadius: cornerRadius)
        return clipShape(roundedRect)
            .overlay(roundedRect.strokeBorder(content, lineWidth: width))
    }
}

func getWiFiSsid() -> String? {
    var ssid: String?
    if let interfaces = CNCopySupportedInterfaces() as NSArray? {
        for interface in interfaces {
            if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                break
            }
        }
    }
    return ssid
}



struct settings_main_list : View {
    var horizontalSpacing: CGFloat = 12
    var body: some View {
        ZStack {
            Color.init(red: 197/255, green: 204/255, blue: 212/255).edgesIgnoringSafeArea(.all)
            vertical_bar_background().clipped()
            VStack {
                Spacer()
            }
        }
    }
}

