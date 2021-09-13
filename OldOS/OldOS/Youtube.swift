//
//  Youtube.swift
//  OldOS
//
//  Created by Zane Kleinberg on 5/24/21.
//

import Foundation
import SwiftUI
import Alamofire
import SDWebImageSwiftUI
import Combine

struct Youtube: View {
    @StateObject var youtube_observer: YoutubeObserver = YoutubeObserver()
    @StateObject var most_viewed_observer: MostViewedObserver = MostViewedObserver()
    @StateObject var favorite_observer: favorite_videos_observer = favorite_videos_observer()
    @State var current_nav_view: String = "Main"
    @State var forward_or_backward: Bool = false
    @State var selectedTab = "Featured"
    @State var show_alert:Bool = false
    @State var increase_brightness: Bool = false
    @State var done_loading: Bool = false
    @State var selected_segment: Int = 0
    @State var search_results = [YouTubeVideoData]()
    @State var is_searching: Bool = false
    @State var featured_current_nav_view: String = "Main"
    @State var mv_current_nav_view: String = "Main"
    @State var fv_current_nav_view: String = "Main"
    @State var search_current_nav_view: String = "Main"
    @State var featured_current_video: YouTubeVideoData?
    @State var mv_current_video: YouTubeVideoData?
    @State var fv_current_video: YouTubeVideoData?
    @State var search_current_video: YouTubeVideoData?
    @State var currently_playing_video: YouTubeVideoData?
    @State var proxy: GeometryProxy?
    @State var selected_video_player: AVPlayer = AVPlayer()
    @State var show_video_player: Bool = false
    @State var instant_video_change: Bool = false
    @State var is_editing_favorites: Bool = false
    @Binding var instant_multitasking_change: Bool
    @ObservedObject private var volObserver = VolumeObserver()
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if instant_video_change {
                    containerYoutube(show_video_player: $show_video_player, instant_video_change: $instant_video_change, player: $selected_video_player).frame(width: geometry.size.width, height: geometry.size.height).zIndex(0)
                }
                    ZStack {
                        if show_video_player == false{
                        VStack {
                            status_bar_in_app().frame(minHeight: 24, maxHeight:24).zIndex(1)
                            Spacer()
                        }.transition(.asymmetric(insertion: .opacity, removal: .move(edge:.bottom)))
                        }
                        if show_video_player == false{
                        VStack(spacing:0) {
                            Spacer().frame(height: 24)
                            youtube_title_bar(title: (selectedTab == "Featured" && featured_current_nav_view == "Main") ? selectedTab : (selectedTab == "Featured" && featured_current_nav_view == "Video_Destination") ? featured_current_video?.title ?? "" : (selectedTab == "Featured" && featured_current_nav_view == "Video_Info") ? "More Info" : (selectedTab == "Most Viewed" && mv_current_nav_view == "Main") ? selectedTab : (selectedTab == "Most Viewed" && mv_current_nav_view == "Video_Destination") ? mv_current_video?.title ?? "" : (selectedTab == "Most Viewed" && mv_current_nav_view == "Video_Info") ? "More Info" : (selectedTab == "Search" && search_current_nav_view == "Main") ? selectedTab : (selectedTab == "Search" && search_current_nav_view == "Video_Destination") ? search_current_video?.title ?? "" : (selectedTab == "Search" && search_current_nav_view == "Video_Info") ? "More Info" : (selectedTab == "Favorites" && fv_current_nav_view == "Main") ? selectedTab : (selectedTab == "Favorites" && fv_current_nav_view == "Video_Destination") ? fv_current_video?.title ?? "" : (selectedTab == "Favorites" && fv_current_nav_view == "Video_Info") ? "More Info" : selectedTab, selectedTab: $selectedTab, selected_segment: $selected_segment, instant_multitasking_change: $instant_multitasking_change, search_results: $search_results, is_searching: $is_searching, forward_or_backward: $forward_or_backward, featured_current_nav_view: $featured_current_nav_view, mv_current_nav_view: $mv_current_nav_view, fv_current_nav_view: $fv_current_nav_view, search_current_nav_view: $search_current_nav_view, instant_video_change: $instant_video_change, is_editing_favorites: $is_editing_favorites, editing_favorites_action: {
                                withAnimation() {
                                    is_editing_favorites.toggle()
                                }
                            }).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 60, maxHeight:60).zIndex(1)
                            YoutubeTabView(youtube_observer: youtube_observer, most_viewed_observer: most_viewed_observer, favorite_observer: favorite_observer, selectedTab: $selectedTab, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, done_loading: $done_loading, selected_segment: $selected_segment, search_results: $search_results, is_searching: $is_searching, featured_current_nav_view: $featured_current_nav_view, mv_current_nav_view: $mv_current_nav_view, fv_current_nav_view: $fv_current_nav_view, search_current_nav_view: $search_current_nav_view, featured_current_video: $featured_current_video, mv_current_video: $mv_current_video, fv_current_video: $fv_current_video, search_current_video: $search_current_video, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player, is_editing_favorites: $is_editing_favorites).clipped()
                        }.transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom)))
                        }
                    }.zIndex(1)
            }.compositingGroup().clipped()
        }.onAppear() {
            UIScrollView.appearance().bounces = true
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
        }
        
    }
}

var youtube_tabs = ["Featured", "Most Viewed", "Search", "Favorites", "More"]
struct YoutubeTabView : View {
    @StateObject var youtube_observer: YoutubeObserver
    @StateObject var most_viewed_observer: MostViewedObserver
    @StateObject var favorite_observer: favorite_videos_observer
    @Binding var selectedTab:String
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var done_loading: Bool
    @Binding var selected_segment: Int
    @Binding var search_results: [YouTubeVideoData]
    @Binding var is_searching: Bool
    @Binding var featured_current_nav_view: String
    @Binding var mv_current_nav_view: String
    @Binding var fv_current_nav_view: String
    @Binding var search_current_nav_view: String
    @Binding var featured_current_video: YouTubeVideoData?
    @Binding var mv_current_video: YouTubeVideoData?
    @Binding var fv_current_video: YouTubeVideoData?
    @Binding var search_current_video: YouTubeVideoData?
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @Binding var selected_video_player: AVPlayer
    @Binding var is_editing_favorites: Bool
    var body: some View{
        GeometryReader {geometry in
            VStack(spacing:0) {
                
                ScrollView([], showsIndicators: false) {
                    switch selectedTab {
                    case "Featured":
                        YoutubeFeaturedView(youtube_observer: youtube_observer, favorite_observer: favorite_observer, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, featured_current_nav_view: $featured_current_nav_view, featured_current_video: $featured_current_video, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player).frame(height: geometry.size.height - 57).tag("Featured").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Most Viewed":
                        YoutubeMostViewedView(most_viewed_observer: most_viewed_observer, favorite_observer: favorite_observer, mv_current_nav_view: $mv_current_nav_view, mv_current_video: $mv_current_video, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, selected_segment: $selected_segment, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player).frame(height: geometry.size.height - 57).tag("Most Viewed").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Search":
                        YoutubeSearchView(favorite_observer: favorite_observer, search_current_nav_view: $search_current_nav_view, search_current_video: $search_current_video, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, search_results: $search_results, is_searching: $is_searching, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player).frame(height: geometry.size.height - 57).tag("Search").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Favorites":
                        YoutubeFavoriteView(favorite_observer: favorite_observer, fv_current_nav_view: $fv_current_nav_view, fv_current_video: $fv_current_video, is_editing_favorites: $is_editing_favorites, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player).frame(height: geometry.size.height - 57).tag("Favorites").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "More":
                        youtube_more().frame(height: geometry.size.height - 57).tag("More").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    default:
                        YoutubeFeaturedView(youtube_observer: youtube_observer, favorite_observer: favorite_observer, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, featured_current_nav_view: $featured_current_nav_view, featured_current_video: $featured_current_video, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player).frame(height: geometry.size.height - 57).tag("Featured").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
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
import AVFoundation
struct player_test: View {
    @State var player = AVPlayer(url: URL(string: "https://r1---sn-vgqs7nly.googlevideo.com/videoplayback?expire=1629081499&ei=OnsZYfKQO4zNuAKfpojIAg&ip=107.178.237.6&id=o-AF6w1T2QjFauxYrlIeOyCbl_UQ2ahTVwd9KZYtmOMTM2&itag=22&source=youtube&requiressl=yes&vprv=1&mime=video%2Fmp4&ns=SBT0QS4TNrGDT49vrGpMkBwG&cnr=14&ratebypass=yes&dur=1194.550&lmt=1628954646720174&fexp=9466585,24001373,24007246&beids=9466585&c=WEB&txp=5516222&n=Kn_U2Y73ohwVbbBTlx1&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cvprv%2Cmime%2Cns%2Ccnr%2Cratebypass%2Cdur%2Clmt&sig=AOq0QJ8wRgIhAILaKVvw6gOgE6vtwWyQg1ViOxN_GleoCnxbZ8eAhVxVAiEAgfDbceNF6H3xSC37xij_xTE9gYJYg-qX9pA6yufVnA0%3D&redirect_counter=1&cm2rm=sn-qxos67z&req_id=fa0406c7e4aba3ee&cms_redirect=yes&mh=61&mip=47.20.27.224&mm=34&mn=sn-vgqs7nly&ms=ltu&mt=1629059630&mv=u&mvi=1&pl=23&lsparams=mh,mip,mm,mn,ms,mv,mvi,pl&lsig=AG3C_xAwRQIhAJQ3vVKO8IE9O4t4yQxj8GhsoYHKm6BxVzCqzvbOptqBAiBaBvie7gp2D-N2W_GjinOPA3G4P6T0ECefvWF5L7WixA%3D%3D") ?? URL(string: "google.com")!)
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                PlayerContainerView(player: player, gravity: .fit).frame(width: geometry.size.width, height:geometry.size.height)
            }.background(Color.white)
        }
    }
}

struct YoutubeVideoInfoView: View {
    @State var selected: Int = 0
    @State var comments: YoutubeVideoComments?
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var current_video: YouTubeVideoData?
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                settings_main_list()
                ScrollView(showsIndicators: true) {
                    VStack {
                        Spacer().frame(height: 15)
                        
                        dual_segmented_control_big_bluegray(selected: $selected, first_text: "Info", second_text: "More Videos", should_animate: false).frame(width: geometry.size.width-24, height: 45)
                        
                        Spacer().frame(height:15)
                        VStack {
                            Text(current_video?.description ?? "").font(.custom("Helvetica Neue Regular", size: 13)).fixedSize(horizontal: false, vertical: true).padding([.top, .leading, .trailing]).padding(.bottom, 3)
                            Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                            HStack(alignment: .top) {
                                HStack(alignment: .top, spacing: 0) {
                                    Spacer()
                                    Text("Added").multilineTextAlignment(.trailing).font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255))
                                }.frame(width: geometry.size.width/5)
                                Text(current_video?.uploaded?.text ?? "").font(.custom("Helvetica Neue Regular", size: 13)).foregroundColor(.black)
                                Spacer()
                            }.padding([.top, .bottom], 3)
                            Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                            HStack(alignment: .top) {
                                HStack(alignment: .top, spacing: 0) {
                                    Spacer()
                                    Text("Category").multilineTextAlignment(.trailing).font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255))
                                }.frame(width: geometry.size.width/5)
                                Text(current_video?.category ?? "").font(.custom("Helvetica Neue Regular", size: 13)).foregroundColor(.black)//fix to formated current release version
                                Spacer()
                            }.padding([.top, .bottom], 3)
                            Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                            HStack(alignment: .top) {
                                HStack(alignment: .top, spacing: 0) {
                                    Spacer()
                                    Text("Tags").multilineTextAlignment(.trailing).font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255))
                                }.frame(width: geometry.size.width/5)
                                Text((current_video?.keywords ?? []).map{String($0)}.joined(separator: ", ")).font(.custom("Helvetica Neue Regular", size: 13)).foregroundColor(.black)//fix to formated current release version
                                Spacer()
                            }.padding([.top], 3).padding(.bottom)
                        }.background(Color.white.cornerRadius(10)).cornerRadius(10).strokeRoundedRectangle(10, Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1).padding([.leading, .trailing], 12)
                        
                        Spacer().frame(height: 15)
                        HStack {
                            Spacer()
                            Text("Rate, Comment or Flag").foregroundColor(.black).font(.custom("Helvetica Neue Bold", size: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                            Spacer()
                        }.frame(height: 50).background(Color.white.cornerRadius(10)).cornerRadius(10).strokeRoundedRectangle(10, Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1).padding([.leading, .trailing], 12)
                        Spacer().frame(height: 10)
                        
                        VStack(spacing:0) {
                            ForEach(comments?.comments ?? [], id:\.commentID) { comment in
                                ZStack {
                                    Rectangle().fill(((comments?.comments ?? []).firstIndex(where: {$0.commentID == comment.commentID}) ?? 0) % 2 == 0 ? Color(red: 242/255, green: 242/255, blue: 242/255) : Color(red: 255/255, green: 255/255, blue: 255/255))
                                    VStack(spacing: 0) {
                                        Spacer()
                                        HStack {
                                            Text(comment.author ?? "").font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(Color(red: 165/255, green: 65/255, blue: 35/255)).padding([.leading, .trailing])
                                            Spacer()
                                            Text((comment.time ?? "").startcased()).font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).padding([.leading, .trailing])
                                        }
                                        Spacer().frame(height: 10)
                                        Text(comment.text ?? "").font(.custom("Helvetica Neue Regular", size: 13)).foregroundColor(.black).padding([.leading, .trailing])
                                        Spacer()
                                        if comment.commentID != (comments?.comments ?? []).last?.commentID {
                                            Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                                        }
                                    }.frame(minHeight: 90)
                                }.frame(minHeight: 90)
                            }
                        }.background(Color.white.cornerRadius(10)).cornerRadius(10).strokeRoundedRectangle(10, Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1).padding([.leading, .trailing], 12)
                        Spacer().frame(height: 10)
                    }
                }
            }
        }.onAppear() {
            fetch_comment_data(id: current_video?.id ?? "", completion: {result in
                comments = result
            })
        }
    }
}

