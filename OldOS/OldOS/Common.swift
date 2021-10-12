//
//  Common.swift
//  OldOS
//
//  Created by Zane Kleinberg on 1/15/21.
//

import SwiftUI
import CoreTelephony
import PureSwiftUITools
import Foundation
import SystemConfiguration.CaptiveNetwork
import LocationProvider
import MediaPlayer

//So what is this entire file just called common? Basically, my mindset was to build the app in the same way Apple built interface builder — you have a collection of UI elements at your disposal that are bases. You can then make a copy in whatever other file you'd like if you require custom abilities. If you just need the generic version, you can use the generic.

struct multitasking_music_controls: View {
    @Binding var current_view: String
    @Binding var should_update: Bool
    @Binding var show_remove: Bool
    @Binding var instant_multitasking_change: Bool
    @Binding var show_multitasking: Bool
    @Binding var apps_scale: CGFloat
    @Binding var dock_offset: CGFloat
    @State var now_playing = MPMusicPlayerController.systemMusicPlayer.nowPlayingItem?.title ?? ""
    @State var is_playing = MPMusicPlayerController.systemMusicPlayer.playbackState
    var body: some View {
        HStack {
            LazyVGrid(columns: [
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)*2/3), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)*2/3), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)*2/3), spacing: 1),
                GridItem(.fixed(UIScreen.main.bounds.width/(390/85)), spacing: 1),
            ], alignment: .center, spacing: UIScreen.main.bounds.height/(844/40)) {
                Image("RotationUnlockButton").resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
                Button(action:{
                    let music_player = MPMusicPlayerController.systemMusicPlayer
                    music_player.skipToPreviousItem()
                    now_playing = MPMusicPlayerController.systemMusicPlayer.nowPlayingItem?.title ?? ""
                }) {
                    Image("MCPrev")
                }
                Button(action:{
                    let music_player = MPMusicPlayerController.systemMusicPlayer
                    if  (music_player.playbackState) == .playing {
                        music_player.pause()
                        is_playing = .paused
                    } else {
                        music_player.play()
                        is_playing = .playing
                    }
                    
                }) {
                    Image(is_playing == .playing ? "MCPause" : "MCPlay")
                }
                Button(action:{
                        let music_player = MPMusicPlayerController.systemMusicPlayer
                        music_player.skipToNextItem()
                    now_playing = MPMusicPlayerController.systemMusicPlayer.nowPlayingItem?.title ?? ""
                    
                }) {
                    Image("MCNext")
                }
                Button(action:{
                    if current_view == "iPod" {
                        withAnimation {
                            show_multitasking = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
                            instant_multitasking_change = false
                        }
                        should_update = false
                        show_remove = false
                    } else {
                        withAnimation(.linear(duration: 0.32)) {
                            apps_scale = 4
                            dock_offset = 100
                        }
                        DispatchQueue.main.asyncAfter(deadline:.now()+0.01) {
                            withAnimation(.linear(duration: 0.32)) {
                                current_view = "iPod"
                            }
                        }
                    }
                }){
                Image("iPod").resizable().scaledToFit().frame(width: UIScreen.main.bounds.width/(390/60))
                }
            }
        }.overlay(VStack {
            Spacer()
            Text("\(now_playing)").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.white).shadow(color: Color.black.opacity(0.9), radius: 0.75, x: 0, y: 1.75).offset(y: 15)
        })
    }
}


struct toggle_orange: View {
    @State var offset = CGPoint(x: -53.6666666667, y: 0)
    @State var show_overlay: Bool = false
    @State var on: Bool = false
    var body: some View {
        ZStack {
            Rectangle().fill(LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 255/255, green: 140/255, blue: 14/255), location: 0.0), .init(color:Color(red: 255/255, green: 140/255, blue: 15/255), location: 0.50), .init(color:Color(red: 253/255, green: 168/255, blue: 61/255), location: 0.47), .init(color:Color(red: 253/255, green: 177/255, blue: 72/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).innerShadowToggle(color: Color(red: 101/255, green: 41/255, blue: 1/255).opacity(0.95), radius: 0.3).overlay(LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 232/255, green: 232/255, blue: 232/255), location: 0.0), .init(color:Color(red: 235/255, green: 235/255, blue: 235/255), location: 0.50), .init(color:Color(red: 247/255, green: 247/255, blue: 247/255), location: 0.50), .init(color:Color(red: 251/255, green: 251/255, blue: 251/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).innerShadowToggleSecondary(color: Color.black.opacity(0.43), radius: 0.3).cornerRadius(0).offset(x:100 + offset.x)).cornerRadius(4).overlay(
               RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray, lineWidth: 0.25)
            )
            HStack {
                Spacer()
                Text("OFF").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color(red: 125/255, green: 125/255, blue: 125/255)).padding(.trailing,12).shadow(color: Color.white.opacity(0.84), radius: 2, x: 0.0, y: 2).offset(x: 53.6666666667 + offset.x)
            }.clipped()
            HStack {
                Text("ON").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.white).padding(.leading,14).shadow(color: Color.black.opacity(0.45), radius: 0.34, x: 0, y: -1.25)
                ZStack {
                    Rectangle().fill(Color(red: 101/255, green: 41/255, blue: 1/255).opacity(0.6)).cornerRadius(4.25).padding(.leading, 4).offset(x:-1).frame(maxHeight:30).clipped().blur(0.5).opacity(offset.x > -52 ? 0.95 : 0)
                    Rectangle().fill(Color(red: 101/255, green: 41/255, blue: 1/255).opacity(0.6)).cornerRadius(4.25).padding(.leading, 4).offset(x:1).frame(maxHeight:30).clipped().blur(0.5).opacity(offset.x < -1 ? 0.95: 0)
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color(red: 208/255, green: 208/255, blue: 208/255), Color(red: 254/255, green: 254/255, blue: 254/255)]), startPoint: .top, endPoint: .bottom)).innerShadowToggleTop(color: Color.white, radius: 0.15).cornerRadius(4).overlay(Color.gray.opacity(show_overlay ? 0.3 : 0)).addBorder(LinearGradient(gradient: Gradient(colors: [Color(red: 136/255, green: 135/255, blue: 135/255), Color(red: 183/255, green: 182/255, blue: 182/255)]), startPoint: .top, endPoint: .bottom), width: 0.5, cornerRadius: 4).padding(.leading, 4)
                }
            }.draggable_toggle(offset: $offset, on: $on, show_overlay: $show_overlay).clipped()
        }.frame(width: 104, height: 30)
    }
}

struct generic_title_bar : View {
    var title:String
    public var done_action: (() -> Void)?
    var show_done: Bool?
    var body :some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.49), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.49), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(title).ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", fixedSize: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).id(title)
                    Spacer()
                }
                Spacer()
            }
            if show_done == true {
            HStack {
                Spacer()
            tool_bar_rectangle_button(action: {done_action?()}, button_type: .blue, content: "Done").padding(.trailing, 5)
            }
            }
        }
    }
}

struct generic_title_bar_clear_cancel : View {
    var title:String
    public var done_action: (() -> Void)?
    public var clear_action: (() -> Void)?
    var show_done: Bool?
    var show_clear: Bool?
    var body :some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.49), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.49), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(title).ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", fixedSize: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).id(title)
                    Spacer()
                }
                Spacer()
            }
            if show_done == true {
            HStack {
                Spacer()
            tool_bar_rectangle_button(action: {done_action?()}, button_type: .blue_gray, content: "Cancel").padding(.trailing, 5)
            }
            }
            if show_clear == true {
            HStack {
            tool_bar_rectangle_button(action: {clear_action?()}, button_type: .blue_gray, content: " Clear ").padding(.leading, 5)
                Spacer()
            }
            }
        }
    }
}



struct generic_title_bar_cancel_save : View {
    var title:String
    public var cancel_action: (() -> Void)?
    public var save_action: (() -> Void)?
    var show_cancel: Bool?
    var show_save: Bool?
    var switch_to_done: Bool?
    var body :some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.49), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.49), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(title).ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", fixedSize: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).id(title)
                    Spacer()
                }
                Spacer()
            }
            if show_save == true {
            HStack {
                Spacer()
                tool_bar_rectangle_button(action: {save_action?()}, button_type: .blue, content: switch_to_done == true ? "Done" : "Save").padding(.trailing, 5)
            }
            }
            if show_cancel == true {
                HStack {
                    tool_bar_rectangle_button(action: {cancel_action?()}, button_type: .blue_gray, content: "Cancel").padding(.leading, 5)
                    Spacer()
                }
                
            }
        }
    }
}

struct toggle: View {
    @State var offset = CGPoint(x: -53.6666666667, y: 0)
    @State var show_overlay: Bool = false
    @State var on: Bool = true
    var body: some View {
        ZStack {
            Rectangle().fill(LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 52/255, green: 123/255, blue: 245/255), location: 0.0), .init(color:Color(red: 53/255, green: 126/255, blue: 247/255), location: 0.50), .init(color:Color(red: 91/255, green: 154/255, blue: 247/255), location: 0.47), .init(color:Color(red: 101/255, green: 161/255, blue: 249/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).innerShadowToggle(color: Color(red: 1/255, green: 19/255, blue: 50/255).opacity(0.32), radius: 0.3).overlay(LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 232/255, green: 232/255, blue: 232/255), location: 0.0), .init(color:Color(red: 235/255, green: 235/255, blue: 235/255), location: 0.50), .init(color:Color(red: 247/255, green: 247/255, blue: 247/255), location: 0.50), .init(color:Color(red: 251/255, green: 251/255, blue: 251/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).innerShadowToggleSecondary(color: Color.black.opacity(0.43), radius: 0.3).cornerRadius(0).offset(x:100 + offset.x)).cornerRadius(4).overlay(
               RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray, lineWidth: 0.25)
            )
            HStack {
                Spacer()
                Text("OFF").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color(red: 125/255, green: 125/255, blue: 125/255)).padding(.trailing,12).shadow(color: Color.white.opacity(0.84), radius: 2, x: 0.0, y: 2).offset(x: 53.6666666667 + offset.x)
            }.clipped()
            HStack {
                Text("ON").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.white).padding(.leading,14).shadow(color: Color.black.opacity(0.45), radius: 0.34, x: 0, y: -1.25)
                ZStack {
                    Rectangle().fill(Color(red: 101/255, green: 41/255, blue: 1/255).opacity(0.6)).cornerRadius(4.25).padding(.leading, 4).offset(x:-1).frame(maxHeight:30).clipped().blur(0.5).opacity(offset.x > -52 ? 0.95 : 0)
                    Rectangle().fill(Color(red: 101/255, green: 41/255, blue: 1/255).opacity(0.6)).cornerRadius(4.25).padding(.leading, 4).offset(x:1).frame(maxHeight:30).clipped().blur(0.5).opacity(offset.x < -1 ? 0.95: 0)
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color(red: 208/255, green: 208/255, blue: 208/255), Color(red: 254/255, green: 254/255, blue: 254/255)]), startPoint: .top, endPoint: .bottom)).innerShadowToggleTop(color: Color.white, radius: 0.15).cornerRadius(4).overlay(Color.gray.opacity(show_overlay ? 0.3 : 0)).addBorder(LinearGradient(gradient: Gradient(colors: [Color(red: 136/255, green: 135/255, blue: 135/255), Color(red: 183/255, green: 182/255, blue: 182/255)]), startPoint: .top, endPoint: .bottom), width: 0.5, cornerRadius: 4).padding(.leading, 4)
                }
            }.draggable_toggle(offset: $offset, on: $on, show_overlay: $show_overlay).clipped()
        }.frame(width: 104, height: 30).onAppear() {
            if on {
                offset.x = 0
            }
        }
    }
}

struct list_row: Identifiable, Equatable {
    
    var id = UUID()
    var title: String
    var image: String?
    var content: AnyView
    var destination: String?
    var selected: Bool?
    static func == (lhs: list_row, rhs: list_row) -> Bool {
        return lhs.id == rhs.id
    }
}

