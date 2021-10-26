//
//  Weather.swift
//  OldOS
//
//  Created by Zane Kleinberg on 4/9/21.
//

import SwiftUI
import SwiftUIPager
import MapKit
import Combine
import Foundation

struct Weather: View, Equatable {
    
    static func == (lhs: Weather, rhs: Weather) -> Bool {
        //Our views will want to redraw when we activate multitasking. The easiest solution is to make our views equatable and not have them redraw when changing it.
        return lhs.show_multitasking != rhs.show_multitasking
    }

    
    @State var current_nav_view: String = "Main"
    @State var forward_or_backward = false
    @State var show_settings:Bool = false
    @State var switch_to_settings: Bool = false
    @State var collapse_pager: Bool = false
    @State var hide_weather: Bool = false
    @StateObject var page: Page = .first()
    @Binding var show_multitasking: Bool
    @ObservedObject var weather_data: ObservableArray<WeatherObserver> = try! ObservableArray(array: [WeatherObserver(location: "", mode: "imperial")]).observeChildrenChanges()
    // @ObservedObject var weatherData = WeatherObserver()
    var items = Array(0..<3)
    
    init(show_multitasking: Binding<Bool>) {
        
        _show_multitasking = show_multitasking
        
        // Because of how our observable array works, empty values will result in breaking the application. With this approach, we never have an empty array. I'd say it would be wildy inefficent if we we're initialising our array with data from the web, but because we are pulling from userdefaults its almost instant and unnoticable. It appears this is how Apple actually does it in the Weather app.
        let userDefaults = UserDefaults.standard
        var weather = (userDefaults.object(forKey: "weather_cities") as? [String:String] ?? ["0":""]).sorted(by: <)
        var mode = userDefaults.object(forKey: "weather_mode") as? String ?? "imperial"
        if weather.count >= 1 {
            for (key, value) in weather {
                weather_data.array.append(WeatherObserver(location: value, mode: mode))
                if key == "0" {
                    weather_data.array.removeFirst()
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            status_bar().background(Color.black).frame(minHeight: 24, maxHeight:24).zIndex(1)
        GeometryReader { geometry in
            ZStack {
                weather_settings(show_settings: $show_settings, switch_to_settings: $switch_to_settings, collapse_pager: $collapse_pager, weather_data: weather_data).frame(width:geometry.size.width, height:geometry.size.height).rotation3DEffect(.degrees(show_settings == false ? 90 : 0), axis: (x: 0, y:1, z: 0), anchor: UnitPoint(0, 0.5)).offset(x:show_settings == false ? geometry.size.width/2 : 0).opacity(show_settings == false ? 0: 1)
                    //Rotating the entire Page view is far too resource heavy, instead we opt for a collapse approach. Our pager is instantly replaced with an identical view prior to performing the flip, and instantly switched back after the flip.
                    VStack(spacing: 0) {
                        if collapse_pager == true {
                            VStack(spacing: 0) {
                                Spacer().frame(height:80)
                                if (weather_data.array[optional: page.index]?.current_data?.weather?[0].icon ?? "").contains("n") {
                                    weather_content_view_night_2(weatherData: weather_data.array[optional:page.index] ?? WeatherObserver(location: "", mode: "imperial"), show_settings: $show_settings, switch_to_settings: $switch_to_settings)
                                } else {
                                    weather_content_view_day(weatherData: weather_data.array[optional:page.index] ?? WeatherObserver(location: "", mode: "imperial"), show_settings: $show_settings, switch_to_settings: $switch_to_settings, collapse_pager: $collapse_pager)
                                }
                            }.overlay(VStack(spacing: 0) {
                                Spacer().frame(height:30 + json_iconography_to_offset(weather_data.array[optional: page.index]?.current_data?.weather?[0].icon ?? ""))
                                Image(json_iconography_to_image(weather_data.array[optional: page.index]?.current_data?.weather?[0].icon ?? "", is_mini: false))
                                Spacer()
                            })
                        } else {
                        Pager(page: page, data: weather_data.array, id: \.full_location, content: {index in
                            //      if index == 0 {
                            ZStack {
                            VStack(spacing: 0) {
                                Spacer().frame(height:80)
                                if (index.current_data?.weather?[0].icon ?? "").contains("n") {
                                    weather_content_view_night_2(weatherData: index, show_settings: $show_settings, switch_to_settings: $switch_to_settings)
                                } else {
                                    weather_content_view_day(weatherData: index, show_settings: $show_settings, switch_to_settings: $switch_to_settings, collapse_pager: $collapse_pager)
                                }
                            }
                           VStack(spacing: 0) {
                            if !(index.current_data?.weather?[0].icon?.isEmpty ?? false) {
                                Spacer().frame(height:30 + json_iconography_to_offset(index.current_data?.weather?[0].icon ?? ""))
                                    Image(json_iconography_to_image(weather_data.array[optional: page.index]?.current_data?.weather?[0].icon ?? "", is_mini: false)).animationsDisabled()
                                }
                                Spacer()
                            }.animationsDisabled()
                            }
                        })
                        }
                        Spacer().frame(height:25)
                        HStack(spacing: 10) {
                            Spacer()
                            ForEach(weather_data.array, id:\.id
                            ) { index in
                                Circle().fill(Color.white).frame(width:7.5, height:7.5).opacity(weather_data.array.firstIndex(of: index) == page.index ? 1 : 0.25)
                            }
                            Spacer()
                        }.animationsDisabled().padding(.bottom, 25)
                    }.frame(width:geometry.size.width, height:geometry.size.height).rotation3DEffect(.degrees(switch_to_settings == true ? -90 : 0), axis: (x: 0, y:1, z: 0), anchor: UnitPoint(1, 0.5)).offset(x:switch_to_settings == true ? -geometry.size.width/2 : 0).opacity(switch_to_settings == true ? 0 : 1).isHidden(hide_weather)
            }
        }.compositingGroup()
        }.background(Color.black).onAppear() {
            print(json_iconography_to_image(weather_data.array[optional: page.index]?.current_data?.weather?[0].icon ?? "", is_mini: false))
        }
    }
}



struct weather_settings: View {
    @State var to_delete: UUID = UUID()
    @State var selected_segment: Int = (UserDefaults.standard.object(forKey: "weather_mode") as? String ?? "imperial" == "imperial" ? 0 : 1)
    @State var show_add_location: Bool = false
    @State var will_delete:Bool = false
    @Binding var show_settings: Bool
    @Binding var switch_to_settings: Bool
    @Binding var collapse_pager: Bool
    @ObservedObject var weather_data: ObservableArray<WeatherObserver>
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("Weather_Settings_BackgroundTile").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).frame(width:geometry.size.width, height: geometry.size.height)
                VStack {
                    weather_settings_title_bar(done_action: {
                        withAnimation(.easeIn(duration: 0.4)){
                            show_settings.toggle()}
                        DispatchQueue.main.asyncAfter(deadline:.now()+0.39) { //maybe 0.45
                            withAnimation(.easeOut(duration: 0.4)){switch_to_settings.toggle()}
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.8) {
                            collapse_pager = false
                        }
                        
                    }, new_action: {withAnimation(){show_add_location.toggle()}}, show_done: true).frame(height: 60)
                    Spacer().frame(height: 15)
                    
                    
                    ZStack {
                        
                        VStack(spacing: 0) {
                            ForEach(weather_data.array, id: \.id) { index in
                                VStack(alignment: .leading, spacing: 0) {
                                        Color.white.frame(height: 44-0.95)
                                    Rectangle().fill(will_delete == true ? Color.white : Color.black).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                    
                                }
                                
                            }.frame(height: 44).animationsDisabled()
                            Color.white.animationsDisabled()
                        }
                        
                        
                    NoSepratorList_NonLazy {
                        ForEach(weather_data.array, id: \.id) { index in
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(alignment: .center) {
                                    Spacer().frame(width:1, height: 44-0.95)
                                    if weather_data.array.count > 1 {
                                    Button(action:{
                                        withAnimation(.linear(duration:0.15)) {
                                            if to_delete != index.id {
                                                to_delete = index.id
                                            } else {
                                                to_delete = UUID()
                                            }
                                        }
                                    }) {
                                        ZStack {
                                            Image("UIRemoveControlMinus")
                                            Text("—").foregroundColor(.white).font(.system(size: 15, weight: .heavy, design: .default)).offset(y:to_delete == index.id ? -0.8 : -2).rotationEffect(.degrees(to_delete == index.id ? -90 : 0), anchor: .center).offset(y:to_delete == index.id ? -0.5 : 0)
                                        }
                                    }.transition(AnyTransition.asymmetric(insertion: .move(edge:.leading), removal: .move(edge:.leading)).combined(with: .opacity)).offset(x:-4)
                                }
                                    Text(index.location_string).font(.custom("Helvetica Neue Bold", fixedSize: 20)).foregroundColor(.black).lineLimit(1)
                                    ZStack {
                                        HStack {
                                            Spacer()
                                            Image("UITableGrabber").padding(.trailing, 12)
                                        }
                                        HStack {
                                            Spacer()
                                            if to_delete == index.id, weather_data.array.count > 1 {
                                                tool_bar_rectangle_button(action: {will_delete = true; withAnimation() {
                                                    weather_data.array.removeAll(where: {$0.id == to_delete})
                                                    let userDefaults = UserDefaults.standard
                                                    var weather_dict = [String:String]()
                                                        var i = 0
                                                        for item in weather_data.array {
                                                            weather_dict["\(i)"] = (item.full_location != nil ? item.full_location : "")
                                                            i += 1
                                                        }
                                                        var defaults_weather = (userDefaults.object(forKey: "weather_cities") as? [String:String] ?? ["0":""]).sorted(by: >)
                                                        if defaults_weather != weather_dict.sorted(by: >) {
                                                        userDefaults.setValue(weather_dict, forKey: "weather_cities")
                                                    }
                                                    
                                                }
                                                
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    will_delete = false //Set the background back
                                                }
                                                }, button_type: .red, content: "Delete").padding(.trailing, 12).transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge:.trailing)).combined(with: .opacity))
                                            }
                                        }
                                    }
                                }.padding([.leading], 8)
                                Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                
                            }
                            
                        }.frame(height: 44)
                    
                    }
                    }.cornerRadius(12).padding([.leading, .trailing], 12)
                    Spacer().frame(height: 15)
                    dual_segmented_control_big_bluegray_no_stroke(selected: $selected_segment, first_text: "°F", second_text: "°C").frame(width: geometry.size.width-24, height: 45)
                    Spacer().frame(height: 15)
                    Image("yahoo_weather")
                    Spacer().frame(height: 15)
                }
                if show_add_location {
                    new_location_search(show_add_location: $show_add_location, weather_data: weather_data).transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom))).zIndex(2)
                }
            }
        }.onChange(of: selected_segment, perform: {_ in
            let userDefaults = UserDefaults.standard
            if selected_segment == 0 {
                userDefaults.setValue("imperial", forKey: "weather_mode")
            }
            if selected_segment == 1 {
                userDefaults.setValue("metric", forKey: "weather_mode")
            }
        })
    }
}

