//
//  GameCenter.swift
//  OldOS
//
//  Created by Zane Kleinberg on 3/8/21.
//

import Foundation
import SwiftUI
import GameKit

struct GameCenter: View {
    @State var current_nav_view: String = "Main"
    @State var forward_or_backward: Bool = false
    @State var selectedTab = "Me"
    @State var show_friend: Bool = false
    @State var current_friend = GKPlayer()
    @ObservedObject var gc_observer = game_center_observer()
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing:0) {
                    status_bar().background(Color.black).frame(minHeight: 24, maxHeight:24).zIndex(1)
                    game_center_title_bar(title: selectedTab == "Friends" ? show_friend == false ? "\(gc_observer.friends.count) \(gc_observer.friends.count != 1 ? "Friends" : "Friend")" : current_friend.alias : selectedTab == "Games" ? "1 Game" : selectedTab == "Requests" ? "Friend Requests" : selectedTab, back_action: {
                        forward_or_backward = true; DispatchQueue.main.asyncAfter(deadline:.now()+0.3){ withAnimation(.linear(duration: 0.28)) {show_friend = false}}
                    }, show_back: show_friend,selectedTab: $selectedTab).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 60, maxHeight:60).zIndex(1)
                    GameCenterTabView(selectedTab: $selectedTab, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, show_friend: $show_friend, current_friend: $current_friend, gc_observer: gc_observer).clipped()
                }
            }.compositingGroup().clipped()
        }.onAppear() {
            UIScrollView.appearance().bounces = true
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
        }
    }
}

var gamecenter_tabs = ["Me", "Friends", "Games", "Requests"]
struct GameCenterTabView : View {
    
    @Binding var selectedTab:String
    @State var edge = UIApplication.shared.windows.first?.safeAreaInsets
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var show_friend: Bool
    @Binding var current_friend: GKPlayer
    @ObservedObject var gc_observer: game_center_observer
    var body: some View{
        GeometryReader {geometry in
            VStack(spacing:0) {
                
                ScrollView([], showsIndicators: false) {
                    switch selectedTab {
                    case "Me":
                        game_center_me_view(gc_observer: gc_observer).frame(height: geometry.size.height - 57)
                            .tag("Me")
                    case "Friends":
                        game_center_friends_view(current_friend: $current_friend, gc_observer: gc_observer, show_friend: $show_friend, forward_or_backward: $forward_or_backward).frame(height: geometry.size.height - 57)
                            .tag("Friends")
                    case "Games":
                        game_center_games_view().frame(height: geometry.size.height - 57)
                            .tag("Games")
                    case "Requests":
                        game_center_requests_view().frame(height: geometry.size.height - 57)
                            .tag("Requests")
                    default:
                        game_center_me_view(gc_observer: gc_observer).frame(height: geometry.size.height - 57)
                            .tag("Me")
                    }
                }.background(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0), .init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0.5), .init(color: Color.white, location: 0.5), .init(color: Color.white, location: 1)]), startPoint: .top, endPoint: .bottom))
                // for bottom overflow...
                ZStack {
                    Image("GKTabbarPortrait").resizable().scaledToFill().frame(width: geometry.size.width, height:57).clipped()
                    HStack(spacing: 0){
                        
                        ForEach(gamecenter_tabs,id: \.self){image in
                            TabButtonGameCenter(image: image, selectedTab: $selectedTab, geometry: geometry)
                            
                            // equal spacing...
                            
                            if image != tabs.last{
                                
                                Spacer(minLength: 0)
                            }
                        }
                    }.frame(height:55)
                }.padding(.bottom, 0)
            }
        }
    }
    
}

//**Mark: Me Views

struct game_center_me_view: View {
    @State var topOffset: CGFloat = 0
    @State var background_size: CGFloat = 0
    @ObservedObject var gameKitHelper = GameKitHelper.sharedInstance
    @ObservedObject var gc_observer: game_center_observer
    struct TopOffsetKey: PreferenceKey {
        typealias Value = CGFloat
        
        static var defaultValue: Value = 0
        