struct PrimaryButtonStyle2: ButtonStyle {
    let height: CGFloat = 50
    let gradient = LinearGradient(gradient: Gradient(colors: [Color(red:41/255, green:146/255, blue:229/255), Color(red:24/255, green:115/255, blue:219/255)]), startPoint: .top, endPoint: .bottom)
    let gradient_clear = LinearGradient(gradient: Gradient(colors: [Color.clear]), startPoint: .top, endPoint: .bottom)
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
            .background(configuration.isPressed ? gradient : gradient_clear)
            .cornerRadius(.infinity)
    }
}


struct NoHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.custom("Helvetica Neue Bold", fixedSize: 13.25)).frame(width:14, height: 16.5)
            .foregroundColor(Color(red: 106/255, green: 115/255, blue: 125/255))
            .padding(.trailing, 12)
    }
}


struct list_section: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var content: [list_row]
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10)
                                                                            .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25))
            VStack(spacing:0) {
                ForEach(content) { row in
                    if row.destination != nil {
                    Button(action: {if row.destination != nil {forward_or_backward = false; DispatchQueue.main.asyncAfter(deadline:.now()+0.3){ withAnimation(.linear(duration: 0.28)) {current_nav_view = row.destination ?? ""}}}}) {
                        ZStack {
                            if row == content.last {
                                Rectangle().fill(Color.clear).frame(height:50)
                            } else {
                                Rectangle().fill(Color.clear).frame(height:50).border_bottom(width: 1.25, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))
                            }
                            HStack {
                                if row.image != nil {
                                Image(row.image ?? "").resizable().frame(width:30, height: 30).padding(.leading, 12)
                                }
                                Text(row.title).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).padding(.leading, row.image != nil ? 0 : 12)
                                Spacer()
                                row.content
                            }
                        }
                    }.frame(height: 50)
                    } else {
                        ZStack {
                            if row == content.last {
                                Rectangle().fill(Color.clear).frame(height:50)
                            } else {
                                Rectangle().fill(Color.clear).frame(height:50).border_bottom(width: 1.25, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))
                            }
                            HStack {
                                if row.image != nil {
                                Image(row.image ?? "").resizable().frame(width:30, height: 30).padding(.leading, 12)
                                }
                                Text(row.title).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).padding(.leading, row.image != nil ? 0 : 12)
                                Spacer()
                                row.content
                            }
                        }.frame(height: 50)
                    }
                }
            }
        }.frame(height: CGFloat(content.count)*50).padding([.leading, .trailing], 12)
    }
}

struct list_section_content_only: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var content: [list_row]
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10)
                                                                            .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25))
            VStack(spacing:0) {
                ForEach(content) { row in
                    if row.destination != nil {
                    Button(action: {if row.destination != nil {forward_or_backward = false; DispatchQueue.main.asyncAfter(deadline:.now()+0.3){ withAnimation(.linear(duration: 0.28)) {current_nav_view = row.destination ?? ""}}}}) {
                        ZStack {
                            if row == content.last {
                                Rectangle().fill(Color.clear).frame(height:50)
                            } else {
                                Rectangle().fill(Color.clear).frame(height:50).border_bottom(width: 1.25, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))
                            }
                            HStack {
                                if row.image != nil {
                                Image(row.image ?? "").resizable().frame(width:30, height: 30).padding(.leading, 12)
                                }
                                if row.title != "" {
                                Text(row.title).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).padding(.leading, row.image != nil ? 0 : 12)
                                Spacer()
                                }
                                row.content
                            }
                        }
                    }.frame(height: 50)
                    } else {
                        ZStack {
                            if row == content.last {
                                Rectangle().fill(Color.clear).frame(height:50)
                            } else {
                                Rectangle().fill(Color.clear).frame(height:50).border_bottom(width: 1.25, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))
                            }
                            HStack {
                                if row.image != nil {
                                Image(row.image ?? "").resizable().frame(width:30, height: 30).padding(.leading, 12)
                                }
                                if row.title != "" {
                                Text(row.title).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).padding(.leading, row.image != nil ? 0 : 12)
                                Spacer()
                                }
                                row.content
                            }
                        }.frame(height: 50)
                    }
                }
            }
        }.frame(height: CGFloat(content.count)*50).padding([.leading, .trailing], 12)
    }
}

struct list_section_content_only_large: View {
    @Binding var current_nav_view: String?
    @Binding var forward_or_backward: Bool?
    var content: [list_row]
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10)
                                                                            .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25))
            VStack(spacing:0) {
                ForEach(content) { row in
                    if row.destination != nil {
                    Button(action: {if row.destination != nil {forward_or_backward = false; DispatchQueue.main.asyncAfter(deadline:.now()+0.3){ withAnimation(.linear(duration: 0.28)) {current_nav_view = row.destination ?? ""}}}}) {
                        ZStack {
                            if row == content.last {
                                Rectangle().fill(Color.clear).frame(height:75)
                            } else {
                                Rectangle().fill(Color.clear).frame(height:75).border_bottom(width: 1.25, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))
                            }
                            HStack {
                                if row.image != nil {
                                Image(row.image ?? "").resizable().frame(width:30, height: 30).padding(.leading, 12)
                                }
                                if row.title != "" {
                                Text(row.title).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).padding(.leading, row.image != nil ? 0 : 12)
                                Spacer()
                                }
                                row.content
                            }
                        }
                    }.frame(height: 50)
                    } else {
                        ZStack {
                            if row == content.last {
                                Rectangle().fill(Color.clear).frame(height:75)
                            } else {
                                Rectangle().fill(Color.clear).frame(height:75).border_bottom(width: 1.25, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))
                            }
                            HStack {
                                if row.image != nil {
                                Image(row.image ?? "").resizable().frame(width:30, height: 30).padding(.leading, 12)
                                }
                                if row.title != "" {
                                Text(row.title).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).padding(.leading, row.image != nil ? 0 : 12)
                                Spacer()
                                }
                                row.content
                            }
                        }.frame(height: 75)
                    }
                }
            }
        }.frame(height: CGFloat(content.count)*75).padding([.leading, .trailing], 12)
    }
}


struct list_section_oversize: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var content: [list_row]
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10)
                                                                            .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25))
            VStack(spacing:0) {
                ForEach(content) { row in
                    if row.destination != nil {
                    Button(action: {if row.destination != nil {forward_or_backward = false; DispatchQueue.main.asyncAfter(deadline:.now()+0.3){ withAnimation(.linear(duration: 0.28)) {current_nav_view = row.destination ?? ""}}}}) {
                        ZStack {
                            if row == content.last {
                                Rectangle().fill(Color.clear).frame(height:50)
                            } else {
                                Rectangle().fill(Color.clear).frame(height:50).border_bottom(width: 1.25, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))
                            }
                            HStack {
                                if row.image != nil {
                                Image(row.image ?? "").resizable().frame(width:30, height: 30).padding(.leading, 12)
                                }
                                Text(row.title).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).padding(.leading, row.image != nil ? 0 : 12)
                                Spacer()
                                row.content
                            }
                        }
                    }.frame(height: 50)
                    } else {
                        ZStack {
                            if row == content.last {
                                Rectangle().fill(Color.clear).frame(height:50)
                            } else {
                                Rectangle().fill(Color.clear).frame(height:50).border_bottom(width: 1.25, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))
                            }
                            HStack {
                                if row.image != nil {
                                Image(row.image ?? "").resizable().frame(width:30, height: 30).padding(.leading, 12)
                                }
                                Text(row.title).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).padding(.leading, row.image != nil ? 0 : 0)
                                row.content
                            }
                        }.frame(height: 50)
                    }
                }
            }
        }.frame(height: CGFloat(content.count)*50).padding([.leading, .trailing], 12)
    }
}
struct list_section_blue: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var content: [list_row]
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10)
                                                                            .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25))
            VStack(spacing:0) {
                ForEach(content) { row in
                    if row.destination != nil {
                    Button(action: {if row.destination != nil {forward_or_backward = false; DispatchQueue.main.asyncAfter(deadline:.now()+0.3){ withAnimation(.linear(duration: 0.28)) {current_nav_view = row.destination ?? ""}}}}) {
                        ZStack {
                            if row == content.last {
                                Rectangle().fill(Color.clear).frame(height:50)
                            } else {
                                Rectangle().fill(Color.clear).frame(height:50).border_bottom(width: 1.25, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))
                            }
                            HStack {
                                if row.selected != nil {
                                Image(row.image ?? "").resizable().frame(width:30, height: 30).padding(.leading, 12)
                                }
                                Text(row.title).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color(red: 50/255, green: 50/255, blue: 74/255)).padding(.leading, row.image != nil ? 0 : 12)
                                Spacer()
                                row.content
                            }
                        }//.frame(height: 50)
                    }.frame(height: 50)
                    } else {
                        ZStack {
                            if row == content.last {
                                Rectangle().fill(Color.clear).frame(height:50)
                            } else {
                                Rectangle().fill(Color.clear).frame(height:50).border_bottom(width: 1.25, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))
                            }
                            HStack {
                              if row.image != nil {
                                    Image(row.image ?? "").resizable().font(Font.title.weight(.bold)).frame(width:15, height: 15).foregroundColor(row.selected == true ? Color(red: 62/255, green: 83/255, blue: 131/255) : .black).padding(.leading, 12)
                                } else {
                                   // Spacer().frame(width:15).padding(.leading,12)
                                }
                                Text(row.title).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(row.selected == true ? Color(red: 62/255, green: 83/255, blue: 131/255) : .black).padding(.leading, row.image != nil ? 0 : 12)
                                Spacer()
                                row.content
                            }
                        }.frame(height: 50)
                    }
                }
            }
        }.frame(height: CGFloat(content.count)*50).padding([.leading, .trailing], 12)
    }
}
struct title_bar : View {
    @Binding var forward_or_backward: Bool
    @Binding var current_nav_view: String
    var title:String
    var body :some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.49), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.49), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(title).ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", fixedSize: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)).combined(with: .opacity)).id(title)
                    Spacer()
                }
                Spacer()
            }
            if current_nav_view != "Settings", current_nav_view != "Wallpaper_Select", current_nav_view.contains("General_") == false {
            VStack {
                Spacer()
                HStack {
                    Button(action:{forward_or_backward = true; withAnimation(.linear(duration: 0.28)){current_nav_view = ((current_nav_view == "Wallpaper_Grid" || current_nav_view == "Wallpaper_Grid_Camera_Roll") ? "Wallpaper_Select" : "Settings")}}) {
                    ZStack {
                        Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                        HStack(alignment: .center) {
                            Text((current_nav_view == "Wallpaper_Grid" || current_nav_view == "Wallpaper_Grid_Camera_Roll") ? "Back" : "Settings").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                        }
                    }.padding(.leading, 6)
                    }.transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)).combined(with: AnyTransition.opacity))
                    Spacer()
                }
                Spacer()
            }
            }
            if current_nav_view == "Wallpaper_Select" {
            VStack {
                Spacer()
                HStack {
                    Button(action:{forward_or_backward = true; withAnimation(.linear(duration: 0.28)){current_nav_view = "Wallpaper"}}) {
                    ZStack {
                        Image("Button_wp4").resizable().aspectRatio(contentMode: .fit).frame(width:84, height: 34.33783783783784)
                        HStack(alignment: .center) {
                            Text("Wallpaper").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1).offset(x: 1)
                        }
                    }.padding(.leading, 6)
                    }.transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)).combined(with: AnyTransition.opacity))
                    Spacer()
                }
                Spacer()
            }
            }
            if  current_nav_view.contains("General_") {
            VStack {
                Spacer()
                HStack {
                    Button(action:{forward_or_backward = true; withAnimation(.linear(duration: 0.28)){current_nav_view = "General" }}) {
                    ZStack {
                        Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                        HStack(alignment: .center) {
                            Text("General").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                        }
                    }.padding(.leading, 6)
                    }.transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)).combined(with: AnyTransition.opacity))
                    Spacer()
                }
                Spacer()
            }
            }
        }
    }
}

//In App Status Bar

