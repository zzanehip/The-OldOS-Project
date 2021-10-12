//
//  Phone.swift
//  OldOS
//
//  Created by Zane Kleinberg on 2/28/21.
//

import SwiftUI
import AVFoundation
import Contacts
import CoreTelephony
struct Phone: View {
    @State var selectedTab = "Favorites"
    @State var current_nav_view: String = "Main"
    @State var forward_or_backward = false
    @State var contacts_current_nav_view: String = "Contacts"
    @State var current_contact: CNContact = CNContact()
    @State var show_add_contact: Bool = false
    @State var show_edit: Bool = false
    @State var show_add_favorite: Bool = false
    @State var show_recents_clear: Bool = false
    @State var selected_segment: Int = 0
    @ObservedObject var favorites_obs = favorites_observer()
    @ObservedObject var recents_obs = recents_observer()
    @Binding var instant_multitasking_change: Bool
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing:0) {
                    status_bar_in_app().frame(minHeight: 24, maxHeight:24).zIndex(1)
                    if selectedTab != "Keypad" {
                        phone_title_bar(title:selectedTab == "Contacts" ? contacts_current_nav_view != "Contacts" ? "Info" : "All Contacts" : selectedTab, forward_or_backward: $forward_or_backward, selectedTab: $selectedTab, contacts_current_nav_view: $contacts_current_nav_view, is_editing_favorites: $show_edit, selected_segment: $selected_segment, instant_multitasking_change: $instant_multitasking_change, favorites_obs: favorites_obs, recents_obs: recents_obs, show_edit: selectedTab == "Favorites" ? true : false, show_plus: selectedTab == "Favorites" ? show_edit == false ? true : false : false, edit_action: {
                            if selectedTab == "Favorites" {
                                withAnimation {
                                show_edit.toggle()
                                }
                            }
                            if selectedTab == "Recents" {
                                withAnimation() {
                                    show_recents_clear.toggle()
                                }
                            }
                        }, plus_action: {
                            if selectedTab == "Favorites" {
                                withAnimation {
                                show_add_favorite.toggle()
                                }
                            }
                        }).frame(height:60)
                    }
                    PhoneTabView(selectedTab: $selectedTab, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, contacts_current_nav_view: $contacts_current_nav_view, current_contact: $current_contact, show_add_contact: $show_add_contact, show_edit: $show_edit, selected_segment: $selected_segment, favorites_obs: favorites_obs, recents_obs: recents_obs).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                }
                if show_add_contact {
                    add_contact_view(show_add_contact: $show_add_contact).transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom))).zIndex(1).clipped().compositingGroup()
                }
                if show_add_favorite {
                    add_favorites_view(favorites_obs: favorites_obs, show_add_favorite: $show_add_favorite).transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom))).zIndex(1).clipped().compositingGroup()
                }
                ZStack {
                if show_recents_clear == true {
                    Color.black.opacity(0.35)
                    VStack(spacing:0) {
                        Spacer().foregroundColor(.clear).zIndex(0)
                        clear_recents_view(cancel_action: {withAnimation{show_recents_clear.toggle()}}, clear_action: {withAnimation() {
                            recents_obs.recents.removeAll()
                            show_recents_clear.toggle()
                        }}).frame(minHeight: geometry.size.height*(1/3.6), maxHeight: geometry.size.height*(1/3.6))
                    }.transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom)))
               }//We nest this in a VStack to get around type check errors
                }.zIndex(3)
            }.compositingGroup().clipped()
        }.onAppear() {
            UIScrollView.appearance().bounces = true
            UITableView.appearance().backgroundColor = .clear
            UITableView.appearance().showsVerticalScrollIndicator = false
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
            UITableView.appearance().showsVerticalScrollIndicator = true
        }
    }
}

var phone_tabs = ["Favorites", "Recents", "Contacts", "Keypad", "Voicemail"]
struct PhoneTabView : View {
    
    @Binding var selectedTab:String
    @State var edge = UIApplication.shared.windows.first?.safeAreaInsets
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var contacts_current_nav_view: String
    @Binding var current_contact: CNContact
    @Binding var show_add_contact: Bool
    @Binding var show_edit: Bool
    @Binding var selected_segment: Int
    @ObservedObject var favorites_obs: favorites_observer
    @ObservedObject var recents_obs: recents_observer
    var body: some View{
        GeometryReader {geometry in
            VStack(spacing:0) {
                
                ScrollView([], showsIndicators: false) {
                    switch selectedTab {
                    case "Favorites":
                        favorites_view(favorites_obs: favorites_obs, recents_obs: recents_obs, show_edit: $show_edit).frame(height: geometry.size.height - 57)
                            .tag("Favorites")
                    case "Recents":
                        recents_view(recents_obs: recents_obs, selected_segment: $selected_segment).frame(height: geometry.size.height - 57)
                            .tag("Recents")
                    case "Contacts":
                        contacts_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, contacts_current_nav_view: $contacts_current_nav_view, current_contact: $current_contact, recents_obs: recents_obs).frame(height: geometry.size.height - 57)
                            .tag("Contacts")
                    case "Keypad":
                        phone_keypad_view(show_add_contact: $show_add_contact, recents_obs: recents_obs)
                            .tag("Keypad")
                    case "Voicemail":
                        voicemail_view().frame(height: geometry.size.height - 57).tag("Voicemail")
                    default:
                        blank() .tag("Favorites")
                    }
                }.background(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0), .init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0.5), .init(color: Color.white, location: 0.5), .init(color: Color.white, location: 1)]), startPoint: .top, endPoint: .bottom))
                // for bottom overflow...
                ZStack {
                    Rectangle().fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.02), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom)).frame(height:57)
                    HStack(spacing: 0){
                        
                        ForEach(phone_tabs,id: \.self){image in
                            TabButton_Phone(image: image, selectedTab: $selectedTab, geometry: geometry)
                            
                            // equal spacing...
                            
                            if image != phone_tabs.last{
                                
                                Spacer(minLength: 0)
                            }
                        }
                    }.frame(height:55)
                }.padding(.bottom, 0)
            }
        }
    }
    
}

struct voicemail_view: View {
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            VStack() {
                Spacer()
                HStack {
                    Image("VMOutOfOrderImage").resizable().scaledToFit().padding([.leading, .trailing], 60)
                }
                Spacer().frame(height:35)
                HStack {
                    Spacer()
                    Text("Cannot Connect\nto Voicemail") .font(.custom("Helvetica Neue Bold", fixedSize: 20))
                        .foregroundColor(Color(red: 98/255, green: 106/255, blue: 121/255)).multilineTextAlignment(.center)
                    Spacer()
                }
                Spacer()
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9).fill(LinearGradient([Color(red: 252/255, green: 253/255, blue: 253/255), Color(red: 232/255, green: 235/255, blue: 241/255)], from: .top, to: .bottom)).addBorder(Color(red: 138/255, green: 147/255, blue: 167/255), width: 0.8, cornerRadius: 11).padding([.leading, .trailing], 25).frame(height: 50)
                        Text("Call \(CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.first?.value.carrierName ?? "")").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color(red: 102/255, green: 106/255, blue: 113/255))
                    }
                }.padding(.bottom, 25)
            }
        }
    }
}

struct clear_recents_view: View {
    public var cancel_action: (() -> Void)?
    public var clear_action: (() -> Void)?
    private let background_gradient = LinearGradient(gradient: Gradient(colors: [Color.init(red: 70/255, green: 73/255, blue: 81/255), Color.init(red: 70/255, green: 73/255, blue: 81/255)]), startPoint: .top, endPoint: .bottom)
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                VStack(spacing:0) {
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 166/255, green: 171/255, blue: 179/255).opacity(0.88), Color.init(red: 122/255, green: 127/255, blue: 138/255).opacity(0.88)]), startPoint: .top, endPoint: .bottom)).innerShadowBottom(color: Color.white.opacity(0.98), radius: 0.1).border_top(width: 1, edges:[.top], color: Color.black).frame(height:30)
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 96/255, green: 101/255, blue: 111/255).opacity(0.88), Color.init(red: 96/255, green: 101/255, blue: 111/255).opacity(0.9)]), startPoint: .top, endPoint: .bottom))
                }
                VStack {
                    Button(action:{
                        clear_action?()
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color.clear).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5)).ps_innerShadow(.roundedRectangle(12, background_gradient), radius:5/3, offset: CGPoint(0, 1/3), intensity: 1)
                            RoundedRectangle(cornerRadius: 9).fill(returnLinearGradient(.red)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Clear All Recents").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0.0, y: -0.6)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.bottom], 2.5).padding(.top, 28)
                    Spacer()
                    Button(action:{
                      cancel_action?()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color.clear).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5)).ps_innerShadow(.roundedRectangle(12, background_gradient), radius:5/3, offset: CGPoint(0, 1/3), intensity: 1)
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient([(color: Color(red: 107/255, green: 113/255, blue:119/255), location: 0), (color: Color(red: 53/255, green: 62/255, blue:69/255), location: 0.50), (color: Color(red: 41/255, green: 48/255, blue:57/255), location: 0.50), (color: Color(red: 56/255, green: 62/255, blue:71/255), location: 1)], from: .top, to: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.gray.opacity(0.9), Color.gray.opacity(0.35)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3).opacity(0.6)
                            Text("Cancel").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0.0, y: -0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.bottom], 25)
                }
            }.drawingGroup()
        }
    }
}