extension StringProtocol {
    func startcased() -> String {
        components(separatedBy: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

struct YoutubeDetailView: View {
    @StateObject var favorite_observer: favorite_videos_observer
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var current_video: YouTubeVideoData?
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                settings_main_list()
                ScrollView(showsIndicators: true) {
                    VStack {
                        Spacer().frame(height: 20)
                        VStack(spacing: 0) {
                            let like_count = Int((current_video?.ratings?.likes?.text ?? "").filter("0123456789.".contains)) ?? 1
                            let dislike_count = Int((current_video?.ratings?.dislikes?.text ?? "").filter("0123456789.".contains)) ?? 1
                            let view_count = (current_video?.views?.text ?? "").filter("0123456789.".contains) ?? ""
                            let duration = Double((current_video?.duration?.lengthSec ?? "").filter("0123456789.".contains) ?? "") ?? 0
                            HStack {
                                
                                WebImage(url: current_video?.thumbnails?[optional: 0]?.url).resizable().placeholder {
                                    Image("DefaultThumbnail")
                                }.aspectRatio(contentMode: .fit).frame(width:geometry.size.width/3.75, height: 60).background(Color.black).padding(.leading, 6).cornerRadius(4)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(current_video?.title ?? "---").font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(.black).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                                    HStack(alignment: .top, spacing: 2.5) {
                                        Image("thumbsUp").offset(y: -4.5)
                                        Text("\(Int(Float(like_count)/(Float(like_count) + Float(dislike_count))*100))%").font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(Color(red: 73/255, green: 128/255, blue: 35/255))
                                        Text(view_count + " views").font(.custom("Helvetica Neue Regular", size: 13)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255))
                                        
                                        
                                        Spacer()
                                    }.offset(y: 4).padding(.bottom, 4)
                                    HStack() {
                                      
                                        
                                        
                                        Text(duration.asString(style: .positional)).font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(.black).lineLimit(1).onAppear() {
                             
                                        }
                                      
                                        Text(current_video?.channel?.name ?? "---").font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).lineLimit(1)
                                    }
                                }
                                Spacer()
                                Button(action: {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Video_Info"}
                                    }
                                }) {
                                    Image("ABTableNextButton").padding(.trailing, 12)
                                }
                            }
                        }.frame(height: 90).background(Color.white.cornerRadius(10)).cornerRadius(10).strokeRoundedRectangle(10, Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1).padding([.leading, .trailing], 12)
                        Spacer().frame(height:10)
                        HStack(spacing: 0) {
                            Button(action: {
                                if favorite_observer.favorites.contains(current_video?.id ?? "") == false {
                                    favorite_observer.favorites.append(current_video?.id ?? "")
                                }
                            }) {
                            list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: [list_row(title: "", content: AnyView(multiline_text_content(first_line: "Add to", second_line: "Favorites")))])
                            }
                            list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: [list_row(title: "", content: AnyView(multiline_text_content(first_line: "Add to", second_line: "Playlist")))])
                            list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: [list_row(title: "", content: AnyView(multiline_text_content(first_line: "Share", second_line: "Video")))])
                        }
                        Spacer().frame(height: 20)
                        HStack {
                            Text("Related Videos").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", size: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        Spacer().frame(height: 10)
                        HStack {
                            Spacer()
                            Text("No Related Videos").foregroundColor(Color(red: 56/255, green: 95/255, blue: 210/255)).font(.custom("Helvetica Neue Bold", size: 17))
                            Spacer()
                        }.frame(height: 90).background(Color.white.cornerRadius(10)).cornerRadius(10).strokeRoundedRectangle(10, Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1).padding([.leading, .trailing], 12)
                        Spacer()
                    }
                }
            }
        }
    }
}

struct YoutubeFeaturedView: View {
    @StateObject var youtube_observer: YoutubeObserver
    @StateObject var favorite_observer: favorite_videos_observer
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var featured_current_nav_view: String
    @Binding var featured_current_video: YouTubeVideoData?
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @Binding var selected_video_player: AVPlayer
    var body: some View {
        GeometryReader { geometry in
            switch featured_current_nav_view {
            case "Main":
                VStack(spacing:0) {
                    ScrollView(showsIndicators: true) {
                        
                        VStack {
                            if youtube_observer.featured.isEmpty || youtube_observer.featured_stats.isEmpty || youtube_observer.featured_details.isEmpty {
                                HStack {
                                    Spacer()
                                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                                    Spacer().frame(width: 8)
                                    Text("Loading...").font(.custom("Helvetica Neue Regular", size: 16)).foregroundColor(Color(red: 129/255, green: 129/255, blue: 129/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                                    Spacer()
                                    
                                }.frame(width: geometry.size.width, height: geometry.size.height)
                            } else {
                                VStack(spacing:0){
                                    ForEach(youtube_observer.featured, id:\.id) { video in
                                        let like_count = Int(youtube_observer.featured_stats[optional: youtube_observer.featured_stats.firstIndex(where: {$0.id == video.id}) ?? 0]?.statistics.likeCount ?? "") ?? 1
                                        let dislike_count = Int(youtube_observer.featured_stats[optional: youtube_observer.featured_stats.firstIndex(where: {$0.id == video.id}) ?? 0]?.statistics.dislikeCount ?? "") ?? 1
                                        let view_count = youtube_observer.featured_stats[optional: youtube_observer.featured_stats.firstIndex(where: {$0.id == video.id}) ?? 0]?.statistics.viewCount ?? ""
                                        let duration = youtube_observer.featured_details[optional: youtube_observer.featured_details.firstIndex(where: {$0.id == video.id}) ?? 0]?.contentDetails.duration ?? ""
                                        Button(action:{
                                            fetch_searched_video(id: video.id, completion: {result in
                                                let url = result.streams?.formats?.first?.url
                                                selected_video_player = AVPlayer(url: result.streams?.formats?.first?.url ?? URL(string: "google.com")!)
                                                instant_video_change = true; withAnimation(.linear(duration: 0.4)) {show_video_player = true}
                                            })
                                            
                                            
                                        }) {
                                            VStack(spacing: 0) {
                                                HStack {
                                                    WebImage(url: video.snippet.thumbnails.medium.url).resizable().placeholder {
                                                        Image("DefaultThumbnail")
                                                    }.aspectRatio(contentMode: .fit).frame(width:geometry.size.width/3, height: 89).background(Color.black).border_top(width: 1, edges:[.trailing], color: Color(red: 217/255, green: 217/255, blue: 217/255))
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(video.snippet.title ?? "---").font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(.black).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                                                        HStack(alignment: .top, spacing: 2.5) {
                                                            Image("thumbsUp").offset(y: -4.5)
                                                            Text("\(Int(Float(like_count)/(Float(like_count) + Float(dislike_count))*100))%").font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(Color(red: 73/255, green: 128/255, blue: 35/255))
                                                            Text(view_count + " views").font(.custom("Helvetica Neue Regular", size: 13)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255))
                                                            
                                                            
                                                            Spacer()
                                                        }.offset(y: 4).padding(.bottom, 4)
                                                        HStack() {
                                          
                                                            
                                                            
                                                            Text(duration.getYoutubeFormattedDuration()).font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(.black).lineLimit(1).onAppear() {
                                                          
                                                            }
                                          
                                                            Text(video.snippet.channelTitle ?? "---").font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).lineLimit(1)
                                                        }
                                                    }
                                                    Spacer()
                                                    Button(action: {
                                                        fetch_searched_video(id: video.id, completion: {result in
                                                            featured_current_video = result
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                                                forward_or_backward = false; withAnimation(.linear(duration: 0.28)){featured_current_nav_view = "Video_Destination"}
                                                            }
                                                        })
                                                    }) {
                                                        Image("ABTableNextButton").padding(.trailing, 12)
                                                    }
                                                }
                                    
                                                Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)

                                            }.frame(height: 90)
                                        }.frame(height: 90).buttonStyle(BlankButtonStyle())
                                    }
                                }.background(Color.white)
                              
                            }
                          
                        }
                        
                    }
                }.transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Video_Destination":
                YoutubeDetailView(favorite_observer: favorite_observer, current_nav_view: $featured_current_nav_view, forward_or_backward: $forward_or_backward, current_video: featured_current_video).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Video_Info":
                YoutubeVideoInfoView(current_nav_view: $featured_current_nav_view, forward_or_backward: $forward_or_backward, current_video: featured_current_video).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            default:
                Spacer()
            }
        }.background(Color.white)
    }
}