struct new_location_search: View {
    @State var search: String = ""
    @State var is_validating: Bool = false
    @State var city_list = [WeatherSearch.List]()
    @State var should_perform_search: Bool = true
    @ObservedObject var keyboard = KeyboardResponder()
    @Binding var show_add_location: Bool
    @ObservedObject var weather_data: ObservableArray<WeatherObserver>
    @State var timer: Timer.TimerPublisher = Timer.publish (every: 0.25, on: .main, in: .common)
    @State var timer_elapsed: Float = 0.0
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    search_text_title_bar(search: $search, top_text:is_validating ? "Validating City..." : "Type the City, State, or ZIP code:", cancel_action: {withAnimation(){show_add_location.toggle()}}, show_cancel: true).frame(minHeight: 90, maxHeight: 90)
                    NoSepratorList_NonLazy {
                        ForEach(city_list, id: \.id) { index in
                            Button(action: {
                                if weather_data.array.count < 9 {
                                    weather_data.array.append(WeatherObserver(location: "\(index.name ?? ""),\(index.sys?.country ?? "")", mode:  UserDefaults.standard.object(forKey: "weather_mode") as? String ?? "imperial"))
                                let userDefaults = UserDefaults.standard
                                var weather_dict = [String:String]()
                                    var i = 0
                                    for item in weather_data.array {
                                        weather_dict["\(i)"] = (item.full_location != nil ? item.full_location : "")
                                        i += 1
                                    }
                                    var defaults_weather = (userDefaults.object(forKey: "weather_cities") as? [String:String] ?? ["0":""]).sorted(by: >)
                                    if defaults_weather != weather_dict.sorted(by: >) {
                                    userDefaults.setValue(weather_dict, forKey: "weather_cities")
                                }
                                }
                                withAnimation(){show_add_location.toggle()}
                            }) {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(alignment: .center) {
                                    Spacer().frame(width:1, height: 44-0.95)
                                    
                                    Text("\(index.name ?? ""), \(index.sys?.country ?? "")").font(.custom("Helvetica Neue Bold", fixedSize: 20)).foregroundColor(.black).lineLimit(1).padding(.trailing, 12)
                                }.padding([.leading], 8)
                                Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                
                            }
                        }
                        }.frame(height: 44)
                    
                    }.padding(.bottom, keyboard.currentHeight).edgesIgnoringSafeArea(.bottom).compositingGroup()
                }.background(Color.white)
            }
        }.onReceive(timer, perform: {_ in
            timer_elapsed += 0.25
            if timer_elapsed >= 1 && !search.isEmpty && should_perform_search {
                parse_search_data(search: search)
                should_perform_search = false
            }
        })
        
        .onChange(of: search, perform: {_ in
            timer_elapsed = 0
            is_validating = true
            should_perform_search = true
        }).onAppear() {
            self.timer.connect()
            UIScrollView.appearance().bounces = true
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
            self.timer.connect().cancel()
        }
    }

    func parse_search_data(search: String) {
        guard let find_search = search.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {return}
        let developed_string = "https://api.openweathermap.org/data/2.5/find?q=\(find_search)&appid=a287713003f81bf6e2f8a73fe70a5f6b"
        let search_url = URL(string: developed_string)!
        let request = URLRequest(url: search_url)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            
            if let error = error {
                print(error, "failed search")
                is_validating = false
                return
            }
            
            // Parse JSON data
            if let data = data {
                let decoder = JSONDecoder()
                
                do {
                    let loanDataStore = try decoder.decode(WeatherSearch.self, from: data)
                    DispatchQueue.main.async {
                        self.city_list = loanDataStore.list ?? []
                        is_validating = false
                    }
                    
                } catch {
                    is_validating = false
                  //  self.last_updated_text = "Update failed"
                    print(error, "failed search")
                }
            }
        })
        
        task.resume()
    }
    
}