struct status_bar_in_app: View {
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
    var selected_page = 1
    @State var wifi_connected : Bool = true
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.init(red: 237/255, green: 244/255, blue: 247/255), Color.init(red: 191/255, green: 199/255, blue: 203/255)]), startPoint: UnitPoint(x: 0.5, y: 0.07), endPoint: .bottom).innerShadowBottomView(color: Color.init(red: 142/255, green: 149/255, blue: 154/255), radius: 0.05).border_bottom(width: 0.45, edges:[.bottom], color: Color.init(red: 93/255, green: 100/255, blue: 105/255)).cornerRadiusSpecific(radius: 1.75, corners: [.topLeft, .topRight])
            HStack {
                Text(carrier_id == "" ? "No SIM" : carrier_id).foregroundColor(carrier_id == "" ? .black : Color.init(red: 66/255, green: 66/255, blue: 66/255)).font(.custom("Helvetica Neue Bold", fixedSize: 15)).shadowStyle().onAppear() {
                    let networkInfo = CTTelephonyNetworkInfo()
                    let carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value
                    
                    // Get carrier name
                    let carrierName = carrier?.carrierName
                    carrier_id = carrierName ?? ""
                }
                ZStack {
                    Image(systemName: "wifi").gradientForegroundNonDynamic(colors: [Color.init(red: 32/255, green: 157/255, blue: 237/255), Color.init(red: 72/255, green: 118/255, blue: 196/255)]) .opacity(wifi_connected ? 1 : 0).shadowStyle().mask( Image(systemName: "wifi").gradientForegroundNonDynamic(colors: [Color.init(red: 32/255, green: 157/255, blue: 237/255), Color.init(red: 72/255, green: 118/255, blue: 196/255)]) .opacity(wifi_connected ? 1 : 0).shadowStyle().innerShadow2(color: Color.black.opacity(0.8), radius: 1))//Is it messy, yes, does it work, yes
                }
                Spacer()
                Text("\(Int(battery_level))%").foregroundColor(Color.init(red: 74/255, green: 74/255, blue: 74/255)).font(.custom("Helvetica Neue Bold", size: 15)).shadowStyle().offset(x: 10).isHidden(charging)
                battery_in_app(battery: Float(battery_level/100), charging: charging)
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
                Text(timeString(date: date).uppercased()).foregroundColor(Color.black).font(.custom("Helvetica Neue Bold", fixedSize: 15)).shadowStyle()
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

extension View {
    func shadowStyle() -> some View {
        self.modifier(Shadow())
    }
}

struct Shadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.white.opacity(0.5), radius: 0, x: 0, y: 1)
    }
}

//Yes, all this for a battery
struct battery_in_app: View {
    var battery = Float()
    var charging = Bool()
    let rect = CGRect(x: 0, y: 0, width: 17, height: 6.5)
    var body: some View {
        HStack {
            ZStack {
                Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 77/255, green: 77/255, blue: 79/255), Color.init(red: 77/255, green: 77/255, blue: 79/255), Color.init(red: 198/255, green: 198/255, blue: 198/255)]), startPoint: .top, endPoint: .bottom)).innerShadow2(color:Color.init(red: 51/255, green: 53/255, blue: 58/255), radius: 0.2).overlay(RoundedRectangle(cornerRadius:0.25).stroke(LinearGradient(gradient: Gradient(colors: [Color.init(red: 39/255, green: 41/255, blue: 47/255), Color.init(red: 95/255, green: 101/255, blue: 116/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 1.25)).frame(width: 23.0, height: 12.25).shadowStyle()
                Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 107/255, green: 208/255, blue: 55/255), Color.init(red: 215/255, green: 252/255, blue: 180/255), Color.init(red: 134/255, green: 226/255, blue: 73/255), Color.init(red: 68/255, green: 163/255, blue: 29/255)]), startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.73))).innerShadow2(color: Color.init(red: 220/255, green: 255/255, blue: 177/255), radius: 0.2).frame(width: 21.5*CGFloat(battery), height: 12.25-1.5).offset(x:(-21.5/2)+(21.5/2)*CGFloat(battery)) .applyModifier(charging) {  AnyView($0.overlay(ZStack {Image(systemName:"bolt.fill").resizable().frame(width: 8, height: 12.25-2.5)}.frame(width: 21.5*CGFloat(battery), height: 12.25-1.5).foregroundColor(.black)))
                }
            }
            
            Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 250/255, green: 250/255, blue: 250/255), Color.init(red: 149/255, green: 149/255, blue: 149/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius:0.25).stroke(LinearGradient(gradient: Gradient(colors: [Color.init(red: 39/255, green: 41/255, blue: 47/255), Color.init(red: 95/255, green: 101/255, blue: 116/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 1)).frame(width: 3, height: 5).offset(x:-7.95)
        }
    }
}

public extension ShapeAndContent {
    static var rectangleCustomCorners: ShapeAndContent<RoundedCorners, Color> {
        rectangleCustomCorners(Color.clear)
    }
    
    static func rectangleCustomCorners<V: View>(_ content: V? = nil) -> ShapeAndContent<RoundedCorners, V> {
        ShapeAndContent<RoundedCorners, V>(RoundedCorners(tl: 6, tr: 0, bl: 6, br: 0), content)
    }
    static var rectangleCustomCornersRight: ShapeAndContent<RoundedCorners, Color> {
        rectangleCustomCorners(Color.clear)
    }
    
    static func rectangleCustomCornersRight<V: View>(_ content: V? = nil) -> ShapeAndContent<RoundedCorners, V> {
        ShapeAndContent<RoundedCorners, V>(RoundedCorners(tl: 0, tr: 6, bl: 0, br: 6), content)
    }
    static var rectangleCustomCorners_Double: ShapeAndContent<RoundedCorners, Color> {
        rectangleCustomCorners(Color.clear)
    }
    
    static func rectangleCustomCorners_Double<V: View>(_ content: V? = nil) -> ShapeAndContent<RoundedCorners, V> {
        ShapeAndContent<RoundedCorners, V>(RoundedCorners(tl: 12, tr: 0, bl: 12, br: 0), content)
    }
    static var rectangleCustomCornersRight_Double: ShapeAndContent<RoundedCorners, Color> {
        rectangleCustomCorners(Color.clear)
    }
    
    static func rectangleCustomCornersRight_Double<V: View>(_ content: V? = nil) -> ShapeAndContent<RoundedCorners, V> {
        ShapeAndContent<RoundedCorners, V>(RoundedCorners(tl: 0, tr: 12, bl: 0, br: 12), content)
    }
}

public struct RoundedCorners: Shape {
    var tl: CGFloat = 0.0
    var tr: CGFloat = 0.0
    var bl: CGFloat = 0.0
    var br: CGFloat = 0.0

    public func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.size.width
        let h = rect.size.height

        // Make sure we do not exceed the size of the rectangle
        let tr = min(min(self.tr, h/2), w/2)
        let tl = min(min(self.tl, h/2), w/2)
        let bl = min(min(self.bl, h/2), w/2)
        let br = min(min(self.br, h/2), w/2)

        path.move(to: CGPoint(x: w / 2.0, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr,
                    startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)

        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br,
                    startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)

        path.addLine(to: CGPoint(x: bl, y: h))
        path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl,
                    startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)

        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(center: CGPoint(x: tl, y: tl), radius: tl,
                    startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)

        return path
    }
}

