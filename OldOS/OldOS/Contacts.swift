//
//  Contacts.swift
//  OldOS
//
//  Created by Zane Kleinberg on 5/24/21.
//

import SwiftUI
import AVFoundation
import Contacts
import CoreTelephony

struct Contacts: View {
    @State var selectedTab = "Contacts"
    @State var current_nav_view: String = "Main"
    @State var forward_or_backward = false
    @State var contacts_current_nav_view: String = "Contacts"
    @State var current_contact: CNContact = CNContact()
    @State var show_add_contact: Bool = false
    @State var show_edit: Bool = false
    @State var show_add_favorite: Bool = false
    @State var show_recents_clear: Bool = false
    @State var selected_segment: Int = 0
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0), .init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0.5), .init(color: Color.white, location: 0.5), .init(color: Color.white, location: 1)]), startPoint: .top, endPoint: .bottom)
                VStack(spacing:0) {
                    status_bar_in_app().frame(minHeight: 24, maxHeight:24).zIndex(1)
                    contacts_title_bar(title: contacts_current_nav_view != "Contacts" ? "Info" : "All Contacts", forward_or_backward: $forward_or_backward, selectedTab: $selectedTab, contacts_current_nav_view: $contacts_current_nav_view, is_editing_favorites: $show_edit, selected_segment: $selected_segment, show_plus: contacts_current_nav_view == "Contacts" ? true : false, plus_action: {
                        withAnimation(.linear(duration:0.35)){show_add_contact.toggle()}
                    }).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 60, maxHeight:60).zIndex(1)
                    contacts_view_app(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, contacts_current_nav_view: $contacts_current_nav_view, current_contact: $current_contact).clipped()
                }
                if show_add_contact {
                    add_contact_view(show_add_contact: $show_add_contact).transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom))).zIndex(1).clipped().compositingGroup()
                }
            }.compositingGroup().clipped()//.background(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0), .init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0.5), .init(color: Color.white, location: 0.5), .init(color: Color.white, location: 1)]), startPoint: .top, endPoint: .bottom)).clipped()
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

struct contacts_title_bar : View {
    var title:String
    @Binding var forward_or_backward: Bool
    @Binding var selectedTab:String
    @Binding var contacts_current_nav_view: String
    @Binding var is_editing_favorites: Bool
    @Binding var selected_segment: Int
    var show_edit: Bool?
    var show_plus: Bool?
    public var edit_action: (() -> Void)?
    public var plus_action: (() -> Void)?
    var body :some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.49), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.49), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
            VStack {
                Spacer()
                HStack {
                    Spacer()
    
                    Text(title).ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", size: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)).combined(with: .opacity)).id(title)

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
                                    Text("All Contacts").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", size: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1).offset(x: 1).frame(maxWidth: 90).lineLimit(0)
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
            if show_plus == true {
            HStack {
                Spacer()
                tool_bar_rectangle_button(action: {plus_action?()}, button_type: .blue_gray, content: "UIButtonBarPlus", use_image: true).padding(.trailing, 5)
            }
            }

        }
    }
}

struct Contacts_Previews: PreviewProvider {
    static var previews: some View {
        Contacts()
    }
}

struct contacts_view_app: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var contacts_current_nav_view: String
    @State var editing_state: String = "None"
    @Binding var current_contact: CNContact
    @ObservedObject var contacts_observer = ContactStore()
    @ObservedObject var recents_obs = recents_observer()
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