func readLocalFile(name: String) -> Data? {
    do {
        if let bundlePath = Bundle.main.path(forResource: name,
                                             ofType: "json"),
            let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) {
            return jsonData
        }
    } catch {
        print(error)
    }
    
    return nil
}

struct Weather_City: Decodable {
    let id: Int?
    let name: String?
    let country: String?
}

struct search_text_title_bar: View {
    @Binding var search: String
    @State var place_holder = ""
    @State var editing_state: String = "Active_Empty"
    var top_text: String?
    var title: String?
    public var cancel_action: (() -> Void)?
    public var save_action: (() -> Void)?
    var show_cancel: Bool?
    var show_save: Bool?
    private let gradient = LinearGradient([.white, .white], to: .trailing)
    var body: some View {
        GeometryReader{ geometry in
            ZStack {
                LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.0), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.39), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.39), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.015)
                VStack {
                    HStack {
                        Spacer()
                        Text(top_text ?? "").foregroundColor(Color(red: 168/255, green: 168/255, blue: 168/255)).font(.custom("Helvetica Neue Regular", fixedSize: 14)).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0.0, y: -1).padding([.leading, .trailing], 24)
                        Spacer()
                    }.padding(.top, 12)
                    Spacer()
                    VStack {
                        Spacer()
                        HStack {
                            HStack {
                                Spacer(minLength: 5)
                                HStack (alignment: .center,
                                        spacing: 10) {
                                    Image("search_icon").resizable().font(Font.title.weight(.medium)).frame(width: 15, height: 15).padding(.leading, 5)

                                    TextField("", text: $search, onEditingChanged: { (changed) in
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
                                        withAnimation() {
                                            editing_state = "None"
                                            if search != "" {
                                            }
                                        }
                                    }.onChange(of: search) { _ in
                                        if search != "" {
                                            editing_state = "Active"
                                        } else {
                                            if editing_state != "None" {
                                                editing_state = "Active_Empty"
                                            }
                                        }
                                    }.keyboardType(.alphabet).disableAutocorrection(true)
                                    if search.count != 0 {
                                        Button(action:{search = ""}) {
                                            Image("UITextFieldClearButton")
                                        }.fixedSize()
                                    }
                                }

                                .padding([.top,.bottom], 5)
                                .padding(.leading, 5)
                                .cornerRadius(40)
                                Spacer(minLength: 8)
                            } .ps_innerShadow(.capsule(gradient), radius:1.6, offset: CGPoint(0, 1), intensity: 0.7).strokeCapsule(Color(red: 166/255, green: 166/255, blue: 166/255), lineWidth: 0.33).padding(.leading, 5.5).padding(.trailing, 5.5)
                            tool_bar_rectangle_button(action: {cancel_action?()}, button_type: .black, content: "Cancel").padding(.trailing, 5)
                        }
                        Spacer()
                    }

                    Spacer()
                }
                }
        }
    }
}



