//
//  Youtube.swift
//  OldOS
//
//  Created by Zane Kleinberg on 5/24/21.
//

import Foundation
import SwiftUI

//Messages, Calendar, Youtube, and Mail are all coming soon. I have my own private version of these which I am currently working on, but decided to include the public version here.

struct Youtube: View {
    @State var current_nav_view: String = "Main"
    @State var forward_or_backward: Bool = false
    @State var selectedTab = "Featured"
    @State var show_alert:Bool = false
    @State var increase_brightness: Bool = false
    @State var done_loading: Bool = false
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing:0) {
                    status_bar_in_app().frame(minHeight: 24, maxHeight:24).zIndex(1)
                    generic_title_bar(title: selectedTab).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 60, maxHeight:60).zIndex(1).disabled(true)
                    YoutubeTabView(selectedTab: $selectedTab, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, done_loading: $done_loading).clipped().disabled(true)
                }
            }.compositingGroup().clipped().overlay(ZStack{
                if show_alert {
                    Color.black.opacity(0.55).transition(.opacity)
                    Rectangle().fill(Color.white.opacity(0.25)).frame(width:geometry.size.width-10, height:geometry.size.width).cornerRadius(geometry.size.width/2).blur(radius: 30).transition(.opacity)
                    skeumorphic_alert(title:"YouTube is Coming Soon", subtitle: "There's still some major issues with YouTube I'm working to fix, but I didn't want you to miss out on OldOS. Check back soon.", dismiss_action: {
                        increase_brightness = true
                        withAnimation(.linear(duration:0.25)){show_alert.toggle()}
                        
                    }).brightness(increase_brightness == true ? 0.5 : 0).clipped().transition(.asymmetric(insertion: .scale, removal: .opacity))
                    //Don't ask me why, but it likes to fade to gray, we set the brightness to 0.5 when removing to restore it to a neutral color.
                }
            })
        }.onAppear() {
            UIScrollView.appearance().bounces = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                increase_brightness = false
                done_loading = true
                withAnimation(.spring(response: 0.3, dampingFraction: 0.55, blendDuration: 0.25)) {
                    show_alert.toggle()
                }
            }
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
        }
    }
}

var youtube_tabs = ["Featured", "Most Viewed", "Search", "Favorites", "More"]
struct YoutubeTabView : View {
    