struct dual_segmented_control: View {
    @Binding var selected: Int //either 0 or 1
    @Binding var instant_multitasking_change: Bool
    var first_text: String
    var second_text: String
    var should_animate:Bool?
    private let unselected_gradient = LinearGradient([(color: Color(red: 158/255, green: 173/255, blue: 191/255), location: 0), (color: Color(red: 137/255, green: 155/255, blue: 178/255), location: 0.51), (color: Color(red: 127/255, green: 148/255, blue: 176/255), location: 0.51), (color: Color(red: 126/255, green: 148/255, blue: 178/255), location: 1)], from: .top, to: .bottom)
    private let selected_gradient = LinearGradient([(color: Color(red: 136/255, green: 160/255, blue: 190/255), location: 0), (color: Color(red: 88/255, green: 119/255, blue: 162/255), location: 0.51), (color: Color(red: 71/255, green: 105/255, blue: 153/255), location: 0.51), (color: Color(red: 74/255, green: 108/255, blue: 154/255), location: 1)], from: .top, to: .bottom)
    private let middle_gradient = LinearGradient([(color: Color(red: 73/255, green: 85/255, blue: 98/255), location: 0), (color: Color(red: 92/255, green: 118/255, blue: 156/255), location: 0.04), (color: Color(red: 58/255, green: 90/255, blue: 136/255), location: 0.51), (color: Color(red: 51/255, green: 84/255, blue: 131/255), location: 0.51), (color: Color(red: 37/255, green: 72/255, blue: 120/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        GeometryReader{ geometry in
            HStack(spacing: 0) {
                Button(action:{selected = 0}) {
                    Text(first_text).font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0, y: -0.66)
                }.frame(width: geometry.size.width/2, height: geometry.size.height).ps_innerShadow(.rectangleCustomCorners(selected == 0 ? selected_gradient: unselected_gradient), radius:0.82, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                Button(action:{selected = 1}) {
                    Text(second_text).font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0, y: -0.66)
                }.frame(width: geometry.size.width/2, height: geometry.size.height).ps_innerShadow(.rectangleCustomCornersRight(selected == 1 ? selected_gradient: unselected_gradient), radius:0.82, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
            }.overlay(
                ZStack {
                    HStack(spacing:0) {
                        Spacer()
                        Rectangle().fill(selected == 0 ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                            })
                        Rectangle().fill(selected == 1 ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                                
                            })
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Rectangle().fill(middle_gradient).frame(width: 1)
                        Spacer()
                    }
                }
            )
        }.animation((should_animate == true || instant_multitasking_change == true) ? .default : .none).transition(AnyTransition.asymmetric(insertion: .move(edge:.leading), removal: .move(edge: .leading)))
    }
}

struct dual_segmented_control_big_bluegray: View {
    @Binding var selected: Int //either 0 or 1
    var first_text: String
    var second_text: String
    var should_animate:Bool?
    private let unselected_gradient = LinearGradient([(color: Color(red: 251/255, green: 251/255, blue: 251/255), location: 0), (color: Color(red: 210/255, green: 210/255, blue: 210/255), location: 1)], from: .top, to: .bottom)
    private let selected_gradient = LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 64/255, green: 135/255, blue: 220/255), location: 0.0), .init(color:Color(red: 81/255, green: 151/255, blue: 236/255), location: 0.46), .init(color:Color(red: 103/255, green: 165/255, blue: 245/255), location: 0.56), .init(color:Color(red: 138/255, green: 188/255, blue: 253/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)
    private let middle_gradient = LinearGradient([(color: Color(red: 73/255, green: 85/255, blue: 98/255), location: 0), (color: Color(red: 92/255, green: 118/255, blue: 156/255), location: 0.04), (color: Color(red: 58/255, green: 90/255, blue: 136/255), location: 0.51), (color: Color(red: 51/255, green: 84/255, blue: 131/255), location: 0.51), (color: Color(red: 37/255, green: 72/255, blue: 120/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        GeometryReader{ geometry in
            HStack(spacing: 0) {
                Button(action:{selected = 0}) {
                    Text(first_text).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(selected == 0 ? .white : Color(red: 127/255, green: 127/255, blue: 127/255)).shadow(color: selected == 0 ? Color.black.opacity(0.4) : Color.white.opacity(0.9), radius: 0, x: 0, y: selected == 0 ? -0.66 : 0.99)
                }.frame(width: geometry.size.width/2, height: geometry.size.height).ps_innerShadow(.rectangleCustomCorners_Double(selected == 0 ? selected_gradient: unselected_gradient), radius:3, offset: CGPoint(0, 3), intensity: selected == 0 ? 0.4 : 0).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                Button(action:{selected = 1}) {
                    Text(second_text).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(selected == 1 ? .white : Color(red: 127/255, green: 127/255, blue: 127/255)).shadow(color: selected == 1 ? Color.black.opacity(0.4) : Color.white.opacity(0.9), radius: 0, x: 0, y: selected == 1 ? -0.66 : 0.99)
                }.frame(width: geometry.size.width/2, height: geometry.size.height).ps_innerShadow(.rectangleCustomCornersRight_Double(selected == 1 ? selected_gradient: unselected_gradient), radius:3, offset: CGPoint(0, 3), intensity: selected == 1 ? 0.4 : 0).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
            }.strokeRoundedRectangle(12, Color(red: 172/255, green: 172/255, blue: 172/255), lineWidth: 0.75)
        }.animation(should_animate == true ? .default : .none).transition(AnyTransition.asymmetric(insertion: .move(edge:.leading), removal: .move(edge: .leading)))
    }
}

struct dual_segmented_control_big_bluegray_no_stroke: View {
    @Binding var selected: Int //either 0 or 1
    var first_text: String
    var second_text: String
    var should_animate:Bool?
    private let unselected_gradient = LinearGradient([(color: Color(red: 251/255, green: 251/255, blue: 251/255), location: 0), (color: Color(red: 210/255, green: 210/255, blue: 210/255), location: 1)], from: .top, to: .bottom)
    private let selected_gradient = LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 64/255, green: 135/255, blue: 220/255), location: 0.0), .init(color:Color(red: 81/255, green: 151/255, blue: 236/255), location: 0.46), .init(color:Color(red: 103/255, green: 165/255, blue: 245/255), location: 0.56), .init(color:Color(red: 138/255, green: 188/255, blue: 253/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)
    private let middle_gradient = LinearGradient([(color: Color(red: 73/255, green: 85/255, blue: 98/255), location: 0), (color: Color(red: 92/255, green: 118/255, blue: 156/255), location: 0.04), (color: Color(red: 58/255, green: 90/255, blue: 136/255), location: 0.51), (color: Color(red: 51/255, green: 84/255, blue: 131/255), location: 0.51), (color: Color(red: 37/255, green: 72/255, blue: 120/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        GeometryReader{ geometry in
            HStack(spacing: 0) {
                Button(action:{selected = 0}) {
                    Text(first_text).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(selected == 0 ? .white : Color(red: 127/255, green: 127/255, blue: 127/255)).shadow(color: selected == 0 ? Color.black.opacity(0.4) : Color.white.opacity(0.9), radius: 0, x: 0, y: selected == 0 ? -0.66 : 0.99)
                }.frame(width: geometry.size.width/2, height: geometry.size.height).ps_innerShadow(.rectangleCustomCorners_Double(selected == 0 ? selected_gradient: unselected_gradient), radius:3, offset: CGPoint(0, 3), intensity: selected == 0 ? 0.4 : 0).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                Button(action:{selected = 1}) {
                    Text(second_text).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(selected == 1 ? .white : Color(red: 127/255, green: 127/255, blue: 127/255)).shadow(color: selected == 1 ? Color.black.opacity(0.4) : Color.white.opacity(0.9), radius: 0, x: 0, y: selected == 1 ? -0.66 : 0.99)
                }.frame(width: geometry.size.width/2, height: geometry.size.height).ps_innerShadow(.rectangleCustomCornersRight_Double(selected == 1 ? selected_gradient: unselected_gradient), radius:3, offset: CGPoint(0, 3), intensity: selected == 1 ? 0.4 : 0).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
            }
        }.animation(should_animate == true ? .default : .none).transition(AnyTransition.asymmetric(insertion: .move(edge:.leading), removal: .move(edge: .leading)))
    }
}

struct tri_control_big_bluegray_no_stroke: View {
    @Binding var selected: Int //either 0 or 1
    var first_text: String
    var second_text: String
    var third_text: String
    var should_animate:Bool?
    private let unselected_gradient = LinearGradient([(color: Color(red: 251/255, green: 251/255, blue: 251/255), location: 0), (color: Color(red: 210/255, green: 210/255, blue: 210/255), location: 1)], from: .top, to: .bottom)
    private let selected_gradient = LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 64/255, green: 135/255, blue: 220/255), location: 0.0), .init(color:Color(red: 81/255, green: 151/255, blue: 236/255), location: 0.46), .init(color:Color(red: 103/255, green: 165/255, blue: 245/255), location: 0.56), .init(color:Color(red: 138/255, green: 188/255, blue: 253/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)
    private let middle_gradient = LinearGradient([(color: Color(red: 73/255, green: 85/255, blue: 98/255), location: 0), (color: Color(red: 92/255, green: 118/255, blue: 156/255), location: 0.04), (color: Color(red: 58/255, green: 90/255, blue: 136/255), location: 0.51), (color: Color(red: 51/255, green: 84/255, blue: 131/255), location: 0.51), (color: Color(red: 37/255, green: 72/255, blue: 120/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        GeometryReader{ geometry in
            HStack(spacing: 0) {
                Button(action:{selected = 0}) {
                    Text(first_text).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(selected == 0 ? .white : Color(red: 127/255, green: 127/255, blue: 127/255)).shadow(color: selected == 0 ? Color.black.opacity(0.4) : Color.white.opacity(0.9), radius: 0, x: 0, y: selected == 0 ? -0.66 : 0.99)
                }.frame(width: geometry.size.width/3, height: geometry.size.height).ps_innerShadow(.rectangleCustomCorners_Double(selected == 0 ? selected_gradient: unselected_gradient), radius:3, offset: CGPoint(0, 3), intensity: selected == 0 ? 0.4 : 0).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                Button(action:{selected = 1}) {
                    Text(second_text).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(selected == 1 ? .white : Color(red: 127/255, green: 127/255, blue: 127/255)).shadow(color: selected == 1 ? Color.black.opacity(0.4) : Color.white.opacity(0.9), radius: 0, x: 0, y: selected == 1 ? -0.66 : 0.99)
                }.frame(width: geometry.size.width/3, height: geometry.size.height).ps_innerShadow(.rectangle(selected == 1 ? selected_gradient: unselected_gradient), radius:3, offset: CGPoint(0, 3), intensity: selected == 1 ? 0.4 : 0).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8).if(selected == 0 || selected == 2) {
                    $0.overlay(HStack(spacing: 0) {
                        if selected == 0 {
                        Spacer()
                        }
                        Rectangle().fill(Color(red: 186/255, green: 186/255, blue: 186/255)).frame(width: 1, height: geometry.size.height)
                        if selected == 2 {
                        Spacer()
                        }
                    })
                }
                Button(action:{selected = 2}) {
                    Text(third_text).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(selected == 2 ? .white : Color(red: 127/255, green: 127/255, blue: 127/255)).shadow(color: selected == 2 ? Color.black.opacity(0.4) : Color.white.opacity(0.9), radius: 0, x: 0, y: selected == 2 ? -0.66 : 0.99)
                }.frame(width: geometry.size.width/3, height: geometry.size.height).ps_innerShadow(.rectangleCustomCornersRight_Double(selected == 2 ? selected_gradient: unselected_gradient), radius:3, offset: CGPoint(0, 3), intensity: selected == 2 ? 0.4 : 0).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
            }
        }.animation(should_animate == true ? .default : .none).transition(AnyTransition.asymmetric(insertion: .move(edge:.leading), removal: .move(edge: .leading)))
    }
}

struct tri_segmented_control: View {
    @Binding var selected: Int //either 0 or 1
    @Binding var instant_multitasking_change: Bool
    var first_text: String
    var second_text: String
    var third_text: String
    var should_animate:Bool?
    private let unselected_gradient = LinearGradient([(color: Color(red: 158/255, green: 173/255, blue: 191/255), location: 0), (color: Color(red: 137/255, green: 155/255, blue: 178/255), location: 0.51), (color: Color(red: 127/255, green: 148/255, blue: 176/255), location: 0.51), (color: Color(red: 126/255, green: 148/255, blue: 178/255), location: 1)], from: .top, to: .bottom)
    private let selected_gradient = LinearGradient([(color: Color(red: 136/255, green: 160/255, blue: 190/255), location: 0), (color: Color(red: 88/255, green: 119/255, blue: 162/255), location: 0.51), (color: Color(red: 71/255, green: 105/255, blue: 153/255), location: 0.51), (color: Color(red: 74/255, green: 108/255, blue: 154/255), location: 1)], from: .top, to: .bottom)
    private let middle_gradient = LinearGradient([(color: Color(red: 73/255, green: 85/255, blue: 98/255), location: 0), (color: Color(red: 92/255, green: 118/255, blue: 156/255), location: 0.04), (color: Color(red: 58/255, green: 90/255, blue: 136/255), location: 0.51), (color: Color(red: 51/255, green: 84/255, blue: 131/255), location: 0.51), (color: Color(red: 37/255, green: 72/255, blue: 120/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        GeometryReader{ geometry in
            HStack(spacing: 0) {
                Button(action:{selected = 0}) {
                    Text(first_text).font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0, y: -0.66)
                }.frame(width: geometry.size.width/3, height: geometry.size.height).ps_innerShadow(.rectangleCustomCorners(selected == 0 ? selected_gradient: unselected_gradient), radius:0.82, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                Button(action:{selected = 1}) {
                    Text(second_text).font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0, y: -0.66)
                }.frame(width: geometry.size.width/3, height: geometry.size.height).ps_innerShadow(.rectangle(selected == 1 ? selected_gradient: unselected_gradient), radius:0.82, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                Button(action:{selected = 2}) {
                    Text(third_text).font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0, y: -0.66)
                }.frame(width: geometry.size.width/3, height: geometry.size.height).ps_innerShadow(.rectangleCustomCornersRight(selected == 2 ? selected_gradient: unselected_gradient), radius:0.82, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
            }.overlay(
                ZStack {
                    HStack(spacing:0) {
                        Spacer().frame(width: geometry.size.width/3-2)
                        Rectangle().fill(selected == 0 ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                            })
                        Rectangle().fill((selected == 1) ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                                
                            })
                        Spacer().frame(width: geometry.size.width*2/3-2)
                    }
                    HStack(spacing:0) {
                        Spacer().frame(width: geometry.size.width*2/3-2)
                        Rectangle().fill(selected == 1 ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                            })
                        Rectangle().fill((selected == 2) ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                                
                            })
                        Spacer().frame(width: geometry.size.width/3-2)
                    }
                    HStack {
                        Spacer().frame(width: geometry.size.width/3-0.5)
                        Rectangle().fill(middle_gradient).frame(width: 1)
                        Spacer().frame(width: geometry.size.width*2/3-0.5)
                    }
                    HStack {
                        Spacer().frame(width: geometry.size.width*2/3-0.5)
                        Rectangle().fill(middle_gradient).frame(width: 1)
                        Spacer().frame(width: geometry.size.width/3-0.5)
                    }
                }
            )
        }.animation((should_animate == true || instant_multitasking_change == true) ? .default : .none).transition(AnyTransition.asymmetric(insertion: .move(edge:.leading), removal: .move(edge: .leading)))
    }
}

struct tri_segmented_control_youtube: View {
    @Binding var selected: Int //either 0 or 1
    @Binding var instant_multitasking_change: Bool
    var first_text: String
    var second_text: String
    var third_text: String
    var should_animate:Bool?
    private let unselected_gradient = LinearGradient([(color: Color(red: 158/255, green: 173/255, blue: 191/255), location: 0), (color: Color(red: 137/255, green: 155/255, blue: 178/255), location: 0.51), (color: Color(red: 127/255, green: 148/255, blue: 176/255), location: 0.51), (color: Color(red: 126/255, green: 148/255, blue: 178/255), location: 1)], from: .top, to: .bottom)
    private let selected_gradient = LinearGradient([(color: Color(red: 136/255, green: 160/255, blue: 190/255), location: 0), (color: Color(red: 88/255, green: 119/255, blue: 162/255), location: 0.51), (color: Color(red: 71/255, green: 105/255, blue: 153/255), location: 0.51), (color: Color(red: 74/255, green: 108/255, blue: 154/255), location: 1)], from: .top, to: .bottom)
    private let middle_gradient = LinearGradient([(color: Color(red: 73/255, green: 85/255, blue: 98/255), location: 0), (color: Color(red: 92/255, green: 118/255, blue: 156/255), location: 0.04), (color: Color(red: 58/255, green: 90/255, blue: 136/255), location: 0.51), (color: Color(red: 51/255, green: 84/255, blue: 131/255), location: 0.51), (color: Color(red: 37/255, green: 72/255, blue: 120/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        GeometryReader{ geometry in
            HStack(spacing: 0) {
                Button(action:{selected = 0}) {
                    Text(first_text).font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0, y: -0.66)
                }.frame(width: geometry.size.width/3, height: geometry.size.height).ps_innerShadow(.rectangleCustomCorners(selected == 0 ? selected_gradient: unselected_gradient), radius:0.82, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                Button(action:{selected = 1}) {
                    Text(second_text).font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0, y: -0.66)
                }.frame(width: geometry.size.width/3, height: geometry.size.height).ps_innerShadow(.rectangle(selected == 1 ? selected_gradient: unselected_gradient), radius:0.82, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                Button(action:{selected = 2}) {
                    Text(third_text).font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0, y: -0.66)
                }.frame(width: geometry.size.width/3, height: geometry.size.height).ps_innerShadow(.rectangleCustomCornersRight(selected == 2 ? selected_gradient: unselected_gradient), radius:0.82, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
            }.overlay(
                ZStack {
                    HStack(spacing:0) {
                        Spacer().frame(width: geometry.size.width/3-2)
                        Rectangle().fill(selected == 0 ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                            })
                        Rectangle().fill((selected == 1) ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                                
                            })
                        Spacer().frame(width: geometry.size.width*2/3-2)
                    }
                    HStack(spacing:0) {
                        Spacer().frame(width: geometry.size.width*2/3-2)
                        Rectangle().fill(selected == 1 ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                            })
                        Rectangle().fill((selected == 2) ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                                
                            })
                        Spacer().frame(width: geometry.size.width/3-2)
                    }
                    HStack {
                        Spacer().frame(width: geometry.size.width/3-0.5)
                        Rectangle().fill(middle_gradient).frame(width: 1)
                        Spacer().frame(width: geometry.size.width*2/3-0.5)
                    }
                    HStack {
                        Spacer().frame(width: geometry.size.width*2/3-0.5)
                        Rectangle().fill(middle_gradient).frame(width: 1)
                        Spacer().frame(width: geometry.size.width/3-0.5)
                    }
                }
            )
        }.animation((should_animate == true || instant_multitasking_change == true) ? .linear(duration: 0.4) : .none)
    }
}


struct tri_segmented_control_image: View {
    @Binding var selected: Int //either 0 or 1
    @Binding var instant_multitasking_change: Bool
    var first_image: String
    var second_image: String
    var third_image: String
    var should_animate:Bool?
    private let unselected_gradient = LinearGradient([(color: Color(red: 158/255, green: 173/255, blue: 191/255), location: 0), (color: Color(red: 137/255, green: 155/255, blue: 178/255), location: 0.51), (color: Color(red: 127/255, green: 148/255, blue: 176/255), location: 0.51), (color: Color(red: 126/255, green: 148/255, blue: 178/255), location: 1)], from: .top, to: .bottom)
    private let selected_gradient = LinearGradient([(color: Color(red: 136/255, green: 160/255, blue: 190/255), location: 0), (color: Color(red: 88/255, green: 119/255, blue: 162/255), location: 0.51), (color: Color(red: 71/255, green: 105/255, blue: 153/255), location: 0.51), (color: Color(red: 74/255, green: 108/255, blue: 154/255), location: 1)], from: .top, to: .bottom)
    private let middle_gradient = LinearGradient([(color: Color(red: 73/255, green: 85/255, blue: 98/255), location: 0), (color: Color(red: 92/255, green: 118/255, blue: 156/255), location: 0.04), (color: Color(red: 58/255, green: 90/255, blue: 136/255), location: 0.51), (color: Color(red: 51/255, green: 84/255, blue: 131/255), location: 0.51), (color: Color(red: 37/255, green: 72/255, blue: 120/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        GeometryReader{ geometry in
            HStack(spacing: 0) {
                Button(action:{selected = 0}) {
                    Image(first_image)
                }.frame(width: geometry.size.width/3, height: geometry.size.height).ps_innerShadow(.rectangleCustomCorners(selected == 0 ? selected_gradient: unselected_gradient), radius:0.82, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                Button(action:{selected = 1}) {
                    Image(second_image)
                }.frame(width: geometry.size.width/3, height: geometry.size.height).ps_innerShadow(.rectangle(selected == 1 ? selected_gradient: unselected_gradient), radius:0.82, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                Button(action:{selected = 2}) {
                    Image(third_image)
                }.frame(width: geometry.size.width/3, height: geometry.size.height).ps_innerShadow(.rectangleCustomCornersRight(selected == 2 ? selected_gradient: unselected_gradient), radius:0.82, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
            }.overlay(
                ZStack {
                    HStack(spacing:0) {
                        Spacer().frame(width: geometry.size.width/3-2)
                        Rectangle().fill(selected == 0 ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                            })
                        Rectangle().fill((selected == 1) ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                                
                            })
                        Spacer().frame(width: geometry.size.width*2/3-2)
                    }
                    HStack(spacing:0) {
                        Spacer().frame(width: geometry.size.width*2/3-2)
                        Rectangle().fill(selected == 1 ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                            })
                        Rectangle().fill((selected == 2) ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                                
                            })
                        Spacer().frame(width: geometry.size.width/3-2)
                    }
                    HStack {
                        Spacer().frame(width: geometry.size.width/3-0.5)
                        Rectangle().fill(middle_gradient).frame(width: 1)
                        Spacer().frame(width: geometry.size.width*2/3-0.5)
                    }
                    HStack {
                        Spacer().frame(width: geometry.size.width*2/3-0.5)
                        Rectangle().fill(middle_gradient).frame(width: 1)
                        Spacer().frame(width: geometry.size.width/3-0.5)
                    }
                }
            )
        }.animation((should_animate == true || instant_multitasking_change == true) ? .default : .none).transition(AnyTransition.asymmetric(insertion: .move(edge:.leading), removal: .move(edge: .leading)))
    }
}

struct tri_segmented_control_gray: View {
    @Binding var selected: Int //either 0 or 1
    var first_text: String
    var second_text: String
    var third_text: String
    var should_animate:Bool?
    private let unselected_gradient = LinearGradient([(color: Color(red: 213/255, green: 220/255, blue: 224/255), location: 0), (color: Color(red: 192/255, green: 201/255, blue: 207/255), location: 0.53), (color: Color(red: 178/255, green: 188/255, blue: 196/255), location: 1)], from: .top, to: .bottom)
    private let selected_gradient = LinearGradient([(color: Color(red: 140/255, green: 154/255, blue: 175/255), location: 0), (color: Color(red: 101/255, green: 120/255, blue: 146/255), location: 1)], from: .top, to: .bottom)
    private let middle_gradient = Color(red: 109/255, green: 126/255, blue: 145/255)
    var body: some View {
        GeometryReader{ geometry in
            HStack(spacing: 0) {
                Button(action:{selected = 0}) {
                    Text(first_text).font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(selected == 0 ? Color.white : Color(red: 74/255, green: 102/255, blue: 139/255)).shadow(color: selected == 0 ? Color(red:44/255, green: 45/255, blue:46/255).opacity(0.47) : Color.white.opacity(0.47), radius: 0, x: 0, y: selected == 0 ? -0.66 : 0.66)
                }.frame(width: geometry.size.width/3, height: geometry.size.height).ps_innerShadow(.rectangleCustomCorners(selected == 0 ? selected_gradient: unselected_gradient), radius:0.82, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                Button(action:{selected = 1}) {
                    Text(second_text).font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(selected == 1 ? Color.white : Color(red: 74/255, green: 102/255, blue: 139/255)).shadow(color: selected == 1 ? Color(red:44/255, green: 45/255, blue:46/255).opacity(0.47) : Color.white.opacity(0.47), radius: 0, x: 0, y: selected == 1 ? -0.66 : 0.66)
                }.frame(width: geometry.size.width/3, height: geometry.size.height).ps_innerShadow(.rectangle(selected == 1 ? selected_gradient: unselected_gradient), radius:0.82, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                Button(action:{selected = 2}) {
                    Text(third_text).font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(selected == 2 ? Color.white : Color(red: 74/255, green: 102/255, blue: 139/255)).shadow(color: selected == 2 ? Color(red:44/255, green: 45/255, blue:46/255).opacity(0.47) : Color.white.opacity(0.47), radius: 0, x: 0, y: selected == 2 ? -0.66 : 0.66)
                }.frame(width: geometry.size.width/3, height: geometry.size.height).ps_innerShadow(.rectangleCustomCornersRight(selected == 2 ? selected_gradient: unselected_gradient), radius:0.82, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
            }.overlay(
                ZStack {
                    HStack(spacing:0) {
                        Spacer().frame(width: geometry.size.width/3-2)
                        Rectangle().fill(selected == 0 ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                            })
                        Rectangle().fill((selected == 1) ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                                
                            })
                        Spacer().frame(width: geometry.size.width*2/3-2)
                    }
                    HStack(spacing:0) {
                        Spacer().frame(width: geometry.size.width*2/3-2)
                        Rectangle().fill(selected == 1 ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                            })
                        Rectangle().fill((selected == 2) ? selected_gradient: unselected_gradient).frame(width: 2).mask(
                            VStack(spacing:0) {
                                Rectangle().fill(LinearGradient([.clear, .white], from: .top, to: .bottom)).frame(height:4.5)
                                Rectangle()
                                Rectangle().fill(LinearGradient([.white, .clear], from: .top, to: .bottom)).frame(height: 1.5)
                                
                            })
                        Spacer().frame(width: geometry.size.width/3-2)
                    }
                    HStack {
                        Spacer().frame(width: geometry.size.width/3-0.5)
                        Rectangle().fill(middle_gradient).frame(width: 1)
                        Spacer().frame(width: geometry.size.width*2/3-0.5)
                    }
                    HStack {
                        Spacer().frame(width: geometry.size.width*2/3-0.5)
                        Rectangle().fill(middle_gradient).frame(width: 1)
                        Spacer().frame(width: geometry.size.width/3-0.5)
                    }
                }
            )
        }
    }
}


//Thank you to https://medium.com/macoclock/how-to-remove-line-separator-below-list-using-swiftui-466025c1b8b1 for this
struct NoSepratorList<Content>: View where Content: View {

    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
        
    }
        
    var body: some View {
        if #available(iOS 14.0, *) {
           ScrollView {
               LazyVStack(spacing: 0) {
                self.content().transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
             }
           }
        } else {
            List {
                self.content()
            }
            .onAppear {
               UITableView.appearance().separatorStyle = .none
            }.onDisappear {
               UITableView.appearance().separatorStyle = .singleLine
            }
        }
    }
}

//Thank you to https://medium.com/macoclock/how-to-remove-line-separator-below-list-using-swiftui-466025c1b8b1 for this
struct NoSepratorList_NonLazy<Content>: View where Content: View {

    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
        
    }
        
    var body: some View {
        if #available(iOS 14.0, *) {
           ScrollView {
               VStack(spacing: 0) {
                self.content().transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
             }
           }
        } else {
            List {
                self.content()
            }
            .onAppear {
               UITableView.appearance().separatorStyle = .none
            }.onDisappear {
               UITableView.appearance().separatorStyle = .singleLine
            }
        }
    }
}

extension View {
    public func gradientForegroundNonDynamic(colors: [Color]) -> some View {
        self.overlay(LinearGradient(gradient: .init(colors: colors),
                                    startPoint: .top,
                                    endPoint: .bottom))
            .mask(self)
    }
    
}
extension View {
    func innerShadow2(color: Color, radius: CGFloat) -> some View {
        modifier(InnerShadow2(color: color, radius: min(max(0, radius), 1)))
    }
}

private struct InnerShadow2: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1
    
    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .top, endPoint: .bottom)
                            .frame(height: self.radius * self.minSide(geo)),
                         alignment: .top)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .bottom, endPoint: .top)
                            .frame(height: self.radius * self.minSide(geo)),
                         alignment: .bottom)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .leading, endPoint: .trailing)
                            .frame(width: self.radius * self.minSide(geo)),
                         alignment: .leading)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .trailing, endPoint: .leading)
                            .frame(width: self.radius * self.minSide(geo)),
                         alignment: .trailing)
        }
    }
    
    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}