        static func reduce(
            value: inout Value,
            nextValue: () -> Value
        ) {
            value = nextValue()
        }
    }
    let GKAuthPublisher = NotificationCenter.default.publisher(for:.GKPlayerAuthenticationDidChangeNotificationName).makeConnectable().autoconnect()
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ZStack {
                    Image("GKBackgroundPortrait").overlay(
                        GeometryReader { proxy in
                            Color.clear.hidden().onAppear() {
                                print(proxy.size.width)
                                background_size = proxy.size.width
                            }
                        }
                    ).opacity(0)
                    VStack(spacing:0) {
                        Spacer().frame(height: 30)
                        Text("\(gc_observer.local_player.alias) is...").font(.custom("Superclarendon Bold", size: 15)).foregroundColor(Color(red: 35/255, green: 66/255, blue: 45/255)).lineLimit(0).shadow(color: Color(red: 105/255, green: 194/255, blue: 132/255).opacity(0.85), radius: 0, y: 1)
                        ZStack {
                            Image("GKAliasShadowTexture").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).frame(width:geometry.size.width, height: 74).mask(
                                Text("\(gc_observer.local_player.alias)").font(.custom("Phosphate-Inline", size: 74)).lineLimit(0).offset(x: 3.5, y: 3.5)
                            ).shadow(color: Color(red: 86/255, green: 164/255, blue: 108/255).opacity(0.5), radius: 0, y: 1)
                            Image("GKAliasTexture").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).frame(width:geometry.size.width, height: 74).mask(
                                Text("\(gc_observer.local_player.alias)").font(.custom("Phosphate-Inline", size: 74))).lineLimit(0)
                        }
                        Spacer().frame(height: 30)
                        HStack {
                            VStack(spacing: 1) {
                                ribbon_view(ribbon: "GKRibbonRed", text: "\(gc_observer.friends.count)")
                                Text("FRIENDS").font(.custom("Helvetica Neue Bold", size: 11.5)).foregroundColor(.white).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                            }.frame(width:geometry.size.width/3-20)
                            VStack(spacing: 1) {
                                ribbon_view(ribbon: "GKRibbonYellow", text: "1")
                                Text("GAME").font(.custom("Helvetica Neue Bold", size: 11.5)).foregroundColor(.white).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                            }.frame(width:geometry.size.width/3-20)
                            VStack(spacing: 1) {
                                ribbon_view(ribbon: "GKRibbonBlue", text: "\(gc_observer.achievements.count)")
                                Text("ACHIEVEMENTS").font(.custom("Helvetica Neue Bold", size: 11.5)).foregroundColor(.white).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1).lineLimit(1)
                            }.frame(width:geometry.size.width/3-15)
                        }.clipped()
                        Spacer().frame(height: 30)
                        ZStack {
                            Image("GKCellBorderTexture").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).frame(height: 50).mask(
                                RoundedRectangle(cornerRadius: 8.5).padding([.leading, .trailing], 10)).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                            Image("GKBackgroundPortrait").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).frame(height: 46).mask(
                                RoundedRectangle(cornerRadius: 8.5*10/12 ).padding([.leading, .trailing], 12))
                            Image("GKAliasShadowTexture").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).brightness(0.07).frame(height: 40).mask(
                                RoundedRectangle(cornerRadius: 8.5*10/15)).ps_innerShadow(.roundedRectangle(8.5*10/15), radius: 1, intensity: 0.6).padding([.leading, .trailing], 15)
                            Text("Status").font(.custom("Superclarendon Bold", size: 16.5)).foregroundColor(Color(red: 29/255, green: 54/255, blue: 37/255)).shadow(color: Color(red: 86/255, green: 164/255, blue: 108/255).opacity(0.7), radius: 0, y: 0.8)
                        }
                        Spacer().frame(height:20)
                        large_ribbon_button(ribbon: "GKRibbonButton", text: "Account: \(gc_observer.local_player.alias)@mac.com").padding([.leading, .trailing], 10)
                        Spacer()
                    }.offset(y: topOffset < 0 ? -topOffset/2 : 0)
                    GeometryReader { proxy in
                        let offset = proxy.frame(in: .named("scroll")).minY
                        Color.clear.preference(key: TopOffsetKey.self, value: offset)
                    }
                }
            }.coordinateSpace(name: "scroll")
            .onPreferenceChange(TopOffsetKey.self) { value in
                print(value)
                topOffset = value
            }.background(
                VStack(spacing:0) {
                    Image("GKBackgroundPortrait").resizable(capInsets: EdgeInsets(top: 960/2-topOffset, leading: 0, bottom: 0, trailing: -(geometry.size.width-background_size)), resizingMode: .tile).frame(width:geometry.size.width, height:topOffset > 0 ? topOffset : 0).offset(y: topOffset > 0 ? topOffset : 0)
                    Image("GKBackgroundPortrait").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: -(geometry.size.width-background_size)), resizingMode: .tile).frame(width:geometry.size.width, height:geometry.size.height+abs(topOffset)).offset(y: topOffset > 0 ? topOffset : 0)
                }
            )
        }.onAppear() {
            gameKitHelper.authenticateLocalPlayer()
        }.onReceive(GKAuthPublisher) {_ in //Move to observable object
        }
    }
}

