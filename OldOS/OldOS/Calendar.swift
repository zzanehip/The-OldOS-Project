//
//  Calendar.swift
//  OldOS
//
//  Created by Zane Kleinberg on 6/4/21.
//

//Messages, Calendar, Youtube, and Mail are all coming soon. I have my own private version of these which I am currently working on, but decided to include the public version here.

import SwiftUI

struct CalendarView: View {
    @State var current_nav_view: String = "Main"
    @State var forward_or_backward: Bool = false
    @State var show_alert:Bool = false
    @State var increase_brightness: Bool = false
    @State private var alertTask: Task<Void, Never>?
    var content_header = [list_row(title: "", content: AnyView(calendar_content_hide()))]
    var content_mid = [list_row(title: "", content: AnyView(calendar_content_calendar()))]
    var content_footer = [list_row(title: "", content: AnyView(calendar_content_footer()))]
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                settings_main_list()
                VStack(spacing:0) {
                    status_bar_in_app().frame(minHeight: 24, maxHeight:24).zIndex(1)
                    generic_title_bar(title: "Calendars").frame(height: 60)
                    ScrollView {
                        VStack {
                            Spacer().frame(height: 15)
                            list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content:content_header)
                            Spacer().frame(height: 10)
                            HStack {
                                Text("On My iPhone").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                                Spacer()
                            }
                            list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content:content_mid)
                            Spacer().frame(height: 10)
                            HStack {
                                Text("Other").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                                Spacer()
                            }
                            list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content:content_footer)
                            Spacer()
                        }
                    }
                }
            }.overlay(ZStack{
                if show_alert {
                    Color.black.opacity(0.55).transition(.opacity)
                    Rectangle().fill(Color.white.opacity(0.25)).frame(width:geometry.size.width-10, height:geometry.size.width).cornerRadius(geometry.size.width/2).blur(radius: 30).transition(.opacity)
                    skeumorphic_alert(title:"Calendar is Coming Soon", subtitle: "There's still some major issues with Calendar I'm working to fix, but I didn't want you to miss out on OldOS. Check back soon.", dismiss_action: {
                        increase_brightness = true
                        withAnimation(.linear(duration:0.25)){show_alert.toggle()}
                        
                    }).brightness(increase_brightness == true ? 0.5 : 0).clipped().transition(.asymmetric(insertion: .scale, removal: .opacity))
                    //Don't ask me why, but it likes to fade to gray, we set the brightness to 0.5 when removing to restore it to a neutral color.
                }
            }).compositingGroup().clipped()
        }.onAppear() {
            UIScrollView.appearance().bounces = true
            alertTask?.cancel()
            alertTask = Task<Void, Never> { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }

                increase_brightness = false
                withAnimation(.spring(response: 0.3,
                                       dampingFraction: 0.55,
                                       blendDuration: 0.25)) {
                    show_alert.toggle()
                }
            }
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
            alertTask?.cancel()
            alertTask = nil
        }
    }
}

struct calendar_content_hide: View {
    var body: some View {
        HStack {
           Spacer()
            Text("Hide All Calendars").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black)
            Spacer()
        }
    }
}


struct calendar_content_calendar: View {
    var body: some View {
        HStack {
            Circle().fill(Color(red: 184/255, green: 154/255, blue: 190/255)).strokeCircle(Color(red: 141/255, green: 98/255, blue: 149/255), lineWidth: 0.75).frame(width: 15, height: 15).padding(.leading, 12)
            Text("Calendar").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black)
            Spacer()
            Image("UIPreferencesBlueCheck").padding(.trailing, 12)
        }
    }
}

struct calendar_content_footer: View {
    var body: some View {
        HStack {
            Image("birthday").padding(.leading, 12)
            Text("Birthdays").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black)
            Spacer()
            Image("UIPreferencesBlueCheck").padding(.trailing, 12)
        }
    }
}