struct tool_bar_rectangle_button_background_image_weather: View {
    public var action: (() -> Void)?
    var button_type: tool_bar_button_type
    var content: String
    var use_image: Bool?
    private let gray_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    private let blue_gradient = LinearGradient([(color: Color(red: 120/255, green: 158/255, blue:237/255), location: 0), (color: Color(red: 55/255, green: 110/255, blue:224/255), location: 0.51), (color: Color(red: 34/255, green: 96/255, blue:221/255), location: 0.52), (color: Color(red: 36/255, green: 100/255, blue:224/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        Button(action:{action?()}) {
            ZStack {
                Image("UINavigationBarBlackTranslucentButton").frame(width: 32, height: 32).scaledToFill()
                Image(content).resizable().scaledToFit().frame(width: 13).padding([.leading, .trailing], 11)
                
            }
        }.frame(width: 32, height: 32).padding(.trailing, 40)
    }
}

struct weather_settings_title_bar : View {
    public var done_action: (() -> Void)?
    public var new_action: (() -> Void)?
    var show_done: Bool?
    var body :some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.02), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025).opacity(0.8)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("Weather").ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", fixedSize: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1)
                    Spacer()
                }
                Spacer()
            }
            if show_done == true {
            HStack {
                tool_bar_rectangle_button_background_image_weather(action:{new_action?()}, button_type: .blue_gray, content: "UIButtonBarPlus", use_image: true).padding(.leading, 8)
                Spacer()
            tool_bar_rectangle_button(action: {done_action?()}, button_type: .blue, content: "Done").padding(.trailing, 8)
            }
            }
        }
    }
}