struct CornerRadiusStyle: ViewModifier {
    var radius: CGFloat
    var corners: UIRectCorner
    
    struct CornerRadiusShape: Shape {
        
        var radius = CGFloat.infinity
        var corners = UIRectCorner.allCorners
        
        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            return Path(path.cgPath)
        }
    }
    
    func body(content: Content) -> some View {
        content
            .clipShape(CornerRadiusShape(radius: radius, corners: corners))
    }
}

extension View {
    func cornerRadiusSpecific(radius: CGFloat, corners: UIRectCorner) -> some View {
        ModifiedContent(content: self, modifier: CornerRadiusStyle(radius: radius, corners: corners))
    }
}
extension View {
    func draggable_toggle(offset: Binding<CGPoint>, on: Binding<Bool>, show_overlay: Binding<Bool>) -> some View {
        return modifier(DraggableToggle(offset: offset, on: on, show_overlay: show_overlay))
  }
}
struct DraggableToggle: ViewModifier {
    @Binding var offset: CGPoint
    @Binding var on: Bool
    @Binding var show_overlay: Bool
   // var width: CGFloat
  func body(content: Content) -> some View {
    content
      .simultaneousGesture(DragGesture(minimumDistance: 0)
        .onChanged { value in
        if self.offset.x >= -53.6666666667 && self.offset.x <= 0 {
          self.offset.x += value.location.x - value.startLocation.x
            if self.offset.x < -53.6666666667 {
                self.offset.x = -53.6666666667
            }
            if self.offset.x > 0 {
                self.offset.x = 0
            }
        }
            show_overlay = true
            print(offset.x, "moving")
        }.onEnded { value in
            show_overlay = false
            if self.offset.x > -53.6666666667/2 {
                on = true
                withAnimation(.linear(duration: 0.1)) {
                    self.offset.x = 0
                }
            } else {
                on = false
                withAnimation(.linear(duration: 0.1)) {
                    self.offset.x = -53.6666666667
                }
            }
        })
        .offset(x: offset.x, y: 0)
  }
}

