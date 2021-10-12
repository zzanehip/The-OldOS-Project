//
//  Crypto.swift
//  OldOS
//
//  Created by Zane Kleinberg on 10/1/21.
//

import Foundation
import SwiftUI

struct Crypto: View {
    @State var current_nav_view: String = "My Wallet"
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
                    generic_title_bar(title: "Zane's Wallet").frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 60, maxHeight:60).zIndex(1).disabled(true)
                    CryptoTabView(selectedTab: $selectedTab, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, done_loading: $done_loading).clipped()
                }
            }.compositingGroup().clipped()
        }.onAppear() {
            UIScrollView.appearance().bounces = true
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
        }
    }
}


struct crypto_content: View {
    var up: String
    var money: String
    var body: some View {
        HStack {
            Spacer()
            Text(money).font(.custom("Helvetica Neue Regular", fixedSize: 18)).textCase(.uppercase).foregroundColor(.gray).padding(.trailing, 8)
            crypto_delta_capsule(content: up, color_indicator: 2 % 2 == 0 ? "green" : "red").frame(width: 90, height: 35).padding(.trailing, 8)
        }
    }
}

struct crypto_content_dest: View {
    var body: some View {
        HStack {
            Spacer()
            Image("UITableNext").padding(.trailing, 12)
        }
    }
}