struct recents_view: View {
    @ObservedObject var recents_obs: recents_observer
    @Binding var selected_segment: Int
    var body: some View {
        ZStack {
            if selected_segment == 0 {
        NoSepratorList {
            ForEach(recents_obs.recents.reversed(), id:\.id) { recent in
                Button(action:{
                    if recent.number != "" {
                        callNumber(String(recent.number.filter { !" \n\t\r".contains($0) }))
                        print((String(recent.number.filter { !" \n\t\r".contains($0) })))
                    }
                }) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center) {
                        Spacer().frame(width:1, height: 44-0.95)
                        VStack(alignment: .leading, spacing: 1.5) {
                            Text(recent.number).font(.custom("Helvetica Neue Bold", fixedSize: 15.5)).foregroundColor(.black).lineLimit(1)
                            HStack {
                            Text(recent.type).font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1)
                            Image("outgoingcall")
                                Spacer()
                            }
                        }.padding(.trailing, 12)
                        Spacer()
                        Text(format_date(recent.date)).font(.custom("Helvetica Neue Regular", fixedSize: 14.5)).foregroundColor(Color(red: 58/255, green: 111/255, blue: 209/255))
                        Image("ABTableNextButton").padding(.trailing, 11).transition(.opacity)
                    }.padding(.leading, 11)
                    Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)

                }
                }
            }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 44).drawingGroup()
        }.background(Color.white)
            } else {
                Color.white.edgesIgnoringSafeArea(.all)
            }
        }.clipped()
    }
    func format_date(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yy"
        return dateFormatter.string(from: date)
    }
}

class recents_observer: ObservableObject {
    @Published var recents: [recents_datatype] {
        didSet {
            do {
                let encoder = JSONEncoder()
                if let encoded = try? encoder.encode(self.recents) {
                    UserDefaults.standard.set(encoded, forKey: "recents")
                    objectWillChange.send()
                 }
            } catch {
            print("Couldn't write file")
            }
        }
    }
    
    init() {
        if let recents = UserDefaults.standard.data(forKey: "recents") {
              let decoder = JSONDecoder()
              if let decoded = try? decoder.decode([recents_datatype].self, from: recents) {
                  self.recents = decoded
              }  else {
                self.recents = []
            }
        } else {
            self.recents = []
        }
    }
}

struct recents_datatype: Identifiable, Codable, Equatable{
    var id = UUID()
    var date: Date
    var number: String
    var type: String
}

struct favorites_view: View {
    @ObservedObject var favorites_obs: favorites_observer
    @ObservedObject var recents_obs: recents_observer
    @Binding var show_edit: Bool
    @State var to_delete: favorite_datatype?
    var body: some View {
        NoSepratorList {
            ForEach(favorites_obs.favorites, id:\.id) { favorite in
                Button(action:{
                    if show_edit == false {
                    if favorite.number != "" {
                        callNumber(String(favorite.number.filter { !" \n\t\r".contains($0) }))
                        recents_obs.recents.append(recents_datatype(date: Date(), number: favorite.number, type: favorite.type))
                        print((String(favorite.number.filter { !" \n\t\r".contains($0) })))
                    }
                    }
                }) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center) {
                        Spacer().frame(width:1, height: 44-0.95)
                        if show_edit == true {
                            Button(action:{
                                withAnimation(.linear(duration:0.15)) {
                                    if (to_delete ?? nil) != favorite {
                                    to_delete = favorite
                                    } else {
                                        to_delete = nil
                                    }
                                }
                            }) {
                                ZStack {
                                Image("UIRemoveControlMinus")
                                    Text("—").foregroundColor(.white).font(.system(size: 15, weight: .heavy, design: .default)).offset(y: (to_delete ?? nil) == favorite ? -0.8 : -2).rotationEffect(.degrees((to_delete ?? nil) == favorite ? -90 : 0), anchor: .center).offset(y: (to_delete ?? nil) == favorite ? -0.5 : 0)
                                }
                            }.transition(AnyTransition.asymmetric(insertion: .move(edge:.leading), removal: .move(edge:.leading)).combined(with: .opacity)).offset(x:-2)
                        }
                        Text(favorite.name).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.trailing, 12)
                        if (to_delete ?? nil) != favorite {
                        Spacer()
                            Text(favorite.type).font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(Color(red: 85/255, green: 101/255, blue: 142/255)).transition(.opacity)
                        Image("ABTableNextButton").padding(.trailing, 11).transition(.opacity)
                        }
                        if  (to_delete ?? nil) == favorite {
                            Spacer()
                            tool_bar_rectangle_button(action: {withAnimation() {
                                if let idx = favorites_obs.favorites.firstIndex(where: { $0 == favorite }) {
                                    favorites_obs.favorites.remove(at: idx)
                                }
                            }}, button_type: .red, content: "Delete").padding(.trailing, 12).transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge:.trailing)).combined(with: .opacity))
                        }
                    }.padding(.leading, 11)
                    Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)

                }
                }
            }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 44).drawingGroup()
        }.background(Color.white)
    }
}

struct add_favorites_view: View {
    @State var editing_state: String = "None"
    @ObservedObject var contacts_observer = ContactStore()
    @ObservedObject var favorites_obs: favorites_observer
    @Binding var show_add_favorite: Bool
    var body: some View {
        VStack(spacing:0) {
            Spacer().frame(height:24)
            double_text_title_bar(top_text:"Choose a contact to add to Favorites", title: "All Contacts", cancel_action: {
                withAnimation(.linear(duration:0.35)) {
                    show_add_favorite.toggle()
                }
            }, show_cancel: true).frame(minHeight: 90, maxHeight: 90)
            SkeuomorphicList_Contacts_Add_To_Favorites(editing_state: $editing_state, indexes:  Array(Set(contacts_observer.contacts.compactMap({
            
            String(alphabet.contains(String(($0.familyName.prefix(1) ?? "") != "" ? ($0.familyName.prefix(1) ?? "") : $0.name.prefix(1) ?? "")) ? (($0.familyName.prefix(1) ?? "") != "" ? ($0.familyName.prefix(1) ?? "") : $0.name.prefix(1) ?? "") : "#")
            
        }))).sorted(by: {
            if $0.first?.isLetter == false && $1.first?.isLetter == true {
                return false
            }
            if $0.first?.isLetter == true && $1.first?.isLetter == false {
                return true
            }
            if $0.first?.isNumber == false && $1.first?.isNumber == true {
                return false
            }
            if $0.first?.isNumber == true && $1.first?.isNumber == false {
                return true
            }
            return $0 < $1
            
        }), contacts_observer: contacts_observer, favorites_obs: favorites_obs, show_add_favorite: $show_add_favorite).modifier(VerticalIndex(indexableList: alphabet, indexes: Array(Set(contacts_observer.contacts.compactMap({
            
            String(alphabet.contains(String(($0.familyName.prefix(1) ?? "") != "" ? ($0.familyName.prefix(1) ?? "") : $0.name.prefix(1) ?? "")) ? (($0.familyName.prefix(1) ?? "") != "" ? ($0.familyName.prefix(1) ?? "") : $0.name.prefix(1) ?? "") : "#")
            
        }))), editing_state: $editing_state)).offset(y:-1.2).background(Color.white).clipped()
      
        }
    }
}

struct double_text_title_bar: View {
    var top_text: String?
    var title: String?
    public var cancel_action: (() -> Void)?
    public var save_action: (() -> Void)?
    var show_cancel: Bool?
    var show_save: Bool?
    var body: some View {
        GeometryReader{ geometry in
            ZStack {
                LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.39), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.39), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
                VStack {
                    HStack {
                        Spacer()
                        Text(top_text ?? "").foregroundColor(Color(red: 47/255, green: 62/255, blue: 88/255)).font(.custom("Helvetica Neue Regular", fixedSize: 14)).shadow(color: Color.white.opacity(0.65), radius: 0, x: 0.0, y: 2/3).padding([.leading, .trailing], 24)
                        Spacer()
                    }.padding(.top, 12)
                    Spacer()
                    HStack {
                        Spacer()
                        Text(title ?? "").ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", fixedSize: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).id(title)
                        Spacer()
                    }
                    Spacer()
                }
            }
            if show_cancel == true {
                VStack {
                    Spacer()
                HStack {
                    Spacer()
                    tool_bar_rectangle_button(action: {cancel_action?()}, button_type: .blue_gray, content: "Cancel").padding(.trailing, 5)
                }.padding(.bottom, 12)
                }
            }
        }
    }
}