struct YoutubeMostViewedView: View {
    @StateObject var most_viewed_observer: MostViewedObserver
    @StateObject var favorite_observer: favorite_videos_observer
    @Binding var mv_current_nav_view: String
    @Binding var mv_current_video: YouTubeVideoData?
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var selected_segment: Int
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @Binding var selected_video_player: AVPlayer
    var body: some View {
        GeometryReader { geometry in
            switch mv_current_nav_view {
            case "Main":
                VStack(spacing:0) {
                    ScrollView(showsIndicators: true) {
                        result_content_view(current_nav_view: $mv_current_nav_view, current_video: $mv_current_video, forward_or_backward: $forward_or_backward, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player, content: selected_segment == 0 ? most_viewed_observer.today : selected_segment == 1 ? most_viewed_observer.this_week : most_viewed_observer.all_time, geometry: geometry, placeholder_content: {
                            HStack {
                                Spacer()
                                ProgressView().progressViewStyle(CircularProgressViewStyle())
                                Spacer().frame(width: 8)
                                Text("Loading...").font(.custom("Helvetica Neue Regular", size: 16)).foregroundColor(Color(red: 129/255, green: 129/255, blue: 129/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                                Spacer()
                                
                            }.frame(width: geometry.size.width, height: geometry.size.height)
                        })
                    }
                    
                }.background(Color.white).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Video_Destination":
                YoutubeDetailView(favorite_observer: favorite_observer, current_nav_view: $mv_current_nav_view, forward_or_backward: $forward_or_backward, current_video: mv_current_video).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Video_Info":
                YoutubeVideoInfoView(current_nav_view: $mv_current_nav_view, forward_or_backward: $forward_or_backward, current_video: mv_current_video).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            default:
                Spacer()
            }
        }
    }
}

struct YoutubeSearchView: View {
    @StateObject var favorite_observer: favorite_videos_observer
    @Binding var search_current_nav_view: String
    @Binding var search_current_video: YouTubeVideoData?
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var search_results: [YouTubeVideoData]
    @Binding var is_searching: Bool
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @Binding var selected_video_player: AVPlayer
    var body: some View {
        GeometryReader { geometry in
            switch search_current_nav_view {
            case "Main":
                VStack(spacing:0) {
                    ScrollView(showsIndicators: true) {
                        result_content_view(current_nav_view: $search_current_nav_view, current_video: $search_current_video, forward_or_backward: $forward_or_backward, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player, content: search_results, geometry: geometry, placeholder_content: {
                            if is_searching {
                                HStack {
                                    Spacer()
                                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                                    Spacer().frame(width: 8)
                                    Text("Loading...").font(.custom("Helvetica Neue Regular", size: 16)).foregroundColor(Color(red: 129/255, green: 129/255, blue: 129/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                                    Spacer()
                                    
                                }.frame(width: geometry.size.width, height: geometry.size.height)
                            } else {
                                HStack {
                                    Spacer()
                                    Text("No Videos").font(.custom("Helvetica Neue Regular", size: 16)).foregroundColor(Color(red: 129/255, green: 129/255, blue: 129/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                                    Spacer()
                                    
                                }.frame(width: geometry.size.width, height: geometry.size.height)
                            }
                        })
                    }
                }.transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Video_Destination":
                YoutubeDetailView(favorite_observer: favorite_observer, current_nav_view: $search_current_nav_view, forward_or_backward: $forward_or_backward, current_video: search_current_video).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Video_Info":
                YoutubeVideoInfoView(current_nav_view: $search_current_nav_view, forward_or_backward: $forward_or_backward, current_video: search_current_video).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            default:
                Spacer()
            }
        }.background(Color.white)
    }
}


struct result_content_view<PlaceholderContent: View>: View {
    @Binding var current_nav_view: String
    @Binding var current_video: YouTubeVideoData?
    @Binding var forward_or_backward: Bool
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @Binding var selected_video_player: AVPlayer
    var content: [YouTubeVideoData]
    var geometry: GeometryProxy
    var placeholder_content: PlaceholderContent
    init(current_nav_view: Binding<String>, current_video: Binding<YouTubeVideoData?>, forward_or_backward: Binding<Bool>, show_video_player: Binding<Bool>, instant_video_change: Binding<Bool>, selected_video_player: Binding<AVPlayer>, content:  [YouTubeVideoData], geometry: GeometryProxy, @ViewBuilder placeholder_content: @escaping () -> PlaceholderContent) {
        _current_nav_view = current_nav_view
        _current_video = current_video
        _forward_or_backward = forward_or_backward
        _show_video_player = show_video_player
        _instant_video_change = instant_video_change
        _selected_video_player = selected_video_player
        self.placeholder_content = placeholder_content()
        self.content = content
        self.geometry = geometry
    }
    var body: some View {
        VStack {
            if content.isEmpty {
               
                placeholder_content
          
            } else {
                VStack(spacing:0){
                    ForEach(content, id:\.id) { video in
                        let like_count = Int((content[optional: content.firstIndex(where: {$0.id == video.id}) ?? 0]?.ratings?.likes?.text ?? "").filter("0123456789.".contains)) ?? 1
                        let dislike_count = Int((content[optional: content.firstIndex(where: {$0.id == video.id}) ?? 0]?.ratings?.dislikes?.text ?? "").filter("0123456789.".contains)) ?? 1
                        let view_count = (content[optional: content.firstIndex(where: {$0.id == video.id}) ?? 0]?.views?.text ?? "").filter("0123456789.".contains) ?? ""
                        let duration = Double((content[optional: content.firstIndex(where: {$0.id == video.id}) ?? 0]?.duration?.lengthSec ?? "").filter("0123456789.".contains) ?? "") ?? 0
                        Button(action:{
                            let url = video.streams?.formats?.first?.url
                            selected_video_player = AVPlayer(url: video.streams?.formats?.first?.url ?? URL(string: "google.com")!)
                            instant_video_change = true; withAnimation(.linear(duration: 0.4)) {show_video_player = true}
                            
                        }) {
                            VStack(spacing: 0) {
                                HStack {
                                    
                                    WebImage(url: video.thumbnails?[optional: 0]?.url).resizable().placeholder {
                                        Image("DefaultThumbnail")
                                    }.aspectRatio(contentMode: .fit).frame(width:geometry.size.width/3, height: 89).background(Color.black).border_top(width: 1, edges:[.trailing], color: Color(red: 217/255, green: 217/255, blue: 217/255))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(video.title ?? "---").font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(.black).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                                        HStack(alignment: .top, spacing: 2.5) {
                                            Image("thumbsUp").offset(y: -4.5)
                                            Text("\(Int(Float(like_count)/(Float(like_count) + Float(dislike_count))*100))%").font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(Color(red: 73/255, green: 128/255, blue: 35/255))
                                            Text(view_count + " views").font(.custom("Helvetica Neue Regular", size: 13)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255))
                                            
                                            
                                            Spacer()
                                        }.offset(y: 4).padding(.bottom, 4)
                                        HStack() {
                                       
                                            
                                            
                                            Text(duration.asString(style: .positional)).font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(.black).lineLimit(1).onAppear() {
                                               
                                            }
                                            
                                            Text(video.channel?.name ?? "---").font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    Button(action: {
                                        current_video = video
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                            forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Video_Destination"}
                                        }
                                    }) {
                                        Image("ABTableNextButton").padding(.trailing, 12)
                                    }
                                }
                              
                                Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
            
                                
                            }.frame(height: 90)
                        }.frame(height: 90).buttonStyle(BlankButtonStyle())
                    }
                }.background(Color.white)
           
            }
         
        }
        
    }
}

struct result_content_view_favorites<PlaceholderContent: View>: View {
    @State var to_delete: String = ""
    @StateObject var favorite_observer: favorite_videos_observer
    @Binding var is_editing_favorites: Bool
    @Binding var current_nav_view: String
    @Binding var current_video: YouTubeVideoData?
    @Binding var forward_or_backward: Bool
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @Binding var selected_video_player: AVPlayer
    var content: [YouTubeVideoData]
    var geometry: GeometryProxy
    var placeholder_content: PlaceholderContent
    init(favorite_observer: StateObject<favorite_videos_observer>, is_editing_favorites: Binding<Bool>, current_nav_view: Binding<String>, current_video: Binding<YouTubeVideoData?>, forward_or_backward: Binding<Bool>, show_video_player: Binding<Bool>, instant_video_change: Binding<Bool>, selected_video_player: Binding<AVPlayer>, content:  [YouTubeVideoData], geometry: GeometryProxy, @ViewBuilder placeholder_content: @escaping () -> PlaceholderContent) {
        _is_editing_favorites = is_editing_favorites
        _current_nav_view = current_nav_view
        _current_video = current_video
        _forward_or_backward = forward_or_backward
        _show_video_player = show_video_player
        _instant_video_change = instant_video_change
        _selected_video_player = selected_video_player
        self.placeholder_content = placeholder_content()
        self.content = content
        self.geometry = geometry
        _favorite_observer = favorite_observer
    }
    var body: some View {
        VStack {
            if content.isEmpty {
              
                placeholder_content
              
            } else {
                VStack(spacing:0){
                    ForEach(content, id:\.id) { video in
                        let like_count = Int((content[optional: content.firstIndex(where: {$0.id == video.id}) ?? 0]?.ratings?.likes?.text ?? "").filter("0123456789.".contains)) ?? 1
                        let dislike_count = Int((content[optional: content.firstIndex(where: {$0.id == video.id}) ?? 0]?.ratings?.dislikes?.text ?? "").filter("0123456789.".contains)) ?? 1
                        let view_count = (content[optional: content.firstIndex(where: {$0.id == video.id}) ?? 0]?.views?.text ?? "").filter("0123456789.".contains) ?? ""
                        let duration = Double((content[optional: content.firstIndex(where: {$0.id == video.id}) ?? 0]?.duration?.lengthSec ?? "").filter("0123456789.".contains) ?? "") ?? 0
                        Button(action:{
                            if !is_editing_favorites {
                            let url = video.streams?.formats?.first?.url
                            selected_video_player = AVPlayer(url: video.streams?.formats?.first?.url ?? URL(string: "google.com")!)
                            instant_video_change = true; withAnimation(.linear(duration: 0.4)) {show_video_player = true}
                            }
                            
                        }) {
                            VStack(spacing: 0) {
                                HStack {
                                    if is_editing_favorites == true {
                                        Button(action:{
                                            withAnimation(.linear(duration:0.15)) {
                                                if to_delete != video.id ?? "" {
                                                to_delete = video.id ?? ""
                                                } else {
                                                    to_delete = ""
                                                }
                                            }
                                        }) {
                                            ZStack {
                                            Image("UIRemoveControlMinus")
                                                Text("—").foregroundColor(.white).font(.system(size: 15, weight: .heavy, design: .default)).offset(y:to_delete == video.id ? -0.8 : -2).rotationEffect(.degrees(to_delete == video.id ? -90 : 0), anchor: .center).offset(y:to_delete == video.id ? -0.5 : 0)
                                            }
                                        }.transition(AnyTransition.asymmetric(insertion: .move(edge:.leading), removal: .move(edge:.leading)).combined(with: .opacity)).offset(x:-2).padding(.leading, 5)
                                    }
                                    WebImage(url: video.thumbnails?[optional: 0]?.url).resizable().placeholder {
                                        Image("DefaultThumbnail")
                                    }.aspectRatio(contentMode: .fit).frame(width:geometry.size.width/3, height: 89).background(Color.black).border_top(width: 1, edges:[.trailing], color: Color(red: 217/255, green: 217/255, blue: 217/255))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(video.title ?? "---").font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(.black).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                                        HStack(alignment: .top, spacing: 2.5) {
                                            Image("thumbsUp").offset(y: -4.5)
                                            Text("\(Int(Float(like_count)/(Float(like_count) + Float(dislike_count))*100))%").font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(Color(red: 73/255, green: 128/255, blue: 35/255))
                                            Text(view_count + " views").font(.custom("Helvetica Neue Regular", size: 13)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).lineLimit(0)
                                            
                                            
                                            Spacer()
                                        }.offset(y: 4).padding(.bottom, 4)
                                        HStack() {
                           
                                            
                                            
                                            Text(duration.asString(style: .positional)).font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(.black).lineLimit(1).onAppear() {
                                 
                                            }
                                          
                                            Text(video.channel?.name ?? "---").font(.custom("Helvetica Neue Bold", size: 13)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    if !is_editing_favorites {
                                    Button(action: {
                                        if !is_editing_favorites {
                                        current_video = video
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                            forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Video_Destination"}
                                        }
                                        }
                                    }) {
                                        Image("ABTableNextButton").padding(.trailing, 12)
                                    }
                                    }
                                    if to_delete == video.id ?? "", is_editing_favorites == true {
                                        Spacer()
                                        tool_bar_rectangle_button(action: {withAnimation() {
                                            if let idx = favorite_observer.favorites.firstIndex(where: {$0 == video.id}) {
                                                favorite_observer.favorites.remove(at: idx)
                                            }
                                            if let idx = favorite_observer.videos.firstIndex(where: {$0.id == video.id}) {
                                                favorite_observer.videos.remove(at: idx)
                                            }
                                        }}, button_type: .red, content: "Delete").padding(.trailing, 12).transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge:.trailing)).combined(with: .opacity))
                                    }
                                }
                             
                                Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                
                                
                            }.frame(height: 90)
                        }.frame(height: 90).buttonStyle(BlankButtonStyle())
                    }
                }.background(Color.white)

            }
     
        }
        
    }
}

struct YoutubeFavoriteView: View {
    @StateObject var favorite_observer: favorite_videos_observer
    @Binding var fv_current_nav_view: String
    @Binding var fv_current_video: YouTubeVideoData?
    @Binding var is_editing_favorites: Bool
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @Binding var selected_video_player: AVPlayer
    var body: some View {
        GeometryReader { geometry in
            switch fv_current_nav_view {
            case "Main":
                VStack(spacing:0) {
                    ScrollView(showsIndicators: true) {
                        result_content_view_favorites(favorite_observer: _favorite_observer, is_editing_favorites: $is_editing_favorites, current_nav_view: $fv_current_nav_view, current_video: $fv_current_video, forward_or_backward: $forward_or_backward, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player, content: favorite_observer.videos, geometry: geometry, placeholder_content: {
                            HStack {
                                Spacer()
                                Text("No Videos").font(.custom("Helvetica Neue Regular", size: 16)).foregroundColor(Color(red: 129/255, green: 129/255, blue: 129/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                                Spacer()
                                
                            }.frame(width: geometry.size.width, height: geometry.size.height)
                        })
                    }
                    
                }.background(Color.white).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Video_Destination":
                YoutubeDetailView(favorite_observer: favorite_observer, current_nav_view: $fv_current_nav_view, forward_or_backward: $forward_or_backward, current_video: fv_current_video).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Video_Info":
                YoutubeVideoInfoView(current_nav_view: $fv_current_nav_view, forward_or_backward: $forward_or_backward, current_video: fv_current_video).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            default:
                Spacer()
            }
        }
    }
}

class favorite_videos_observer: ObservableObject {
    @Published var favorites: [String] {
        didSet {
            let count = (UserDefaults.standard.object(forKey: "yt_favorites") as? [String] ?? []).count
            UserDefaults.standard.set(favorites, forKey: "yt_favorites")
            if count < favorites.count {
            refresh()
            }
        }
    }
    @Published var videos = [YouTubeVideoData]()
    
    init() {
        self.favorites = UserDefaults.standard.object(forKey: "yt_favorites") as? [String] ?? []
        for favorite in self.favorites {
            fetch_searched_video(id: favorite, completion: {result in
                self.videos.append(result)
            })
        }
        
    }
    func refresh() {
        var favorite = favorites.last
            fetch_searched_video(id: favorite ?? "", completion: {result in
                self.videos.append(result)
            })
        
    }
}

struct youtube_more_item: Identifiable {
    let id = UUID()
    let name: String
    let image: String
}

struct youtube_more: View {
    var items = [youtube_more_item(name: "Most Recent", image: "YTBarMostRecent"), youtube_more_item(name: "Top Rated", image: "YTBarFavorites"), youtube_more_item(name: "History", image: "YTBarHistory"), youtube_more_item(name: "My Videos", image: "YTBarMyVideos"), youtube_more_item(name: "Subscriptions", image: "YTBarSubscriptions"), youtube_more_item(name: "Playlists", image: "YTBarPlaylists")]
    var body: some View {
        NoSepratorList {
            ForEach(items, id:\.id) { item in
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center) {
                        Spacer().frame(width:1, height: 44-0.95)
                        Image(item.image).frame(width:25, height: 44-0.95)
                        Text(item.name).font(.custom("Helvetica Neue Bold", size: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 6).padding(.trailing, 40)
                        Spacer()
                        Image("UITableNext").padding(.trailing, 12)
                    }.padding(.leading, 15)
                    Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                    
                }
            }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 44).drawingGroup()
            
        }.background(Color.white)
    }
}



struct containerYoutube: View {
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @Binding var player: AVPlayer
    var body: some View {
        YoutubeVideoPlayer(player: $player, show_video_player: $show_video_player, instant_video_change: $instant_video_change, playerObserver: PlayerItemObserver(player: player))
    }
}

struct YoutubeVideoPlayer: View {
    @Binding var player: AVPlayer
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @ObservedObject var playerObserver: PlayerItemObserver
    @State var showing_title: Bool = false
    @State var gravity: PlayerGravity = .fit
    @State var show_controls: Bool = true
    @State var pervent_delta: Bool = false
    @ObservedObject private var volObserver = VolumeObserver()
    var body: some View {
        GeometryReader {geometry in
            
            ZStack {
                if playerObserver.playerStatus == .readyToPlay && player.status == .readyToPlay && player.currentItem?.duration.seconds.isNaN == false {
                    PlayerContainerView(player: player, gravity: gravity).frame(width: geometry.size.height, height: geometry.size.width)        .onTapGesture() {
                        if pervent_delta == false {
                            pervent_delta = true
                            withAnimation(.linear(duration: show_controls == true ? 0.25 : 0.1)) {
                                show_controls.toggle()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                pervent_delta = false
                            }
                        }
                    }.onAppear() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            if show_video_player {
                                player.play()
                                withAnimation(.linear(duration: show_controls == false ? 0.25 : 0.1)) {
                                    show_controls.toggle()
                                }
                            }
                        }
                    }
                } else {
                    Rectangle().fill(LinearGradient([Color(red: 145/255, green: 145/255, blue: 145/255), .black], from: .top, to: .bottom)).frame(width: geometry.size.height, height: geometry.size.width)
                    Image("YouTubeBug")
                }
                if show_controls {
                    VStack(spacing: 0) {
                        status_bar().frame(width: geometry.size.height, height: 24)
                        video_player_title_bar(player: $player, gravity: $gravity, playerObserver: playerObserver, title: "", is_loading: (playerObserver.playerStatus == .readyToPlay && player.status == .readyToPlay && player.currentItem?.duration.seconds.isNaN == false) ? false : true, back_action: {
                            player.pause(); withAnimation(.linear(duration: 0.075)){show_controls = false}; DispatchQueue.main.asyncAfter(deadline: .now() + 0.075) { withAnimation(.linear(duration: 0.4)) {show_video_player = false}; DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                instant_video_change = false
                            }}
                        }, gravity_action: {
                            if gravity == .fit {
                                gravity = .aspectFill
                            } else {
                                gravity = .fit
                            }
                        }).frame(width: geometry.size.height, height: 60)
                        Spacer()
                    }.frame(width: geometry.size.height, height: geometry.size.width).zIndex(1)
                    VStack {
                        Spacer()
                        video_player_footer(player: $player, playerObserver: playerObserver, back_action: {
                            player.pause(); withAnimation(.linear(duration: 0.075)){show_controls = false}; DispatchQueue.main.asyncAfter(deadline: .now() + 0.075) { withAnimation(.linear(duration: 0.4)) {show_video_player = false}; DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                instant_video_change = false
                            }}
                        }).frame(width: geometry.size.height - 250, height: geometry.size.width/4).padding(.bottom, 40)
                    }.frame(width: geometry.size.height, height: geometry.size.width).zIndex(1)
                }
            }.frame(width: geometry.size.width, height: geometry.size.height)
        }.rotationEffect(.degrees(90)).onChange(of: player.status) {_ in
        }.onAppear {
        }.onReceive(playerObserver.$currentStatus) { newStatus in
            switch newStatus {
            case nil:
                print("nothing is here")
            case .waitingToPlayAtSpecifiedRate:
                print("waiting")
            case .paused:
                print("paused")
            case .playing:
                print("playing")
            }
        }.onDisappear() {
            player.pause();
        }
    }
}

