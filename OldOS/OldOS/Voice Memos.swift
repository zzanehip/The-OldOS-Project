//
//  Voice Memos.swift
//  OldOS
//
//  Created by Zane on 6/30/25.
//

import SwiftUI
import Foundation
import Combine
import AVFoundation

struct VoiceMemos: View {
    @State var show_recordings: Bool = false
    @State private var didAutoLoadFirst = false
    @StateObject var player = RecordingPlayerVM()
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing:0) {
                    ZStack  {
                        status_bar().background(Color.black).frame(minHeight: 24, maxHeight:24).zIndex(1).opacity(show_recordings ? 0 : 1)
                        status_bar_in_app().background(Color.black).frame(minHeight: 24, maxHeight:24).zIndex(1).opacity(show_recordings ? 1 : 0)
                    }.frame(minHeight: 24, maxHeight:24)
                    Spacer()
                    voice_memos_body_view().frame(width: geometry.size.width*500/640, height: geometry.size.width*500/640*676/400)
                    voice_memos_footer(show_recordings: $show_recordings).frame(width: geometry.size.width, height: geometry.size.width*192/640)
                }
                if show_recordings {
                    recordings_view(show_recordings: $show_recordings).transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom))).zIndex(1)
                }
            }
        }
    }
}

struct recordings_view: View {
    @Binding var show_recordings: Bool
    @StateObject var lib = RecordingsLibrary()
    @StateObject var player = RecordingPlayerVM()
    @State var forward_or_backward = false
    @State var recordings_current_nav_view: String = "Recordings"
    @State var show_delete: Bool = false
    @State var current_recording: RecordingItem?
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                VStack(spacing:0)  {
                    Spacer().frame(minHeight: 24, maxHeight:24)
                    recordings_title_bar(title: recordings_current_nav_view == "Recordings" ? "Voice Memos" : "Info", forward_or_backward: $forward_or_backward, recordings_current_nav_view: $recordings_current_nav_view, show_done: recordings_current_nav_view == "Recordings", is_speaker: player.is_speaker, done_action:{withAnimation(){show_recordings.toggle()}}, speaker_action: {player.toggle_speaker()}).frame(minHeight: 60, maxHeight: 60)
                    switch recordings_current_nav_view {
                    case "Recordings":
                        ZStack {
                            NoSepratorList {
                                ForEach(lib.items.filter({$0.duration != 0})) { item in
                                    Button(action:{
                                        if !playerIsFor(item) {
                                            player.load(item.url)
                                        }
                                    }) {
                                        VStack(alignment: .leading, spacing: 0) {
                                            HStack(alignment: .center) {
                                                Spacer().frame(width:1, height: 60-0.95)
                                                Button(action: {
                                                    if item.url == player.player?.url ?? URL(string: "") {
                                                        player.togglePlayPause()
                                                    }
                                                }) {
                                                    Image(player.player?.isPlaying ?? false ? "button-pause" : "button-play").resizable().scaledToFill().frame(width: 26, height: 27)
                                                }.frame(width: 19, height: 20).padding(.trailing, 4).opacity(item.url == player.player?.url ?? URL(string: "") ? 1 : 0)
                                                VStack(alignment: .leading, spacing: 1.5) {
                                                    Text(item.title).font(.custom("Helvetica Neue Bold", fixedSize: 15.5)).foregroundColor(item.url == player.player?.url ?? URL(string: "") ? Color.white : Color.black).lineLimit(1)
                                                    HStack {
                                                        Text(item.date.formatted(.dateTime.year(.twoDigits).month(.twoDigits).day(.twoDigits))).font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(item.url == player.player?.url ?? URL(string: "") ? Color.white : Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1)
                                                    }
                                                }.padding(.trailing, 12)
                                                Spacer()
                                                Text(item.duration.mmss).font(.custom("Helvetica Neue Regular", fixedSize: 14.5)).foregroundColor(item.url == player.player?.url ?? URL(string: "") ? Color.white : Color(red: 58/255, green: 111/255, blue: 209/255))
                                                Button(action: {
                                                    current_recording = item
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                                        forward_or_backward = false; withAnimation(.linear(duration: 0.28)){recordings_current_nav_view = "Recordings_Destination"}
                                                    }
                                                }) {
                                                    Image("ABTableNextButton").padding(.trailing, 11).transition(.opacity)
                                                }
                                            }.padding(.leading, 11)
                                            Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                            
                                        }.background(LinearGradient([Color(red: 77/255, green: 151/255, blue: 245/255), Color(red: 33/255, green: 106/255, blue: 228/255)], from: .top, to: .bottom).opacity(item.url == player.player?.url ?? URL(string: "") ? 1 : 0))
                                    }
                                }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 60).drawingGroup()
                                Spacer().padding(.bottom, 120)
                            }
                            VStack(spacing: 0) {
                                Spacer()
                                recordings_footer(player: player, lib: lib, show_delete: $show_delete).frame(width: geometry.size.width, height: 120).background(Color.white)
                            }
                        }.background(Color.white).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Recordings_Destination":
                        recordings_destination(current_recording: current_recording ?? RecordingItem(url: URL.documentsDirectory, title: "", duration: TimeInterval(0), date: Date())).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    default:
                        Spacer()
                    }
                }.clipped()
                if show_delete == true {
                    Color.black.opacity(0.35).allowsHitTesting(false)
                    VStack(spacing:0) {
                        Spacer().foregroundColor(.clear).zIndex(0)
                        delete_recording_view(cancel_action:{
                            withAnimation() {
                                show_delete.toggle()
                            }
                        }, delete_action :{
                            guard let url = player.player?.url else {return}
                            player.stopIfPlaying(url: url)
                            lib.delete(url: url)
                            DispatchQueue.main.asyncAfter(deadline:.now()+0.25) {
                                withAnimation(.linear(duration:0.25)) {
                                    show_delete.toggle()
                                }
                            }
                        }).frame(width: geometry.size.width, height: 180)
                    }.transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom))).zIndex(3)
               }
        }
        }.onAppear() {
            UIScrollView.appearance().bounces = true
        }.onDisappear() {
            UIScrollView.appearance().bounces = true
        }.onChange(of: lib.items) { newItems in
            guard let first = newItems.first else { return }
            if player.player?.url == nil {
                player.load(first.url)
            }
        }
        }
    
    private func playerIsFor(_ item: RecordingItem) -> Bool {
        guard let url = playerCurrentURL else { return false }
        return url == item.url
    }

    private var playerCurrentURL: URL? {
        nil
    }

    private func bindingForCurrentTime(_ item: RecordingItem) -> Binding<Double> {
        Binding<Double>(
            get: { playerIsFor(item) ? player.currentTime : 0 },
            set: { newVal in
                if playerIsFor(item) {
                    player.seek(to: newVal)
                } else {
                    player.load(item.url)
                    player.seek(to: newVal)
                }
            }
        )
    }

    private func playerDurationFor(_ item: RecordingItem) -> Double {
        playerIsFor(item) ? max(player.duration, item.duration) : item.duration
    }
}

