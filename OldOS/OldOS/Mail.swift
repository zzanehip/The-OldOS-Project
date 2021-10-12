//
//  Mail.swift
//  OldOS
//
//  Created by Zane Kleinberg on 2/28/21.
//

import SwiftUI

//Messages, Calendar, Youtube, and Mail are all coming soon. I have my own private version of these which I am currently working on, but decided to include the public version here.

struct Mail: View {
    @State var current_nav_view: String?
    @State var forward_or_backward: Bool?
    @State var show_alert:Bool = false
    @State var increase_brightness: Bool = false
    var content = [list_row(title: "", content: AnyView(mail_content(image: "exchange"))), list_row(title: "", content: AnyView(mail_content(image: "mobileme"))), list_row(title: "", content: AnyView(mail_content(image: "gmail"))), list_row(title: "", content: AnyView(mail_content(image: "yahoo"))), list_row(title: "", content: AnyView(mail_content(image: "aol"))),  list_row(title: "", content: AnyView(mail_content_other()))]
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                settings_main_list()
                VStack(spacing:0) {
                    status_bar_in_app().frame(minHeight: 24, maxHeight:24).zIndex(1)
                    generic_title_bar(title: "Welcome to Mail").frame(height: 60)
                    ScrollView {
                        VStack {
                            Spacer().frame(height: 15)
                            list_section_content_only_large(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content:content).onTapGesture {
                                increase_brightness = false
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.55, blendDuration: 0.25)) {
                                    show_alert.toggle()
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }.overlay(ZStack{
                if show_alert {
                    Color.black.opacity(0.55).transition(.opacity)
                    Rectangle().fill(Color.white.opacity(0.25)).frame(width:geometry.size.width-10, height:geometry.size.width).cornerRadius(geometry.size.width/2).blur(radius: 30).transition(.opacity)
                    skeumorphic_alert(title:"Mail is Coming Soon", subtitle: "There's still some major issues with Mail I'm working to fix, but I didn't want you to miss out on OldOS. Check back soon.", dismiss_action: {
                        increase_brightness = true
                        withAnimation(.linear(duration:0.25)){show_alert.toggle()}
                        
                    }).brightness(increase_brightness == true ? 0.5 : 0).clipped().transition(.asymmetric(insertion: .scale, removal: .opacity))
                    //Don't ask me why, but it likes to fade to gray, we set the brightness to 0.5 when removing to restore it to a neutral color.
                }
            }).compositingGroup().clipped()
        }.onAppear() {
            UIScrollView.appearance().bounces = true
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
        }
    }
}

struct mail_content: View {
    var image: String
    var body: some View {
        HStack {
            Image(image)
        }
    }
}

struct mail_content_other: View {
    var body: some View {
        HStack {
          Text("Other").font(.custom("Helvetica Neue Bold", fixedSize: 24))
        }
    }
}

struct test_view: View {
    var body: some View {
        Button(action:{}) {
            Text("hi")
        }.simultaneousGesture(LongPressGesture().onChanged {_ in
            print("long pressed")
        })
    }
}
