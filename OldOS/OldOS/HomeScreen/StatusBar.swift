import SwiftUI
import UIKit
import Network
import CoreTelephony
import Combine

final class OldOSStatusState:ObservableObject {
    static let shared = OldOSStatusState()
    @Published private(set) var date:Date
    @Published private(set) var batteryLevel:Float = 100
    @Published private(set) var charging = false
    @Published private(set) var wifiConnected = true
    @Published private(set) var carrierLabel = "eSIM"
    private let clock:()->Date
    private let networkInfo = CTTelephonyNetworkInfo()
    private let monitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label:"OldOS.Status.Network")
    private var subscriptions = Set<AnyCancellable>()

    init(clock:@escaping()->Date = Date.init) {
        self.clock=clock
        date=clock()
        UIDevice.current.isBatteryMonitoringEnabled=true
        Timer.publish(every:1,on:.main,in:.common).autoconnect()
            .sink { [weak self] _ in self?.updateTime() }.store(in:&subscriptions)
        for name in [UIApplication.didBecomeActiveNotification,UIApplication.significantTimeChangeNotification,
                     NSNotification.Name.NSSystemTimeZoneDidChange,NSLocale.currentLocaleDidChangeNotification] {
            NotificationCenter.default.publisher(for:name).receive(on:DispatchQueue.main)
                .sink { [weak self] _ in self?.refresh() }.store(in:&subscriptions)
        }
        for name in [UIDevice.batteryLevelDidChangeNotification,UIDevice.batteryStateDidChangeNotification] {
            NotificationCenter.default.publisher(for:name).receive(on:DispatchQueue.main)
                .sink { [weak self] _ in self?.updateBattery() }.store(in:&subscriptions)
        }
        networkInfo.serviceSubscriberCellularProvidersDidUpdateNotifier = { [weak self] _ in
            DispatchQueue.main.async { self?.updateCarrier() }
        }
        NotificationCenter.default.publisher(for:Notification.Name.CTServiceRadioAccessTechnologyDidChange).receive(on:DispatchQueue.main)
            .sink { [weak self] _ in self?.updateCarrier() }.store(in:&subscriptions)
        monitor.pathUpdateHandler = { [weak self] path in
            let connected=path.status == .satisfied && path.usesInterfaceType(.wifi)
            DispatchQueue.main.async {
                guard let self, self.wifiConnected != connected else { return }
                self.wifiConnected=connected
            }
        }
        monitor.start(queue:networkQueue)
        refresh()
    }
    deinit { monitor.cancel() }

    func refresh() {
        date=clock()
        updateBattery()
        updateCarrier()
    }
    private func updateTime() {
        let now=clock()
        if floor(now.timeIntervalSince1970/60) != floor(date.timeIntervalSince1970/60) { date=now }
    }
    private func updateBattery() {
        let device=UIDevice.current
        let isCharging=device.batteryState == .charging || device.batteryState == .full
        let level=device.batteryLevel
        let percent:Float = isCharging ? 100:(level >= 0 ? min(100,max(0,level*100)):batteryLevel)
        if charging != isCharging { charging=isCharging }
        if batteryLevel != percent { batteryLevel=percent }
    }
    private func updateCarrier() {
        let providers=networkInfo.serviceSubscriberCellularProviders ?? [:]
        var keys=providers.keys.sorted()
        if let active=networkInfo.dataServiceIdentifier, keys.contains(active) {
            keys.removeAll{$0==active};keys.insert(active,at:0)
        }
        let names=keys.compactMap{providers[$0]?.carrierName}
        let selected=Self.carrierName(from:names)
        let label:String
        if let selected { label=selected }
        else if #available(iOS 16.4,*) { label="eSIM" }
        else { label=providers.isEmpty ? "No SIM":"eSIM" }
        if carrierLabel != label { carrierLabel=label }
    }
    static func carrierName(from names:[String])->String? {
        names.lazy.map{$0.trimmingCharacters(in:.whitespacesAndNewlines)}
            .first{!$0.isEmpty && $0 != "--"}
    }
}