struct vertical_bar_background : View {
    var horizontalSpacing: CGFloat = 12
    var body : some View {
        VStack(alignment: .center) {
            GeometryReader { geometry in
                Path { path in
                    
                    let numberOfVerticalGridLines = Int((geometry.size.width) / self.horizontalSpacing)
                    for index in 0...numberOfVerticalGridLines {
                        let vOffset: CGFloat = CGFloat(index) * self.horizontalSpacing
                        path.move(to: CGPoint(x: vOffset, y: 0))
                        path.addLine(to: CGPoint(x: vOffset, y: geometry.size.height))
                    }
                    
                }
                .stroke(Color.init(red: 203/255, green: 210/255, blue: 216/255), lineWidth: 3)
            }
        }
    }
}

struct CustomSliderComponents {
    let barLeft: CustomSliderModifier
    let barRight: CustomSliderModifier
    let knob: CustomSliderModifier
}
struct CustomSliderModifier: ViewModifier {
    enum Name {
        case barLeft
        case barRight
        case knob
    }
    let name: Name
    let size: CGSize
    let offset: CGFloat

    func body(content: Content) -> some View {
        content
        .frame(width: size.width)
        .position(x: size.width*0.5, y: size.height*0.5)
        .offset(x: offset)
    }
}

struct CustomSlider<Component: View>: View {
    @Binding var value: Double
    @Binding var should_update_from_timer: Bool?
    @Binding var duration: Double?
    var type: String
    var range: (Double, Double)
    var knobWidth: CGFloat?
    let viewBuilder: (CustomSliderComponents) -> Component

    init(type: String, should_update_from_timer: Binding<Bool?> = .constant(true), duration: Binding<Double?> = .constant(0), value: Binding<Double>, range: (Double, Double), knobWidth: CGFloat? = nil,
         _ viewBuilder: @escaping (CustomSliderComponents) -> Component
    ) {
        self.type = type
        _should_update_from_timer = should_update_from_timer
        _duration = duration
        _value = value
        self.range = range
        self.viewBuilder = viewBuilder
        self.knobWidth = knobWidth
    }

    var body: some View {
      return GeometryReader { geometry in
        self.view(geometry: geometry) // function below
      }
    }


    private func view(geometry: GeometryProxy) -> some View {
        var frame = geometry.localFrame
        if type == "Song" {
           frame = geometry.frame(in: .local)
        } else {
     frame = geometry.frame(in: .global)
        }
      let drag = DragGesture(minimumDistance: 0).onChanged({ drag in
        self.onSliderDragChange(drag, frame) }
      ).onEnded({ _ in
        if type == "Song" {
           should_update_from_timer = true
       } //Maybe unnecesary now
      })
      let offsetX = self.getOffsetX(frame: frame)
    
      let knobSize = CGSize(width: knobWidth ?? frame.height, height: frame.height)
      let barLeftSize = CGSize(width: CGFloat(offsetX + knobSize.width * 0.5), height:  frame.height)
      let barRightSize = CGSize(width: frame.width - barLeftSize.width, height: frame.height)

      let modifiers = CustomSliderComponents(
          barLeft: CustomSliderModifier(name: .barLeft, size: barLeftSize, offset: 0),
          barRight: CustomSliderModifier(name: .barRight, size: barRightSize, offset: barLeftSize.width),
          knob: CustomSliderModifier(name: .knob, size: knobSize, offset: offsetX))
      return ZStack { viewBuilder(modifiers).gesture(drag) }
    }
    private func onSliderDragChange(_ drag: DragGesture.Value,_ frame: CGRect) {
        let width = (knob: Double(knobWidth ?? frame.size.height), view: Double(frame.size.width))
        let xrange = (min: Double(0), max: Double(width.view - width.knob))
        var value = Double(drag.startLocation.x + drag.translation.width) // knob center x
        value -= 0.5*width.knob // offset from center to leading edge of knob
        value = value > xrange.max ? xrange.max : value // limit to leading edge
        value = value < xrange.min ? xrange.min : value // limit to trailing edge
        value = value.convert(fromRange: (xrange.min, xrange.max), toRange: range)
        self.value = value
        if type == "Brightness" {
            UIScreen.main.brightness = CGFloat(value/100)
        }
        if type == "Volume" {
        MPVolumeView.setVolume(Float(value/100))
        }
        if type == "Song" {
            should_update_from_timer = false
            let translation = drag.translation.x
//            for n in 0...50 { //a for loop is a descent solution, maybe switch to more efficient if statements. Maybe we use this, idk yet.
//            if Int(abs(drag.translation.x)) == Int(frame.size.width/50)*n {
                let music_player = MPMusicPlayerController.systemMusicPlayer
                DispatchQueue.global(qos: .background).async { //Updadting on main thread will freeze animation
                music_player.currentPlaybackTime = value/100*(duration ?? 0)
//                }
//            }
            }
        }
    }
    private func getOffsetX(frame: CGRect) -> CGFloat {
        let width = (knob: knobWidth ?? frame.size.height, view: frame.size.width)
        let xrange: (Double, Double) = (0, Double(width.view - width.knob))
        let result = self.value.convert(fromRange: range, toRange: xrange)
        return CGFloat(result)
    }
}

struct CustomSliderVideo<Component: View>: View {
    @Binding var value: Double
    @Binding var should_update_from_timer: Bool?
    @Binding var duration: Double?
    @Binding var player: AVPlayer
    var type: String
    var range: (Double, Double)
    var knobWidth: CGFloat?
    let viewBuilder: (CustomSliderComponents) -> Component

    init(player: Binding<AVPlayer>, type: String, should_update_from_timer: Binding<Bool?> = .constant(true), duration: Binding<Double?> = .constant(0), value: Binding<Double>, range: (Double, Double), knobWidth: CGFloat? = nil,
         _ viewBuilder: @escaping (CustomSliderComponents) -> Component
    ) {
        self.type = type
        _should_update_from_timer = should_update_from_timer
        _duration = duration
        _value = value
        _player = player
        self.range = range
        self.viewBuilder = viewBuilder
        self.knobWidth = knobWidth
    }

    var body: some View {
      return GeometryReader { geometry in
        self.view(geometry: geometry) // function below
      }
    }


    private func view(geometry: GeometryProxy) -> some View {
        var frame = geometry.localFrame
           frame = geometry.frame(in: .local)
            let drag = DragGesture(minimumDistance: 0).onChanged({ drag in
        self.onSliderDragChange(drag, frame) }
      ).onEnded({ _ in
//        if type == "Song" {
//           should_update_from_timer = true
//       } //Maybe unnecesary now
      })
      let offsetX = self.getOffsetX(frame: frame)
    
      let knobSize = CGSize(width: knobWidth ?? frame.height, height: frame.height)
      let barLeftSize = CGSize(width: CGFloat(offsetX + knobSize.width * 0.5), height:  frame.height)
      let barRightSize = CGSize(width: frame.width - barLeftSize.width, height: frame.height)

      let modifiers = CustomSliderComponents(
          barLeft: CustomSliderModifier(name: .barLeft, size: barLeftSize, offset: 0),
          barRight: CustomSliderModifier(name: .barRight, size: barRightSize, offset: barLeftSize.width),
          knob: CustomSliderModifier(name: .knob, size: knobSize, offset: offsetX))
      return ZStack { viewBuilder(modifiers).gesture(drag) }
    }
    private func onSliderDragChange(_ drag: DragGesture.Value,_ frame: CGRect) {
        let width = (knob: Double(knobWidth ?? frame.size.height), view: Double(frame.size.width))
        let xrange = (min: Double(0), max: Double(width.view - width.knob))
        var value = Double(drag.startLocation.x + drag.translation.width) // knob center x
        value -= 0.5*width.knob // offset from center to leading edge of knob
        value = value > xrange.max ? xrange.max : value // limit to leading edge
        value = value < xrange.min ? xrange.min : value // limit to trailing edge
        value = value.convert(fromRange: (xrange.min, xrange.max), toRange: range)
        self.value = value
        if type == "Volume" {
        MPVolumeView.setVolume(Float(value/100))
        }
        if type == "Video" {
            guard let item = self.player.currentItem else {
              return
            }
     
            let targetTime = self.value * item.duration.seconds
            player.seek(to: CMTime(seconds: targetTime, preferredTimescale: 600))
        }
//        if type == "Song" {
//            should_update_from_timer = false
//            let translation = drag.translation.x
////            for n in 0...50 { //a for loop is a descent solution, maybe switch to more efficient if statements. Maybe we use this, idk yet.
////            if Int(abs(drag.translation.x)) == Int(frame.size.width/50)*n {
//                let music_player = MPMusicPlayerController.systemMusicPlayer
//                DispatchQueue.global(qos: .background).async { //Updadting on main thread will freeze animation
//                music_player.currentPlaybackTime = value/100*(duration ?? 0)
////                }
////            }
//            }
//        }
    }
    private func getOffsetX(frame: CGRect) -> CGFloat {
        let width = (knob: knobWidth ?? frame.size.height, view: frame.size.width)
        let xrange: (Double, Double) = (0, Double(width.view - width.knob))
        let result = self.value.convert(fromRange: range, toRange: xrange)
        return CGFloat(result)
    }
}