//** Mark: Friends Views

struct game_center_friends_view: View {
    @State var topOffset: CGFloat = 0
    @State var background_size: CGFloat = 0
    @Binding var current_friend: GKPlayer
    @ObservedObject var gc_observer: game_center_observer
    @Binding var show_friend: Bool
    @Binding var forward_or_backward: Bool
    struct TopOffsetKey: PreferenceKey {
        typealias Value = CGFloat
        
        static var defaultValue: Value = 0
        
        static func reduce(
            value: inout Value,
            nextValue: () -> Value
        ) {
            value = nextValue()
        }
    }
    var body: some View {
        ZStack {
            switch show_friend {
            case false:
                GeometryReader { geometry in
                    ScrollView {
                        ZStack {
                            Image("GKBackgroundPortrait").overlay(
                                GeometryReader { proxy in
                                    Color.clear.hidden().onAppear() {
                                        print(proxy.size.width)
                                        background_size = proxy.size.width
                                    }
                                }
                            ).opacity(0)
                            VStack {
                                ZStack {
                                    Image("GKBackgroundPortrait").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).mask(
                                        RoundedRectangle(cornerRadius: 10).fill(Color.white))
                                    
                                    Image("GKCellBorderTexture").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).mask(
                                        RoundedRectangle(cornerRadius: 10).fill(Color.clear).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                                        .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth:4).cornerRadius(10))).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                                    
                                    VStack(spacing:0) {
                                        ForEach(gc_observer.friends, id: \.alias) { friend in
                                            Button(action:{current_friend = friend; forward_or_backward = false; DispatchQueue.main.asyncAfter(deadline:.now()+0.3){ withAnimation(.linear(duration: 0.28)) {show_friend = true}}}) {
                                            ZStack {
                                                if friend != gc_observer.friends.last {
                                                    Image("GKCellBorderTexture").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).mask(
                                                        Rectangle().fill(Color.clear).frame(height:65).border_bottom(width: 2, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))).padding([.leading, .trailing], 2).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                                                } else {
                                                    Rectangle().fill(Color.clear).frame(height:50)
                                                }
                                                HStack {
                                                    VStack(alignment: .leading, spacing: 1) {
                                                        Text("No Status") .font(.custom("Helvetica Neue Bold", size: 12)).foregroundColor(Color(red: 29/255, green: 54/255, blue: 37/255)).shadow(color: Color(red: 105/255, green: 194/255, blue: 132/255).opacity(0.80), radius: 0, y: 1)
                                                        Text(friend.alias).font(.custom("Superclarendon Bold", size: 15)).foregroundColor(.white).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                                                        Text("Never Played") .font(.custom("Helvetica Neue Bold", size: 12)).foregroundColor(Color(red: 29/255, green: 54/255, blue: 37/255)).shadow(color: Color(red: 105/255, green: 194/255, blue: 132/255).opacity(0.80), radius: 0, y: 1)
                                                    }.padding([.leading], 18)
                                                    Spacer()
                                                    Image("GKDisclosureIndicator").padding([.trailing], 12).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                                                }
                                            }.frame(height: 65)
                                        }
                                        }
                                    }
                                }.frame(height: 65*CGFloat(gc_observer.friends.count)).padding([.leading, .trailing], 12).padding(.top, 10)
                                Spacer().frame(height:20)
                                large_ribbon_button(ribbon: "GKRibbonButton", text: "Add Friends").padding([.leading, .trailing], 10).padding(.bottom, 65*CGFloat(gc_observer.friends.count/2 ) + 160)
                                Spacer()
                            }.offset(y: topOffset < 0 ? -topOffset/2 : 0)
                            GeometryReader { proxy in
                                let offset = proxy.frame(in: .named("scroll")).minY
                                Color.clear.preference(key: TopOffsetKey.self, value: offset)
                            }
                        }
                    }.coordinateSpace(name: "scroll")
                    .onPreferenceChange(TopOffsetKey.self) { value in
                        print(value)
                        topOffset = value
                    }.background(
                        VStack(spacing:0) {
                            Image("GKBackgroundPortrait").resizable(capInsets: EdgeInsets(top: 960/2-topOffset, leading: 0, bottom: 0, trailing: -(geometry.size.width-background_size)), resizingMode: .tile).frame(width:geometry.size.width, height:topOffset > 0 ? topOffset : 0).offset(y: topOffset > 0 ? topOffset : 0)
                            Image("GKBackgroundPortrait").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: -(geometry.size.width-background_size)), resizingMode: .tile).frame(width:geometry.size.width, height:geometry.size.height+abs(topOffset)).offset(y: topOffset > 0 ? topOffset : 0)
                        }
                    )
                }.transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case true:
                game_center_friends_destination(friend: current_friend).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            }
        }
    }
}