var Crypto_tabs = ["My Wallet", "Discover", "Transactions", "Send", "More"]
struct CryptoTabView : View {
    var usage_section = [list_row(title: "ETH", image: "Ethereum-ETH-icon", content: AnyView(crypto_content(up: "4.3%", money: "$142.50")), destination: nil), list_row(title: "BTC", image: "1200px-Bitcoin.svg", content: AnyView(crypto_content(up: "1.2%", money: "$38.75")), destination: nil), list_row(title: "SOL", image: "exchange-black", content: AnyView(crypto_content(up: "6.4%", money: "$82.00")), destination: nil), list_row(title: "Savings", image: nil, content: AnyView(crypto_content_dest()), destination: nil)]
    @Binding var selectedTab:String
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var done_loading: Bool
    var body: some View{
        GeometryReader {geometry in
            VStack(spacing:0) {
                ZStack {
                    settings_main_list()
                ScrollView(showsIndicators: false) {
                        VStack {
                            Spacer().frame(height: 15)
                            HStack {
                                Text("Wallet ($263.25)").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                                Spacer()
                            }
                            list_section(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: usage_section)
                            Spacer().frame(height: 10)
                            HStack {
                                Text("Collectibles").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                                Spacer()
                            }
                            HStack {
                                VStack(spacing: 0) {
                                    Image("unnamed").resizable().scaledToFill().frame(width: geometry.size.width/2 - 18, height: geometry.size.height/3 - 45)
                                    HStack {
                                        Image("unnamed 2").resizable().scaledToFill().frame(width: 32, height: 32).clipCircle().padding(.leading, 8)
                                        Text("Pretentious Coffee").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).padding(.leading, 2)
                                        Spacer()
                                    }.background(Color.white.frame(width: geometry.size.width/2 - 18, height: 45)).frame(width: geometry.size.width/2 - 18, height: 45)
                                }.cornerRadius(10).frame(width: geometry.size.width/2 - 18, height: geometry.size.height/3).strokeRoundedRectangle(10, Color(red: 172/255, green: 172/255, blue: 172/255), lineWidth: 1.25).padding(.leading, 12)
                                Spacer()
                                VStack(spacing: 0) {
                                    Image("unnamed (1)").resizable().scaledToFill().frame(width: geometry.size.width/2 - 18, height: geometry.size.height/3 - 45)
                                    HStack {
                                        Image("unnamed 2").resizable().scaledToFill().frame(width: 32, height: 32).clipCircle().padding(.leading, 8)
                                        Text("Pretentious Coffee").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).padding(.leading, 2)
                                        Spacer()
                                    }.background(Color.white.frame(width: geometry.size.width/2 - 18, height: 45)).frame(width: geometry.size.width/2 - 18, height: 45)
                                }.cornerRadius(10).frame(width: geometry.size.width/2 - 18, height: geometry.size.height/3).strokeRoundedRectangle(10, Color(red: 172/255, green: 172/255, blue: 172/255), lineWidth: 1.25).padding(.trailing, 12)
                            }
                            Spacer()
                        }
                    
                }
                }
                // for bottom overflow...
                ZStack {
                    Rectangle().fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.02), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom)).frame(height:57)
                    HStack(spacing: 0){
                        
                        ForEach(Crypto_tabs,id: \.self){image in
                            TabButton_Crypto(image: image, selectedTab: $selectedTab, geometry: geometry)
                            
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

struct crypto_delta_capsule: View {
    var content: String
    var color_indicator: String
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if color_indicator == "green" {
                    RoundedRectangle(3).fill(LinearGradient([Color(red: 147/255, green: 192/255, blue: 107/255), Color(red: 118/255, green: 166/255, blue: 75/255)], from: .top, to: .bottom)).strokeRoundedRectangle(3, LinearGradient([Color(red: 119/255, green: 163/255, blue: 82/255), Color(red: 92/255, green: 139/255, blue: 56/255)], from: .top, to: .bottom), lineWidth: 2.5).frame(width: geometry.size.width, height: geometry.size.height)
                }
                if color_indicator == "red" {
                    RoundedRectangle(3).fill(LinearGradient([Color(red: 191/255, green: 91/255, blue: 80/255), Color(red: 168/255, green: 59/255, blue: 48/255)], from: .top, to: .bottom)).strokeRoundedRectangle(3, LinearGradient([Color(red: 164/255, green: 68/255, blue: 59/255), Color(red: 144/255, green: 44/255, blue: 34/255)], from: .top, to: .bottom), lineWidth: 2.5).frame(width: geometry.size.width, height: geometry.size.height)
                }
                HStack {
                    if color_indicator == "green" {
                    Image("UITintedCircularButtonPlus")
                    }
                    if color_indicator == "red" {
                        Rectangle().fill(Color.white).frame(width: 13.5, height: 3.5).shadow(color: Color.black.opacity(0.75), radius: 0.25, x: 0, y: -2/3).offset(x: 8.5)
                    }
                    Spacer()
                    Text(content).font(.custom("Helvetica Neue Bold", fixedSize: 20)).textCase(.uppercase).multilineTextAlignment(.trailing).foregroundColor(.white).shadow(color: Color.black.opacity(0.8), radius: 0.25, x: 0, y: -2/3).padding(.trailing, 5).minimumScaleFactor(0.5).lineLimit(0)
                }.frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}


struct TabButton_Crypto : View {
    
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
                                Image("\(image)_Crypto").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : image == "Most Viewed" ? 35.5 : 30.5, height: 30.5).overlay(
                                    LinearGradient(gradient: Gradient(colors: [Color(red: 205/255, green: 233/255, blue: 249/255), Color(red: 75/255, green: 220/255, blue: 251/255)]), startPoint: .top, endPoint: .bottom)
                                ).mask(Image("\(image)_Crypto").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : image == "Most Viewed" ? 35.5 : 30.5, height: 30.5)).offset(y:-0.5)
                                
                                Image("\(image)_Crypto").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : 30, height: 30).overlay(
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
                                ).mask(Image("\(image)_Crypto").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : image == "Most Viewed" ? 35.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.6), radius:2.5, x: 0, y:2.5)
                            }
                        }
                        HStack {
                            if image != "Most Viewed" {
                                Spacer()
                            }
                            Text(image).foregroundColor(.white).font(.custom("Helvetica Neue Bold", fixedSize: image == "Most Viewed" ? 10.75 : 11)).fixedSize(horizontal: true, vertical: false)
                            if image != "Most Viewed" {
                                Spacer()
                            }
                        }.frame(maxWidth: geometry.size.width/5 - 5)
                    }
                } else {
                    VStack(spacing: 2) {
                        Image("\(image)_Crypto").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : image == "Most Viewed" ? 35.5 : 30, height: 30).overlay(
                            LinearGradient(gradient: Gradient(colors: [Color(red: 157/255, green: 157/255, blue: 157/255), Color(red: 89/255, green: 89/255, blue: 89/255)]), startPoint: .top, endPoint: .bottom)
                        ).mask(Image("\(image)_Crypto").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : image == "Most Viewed" ? 35.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.75), radius: 0, x: 0, y: -1)
                        HStack {
                            if image != "Most Viewed" {
                                Spacer()
                            }
                            Text(image).foregroundColor(Color(red: 168/255, green: 168/255, blue: 168/255)).font(.custom("Helvetica Neue Bold", fixedSize: image == "Most Viewed" ? 10.75 : 11)).fixedSize(horizontal: true, vertical: false)
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