class VPUtility: NSObject {
    
    private static var timeHMSFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter
    }()
    
    static func formatSecondsToHMS(_ seconds: Double) -> String {
        guard !seconds.isNaN,
              let text = timeHMSFormatter.string(from: seconds) else {
            return "00:00"
        }
        
        return text
    }
    
}

struct video_player_footer: View {
    @Binding var player: AVPlayer
    @ObservedObject private var volObserver = VolumeObserver()
    @ObservedObject var playerObserver: PlayerItemObserver
    public var back_action: (() -> Void)?
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(LinearGradient([(Color(red: 191/255, green: 191/255, blue: 191/255), location: 0), (Color(red: 64/255, green: 64/255, blue: 64/255), location: 0.50), (Color(red: 0/255, green: 0/255, blue: 0/255), location: 0.50), (Color(red: 0/255, green: 0/255, blue: 0/255), location: 1)], from: .top, to: .bottom)).opacity(0.6).strokeRoundedRectangle(8, LinearGradient([(Color(red: 212/255, green: 212/255, blue: 212/255), location: 0), (Color(red: 179/255, green: 179/255, blue: 179/255), location: 0.04), (Color(red: 155/255, green: 155/255, blue: 155/255), location: 1)], from: .top, to: .bottom), lineWidth: 2)
                VStack(spacing: 0) {
                    HStack {
                        Image("mp_addbookmark").padding(.leading, 12)
                        Spacer()
                        Button(action: {
                            if playerObserver.playerStatus == .readyToPlay && player.status == .readyToPlay && player.currentItem?.duration.seconds.isNaN == false {
                                back_action?()
                            }
                        }) {
                            Image("mp_prevtrack")
                        }.opacity(playerObserver.playerStatus == .readyToPlay && player.status == .readyToPlay && player.currentItem?.duration.seconds.isNaN == false ? 1 : 0.6)
                        Spacer()
                        Button(action: {
                            if playerObserver.playerStatus == .readyToPlay && player.status == .readyToPlay && player.currentItem?.duration.seconds.isNaN == false {
                                if playerObserver.currentStatus != .playing {
                                    player.play()
                                } else {
                                    player.pause()
                                }
                            }
                        }) {
                            Image(playerObserver.currentStatus != .playing ? "mp_play" : "mp_pause")
                        }.frame(width: 40).opacity(playerObserver.playerStatus == .readyToPlay && player.status == .readyToPlay && player.currentItem?.duration.seconds.isNaN == false ? 1 : 0.6)
                        Spacer()
                        Button(action: {
                            if playerObserver.playerStatus == .readyToPlay && player.status == .readyToPlay && player.currentItem?.duration.seconds.isNaN == false {
                                back_action?()
                            }
                        }) {
                            Image("mp_nexttrack")
                        }.opacity(playerObserver.playerStatus == .readyToPlay && player.status == .readyToPlay && player.currentItem?.duration.seconds.isNaN == false ? 1 : 0.6)
                        Spacer()
                        Image("mp_email").padding(.trailing, 12)
                    }.frame(width: geometry.size.width).padding(.top, 10)
                    CustomSliderVideo(player: $player, type: "Volume", value: $volObserver.volume.double,  range: (0, 100)) { modifiers in
                        ZStack {
                            
                            LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 205/255, green: 220/255, blue: 241/255), location: 0), .init(color: Color(red: 125/255, green: 174/255, blue: 245/255), location: 0.5), .init(color: Color(red: 45/255, green: 111/255, blue: 198/255), location: 0.5), .init(color: Color(red: 50/255, green: 151/255, blue: 236/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 8.5).cornerRadius(4.25).padding(.leading, 4).modifier(modifiers.barLeft)
                            
                            LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 218/255, green: 218/255, blue: 218/255), location: 0), .init(color: Color(red: 166/255, green: 166/255, blue: 166/255), location: 0.19), .init(color: Color(red: 204/255, green: 204/255, blue: 204/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 8.5).cornerRadius(4.25).padding(.trailing, 4).modifier(modifiers.barRight)
                            ZStack {
                                Image("volume-slider-fat-knob").resizable().scaledToFill()
                                
                            }.modifier(modifiers.knob)
                        }
                    }.frame(height: 25).padding([.top, .bottom]).padding([.leading, .trailing], 30)
                }.frame(height: geometry.size.height)
            }
        }
    }
}