struct game_center_friends_destination: View {
    @State var topOffset: CGFloat = 0
    @State var background_size: CGFloat = 0
    var friend: GKPlayer
    struct TopOffsetKey: PreferenceKey {
        typealias Value = CGFloat
        
        static var defaultValue: Value = 0
        
        static func reduce(
            value: inout Value,
            nextValue: () -> Value
        ) {
            value = nextValue()
        }
    }
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ZStack {
                    Image("GKBackgroundPortrait").overlay(
                        GeometryReader { proxy in
                            Color.clear.hidden().onAppear() {
                                print(proxy.size.width)
                                background_size = proxy.size.width
                            }
                        }
                    ).opacity(0)
                    VStack(spacing:0) {
                        Spacer().frame(height: 30)
                        Text("\(friend.alias) is...").font(.custom("Superclarendon Bold", size: 15)).foregroundColor(Color(red: 35/255, green: 66/255, blue: 45/255)).lineLimit(0).shadow(color: Color(red: 105/255, green: 194/255, blue: 132/255).opacity(0.85), radius: 0, y: 1)
                        ZStack {
                            Image("GKAliasShadowTexture").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).frame(width:geometry.size.width, height: 74).mask(
                                Text("\(friend.alias)").font(.custom("Phosphate-Inline", size: 74)).lineLimit(0).offset(x: 3.5, y: 3.5)
                            ).shadow(color: Color(red: 86/255, green: 164/255, blue: 108/255).opacity(0.5), radius: 0, y: 1)
                            Image("GKAliasTexture").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).frame(width:geometry.size.width, height: 74).mask(
                                Text("\(friend.alias)").font(.custom("Phosphate-Inline", size: 74))).lineLimit(0)
                        }
                        Spacer().frame(height: 30)
                        HStack {
                            VStack(spacing: 1) {
                                ribbon_view(ribbon: "GKRibbonRed", text: "1")
                                Text("FRIEND") .font(.custom("Helvetica Neue Bold", size: 11.5)).foregroundColor(.white).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                            }.frame(width:geometry.size.width/3-20)
                            VStack(spacing: 1) {
                                ribbon_view(ribbon: "GKRibbonYellow", text: "1")
                                Text("GAME") .font(.custom("Helvetica Neue Bold", size: 11.5)).foregroundColor(.white).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                            }.frame(width:geometry.size.width/3-20)
                            VStack(spacing: 1) {
                                ribbon_view(ribbon: "GKRibbonBlue", text: "1")
                                Text("ACHIEVEMENT") .font(.custom("Helvetica Neue Bold", size: 11.5)).foregroundColor(.white).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                            }.frame(width:geometry.size.width/3-20)
                        }.clipped()
                        Spacer().frame(height:15)
                        HStack(spacing: 0) {
                        Spacer()
                            Image("GKSectionHeaderLeftArrow")
                            Image("GKCellBorderTexture").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).frame(width: 180, height: 50).mask(
                        Text("Games in Common") .font(.custom("Superclarendon Bold", size: 16)))
                            Image("GKSectionHeaderRightArrow")
                            Spacer()
                        }.shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                        ZStack {
                            Image("GKBackgroundPortrait").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).mask(
                                RoundedRectangle(cornerRadius: 10).fill(Color.white))
                            
                            Image("GKCellBorderTexture").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).mask(
                                RoundedRectangle(cornerRadius: 10).fill(Color.clear).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                                .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth:4).cornerRadius(10))).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                            
                            VStack(spacing:0) {
                                ZStack {
                                    Rectangle().fill(Color.clear).frame(height:50)
                                    HStack {
                                        Image("OS_Icon_WIP15").resizable().frame(width:45, height: 45).cornerRadius(45*90/512).padding(.leading, 12).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("1 of 1 achievements") .font(.custom("Helvetica Neue Bold", size: 12)).foregroundColor(Color(red: 29/255, green: 54/255, blue: 37/255)).shadow(color: Color(red: 105/255, green: 194/255, blue: 132/255).opacity(0.80), radius: 0, y: 1)
                                            Text("OldOS").font(.custom("Superclarendon Bold", size: 15)).foregroundColor(.white).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                                            Text("Ranked higher than me") .font(.custom("Helvetica Neue Bold", size: 12)).foregroundColor(Color(red: 29/255, green: 54/255, blue: 37/255)).shadow(color: Color(red: 105/255, green: 194/255, blue: 132/255).opacity(0.80), radius: 0, y: 1)
                                        }
                                        Spacer()
                                        Image("GKDisclosureIndicator").padding([.trailing], 12).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                                    }
                                }.frame(height: 65)
                                
                            }
                        }.frame(height: 65).padding([.leading, .trailing], 12).padding(.top, 0)
                        Spacer()
                    }.offset(y: topOffset < 0 ? -topOffset/2 : 0)
                    GeometryReader { proxy in
                        let offset = proxy.frame(in: .named("scroll")).minY
                        Color.clear.preference(key: TopOffsetKey.self, value: offset)
                    }
                }
            }.coordinateSpace(name: "scroll")
            .onPreferenceChange(TopOffsetKey.self) { value in
                print(value)
                topOffset = value
            }.background(
                VStack(spacing:0) {
                    Image("GKBackgroundPortrait").resizable(capInsets: EdgeInsets(top: 960/2-topOffset, leading: 0, bottom: 0, trailing: -(geometry.size.width-background_size)), resizingMode: .tile).frame(width:geometry.size.width, height:topOffset > 0 ? topOffset : 0).offset(y: topOffset > 0 ? topOffset : 0)
                    Image("GKBackgroundPortrait").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: -(geometry.size.width-background_size)), resizingMode: .tile).frame(width:geometry.size.width, height:geometry.size.height+abs(topOffset)).offset(y: topOffset > 0 ? topOffset : 0)
                }
            )
        }
    }
        
    }