//** MARK: Weather Content Views

extension Collection {
    
    subscript(optional i: Index) -> Iterator.Element? {
        return self.indices.contains(i) ? self[i] : nil
    }
    
}

extension Array {
    subscript (wrapping index: Int) -> Element {
        return self[(index % self.count + self.count) % self.count]
    }
}

struct weather_content_view_day: View {
    @ObservedObject var weatherData: WeatherObserver
    @Binding var show_settings: Bool
    @Binding var switch_to_settings: Bool
    @Binding var collapse_pager: Bool
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    Rectangle().fill(LinearGradient([Color(red: 51/255, green: 66/255, blue: 94/255), Color(red: 52/255, green: 67/255, blue: 95/255),  Color(red: 54/255, green: 70/255, blue: 98/255)], from: .top, to: .bottom)).frame(height: geometry.size.height*200/750)
                    ForEach(0..<6) { i in
                        let t = DateFormatter().weekdaySymbols[wrapping: Calendar.current.component(.weekday, from: Date()) - 1 + Int(i)]
                        //      let m = weatherData.forcast_data?.list?[optional: Int(i)]?.weather?[0].icon
                        VStack(spacing:0) {
                            if i == 0 {
                                Rectangle().fill(Color(red: 44/255, green: 56/255, blue: 79/255)).frame(height: 2)
                            }
                            if i != 5 {
                                Rectangle().fill(i % 2 == 0 ? LinearGradient([Color(red: 66/255, green: 85/255, blue: 120/255), Color(red: 66/255, green: 86/255, blue: 119/255)], from: .top, to: .bottom) : LinearGradient([Color(red: 56/255, green:72/255, blue: 98/255), Color(red: 57/255, green: 72/255, blue: 101/255)], from: .top, to: .bottom))
                            } else {
                                Rectangle().fill(LinearGradient([Color(red: 61/255, green: 77/255, blue: 104/255), Color(red: 62/255, green: 78/255, blue: 105/255)], from: .top, to: .bottom))
                            }
                            if i != 5 {
                                Rectangle().fill(Color(red: 44/255, green: 56/255, blue: 79/255)).frame(height: 2)
                            }
                        }.overlay(HStack {
                            HStack(spacing:0) {
                                Text("\(t)").font(.custom("Helvetica Neue Bold", fixedSize: 18)).textCase(.uppercase).foregroundColor(.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0, y: 1.5)
                                Spacer()
                            }.frame(width:geometry.size.width/2.5).padding(.leading, 8)
                            
                            
                            
                            Image(json_iconography_to_image(weatherData.forcast_data?.list?[optional: Int(i)]?.weather?[0].icon ?? "", is_mini: true))
                            
                            Spacer()
                            Text("\(Int(weatherData.forcast_data?.list?[optional: Int(i)]?.temp?.max ?? Double()) )°").font(.custom("Helvetica Neue Bold", fixedSize: 20)).foregroundColor(.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0, y: 1.5)
                            Text("\(Int(weatherData.forcast_data?.list?[optional: Int(i)]?.temp?.min ?? Double()) )°").font(.custom("Helvetica Neue Bold", fixedSize: 20)).foregroundColor(Color(red: 124/255, green: 149/255, blue: 189/255)).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0, y: 1.5).padding(.trailing, 8)
                        })
                    }
                    Rectangle().fill(LinearGradient([Color(red: 62/255, green: 78/255, blue: 105/255), Color(red: 62/255, green: 77/255, blue: 106/255)], from: .top, to: .bottom)).frame(height: geometry.size.height*34/750)
                }.cornerRadius(12).strokeRoundedRectangle(12, Color(red: 101/255, green: 113/255, blue: 134/255), lineWidth: 4)
                .padding([.leading, .trailing], 18).padding([.top, .bottom], 4).overlay(VStack(spacing: 0) {
                    Rectangle().fill(LinearGradient([(color: Color.white, location: 0.2), (color: Color(red: 80/255, green: 84/255, blue: 89/255), location: 1)], from: .top, to: .bottom)).frame(height: geometry.size.height*230/(750*4)).opacity(0.20)
                    Spacer()
                }.cornerRadius(12*18/16).padding([.leading, .trailing], 16).padding([.top], 2))
                
                VStack(spacing: 0) {
                    weather_header(weatherData: weatherData).frame(height: geometry.size.height*200/750)
                    Spacer()
                    HStack {
                        Image("yahoo_button").padding(.leading, 8)
                        Spacer()
                        Text("\(weatherData.last_updated_text)").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0, y: 1.5)
                        Spacer()
                        Button(action:{
                                collapse_pager = true
                            withAnimation(.easeIn(duration: 0.4)){
                                withAnimation(.easeIn(duration: 0.4)){switch_to_settings.toggle()}
                                DispatchQueue.main.asyncAfter(deadline:.now()+0.4) { //maybe 0.45
                                    withAnimation(.easeOut(duration: 0.4)){show_settings.toggle()}
                                }
                            }}) {
                            Image("info").padding(.trailing, 8)
                        }
                    }.padding(.bottom, 8)
                }.cornerRadius(12)    .padding([.leading, .trailing], 18).padding([.top, .bottom], 4)
            }
        }
    }
}