struct video_player_title_bar : View {
    @Binding var player: AVPlayer
    @Binding var gravity: PlayerGravity
    @ObservedObject var playerObserver: PlayerItemObserver
    var title: String
    var is_loading: Bool
    public var back_action: (() -> Void)?
    public var gravity_action: (() -> Void)?
    var shows_back: Bool?
    var body :some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.005), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 0.95, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025).opacity(0.65).shadow(color: Color.black.opacity(0.25), radius: 0.25, x: 0, y: -0.5) //Correct border width for added shadow
            VStack {
                Spacer()
                if is_loading {
                    ZStack {
                        HStack {
                            Text("Loading...").font(.custom("Helvetica Neue Bold", size: 16)).foregroundColor(.white)
                            Spacer().frame(width: 8)
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                        }
                        HStack {
                            tool_bar_rectangle_button(action: {back_action?()}, button_type: .blue, content: "Done").padding(.leading, 5)
                            Spacer()
                        }
                    }
                } else {
                    HStack(spacing: 0) {
                        tool_bar_rectangle_button(action: {back_action?()}, button_type: .blue, content: "Done").padding(.leading, 5)
                        Spacer()
                        Text("\(VPUtility.formatSecondsToHMS(playerObserver.seekPos * (player.currentItem?.duration.seconds ?? 0)))").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(.white).padding([.leading], 15)
                        CustomSliderVideo(player: $player, type: "Video", value: $playerObserver.seekPos,  range: (0, 1)) { modifiers in
                            ZStack {
                                ZStack {
                                    LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 205/255, green: 220/255, blue: 241/255), location: 0), .init(color: Color(red: 125/255, green: 174/255, blue: 245/255), location: 0.5), .init(color: Color(red: 45/255, green: 111/255, blue: 198/255), location: 0.5), .init(color: Color(red: 50/255, green: 151/255, blue: 236/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 9).cornerRadius(4.25).padding(.leading, 4).modifier(modifiers.barLeft)
                                    
                                    LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 218/255, green: 218/255, blue: 218/255), location: 0), .init(color: Color(red: 166/255, green: 166/255, blue: 166/255), location: 0.19), .init(color: Color(red: 204/255, green: 204/255, blue: 204/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 9).cornerRadius(4.25).padding(.trailing, 4).modifier(modifiers.barRight)
                                }.overlay(LinearGradient([Color(red: 48/255, green: 50/255, blue: 53/255), Color(red: 87/255, green: 93/255, blue: 97/255)], from: .top, to: .bottom).mask(LinearGradient([(Color.black, location: 0), (Color.black, location: playerObserver.buffer/(player.currentItem?.duration.seconds ?? 1)), (Color.white, location: playerObserver.buffer/(player.currentItem?.duration.seconds ?? 1))], from: .leading, to: .trailing).frame(height: 4.5).cornerRadius(4.25/8.5*4.5).luminanceToAlpha()).frame(height: 4.5).cornerRadius(4.25/8.5*4.5).padding([.leading, .trailing], 7).offset(y: 0.25))
                                ZStack {
                                    Image("volume-slider-fat-knob").resizable().scaledToFill()
                                    
                                }.modifier(modifiers.knob)
                            }
                        }.frame(height: 25)
                        Text("-\(VPUtility.formatSecondsToHMS((player.currentItem?.duration.seconds ?? 0) - playerObserver.seekPos * (player.currentItem?.duration.seconds ?? 0)))").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(.white).padding([.trailing], 15)
                        Spacer()
                        tool_bar_rectangle_button_image_done_size(action: {gravity_action?()}, button_type: .black, content: gravity == .fit ? "mp_zoomout" : "mp_zoomin", use_image: true).padding(.trailing, 5)
                    }
                }
                Spacer()
            }
        }
    }
}