struct recordings_destination: View {
    var current_recording: RecordingItem
    @State var current_nav_view: String = ""
    @State var forward_or_backward: Bool = false
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                settings_main_list()
            ScrollView(showsIndicators: true) {
                VStack {
                    HStack() {
                        VStack {
                            Image("vm-microphone-icon").padding(.leading, 22).offset(y: 16)
                            Spacer()
                        }
                        VStack(alignment: .leading) {
                            Text(current_recording.title).font(.custom("Helvetica Neue Bold", fixedSize: 20)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).lineLimit(0).padding(.leading, 5)
                            Text(formatTimeInterval(current_recording.duration)).font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(.gray).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).lineLimit(0).padding(.leading, 5)
                            Text("Recorded on " + formatFullDate(current_recording.date)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(Color(red: 85/255, green: 101/255, blue: 142/255)).multilineTextAlignment(.leading).lineLimit(2).padding(.leading, 5).padding(.top, 1)
                        }
                        Spacer()
                        Image("chevron").padding(.trailing, 12)
                    }.frame(height: 110).background(Color.white.cornerRadius(10)).cornerRadius(10).strokeRoundedRectangle(10, Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1).padding([.leading, .trailing], 12).padding(.top, 20)
                    Spacer().frame(height:20)
                    HStack(spacing: 0) {
                        list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: [list_row(title: "", content: AnyView( Text("Trim Memo").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(Color(red: 85/255, green: 101/255, blue: 142/255)).multilineTextAlignment(.center).frame(width:75, alignment: .center).lineLimit(0)))])
                        list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: [list_row(title: "", content: AnyView(Text("Share").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(Color(red: 85/255, green: 101/255, blue: 142/255)).multilineTextAlignment(.center).frame(width:75, alignment: .center).lineLimit(0)))])
                    }
                    Spacer()
                }
            }
            }
        }
    }
    func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM\nd, yyyy"
        return formatter.string(from: date)
    }
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct recordings_title_bar : View {
    var title:String
    @Binding var forward_or_backward: Bool
    @Binding var recordings_current_nav_view: String
    var show_done: Bool?
    var is_speaker: Bool
    public var done_action: (() -> Void)?
    public var speaker_action: (() -> Void)?
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
            if recordings_current_nav_view != "Recordings" {
                VStack {
                    Spacer()
                    HStack {
                        Button(action:{
                            forward_or_backward = true; withAnimation(.linear(duration: 0.28)){recordings_current_nav_view = "Recordings"}
                        }){
                            ZStack {
                                Image("Button_wp5").resizable().scaledToFit().frame(width:200*84/162*(33/34.33783783783784), height: 33)
                                HStack(alignment: .center) {
                                    Text("Voice Memos").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1).offset(x: 1).frame(maxWidth: 90).lineLimit(0)
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
                        tool_bar_rectangle_button(button_type: .blue_gray, content: "Edit ").padding(.trailing, 8)
                    }
                    Spacer()
                }.offset(y:-0.75).transition(.opacity)

            }
            if show_done == true {
            HStack {
                tool_bar_rectangle_button(action: {speaker_action?()}, button_type: is_speaker ? .blue : .blue_gray, content: "Speaker").padding(.leading, 5)
                Spacer()
                tool_bar_rectangle_button(action: {done_action?()}, button_type: .blue, content: "Done").padding(.trailing, 5)
            }
            }

        }
    }
}