struct skeumorphic_alert: View {
    var title: String?
    var subtitle: String?
    var notification: String?
    public var dismiss_action: (() -> Void)?
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                VStack {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(Color(red: 11/255, green: 27/255, blue: 68/255)).opacity(0.85).strokeRoundedRectangle(12, LinearGradient([(color: Color(red: 226/255, green: 227/255, blue: 228/255), location:0), (color: Color(red: 178/255, green: 183/255, blue: 194/255), location:0.19)], from: .top, to: .bottom), lineWidth: 2).shadow(color: Color.black.opacity(0.75), radius: 3, x: 0, y: 2)
                        VStack {
                            top_gloss(length: geometry.size.width-60).fill(LinearGradient([(color: Color.white, location: 0.2), (color: Color(red: 80/255, green: 84/255, blue: 89/255), location: 1)], from: .top, to: .bottom)).frame(height:45).cornerRadiusSpecific(radius: 12, corners: [.topLeft, .topRight]).opacity(0.30)
                            Spacer()
                        }
                        VStack(alignment:.center) {
                            Text(title ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.white).shadow(color: Color.black.opacity(0.80), radius: 0, x: 0.0, y: -1.2).padding(.top, 15)
                            Spacer()
                            Text(subtitle ?? "").font(.custom("Helvetica Neue Regular", fixedSize: 14.5)).foregroundColor(.white).shadow(color: Color.black.opacity(0.80), radius: 0, x: 0.0, y: -1.2).multilineTextAlignment(.center).padding([.leading, .trailing], 10).padding(.bottom, 5)
                            Spacer()
                            Button(action:{dismiss_action?()}) {
                            ZStack {
                            RoundedRectangle(cornerRadius: 6).fill(LinearGradient([(color:Color(red: 214/255, green: 214/255, blue: 214/255), location: 0), (color:Color(red: 113/255, green: 115/255, blue: 119/255), location: 0.49), (color:Color(red: 74/255, green: 75/255, blue: 78/255), location: 0.50), (color:Color(red: 102/255, green: 103/255, blue: 106/255), location: 1)], from: .top, to: .bottom)).shadow(color: Color.white.opacity(0.2), radius: 0, x: 0, y: 0.5).opacity(0.80).blendMode(.screen).strokeRoundedRectangle(6, Color(red: 19/255, green: 30/255, blue: 58/255), lineWidth: 1).frame(height:40).padding(.bottom, 8).padding([.leading, .trailing], 8)
                                Text("OK").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.white).shadow(color: Color.black.opacity(0.80), radius: 0, x: 0.0, y: -1.2).padding(.bottom, 8)
                            }
                            }
                             
                        }
                    }.frame(maxHeight: 200).fixedSize(horizontal: false, vertical: true).padding([.leading, .trailing], 30)
                    Spacer()
                }
            }
        }.clipped()
    }
}

struct top_gloss: Shape {

    var height: CGFloat = 80
    var length: CGFloat
    var startX: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midPoint: CGFloat = (startX + length) / 2
        let apex1: CGFloat = (startX + midPoint) / 2
        let apex2: CGFloat = (midPoint + length) / 2

        path.move(to:CGPoint(midPoint, 0))

        path.addLine(to: CGPoint(0, 0))
        path.addLine(to: CGPoint(0, 20))
        path.addQuadCurve(to: CGPoint(length,20), control: CGPoint(midPoint,40))
        path.addLine(to: CGPoint(length, 0))
        return path
    }
}

struct tool_bar_button: View {
    var image: String?
    public var action: (() -> Void)?
    var body: some View {
        HStack {
            Spacer()
            Button(action:{action?()}) {
                Image(image ?? "")
            }
            Spacer()
        }
    }
}

enum tool_bar_button_type {
    case gray, blue_gray, blue, black, red, app_store, itunes_store
}

func returnLinearGradient(_ color: tool_bar_button_type) -> LinearGradient {
    switch color {
    case .gray:
        return LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    case .blue_gray:
        return LinearGradient([(color: Color(red: 142/255, green: 166/255, blue:196/255), location: 0), (color: Color(red: 88/255, green: 119/255, blue:166/255), location: 0.50), (color: Color(red: 71/255, green: 105/255, blue:153/255), location: 0.533), (color: Color(red: 74/255, green: 108/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    case .blue:
        return LinearGradient([(color: Color(red: 137/255, green: 173/255, blue:238/255), location: 0), (color: Color(red: 80/255, green: 140/255, blue:231/255), location: 0.51), (color: Color(red: 43/255, green: 120/255, blue:228/255), location: 0.52), (color: Color(red: 46/255, green: 123/255, blue:229/255), location: 1)], from: .top, to: .bottom)
    case .black:
       return LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 95/255, green: 95/255, blue: 95/255), location: 0.0), .init(color: Color(red: 32/255, green: 32/255, blue: 32/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom)
    case .red:
        return LinearGradient([(color: Color(red: 239/255, green: 135/255, blue:142/255), location: 0), (color: Color(red: 199/255, green: 52/255, blue:63/255), location: 0.48), (color: Color(red: 189/255, green: 20/255, blue:33/255), location: 0.49), (color: Color(red: 189/255, green: 20/255, blue:33/255), location: 1)], from: .top, to: .bottom)
    case .app_store:
        return LinearGradient([(color: Color(red: 99/255, green: 115/255, blue:152/255), location: 0), (color: Color(red: 58/255, green: 85/255, blue:151/255), location: 1)], from: .top, to: .bottom)
    case .itunes_store:
        return LinearGradient([(color: Color(red: 162/255, green: 169/255, blue:183/255), location: 0), (color: Color(red: 124/255, green: 136/255, blue:161/255), location: 1)], from: .top, to: .bottom)
        
    }
}


struct tool_bar_rectangle_button: View {
    public var action: (() -> Void)?
    var button_type: tool_bar_button_type
    var content: String
    var use_image: Bool?
    var height_modifier: CGFloat? = 0
    private let gray_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    private let blue_gradient = LinearGradient([(color: Color(red: 120/255, green: 158/255, blue:237/255), location: 0), (color: Color(red: 55/255, green: 110/255, blue:224/255), location: 0.51), (color: Color(red: 34/255, green: 96/255, blue:221/255), location: 0.52), (color: Color(red: 36/255, green: 100/255, blue:224/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        Button(action:{action?()}) {
            ZStack {
                if use_image == true {
                    Image(content).resizable().scaledToFit().frame(width: 13).padding([.leading, .trailing], 11)
                } else {
                Text(content).font(.custom("Helvetica Neue Bold", fixedSize: 13.25)).foregroundColor(.white).shadow(color: Color.black.opacity(0.75), radius: 1, x: 0, y: -0.25).lineLimit(0).padding([.leading, .trailing], 11)
                }
            }.frame(height: 32 + (height_modifier ?? 0)).ps_innerShadow(.roundedRectangle(5.5, returnLinearGradient(button_type)), radius:0.8, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
        }.frame(height: 32 + (height_modifier ?? 0))
    }
}

struct tool_bar_rectangle_button_image_done_size: View { //Is this a bad solution? I mean yeah. But does it work? Yeah.
    public var action: (() -> Void)?
    var button_type: tool_bar_button_type
    var content: String
    var use_image: Bool?
    var height_modifier: CGFloat? = 0
    private let gray_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    private let blue_gradient = LinearGradient([(color: Color(red: 120/255, green: 158/255, blue:237/255), location: 0), (color: Color(red: 55/255, green: 110/255, blue:224/255), location: 0.51), (color: Color(red: 34/255, green: 96/255, blue:221/255), location: 0.52), (color: Color(red: 36/255, green: 100/255, blue:224/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        Button(action:{action?()}) {
            ZStack {
                    Image(content).resizable().scaledToFit().frame(width: 30)

                Text("Done").font(.custom("Helvetica Neue Bold", size: 13.25)).foregroundColor(.white).shadow(color: Color.black.opacity(0.75), radius: 1, x: 0, y: -0.25).lineLimit(0).padding([.leading, .trailing], 11).opacity(0)
                
            }.frame(height: 32 + (height_modifier ?? 0)).ps_innerShadow(.roundedRectangle(5.5, returnLinearGradient(button_type)), radius:0.8, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
        }.frame(height: 32 + (height_modifier ?? 0))
    }
}

struct tool_bar_rectangle_button_larger_image: View {
    public var action: (() -> Void)?
    var button_type: tool_bar_button_type
    var content: String
    var use_image: Bool?
    var height_modifier: CGFloat? = 0
    private let gray_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    private let blue_gradient = LinearGradient([(color: Color(red: 120/255, green: 158/255, blue:237/255), location: 0), (color: Color(red: 55/255, green: 110/255, blue:224/255), location: 0.51), (color: Color(red: 34/255, green: 96/255, blue:221/255), location: 0.52), (color: Color(red: 36/255, green: 100/255, blue:224/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        Button(action:{action?()}) {
            ZStack {
                if use_image == true {
                    Image(content).resizable().scaledToFit().frame(width: 19).padding([.leading, .trailing], 7)
                } else {
                Text(content).font(.custom("Helvetica Neue Bold", fixedSize: 13.25)).foregroundColor(.white).shadow(color: Color.black.opacity(0.75), radius: 1, x: 0, y: -0.25).lineLimit(0).padding([.leading, .trailing], 11)
                }
            }.frame(height: 32 + (height_modifier ?? 0)).ps_innerShadow(.roundedRectangle(5.5, returnLinearGradient(button_type)), radius:0.8, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
        }.frame(height: 32 + (height_modifier ?? 0))
    }
}

struct tool_bar_rectangle_button_larger_image_wide: View {
    public var action: (() -> Void)?
    var button_type: tool_bar_button_type
    var content: String
    var use_image: Bool?
    var height_modifier: CGFloat? = 0
    private let gray_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    private let blue_gradient = LinearGradient([(color: Color(red: 120/255, green: 158/255, blue:237/255), location: 0), (color: Color(red: 55/255, green: 110/255, blue:224/255), location: 0.51), (color: Color(red: 34/255, green: 96/255, blue:221/255), location: 0.52), (color: Color(red: 36/255, green: 100/255, blue:224/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        Button(action:{action?()}) {
            ZStack {
                if use_image == true {
                    Image(content).resizable().scaledToFit().frame(width: 22).padding([.leading, .trailing], 12).offset(x: 2, y: -1)
                } else {
                Text(content).font(.custom("Helvetica Neue Bold", fixedSize: 13.25)).foregroundColor(.white).shadow(color: Color.black.opacity(0.75), radius: 1, x: 0, y: -0.25).lineLimit(0).padding([.leading, .trailing], 11)
                }
            }.frame(height: 32 + (height_modifier ?? 0)).ps_innerShadow(.roundedRectangle(5.5, returnLinearGradient(button_type)), radius:0.8, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
        }.frame(height: 32 + (height_modifier ?? 0))
    }
}



struct tool_bar_rectangle_button_custom_radius: View {
    public var action: (() -> Void)?
    var button_type: tool_bar_button_type
    var content: String
    var use_image: Bool?
    var height_modifier: CGFloat? = 0
    var radius: CGFloat
    private let gray_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    private let blue_gradient = LinearGradient([(color: Color(red: 120/255, green: 158/255, blue:237/255), location: 0), (color: Color(red: 55/255, green: 110/255, blue:224/255), location: 0.51), (color: Color(red: 34/255, green: 96/255, blue:221/255), location: 0.52), (color: Color(red: 36/255, green: 100/255, blue:224/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        Button(action:{action?()}) {
            ZStack {
                if use_image == true {
                    Image(content).resizable().scaledToFit().frame(width: 13).padding([.leading, .trailing], 11)
                } else {
                    Text(content).font(.custom("Helvetica Neue Bold", fixedSize: 13.25)).foregroundColor(.white).shadow(color: Color.black.opacity(0.75), radius: 0, x: 0, y: -1).lineLimit(0).padding([.leading, .trailing], 11)
                }
            }.frame(height: 32 + (height_modifier ?? 0)).ps_innerShadow(.roundedRectangle(radius, returnLinearGradient(button_type)), radius:0.8, offset: CGPoint(0, 0.6), intensity: 0.8).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
        }.frame(height: 32 + (height_modifier ?? 0))
    }
}

extension Double {
    func convert(fromRange: (Double, Double), toRange: (Double, Double)) -> Double {
        var value = self
        value -= fromRange.0
        value /= Double(fromRange.1 - fromRange.0)
        value *= toRange.1 - toRange.0
        value += toRange.0
        return value
    }
}
extension MPVolumeView {
    static func setVolume(_ volume: Float) -> Void {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
    @objc func volumeChanged(_ notification: NSNotification) {
        if let volume = notification.userInfo!["AVSystemController_AudioVolumeNotificationParameter"] as? Float {
            print("volume: \(volume)")
        }
    }
}

final class VolumeObserver: ObservableObject {

    @Published var volume: Float = AVAudioSession.sharedInstance().outputVolume *  100

    private let session = AVAudioSession.sharedInstance()
    private var progressObserver: NSKeyValueObservation!

    func subscribe() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("cannot activate session")
        }

        progressObserver = session.observe(\.outputVolume) { [self] (session, value) in
            DispatchQueue.main.async {
                self.volume = session.outputVolume * 100
            }
        }
    }

    func unsubscribe() {
        self.progressObserver.invalidate()
    }

    init() {
        subscribe()
    }
}

extension Float {
     var double: Double {
         get { Double(self) }
         set { self = Float(newValue) }
     }
 }

extension CGFloat {
     var double: Double {
         get { Double(self) }
         set { self = CGFloat(newValue) }
     }
 }

final class BrightnessObserver: ObservableObject {

    @Published var brightness: CGFloat = UIScreen.main.brightness*100

    let session = UIScreen()
    private var progressObserver: NSKeyValueObservation!

    func subscribe() {
        do {
            print("reg")
        let noteCenter = NotificationCenter.default
        noteCenter.addObserver(self,
                               selector: #selector(brightnessDidChange),
                               name: UIScreen.brightnessDidChangeNotification,
                               object: nil)
        } catch {
            print("cannot activate session")
        }

    }

    func unsubscribe() {
        self.progressObserver.invalidate()
    }

    init() {
        subscribe()
    }
    
    @objc func brightnessDidChange() {
        brightness = UIScreen.main.brightness*100
    }
}

extension View {
    func innerShadow(color: Color, radius: CGFloat = 0.1) -> some View {
        modifier(InnerShadow(color: color, radius: min(max(0, radius), 1)))
    }
    func innerShadowBottom(color: Color, radius: CGFloat = 0.1) -> some View {
        modifier(InnerShadow_Bottom(color: color, radius: min(max(0, radius), 1)))
    }
    func innerShadowBottomView(color: Color, radius: CGFloat = 0.1) -> some View {
        modifier(InnerShadow_Bottom_View(color: color, radius: min(max(0, radius), 1)))
    }
    func innerShadowToggle(color: Color, radius: CGFloat = 0.1) -> some View {
        modifier(InnerShadow_Toggle(color: color, radius: min(max(0, radius), 1)))
    }
    func innerShadowToggleTop(color: Color, radius: CGFloat = 0.1) -> some View {
        modifier(InnerShadow_Toggle_Top(color: color, radius: min(max(0, radius), 1)))
    }
    func innerShadowToggleSecondary(color: Color, radius: CGFloat = 0.1) -> some View {
        modifier(InnerShadow_Toggle_Secondary(color: color, radius: min(max(0, radius), 1)))
    }
    func innerShadowSlider(color: Color, radius: CGFloat = 0.1) -> some View {
        modifier(InnerShadowSlider(color: color, radius: min(max(0, radius), 1)))
    }
    func innerShadowSliderRight(color: Color, radius: CGFloat = 0.1) -> some View {
        modifier(InnerShadowSliderRight(color: color, radius: min(max(0, radius), 1)))
    }
    func innerShadowSliderMulti(color: Color, radius: CGFloat = 0.1) -> some View {
        modifier(InnerShadowSliderMulti(color: color, radius: min(max(0, radius), 1)))
    }
    func innerShadowSliderMultiDiffed(color: Color, radius: CGFloat = 0.1) -> some View {
        modifier(InnerShadowSliderDiffed(color: color, radius: min(max(0, radius), 1)))
    }
    func innerShadowFull(color: Color, radius: CGFloat = 0.1) -> some View {
          modifier(InnerShadow_Full(color: color, radius: min(max(0, radius), 1)))
      }
    func innerShadowBottomWithOffset(color: Color, radius: CGFloat = 0.1, offset: CGFloat) -> some View {
        modifier(InnerShadow_Bottom_With_Offset(color: color, radius: min(max(0, radius), 1), offset: offset))
    }
    func innerShadowSides(color: Color, radius: CGFloat = 0.1) -> some View {
        modifier(InnerShadow_Sides(color: color, radius: min(max(0, radius), 1)))
    }
}


private struct InnerShadow_Full: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1

    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }

    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .top, endPoint: .bottom)
                    .frame(height: self.radius * self.minSide(geo)),
                         alignment: .top)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .bottom, endPoint: .top)
                    .frame(height: self.radius * self.minSide(geo)),
                         alignment: .bottom)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .leading, endPoint: .trailing)
                    .frame(width: self.radius * self.minSide(geo)),
                         alignment: .leading)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .trailing, endPoint: .leading)
                    .frame(width: self.radius * self.minSide(geo)),
                         alignment: .trailing)
        }
    }

    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}

private struct InnerShadow_Sides: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1

    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }

    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .leading, endPoint: .trailing)
                    .frame(width: self.radius * self.minSide(geo)),
                         alignment: .leading)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .trailing, endPoint: .leading)
                    .frame(width: self.radius * self.minSide(geo)),
                         alignment: .trailing)
        }
    }

    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}

private struct InnerShadow: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1
    
    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .top, endPoint: .bottom)
                            .frame(height: self.radius * self.minSide(geo)),
                         alignment: .top)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .bottom, endPoint: .top)
                            .frame(height: self.radius * self.minSide(geo)),
                         alignment: .bottom)
        }
    }
    
    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}