class PlayerItemObserver: ObservableObject {
    
    @Published var currentStatus: AVPlayer.TimeControlStatus?
    @Published var playerStatus: AVPlayer.Status?
    @Published var seekPos: Double = 0.0
    @Published var buffer: Double = 0.0
    private var timeObserverToken: Any?
    private var itemObservation: AnyCancellable?
    private var itemObservation1: AnyCancellable?
    private var itemObservation2: AnyCancellable?
    
    init(player: AVPlayer) {
        
        itemObservation = player.publisher(for: \.timeControlStatus).sink { newStatus in
            self.currentStatus = newStatus
        }
        itemObservation1 = player.publisher(for: \.status).sink {status in
            self.playerStatus = status
        }
        itemObservation2 = player.publisher(for: \AVPlayer.currentItem?.loadedTimeRanges).sink {times in
            guard let initial_range = times?.first?.timeRangeValue else {
                return
            }
            var time = CMTimeGetSeconds(initial_range.duration)
            var start = CMTimeGetSeconds(initial_range.start)
            self.buffer = time + start
        }
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: nil) { time in
            guard let item = player.currentItem else {
                return
            }
            if item.duration.seconds != 0, item.duration.seconds.isNaN == false {
                self.seekPos = time.seconds / item.duration.seconds
            }
        }
    }
    
    func invalidate() {
        itemObservation?.cancel()
        itemObservation = nil
        itemObservation1?.cancel()
        itemObservation1 = nil
        itemObservation2?.cancel()
        itemObservation2 = nil
    }
    deinit {
        itemObservation?.cancel()
        itemObservation = nil
        itemObservation1?.cancel()
        itemObservation1 = nil
        itemObservation2?.cancel()
        itemObservation2 = nil
    }
    
}


extension Double {
    func asString(style: DateComponentsFormatter.UnitsStyle) -> String {
        let formatter = DateComponentsFormatter()
        if self > 3600 {
            formatter.allowedUnits = [.hour, .minute, .second]
        } else {
            formatter.allowedUnits = [.minute, .second]
        }
        formatter.unitsStyle = style
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: self) ?? ""
    }
}

struct youtube_title_bar : View {
    var title:String
    @Binding var selectedTab: String
    @Binding var selected_segment: Int
    @Binding var instant_multitasking_change: Bool
    @Binding var search_results: [YouTubeVideoData]
    @Binding var is_searching: Bool
    @Binding var forward_or_backward: Bool
    @Binding var featured_current_nav_view: String
    @Binding var mv_current_nav_view: String
    @Binding var fv_current_nav_view: String
    @Binding var search_current_nav_view: String
    @Binding var instant_video_change: Bool
    @Binding var is_editing_favorites: Bool
    @State var search: String = ""
    @State var place_holder = ""
    var no_right_padding: Bool?
    @State var editing_state: String = "None"
    public var done_action: (() -> Void)?
    public var editing_favorites_action: (() -> Void)?
    var show_done: Bool?
    private let gradient = LinearGradient([.white, .white], to: .trailing)
    var body :some View {
        GeometryReader {geometry in
            ZStack {
                LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.49), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.49), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if (selectedTab != "Most Viewed" || mv_current_nav_view != "Main"), (selectedTab != "Search" || search_current_nav_view != "Main") {
                            Text(title).ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", size: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).id(title).frame(maxWidth: selectedTab == "Most Viewed" ? 145 : 180)
                        } else if selectedTab == "Most Viewed" {
                            tri_segmented_control_youtube(selected: $selected_segment, instant_multitasking_change: $instant_multitasking_change, first_text: "Today", second_text: "This week", third_text: "All", should_animate: instant_video_change).frame(width: geometry.size.width-24, height: 30)
                        } else if selectedTab == "Search" {
                            VStack {
                                Spacer()
                                HStack {
                                    HStack {
                                        Spacer(minLength: 5)
                                        HStack (alignment: .center,
                                                spacing: 10) {
                                            Image("search_icon").resizable().font(Font.title.weight(.medium)).frame(width: 15, height: 15).padding(.leading, 5)
                                    
                                            
                                            TextField ("YouTube", text: $search, onEditingChanged: { (changed) in
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
                                                }
                                                if search != "" {
                                                    search_results.removeAll()
                                                    is_searching = true
                                                    guard let search_string = search.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {return}
                                                    guard let url = URL(string: "https://us-central1-oldos-310521.cloudfunctions.net/api/search-yext?query=\(search_string)") else {return}
                                                    let request = URLRequest(url: url)
                                                    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
                                                        
                                                        if let error = error {
                                                            print(error)
                                                            return
                                                        }
                                                        
                                                        // Parse JSON data
                                                        if let data = data {
                                                            guard let compiled_object = parseJsonSearchData(data: data) else {
                                                                return
                                                            }
                                                            if compiled_object.isEmpty == false {
                                                                var temp_array = [YouTubeVideoData]()
                                                                for video in compiled_object {
                                                                    fetch_searched_video(id: video.id ?? "", completion: {result in
                                                                        temp_array.append(result)
                                                                        if temp_array.count == compiled_object.count {
                                                                            search_results = temp_array
                                                                            is_searching = false
                                                                        }
                                                                    })
                                                                }
                                                            }
                                                        }
                                                    })
                                                    
                                                    task.resume()
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
                                        }.padding([.top,.bottom], 5).padding(.leading, 5).cornerRadius(40)
                                        Spacer(minLength: 8)
                                    } .ps_innerShadow(.capsule(gradient), radius:1.6, offset: CGPoint(0, 1), intensity: 0.7).strokeCapsule(Color(red: 166/255, green: 166/255, blue: 166/255), lineWidth: 0.33).padding(.leading, 5.5).padding(.trailing, 5.5)
                                }
                                Spacer()
                            }
                        }
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
                if selectedTab == "Featured", featured_current_nav_view != "Main" { //, featured_show_application == true
                    VStack {
                        Spacer()
                        HStack {
                            Button(action:{
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)){featured_current_nav_view = (featured_current_nav_view == "Video_Info" ? "Video_Destination": "Main")}
                            }){
                                ZStack {
                                    Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                                    HStack(alignment: .center) {
                                        Text("Search").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", size: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                                    }
                                }.padding(.leading, 6)
                            }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                            Spacer()
                        }
                        Spacer()
                    }.offset(y:-0.5)
                    
                }
                if selectedTab == "Most Viewed", mv_current_nav_view != "Main" { //, featured_show_application == true
                    VStack {
                        Spacer()
                        HStack {
                            Button(action:{
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)){mv_current_nav_view = (mv_current_nav_view == "Video_Info" ? "Video_Destination": "Main")}
                            }){
                                ZStack {
                                    Image("Button_wp5").resizable().scaledToFit().frame(width:200*84/162*(33/34.33783783783784), height: 33)
                                    HStack(alignment: .center) {
                                        Text("Most Viewed").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", size: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1).offset(x: 1)
                                    }
                                }.padding(.leading, 6)
                            }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                            Spacer()
                        }
                        Spacer()
                    }.offset(y:-0.5)
                    
                }
                if selectedTab == "Search", search_current_nav_view != "Main" { //, featured_show_application == true
                    VStack {
                        Spacer()
                        HStack {
                            Button(action:{
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)){search_current_nav_view = (search_current_nav_view == "Video_Info" ? "Video_Destination": "Main")}
                            }){
                                ZStack {
                                    Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                                    HStack(alignment: .center) {
                                        Text("Search").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", size: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                                    }
                                }.padding(.leading, 6)
                            }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                            Spacer()
                        }
                        Spacer()
                    }.offset(y:-0.5)
                    
                }
                if selectedTab == "Favorites", fv_current_nav_view != "Main" { //, featured_show_application == true
                    VStack {
                        Spacer()
                        HStack {
                            Button(action:{
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)){fv_current_nav_view = (fv_current_nav_view == "Video_Info" ? "Video_Destination": "Main")}
                            }){
                                ZStack {
                                    Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                                    HStack(alignment: .center) {
                                        Text("Favorites").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", size: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                                    }
                                }.padding(.leading, 6)
                            }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                            Spacer()
                        }
                        Spacer()
                    }.offset(y:-0.5)
                    
                }
                if selectedTab == "Favorites", fv_current_nav_view == "Main" { //, featured_show_application == true
                    VStack {
                        Spacer()
                        HStack {
                            tool_bar_rectangle_button(action: {}, button_type: .blue_gray, content: " Sign In ").padding(.leading, 5)
                            Spacer()
                            tool_bar_rectangle_button(action: {editing_favorites_action?()}, button_type: is_editing_favorites == false ? .blue_gray : .blue, content: is_editing_favorites == false ? " Edit " : "Done").padding(.trailing, 5)
                        }
                        Spacer()
                    }.offset(y:-0.5)
                    
                }
                if selectedTab == "More" { //, featured_show_application == true
                    VStack {
                        Spacer()
                        HStack {
                            tool_bar_rectangle_button(action: {}, button_type: .blue_gray, content: " Sign In ").padding(.leading, 5)
                            Spacer()
                        }
                        Spacer()
                    }.offset(y:-0.5)
                    
                }
            }
        }
    }
}

extension String {
    