struct delete_recording_view: View {
    public var cancel_action: (() -> Void)?
    public var delete_action: (() -> Void)?
    private let background_gradient = LinearGradient(gradient: Gradient(colors: [Color.init(red: 70/255, green: 73/255, blue: 81/255), Color.init(red: 70/255, green: 73/255, blue: 81/255)]), startPoint: .top, endPoint: .bottom)
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                VStack(spacing:0) {
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 166/255, green: 171/255, blue: 179/255).opacity(0.88), Color.init(red: 122/255, green: 127/255, blue: 138/255).opacity(0.88)]), startPoint: .top, endPoint: .bottom)).innerShadowBottom(color: Color.white.opacity(0.98), radius: 0.1).border_top(width: 1, edges:[.top], color: Color.black).frame(height:30)
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 96/255, green: 101/255, blue: 111/255).opacity(0.88), Color.init(red: 96/255, green: 101/255, blue: 111/255).opacity(0.9)]), startPoint: .top, endPoint: .bottom))
                }
                VStack {
                    Spacer()
                    Button(action:{
                        delete_action?()
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color.clear).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5)).ps_innerShadow(.roundedRectangle(12, background_gradient), radius:5/3, offset: CGPoint(0, 1/3), intensity: 1)
                            RoundedRectangle(cornerRadius: 9).fill(returnLinearGradient(.red)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Delete").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0.0, y: -0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }
                    Spacer()
                    Button(action:{
                      cancel_action?()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color.clear).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5)).ps_innerShadow(.roundedRectangle(12, background_gradient), radius:5/3, offset: CGPoint(0, 1/3), intensity: 1)
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient([(color: Color(red: 107/255, green: 113/255, blue:119/255), location: 0), (color: Color(red: 53/255, green: 62/255, blue:69/255), location: 0.50), (color: Color(red: 41/255, green: 48/255, blue:57/255), location: 0.50), (color: Color(red: 56/255, green: 62/255, blue: 71/255), location: 1)], from: .top, to: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.gray.opacity(0.9), Color.gray.opacity(0.35)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3).opacity(0.6)
                            Text("Cancel").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0.0, y: -0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }
                    Spacer()
                }
            }.drawingGroup()
        }
    }
}