private struct InnerShadowSlider: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1
    
    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .top, endPoint: .bottom)
                            .frame(height: self.radius * self.minSide(geo)),
                         alignment: .top)
             //   .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .leading, endPoint: .trailing)
                //            .frame(width: 40*self.radius, height: self.minSide(geo)),
             //            alignment: .leading)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .bottom, endPoint: .top)
                            .frame(height: self.radius * self.minSide(geo)),
                         alignment: .bottom)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .leading, endPoint: .trailing)
                            .frame(width: self.radius * self.minSide(geo)*3).opacity(0.5),
                         alignment: .leading)
        }
    }
    
    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}

private struct InnerShadowSliderRight: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1
    
    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .top, endPoint: .bottom)
                            .frame(height: self.radius * self.minSide(geo)),
                         alignment: .top)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .bottom, endPoint: .top)
                            .frame(height: self.radius * self.minSide(geo)),
                         alignment: .bottom)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .trailing, endPoint: .leading)
                                  .frame(width: self.radius * self.minSide(geo)),
                                       alignment: .trailing)
        }
    }
    
    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}

private struct InnerShadowSliderMulti: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1
    
    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .top, endPoint: .bottom)
                            .frame(height: self.radius * self.minSide(geo) * 1.25),
                         alignment: .top)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .bottom, endPoint: .top)
                            .frame(height: self.radius * self.minSide(geo) * 0.25),
                         alignment: .bottom)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .trailing, endPoint: .leading)
                                  .frame(width: self.radius * self.minSide(geo)),
                                       alignment: .trailing)
        }
    }
    
    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}

private struct InnerShadowSliderDiffed: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1
    
    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .top, endPoint: .bottom)
                            .frame(height: self.radius * self.minSide(geo) * 0.75).offset(y: 0.1),
                         alignment: .top)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .bottom, endPoint: .top)
                            .frame(height: self.radius * self.minSide(geo)*0.25).opacity(0.45),
                         alignment: .bottom)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .leading, endPoint: .trailing)
                            .frame(width: self.radius * self.minSide(geo)*0.1),
                                       alignment: .leading)
        }
    }
    
    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}

private struct InnerShadow_Toggle: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1
    
    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .top, endPoint: .bottom)
                            .frame(height: self.radius * self.minSide(geo)),
                         alignment: .top)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .leading, endPoint: .trailing)
                            .frame(width: 20*radius, height: self.minSide(geo)).opacity(0.3),
                         alignment: .leading)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .bottom, endPoint: .top)
                            .frame(height: self.radius * self.minSide(geo)*0.3).opacity(0.25),
                         alignment: .bottom)
        }
    }
    
    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}
private struct InnerShadow_Toggle_Secondary: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1
    
    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .top, endPoint: .bottom)
                            .frame(height: self.radius * self.minSide(geo)),
                         alignment: .top)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .trailing, endPoint: .leading)
                            .frame(width: 20*radius, height: self.minSide(geo)).opacity(0.3),
                         alignment: .trailing)
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .bottom, endPoint: .top)
                            .frame(height: self.radius * self.minSide(geo)*0.3).opacity(0.25),
                         alignment: .bottom)
        }
    }
    
    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}
private struct InnerShadow_Toggle_Top: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1
    
    private var colors: [Color] {
        [color.opacity(1.0), color.opacity(0.0), .clear]
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .top, endPoint: .bottom)
                            .frame(height: self.radius * self.minSide(geo)),
                         alignment: .top)
        }
    }
    
    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}
private struct InnerShadow_Bottom: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1
    
    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .top, endPoint: .bottom)
                            .frame(height: self.radius * self.minSide(geo)),
                         alignment: .top)
        }
    }
    
    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}

private struct InnerShadow_Bottom_With_Offset: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1
    var offset: CGFloat = 0.1
    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .top, endPoint: .bottom)
                            .frame(height: self.radius * self.minSide(geo)).offset(y:offset),
                         alignment: .top)
        }
    }
    
    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}
private struct InnerShadow_Bottom_View: ViewModifier {
    var color: Color = .gray
    var radius: CGFloat = 0.1
    
    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .overlay(LinearGradient(gradient: Gradient(colors: self.colors), startPoint: .bottom, endPoint: .top)
                            .frame(height: self.radius * self.minSide(geo)),
                         alignment: .bottom)
        }
    }
    
    func minSide(_ geo: GeometryProxy) -> CGFloat {
        CGFloat(3) * min(geo.size.width, geo.size.height) / 2
    }
}
extension View {
    func border_top(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
    func border_bottom(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
    func border_gradient(width: CGFloat, edges: [Edge], color: LinearGradient) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).fill(color))
    }
}
struct EdgeBorder: Shape {
    
    var width: CGFloat
    var edges: [Edge]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat {
                switch edge {
                case .top, .bottom, .leading: return rect.minX
                case .trailing: return rect.maxX - width
                }
            }
            
            var y: CGFloat {
                switch edge {
                case .top, .leading, .trailing: return rect.minY
                case .bottom: return rect.maxY - width
                }
            }
            
            var w: CGFloat {
                switch edge {
                case .top, .bottom: return rect.width
                case .leading, .trailing: return self.width
                }
            }
            
            var h: CGFloat {
                switch edge {
                case .top, .bottom: return self.width
                case .leading, .trailing: return rect.height
                }
            }
            path.addPath(Path(CGRect(x: x, y: y, width: w, height: h)))
        }
        return path
    }
}
extension Date {
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }
    
    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
}

extension View {
   @ViewBuilder
   func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
        if conditional {
            content(self)
        } else {
            self
        }
    }
}

class DiskStatus {

    //MARK: Formatter MB only
    class func MBFormatter(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = ByteCountFormatter.Units.useMB
        formatter.countStyle = ByteCountFormatter.CountStyle.decimal
        formatter.includesUnit = false
        return formatter.string(fromByteCount: bytes) as String
    }


    //MARK: Get String Value
    class var totalDiskSpace:String {
        get {
            return ByteCountFormatter.string(fromByteCount: totalDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.file)
        }
    }

    class var freeDiskSpace:String {
        get {
            return ByteCountFormatter.string(fromByteCount: freeDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.file)
        }
    }

    class var usedDiskSpace:String {
        get {
            return ByteCountFormatter.string(fromByteCount: usedDiskSpaceInBytes, countStyle: ByteCountFormatter.CountStyle.file)
        }
    }


    //MARK: Get raw value
    class var totalDiskSpaceInBytes:Int64 {
        get {
            do {
                let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
                let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value
                return space!
            } catch {
                return 0
            }
        }
    }

    class var freeDiskSpaceInBytes:Int64 {
        get {
            do {
                let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String)
                let freeSpace = (systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.int64Value
                return freeSpace!
            } catch {
                return 0
            }
        }
    }

    class var usedDiskSpaceInBytes:Int64 {
        get {
            let usedSpace = totalDiskSpaceInBytes - freeDiskSpaceInBytes
            return usedSpace
        }
    }

}
func randomString(length: Int) -> String {
  let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  return String((0..<length).map{ _ in letters.randomElement()! })
}

func randomNumberString(length: Int) -> String {
  let letters = "0123456789"
  return String((0..<length).map{ _ in letters.randomElement()! })
}