class favorites_observer: ObservableObject {
    @Published var favorites: [favorite_datatype] {
        didSet {
            do {
                let encoder = JSONEncoder()
                if let encoded = try? encoder.encode(self.favorites) {
                    UserDefaults.standard.set(encoded, forKey: "favorites")
                    objectWillChange.send()
                 }
            } catch {
            print("Couldn't write file")
            }
        }
    }
    
    init() {
        if let favorites = UserDefaults.standard.data(forKey: "favorites") {
              let decoder = JSONDecoder()
              if let decoded = try? decoder.decode([favorite_datatype].self, from: favorites) {
                  self.favorites = decoded
              }  else {
                self.favorites = []
            }
        } else {
            self.favorites = []
        }
    }
}

struct favorite_datatype: Identifiable, Codable, Equatable{
    var id = UUID()
    var name: String
    var number: String
    var type: String
}

struct contacts_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var contacts_current_nav_view: String
    @State var editing_state: String = "None"
    @Binding var current_contact: CNContact
    @ObservedObject var contacts_observer = ContactStore()
    @ObservedObject var recents_obs: recents_observer
    var body: some View {
        VStack(spacing:0) {
            switch contacts_current_nav_view {
            case "Contacts":
                SkeuomorphicList_Contacts(forward_or_backward: $forward_or_backward, current_nav_view: $current_nav_view, editing_state: $editing_state, contacts_current_nav_view: $contacts_current_nav_view, current_contact: $current_contact, indexes:  Array(Set(contacts_observer.contacts.compactMap({
                
                String(alphabet.contains(String(($0.familyName.prefix(1) ?? "") != "" ? ($0.familyName.prefix(1) ?? "") : $0.name.prefix(1) ?? "")) ? (($0.familyName.prefix(1) ?? "") != "" ? ($0.familyName.prefix(1) ?? "") : $0.name.prefix(1) ?? "") : "#")
                
            }))).sorted(by: {
                if $0.first?.isLetter == false && $1.first?.isLetter == true {
                    return false
                }
                if $0.first?.isLetter == true && $1.first?.isLetter == false {
                    return true
                }
                if $0.first?.isNumber == false && $1.first?.isNumber == true {
                    return false
                }
                if $0.first?.isNumber == true && $1.first?.isNumber == false {
                    return true
                }
                return $0 < $1
                
            }), contacts_observer: contacts_observer).modifier(VerticalIndex(indexableList: alphabet, indexes: Array(Set(contacts_observer.contacts.compactMap({
                
                String(alphabet.contains(String(($0.familyName.prefix(1) ?? "") != "" ? ($0.familyName.prefix(1) ?? "") : $0.name.prefix(1) ?? "")) ? (($0.familyName.prefix(1) ?? "") != "" ? ($0.familyName.prefix(1) ?? "") : $0.name.prefix(1) ?? "") : "#")
                
            }))), editing_state: $editing_state)).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Contacts_Desination":
                contacts_destination(contacts_current_nav_view: $contacts_current_nav_view, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, current_contact: current_contact, recents_obs: recents_obs).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            default:
                SkeuomorphicList_Contacts(forward_or_backward: $forward_or_backward, current_nav_view: $current_nav_view, editing_state: $editing_state, contacts_current_nav_view: $contacts_current_nav_view, current_contact: $current_contact, indexes:  Array(Set(contacts_observer.contacts.compactMap({
                    
                    String(alphabet.contains(String(($0.familyName.prefix(1) ?? "") != "" ? ($0.familyName.prefix(1) ?? "") : $0.name.prefix(1) ?? "")) ? (($0.familyName.prefix(1) ?? "") != "" ? ($0.familyName.prefix(1) ?? "") : $0.name.prefix(1) ?? "") : "#")
                    
                }))).sorted(by: {
                    if $0.first?.isLetter == false && $1.first?.isLetter == true {
                        return false
                    }
                    if $0.first?.isLetter == true && $1.first?.isLetter == false {
                        return true
                    }
                    if $0.first?.isNumber == false && $1.first?.isNumber == true {
                        return false
                    }
                    if $0.first?.isNumber == true && $1.first?.isNumber == false {
                        return true
                    }
                    return $0 < $1
                    
                }), contacts_observer: contacts_observer).modifier(VerticalIndex(indexableList: alphabet, indexes: Array(Set(contacts_observer.contacts.compactMap({
                    
                    String(alphabet.contains(String(($0.familyName.prefix(1) ?? "") != "" ? ($0.familyName.prefix(1) ?? "") : $0.name.prefix(1) ?? "")) ? (($0.familyName.prefix(1) ?? "") != "" ? ($0.familyName.prefix(1) ?? "") : $0.name.prefix(1) ?? "") : "#")
                    
                }))), editing_state: $editing_state)).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            }
        }.offset(y:-1.2)
    }
}