struct recordings_footer: View {
    @ObservedObject var player: RecordingPlayerVM
    @ObservedObject var lib: RecordingsLibrary
    @Binding var show_delete: Bool
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                VStack(spacing:0) {
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 101/255, green: 100/255, blue: 100/255).opacity(0.88), Color.init(red: 31/255, green: 30/255, blue: 30/255).opacity(0.88)]), startPoint: .top, endPoint: .bottom)).innerShadowBottom(color: Color.white.opacity(0.98), radius: 0.1).border_top(width: 1, edges:[.top], color: Color.black).frame(height:30)
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 21/255, green: 20/255, blue: 20/255).opacity(0.88), Color.black.opacity(0.95)]), startPoint: .top, endPoint: .bottom))
                }
                VStack(spacing: 0) {
                    HStack {
                        Text(formattedDuration(player.currentTime)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).padding(.leading, 15)
                        CustomSliderMemo(
                            type: "Memo",
                            duration: player.duration,
                            value: $player.currentTime,
                            range: (0, player.duration),
                            knobWidth: 14
                        ) { modifiers in
                            ZStack {
                                
                                LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 205/255, green: 220/255, blue: 241/255), location: 0), .init(color: Color(red: 125/255, green: 174/255, blue: 245/255), location: 0.5), .init(color: Color(red: 45/255, green: 111/255, blue: 198/255), location: 0.5), .init(color: Color(red: 50/255, green: 151/255, blue: 236/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 8).cornerRadius(4.25).padding(.leading, 4).modifier(modifiers.barLeft)
                                
                                LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 218/255, green: 218/255, blue: 218/255), location: 0), .init(color: Color(red: 166/255, green: 166/255, blue: 166/255), location: 0.19), .init(color: Color(red: 204/255, green: 204/255, blue: 204/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 8).cornerRadius(4.25).padding(.trailing, 4).modifier(modifiers.barRight)
                                ZStack {
                                    Image("volume-slider-fat-knob").resizable().scaledToFill()
                                }.modifier(modifiers.knob)
                            }
                        }.frame(height: 20)
                        Text(formattedDuration(player.duration)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).shadow(color: Color.black.opacity(0.75), radius: 0, x: 0.0, y: -1).padding(.trailing, 15)
                    }.offset(y: 10)
                    HStack {
                        Button(action:{
                        }){
                            ZStack {
                                RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5))
                                RoundedRectangle(cornerRadius: 9).fill(returnLinearGradient(.blue)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                                Text("Share").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0.0, y: -0.9)
                            }.padding([.leading], 12).padding([.trailing], 6).frame(minHeight: 50, maxHeight:50)
                        }.padding([.bottom], 2.5).padding(.top, 28)
                        Spacer()
                        Button(action:{
                            withAnimation() {
                                show_delete.toggle()
                            }
                        }){
                            ZStack {
                                RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5))
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(returnLinearGradient(.red)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                                Text("Delete").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0.0, y: -0.9)
                            }.padding([.leading], 6).padding([.trailing], 12).frame(minHeight: 50, maxHeight:50)
                        }.padding([.bottom], 2.5).padding(.top, 28)
                    }
                }
            }
        }
    }
    func formattedDuration(_ duration: Double) -> String {
        guard duration.isFinite && duration > 0 else { return "0:00" }
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct RecordingItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let title: String
    let duration: TimeInterval
    let date: Date
}


final class RecordingsLibrary: ObservableObject {
    @Published var items: [RecordingItem] = []