    @Binding var selectedTab:String
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var done_loading: Bool
    var body: some View{
        GeometryReader {geometry in
            VStack(spacing:0) {
                
                ScrollView([], showsIndicators: false) {
                    ZStack {
                    Color.white.edgesIgnoringSafeArea(.all)
                        if done_loading == false {
                        HStack {
                            Spacer()
                            ProgressView().progressViewStyle(CircularProgressViewStyle())
                            Spacer().frame(width: 8)
                            Text("Loading...").font(.custom("Helvetica Neue Regular", size: 16)).foregroundColor(Color(red: 129/255, green: 129/255, blue: 129/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                            Spacer()
                            
                        }
                        } else {
                        Text("No Videos").foregroundColor(Color(red: 129/255, green: 129/255, blue: 129/255)).font(.custom("Helvetica Neue Regular", size: 16))
                        }
                    }
                }.background(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0), .init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0.5), .init(color: Color.white, location: 0.5), .init(color: Color.white, location: 1)]), startPoint: .top, endPoint: .bottom))
                // for bottom overflow...
                ZStack {
                    Rectangle().fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.02), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom)).frame(height:57)
                    HStack(spacing: 0){
                        
                        ForEach(youtube_tabs,id: \.self){image in
                            TabButton_Youtube(image: image, selectedTab: $selectedTab, geometry: geometry)
                            
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

struct TabButton_Youtube : View {
    
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
                        if image == "Featured" {
                            Image("UITabBarFeaturedSelected2").resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : image == "Most Viewed" ? 35.5 : 30.5, height: 30.5)
                        } else {
                            ZStack {
                                Image("\(image)_Store").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : image == "Most Viewed" ? 35.5 : 30.5, height: 30.5).overlay(
                                    LinearGradient(gradient: Gradient(colors: [Color(red: 205/255, green: 233/255, blue: 249/255), Color(red: 75/255, green: 220/255, blue: 251/255)]), startPoint: .top, endPoint: .bottom)
                                ).mask(Image("\(image)_Store").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : image == "Most Viewed" ? 35.5 : 30.5, height: 30.5)).offset(y:-0.5)
                                
                                Image("\(image)_Store").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : 30, height: 30).overlay(
                                    ZStack {
                                        LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 197/255, green: 210/255, blue: 229/255), location: 0), .init(color: Color(red: 99/255, green: 162/255, blue: 216/255), location: 0.47), .init(color: Color(red: 0/255, green: 145/255, blue: 230/255), location: 0.49), .init(color: Color(red: 21/255, green: 197/255, blue: 252/255), location: 1)]), startPoint: .top, endPoint: .bottom).rotationEffect(Angle(degrees: image == "More" ? 0 : -15)).frame(width: image == "More" ? 40 : 40, height: image == "Search" ? 38 : image == "Contacts" ? 34 : 30).brightness(0.095).offset(y: image == "Artists" ? 2 : 0)
                                        if image == "Featured" {
                                            VStack(spacing:0) {
                                                HStack(spacing:0) {
                                                    ZStack {
                                                        Ellipse().fill(LinearGradient(gradient: Gradient(stops:[.init(color: Color(red: 0/255, green: 145/255, blue: 230/255), location: 0), .init(color: Color(red: 21/255, green: 197/255, blue: 252/255), location: 1)]), startPoint: .top, endPoint: .bottom)).frame(width: 16, height: 12).offset(y:-1)
                                                    }
                                                    Spacer().frame(width: 7)
                                                    ZStack {
                                                        Ellipse().fill(Color(red: 185/255, green: 249/255, blue: 254/255)).frame(width: 16, height: 12).offset(y:-1)
                                                        Ellipse().fill(LinearGradient(gradient: Gradient(stops:[.init(color: Color(red: 0/255, green: 145/255, blue: 230/255), location: 0), .init(color: Color(red: 21/255, green: 197/255, blue: 252/255), location: 1)]), startPoint: .top, endPoint: .bottom)).frame(width: 16, height: 6).brightness(0.095).offset(y:1.5)
                                                    }
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                ).mask(Image("\(image)_Store").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : image == "Most Viewed" ? 35.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.6), radius:2.5, x: 0, y:2.5)
                            }
                        }
                        HStack {
                            if image != "Most Viewed" {
                                Spacer()
                            }
                            Text(image).foregroundColor(.white).font(.custom("Helvetica Neue Bold", size: image == "Most Viewed" ? 10.75 : 11)).fixedSize(horizontal: true, vertical: false)
                            if image != "Most Viewed" {
                                Spacer()
                            }
                        }.frame(maxWidth: geometry.size.width/5 - 5)
                    }
                } else {
                    VStack(spacing: 2) {
                        Image("\(image)_Store").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : image == "Most Viewed" ? 35.5 : 30, height: 30).overlay(
                            LinearGradient(gradient: Gradient(colors: [Color(red: 157/255, green: 157/255, blue: 157/255), Color(red: 89/255, green: 89/255, blue: 89/255)]), startPoint: .top, endPoint: .bottom)
                        ).mask(Image("\(image)_Store").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : image == "Most Viewed" ? 35.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.75), radius: 0, x: 0, y: -1)
                        HStack {
                            if image != "Most Viewed" {
                                Spacer()
                            }
                            Text(image).foregroundColor(Color(red: 168/255, green: 168/255, blue: 168/255)).font(.custom("Helvetica Neue Bold", size: image == "Most Viewed" ? 10.75 : 11)).fixedSize(horizontal: true, vertical: false)
                            if image != "Most Viewed" {
                                Spacer()
                            }
                        }.frame(maxWidth: geometry.size.width/5 - 5)
                    }
                }
            }
        }
    }
}