struct weather_content_view_night_2: View {
    @ObservedObject var weatherData: WeatherObserver
    @Binding var show_settings: Bool
    @Binding var switch_to_settings: Bool
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    Rectangle().fill(LinearGradient([Color(red: 52/255, green: 34/255, blue: 50/255)], from: .top, to: .bottom)).frame(height: geometry.size.height*200/750)
                    ForEach(0..<6) { i in
                        let t = DateFormatter().weekdaySymbols[wrapping: Calendar.current.component(.weekday, from: Date()) - 1 + Int(i)]
                        //      let m = weatherData.forcast_data?.list?[optional: Int(i)]?.weather?[0].icon
                        VStack(spacing:0) {
                            if i == 0 {
                                Rectangle().fill(Color(red: 49/255, green: 32/255, blue: 47/255)).frame(height: 2)
                            }
                            Rectangle().fill(i % 2 == 0 ? LinearGradient([Color(red: 64/255, green: 41/255, blue: 60/255)], from: .top, to: .bottom) : LinearGradient([Color(red: 52/255, green:34/255, blue: 50/255)], from: .top, to: .bottom))
                            if i != 5 {
                                Rectangle().fill(Color(red: 49/255, green: 32/255, blue: 47/255)).frame(height: 2)
                            }
                        }.overlay(HStack {
                            HStack(spacing:0) {
                                Text("\(t)").font(.custom("Helvetica Neue Bold", fixedSize: 18)).textCase(.uppercase).foregroundColor(.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0, y: 1.5)
                                Spacer()
                            }.frame(width:geometry.size.width/2.5).padding(.leading, 8)
                            
                            
                            
                            Image(json_iconography_to_image(weatherData.forcast_data?.list?[optional: Int(i)]?.weather?[0].icon ?? "", is_mini: true))
                            
                            Spacer()
                            Text("\(Int(weatherData.forcast_data?.list?[optional: Int(i)]?.temp?.max ?? Double()) )°").font(.custom("Helvetica Neue Bold", fixedSize: 20)).foregroundColor(.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0, y: 1.5)
                            Text("\(Int(weatherData.forcast_data?.list?[optional: Int(i)]?.temp?.min ?? Double()) )°").font(.custom("Helvetica Neue Bold", fixedSize: 20)).foregroundColor(Color(red: 83/255, green: 76/255, blue: 84/255)).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0, y: 1.5).padding(.trailing, 8)
                        })
                    }
                    Rectangle().fill(LinearGradient([Color(red: 52/255, green: 34/255, blue: 50/255)], from: .top, to: .bottom)).frame(height: geometry.size.height*34/750)
                }.cornerRadius(12).strokeRoundedRectangle(12, Color(red: 93/255, green: 78/255, blue: 91/255), lineWidth: 4)
                .padding([.leading, .trailing], 18).padding([.top, .bottom], 4).overlay(VStack(spacing: 0) {
                    Rectangle().fill(LinearGradient([(color: Color.white, location: 0.2), (color: Color(red: 80/255, green: 84/255, blue: 89/255), location: 1)], from: .top, to: .bottom)).frame(height: geometry.size.height*230/(750*4)).opacity(0.20)
                    Spacer()
                }.cornerRadius(12*18/16).padding([.leading, .trailing], 16).padding([.top], 2))
                
                VStack(spacing: 0) {
                    weather_header(weatherData: weatherData).frame(height: geometry.size.height*200/750)
                    Spacer()
                    HStack {
                        Image("yahoo_button").padding(.leading, 8)
                        Spacer()
                        Text("\(weatherData.last_updated_text)").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0, y: 1.5)
                        Spacer()
                        Button(action:{
                            withAnimation(.easeIn(duration: 0.4)){
                                withAnimation(.easeIn(duration: 0.4)){switch_to_settings.toggle()} //Freezing for some reason
                                DispatchQueue.main.asyncAfter(deadline:.now()+0.35) { //maybe 0.45
                                    withAnimation(.easeOut(duration: 0.4)){show_settings.toggle()}
                                }
                            }}) {
                            Image("info").padding(.trailing, 8)
                        }
                    }.padding(.bottom, 8)
                }.cornerRadius(12)    .padding([.leading, .trailing], 18).padding([.top, .bottom], 4)
            }
        }
    }
}