struct add_contact_view: View{
    @State var first_name: String = ""
    @State var last_name: String = ""
    @State var company: String = ""
    @State var phone: String = ""
    @State var email: String = ""
    @State var url: String = ""
    @Binding var show_add_contact: Bool
    var body: some View {
        VStack(spacing:0) {
            Spacer().frame(height:24)
            ZStack {
                settings_main_list()
                VStack(spacing:0) {
                    generic_title_bar_cancel_save(title: "New Contact", cancel_action: {withAnimation(.linear(duration:0.35)){show_add_contact.toggle()}}, save_action: {save_contact()}, show_cancel: true, show_save: true, switch_to_done: true).frame(height:60)
                    ScrollView {
                        VStack {
                            HStack(alignment: .top) {
                                Button(action:{}) {
                                    ZStack {
                                        Image("ABPictureDropWell").cornerRadius(4)
                                        VStack(spacing: 1) {
                                        Text("add").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(Color(red: 85/255, green: 101/255, blue: 142/255))
                                        Text("photo").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(Color(red: 85/255, green: 101/255, blue: 142/255))
                                        }
                                    }.padding([.leading, .trailing], 18)
                                }
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                                    .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25))
                                    VStack(spacing:0) {
                                        ZStack {
                                            Rectangle().fill(Color.clear).frame(height:50).border_bottom(width: 1.25, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))
                                            HStack {
                                                TextField("First", text: $first_name){
                                                }.font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.black).padding(.leading, 12)
                                                if first_name.count != 0 {
                                                    Button(action:{first_name = ""}) {
                                                        Image("UITextFieldClearButton")
                                                    }.fixedSize().padding(.trailing,12)
                                                }
                                            }
                                        }.frame(height: 50)
                                        ZStack {
                                            Rectangle().fill(Color.clear).frame(height:50).border_bottom(width: 1.25, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))
                                            HStack {
                                                TextField("Last", text: $last_name){
                                                }.font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.black).padding(.leading, 12)
                                                if last_name.count != 0 {
                                                    Button(action:{last_name = ""}) {
                                                        Image("UITextFieldClearButton")
                                                    }.fixedSize().padding(.trailing,12)
                                                }
                                            }
                                        }.frame(height: 50)
                                        ZStack {
                                            Rectangle().fill(Color.clear).frame(height:50)
                                            HStack {
                                                TextField("Company", text: $company){
                                                }.font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.black).padding(.leading, 12)
                                                if company.count != 0 {
                                                    Button(action:{company = ""}) {
                                                        Image("UITextFieldClearButton")
                                                    }.fixedSize().padding(.trailing,12)
                                                }
                                            }
                                        }.frame(height: 50)
                                    }
                                }.frame(height: 150).padding([.trailing], 12)
                            }.padding(.top, 20)
                            
                            HStack {
                                Spacer().frame(width: 45)
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                                .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25))
                                VStack(spacing:0) {
                                    ZStack {
                                        Rectangle().fill(Color.clear).frame(height:50)
                                        HStack(spacing: 5) {
                                            Text("mobile").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(Color(red: 85/255, green: 101/255, blue: 142/255)).multilineTextAlignment(.trailing).frame(width:75, alignment: .trailing).lineLimit(0).padding(.leading, 5)
                                            Rectangle().fill(Color(red: 191/255, green: 191/255, blue: 191/255)).frame(width: 1, height: 50)
                                            TextField("Phone", text: $phone){
                                            }.font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.black)
                                            if phone.count != 0 {
                                                Button(action:{phone = ""}) {
                                                    Image("UITextFieldClearButton")
                                                }.fixedSize().padding(.trailing,12)
                                            }
                                        }
                                    }.frame(height: 50)
                                }
                            }.frame(height: 50).padding([.trailing], 12)
                            
                            }.padding(.top, 10)
                            
                            HStack {
                                Spacer().frame(width: 45)
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                                .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25))
                                VStack(spacing:0) {
                                    ZStack {
                                        Rectangle().fill(Color.clear).frame(height:50)
                                        HStack(spacing: 5) {
                                            Text("home").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(Color(red: 85/255, green: 101/255, blue: 142/255)).multilineTextAlignment(.trailing).frame(width:75, alignment: .trailing).lineLimit(0).padding(.leading, 5)
                                            Rectangle().fill(Color(red: 191/255, green: 191/255, blue: 191/255)).frame(width: 1, height: 50)
                                            TextField("Email", text: $email){
                                            }.font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.black)
                                            if email.count != 0 {
                                                Button(action:{email = ""}) {
                                                    Image("UITextFieldClearButton")
                                                }.fixedSize().padding(.trailing,12)
                                            }
                                        }
                                    }.frame(height: 50)
                                }
                            }.frame(height: 50).padding([.trailing], 12)
                            
                            }.padding(.top, 10)
                            
                            HStack {
                                Spacer().frame(width: 45)
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                                .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25))
                                VStack(spacing:0) {
                                    ZStack {
                                        Rectangle().fill(Color.clear).frame(height:50).border_bottom(width: 1.25, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))
                                        HStack(spacing: 5) {
                                            Text("ringtone").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(Color(red: 85/255, green: 101/255, blue: 142/255)).multilineTextAlignment(.trailing).frame(width:75, alignment: .trailing).lineLimit(0).padding(.leading, 5)
                                            Rectangle().fill(Color.clear).frame(width: 1, height: 50)
                                          Text("Default").font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.black)
                                            Spacer()
                                        }
                                    }.frame(height: 50)
                                    ZStack {
                                        Rectangle().fill(Color.clear).frame(height:50)
                                        HStack(spacing: 5) {
                                            Text("text tone").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(Color(red: 85/255, green: 101/255, blue: 142/255)).multilineTextAlignment(.trailing).frame(width:75, alignment: .trailing).lineLimit(0).padding(.leading, 5)
                                            Rectangle().fill(Color.clear).frame(width: 1, height: 50)
                                          Text("Default").font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.black)
                                            Spacer()
                                        }
                                    }.frame(height: 50)
                                }
                            }.frame(height: 100).padding([.trailing], 12)
                            
                            }.padding(.top, 10)
                            
                            HStack {
                                Spacer().frame(width: 45)
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                                .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25))
                                VStack(spacing:0) {
                                    ZStack {
                                        Rectangle().fill(Color.clear).frame(height:50)
                                        HStack(spacing: 5) {
                                            Text("home page").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(Color(red: 85/255, green: 101/255, blue: 142/255)).multilineTextAlignment(.trailing).frame(width:75, alignment: .trailing).lineLimit(0).padding(.leading, 5)
                                            Rectangle().fill(Color(red: 191/255, green: 191/255, blue: 191/255)).frame(width: 1, height: 50)
                                            TextField("URL", text: $url){
                                            }.font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.black)
                                            if url.count != 0 {
                                                Button(action:{url = ""}) {
                                                    Image("UITextFieldClearButton")
                                                }.fixedSize().padding(.trailing,12)
                                            }
                                        }
                                    }.frame(height: 50)
                                }
                            }.frame(height: 50).padding([.trailing], 12)
                            
                            }.padding(.top, 10)
                            
                        }
                    }
                }
            }
        }
    }
    
    func save_contact() {
        if first_name != "" || first_name != "" || last_name != "" || company != "" || phone != "" || email != "" || url != "" {
            let contact = CNMutableContact()
            contact.givenName = first_name + " " + last_name
            contact.jobTitle = company
            let phoneNumber = CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: phone))
            let userEmail = CNLabeledValue(label:CNLabelHome, value:email as NSString)
            let userURL = CNLabeledValue(label: CNLabelURLAddressHomePage, value: url as NSString)
            contact.emailAddresses = [userEmail]
            contact.phoneNumbers = [phoneNumber]
            contact.urlAddresses = [userURL]
            do {
                let saveRequest = CNSaveRequest()
                saveRequest.add(contact, toContainerWithIdentifier: nil)
                try CNContactStore().execute(saveRequest)
                withAnimation(.linear(duration:0.35)){show_add_contact.toggle()}
                print("saved")
            } catch {
                print("error")
            }
        }
    }
}



struct contacts_destination: View {
    @Binding var contacts_current_nav_view: String
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var current_contact: CNContact
    @State var phone_content = [list_row]()
    @State var email_content = [list_row]()
    @ObservedObject var recents_obs: recents_observer
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                settings_main_list()
            ScrollView(showsIndicators: true) {
                VStack {
                    HStack() {
                        if current_contact.imageDataAvailable == false {
                        Image("ABPicturePerson").padding(.leading, 22)
                        } else {
                            Image(uiImage: (UIImage(data: current_contact.imageData ?? Data()) ?? UIImage(named:"ABPicturePerson")) ?? UIImage()).resizable().aspectRatio(contentMode: .fill).background(Color(red: 246/255, green: 246/255, blue: 250/255)).frame(width: 66, height: 64).mask(Image("ABPictureOutline").compositingGroup() .background(Color.white).luminanceToAlpha()).overlay(Image("ABPictureOutline")).padding(.leading, 22)
                        }
                        Text(current_contact.name).font(.custom("Helvetica Neue Bold", fixedSize: 20)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).lineLimit(0).padding(.leading, 5)
                        Spacer()
                    }.padding(.top, 20)
                    Spacer().frame(height:20)
                    list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: phone_content)
                    Spacer().frame(height:20)
                    list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: email_content)
                    Spacer().frame(height:20)
                    HStack(spacing: 0) {
                    list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: [list_row(title: "", content: AnyView(multiline_text_content(first_line: "Text", second_line: "Message")))])
                    list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: [list_row(title: "", content: AnyView(multiline_text_content(first_line: "Share", second_line: "Contact")))])
                    list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: [list_row(title: "", content: AnyView(multiline_text_content(first_line: "Add to", second_line: "Favorites")))])
                    }
                    Spacer()
                }
            }
            }
        }.onAppear() {
            for number in current_contact.phoneNumbers {
                phone_content.append(list_row(title: "", content: AnyView(contacts_destination_content(type:  CNLabeledValue<NSString>.localizedString(forLabel: number.label ?? "other") ?? "other", number: number.value.stringValue ?? "", recents_obs: recents_obs))))
            }
            for email in current_contact.emailAddresses {
                email_content.append(list_row(title: "", content: AnyView(contacts_destination_content_email(type:  CNLabeledValue<NSString>.localizedString(forLabel: email.label ?? "other") ?? "other", number: email.value as String))))
            }
        }
    }
}

struct multiline_text_content: View {
    var first_line: String
    var second_line: String
    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .center) {
            Text(first_line).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(Color(red: 85/255, green: 101/255, blue: 142/255)).multilineTextAlignment(.center).frame(width:75, alignment: .center).lineLimit(0)
                Text(second_line).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(Color(red: 85/255, green: 101/255, blue: 142/255)).multilineTextAlignment(.center).frame(width:75, alignment: .center).lineLimit(0)
        }
            Spacer()
        }
    }
}

extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}

struct contacts_destination_content: View {
    var type: String
    var number: String
    @ObservedObject var recents_obs: recents_observer
    var body: some View {
        Button(action:{
            callNumber(String(number.filter { !" \n\t\r".contains($0) }))
            recents_obs.recents.append(recents_datatype(date: Date(), number: number, type: type))
        }) {
        HStack {
            Text(type).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(Color(red: 85/255, green: 101/255, blue: 142/255)).multilineTextAlignment(.trailing).frame(width:75, alignment: .trailing).lineLimit(0)
            Text(number).font(.custom("Helvetica Neue Bold", fixedSize: 15)).padding(.leading, 5)
            Spacer()
        }
        }.buttonStyle(PlainButtonStyle())
    }
}

struct contacts_destination_content_email: View {
    var type: String
    var number: String
    var body: some View {
        Button(action:{
        }) {
        HStack {
            Text(type).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(Color(red: 85/255, green: 101/255, blue: 142/255)).multilineTextAlignment(.trailing).frame(width:75, alignment: .trailing).lineLimit(0)
            Text(number).font(.custom("Helvetica Neue Bold", fixedSize: 15)).padding(.leading, 5)
            Spacer()
        }
    }.buttonStyle(PlainButtonStyle())
    }
}