    private let fm = FileManager.default
    private let dfTitle: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short
        return df
    }()
    
    init() {
        refresh()
    }

    func refresh() {
          let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
          let urls = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
          let m4a = urls.filter { $0.pathExtension.lowercased() == "m4a" }

          let dfFile = DateFormatter()
          dfFile.locale = Locale(identifier: "en_US_POSIX")
          dfFile.dateFormat = "yyyy-MM-dd_HH-mm-ss"

        let dfTitle = DateFormatter()
        dfTitle.locale = Locale(identifier: "en_US_POSIX")
        dfTitle.timeZone = .current
        dfTitle.dateFormat = "h:mm a"
        
          var out: [RecordingItem] = []
        for url in m4a {
            let name = url.deletingPathExtension().lastPathComponent
            var title = "Unknown"
            var date = Date()

            if name.hasPrefix("REC_") {
                let stamp = String(name.dropFirst(4))
                if let parsed = dfFile.date(from: stamp) {
                    date = parsed
                    title = dfTitle.string(from: parsed)
                }
            }

            let asset = AVURLAsset(url: url)
            let dur = CMTimeGetSeconds(asset.duration)
            out.append(RecordingItem(url: url, title: title, duration: dur, date: date))
        }

        out.sort { $0.date > $1.date }
          DispatchQueue.main.async { self.items = out }
      }

    private func parsedDateFromFilename(_ url: URL) -> Date? {
        let name = url.deletingPathExtension().lastPathComponent
        guard name.hasPrefix("REC_") else { return nil }
        let stamp = String(name.dropFirst(4))
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return df.date(from: stamp)
    }
    
    func delete(url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Delete failed:", error)
        }
        items.removeAll { $0.url == url }
    }
    
}

final class RecordingPlayerVM: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var is_speaker: Bool = false
    
    private var observers: [NSObjectProtocol] = []

    init() {
        let nc = NotificationCenter.default

        let scrub = nc.addObserver(
            forName: .memoSliderDidScrub, object: nil, queue: .main
        ) { [weak self] note in
            guard let t = note.userInfo?["time"] as? Double else { return }
            self?.seek(to: t)
        }

        let end = nc.addObserver(
            forName: .memoSliderDidEndScrub, object: nil, queue: .main
        ) { [weak self] note in
            guard let t = note.userInfo?["time"] as? Double else { return }
            self?.seek(to: t)
        }

        observers.append(contentsOf: [scrub, end])
    }

    deinit {
        let nc = NotificationCenter.default
        observers.forEach { nc.removeObserver($0) }
        observers.removeAll()
    }

    var player: AVAudioPlayer?
    private var tick: Timer?

    func load(_ url: URL) {
        stop()
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.prepareToPlay()
            player = p
            duration = p.duration
            currentTime = 0
            isPlaying = false
        } catch {
            print("Player load error:", error)
        }
    }

    func togglePlayPause() {
        guard let p = player else { return }
        if p.isPlaying {
            p.pause()
            isPlaying = false
            stopTick()
        } else {
            p.play()
            isPlaying = true
            startTick()
        }
    }
    
    func toggle_speaker() {
        if is_speaker {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                try session.overrideOutputAudioPort(.none)
                try session.setActive(true)
                is_speaker = false
            } catch {
                print("Audio session setup error: \(error)")
            }
        } else {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                try session.overrideOutputAudioPort(.speaker)
                try session.setActive(true)
                is_speaker = true
            } catch {
                print("Audio session setup error: \(error)")
            }
        }
    }


    func seek(to time: TimeInterval) {
        guard let p = player else { return }
        p.currentTime = min(max(0, time), p.duration)
        currentTime = p.currentTime
        if isPlaying { startTick() }
    }

    func stop() {
        player?.stop()
        isPlaying = false
        stopTick()
        currentTime = 0
    }

    private func startTick() {
        stopTick()
        tick = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let p = self.player else { return }
            self.currentTime = p.currentTime
            if !p.isPlaying || p.currentTime >= p.duration {
                self.stop()
            }
        }
        RunLoop.main.add(tick!, forMode: .common)
    }

    private func stopTick() {
        tick?.invalidate()
        tick = nil
    }
    
    func stopIfPlaying(url: URL) {
        if player?.url == url {
            stop()
        }
    }
}