struct weather_header: View {
    @ObservedObject var weatherData: WeatherObserver
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack() {
                VStack(alignment:.leading) {
                    Text("\(weatherData.location_string)").font(.custom("Helvetica Neue Bold", fixedSize: 20)).foregroundColor(.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0, y: 1.5)
                    Text("H: \(Int(weatherData.current_data?.main?.tempMax ?? Double()))° L: \(Int(weatherData.current_data?.main?.tempMin ?? Double()))°").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.white.opacity(0.8)).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0, y: 1.5)
                }.padding(.leading, 8).padding(.top, 40)
                Spacer()
                Group {
                    Text("\(Int(weatherData.current_data?.main?.temp ?? Double()))").font(.custom("Helvetica Neue Regular", fixedSize: 80)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0, y: 1.5)
                    Text("°").font(.custom("Helvetica Neue Regular", fixedSize: 40)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0, y: 1.5).offset(x: -10, y: -14)
                }.padding(.leading, 4)
            }
        }
    }
}

//** MARK: Weather Data

class WeatherObserver: ObservableObject, Identifiable, Equatable {
    public static func == (lhs: WeatherObserver, rhs: WeatherObserver) -> Bool {
        return lhs.id == rhs.id
    }
    @Published var forcast_data: WeatherForecast?
    @Published var current_data: CurrentWeather?
    @Published var last_updated_text: String = ""
    @Published var location_string: String = ""
    @Published var full_location: String = ""
    var id = UUID()
    init(location: String, mode: String) {
        full_location = location
        location_string = location
        if let index = location.range(of: ",")?.lowerBound {
            let substring = location[..<index]
            location_string = String(substring)
        }
        parse_forcast_data(location: location, mode: mode)
        parse_current_data(location: location, mode: mode)
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy h:mm a"
        last_updated_text = "Updated \(formatter.string(from: Date()))"
    }
    static let long_format: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy h:mm a"
        return formatter
    }()
    func parse_forcast_data(location: String, mode: String) {
        guard let location_string = location.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {return}
        let developed_string = "https://api.openweathermap.org/data/2.5/forecast/daily?q=\(location_string),us&appid=a287713003f81bf6e2f8a73fe70a5f6b&units=\(mode)&cnt=6"
        let forcast_url = URL(string: developed_string)!
        let request = URLRequest(url: forcast_url)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            
            if let error = error {
                print(error, "failed update")
                self.last_updated_text = "Update failed"
                return
            }
            
            // Parse JSON data
            if let data = data {
                let decoder = JSONDecoder()
                
                do {
                    let loanDataStore = try decoder.decode(WeatherForecast.self, from: data)
                    DispatchQueue.main.async {
                        self.forcast_data = loanDataStore
                    }
                    
                } catch {
                    self.last_updated_text = "Update failed"
                    print(error, "failed update")
                }
            }
        })
        
        task.resume()
    }
    
    func parse_current_data(location: String, mode: String) {
        guard let location_string = location.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {return}
        //There's a very odd SwiftUI bug where if we properly format the url, it will fail to update our image header. This url will essentially be (location),(country),(country), instead of (location),(country). Why this happens is beyond me.
        let developed_string = "https://api.openweathermap.org/data/2.5/weather?q=\(location_string),us&appid=a287713003f81bf6e2f8a73fe70a5f6b&units=\(mode)"
        let current_url = URL(string: developed_string)!
        print(current_url)
        let request = URLRequest(url: current_url)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            
            if let error = error {
                print(error)
                self.last_updated_text = "Update failed"
                return
            }
            print("Here1, ZSK")
            // Parse JSON data
            if let data = data {
                let decoder = JSONDecoder()
                print("Here2, ZSK")
                do {
                    let loanDataStore = try decoder.decode(CurrentWeather.self, from: data)
                    print(loanDataStore.weather?[0].icon, "ZSK")
                    DispatchQueue.main.async {
                        self.objectWillChange.send()
                        self.current_data = loanDataStore
                        print(self.current_data?.weather?[0].icon, "ZSK")
                    }
                    
                } catch {
                    self.last_updated_text = "Update failed"
                    print(error)
                }
            }
        })
        
        task.resume()
    }
    
}

struct WeatherForecast: Codable {
    struct City: Codable {
        struct Coord: Codable {
            let lon: Double?
            let lat: Double?
        }
        
        let id: Int?
        let name: String?
        let coord: Coord?
        let country: String?
        let population: Int?
        let timezone: Int?
    }
    
    struct List: Codable {
        struct Temp: Codable {
            let day: Double?
            let min: Double?
            let max: Double?
            let night: Double?
            let eve: Double?
            let morn: Double?
        }
        
        struct FeelsLike: Codable {
            let day: Double?
            let night: Double?
            let eve: Double?
            let morn: Double?
        }
        
        struct Weather: Codable {
            let id: Int?
            let main: String?
            let description: String?
            let icon: String?
        }
        
        let dt: Date?
        let sunrise: Date?
        let sunset: Date?
        let temp: Temp?
        let feelsLike: FeelsLike?
        let pressure: Int?
        let humidity: Int?
        let weather: [Weather]?
        let speed: Double?
        let deg: Int?
        let clouds: Int?
        let pop: Double?
        let rain: Double?
        