struct SkeuomorphicList_Contacts: View {
    @Binding var forward_or_backward: Bool
    @Binding var current_nav_view: String
    @Binding var editing_state: String
    @Binding var contacts_current_nav_view: String
    @Binding var current_contact: CNContact
    var indexes: [String]
    var contacts_observer: ContactStore
    @State var search = ""
    var body: some View {
        ZStack(alignment: .top) {
            List {
                ipod_search(search: $search, no_right_padding: editing_state != "None" ? true : false, editing_state:$editing_state).id("Search").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height:44).hideRowSeparator()
                ForEach(indexes, id: \.self) { letter in
                    Section(header: alpha_list_header(letter: letter).id(letter) .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                        ForEach(contacts_observer.contacts.filter({(contact: CNContact) -> Bool in
                            String(alphabet.contains(String((contact.familyName.prefix(1) ?? "") != "" ? (contact.familyName.prefix(1) ?? "") : contact.name.prefix(1) ?? "")) ? ((contact.familyName.prefix(1) ?? "") != "" ? (contact.familyName.prefix(1) ?? "") : contact.name.prefix(1) ?? "") : "#") == letter
                            
                        }), id: \.self.name) { (contact: CNContact) in
                            Button(action:{
                                current_contact = contact
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    forward_or_backward = false; withAnimation(.linear(duration: 0.28)){contacts_current_nav_view = "Contacts_Desination"}
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Spacer()
                                    HStack() {
                                        Group{Text(contact.givenName ?? "").font(contact.familyName == "" ? .custom("Helvetica Neue Bold", fixedSize: 18) : .custom("Helvetica Neue SemiBold", fixedSize: 18)) + Text(" ").font(.custom("Helvetica Neue SemiBold", fixedSize: 18)) + Text(contact.familyName ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 18))}.padding(.leading, 11).padding(.trailing, 40)
                                        Spacer()
                                    }
                                    Spacer()
                                    Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all).opacity(contact == contacts_observer.contacts.filter({(contact: CNContact) -> Bool in
                                        String(alphabet.contains(String((contact.familyName.prefix(1) ?? "") != "" ? (contact.familyName.prefix(1) ?? "") : contact.name.prefix(1) ?? "")) ? ((contact.familyName.prefix(1) ?? "") != "" ? (contact.familyName.prefix(1) ?? "") : contact.name.prefix(1) ?? "") : "#") == letter
                                        
                                    }).last ? 1 : 1 )
                                }
                            }
                        }.frame(height:44).hideRowSeparator()
                    }
                }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).drawingGroup()
                HStack {
                    Spacer()
                    Text("\(contacts_observer.contacts.count) Contacts").font(.custom("Helvetica Neue Regular", fixedSize: 20)).foregroundColor(.cgLightGray).lineLimit(1)
                    Spacer()
                }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            
            
        }
        if editing_state == "Active_Empty" {
            Color.black.opacity(0.9).edgesIgnoringSafeArea(.all).offset(y: 44)
        }
        if editing_state == "Active" {
            Color.white.edgesIgnoringSafeArea(.all).offset(y: 44)
            List {
                if contacts_observer.contacts.filter {(contact: CNContact) in contact.name.localizedCaseInsensitiveContains(search)}.count != 0 {
                    ForEach(contacts_observer.contacts.filter {(contact: CNContact) in contact.name.localizedCaseInsensitiveContains(search) }, id: \.self.name) { (contact: CNContact) in
                            Button(action:{
                                current_contact = contact
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    forward_or_backward = false; withAnimation(.linear(duration: 0.28)){contacts_current_nav_view = "Contacts_Desination"}
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Spacer()
                                    HStack() {
                                        Group{Text(contact.givenName ?? "").font(contact.familyName == "" ? .custom("Helvetica Neue Bold", fixedSize: 18) : .custom("Helvetica Neue SemiBold", fixedSize: 18)) + Text(" ").font(.custom("Helvetica Neue SemiBold", fixedSize: 18)) + Text(contact.familyName ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 18))}.padding(.leading, 11).padding(.trailing, 40)
                                        Spacer()
                                        Image("UITableNext").padding(.trailing, 12)
                                    }
                                    Spacer()
                                    Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                }
                            }
                        }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 44).drawingGroup()
                }
            }.offset(y: 44)
        }
    }
}


struct SkeuomorphicList_Contacts_Add_To_Favorites: View {
    @Binding var editing_state: String
    var indexes: [String]
    var contacts_observer: ContactStore
    var favorites_obs: favorites_observer
    @Binding var show_add_favorite: Bool
    @State var search = ""
    var body: some View {
        ZStack(alignment: .top) {
            List {
                ipod_search(search: $search, no_right_padding: editing_state != "None" ? true : false, editing_state:$editing_state).id("Search").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height:44).hideRowSeparator()
                ForEach(indexes, id: \.self) { letter in
                    Section(header: alpha_list_header(letter: letter).id(letter) .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                        ForEach(contacts_observer.contacts.filter({(contact: CNContact) -> Bool in
                            String(alphabet.contains(String((contact.familyName.prefix(1) ?? "") != "" ? (contact.familyName.prefix(1) ?? "") : contact.name.prefix(1) ?? "")) ? ((contact.familyName.prefix(1) ?? "") != "" ? (contact.familyName.prefix(1) ?? "") : contact.name.prefix(1) ?? "") : "#") == letter
                            
                        }), id: \.self.name) { (contact: CNContact) in
                            Button(action:{
                                if !contact.phoneNumbers.isEmpty {
                                withAnimation(.linear(duration:0.35)) {
                                    favorites_obs.favorites.append(favorite_datatype(name: contact.name, number: contact.phoneNumbers[0].value.stringValue, type: CNLabeledValue<NSString>.localizedString(forLabel: contact.phoneNumbers[0].label ?? "other") ?? "other"))
                                    show_add_favorite.toggle()
                                }
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Spacer()
                                    HStack() {
                                        Group{Text(contact.givenName ?? "").font(contact.familyName == "" ? .custom("Helvetica Neue Bold", fixedSize: 18) : .custom("Helvetica Neue SemiBold", fixedSize: 18)) + Text(" ").font(.custom("Helvetica Neue SemiBold", fixedSize: 18)) + Text(contact.familyName ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 18))}.padding(.leading, 11).padding(.trailing, 40)
                                        Spacer()
                                    }
                                    Spacer()
                                    Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all).opacity(contact == contacts_observer.contacts.filter({(contact: CNContact) -> Bool in
                                        String(alphabet.contains(String((contact.familyName.prefix(1) ?? "") != "" ? (contact.familyName.prefix(1) ?? "") : contact.name.prefix(1) ?? "")) ? ((contact.familyName.prefix(1) ?? "") != "" ? (contact.familyName.prefix(1) ?? "") : contact.name.prefix(1) ?? "") : "#") == letter
                                        
                                    }).last ? 1 : 1 )
                                }
                            }
                        }.frame(height:44).hideRowSeparator()
                    }
                }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).drawingGroup()
                HStack {
                    Spacer()
                    Text("\(contacts_observer.contacts.count) Contacts").font(.custom("Helvetica Neue Regular", fixedSize: 20)).foregroundColor(.cgLightGray).lineLimit(1)
                    Spacer()
                }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            
            
        }
        if editing_state == "Active_Empty" {
            Color.black.opacity(0.9).edgesIgnoringSafeArea(.all).offset(y: 44)
        }
        if editing_state == "Active" {
            Color.white.edgesIgnoringSafeArea(.all).offset(y: 44)
            List {
                if contacts_observer.contacts.filter {(contact: CNContact) in contact.name.localizedCaseInsensitiveContains(search)}.count != 0 {
                    ForEach(contacts_observer.contacts.filter {(contact: CNContact) in contact.name.localizedCaseInsensitiveContains(search) }, id: \.self.name) { (contact: CNContact) in
                            Button(action:{
                                if !contact.phoneNumbers.isEmpty {
                                withAnimation(.linear(duration:0.35)) {
                                    favorites_obs.favorites.append(favorite_datatype(name: contact.name, number: contact.phoneNumbers[0].value.stringValue, type: CNLabeledValue<NSString>.localizedString(forLabel: contact.phoneNumbers[0].label ?? "other") ?? "other"))
                                    show_add_favorite.toggle()
                                }
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Spacer()
                                    HStack() {
                                        Group{Text(contact.givenName ?? "").font(contact.familyName == "" ? .custom("Helvetica Neue Bold", fixedSize: 18) : .custom("Helvetica Neue SemiBold", fixedSize: 18)) + Text(" ").font(.custom("Helvetica Neue SemiBold", fixedSize: 18)) + Text(contact.familyName ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 18))}.padding(.leading, 11).padding(.trailing, 40)
                                        Spacer()
                                        Image("UITableNext").padding(.trailing, 12)
                                    }
                                    Spacer()
                                    Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                }
                            }
                        }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 44).drawingGroup()
                }
            }.offset(y: 44)
        }
    }
}