//** Mark: Games Views

struct game_center_games_view: View {
    @State var topOffset: CGFloat = 0
    @State var background_size: CGFloat = 0
    struct TopOffsetKey: PreferenceKey {
        typealias Value = CGFloat
        
        static var defaultValue: Value = 0
        
        static func reduce(
            value: inout Value,
            nextValue: () -> Value
        ) {
            value = nextValue()
        }
    }
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ZStack {
                    Image("GKBackgroundPortrait").overlay(
                        GeometryReader { proxy in
                            Color.clear.hidden().onAppear() {
                                print(proxy.size.width)
                                background_size = proxy.size.width
                            }
                        }
                    ).opacity(0)
                    VStack {
                        ZStack {
                            Image("GKBackgroundPortrait").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).mask(
                                RoundedRectangle(cornerRadius: 10).fill(Color.white))
                            
                            Image("GKCellBorderTexture").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).mask(
                                RoundedRectangle(cornerRadius: 10).fill(Color.clear).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                                .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth:4).cornerRadius(10))).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                            
                            VStack(spacing:0) {
                                ZStack {
                                    Rectangle().fill(Color.clear).frame(height:50)
                                    HStack {
                                        Image("OS_Icon_WIP15").resizable().frame(width:45, height: 45).cornerRadius(45*90/512).padding(.leading, 12).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("1 of 1 achievements") .font(.custom("Helvetica Neue Bold", size: 12)).foregroundColor(Color(red: 29/255, green: 54/255, blue: 37/255)).shadow(color: Color(red: 105/255, green: 194/255, blue: 132/255).opacity(0.80), radius: 0, y: 1)
                                            Text("OldOS").font(.custom("Superclarendon Bold", size: 15)).foregroundColor(.white).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                                            Text("#1 of 10,000") .font(.custom("Helvetica Neue Bold", size: 12)).foregroundColor(Color(red: 29/255, green: 54/255, blue: 37/255)).shadow(color: Color(red: 105/255, green: 194/255, blue: 132/255).opacity(0.80), radius: 0, y: 1)
                                        }
                                        Spacer()
                                        Image("GKDisclosureIndicator").padding([.trailing], 12).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                                    }
                                }.frame(height: 65)
                                
                            }
                        }.frame(height: 65).padding([.leading, .trailing], 12).padding(.top, 10)
                        Spacer().frame(height:20)
                        large_ribbon_button(ribbon: "GKRibbonButton", text: "Find Game Center Games").padding([.leading, .trailing], 10)
                        Spacer()
                    }.offset(y: topOffset < 0 ? -topOffset/2 : 0)
                    GeometryReader { proxy in
                        let offset = proxy.frame(in: .named("scroll")).minY
                        Color.clear.preference(key: TopOffsetKey.self, value: offset)
                    }
                }
            }.coordinateSpace(name: "scroll")
            .onPreferenceChange(TopOffsetKey.self) { value in
                print(value)
                topOffset = value
            }.background(
                VStack(spacing:0) {
                    Image("GKBackgroundPortrait").resizable(capInsets: EdgeInsets(top: 960/2-topOffset, leading: 0, bottom: 0, trailing: -(geometry.size.width-background_size)), resizingMode: .tile).frame(width:geometry.size.width, height:topOffset > 0 ? topOffset : 0).offset(y: topOffset > 0 ? topOffset : 0)
                    Image("GKBackgroundPortrait").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: -(geometry.size.width-background_size)), resizingMode: .tile).frame(width:geometry.size.width, height:geometry.size.height+abs(topOffset)).offset(y: topOffset > 0 ? topOffset : 0)
                }
            )
        }
    }
}