        private enum CodingKeys: String, CodingKey {
            case dt
            case sunrise
            case sunset
            case temp
            case feelsLike = "feels_like"
            case pressure
            case humidity
            case weather
            case speed
            case deg
            case clouds
            case pop
            case rain
        }
    }
    
    let city: City?
  let cod: String?
let message: Double?
    let cnt: Int?
    let list: [List]?
}

import Foundation

struct CurrentWeather: Codable {
    struct Coord: Codable {
        let lon: Double?
        let lat: Double?
    }
    
    struct Weather: Codable {
        let id: Int?
        let main: String?
        let description: String?
        let icon: String?
    }
    
    struct Main: Codable {
        let temp: Double?
        let feelsLike: Double?
        let tempMin: Double?
        let tempMax: Double?
        let pressure: Int?
        let humidity: Int?
        
        private enum CodingKeys: String, CodingKey {
            case temp
            case feelsLike = "feels_like"
            case tempMin = "temp_min"
            case tempMax = "temp_max"
            case pressure
            case humidity
        }
    }
    
    struct Wind: Codable {
        let speed: Double?
        let deg: Int?
    }
    
    struct Rain: Codable {
        let _1h: Double?
        
        private enum CodingKeys: String, CodingKey {
            case _1h = "1h"
        }
    }
    
    struct Clouds: Codable {
        let all: Int?
    }
    
    struct Sys: Codable {
        let type: Int?
        let id: Int?
        let country: String?
        let sunrise: Date?
        let sunset: Date?
    }
    
    let coord: Coord?
    let weather: [Weather]?
    let base: String?
    let main: Main?
    let visibility: Int?
    let wind: Wind?
    let rain: Rain?
    let clouds: Clouds?
    let dt: Date?
    let sys: Sys?
    let timezone: Int?
    let id: Int?
    let name: String?
    let cod: Int?
}

struct WeatherSearch: Codable {
  struct List: Codable {
    struct Coord: Codable {
      let lat: Double?
      let lon: Double?
    }

    struct Main: Codable {
      let temp: Double?
      let feelsLike: Double?
      let tempMin: Double?
      let tempMax: Double?
      let pressure: Int?
      let humidity: Int?
      let seaLevel: Int?
      let grndLevel: Int?

      private enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure
        case humidity
        case seaLevel = "sea_level"
        case grndLevel = "grnd_level"
      }
    }

    struct Wind: Codable {
      let speed: Double?
      let deg: Int?
    }

    struct Sys: Codable {
      let country: String?
    }

    struct Clouds: Codable {
      let all: Int?
    }

    struct Weather: Codable {
      let id: Int?
      let main: String?
      let description: String?
      let icon: String?
    }

    let id: Int?
    let name: String?
    let coord: Coord?
    let main: Main?
    let dt: Date?
    let wind: Wind?
    let sys: Sys?
   // let rain: Any?
  //  let snow: Any?
    let clouds: Clouds?
    let weather: [Weather]?
  }

  let message: String?
  let cod: String?
  let count: Int?
  let list: [List]?
}

func json_iconography_to_image(_ input: String, is_mini: Bool) -> String {
    if input.contains("n") {
        return "moon"
    }
    if input.contains("d") {
        switch input {
        case "01d":
            return "weather\(is_mini == true ? "_mini" : "")_sun"
        case "02d":
            return "weather\(is_mini == true ? "_mini" : "")_partly_cloudy"
        case "03d":
            return "weather\(is_mini == true ? "_mini" : "")_cloudy"
        case "04d":
            return "weather\(is_mini == true ? "_mini" : "")_partly_cloudy"
        case "09d":
            return "weather\(is_mini == true ? "_mini" : "")_rain_clouds"
        case "10d":
            return "weather\(is_mini == true ? "_mini" : "")_rain"
        case "11d":
            return "weather\(is_mini == true ? "_mini" : "")_lightning"
        case "13d":
            return "weather\(is_mini == true ? "_mini" : "")_snow"
        case "50d":
            return "weather\(is_mini == true ? "_mini" : "")_fog"
        default:
            return "weather\(is_mini == true ? "_mini" : "")_fog"
        }
    }
    else {
        return ""
    }
}

func json_iconography_to_offset(_ input: String) -> CGFloat {
    if input.contains("n") {
        return 40
    }
    if input.contains("d") {
        switch input {
        case "01d":
            return 0
        case "02d":
            return 0
        case "03d":
            return 20
        case "04d":
            return 0
        case "09d":
            return 15
        case "10d":
            return 22.5
        case "11d":
            return 25
        case "13d":
            return 10
        case "50d":
            return 15
        default:
            return 15
        }
    }
    else {
        return 0
    }
}

//struct Weather_Previews: PreviewProvider {
//    static var previews: some View {
//        Weather()
//    }
//}