class ContactStore: ObservableObject {
    @Published var contacts: [CNContact] = []
    @Published var error: Error? = nil

    init() {
        fetch()
    }
    func fetch() {
        do {
            let store = CNContactStore()
            let keysToFetch = [CNContactGivenNameKey as CNKeyDescriptor,
                               CNContactMiddleNameKey as CNKeyDescriptor,
                               CNContactFamilyNameKey as CNKeyDescriptor,
                               CNContactImageDataAvailableKey as CNKeyDescriptor,
                               CNContactImageDataKey as CNKeyDescriptor,
                               CNContactPhoneNumbersKey as CNKeyDescriptor,
                               CNContactEmailAddressesKey as CNKeyDescriptor]
            
            var allContainers: [CNContainer] = []
               do {
                allContainers = try store.containers(matching: nil)
               } catch {
                   print("Error fetching containers")
               }

               var results: [CNContact] = []
               for container in allContainers {
                let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)

                   do {
                    let containerResults = try store.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch)
                    results.append(contentsOf: containerResults)
                   } catch {
                       print("Error fetching results for container")
                   }
               }
            
            self.contacts = results
        } catch {
            self.error = error
        }
    }
}

extension CNContact: Identifiable {
    var name: String {
        return [givenName, middleName, familyName].filter{ $0.count > 0}.joined(separator: " ")
    }
}


struct blank:View {
    var body: some View {
        Text("Blank")
    }
}
import Combine
struct BluePrimitiveButtonStyle: PrimitiveButtonStyle {
    @Binding var is_pressed: Bool
    @Binding var currently_pressed_button: String
    var current_button: String
    public var delete_action: (() -> Void)?
    func makeBody(configuration: PrimitiveButtonStyle.Configuration) -> some View {
        BlueButton(is_pressed: $is_pressed, currently_pressed_button: $currently_pressed_button, current_button: current_button, delete_action: delete_action, configuration: configuration)
    }
    
    struct BlueButton: View {
        @State var audioPlayer: AVAudioPlayer!
        @GestureState private var pressed = false
        @Binding var is_pressed: Bool
        @Binding var currently_pressed_button: String
        var current_button: String
        public var delete_action: (() -> Void)?
        let configuration: PrimitiveButtonStyle.Configuration
        @State private var timerSubscription: Cancellable?
              @State private var timer = Timer.publish(every: 1, on: .main, in: .common)
        var body: some View {
            
            return configuration.label
                .background(Color.clear)
                .compositingGroup()
                .onLongPressGesture(minimumDuration: .infinity, maximumDistance: current_button == "phone" ? 100 : .infinity, pressing: { pressing in
                        self.is_pressed = pressing
                        self.currently_pressed_button = self.current_button
                    if pressing {
                        print("My long pressed starts", is_pressed)
                        self.configuration.trigger()
                        playSounds("dtmf-\(current_button).caf")
                        if current_button == "delete" {
                            self.timer = Timer.publish(every: 1, on: .main, in: .common)
                        self.timerSubscription = self.timer.connect()
                        }
                    } else {
                        print("My long pressed ends", is_pressed)
                        if current_button == "delete" {
                            self.timer = Timer.publish(every: 1, on: .main, in: .common)
                            timerSubscription?.cancel()
                            timerSubscription = nil
                        }
                    }
                }, perform: { }) .onReceive(timer) { _ in
                    if self.timer.interval != 0.05 {
                    self.timer = Timer.publish(every: 0.05, on: .main, in: .common)
                        self.timerSubscription = self.timer.connect()
                    }
                    delete_action?()
                }
            
        }
        func playSounds(_ soundFileName : String) {
            guard let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: nil) else {
                return
            }
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            } catch {
                print(error.localizedDescription)
            }
            audioPlayer.play()
        }
    }
}

func callNumber(_ phoneNumber:String) {

  if let phoneCallURL = URL(string: "tel://\(phoneNumber)") {

    let application:UIApplication = UIApplication.shared
    if (application.canOpenURL(phoneCallURL)) {
        application.open(phoneCallURL, options: [:], completionHandler: nil)
    }
  }
}