//** Mark: Request Views

struct game_center_requests_view: View {
    @State var topOffset: CGFloat = 0
    @State var background_size: CGFloat = 0
    struct TopOffsetKey: PreferenceKey {
        typealias Value = CGFloat
        
        static var defaultValue: Value = 0
        
        static func reduce(
            value: inout Value,
            nextValue: () -> Value
        ) {
            value = nextValue()
        }
    }
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ZStack {
                    Image("GKBackgroundPortrait").overlay(
                        GeometryReader { proxy in
                            Color.clear.hidden().onAppear() {
                                print(proxy.size.width)
                                background_size = proxy.size.width
                            }
                        }
                    ).opacity(0)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("No Friend Requests") .font(.custom("Superclarendon Bold", size: 14)).foregroundColor(.white).shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 1)
                            Spacer()
                        }
                        Spacer()
                    }.offset(y: topOffset < 0 ? -topOffset/2 : 0)
                    GeometryReader { proxy in
                        let offset = proxy.frame(in: .named("scroll")).minY
                        Color.clear.preference(key: TopOffsetKey.self, value: offset)
                    }
                }
            }.coordinateSpace(name: "scroll")
            .onPreferenceChange(TopOffsetKey.self) { value in
                print(value)
                topOffset = value
            }.background(
                VStack(spacing:0) {
                    Image("GKBackgroundPortrait").resizable(capInsets: EdgeInsets(top: 960/2-topOffset, leading: 0, bottom: 0, trailing: -(geometry.size.width-background_size)), resizingMode: .tile).frame(width:geometry.size.width, height:topOffset > 0 ? topOffset : 0).offset(y: topOffset > 0 ? topOffset : 0)
                    Image("GKBackgroundPortrait").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: -(geometry.size.width-background_size)), resizingMode: .tile).frame(width:geometry.size.width, height:geometry.size.height+abs(topOffset)).offset(y: topOffset > 0 ? topOffset : 0)
                }
            )
        }
    }
}