    func getYoutubeFormattedDuration() -> String {
        
        let formattedDuration = self.replacingOccurrences(of: "PT", with: "").replacingOccurrences(of: "H", with:":").replacingOccurrences(of: "M", with: ":").replacingOccurrences(of: "S", with: "")
        
        let components = formattedDuration.components(separatedBy: ":")
        var duration = ""
        for component in components {
            duration = duration.count > 0 ? duration + ":" : duration
            if component.count < 2 {
                duration += "0" + component
                continue
            }
            duration += component
        }
        
        return duration
        
    }
    
}

func format_video_duration(duration: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    let date = formatter.date(from: duration) ?? Date()
    return formatter.string(from: date)
}

class YoutubeObserver: ObservableObject {
    @Published var featured = [YoutubeFeatured.Item]()
    @Published var featured_stats = [YoutubeVideoStats.Item]()
    @Published var featured_details = [YoutubeVideoDetails.Item]()
    init() {
        parse_data()
    }
    func parse_data() {
        print("parsing data")
        fetch_featured_data(completion: {data in
            self.featured = data
        })
        fetch_featured_stats(completion: {data in
            self.featured_stats = data
        })
        fetch_featured_details(completion: {data in
            self.featured_details = data
        })
    }
    
}


class MostViewedObserver: ObservableObject {
    @Published var today = [YouTubeVideoData]()
    @Published var this_week = [YouTubeVideoData]()
    @Published var all_time = [YouTubeVideoData]()
    init() {
        parse_data()
    }
    func parse_data() {
        print("parsing data")
        fetch_most_viewed(type: "Today", completion: {results in
            for result in results {
                fetch_most_viewed_video(id: result.id.videoID, completion: {video in
                    self.today.append(video)
                })
            }
        })
        fetch_most_viewed(type: "ThisWeek", completion: {results in
            for result in results {
                fetch_most_viewed_video(id: result.id.videoID, completion: {video in
                    self.this_week.append(video)
                })
            }
        })
        fetch_most_viewed(type: "", completion: {results in
            for result in results {
                fetch_most_viewed_video(id: result.id.videoID, completion: {video in
                    self.all_time.append(video)
                })
            }
        })
    }
}


func fetch_featured_data(completion: @escaping ([YoutubeFeatured.Item]) -> Void) {
    let url = URL(string: "https://us-central1-oldos-310521.cloudfunctions.net/api/mostPopular")!
    var request = URLRequest(url: url)
    request.setValue("sent-from-app", forHTTPHeaderField: "x-oldos-app")
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
        
        if let error = error {
            print(error)
            return
        }
        
        // Parse JSON data
        if let data = data {
            guard let compiled_object = parseJsonYoutubeFeaturedData(data: data) else {
                return
            }
            if compiled_object.isEmpty == false {
                completion(compiled_object)
            }
        }
    })
    
    task.resume()
}

func fetch_featured_stats(completion: @escaping ([YoutubeVideoStats.Item]) -> Void) {
    //Our first step is to fetch the ID of the application, a trick we can do is to grab it from the URL...
    let url = URL(string: "https://us-central1-oldos-310521.cloudfunctions.net/api/mostPopular/stats")!
    var request = URLRequest(url: url)
    request.setValue("sent-from-app", forHTTPHeaderField: "x-oldos-app")
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
        
        if let error = error {
            print(error)
            return
        }
        
        // Parse JSON data
        if let data = data {
            guard let compiled_object = parseJsonYoutubeFeaturedDataS(data: data) else {
                return
            }
            if compiled_object.isEmpty == false {
                completion(compiled_object)
            }
        }
    })
    
    task.resume()
}

func fetch_featured_details(completion: @escaping ([YoutubeVideoDetails.Item]) -> Void) {
    //Our first step is to fetch the ID of the application, a trick we can do is to grab it from the URL...
    let url = URL(string: "https://us-central1-oldos-310521.cloudfunctions.net/api/mostPopular/details")!
    var request = URLRequest(url: url)
    request.setValue("sent-from-app", forHTTPHeaderField: "x-oldos-app")
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
        
        if let error = error {
            print(error)
            return
        }
        
        // Parse JSON data
        if let data = data {
            guard let compiled_object = parseJsonYoutubeFeaturedDataD(data: data) else {
                return
            }
            if compiled_object.isEmpty == false {
                completion(compiled_object)
            }
        }
    })
    
    task.resume()
}

func fetch_most_viewed(type: String?, completion: @escaping ([MostViewed.Item]) -> Void) {
    //Our first step is to fetch the ID of the application, a trick we can do is to grab it from the URL...
    let url = URL(string: "https://us-central1-oldos-310521.cloudfunctions.net/api/mostViewed\(type ?? "")")!
    var request = URLRequest(url: url)
    request.setValue("sent-from-app", forHTTPHeaderField: "x-oldos-app")
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
        
        if let error = error {
            print(error)
            return
        }
        
        // Parse JSON data
        if let data = data {
            guard let compiled_object = parseJsonYoutubeMostViewedData(data: data) else {
                return
            }
            if compiled_object.isEmpty == false {
                completion(compiled_object)
            }
        }
    })
    
    task.resume()
}

func fetch_most_viewed_video(id: String?, completion: @escaping (YouTubeVideoData) -> Void) {
    //Our first step is to fetch the ID of the application, a trick we can do is to grab it from the URL...
    let url = URL(string: "https://us-central1-oldos-310521.cloudfunctions.net/api/video-info?query=\(id ?? "")")!
    var request = URLRequest(url: url)
    request.setValue("sent-from-app", forHTTPHeaderField: "x-oldos-app")
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
        
        if let error = error {
            print(error)
            return
        }
        
        // Parse JSON data
        if let data = data {
            do {
                let decoder = JSONDecoder()
                let compiled_object = try decoder.decode(YouTubeVideoData.self, from: data)
                completion(compiled_object)
            } catch {
                print(error)
            }
            //    if compiled_object.isEmpty == false {ject)
            //   }
        }
    })
    
    task.resume()
}

func fetch_searched_video(id: String?, completion: @escaping (YouTubeVideoData) -> Void) {
    //Our first step is to fetch the ID of the application, a trick we can do is to grab it from the URL...
    let url = URL(string: "https://us-central1-oldos-310521.cloudfunctions.net/api/video-info?query=\(id ?? "")")!
    var request = URLRequest(url: url)
    request.setValue("sent-from-app", forHTTPHeaderField: "x-oldos-app")
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
        
        if let error = error {
            print(error)
            return
        }
        
        // Parse JSON data
        if let data = data {
            do {
                let decoder = JSONDecoder()
                let compiled_object = try decoder.decode(YouTubeVideoData.self, from: data)
                completion(compiled_object)
            } catch {
                print(error)
            }
        }
    })
    
    task.resume()
}

func fetch_comment_data(id: String?, completion: @escaping (YoutubeVideoComments) -> Void) {
    //Our first step is to fetch the ID of the application, a trick we can do is to grab it from the URL...
    let url = URL(string: "https://us-central1-oldos-310521.cloudfunctions.net/api/comments?query=\(id ?? "")")!
    var request = URLRequest(url: url)
    request.setValue("sent-from-app", forHTTPHeaderField: "x-oldos-app")
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
        
        if let error = error {
            print(error)
            return
        }
        
        // Parse JSON data
        if let data = data {
            do {
                let decoder = JSONDecoder()
                let compiled_object = try decoder.decode(YoutubeVideoComments.self, from: data)
                completion(compiled_object)
            } catch {
                print(error)
            }
            //    if compiled_object.isEmpty == false {ject)
            //   }
        }
    })
    
    task.resume()
}


func parseJsonSearchData(data: Data) -> [YoutubeVideoSearchData.Videos]? {
    
    var application_data = [YoutubeVideoSearchData.Videos]()
    
    let decoder = JSONDecoder()
    
    do {
        let loanDataStore = try decoder.decode(YoutubeVideoSearchData.self, from: data)
        application_data = loanDataStore.videos ?? []
        
    } catch {
        print(error)
    }
    
    return application_data
}


func parseJsonYoutubeMostViewedData(data: Data) -> [MostViewed.Item]? {
    
    var application_data = [MostViewed.Item]()
    
    let decoder = JSONDecoder()
    
    do {
        let loanDataStore = try decoder.decode(MostViewed.self, from: data)
        application_data = loanDataStore.items ?? []
        
    } catch {
        print(error)
    }
    
    return application_data
}

func parseJsonYoutubeFeaturedData(data: Data) -> [YoutubeFeatured.Item]? {
    
    var application_data = [YoutubeFeatured.Item]()
    
    let decoder = JSONDecoder()
    
    do {
        let loanDataStore = try decoder.decode(YoutubeFeatured.self, from: data)
        application_data = loanDataStore.items ?? []
        
    } catch {
        print(error)
    }
    
    return application_data
}


func parseJsonYoutubeFeaturedDataS(data: Data) -> [YoutubeVideoStats.Item]? {
    
    var application_data = [YoutubeVideoStats.Item]()
    
    let decoder = JSONDecoder()
    
    do {
        let loanDataStore = try decoder.decode(YoutubeVideoStats.self, from: data)
        application_data = loanDataStore.items ?? []
        
    } catch {
        print(error)
    }
    
    return application_data
}