struct phone_keypad_view: View {
    var sub_letters = [1:"  ", 2:"ABC", 3:"DEF", 4:"GHI", 5:"JKL", 6:"MNO", 7:"PQR", 8:"TUV", 9:"WXYZ"]
    @State var phone_number: String = ""
    @State var formated_phone: String = ""
    @State var is_pressed: Bool = false
    @State var currently_pressed_button = ""
    @State var audioPlayer: AVAudioPlayer!
    @Binding var show_add_contact: Bool
    @ObservedObject var recents_obs: recents_observer
    var body: some View {
        VStack(spacing:0) {
            ZStack {
                Rectangle().fill(LinearGradient([(color: Color(red: 104/255, green: 123/255, blue: 149/255), location:0), (color: Color(red: 38/255, green: 66/255, blue: 104/255), location:0.53), (color: Color(red: 11/255, green: 42/255, blue: 85/255), location:0.53), (color: Color(red: 11/255, green: 42/255, blue: 85/255), location:0.99), (color: Color(red: 5/255, green: 17/255, blue: 35/255), location:1)], from: .top, to: .bottom)).frame(height:110)
                Text(formated_phone).font(.custom("Helvetica Neue Regular", fixedSize: 40)).foregroundColor(.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0.0, y: -1).lineLimit(0).minimumScaleFactor(0.5).padding([.leading, .trailing], 5).truncationMode(.head)
            }
            GeometryReader{ geometry in
                VStack(spacing:0) {
                    ForEach(1..<4) {x in
                        HStack(spacing:0) {
                            ForEach(0..<3) {i in
                                Button(action:{
                                    phone_number.append("\(Int(x*(x != 3 ? x : 2)+i+(x == 3 ? 1  : 0)))")
                                    var formatter = PhoneFormatter(rulesets: PNFormatRuleset.usParethesis())
                                    if phone_number.prefix(1) == "1"{
                                        formatter = PhoneFormatter(rulesets: PNFormatRuleset.start_with_one())
                                    }
                                    formated_phone = formatter.format(number: phone_number)
                                }) {
                                    ZStack {
                                        numberpad_rectangle_blue_gray(geometry: geometry, i: i, highlight: $is_pressed, currently_pressed_button: $currently_pressed_button, current_button: "\(Int(x*(x != 3 ? x : 2)+i+(x == 3 ? 1  : 0)))")
                                        VStack {
                                            Text("\(Int(x*(x != 3 ? x : 2)+i+(x == 3 ? 1  : 0)))").font(.custom("Helvetica Neue Bold", fixedSize: 34)).foregroundColor(.white).shadow(color: Color.black.opacity(0.3), radius: 2, x: 0.0, y: 4) //This is the most asinine way to approach this, but its a sequence, so there ya go.
                                            Text(sub_letters[Int(x*(x != 3 ? x : 2)+i+(x == 3 ? 1  : 0))] ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 15)).foregroundColor(Color(red: 137/255, green:140/255, blue:145/255)).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0.0, y: -1)
                                        }
                                    }
                                }.buttonStyle(BluePrimitiveButtonStyle(is_pressed: $is_pressed, currently_pressed_button: $currently_pressed_button, current_button: "\(Int(x*(x != 3 ? x : 2)+i+(x == 3 ? 1  : 0)))"))
                            }
                        }
                    }
                    
                    HStack(spacing:0) {
                        Button(action:{
                            phone_number.append("*")
                            var formatter = PhoneFormatter(rulesets: PNFormatRuleset.usParethesis())
                            if phone_number.prefix(1) == "1"{
                                formatter = PhoneFormatter(rulesets: PNFormatRuleset.start_with_one())
                            }
                            formated_phone = formatter.format(number: phone_number)
                        }) {
                            ZStack {
                                numberpad_rectangle_blue_gray(geometry: geometry, i: 0, highlight: $is_pressed, currently_pressed_button: $currently_pressed_button, current_button: "star")
                                VStack {
                                    Image("star_phone").resizable().scaledToFit().frame(width:26, height: 26).padding(.top, 7.5).shadow(color: Color.black.opacity(0.3), radius: 2, x: 0.0, y: 4)
                                    Text("  ").font(.custom("Helvetica Neue Bold", fixedSize: 15)).foregroundColor(Color(red: 137/255, green:140/255, blue:145/255)).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0.0, y: -1)
                                }
                            }
                        }.buttonStyle(BluePrimitiveButtonStyle(is_pressed: $is_pressed, currently_pressed_button: $currently_pressed_button, current_button: "star"))
                        Button(action:{
                            phone_number.append("0")
                            var formatter = PhoneFormatter(rulesets: PNFormatRuleset.usParethesis())
                            if phone_number.prefix(1) == "1"{
                                formatter = PhoneFormatter(rulesets: PNFormatRuleset.start_with_one())
                            }
                            formated_phone = formatter.format(number: phone_number)
                        }) {
                            ZStack {
                                numberpad_rectangle_blue_gray(geometry: geometry, i: 1, highlight: $is_pressed, currently_pressed_button: $currently_pressed_button, current_button: "0")
                                VStack {
                                    Text("0").font(.custom("Helvetica Neue Bold", fixedSize: 34)).foregroundColor(.white).shadow(color: Color.black.opacity(0.3), radius: 2, x: 0.0, y: 4)
                                    Text("+").font(.custom("Helvetica Neue Bold", fixedSize: 15)).foregroundColor(Color(red: 137/255, green:140/255, blue:145/255)).scaleEffect(1.6).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0.0, y: -1)
                                }
                            }
                        }.buttonStyle(BluePrimitiveButtonStyle(is_pressed: $is_pressed, currently_pressed_button: $currently_pressed_button, current_button: "0"))
                        Button(action:{
                            phone_number.append("#")
                            var formatter = PhoneFormatter(rulesets: PNFormatRuleset.usParethesis())
                            if phone_number.prefix(1) == "1"{
                                formatter = PhoneFormatter(rulesets: PNFormatRuleset.start_with_one())
                            }
                            formated_phone = formatter.format(number: phone_number)
                        }) {
                            ZStack {
                                numberpad_rectangle_blue_gray(geometry: geometry, i: 2, highlight: $is_pressed, currently_pressed_button: $currently_pressed_button, current_button: "pound")
                                VStack {
                                    Image("pound_phone").resizable().scaledToFit().frame(width:26, height: 26).padding(.top, 7.5).shadow(color: Color.black.opacity(0.3), radius: 2, x: 0.0, y: 4)
                                    Text("a").font(.custom("Helvetica Neue Bold", fixedSize: 15)).foregroundColor(Color(red: 137/255, green:140/255, blue:145/255)).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0.0, y: -1).opacity(0)
                                }
                            }
                        }.buttonStyle(BluePrimitiveButtonStyle(is_pressed: $is_pressed, currently_pressed_button: $currently_pressed_button, current_button: "pound"))
                    }
                    HStack(spacing:0) {
                        Button(action:{
                            withAnimation(.linear(duration:0.35)) {
                                show_add_contact.toggle()
                            }
                        }) {
                            ZStack {
                                numberpad_rectangle_blue(geometry: geometry, right: true, highlight: $is_pressed, currently_pressed_button: $currently_pressed_button, current_button: "add")
                                Image("add_contact").resizable().scaledToFit().frame(height: 24).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0.0, y: -1)
                            }
                        }.buttonStyle(BluePrimitiveButtonStyle(is_pressed: $is_pressed, currently_pressed_button: $currently_pressed_button, current_button: "add"))
                        Button(action:{
                            if phone_number != "" {
                            callNumber(phone_number)
                                recents_obs.recents.append(recents_datatype(date: Date(), number: formated_phone, type: "unknown"))
                            }
                        }) {
                            ZStack {
                                numberpad_rectangle_green(geometry: geometry, highlight: $is_pressed, currently_pressed_button: $currently_pressed_button, current_button: "call")
                                HStack {
                                    Image("callglyph_big")
                                    Text("Call").font(.custom("Helvetica Neue Bold", fixedSize: 26)).foregroundColor(.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0.0, y: -1)
                                }
                            }
                        }.buttonStyle(BluePrimitiveButtonStyle(is_pressed: $is_pressed, currently_pressed_button: $currently_pressed_button, current_button: "call"))
                        Button(action:{
                            phone_number = String(phone_number.dropLast())
                            var formatter = PhoneFormatter(rulesets: PNFormatRuleset.usParethesis())
                            if phone_number.prefix(1) == "1"{
                                formatter = PhoneFormatter(rulesets: PNFormatRuleset.start_with_one())
                            }
                            formated_phone = formatter.format(number: phone_number)
                        }) {
                            ZStack {
                                numberpad_rectangle_blue(geometry: geometry, right: false, highlight: $is_pressed, currently_pressed_button: $currently_pressed_button, current_button: "delete")
                                Image("backspace").resizable().scaledToFit().frame(height: 24).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0.0, y: -1)
                            }
                        }.buttonStyle(BluePrimitiveButtonStyle(is_pressed: $is_pressed, currently_pressed_button: $currently_pressed_button, current_button: "delete", delete_action:{                        phone_number = String(phone_number.dropLast())
                                                                var formatter = PhoneFormatter(rulesets: PNFormatRuleset.usParethesis())
                                                                if phone_number.prefix(1) == "1"{
                                                                    formatter = PhoneFormatter(rulesets: PNFormatRuleset.start_with_one())
                                                                }
                                                                formated_phone = formatter.format(number: phone_number)}))
                    }
                }
            }
        }
    }
}


struct numberpad_rectangle_blue_gray: View {
    var geometry: GeometryProxy
    var i: Int?
    @Binding var highlight: Bool
    @Binding var currently_pressed_button: String
    var current_button: String
    var body: some View {
        Rectangle().fill(highlight == false ? LinearGradient([Color(red: 30/255, green: 37/255, blue: 47/255), Color(red: 14/255, green: 21/255, blue: 32/255)], from: .top, to: .bottom) : current_button == currently_pressed_button ? LinearGradient([Color(red: 77/255, green: 151/255, blue: 245/255), Color(red: 33/255, green: 106/255, blue: 228/255)], from: .top, to: .bottom) : LinearGradient([Color(red: 30/255, green: 37/255, blue: 47/255), Color(red: 14/255, green: 21/255, blue: 32/255)], from: .top, to: .bottom)).border_top(width: 1, edges: [.top], color: Color(red: 59/255, green: 69/255, blue: 74/255)).border_top(width: 1, edges: [.bottom], color: Color(red: 11/255, green: 17/255, blue: 26/255)).border_top(width: 1, edges: [.leading], color: i == 0 ? Color(red: 58/255, green: 58/255, blue: 58/255) : Color(red: 64/255, green: 70/255, blue: 78/255)).border_top(width: 1, edges: [.trailing], color: i == 2 ? Color(red: 64/255, green: 70/255, blue: 78/255) : Color(red: 14/255, green: 20/255, blue: 27/255)).frame(width:geometry.size.width/3, height: geometry.size.height/5).brightness(highlight == false  ? 0 : current_button == currently_pressed_button ? -0.1 : 0).animationsDisabled()
    }
}

struct numberpad_rectangle_blue: View {
    var geometry: GeometryProxy
    var right: Bool
    @Binding var highlight: Bool
    @Binding var currently_pressed_button: String
    var current_button: String
    var body: some View {
        if right {
            Rectangle().fill(highlight == false ? LinearGradient([(color: Color(red: 32/255, green: 48/255, blue: 70/255), location:0), (color: Color(red: 11/255, green: 29/255, blue: 54/255), location:0.50), (color: Color(red: 5/255, green: 24/255, blue: 49/255), location:0.50), (color: Color(red: 5/255, green: 24/255, blue: 49/255), location:1)], from: .top, to: .bottom) : current_button == currently_pressed_button ? LinearGradient([Color(red: 77/255, green: 151/255, blue: 245/255), Color(red: 33/255, green: 106/255, blue: 228/255)], from: .top, to: .bottom) : LinearGradient([(color: Color(red: 32/255, green: 48/255, blue: 70/255), location:0), (color: Color(red: 11/255, green: 29/255, blue: 54/255), location:0.50), (color: Color(red: 5/255, green: 24/255, blue: 49/255), location:0.50), (color: Color(red: 5/255, green: 24/255, blue: 49/255), location:1)], from: .top, to: .bottom)).border_top(width: 1, edges: [.top], color: Color(red: 59/255, green: 69/255, blue: 74/255)).border_top(width: 1, edges: [.bottom], color: Color(red: 11/255, green: 17/255, blue: 26/255)).border_top(width: 1, edges: [.leading], color: Color(red: 58/255, green: 58/255, blue: 58/255)).border_top(width: 1, edges: [.trailing], color: Color(red: 14/255, green: 20/255, blue: 27/255)).frame(width:geometry.size.width/3, height: geometry.size.height/5).brightness(highlight == false  ? 0 : current_button == currently_pressed_button ? -0.1 : 0).animationsDisabled()
        } else {
            Rectangle().fill(highlight == false ? LinearGradient([(color: Color(red: 32/255, green: 48/255, blue: 70/255), location:0), (color: Color(red: 11/255, green: 29/255, blue: 54/255), location:0.50), (color: Color(red: 5/255, green: 24/255, blue: 49/255), location:0.50), (color: Color(red: 5/255, green: 24/255, blue: 49/255), location:1)], from: .top, to: .bottom) : current_button == currently_pressed_button ? LinearGradient([Color(red: 77/255, green: 151/255, blue: 245/255), Color(red: 33/255, green: 106/255, blue: 228/255)], from: .top, to: .bottom) : LinearGradient([(color: Color(red: 32/255, green: 48/255, blue: 70/255), location:0), (color: Color(red: 11/255, green: 29/255, blue: 54/255), location:0.50), (color: Color(red: 5/255, green: 24/255, blue: 49/255), location:0.50), (color: Color(red: 5/255, green: 24/255, blue: 49/255), location:1)], from: .top, to: .bottom)).border_top(width: 1, edges: [.top], color: Color(red: 59/255, green: 69/255, blue: 74/255)).border_top(width: 1, edges: [.bottom], color: Color(red: 38/255, green: 51/255, blue: 71/255)).border_top(width: right == true ? 1 : 0, edges: [.leading], color: Color(red: 64/255, green: 70/255, blue: 78/255)).border_top(width: right == false ? 1 : 0, edges: [.trailing], color: Color(red: 64/255, green: 70/255, blue: 78/255)).frame(width:geometry.size.width/3, height: geometry.size.height/5).brightness(highlight == false  ? 0 : current_button == currently_pressed_button ? -0.1 : 0).animationsDisabled()
        }
    }
}