//** Mark: Game Center Dependencies

class game_center_observer: ObservableObject {
    @Published var friends = [GKPlayer]()
    @Published var achievements = [GKAchievement]()
    @Published var local_player = GKLocalPlayer()
    @ObservedObject var gameKitHelper = GameKitHelper.sharedInstance
    init() {
        
        gameKitHelper.authenticateLocalPlayer()
        print(GKLocalPlayer.local.alias)
        self.local_player = GKLocalPlayer.local
        print(GKLocalPlayer.local.displayName)
        GKLocalPlayer.local.loadChallengableFriends(completionHandler: { friends, error in
            self.friends = friends ?? []
            print(self.friends)
        })
        GKAchievement.loadAchievements(completionHandler: { achievements, error in
            self.achievements = achievements ?? []
        })
    }
    
}



struct ribbon_view: View {
    var ribbon: String
    var text: String
    @State var proxy:GeometryProxy?
    var body: some View {
        ZStack {
            Image(ribbon)
            Text(text).font(.custom("Superclarendon Bold", size: 18)).lineLimit(0).foregroundColor(.white).offset(y:3.5).overlay(
                GeometryReader { proxy in
                    Color.clear.hidden().onAppear() {
                        self.proxy = proxy
                    }
                }
            ).shadow(color: Color.black.opacity(0.4), radius: 0.5, x: 0, y: 1)
        }.frame(minWidth:(proxy?.size.width ?? 40) + 40 + (text.count <= 2 ? 25 : 0), maxWidth:(proxy?.size.width ?? 40) + 40 + (text.count <= 2 ? 25 : 0), minHeight: 78/2, maxHeight: 78/2)
    }
}

struct large_ribbon_button: View {
    var ribbon: String
    var text: String
    @State var proxy:GeometryProxy?
    var body: some View {
        ZStack {
            Image(ribbon)
            Image("GKCellBackgroundShowMoreGreen").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).brightness(-0.08).mask(
                Text(text).font(.custom("Superclarendon Bold", size: 16)).foregroundColor(.white).lineLimit(0).offset(y:4.5).overlay(
                    GeometryReader { proxy in
                        Color.clear.hidden().onAppear() {
                            self.proxy = proxy
                        }
                    }
                )).shadow(color: Color(red: 224/255, green: 231/255, blue: 124/255).opacity(0.85), radius: 0.5, x: 0, y: 1)
        }.frame(minWidth:(proxy?.size.width ?? 40) + 40 + (text.count <= 2 ? 25 : 0), maxWidth:.infinity, minHeight: 92/2, maxHeight: 92/2)
    }
}



struct TabButtonGameCenter : View {
    