struct status_bar: View {
    @ObservedObject private var status = OldOSStatusState.shared
    var locked = false
    private var date:Date { status.date }
    private var battery_level:Float { status.batteryLevel }
    private var charging:Bool { status.charging }
    private var wifi_connected:Bool { status.wifiConnected }
    private var carrier_id:String { status.carrierLabel }
    private var timeFormat:DateFormatter {
        let formatter=DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat="h:mm a"
        return formatter
    }
    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
            HStack {
                Text(carrier_id).foregroundColor(Color.init(red: 200/255, green: 200/255, blue: 200/255)).font(.custom("Helvetica Neue Medium", fixedSize: 15))
                Image(systemName: "wifi").foregroundColor(Color.init(red: 190/255, green: 190/255, blue: 190/255)).opacity(wifi_connected ? 1 : 0)
                Spacer()
                Text("\(Int(battery_level))%").isHidden(charging).foregroundColor(Color.init(red: 190/255, green: 190/255, blue: 190/255)).font(.custom("Helvetica Neue Medium", fixedSize: 15)).offset(x: 10)
                battery(battery: Float(battery_level/100), charging: charging)
                    .offset(x: 5)

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
        }.onAppear { status.refresh() }
    }
    func timeString(date: Date) -> String {
        timeFormat.string(from: date)
    }
}

struct status_bar_in_app: View {
    @ObservedObject private var status = OldOSStatusState.shared
    var locked = false
    var selected_page = 1
    private var date:Date { status.date }
    private var battery_level:Float { status.batteryLevel }
    private var charging:Bool { status.charging }
    private var wifi_connected:Bool { status.wifiConnected }
    private var carrier_id:String { status.carrierLabel }
    private var timeFormat:DateFormatter {
        let formatter=DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat="h:mm a"
        return formatter
    }
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.init(red: 237/255, green: 244/255, blue: 247/255), Color.init(red: 191/255, green: 199/255, blue: 203/255)]), startPoint: UnitPoint(x: 0.5, y: 0.07), endPoint: .bottom).innerShadowBottomView(color: Color.init(red: 142/255, green: 149/255, blue: 154/255), radius: 0.05).border_bottom(width: 0.45, edges:[.bottom], color: Color.init(red: 93/255, green: 100/255, blue: 105/255)).cornerRadiusSpecific(radius: 1.75, corners: [.topLeft, .topRight])
            HStack {
                Text(carrier_id).foregroundColor(carrier_id == "No SIM" ? .black : Color.init(red: 66/255, green: 66/255, blue: 66/255)).font(.custom("Helvetica Neue Bold", fixedSize: 15)).shadowStyle()
                ZStack {
                    Image(systemName: "wifi").gradientForegroundNonDynamic(colors: [Color.init(red: 32/255, green: 157/255, blue: 237/255), Color.init(red: 72/255, green: 118/255, blue: 196/255)]) .opacity(wifi_connected ? 1 : 0).shadowStyle().mask( Image(systemName: "wifi").gradientForegroundNonDynamic(colors: [Color.init(red: 32/255, green: 157/255, blue: 237/255), Color.init(red: 72/255, green: 118/255, blue: 196/255)]) .opacity(wifi_connected ? 1 : 0).shadowStyle().innerShadow2(color: Color.black.opacity(0.8), radius: 1))
                }
                Spacer()
                Text("\(Int(battery_level))%").foregroundColor(Color.init(red: 74/255, green: 74/255, blue: 74/255)).font(.custom("Helvetica Neue Bold", fixedSize: 15)).shadowStyle().offset(x: 10).isHidden(charging)
                battery_in_app(battery: Float(battery_level/100), charging: charging)
                    .offset(x: 5)
            }.padding([.leading, .trailing], 4)
            HStack {
                Spacer()
                Text(timeString(date: date).uppercased()).foregroundColor(Color.black).font(.custom("Helvetica Neue Bold", fixedSize: 15)).shadowStyle()
                Spacer()
            }
        }.onAppear { status.refresh() }
    }
    func timeString(date: Date) -> String {
        timeFormat.string(from: date)
    }
}