extension TimeInterval {
    var mmss: String {
        if self < 60 { return "\(Int(self.rounded()))s" }
        let m = Int(self) / 60
        let s = Int(self) % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct voice_memos_body_view: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("whiteglow").resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).opacity(0.45)
                Image("mic").resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

struct voice_memos_footer: View {
    @StateObject private var recorder = AudioRecorderWithLiveVU()
    @Binding var show_recordings: Bool
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("bezel").resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height)
                VUMeterView(recorder: recorder).frame(width: geometry.size.width, height: geometry.size.height).offset(y: -1)
                HStack(spacing: 0) {
                    Button(action: {
                        if recorder.state == .stopped {
                            recorder.startRecording()
                        } else if recorder.state == .paused {
                            recorder.resumeRecording()
                        } else {
                            recorder.pauseRecording()
                        }
                    }) {
                        Image(recorder.state == .recording ? "voicememos-pause" : "record").resizable().scaledToFill()
                    }.frame(width: geometry.size.height*92/192, height: geometry.size.height*94/192).padding([.leading], geometry.size.width*30/640+1).padding(.top, 0.5)
                    Spacer()
                    Button(action: {
                        if recorder.state == .recording {
                            recorder.stopRecording()
                        } else {
                            withAnimation() {
                                show_recordings.toggle()
                            }
                        }
                    }) {
                        Image(recorder.state == .recording ? "stop" : "list").resizable().scaledToFill()
                    }.frame(width: geometry.size.height*92/192, height: geometry.size.height*94/192).padding([.trailing], geometry.size.width*30/640+1).padding(.top, 0.5)
                }
            }
        }
    }
}

struct VUNeedle: View {
    var angleDegrees: Double
    var length: CGFloat
    var thickness: CGFloat

    var body: some View {
        Image("needle")
               .resizable()
               .scaledToFit()
               .rotationEffect(.degrees(angleDegrees), anchor: .bottom)
               .allowsHitTesting(false)
    }
}

struct VUMeterView: View {
    @ObservedObject var recorder: AudioRecorderWithLiveVU

    private let minVU: Double = -20
    private let maxVU: Double = 5
    private let startAngle: Double = -56
    private let endAngle: Double = 56

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("vu")
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .overlay(Image(recorder.vu == maxVU ? "redlevelON" :  "redlevelOFF").resizable().scaledToFill().frame(width: 30, height: 30).offset(x: 133/640*geo.size.width, y: -geo.size.height*150/640/2))

                let angle    = needleAngle(for: recorder.vu)
                let needleH = geo.size.height * (123.0 / 190.0)
                let needleW = needleH * (11.0 / 71.0)
                let pivotY  = geo.size.height - geo.size.height * (20.0 / 194.0)

                Image("needle")
                    .resizable()
                    .frame(width: needleW, height: needleH)
                    .rotationEffect(.degrees(needleAngle(for: angle)), anchor: .bottom)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .position(x: geo.size.width / 2, y: pivotY - needleH/2)
                    .allowsHitTesting(false)
                    .zIndex(1)
                    .mask(
                        Image("vumask")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width*320/640, height: geo.size.width*150/640)
                    )
            }
            .onAppear { recorder.startMonitoring() }
            .onDisappear { recorder.stopMonitoring() }
        }
    }

    private func needleAngle(for vu: Double) -> Double {
        let clamped = max(min(vu, maxVU), minVU)
        let t = (clamped - minVU) / (maxVU - minVU)
        return startAngle + t * (endAngle - startAngle)
    }
}

final class AudioRecorderWithLiveVU: ObservableObject {
    enum State { case stopped, recording, paused }

    @Published var vu: Double = -20.0
    @Published var state: State = .stopped
    @Published var lastError: String?

    private let tau: Double = 0.30
    private var vuSmooth: Double = -20.0
    private let minVU = -20.0, maxVU = 5.0
    private let vuRefOffset: Double = 40

    private var engine = AVAudioEngine()
    private var recorder: AVAudioRecorder?
    
    private let tauAttack: Double = 0.30
    private let tauRelease: Double = 0.60
    private var last3: [Double] = []

    private func median3(_ a: [Double]) -> Double {
        var b = a
        b.sort()
        return b[b.count/2]
    }

    func startMonitoring() {
        configureSessionIfNeeded()
        installVUTapIfNeeded()
        do { try engine.start() } catch { lastError = "Engine start: \(error.localizedDescription)" }
    }