    var image : String
    @Binding var selectedTab : String
    var geometry: GeometryProxy
    var body: some View{
        Button(action: {
            selectedTab = image
        }) {
            ZStack {
                if selectedTab == image {
                    Image("GKTabbarActiveTab").resizable().scaledToFill().frame(width: geometry.size.width/4 - 5, height: 51)
                    VStack(spacing: 2) {
                        ZStack {
                            Image("GKTabbarIcon\(image)Active").resizable().aspectRatio(contentMode: .fit).frame(width: image == "Games" ? 35.5 : image == "Friends" ? 45.5 : 30.5, height: 30.5)
                        }
                        HStack {
                            Spacer()
                            Text(image).foregroundColor(.white).font(.custom("Helvetica Neue Bold", size: 11))
                            Spacer()
                        }
                    }
                } else {
                    VStack(spacing: 2) {
                        Image("GKTabbarIcon\(image)Inactive").resizable().aspectRatio(contentMode: .fit).frame(width: image == "Games" ? 35 : image == "Friends" ? 45.5 : 30, height: 30)
                        HStack {
                            Spacer()
                            Text(image).foregroundColor(.white).font(.custom("Helvetica Neue Bold", size: 11))
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}


struct game_center_title_bar : View {
    var title:String
    public var done_action: (() -> Void)?
    var show_done: Bool?
    public var back_action: (() -> Void)?
    var show_back: Bool?
    @Binding var selectedTab: String
    var body :some View {
        ZStack {
            Image("GKNavbarPortrait").resizable().scaledToFill().clipped().shadow(color: Color.black.opacity(0.98), radius: 6, x: 0.0, y: 3)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(title).ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", size: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).id(title).animation(.none).frame(maxWidth: (selectedTab == "Friends" && show_back == true) ? 200 : .infinity)
                    Spacer()
                }
                Spacer()
            }
            if selectedTab == "Friends", show_back == true {
            VStack {
                Spacer()
                HStack {
                    Button(action:{back_action?()}) {
                    ZStack {
                        Image("GKNavbarBackButtonNormal").frame(width: 70, height: 33).scaledToFill()
                        HStack(alignment: .center) {
                            Text("Friends").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", size: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                        }
                    }.padding(.leading, 50)
                    }
                    Spacer()
                }
                Spacer()
            }
            }
            if selectedTab == "Friends", show_back == false {
                HStack {
                    Spacer()
                    tool_bar_rectangle_button_background_image(button_type: .blue_gray, content: "UIButtonBarPlus", use_image: true).padding(.trailing, 5)
                }
            }
        }
    }
}

struct tool_bar_rectangle_button_background_image: View {
    public var action: (() -> Void)?
    var button_type: tool_bar_button_type
    var content: String
    var use_image: Bool?
    private let gray_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    private let blue_gradient = LinearGradient([(color: Color(red: 120/255, green: 158/255, blue:237/255), location: 0), (color: Color(red: 55/255, green: 110/255, blue:224/255), location: 0.51), (color: Color(red: 34/255, green: 96/255, blue:221/255), location: 0.52), (color: Color(red: 36/255, green: 100/255, blue:224/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        Button(action:{action?()}) {
            ZStack {
                Image("GKNavbarPortrait").scaledToFill().clipped().frame(width: 32, height: 32).cornerRadius(5.5).ps_innerShadow(.roundedRectangle(5.5, Color.clear), radius:1.1, offset: CGPoint(0, 0.4), intensity: 0.85)
                Image(content).resizable().scaledToFit().frame(width: 13).padding([.leading, .trailing], 11)
                
            }
        }.frame(width: 32, height: 32).padding(.trailing, 45)
    }
}

public enum PopupControllerMessage : String
{
    case PresentAuthentication = "PresentAuthenticationViewController"
    case GameCenter = "GameCenterViewController"
}

extension PopupControllerMessage
{
    public func postNotification() {
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: self.rawValue),
            object: self)
    }
    
    public func addHandlerForNotification(_ observer: Any,
                                          handler: Selector) {
        NotificationCenter.default .
            addObserver(observer, selector: handler, name:
                            NSNotification.Name(rawValue: self.rawValue), object: nil)
    }
    
}

// based on code from raywenderlich.com
// helper class to make interacting with the Game Center easier

open class GameKitHelper: NSObject,  ObservableObject,  GKGameCenterControllerDelegate  {
    public var authenticationViewController: UIViewController?
    public var lastError: Error?
    
    
    private static let _singleton = GameKitHelper()
    public class var sharedInstance: GameKitHelper {
        return GameKitHelper._singleton
    }
    
    private override init() {
        super.init()
    }
    @Published public var enabled :Bool = false
    
    public var  gameCenterEnabled : Bool {
        return GKLocalPlayer.local.isAuthenticated }
    
    public func authenticateLocalPlayer () {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = {(viewController, error) in
            
            self.lastError = error as NSError?
            self.enabled = GKLocalPlayer.local.isAuthenticated
            if viewController != nil {
                self.authenticationViewController = viewController
                PopupControllerMessage
                    .PresentAuthentication
                    .postNotification()
            }
        }
    }
    
    public var gameCenterViewController : GKGameCenterViewController? { get {
        
        guard gameCenterEnabled else {
            print("Local player is not authenticated")
            return nil }
        
        let gameCenterViewController = GKGameCenterViewController()
        
        gameCenterViewController.gameCenterDelegate = self
        
        gameCenterViewController.viewState = .achievements
        
        return gameCenterViewController
    }}
    
    open func gameCenterViewControllerDidFinish(_
                                                    gameCenterViewController: GKGameCenterViewController) {
        
        gameCenterViewController.dismiss(
            animated: true, completion: nil)
    }
    
}