func parseJsonYoutubeFeaturedDataD(data: Data) -> [YoutubeVideoDetails.Item]? {
    
    var application_data = [YoutubeVideoDetails.Item]()
    
    let decoder = JSONDecoder()
    
    do {
        let loanDataStore = try decoder.decode(YoutubeVideoDetails.self, from: data)
        application_data = loanDataStore.items ?? []
        
    } catch {
        print(error)
    }
    
    return application_data
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


struct YoutubeFeatured: Codable {
    struct Item: Codable {
        struct Snippet: Codable {
            struct Thumbnail: Codable {
                struct Default: Codable {
                    let url: URL
                    let width: Int
                    let height: Int
                }
                
                struct Medium: Codable {
                    let url: URL
                    let width: Int
                    let height: Int
                }
                
                struct High: Codable {
                    let url: URL
                    let width: Int
                    let height: Int
                }
                
                struct Standard: Codable {
                    let url: URL
                    let width: Int
                    let height: Int
                }
                
                struct Maxre: Codable {
                    let url: URL
                    let width: Int
                    let height: Int
                }
                
                let `default`: Default
                let medium: Medium
                let high: High
                let standard: Standard?
                let maxres: Maxre?
            }
            
            struct Localized: Codable {
                let title: String
                let description: String
            }
            
            let publishedAt: String?
            let channelID: String
            let title: String
            let description: String
            let thumbnails: Thumbnail
            let channelTitle: String
            let tags: [String]?
            let categoryID: String
            let liveBroadcastContent: String
            let localized: Localized
            let defaultLanguage: String?
            let defaultAudioLanguage: String?
            
            private enum CodingKeys: String, CodingKey {
                case publishedAt
                case channelID = "channelId"
                case title
                case description
                case thumbnails
                case channelTitle
                case tags
                case categoryID = "categoryId"
                case liveBroadcastContent
                case localized
                case defaultLanguage
                case defaultAudioLanguage
            }
        }
        
        let kind: String?
        let etag: String?
        let id: String
        let snippet: Snippet
    }
    
    struct PageInfo: Codable {
        let totalResults: Int
        let resultsPerPage: Int
    }
    
    let kind: String?
    let etag: String?
    let items: [Item]?
    let nextPageToken: String?
    let pageInfo: PageInfo?
}

struct MostViewed: Codable {
    struct PageInfo: Codable {
        let totalResults: Int
        let resultsPerPage: Int
    }
    
    struct Item: Codable {
        struct ID: Codable {
            let kind: String?
            let videoID: String
            
            private enum CodingKeys: String, CodingKey {
                case kind
                case videoID = "videoId"
            }
        }
        
        struct Snippet: Codable {
            struct Thumbnail: Codable {
                struct Default: Codable {
                    let url: URL
                    let width: Int
                    let height: Int
                }
                
                struct Medium: Codable {
                    let url: URL
                    let width: Int
                    let height: Int
                }
                
                struct High: Codable {
                    let url: URL
                    let width: Int
                    let height: Int
                }
                
                let `default`: Default
                let medium: Medium
                let high: High
            }
            
            let publishedAt: String?
            let channelID: String
            let title: String
            let description: String
            let thumbnails: Thumbnail
            let channelTitle: String
            let liveBroadcastContent: String
            let publishTime: String?
            
            private enum CodingKeys: String, CodingKey {
                case publishedAt
                case channelID = "channelId"
                case title
                case description
                case thumbnails
                case channelTitle
                case liveBroadcastContent
                case publishTime
            }
        }
        
        let kind: String?
        let etag: String?
        let id: ID
        let snippet: Snippet
    }
    
    let kind: String?
    let etag: String?
    let nextPageToken: String?
    let regionCode: String?
    let pageInfo: PageInfo?
    let items: [Item]?
}

struct YoutubeVideoDetails: Codable {
    struct Item: Codable {
        struct ContentDetail: Codable {
            struct ContentRating: Codable {
            }
            
            let duration: String
            let dimension: String
            let definition: String
            let caption: String
            let licensedContent: Bool
            let contentRating: ContentRating
            let projection: String
        }
        
        let kind: String?
        let etag: String?
        let id: String?
        let contentDetails: ContentDetail
    }
    
    struct PageInfo: Codable {
        let totalResults: Int?
        let resultsPerPage: Int?
    }
    
    let kind: String?
    let etag: String?
    let items: [Item]?
    let nextPageToken: String?
    let pageInfo: PageInfo?
}

struct YoutubeVideoStats: Codable {
    struct Item: Codable {
        struct Statistic: Codable {
            let viewCount: String?
            let likeCount: String?
            let dislikeCount: String?
            let favoriteCount: String?
            let commentCount: String?
        }
        
        let kind: String?
        let etag: String?
        let id: String
        let statistics: Statistic
    }
    
    struct PageInfo: Codable {
        let totalResults: Int
        let resultsPerPage: Int
    }
    
    let kind: String?
    let etag: String?
    let items: [Item]?
    let nextPageToken: String?
    let pageInfo: PageInfo?
}

struct YouTubeVideoData: Codable {
    struct Channel: Codable {
        struct Subscriber: Codable {
            let pretty: String?
        }
        
        struct Icon: Codable {
            let url: URL?
            let width: Int?
            let height: Int?
        }
        
        let name: String?
        let id: String?
        let url: URL?
        let subscribers: Subscriber?
        let icons: [Icon]?
    }
    
    struct Duration: Codable {
        let lengthSec: String?
    }
    
    struct Thumbnail: Codable {
        let url: URL?
        let width: Int?
        let height: Int?
    }
    
    struct Rating: Codable {
        struct Like: Codable {
            let text: String?
            let pretty: String?
        }
        
        struct Dislike: Codable {
            let text: String?
            let pretty: String?
        }
        
        let likes: Like?
        let dislikes: Dislike?
    }
    
    struct View: Codable {
        let text: String?
        let pretty: String?
    }
    
    struct Published: Codable {
        let pretty: String?
        let text: String?
    }
    
    struct Uploaded: Codable {
        let text: String?
    }
    
    struct Embed: Codable {
        let iframeURL: URL?
        let flashURL: URL?
        let width: Int?
        let height: Int?
        let flashSecureURL: URL?
        
        private enum CodingKeys: String, CodingKey {
            case iframeURL = "iframeUrl"
            case flashURL = "flashUrl"
            case width
            case height
            case flashSecureURL = "flashSecureUrl"
        }
    }
    
    struct Stream: Codable {
        struct Format: Codable {
            let itag: Int?
            let url: URL?
            let mimeType: String?
            let bitrate: Int?
            let width: Int?
            let height: Int?
            let lastModified: String?
            let contentLength: String?
            let quality: String?
            let fps: Int?
            let qualityLabel: String?
            let projectionType: String?
            let averageBitrate: Int?
            let audioQuality: String?
            let approxDurationMs: String?
            let audioSampleRate: String?
            let audioChannels: Int?
        }
        
        struct AdaptiveFormat: Codable {
            struct InitRange: Codable {
                let start: String?
                let end: String?
            }
            
            struct IndexRange: Codable {
                let start: String?
                let end: String?
            }
            
            struct ColorInfo: Codable {
                let primaries: String?
                let transferCharacteristics: String?
                let matrixCoefficients: String?
            }
            
            let itag: Int?
            let url: URL?
            let mimeType: String?
            let bitrate: Int?
            let width: Int?
            let height: Int?
            let initRange: InitRange?
            let indexRange: IndexRange?
            let lastModified: String?
            let contentLength: String?
            let quality: String?
            let fps: Int?
            let qualityLabel: String?
            let projectionType: String?
            let averageBitrate: Int?
            let approxDurationMs: String?
            let colorInfo: ColorInfo?
            let highReplication: Bool?
            let audioQuality: String?
            let audioSampleRate: String?
            let audioChannels: Int?
            let loudnessDb: Double?
        }
        
        struct Player: Codable {
            let url: URL?
        }
        
        let expiresInSeconds: String?
        let formats: [Format]?
        let adaptiveFormats: [AdaptiveFormat]?
        let player: Player?
    }
    
    let title: String?
    let id: String?
    let url: URL?
    let shortDescription: String?
    let description: String?
    let channel: Channel?
    let duration: Duration?
    let thumbnails: [Thumbnail]?
    let ratings: Rating?
    let views: View?
    let published: Published?
    let uploaded: Uploaded?
    let keywords: [String]?
    let isLive: Bool?
    let isUnlisted: Bool?
    let isFamilySafe: Bool?
    let category: String?
    let embed: Embed?
    let streams: Stream?
}

struct YoutubeVideoSearchData: Codable {
    struct Videos: Codable {
        struct Channel: Codable {
            let name: String?
            let id: String?
            let url: URL?
        }
        
        struct Duration: Codable {
            let text: String?
            let pretty: String?
        }
        
        struct Published: Codable {
            let pretty: String?
        }
        
        struct Views: Codable {
            let text: String?
            let pretty: String?
            let prettyLong: String?
        }
        
        struct Thumbnails: Codable {
            let url: URL?
            let width: Int?
            let height: Int?
        }
        
        let title: String?
        let id: String?
        let url: URL?
        let channel: Channel?
        let duration: Duration?
        let published: Published?
        let views: Views?
        let thumbnails: [Thumbnails]?
    }
    
    struct Channels: Codable {
        struct Subscribers: Codable {
            let text: String?
            let pretty: String?
        }
        
        struct Icons: Codable {
            let url: URL?
            let width: Int?
            let height: Int?
        }
        
        let name: String?
        let id: String?
        let url: URL?
        let subscribers: Subscribers?
        let videoCount: String?
        let icons: [Icons]?
    }
    
    struct Playlists: Codable {
        struct Thumbnails: Codable {
            let url: URL?
            let width: Int?
            let height: Int?
        }
        
        struct Published: Codable {
        }
        
        let name: String?
        let id: String?
        let url: URL?
        let thumbnails: [Thumbnails]?
        let videoCount: String?
        let published: Published?
    }
    
    let videos: [Videos]?
    let channels: [Channels]?
    let playlists: [Playlists]?
}

struct YoutubeVideoComments: Codable {
    struct Comments: Codable {
        struct AuthorThumb: Codable {
            let url: URL?
            let width: Int?
            let height: Int?
        }
        
        let authorThumb: [AuthorThumb]?
        let author: String?
        let authorID: String?
        let commentID: String
        let text: String?
        let likes: String?
        let numReplies: Int?
        let isOwner: Bool?
        let isHearted: Bool?
        let isPinned: Bool?
        let hasOwnerReplied: Bool?
        let time: String?
        let edited: Bool?
        let replyToken: String?
        let isVerified: Bool?
        let isOfficialArtist: Bool?
        
        private enum CodingKeys: String, CodingKey {
            case authorThumb
            case author
            case authorID = "authorId"
            case commentID = "commentId"
            case text
            case likes
            case numReplies
            case isOwner
            case isHearted
            case isPinned
            case hasOwnerReplied
            case time
            case edited
            case replyToken
            case isVerified
            case isOfficialArtist
        }
    }
    
    let comments: [Comments]
    let continuation: String?
}


struct BlankButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(Color.white)
    }
    
}