struct numberpad_rectangle_green: View {
    var geometry: GeometryProxy
    @Binding var highlight: Bool
    @Binding var currently_pressed_button: String
    var current_button: String
    var body: some View {
        Rectangle().fill(LinearGradient([(color: Color(red: 154/255, green: 206/255, blue: 150/255), location:0), (color: Color(red: 64/255, green: 178/255, blue: 59/255), location:0.50), (color: Color(red: 33/255, green: 161/255, blue: 26/255), location:0.50), (color: Color(red: 39/255, green: 170/255, blue: 30/255), location:1)], from: .top, to: .bottom)).border_top(width: 1, edges: [.top], color: Color(red: 171/255, green: 228/255, blue: 160/255)).border_top(width: 0.5, edges: [.top], color: Color(red: 226/255, green: 246/255, blue: 223/255)).border_top(width: 1, edges: [.bottom], color: Color(red: 131/255, green: 203/255, blue: 96/255)).border_top(width: 1, edges: [.leading], color: Color(red: 145/255, green: 222/255, blue: 112/255)).frame(width:geometry.size.width/3, height: geometry.size.height/5).brightness(highlight == false  ? 0 : current_button == currently_pressed_button ? 0.1 : 0).animationsDisabled()
    }
}

struct phone_title_bar : View {
    var title:String
    @Binding var forward_or_backward: Bool
    @Binding var selectedTab:String
    @Binding var contacts_current_nav_view: String
    @Binding var is_editing_favorites: Bool
    @Binding var selected_segment: Int
    @Binding var instant_multitasking_change: Bool
    @ObservedObject var favorites_obs: favorites_observer
    @ObservedObject var recents_obs: recents_observer
    var show_edit: Bool
    var show_plus: Bool
    public var edit_action: (() -> Void)?
    public var plus_action: (() -> Void)?
    var body :some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.49), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.49), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if selectedTab != "Recents" {
                    Text(title).ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", fixedSize: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)).combined(with: .opacity)).id(title)
                    } else {
                        dual_segmented_control(selected: $selected_segment, instant_multitasking_change: $instant_multitasking_change, first_text: "All", second_text: "Missed").frame(width: 180, height: 30)
                    }
                    Spacer()
                }
                Spacer()
            }
            if selectedTab == "Contacts", contacts_current_nav_view != "Contacts" {
                VStack {
                    Spacer()
                    HStack {
                        Button(action:{
                            forward_or_backward = true; withAnimation(.linear(duration: 0.28)){contacts_current_nav_view = "Contacts"}
                        }){
                            ZStack {
                                Image("Button_wp5").resizable().scaledToFit().frame(width:200*84/162*(33/34.33783783783784), height: 33)
                                HStack(alignment: .center) {
                                    Text("All Contacts").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1).offset(x: 1).frame(maxWidth: 90).lineLimit(0)
                                }
                            }.padding(.leading, 5.5)
                        }.transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)).combined(with: AnyTransition.opacity))
                        Spacer()
                    }
                    Spacer()
                }.offset(y:-0.5)
                VStack {
                    Spacer()
                    HStack {
                    Spacer()
                        tool_bar_rectangle_button(button_type: .blue_gray, content: " Edit ").padding(.trailing, 8)
                    }
                    Spacer()
                }.offset(y:-0.75).transition(.opacity)

            }
            if show_edit == true, favorites_obs.favorites.count != 0 {
            HStack {
                tool_bar_rectangle_button(action: {edit_action?()}, button_type: is_editing_favorites == false ? .blue_gray : .blue, content: is_editing_favorites == false ? " Edit " : "Done").padding(.leading, 5)
                Spacer()
            }
            }
            if show_plus == true {
            HStack {
                Spacer()
                tool_bar_rectangle_button(action: {plus_action?()}, button_type: .blue_gray, content: "UIButtonBarPlus", use_image: true).padding(.trailing, 5)
            }
            }
            if selectedTab == "Recents", recents_obs.recents.count != 0  {
                HStack {
                    Spacer()
                    tool_bar_rectangle_button(action: {edit_action?()}, button_type: .blue_gray, content: "Clear").padding(.trailing, 5)
                }
            }
        }
    }
}


struct TabButton_Phone : View {
    
    var image : String
    @Binding var selectedTab : String
    var geometry: GeometryProxy
    var body: some View{
        Button(action: {
            selectedTab = image
        }) {
            ZStack {
                if selectedTab == image {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.1)).frame(width: geometry.size.width/5 - 5, height: 51).blendMode(.screen)
                    VStack(spacing: 2) {
                        ZStack {
                            Image("\(image)_Phone").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Keypad" ? 25 : image == "Voicemail" ? 37.5 : 30.5, height: 30.5).overlay(
                                LinearGradient(gradient: Gradient(colors: [Color(red: 205/255, green: 233/255, blue: 249/255), Color(red: 75/255, green: 220/255, blue: 251/255)]), startPoint: .top, endPoint: .bottom)
                            ).mask(Image("\(image)_Phone").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Keypad" ? 25 : image == "Voicemail" ? 37.5 : 30.5, height: 30.5)).offset(y:-0.5)
                            
                            Image("\(image)_Phone").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Keypad" ? 25 : image == "Voicemail" ? 37.5 : 30, height: 30).overlay(
                                ZStack {
                                    LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 197/255, green: 210/255, blue: 229/255), location: 0), .init(color: Color(red: 99/255, green: 162/255, blue: 216/255), location: 0.47), .init(color: Color(red: 0/255, green: 145/255, blue: 230/255), location: 0.49), .init(color: Color(red: 21/255, green: 197/255, blue: 252/255), location: 1)]), startPoint: .top, endPoint: .bottom).rotationEffect(Angle(degrees: image == "More" ? 0 : -15)).frame(width: image == "More" ? 40 : 40, height: image == "Keypad" ? 38 : image == "Contacts" ? 34 : 30).brightness(0.095).offset(y: image == "Artists" ? 2 : 0)
                                }
                            ).mask(Image("\(image)_Phone").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Keypad" ? 25 : image == "Voicemail" ? 37.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.6), radius:2.5, x: 0, y:2.5)
                        }
                        HStack {
                            Spacer()
                            Text(image).foregroundColor(.white).font(.custom("Helvetica Neue Bold", fixedSize: 11))
                            Spacer()
                        }
                    }
                } else {
                    VStack(spacing: 2) {
                        Image("\(image)_Phone").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Keypad" ? 25 : image == "Voicemail" ? 37.5 : 30, height: 30).overlay(
                            LinearGradient(gradient: Gradient(colors: [Color(red: 157/255, green: 157/255, blue: 157/255), Color(red: 89/255, green: 89/255, blue: 89/255)]), startPoint: .top, endPoint: .bottom)
                        ).mask(Image("\(image)_Phone").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Keypad" ? 25 : image == "Voicemail" ? 37.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.75), radius: 0, x: 0, y: -1)
                        HStack {
                            Spacer()
                            Text(image).foregroundColor(Color(red: 168/255, green: 168/255, blue: 168/255)).font(.custom("Helvetica Neue Bold", fixedSize: 11))
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}