    func stopMonitoring() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }

    func toggleRecordPause() {
        switch state {
        case .stopped, .paused: startRecording()
        case .recording: pauseRecording()
        }
    }

    func stopRecording() {
        recorder?.stop(); recorder = nil
        state = .stopped
    }
    
    func resumeRecording() {
        guard let rec = recorder else {
            startRecording()
            return
        }
        if !rec.isRecording {
            rec.record()
        }
        state = .recording
    }
    
    private func selectBuiltInMicBackPreferred() {
        let session = AVAudioSession.sharedInstance()
        guard let builtIn = session.availableInputs?.first(where: { $0.portType == .builtInMic }) else { return }

        let dsBack   = builtIn.dataSources?.first(where: { $0.orientation == .back })
        let dsBottom = builtIn.dataSources?.first(where: { $0.orientation == .bottom })
        let dsFront  = builtIn.dataSources?.first(where: { $0.orientation == .front })
        let t = builtIn.dataSources
        print(t)
        let chosen =  dsFront ??  dsBack ?? dsBottom ?? builtIn.dataSources?.first

        if let ds = chosen {
            if let pats = ds.supportedPolarPatterns, pats.contains(.cardioid) {
                try? ds.setPreferredPolarPattern(.cardioid)
            }
            try? builtIn.setPreferredDataSource(ds)
        }

        try? session.setPreferredInput(builtIn)
    }


    private func configureSessionIfNeeded() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default,
                                    options: [.defaultToSpeaker, .allowBluetoothHFP, .mixWithOthers]) //Using videoRecording seems give us the best results
            try session.setActive(true)
            try? session.setPreferredInputNumberOfChannels(session.maximumInputNumberOfChannels)
        } catch { lastError = "Session: \(error.localizedDescription)" }
        session.requestRecordPermission { _ in }
    }

    private func installVUTapIfNeeded() {
        let input = engine.inputNode
        let fmt = input.inputFormat(forBus: 0)
        input.removeTap(onBus: 0)

        input.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak self] buf, _ in
            guard let self = self, buf.frameLength > 0 else { return }
            guard let chans = buf.floatChannelData else { return }
            
            let n = Int(buf.frameLength)
            let chCount = Int(fmt.channelCount)
            var sum: Double = 0

            for c in 0..<chCount {
                let p = chans[c]
                var s: Double = 0
                for i in 0..<n {
                    let v = Double(p[i])
                    s += v * v
                }
                sum += s
            }

            let denom = max(n * chCount, 1)
            let rms = sqrt(max(sum / Double(denom), 1e-20))
            let dbFS = 20.0 * log10(rms)
            var vuInstant = dbFS + self.refOffsetForCurrentInput()
            if !vuInstant.isFinite { vuInstant = self.minVU }

            let dt = Double(buf.frameLength) / fmt.sampleRate
            let alpha = dt / (self.tau + dt)
            self.vuSmooth = (1 - alpha) * self.vuSmooth + alpha * vuInstant

            let clamped = min(max(self.vuSmooth, self.minVU), self.maxVU)
            DispatchQueue.main.async { self.vu = clamped }
        }
    }


    func startRecording() {
        do {
            let url = recordingURL()
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let rec = try AVAudioRecorder(url: url, settings: settings)
            rec.isMeteringEnabled = false
            rec.prepareToRecord()
            rec.record()
            recorder = rec
            state = .recording
        } catch {
            lastError = "Record: \(error.localizedDescription)"
        }
    }

    func pauseRecording() {
        recorder?.pause()
        state = .paused
    }

    func recordingURL() -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dfFile = DateFormatter()
        dfFile.locale = Locale(identifier: "en_US_POSIX")
        dfFile.dateFormat = "yyyy-MM-dd_HH-mm-ss"

        let now = Date()
        return dir.appendingPathComponent("REC_\(dfFile.string(from: now)).m4a")
    }
    private func refOffsetForCurrentInput() -> Double {
        let session = AVAudioSession.sharedInstance()
        let port = session.currentRoute.inputs.first?.portType

        switch port {
        case .bluetoothHFP:
            return 12.0
        case .headsetMic, .headphones:
            return 12.0
        case .builtInMic:
            return 12.0
        default:
            return 12.0
        }
    }
}
