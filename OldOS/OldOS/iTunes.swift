//
//  iTunes.swift
//  OldOS
//
//  Created by Zane Kleinberg on 3/25/21.
//

import SwiftUI
import FeedKit
import Foundation
import SDWebImageSwiftUI
import SwiftUIPager
import WebKit
import Alamofire

struct iTunes: View {
    @State var current_nav_view: String = "Main"
    @State var forward_or_backward: Bool = false
    @State var selectedTab = "Music"
    @State var selected_segment: Int = 0
    @State var selected_segment_25: Int = 0
    @StateObject var new_music_observer = iTunesMusicObserver()
    @StateObject var new_movietv_observer = iTunesMovieVideoObserver()
    @State var music_show_music: Bool = false
    @State var music_selected_music: Music_Data.Results?
    @State var music_show_category: Bool = false
    @State var selected_category: top_ten_song_categories_datetype = top_ten_song_categories_datetype(name: "", genre_id: "", image_url: nil)
    @State var selected_segment_videos: Int = 0
    @State var videos_show_movie: Bool = false
    @State var videos_selected_movie: Music_Data.Results?
    @State var videos_show_tv: Bool = false
    @State var videos_selected_tv: Music_Data.Results?
    @State var top25_show_application: Bool = false
    @State var top25_selected_application: Application_Data.Results?
    @State var categories_current_view: String = "Main"
    @State var categories_selected_application: Application_Data.Results?
    @State var search_results = [search_section]()
    @State var search_show_application: Bool = false
    @State var search_selected_application: Application_Data.Results?
    @State var video_title: String?
    @State var search_title: String?
    @State var genius_selected_segment: Int = 0
    @State var search_selected_item_url: URL?
    @State var search_show_result: Bool = false
    @State var editing_state: String = "None"
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing:0) {
                    status_bar_in_app().frame(minHeight: 24, maxHeight:24).zIndex(1)
                    itunes_title_bar(title: (selectedTab == "Music" && music_show_music == true) ? (music_selected_music?.collectionName ?? "") : (selectedTab == "Music" && music_show_category == true) ? selected_category.name : (selectedTab == "Videos" && videos_show_movie == true) ? (video_title ?? "") : (selectedTab == "Search" && search_show_result == true) ? (search_title ?? "") : selectedTab, selected_segment: $selected_segment, selected_segment_videos: $selected_segment_videos, forward_or_backward: $forward_or_backward, selectedTab: $selectedTab, music_show_music: $music_show_music, music_show_category: $music_show_category, videos_show_movie: $videos_show_movie, videos_show_tv: $videos_show_tv, categories_current_view: $categories_current_view, search_results: $search_results, search_show_application: $search_show_application, search_selected_application: $search_selected_application, video_title: $video_title, genius_selected_segment: $genius_selected_segment, search_show_result: $search_show_result, editing_state: $editing_state, show_edit: false, show_plus: false).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 60, maxHeight:60).zIndex(1)
                    iTunesTabView(selectedTab: $selectedTab, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, selected_segment: $selected_segment, selected_segment_videos: $selected_segment_videos, new_music_observer: new_music_observer, new_movietv_observer: new_movietv_observer, music_show_music: $music_show_music, music_selected_music: $music_selected_music, music_show_category: $music_show_category, videos_show_movie: $videos_show_movie, videos_selected_movie: $videos_selected_movie, videos_show_tv: $videos_show_tv, videos_selected_tv: $videos_selected_tv, selected_category: $selected_category, search_results: $search_results, search_show_application: $search_show_application, search_selected_application: $search_selected_application, video_title: $video_title, search_title: $search_title, genius_selected_segment: $genius_selected_segment, search_selected_item_url: $search_selected_item_url, search_show_result: $search_show_result, editing_state: $editing_state).clipped()
                }
            }.compositingGroup().clipped()
        }.onAppear() {
            UIScrollView.appearance().bounces = true
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
        }
    }
}

var itunes_tabs = ["Music", "Videos", "Search", "Genius", "More"]
struct iTunesTabView : View {
    
    @Binding var selectedTab:String
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    
    @Binding var selected_segment: Int
    @Binding var selected_segment_videos: Int
    @StateObject var new_music_observer: iTunesMusicObserver
    @StateObject var new_movietv_observer: iTunesMovieVideoObserver
    @Binding var music_show_music: Bool
    @Binding var music_selected_music: Music_Data.Results?
    @Binding var music_show_category: Bool
    
    @Binding var videos_show_movie: Bool
    @Binding var videos_selected_movie: Music_Data.Results?
    @Binding var videos_show_tv: Bool
    @Binding var videos_selected_tv: Music_Data.Results?
    
    @Binding var selected_category: top_ten_song_categories_datetype
    @Binding var search_results: [search_section]
    @Binding var search_show_application: Bool
    @Binding var search_selected_application: Application_Data.Results?
    @Binding var video_title: String?
    @Binding var search_title: String?
    @Binding var genius_selected_segment: Int
    
    @Binding var search_selected_item_url: URL?
    @Binding var search_show_result: Bool
    @Binding var editing_state: String
    
    var body: some View{
        GeometryReader {geometry in
            VStack(spacing:0) {
                
                ScrollView([], showsIndicators: false) {
                    switch selectedTab {
                    case "Music":
                        switch (music_show_music || music_show_category) {
                        case false:
                            itunes_music_view(new_music_observer: new_music_observer, selected_segment: $selected_segment, music_show_music: $music_show_music, music_selected_music: $music_selected_music, selected_category: $selected_category, music_show_category: $music_show_category, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).frame(height: geometry.size.height - 57).tag("Music").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                        case true:
                            if music_show_music == true {
                                music_destination(music_selected_music: $music_selected_music).frame(height: geometry.size.height - 57).tag("Music").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                            } else {
                                itunes_category_destination_view(selected_category: $selected_category, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).frame(height: geometry.size.height - 57).tag("Music").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                            }
                        }
                    case "Videos":
                        switch (videos_show_tv || videos_show_movie) {
                        case false:
                            itunes_videos_view(new_movietv_observer: new_movietv_observer, selected_segment_videos: $selected_segment_videos, videos_show_movie: $videos_show_movie, videos_selected_movie: $videos_selected_movie, videos_show_tv: $videos_show_tv, videos_selected_tv: $videos_selected_tv, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).frame(height: geometry.size.height - 57).tag("Videos").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                        case true:
                            movies_destination(videos_selected_movie: $videos_selected_movie, video_title: $video_title).tag("Videos").frame(height: geometry.size.height - 57).tag("Videos").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                        }
                        
                    case "Search":
                        switch search_show_result {
                        case false:
                            itunes_search(search_results: $search_results, search_selected_item_url: $search_selected_item_url, search_show_result: $search_show_result, forward_or_backward: $forward_or_backward, editing_state: $editing_state).frame(height: geometry.size.height - 57).tag("Search").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                        case true:
                            search_destination(search_selected_item_url: $search_selected_item_url, video_title: $search_title).frame(height: geometry.size.height - 57).tag("Search").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                        }
                    case "Genius":
                        itunes_genius_view(genius_selected_segment: $genius_selected_segment).frame(height: geometry.size.height - 57).tag("Search").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "More":
                        itunes_more().frame(height: geometry.size.height - 57)
                            .tag("More")
                    default:
                        blank_appstore_view().frame(height: geometry.size.height - 57)
                            .tag("More")
                    }
                }.background(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0), .init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0.5), .init(color: Color.white, location: 0.5), .init(color: Color.white, location: 1)]), startPoint: .top, endPoint: .bottom))
                ZStack {
                    Rectangle().fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.02), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom)).frame(height:57)
                    HStack(spacing: 0){
                        
                        ForEach(itunes_tabs,id: \.self){image in
                            TabButton_iTunes(image: image, selectedTab: $selectedTab, geometry: geometry)
                            
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

//** MARK: iTunes Music View

struct itunes_music_view: View {
    @StateObject var new_music_observer: iTunesMusicObserver
    @ObservedObject var top_tens_obs = top_ten_song_categories_observer()
    @Binding var selected_segment: Int
    @Binding var music_show_music: Bool
    @Binding var music_selected_music: Music_Data.Results?
    @Binding var selected_category: top_ten_song_categories_datetype
    @Binding var music_show_category: Bool
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing:0) {
                ScrollView(showsIndicators: true) {
                    if selected_segment == 0 {
                        VStack {
                            Spacer().frame(height: 10)
                            HStack {
                                Text("New Music").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", size: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 12)
                                Spacer()
                            }
                            if new_music_observer.new_music.isEmpty {
                                Spacer().frame(height:geometry.size.height)
                            } else {
                                VStack(spacing:0){
                                    ForEach(new_music_observer.new_music, id:\.collectionID) { music in
                                        Button(action:{
                                            music_selected_music = music;forward_or_backward = false; withAnimation(.linear(duration: 0.28)) {music_show_music = true}
                                            
                                        }) {
                                            VStack(spacing: 0) {
                                                HStack {
                                                    WebImage(url: music.artworkUrl100).resizable().placeholder {
                                                        Rectangle().foregroundColor(.gray)
                                                    }.frame(width:89, height: 89).border_top(width: 1, edges:[.trailing], color: Color(red: 217/255, green: 217/255, blue: 217/255))
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(music.artistName ?? "---").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1)
                                                        Text(music.collectionName ?? "---").font(.custom("Helvetica Neue Bold", size: 16)).foregroundColor(.black).lineLimit(1)
                                                        Text("0 Ratings").font(.custom("Helvetica Neue Regular", size: 14)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1)
                                                    }
                                                    Spacer()
                                                    Image("UITableNext").padding(.trailing, 12)
                                                }
                                                if music != new_music_observer.new_music.last {
                                                    Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                                                } else {
                                                    Spacer().frame(height: 1)
                                                }
                                                
                                            }.frame(height: 90)
                                        }.frame(height: 90)
                                    }
                                }.background(Color.white).cornerRadius(10).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                    .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25)).padding([.leading, .trailing], 12)
                            }
                            Spacer().frame(height: 20)
                            Text("Apple ID: OldOS@mac.com").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9).frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 252/255, green: 253/255, blue: 253/255), Color(red: 232/255, green: 235/255, blue: 241/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0).cornerRadius(9).strokeRoundedRectangle(9, Color(red: 133/255, green: 133/255, blue: 135/255), lineWidth: 0.5)
                            Spacer().frame(height: 30)
                            Text("iTunes Store Terms and Conditions...").multilineTextAlignment(.center).foregroundColor(Color(red: 48/255, green: 57/255, blue: 70/255)).font(.custom("Helvetica Neue Bold", size: 14)).shadow(color: Color.white.opacity(0.7), radius: 0, x: 0.0, y: 0.9).padding(.bottom, 30)
                        }.padding([.top, .bottom], 12)
                    } else  {
                        Spacer()
                        VStack {
                            VStack(spacing:0){
                                ForEach(top_tens_obs.categories) { category in
                                    Button(action:{
                                        selected_category = category;forward_or_backward = false; withAnimation(.linear(duration: 0.28)) {music_show_category = true}
                                        
                                    }) {
                                        VStack(spacing: 0) {
                                            HStack {
                                                WebImage(url: category.image_url).resizable().placeholder {
                                                    Rectangle().foregroundColor(.gray)
                                                }.frame(width:59, height: 59).border_top(width: 1, edges:[.trailing], color: Color(red: 217/255, green: 217/255, blue: 217/255))
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(category.name).font(.custom("Helvetica Neue Bold", size: 16)).foregroundColor(.black).lineLimit(1)
                                                }
                                                Spacer()
                                                Image("UITableNext").padding(.trailing, 12)
                                            }
                                            if category != top_tens_obs.categories.last {
                                                Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                                            } else {
                                                Spacer().frame(height: 1)
                                            }
                                            
                                        }.frame(height: 60)
                                    }.frame(height: 60)
                                }
                            }.background(Color.white).cornerRadius(10).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25)).padding([.leading, .trailing], 12)
                            Spacer().frame(height: 20)
                            Text("Apple ID: OldOS@mac.com").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9).frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 252/255, green: 253/255, blue: 253/255), Color(red: 232/255, green: 235/255, blue: 241/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0).cornerRadius(9).strokeRoundedRectangle(9, Color(red: 133/255, green: 133/255, blue: 135/255), lineWidth: 0.5)
                            Spacer().frame(height: 30)
                            Text("iTunes Store Terms and Conditions...").multilineTextAlignment(.center).foregroundColor(Color(red: 48/255, green: 57/255, blue: 70/255)).font(.custom("Helvetica Neue Bold", size: 14)).shadow(color: Color.white.opacity(0.7), radius: 0, x: 0.0, y: 0.9).padding(.bottom, 30)
                        }.padding([.top, .bottom], 12).onAppear() {
                            for category in top_tens_obs.categories {
                                fetch_first_image_for_top_songs_category(id: category.genre_id, completion: { result in
                                    if let index = top_tens_obs.categories.firstIndex(where: {$0.id == category.id}) {
                                        top_tens_obs.categories[index].image_url = result
                                        top_tens_obs.objectWillChange.send()
                                    }
                                })
                            }
                        }
                        
                    }
                }
            }
        }.background(settings_main_list())
    }
}

//** MARK: Music Category Destination

struct itunes_category_destination_view: View {
    @State var top_songs = [Music_Data.Results]()
    @State var top_albums = [Music_Data.Results]()
    @State var selected_segment: Int = 0
    @Binding var selected_category: top_ten_song_categories_datetype
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing:0) {
                ScrollView(showsIndicators: true) {
                    LazyVStack(alignment: .center) {
                        Spacer().frame(height: 10)
                        dual_segmented_control_big_bluegray(selected: $selected_segment, first_text: "Top Songs", second_text: "Top Albums").frame(width: geometry.size.width-24, height: 45)
                        Spacer().frame(height: 20)
                        if selected_segment == 0 {
                            Text("Tap to Preview, Double-Tap to View Album").multilineTextAlignment(.center).lineLimit(0).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Regular", size: 15)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 12)
                            if top_songs.isEmpty {
                                Spacer()
                            } else {
                                VStack(spacing:0){
                                    ForEach(top_songs, id:\.trackID) { track in
                                        Button(action:{
                                        }) {
                                            VStack(spacing: 0) {
                                                HStack {
                                                    WebImage(url: track.artworkUrl100).resizable().placeholder {
                                                        Rectangle().foregroundColor(.gray)
                                                    }.frame(width:59, height: 59).border_top(width: 1, edges:[.trailing], color: Color(red: 217/255, green: 217/255, blue: 217/255))
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text("\(Int(top_songs.firstIndex(of: track) ?? 0) + 1). \(track.trackName ?? "")").font(.custom("Helvetica Neue Bold", size: 16)).foregroundColor(.black).lineLimit(1)
                                                        Text(track.artistName ?? "").font(.custom("Helvetica Neue Regular", size: 14)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1)
                                                    }
                                                    Spacer()
                                                    tool_bar_rectangle_button_custom_radius(action: {
                                                    }, button_type: .itunes_store, content: "$\(track.trackPrice ?? 0)", height_modifier: -5, radius: 3.5).textCase(.uppercase).padding(.trailing, 12)
                                                }
                                                if track != top_songs.last {
                                                    Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                                                } else {
                                                    Spacer().frame(height: 1)
                                                }
                                                
                                            }.frame(height: 60)
                                        }.frame(height: 60)
                                    }
                                }.background(Color.white).cornerRadius(10).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                    .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25)).padding([.leading, .trailing], 12)
                            }
                            Spacer().frame(height: 20)
                            Text("Apple ID: OldOS@mac.com").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9).frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 252/255, green: 253/255, blue: 253/255), Color(red: 232/255, green: 235/255, blue: 241/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0).cornerRadius(9).strokeRoundedRectangle(9, Color(red: 133/255, green: 133/255, blue: 135/255), lineWidth: 0.5)
                            Spacer().frame(height: 30)
                            Text("iTunes Store Terms and Conditions...").multilineTextAlignment(.center).foregroundColor(Color(red: 48/255, green: 57/255, blue: 70/255)).font(.custom("Helvetica Neue Bold", size: 14)).shadow(color: Color.white.opacity(0.7), radius: 0, x: 0.0, y: 0.9).padding(.bottom, 30)
                        } else {
                            VStack(spacing:0){
                                ForEach(top_albums, id:\.collectionID) { music in
                                    Button(action:{
                                    }) {
                                        VStack(spacing: 0) {
                                            HStack {
                                                WebImage(url: music.artworkUrl100).resizable().placeholder {
                                                    Rectangle().foregroundColor(.gray)
                                                }.frame(width:89, height: 89).border_top(width: 1, edges:[.trailing], color: Color(red: 217/255, green: 217/255, blue: 217/255))
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(music.artistName ?? "---").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1)
                                                    Text("\(Int((top_albums.firstIndex(of: music) ?? 0) + 1)). \(music.collectionName ?? "---")").font(.custom("Helvetica Neue Bold", size: 16)).foregroundColor(.black).lineLimit(1)
                                                    Text("0 Ratings").font(.custom("Helvetica Neue Regular", size: 14)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1)
                                                }
                                                Spacer()
                                                Image("UITableNext").padding(.trailing, 12)
                                            }
                                            if music != top_albums.last {
                                                Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                                            } else {
                                                Spacer().frame(height: 1)
                                            }
                                            
                                        }.frame(height: 90)
                                    }.frame(height: 90)
                                }
                            }.background(Color.white).cornerRadius(10).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25)).padding([.leading, .trailing], 12)
                            
                            Spacer().frame(height: 20)
                            Text("Apple ID: OldOS@mac.com").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9).frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 252/255, green: 253/255, blue: 253/255), Color(red: 232/255, green: 235/255, blue: 241/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0).cornerRadius(9).strokeRoundedRectangle(9, Color(red: 133/255, green: 133/255, blue: 135/255), lineWidth: 0.5)
                            Spacer().frame(height: 30)
                            Text("iTunes Store Terms and Conditions...").multilineTextAlignment(.center).foregroundColor(Color(red: 48/255, green: 57/255, blue: 70/255)).font(.custom("Helvetica Neue Bold", size: 14)).shadow(color: Color.white.opacity(0.7), radius: 0, x: 0.0, y: 0.9).padding(.bottom, 30)
                        }
                    }.padding([.top, .bottom], 12).onAppear() {
                        //Top Songs
                        let id = selected_category.genre_id
                        let songs_url = URL(string: "https://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/topsongs/sf=143441/genre=\(id)/xml")!
                        let songs_parser = FeedParser(URL: songs_url)
                        songs_parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let feed):
                                    let rssFeed = feed.atomFeed
                                    for item in rssFeed?.entries ?? [] {
                                        fetch_music_data_atom_song(item, completion: { result in
                                            DispatchQueue.main.async {
                                                self.top_songs.append(result)
                                            }
                                        })
                                    }
                                case .failure(let error):
                                    print(error)
                                }
                            }
                        }
                        
                        //Top Albums
                        let albums_url = URL(string: "https://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/topalbums/sf=143441/genre=\(id)/xml")!
                        let albums_parser = FeedParser(URL: albums_url)
                        albums_parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let feed):
                                    let rssFeed = feed.atomFeed
                                    for item in rssFeed?.entries ?? [] {
                                        fetch_music_data_atom(item, completion: { result in
                                            DispatchQueue.main.async {
                                                self.top_albums.append(result)
                                            }
                                        })
                                    }
                                case .failure(let error):
                                    print(error)
                                }
                            }
                        }
                    }
                    
                }
            }
        }.background(settings_main_list())
    }
}

//** MARK: Music Destination

struct music_destination: View {
    @Binding var music_selected_music: Music_Data.Results?
    @State var tracks = [Music_Data.Results]()
    func format_iso_date(_ date: String) -> String {
        let iso_formatter = ISO8601DateFormatter()
        let iso_date = iso_formatter.date(from: date) ?? Date()
        let date_formater = DateFormatter()
        date_formater.dateFormat = "MMM dd, yyyy"
        return date_formater.string(from: iso_date)
    }
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing:0) {
                    
                    HStack(alignment: .top) {
                        ZStack {
                            WebImage(url: music_selected_music?.artworkUrl100).resizable().placeholder {
                                Rectangle().foregroundColor(.gray)
                            }.frame(width:75, height: 75).clipped().mask(LinearGradient([(color: Color.clear, location: 0), (color: Color.clear, location: 0.78), (color: Color.white.opacity(0.4), location: 1)], from: .top, to: .bottom)).rotationEffect(.degrees(-180)).offset(y:75).rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0)).padding(.leading, 12)//.opacity(0.15)
                            WebImage(url:  music_selected_music?.artworkUrl100).resizable().placeholder {
                                Rectangle().foregroundColor(.gray)
                            }.frame(width:75, height: 75).padding(.leading, 12)
                        }.frame(height:105).clipped()
                        
                        VStack(alignment:.leading, spacing: 4) {
                            Spacer().frame(height: 2)
                            Text(music_selected_music?.artistName ?? "").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(.black).lineLimit(1).multilineTextAlignment(.leading)
                            Text(music_selected_music?.collectionName ?? "").font(.custom("Helvetica Neue Bold", size: 22)).foregroundColor(.black).lineLimit(1).multilineTextAlignment(.leading)
                            Text("Genre: \(music_selected_music?.primaryGenreName ?? "")").font(.custom("Helvetica Neue Bold", size: 10)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1).multilineTextAlignment(.leading)
                            Text("Released \(format_iso_date(music_selected_music?.releaseDate ?? ""))").font(.custom("Helvetica Neue Bold", size: 10)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1).multilineTextAlignment(.leading)
                            Text("\(tracks.count) Songs").font(.custom("Helvetica Neue Bold", size: 10)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1).multilineTextAlignment(.leading)
                            tool_bar_rectangle_button_custom_radius(action: {
                            }, button_type: .itunes_store, content: "$\(music_selected_music?.collectionPrice ?? 0)", height_modifier: -5, radius: 3.5).textCase(.uppercase)
                            Spacer()
                        }.padding(.top, 10)
                        Spacer()
                    }
                    Button(action:{
                        //
                    }) {
                        VStack {
                            Rectangle().fill(Color(red: 230/255, green: 230/255, blue: 230/255)).frame(height:1)
                            Spacer()
                            HStack(spacing: 2) {
                                Spacer().frame(width: 20)
                                ForEach(0..<5) { _ in
                                    ZStack {
                                        Image("UserRatingBorderedStarsBackground")
                                    }
                                }.offset(y:4)
                                Spacer()
                                Image("UITableNext").padding(.trailing, 12)
                            }
                            Spacer()
                            Spacer().frame(height:1)
                        }.frame(height:44).background(Color(red: 221/255, green: 222/255, blue: 224/255))
                    }.frame(height: 44)
                    ForEach(tracks, id: \.trackID) { track in
                        Button(action:{
                            //
                        }) {
                            VStack {
                                if track == tracks[0] {
                                    Rectangle().fill(Color(red: 230/255, green: 230/255, blue: 230/255)).frame(height:1)
                                }
                                Spacer()
                                HStack {
                                    HStack {
                                        Spacer()
                                        Text("\(String(Int(tracks.firstIndex(of: track) ?? 0) + 1))").font(.custom("Helvetica Neue Bold", size: 12)).foregroundColor(.black).lineLimit(1).multilineTextAlignment(.leading)
                                        Spacer()
                                    }.frame(width:40)
                                    Text(track.trackName ?? "---").font(.custom("Helvetica Neue Bold", size: 12)).foregroundColor(.black).lineLimit(1).padding(.leading, 14)
                                    Spacer()
                                    if track.trackExplicitness == "explicit" {
                                        Image("Explicit").resizable().renderingMode(.template).scaledToFit().foregroundColor(Color(red: 204/255, green: 0/255, blue: 0/255)).frame(width: 35).padding(.trailing, 5)
                                    }
                                    tool_bar_rectangle_button_custom_radius(action: {
                                    }, button_type: .itunes_store, content: "$\(track.trackPrice ?? 0)", height_modifier: -5, radius: 3.5).textCase(.uppercase).padding(.trailing, 12)
                                }
                                Spacer()
                                Rectangle().fill(Color(red: 230/255, green: 230/255, blue: 230/255)).frame(height:1)
                            }.overlay(
                                ZStack {
                                    HStack(alignment:.center) {
                                        Rectangle().fill(Color(red: 230/255, green: 230/255, blue: 230/255)).frame(width:1).padding(.leading, 45)
                                        Spacer()
                                    }
                                }
                                
                            ).background((tracks.firstIndex(of: track) ?? 0) % 2  == 0 ? Color(red: 203/255, green: 203/255, blue: 208/255) : Color(red: 221/255, green: 222/255, blue: 224/255))
                        }.frame(height: 44)
                    }
                    Text(music_selected_music?.copyright ?? "").font(.custom("Helvetica Neue Regular", size: 12)).foregroundColor(Color(red: 120/255, green: 121/255, blue: 121/255)).multilineTextAlignment(.leading).padding([.top, .bottom], 12)
                }
                
            }.background(Color(red: 203/255, green: 204/255, blue: 207/255))
        }.onAppear() {
            fetch_music_data_tracks(music_selected_music?.id ?? 0) { result in
                tracks = result
                tracks.removeFirst()
            }
        }
    }
    func get_release_date(_ date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        let yearString = dateFormatter.string(from: date)
        return yearString
    }
}

//** MARK: iTunes Videos View

struct itunes_videos_view: View {
    @StateObject var new_movietv_observer: iTunesMovieVideoObserver
    @Binding var selected_segment_videos: Int
    @Binding var videos_show_movie: Bool
    @Binding var videos_selected_movie: Music_Data.Results?
    @Binding var videos_show_tv: Bool
    @Binding var videos_selected_tv: Music_Data.Results?
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing:0) {
                ScrollView(showsIndicators: true) {
                    if selected_segment_videos == 0 {
                        VStack {
                            Spacer().frame(height: 10)
                            HStack {
                                Text("New Movies Chart").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", size: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 12)
                                Spacer()
                            }
                            if new_movietv_observer.new_movies.isEmpty {
                                Spacer().frame(height:geometry.size.height)
                            } else {
                                VStack(spacing:0){
                                    ForEach(new_movietv_observer.new_movies, id:\.trackID) { video in
                                        Button(action:{
                                            videos_selected_movie = video;forward_or_backward = false; withAnimation(.linear(duration: 0.28)) {videos_show_movie = true}
                                            
                                        }) {
                                            VStack(spacing: 0) {
                                                HStack {
                                                    WebImage(url: video.artworkUrl100).resizable().placeholder {
                                                        Rectangle().foregroundColor(.gray)
                                                    }.frame(width:89*67/100, height: 89).border_top(width: 1, edges:[.trailing], color: Color(red: 217/255, green: 217/255, blue: 217/255))
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(video.primaryGenreName ?? "---").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1)
                                                        Text(video.trackName ?? "---").font(.custom("Helvetica Neue Bold", size: 16)).foregroundColor(.black).lineLimit(1)
                                                        Text("0 Ratings").font(.custom("Helvetica Neue Regular", size: 14)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1)
                                                    }
                                                    Spacer()
                                                    Image("UITableNext").padding(.trailing, 12)
                                                }
                                                if video != new_movietv_observer.new_movies.last {
                                                    Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                                                } else {
                                                    Spacer().frame(height: 1)
                                                }
                                                
                                            }.frame(height: 90)
                                        }.frame(height: 90)
                                    }
                                }.background(Color.white).cornerRadius(10).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                    .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25)).padding([.leading, .trailing], 12)
                            }
                            Spacer().frame(height: 20)
                            Text("Apple ID: OldOS@mac.com").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9).frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 252/255, green: 253/255, blue: 253/255), Color(red: 232/255, green: 235/255, blue: 241/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0).cornerRadius(9).strokeRoundedRectangle(9, Color(red: 133/255, green: 133/255, blue: 135/255), lineWidth: 0.5)
                            Spacer().frame(height: 30)
                            Text("iTunes Store Terms and Conditions...").multilineTextAlignment(.center).foregroundColor(Color(red: 48/255, green: 57/255, blue: 70/255)).font(.custom("Helvetica Neue Bold", size: 14)).shadow(color: Color.white.opacity(0.7), radius: 0, x: 0.0, y: 0.9).padding(.bottom, 30)
                        }.padding([.top, .bottom], 12)
                    }
                    if selected_segment_videos == 1 {
                        VStack {
                            Spacer().frame(height: 10)
                            HStack {
                                Text("Top TV Shows").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", size: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 12)
                                Spacer()
                            }
                            if new_movietv_observer.new_tv.isEmpty {
                                Spacer().frame(height:geometry.size.height)
                            } else {
                                VStack(spacing:0){
                                    ForEach(new_movietv_observer.new_tv, id:\.collectionID) { video in
                                        Button(action:{
                                            videos_selected_movie = video;forward_or_backward = false; withAnimation(.linear(duration: 0.28)) {videos_show_movie = true}
                                            
                                        }) {
                                            VStack(spacing: 0) {
                                                HStack {
                                                    WebImage(url: video.artworkUrl100).resizable().placeholder {
                                                        Rectangle().foregroundColor(.gray)
                                                    }.frame(width:89, height: 89).border_top(width: 1, edges:[.trailing], color: Color(red: 217/255, green: 217/255, blue: 217/255))
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(video.primaryGenreName ?? "---").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1)
                                                        Text(video.collectionName ?? "---").font(.custom("Helvetica Neue Bold", size: 16)).foregroundColor(.black).lineLimit(1)
                                                        Text("0 Ratings").font(.custom("Helvetica Neue Regular", size: 14)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1)
                                                    }
                                                    Spacer()
                                                    Image("UITableNext").padding(.trailing, 12)
                                                }
                                                if video != new_movietv_observer.new_tv.last {
                                                    Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                                                } else {
                                                    Spacer().frame(height: 1)
                                                }
                                                
                                            }.frame(height: 90)
                                        }.frame(height: 90)
                                    }
                                }.background(Color.white).cornerRadius(10).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                    .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25)).padding([.leading, .trailing], 12)
                            }
                            Spacer().frame(height: 20)
                            Text("Apple ID: OldOS@mac.com").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9).frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 252/255, green: 253/255, blue: 253/255), Color(red: 232/255, green: 235/255, blue: 241/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0).cornerRadius(9).strokeRoundedRectangle(9, Color(red: 133/255, green: 133/255, blue: 135/255), lineWidth: 0.5)
                            Spacer().frame(height: 30)
                            Text("iTunes Store Terms and Conditions...").multilineTextAlignment(.center).foregroundColor(Color(red: 48/255, green: 57/255, blue: 70/255)).font(.custom("Helvetica Neue Bold", size: 14)).shadow(color: Color.white.opacity(0.7), radius: 0, x: 0.0, y: 0.9).padding(.bottom, 30)
                        }.padding([.top, .bottom], 12)
                    }
                    if selected_segment_videos == 2 {
                        VStack {
                            Spacer().frame(height: 10)
                            HStack {
                                Text("Top Music Videos").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", size: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 12)
                                Spacer()
                            }
                            if new_movietv_observer.new_music.isEmpty {
                                Spacer().frame(height:geometry.size.height)
                            } else {
                                VStack(spacing:0){
                                    ForEach(new_movietv_observer.new_music, id:\.trackID) { video in
                                        Button(action:{
                                            videos_selected_movie = video;forward_or_backward = false; withAnimation(.linear(duration: 0.28)) {videos_show_movie = true}
                                            
                                        }) {
                                            VStack(spacing: 0) {
                                                HStack {
                                                    WebImage(url: video.artworkUrl100).resizable().placeholder {
                                                        Rectangle().foregroundColor(.gray)
                                                    }.aspectRatio(contentMode: .fit).frame(width:89, height: 89).background(Color.black).border_top(width: 1, edges:[.trailing], color: Color(red: 217/255, green: 217/255, blue: 217/255))
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(video.primaryGenreName ?? "---").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1)
                                                        Text(video.trackName ?? "---").font(.custom("Helvetica Neue Bold", size: 16)).foregroundColor(.black).lineLimit(1)
                                                        Text("0 Ratings").font(.custom("Helvetica Neue Regular", size: 14)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1)
                                                    }
                                                    Spacer()
                                                    Image("UITableNext").padding(.trailing, 12)
                                                }
                                                if video != new_movietv_observer.new_music.last {
                                                    Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                                                } else {
                                                    Spacer().frame(height: 1)
                                                }
                                                
                                            }.frame(height: 90)
                                        }.frame(height: 90)
                                    }
                                }.background(Color.white).cornerRadius(10).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                    .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25)).padding([.leading, .trailing], 12)
                            }
                            Spacer().frame(height: 20)
                            Text("Apple ID: OldOS@mac.com").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9).frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 252/255, green: 253/255, blue: 253/255), Color(red: 232/255, green: 235/255, blue: 241/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0).cornerRadius(9).strokeRoundedRectangle(9, Color(red: 133/255, green: 133/255, blue: 135/255), lineWidth: 0.5)
                            Spacer().frame(height: 30)
                            Text("iTunes Store Terms and Conditions...").multilineTextAlignment(.center).foregroundColor(Color(red: 48/255, green: 57/255, blue: 70/255)).font(.custom("Helvetica Neue Bold", size: 14)).shadow(color: Color.white.opacity(0.7), radius: 0, x: 0.0, y: 0.9).padding(.bottom, 30)
                        }.padding([.top, .bottom], 12)
                    }
                }
            }
        }.background(settings_main_list())
    }
}

//You might ask why we're doing it like this — the short and simple answer is Apple doesn't give us access to most Movie/Video data. I'd still like to give the user the experince, so we use some workarounds with a WebView. P.S. this is literally how Apple does it, iTunes is basically one giant webview.
struct search_destination: View {
    @Binding var search_selected_item_url: URL?
    @Binding var video_title: String?
    @State var show_video: Bool = false
    var body: some View {
        ZStack {
            settings_main_list().overlay(ZStack {
                HStack {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                    Spacer().frame(width: 8)
                    Text("Loading...").font(.custom("Helvetica Neue Bold", size: 16)).foregroundColor(Color(red: 48/255, green: 52/255, blue: 59/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                    Spacer()
                    
                }
            })
            MovieWebview(url: search_selected_item_url ?? URL(string: "google.com")!, show_video: $show_video, video_title: $video_title).opacity(show_video == true ? 1 : 0)
        }
    }
}

//You might ask why we're doing it like this — the short and simple answer is Apple doesn't give us access to most Movie/Video data. I'd still like to give the user the experince, so we use some workarounds with a WebView. P.S. this is literally how Apple does it, iTunes is basically one giant webview.
struct movies_destination: View {
    @Binding var videos_selected_movie: Music_Data.Results?
    @Binding var video_title: String?
    @State var show_video: Bool = false
    var body: some View {
        ZStack {
            settings_main_list().overlay(ZStack {
                HStack {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                    Spacer().frame(width: 8)
                    Text("Loading...").font(.custom("Helvetica Neue Bold", size: 16)).foregroundColor(Color(red: 48/255, green: 52/255, blue: 59/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                    Spacer()
                    
                }
            })
            MovieWebview(url: videos_selected_movie?.collectionViewURL ?? videos_selected_movie?.trackViewURL ?? URL(string: "google.com")!, show_video: $show_video, video_title: $video_title).opacity(show_video == true ? 1 : 0)
        }
    }
}


//I just think the way we do this is so cool. We modify our URL request to get access to a legacy version of the App Store. We then modify it with custom CSS in style.css to fix view size bugs. *Chefs Kiss*
struct MovieWebview: UIViewRepresentable {
    let url: URL
    @Binding var show_video: Bool
    @Binding var video_title: String?
    @State var past_url: URL?
    
    
    func makeUIView(context: UIViewRepresentableContext<MovieWebview>) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.suppressesIncrementalRendering = true
        
        let webview = WKWebView(frame: .zero, configuration: configuration)
        webview.isOpaque = false
        webview.backgroundColor = UIColor(red: 203/255, green: 204/255, blue: 207/255, alpha: 1)
        past_url = url
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("iTunes-iPad/4.3 (2; 32GB)", forHTTPHeaderField: "User-Agent")
        urlRequest.addValue("143441-1,2", forHTTPHeaderField: "X-Apple-Store-Front")
        webview.navigationDelegate = context.coordinator
        webview.customUserAgent = "iTunes-iPad/4.3 (2; 32GB)"
        webview.load(urlRequest)
        return webview
    }
    
    func updateUIView(_ webview: WKWebView, context: UIViewRepresentableContext<MovieWebview>) {
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: MovieWebview
        
        init(_ parent: MovieWebview) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            
            guard let path = Bundle.main.path(forResource: "style", ofType: "css") else {
                print("SHIT")
                return
            }
            
            let cssString = try! String(contentsOfFile: path).components(separatedBy: .newlines).joined()
            
            let source = """
               var style = document.createElement('style');
               style.innerHTML = '\(cssString)';
               document.head.appendChild(style);
             """
            
            webView.evaluateJavaScript(source, completionHandler: { result, error in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.parent.show_video = true
                    self.parent.video_title = webView.title
                }
                print("called show", self.parent.show_video)
            })
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            guard let url = (navigationResponse.response as! HTTPURLResponse).url else {
                decisionHandler(.cancel)
                return
            }
            if url != self.parent.past_url {
                self.parent.past_url = url
                self.parent.show_video = false
                decisionHandler(.cancel)
                var urlRequest = URLRequest(url: url)
                urlRequest.httpMethod = "GET"
                urlRequest.addValue("iTunes-iPad/4.3 (2; 32GB)", forHTTPHeaderField: "User-Agent")
                urlRequest.addValue("143441-1,2", forHTTPHeaderField: "X-Apple-Store-Front")
                webView.load(urlRequest)
            } else {
                let response = navigationResponse.response as? HTTPURLResponse
                decisionHandler(.allow)
            }
        }
        
    }
    
}

//** MARK: iTunes Search

struct search_section: Identifiable {
    let id = UUID()
    let section_item: SearchData.Items
    let contents: [SearchData.Items]
}

struct itunes_search: View {
    @Binding var search_results: [search_section]
    @Binding var search_selected_item_url: URL?
    @Binding var search_show_result: Bool
    @Binding var forward_or_backward: Bool
    @Binding var editing_state: String
    var body: some View {
        GeometryReader { geometry in
            ZStack {
            VStack(spacing:0) {
                ScrollView(showsIndicators: true) {
                    LazyVStack(alignment: .center, spacing: 20) {
                        ForEach(search_results, id:\.id) { result in
                            VStack(spacing: 10) {
                                HStack {
                                    Text(result.section_item.title ?? "").foregroundColor(Color(red: 78/255, green: 86/255, blue: 106/255)).font(.custom("Helvetica Neue Bold", size: 18)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding(.leading, 12)
                                    Spacer()
                                }
                                VStack(alignment: .leading) {
                                    if (result.section_item.title ?? "") == "Songs" || (result.section_item.title ?? "") == "Ringtones" {
                                        Text("Tap to Preview, Double-Tap to View Album").multilineTextAlignment(.center).lineLimit(0).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Regular", size: 15)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 12)
                                    }
                                    VStack(spacing:0){
                                        ForEach(result.contents, id:\.id) { content in
                                            
                                            Button(action:{
                                                
                                                if content.type == "link" {
                                                    if let url = URL(string: content.url ?? "") {
                                                        search_selected_item_url = url;forward_or_backward = false; withAnimation(.linear(duration: 0.28)) {search_show_result = true}
                                                    }
                                                }
                                                
                                            }) {
                                                VStack(spacing: 0) {
                                                    if content.type == "link" {
                                                        HStack {
                                                            WebImage(url: URL(string: content.artworkUrls?.last?.url ?? "")).resizable().placeholder {
                                                                Image("PlaceholderBig").resizable().frame(width: 60, height: 60)
                                                            }.scaledToFit().frame(width:60, height: 60).background(Color.black).border_top(width: 1, edges:[.trailing], color: Color(red: 217/255, green: 217/255, blue: 217/255))
                                                            VStack(alignment: .leading, spacing: 4) {
                                                                Text(content.containerName ?? content.artistName ?? "---").font(.custom("Helvetica Neue Regular", size: 13)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1)
                                                                Text(content.title ?? "---").font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.black).lineLimit(1)
                                                                if content.linkType == "tv-episode" {
                                                                    Text(content.title2 ?? "---").font(.custom("Helvetica Neue Regular", size: 13)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1)
                                                                }
                                                            }
                                                            Spacer()
                                                            if content.mediaType == "video" {
                                                                Image("MediaTypeVideo")
                                                            }
                                                            Image("UITableNext").padding(.trailing, 12)
                                                        }
                                                    }
                                                    if content.type == "song" || content.type == "ringtone" {
                                                        HStack {
                                                            WebImage(url: URL(string: content.artworkUrls?.last?.url ?? "")).resizable().placeholder {
                                                                Image("PlaceholderBig").resizable().frame(width: 60, height: 60)
                                                            }.frame(width:60, height: 60).scaledToFit().background(Color.black).border_top(width: 1, edges:[.trailing], color: Color(red: 217/255, green: 217/255, blue: 217/255))
                                                            VStack(alignment: .leading, spacing: 4) {
                                                                Text(content.containerName ?? content.artistName ?? "---").font(.custom("Helvetica Neue Regular", size: 13)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1)
                                                                Text(content.title ?? "---").font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.black).lineLimit(1)
                                                                Text(content.collectionName ?? "---").font(.custom("Helvetica Neue Regular", size: 13)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1)
                                                            }
                                                            Spacer()
                                                            if content.type == "ringtone" {
                                                                Image("MediaTypeRingtone")
                                                            }
                                                            tool_bar_rectangle_button_custom_radius(action: {
                                                            }, button_type: .itunes_store, content: "$\(content.flavors?._2256?.price ?? 0)", height_modifier: -5, radius: 3.5).textCase(.uppercase).padding(.trailing, 12)
                                                        }
                                                    }
                                                    if content.type == "pagination" {
                                                        HStack {
                                                            Rectangle().fill(Color.white).frame(width:60, height: 60)
                                                            VStack(alignment: .leading, spacing: 4) {
                                                                Text(content.title ?? "---").font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(Color(red: 33/255, green: 80/255, blue: 224/255)).lineLimit(1)
                                                            }
                                                            Spacer()
                                                            Image("UITableNext").padding(.trailing, 12)
                                                        }
                                                    }
                                                    if content != result.contents.last {
                                                        Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                                                    } else {
                                                        Spacer().frame(height: 1)
                                                    }
                                                }.frame(height: 60)
                                            }.frame(height: 60)
                                        }
                                    }.background(Color.white).cornerRadius(10).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                        .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25)).padding([.leading, .trailing], 12)
                                }
                            }
                        }
                        if search_results.isEmpty {
                            Spacer().frame(height: geometry.size.height)
                        }
                        Spacer().frame(height: 30)
                        Text("iTunes Store Terms and Conditions...").multilineTextAlignment(.center).foregroundColor(Color(red: 48/255, green: 57/255, blue: 70/255)).font(.custom("Helvetica Neue Bold", size: 14)).shadow(color: Color.white.opacity(0.7), radius: 0, x: 0.0, y: 0.9).padding(.bottom, 30)
                    }.padding([.top, .bottom], 12)
                }
            }
                if editing_state == "Active" || editing_state == "Active_Empty" {
                Color.black.opacity(0.9).edgesIgnoringSafeArea(.all)
                }
            }
        }.background(settings_main_list())
    }
}

//** MARK: iTunes Genius

struct itunes_genius_view: View {
    @Binding var genius_selected_segment: Int
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Image("geniusatom").resizable().scaledToFit().frame(width: 70).padding(.top, 100)
                Spacer().frame(height: 15)
                Text("You do not currently have any Genius\nrecommendations for \(genius_selected_segment == 0 ? "Music" : genius_selected_segment == 1 ? "Movies" : "TV Shows").").multilineTextAlignment(.center).font(.custom("Helvetica Neue Bold", size: 17)).foregroundColor(.black).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                Spacer().frame(height: 25)
                Text("To start seeing recommendations,\nteach Genius about your tastes by\ndownloading content from iTunes.").multilineTextAlignment(.center).font(.custom("Helvetica Neue Regular", size: 17)).foregroundColor(Color(red: 100/255, green: 101/255, blue: 102/255)).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                Spacer()
            }.frame(width: geometry.size.width, height: geometry.size.height).background(LinearGradient(gradient: Gradient(stops: [.init(color: Color.white, location: 0), .init(color: Color(red: 200/255, green: 202/255, blue: 204/255), location: 1)]), startPoint: .top, endPoint: .bottom))
        }
    }
}

//** MARK: iTunes More

struct itunes_more_item: Identifiable {
    let id = UUID()
    let name: String
    let image: String
}

struct itunes_more: View {
    var items = [itunes_more_item(name: "Tones", image: "BarTones"), itunes_more_item(name: "Podcasts", image: "BarPodcasts"), itunes_more_item(name: "Audiobooks", image: "BarAudioBooks"), itunes_more_item(name: "iTunes U", image: "BarITunesU"), itunes_more_item(name: "Downloads", image: "BarDownloads")]
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

class iTunesMusicObserver: ObservableObject {
    @Published var new_music = [Music_Data.Results]()
    @Published var recent_releases = [Music_Data.Results]()
    
    init() {
        parse_data()
    }
    func parse_data() {
        print("parsing data")
        let url = URL(string: "https://rss.itunes.apple.com/api/v1/us/itunes-music/new-music/all/10/explicit.rss?at=10laCr")!
        let parser = FeedParser(URL: url)
        parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let feed):
                    let rssFeed = feed.rssFeed
                    for item in rssFeed?.items ?? [] {
                        fetch_music_data(item, completion: { result in
                            DispatchQueue.main.async {
                                
                                self.new_music.append(result)
                            }
                        })
                    }
                case .failure(let error):
                    print(error)
                    print("were here bad")
                }
            }
        }
    }
    
}

class top_ten_song_categories_datetype: ObservableObject, Identifiable, Equatable {
    static func == (lhs: top_ten_song_categories_datetype, rhs: top_ten_song_categories_datetype) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id = UUID()
    @Published var name: String
    @Published var genre_id: String
    @Published var image_url: URL?
    
    init(name: String, genre_id: String, image_url: URL?) {
        self.name = name
        self.genre_id = genre_id
        self.image_url = image_url
    }
    
}


class top_ten_song_categories_observer: ObservableObject {
    @Published var categories = [top_ten_song_categories_datetype]()
    
    init() {
        self.categories = [
            top_ten_song_categories_datetype(name: "iTunes", genre_id: "", image_url: nil),
            top_ten_song_categories_datetype(name: "Alternative", genre_id: "20", image_url: nil),
            top_ten_song_categories_datetype(name: "Blues", genre_id: "2", image_url: nil),
            top_ten_song_categories_datetype(name: "Children's Music", genre_id: "4", image_url: nil),
            top_ten_song_categories_datetype(name: "Christian", genre_id: "22", image_url: nil),
            top_ten_song_categories_datetype(name: "Classical", genre_id: "5", image_url: nil),
            top_ten_song_categories_datetype(name: "Comedy", genre_id: "3", image_url: nil),
            top_ten_song_categories_datetype(name: "Country", genre_id: "6", image_url: nil),
            top_ten_song_categories_datetype(name: "Dance", genre_id: "17", image_url: nil),
            top_ten_song_categories_datetype(name: "Electronic", genre_id: "7", image_url: nil),
            top_ten_song_categories_datetype(name: "Hip-Hop/Rap", genre_id: "18", image_url: nil),
            top_ten_song_categories_datetype(name: "Holiday", genre_id: "8", image_url: nil),
            top_ten_song_categories_datetype(name: "Jazz", genre_id: "11", image_url: nil),
            top_ten_song_categories_datetype(name: "K-Pop", genre_id: "51", image_url: nil),
            top_ten_song_categories_datetype(name: "Latin", genre_id: "12", image_url: nil),
            top_ten_song_categories_datetype(name: "Metal", genre_id: "1153", image_url: nil),
            top_ten_song_categories_datetype(name: "Pop", genre_id: "14", image_url: nil),
            top_ten_song_categories_datetype(name: "R&B/Soul", genre_id: "15", image_url: nil),
            top_ten_song_categories_datetype(name: "Reggage", genre_id: "24", image_url: nil),
            top_ten_song_categories_datetype(name: "Rock", genre_id: "21", image_url: nil),
            top_ten_song_categories_datetype(name: "Singer/Sonwriter", genre_id: "1160", image_url: nil),
            top_ten_song_categories_datetype(name: "Soundtrack", genre_id: "16", image_url: nil),
            top_ten_song_categories_datetype(name: "Worldwide", genre_id: "19", image_url: nil)
        ]
    }
}




func getPostString(params:[String:String]) -> String
{
    var data = [String]()
    for(key, value) in params
    {
        data.append(key + "=\(value)")
        
    }
    return data.map { String($0) }.joined(separator: "&")
}


class iTunesMovieVideoObserver: ObservableObject {
    @Published var new_movies = [Music_Data.Results]()
    @Published var new_tv = [Music_Data.Results]()
    @Published var new_music = [Music_Data.Results]()
    
    init() {
        parse_data()
    }
    func parse_data() {
        print("parsing data")
        let url = URL(string: "https://rss.itunes.apple.com/api/v1/us/movies/top-movies/all/10/explicit.rss?at=10laCr")!
        let parser = FeedParser(URL: url)
        parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let feed):
                    let rssFeed = feed.rssFeed
                    for item in rssFeed?.items ?? [] {
                        fetch_movie_data(item, completion: { result in
                            DispatchQueue.main.async {
                                
                                self.new_movies.append(result)
                            }
                        })
                    }
                case .failure(let error):
                    print(error)
                    print("were here bad")
                }
            }
        }
        let tv_url = URL(string: "https://rss.itunes.apple.com/api/v1/us/tv-shows/top-tv-seasons/all/10/explicit.rss?at=10laCr")!
        let tv_parser = FeedParser(URL: tv_url)
        tv_parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let feed):
                    let rssFeed = feed.rssFeed
                    for item in rssFeed?.items ?? [] {
                        fetch_tv_data(item, completion: { result in
                            DispatchQueue.main.async {
                                
                                self.new_tv.append(result)
                            }
                        })
                    }
                case .failure(let error):
                    print(error)
                    print("were here bad")
                }
            }
        }
        let music_url = URL(string: "https://rss.itunes.apple.com/api/v1/us/music-videos/top-music-videos/all/10/explicit.rss?at=10laCr")!
        let music_parser = FeedParser(URL: music_url)
        music_parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let feed):
                    let rssFeed = feed.rssFeed
                    for item in rssFeed?.items ?? [] {
                        fetch_musicvideo_data(item, completion: { result in
                            DispatchQueue.main.async {
                                
                                self.new_music.append(result)
                            }
                        })
                    }
                case .failure(let error):
                    print(error)
                    print("were here bad")
                }
            }
        }
    }
    
}

/// A function that takes an RSSFeedItem (an application), fetches its ID, and grabs its parsed JSON data from itunes.apple.com.
/// - Parameters:
///   - application: RSSFeedItem passed to function.
///   - completion: Result which should be the first returned object in JSON array of Results.
func fetch_movie_data(_ video: RSSFeedItem, completion: @escaping (Music_Data.Results) -> Void) {
    //Our first step is to fetch the ID of the application, a trick we can do is to grab it from the URL...
    var id = ""
    if let id_range = video.link?.range(of: "(?<=id)[^?]+", options: .regularExpression) {
        id = (video.link?.substring(with: id_range) ?? "").filter("0123456789.".contains) //We do the filter to make sure we don't get any accidental chars
    }
    let url = URL(string: "https://itunes.apple.com/lookup?id=\(id)")!
    let request = URLRequest(url: url)
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
        
        if let error = error {
            print(error)
            return
        }
        
        // Parse JSON data
        if let data = data {
            guard let compiled_object = parseJsonMusicData(data: data) else {
                return
            }
            if compiled_object.isEmpty == false {
                completion(compiled_object[0])
            }
        }
    })
    
    task.resume()
}

/// A function that takes an RSSFeedItem (an application), fetches its ID, and grabs its parsed JSON data from itunes.apple.com.
/// - Parameters:
///   - application: RSSFeedItem passed to function.
///   - completion: Result which should be the first returned object in JSON array of Results.
func fetch_tv_data(_ video: RSSFeedItem, completion: @escaping (Music_Data.Results) -> Void) {
    //Our first step is to fetch the ID of the application, a trick we can do is to grab it from the URL...
    var id = ""
    if let id_range = video.link?.range(of: "(?<=id)[^?]+", options: .regularExpression) {
        id = (video.link?.substring(with: id_range) ?? "").filter("0123456789.".contains) //We do the filter to make sure we don't get any accidental chars
    }
    let url = URL(string: "https://itunes.apple.com/lookup?id=\(id)")!
    print(url, id, "ZSK")
    let request = URLRequest(url: url)
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
        
        if let error = error {
            print(error)
            return
        }
        
        // Parse JSON data
        if let data = data {
            guard let compiled_object = parseJsonMusicData(data: data) else {
                return
            }
            if compiled_object.isEmpty == false {
                completion(compiled_object[0])
            }
        }
    })
    
    task.resume()
}

/// A function that takes an RSSFeedItem (an application), fetches its ID, and grabs its parsed JSON data from itunes.apple.com.
/// - Parameters:
///   - application: RSSFeedItem passed to function.
///   - completion: Result which should be the first returned object in JSON array of Results.
func fetch_musicvideo_data(_ video: RSSFeedItem, completion: @escaping (Music_Data.Results) -> Void) {
    //Our first step is to fetch the ID of the application, a trick we can do is to grab it from the URL...
    var id = ""
    if let id_range = video.link?.range(of: "(?<=\\/)[0-9]+", options: .regularExpression) {
        id = (video.link?.substring(with: id_range) ?? "").filter("0123456789.".contains) //We do the filter to make sure we don't get any accidental chars
    }
    let url = URL(string: "https://itunes.apple.com/lookup?id=\(id)")!
    print(url, id, "ZSK")
    let request = URLRequest(url: url)
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
        
        if let error = error {
            print(error)
            return
        }
        
        // Parse JSON data
        if let data = data {
            guard let compiled_object = parseJsonMusicData(data: data) else {
                return
            }
            if compiled_object.isEmpty == false {
                completion(compiled_object[0])
            }
        }
    })
    
    task.resume()
}



func fetch_first_image_for_top_songs_category(id: String, completion: @escaping (URL) -> Void) {
    let paid_url = URL(string: "https://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/topalbums/sf=143441/genre=\(id)/xml")!
    let paid_parser = FeedParser(URL: paid_url)
    paid_parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
        DispatchQueue.main.async {
            switch result {
            case .success(let feed):
                let first_entry = feed.atomFeed?.entries?.first
                fetch_music_data_atom(first_entry ?? AtomFeedEntry(), completion: { result in
                    DispatchQueue.main.async {
                        completion(result.artworkUrl100)
                    }
                })
            case .failure(let error):
                print(error)
                completion(URL(string:"google.com")!)
            }
        }
    }
}

func fetch_music_data(_ music: RSSFeedItem, completion: @escaping (Music_Data.Results) -> Void) {
    //Our first step is to fetch the ID of the application, a trick we can do is to grab it from the URL...
    var id = ""
    print(music.link)
    let start_range = music.link?.range(of: "")
    if let id_range = music.link?.range(of: "(?<=\\/)[0-9](.*)(?=\\?)", options: .regularExpression) {
        id = (music.link?.substring(with: id_range) ?? "").filter("0123456789.".contains) //We do the filter to make sure we don't get any accidental chars
    }
    print(id)
    let url = URL(string: "https://itunes.apple.com/lookup?id=\(id)")!
    let request = URLRequest(url: url)
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
        
        if let error = error {
            print(error)
            return
        }
        
        // Parse JSON data
        if let data = data {
            guard let compiled_object = parseJsonMusicData(data: data) else {
                return
            }
            if compiled_object.isEmpty == false {
                completion(compiled_object[0])
            }
        }
    })
    
    task.resume()
}

func fetch_music_data_tracks(_ music: Int, completion: @escaping ([Music_Data.Results]) -> Void) {
    //Our first step is to fetch the ID of the application, a trick we can do is to grab it from the URL...
    var id = "\(music)"
    print(id)
    let url = URL(string: "https://itunes.apple.com/lookup?id=\(id)&entity=song")!
    let request = URLRequest(url: url)
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
        
        if let error = error {
            print(error)
            return
        }
        
        // Parse JSON data
        if let data = data {
            guard let compiled_object = parseJsonMusicData(data: data) else {
                return
            }
            if compiled_object.isEmpty == false {
                completion(compiled_object)
            }
        }
    })
    
    task.resume()
}

/// A function that takes an AtomFeedEntry (an application), fetches its ID, and grabs its parsed JSON data from itunes.apple.com.
/// - Parameters:
///   - application: AtomFeedEntry passed to function.
///   - completion: Result which should be the first returned object in JSON array of Results.
func fetch_music_data_atom(_ music: AtomFeedEntry, completion: @escaping (Music_Data.Results) -> Void) {
    //Our first step is to fetch the ID of the application, a trick we can do is to grab it from the URL...
    var id = ""
    if let id_range = music.id?.range(of: "(?<=\\/)[0-9](.*)(?=\\?)", options: .regularExpression) {
        id = (music.id?.substring(with: id_range) ?? "").filter("0123456789.".contains) //We do the filter to make sure we don't get any accidental chars
    }
    let url = URL(string: "https://itunes.apple.com/lookup?id=\(id)")!
    let request = URLRequest(url: url)
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
        
        if let error = error {
            print(error)
            return
        }
        
        // Parse JSON data
        if let data = data {
            guard let compiled_object = parseJsonMusicData(data: data) else {
                return
            }
            if compiled_object.isEmpty == false {
                completion(compiled_object[0])
            }
        }
    })
    
    task.resume()
}

/// A function that takes an AtomFeedEntry (an application), fetches its ID, and grabs its parsed JSON data from itunes.apple.com.
/// - Parameters:
///   - application: AtomFeedEntry passed to function.
///   - completion: Result which should be the first returned object in JSON array of Results.
func fetch_music_data_atom_song(_ music: AtomFeedEntry, completion: @escaping (Music_Data.Results) -> Void) {
    //Our first step is to fetch the ID of the application, a trick we can do is to grab it from the URL...
    var id = ""
    if let id_range = music.id?.range(of: "(?<=\\=)(.*)(?=\\&)", options: .regularExpression) {
        id = (music.id?.substring(with: id_range) ?? "").filter("0123456789.".contains) //We do the filter to make sure we don't get any accidental chars
    }
    print(id, "ZSK")
    let url = URL(string: "https://itunes.apple.com/lookup?id=\(id)")!
    let request = URLRequest(url: url)
    let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
        
        if let error = error {
            print(error)
            return
        }
        
        // Parse JSON data
        if let data = data {
            guard let compiled_object = parseJsonMusicData(data: data) else {
                return
            }
            if compiled_object.isEmpty == false {
                completion(compiled_object[0])
            }
        }
    })
    
    task.resume()
}

func parseJsonMusicData(data: Data) -> [Music_Data.Results]? {
    
    var application_data = [Music_Data.Results]()
    
    let decoder = JSONDecoder()
    
    do {
        let loanDataStore = try decoder.decode(Music_Data.self, from: data)
        application_data = loanDataStore.results
        
    } catch {
        print(error)
    }
    
    return application_data
}

struct Music_Data: Codable {
    struct Results: Codable, Identifiable, Equatable {
        var id: Int {return collectionID ?? trackID ?? 0}
        let wrapperType: String?
        let collectionType: String?
        let artistID: Int?
        let collectionID: Int?
        let amgArtistID: Int?
        let artistName: String
        let collectionName: String?
        let collectionCensoredName: String?
        let artistViewURL: URL?
        let collectionViewURL: URL?
        let artworkUrl60: URL
        let artworkUrl100: URL
        let collectionPrice: Double?
        let collectionExplicitness: String?
        let contentAdvisoryRating: String?
        let trackCount: Int?
        let copyright: String?
        let country: String
        let currency: String
        let releaseDate: String?
        let primaryGenreName: String
        let kind: String?
        let trackID: Int?
        let trackName: String?
        let trackCensoredName: String?
        let trackViewURL: URL?
        let previewURL: URL?
        let artworkUrl30: URL?
        let trackPrice: Double?
        let trackExplicitness: String?
        let discCount: Int?
        let discNumber: Int?
        let trackNumber: Int?
        let trackTimeMillis: Int?
        let isStreamable: Bool?
        let collectionArtistName: String?
        
        private enum CodingKeys: String, CodingKey {
            case wrapperType
            case collectionType
            case artistID = "artistId"
            case collectionID = "collectionId"
            case amgArtistID = "amgArtistId"
            case artistName
            case collectionName
            case collectionCensoredName
            case artistViewURL = "artistViewUrl"
            case collectionViewURL = "collectionViewUrl"
            case artworkUrl60
            case artworkUrl100
            case collectionPrice
            case collectionExplicitness
            case contentAdvisoryRating
            case trackCount
            case copyright
            case country
            case currency
            case releaseDate
            case primaryGenreName
            case kind
            case trackID = "trackId"
            case trackName
            case trackCensoredName
            case trackViewURL = "trackViewUrl"
            case previewURL = "previewUrl"
            case artworkUrl30
            case trackPrice
            case trackExplicitness
            case discCount
            case discNumber
            case trackNumber
            case trackTimeMillis
            case isStreamable
            case collectionArtistName
        }
    }
    
    let resultCount: Int
    let results: [Results]
}

struct itunes_title_bar : View {
    var title:String
    @Binding var selected_segment: Int
    @Binding var selected_segment_videos: Int
    @Binding var forward_or_backward: Bool
    @Binding var selectedTab:String
    @Binding var music_show_music: Bool
    @Binding var music_show_category: Bool
    @Binding var videos_show_movie: Bool
    @Binding var videos_show_tv: Bool
    @Binding var categories_current_view: String
    @Binding var search_results: [search_section]
    @Binding var search_show_application: Bool
    @Binding var search_selected_application: Application_Data.Results?
    @Binding var video_title: String?
    @Binding var genius_selected_segment: Int
    @Binding var search_show_result: Bool
    @State var search: String = ""
    @State var place_holder = ""
    @State var results_2 = [search_section]()
    var no_right_padding: Bool?
    @Binding var editing_state: String
    private let gradient = LinearGradient([.white, .white], to: .trailing)
    private let cancel_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    var show_edit: Bool
    var show_plus: Bool
    public var edit_action: (() -> Void)?
    public var plus_action: (() -> Void)?
    var body :some View {
        GeometryReader {geometry in
            ZStack {
                LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.49), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.49), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if (selectedTab != "Music" || music_show_music == true || music_show_category == true) && (selectedTab != "Search" || search_show_result == true) && (selectedTab != "Videos" || videos_show_movie == true || videos_show_tv == true) && (selectedTab != "Genius") {
                            Text(title).ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", size: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)).combined(with: .opacity)).id(title).frame(maxWidth: ((selectedTab == "Music" && music_show_music == true) || (selectedTab == "Videos" && videos_show_movie == true) || (selectedTab == "Search" && search_show_result == true)) ? 175 : .infinity)
                        } else if selectedTab == "Music" {
                            dual_segmented_control(selected: $selected_segment, first_text: "New Releases", second_text: "Top Tens", should_animate: false).frame(width: 220, height: 30)
                        } else if selectedTab == "Videos" {
                            tri_segmented_control(selected: $selected_segment_videos, first_text: "Movies", second_text: "TV Shows", third_text: "Music Videos", should_animate: false).frame(width: geometry.size.width-24, height: 30)
                        } else if selectedTab == "Search" {
                            VStack {
                                Spacer()
                                HStack {
                                    HStack {
                                        Spacer(minLength: 5)
                                        HStack (alignment: .center,
                                                spacing: 10) {
                                            Image("search_icon").resizable().font(Font.title.weight(.medium)).frame(width: 15, height: 15).padding(.leading, 5)
                                            // .foregroundColor(.gray)
                                            
                                            TextField ("Search", text: $search, onEditingChanged: { (changed) in
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
                                                    if search != "" {
                                                        
                                                        let headers: HTTPHeaders = [
                                                            "User-Agent": "Tunes-iPad/4.3 (2; 32GB)",
                                                            "X-Apple-Store-Front": "143441-1,2"
                                                        ]
                                                        guard let search_string = search.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {return}
                                                        AF.request("https://search.itunes.apple.com/WebObjects/MZSearch.woa/wa/search?term=\(search_string)&media=allWithRingtone", method: .get, headers: headers).response { response in
                                                            var statusCode = response.response?.statusCode
                                                            
                                                            switch response.result {
                                                            case .success:
                                                                print("status code is: \(String(describing: statusCode))")
                                                                if let data = response.data {
                                                                    do {
                                                                        search_results.removeAll()
                                                                        let final = try PropertyListDecoder().decode(SearchData.self, from: data)
                                                                        var temp_array = [SearchData.Items]()
                                                                        var is_first: Bool = false
                                                                        for item in final.items ?? [] {
                                                                            if item.type == "separator" {
                                                                                if is_first == false {
                                                                                    is_first = true
                                                                                    temp_array.append(item)
                                                                                } else {
                                                                                    if let first = temp_array.first {
                                                                                        search_results.append(search_section(section_item: first, contents:temp_array.filter({$0.type != "separator"})))
                                                                                        temp_array.removeAll()
                                                                                        temp_array.append(item)
                                                                                    }
                                                                                }
                                                                            } else {
                                                                                temp_array.append(item)
                                                                            }
                                                                        }
                                                                        
                                                                        for i in search_results {
                                                                            print("ZSK", i.section_item.title, i.contents.count)
                                                                        }
                                                                    } catch {
                                                                        print(error)
                                                                    }
                                                                }
                                                            case .failure(let error):
                                                                statusCode = error._code
                                                                print("status code is: \(String(describing: statusCode))")
                                                                print(error)
                                                            }
                                                            
                                                        }
                                                    }
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
                                        }
                                        
                                        .padding([.top,.bottom], 5)
                                        .padding(.leading, 5)
                                        .cornerRadius(40)
                                        Spacer(minLength: 8)
                                    } .ps_innerShadow(.capsule(gradient), radius:1.6, offset: CGPoint(0, 1), intensity: 0.7).strokeCapsule(Color(red: 166/255, green: 166/255, blue: 166/255), lineWidth: 0.33).padding(.leading, 5.5).padding(.trailing, 5.5)
                                }
                                Spacer()
                            }
                        } else if selectedTab == "Genius" {
                            tri_segmented_control(selected: $genius_selected_segment, first_text: "Music", second_text: "Movies", third_text: "TV Shows", should_animate: false).frame(width: geometry.size.width-24, height: 30)
                        }
                        Spacer()
                    }
                    Spacer()
                }
                if selectedTab == "Music", music_show_music == true {
                    VStack {
                        Spacer()
                        HStack {
                            Button(action:{
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)){music_show_music = false}
                            }){
                                ZStack {
                                    Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                                    HStack(alignment: .center) {
                                        Text("Music").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", size: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                                    }
                                }.padding(.leading, 6)
                            }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                            Spacer()
                        }
                        Spacer()
                    }.offset(y:-0.5)
                    
                }
                if selectedTab == "Music", music_show_category == true {
                    VStack {
                        Spacer()
                        HStack {
                            Button(action:{
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)){music_show_category = false}
                            }){
                                ZStack {
                                    Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                                    HStack(alignment: .center) {
                                        Text("Top Tens").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", size: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                                    }
                                }.padding(.leading, 6)
                            }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                            Spacer()
                        }
                        Spacer()
                    }.offset(y:-0.5)
                    
                }
                if selectedTab == "Videos", videos_show_movie == true {
                    VStack {
                        Spacer()
                        HStack {
                            Button(action:{
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)){videos_show_movie = false}
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                                    video_title = ""
                                }
                            }){
                                ZStack {
                                    Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                                    HStack(alignment: .center) {
                                        Text("Videos").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", size: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                                    }
                                }.padding(.leading, 6)
                            }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                            Spacer()
                        }
                        Spacer()
                    }.offset(y:-0.5)
                    
                }
                
                if selectedTab == "Categories", categories_current_view != "Main" {
                    VStack {
                        Spacer()
                        HStack {
                            Button(action:{
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)){categories_current_view = (categories_current_view == "Destination" ? "Category" : "Main")}
                            }){
                                ZStack {
                                    Image("Button_wp4").resizable().aspectRatio(contentMode: .fit).frame(width:84, height: 34.33783783783784)
                                    HStack(alignment: .center) {
                                        Text("Categories").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", size: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1).offset(x: 1)
                                    }
                                }.padding(.leading, 6)
                            }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                            Spacer()
                        }
                        Spacer()
                    }.offset(y:-0.5)
                    
                }
                
                if selectedTab == "Search", search_show_result == true {
                    VStack {
                        Spacer()
                        HStack {
                            Button(action:{
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)){search_show_result = false}
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
                
            }
        }
    }
}



struct TabButton_iTunes: View {
    
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
                            Image("\(image)_iTunes").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Music" ? 20 : (image == "Search" || image == "Genius") ? 25  : image == "Artists" ? 37.5 : 30.5, height: 30.5).overlay(
                                LinearGradient(gradient: Gradient(colors: [Color(red: 205/255, green: 233/255, blue: 249/255), Color(red: 75/255, green: 220/255, blue: 251/255)]), startPoint: .top, endPoint: .bottom)
                            ).mask(Image("\(image)_iTunes").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Music" ? 20 : (image == "Search" || image == "Genius") ? 25  : image == "Artists" ? 37.5 : 30.5, height: 30.5)).offset(y:-0.5)
                            
                            Image("\(image)_iTunes").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Music" ? 20 : (image == "Search" || image == "Genius") ? 25 : image == "Artists" ? 37.5 : 30, height: 30).overlay(
                                ZStack {
                                    if image == "More" {
                                        LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0/255, green: 145/255, blue: 230/255), location: 0), .init(color: Color(red: 21/255, green: 197/255, blue: 252/255), location: 1)]), startPoint: .top, endPoint: .bottom).rotationEffect(Angle(degrees: image == "More" ? 0 : -15)).frame(width: image == "More" ? 40 : 40, height: image == "More" ? 10 : 30).brightness(0.095)
                                    } else {
                                        LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 197/255, green: 210/255, blue: 229/255), location: 0), .init(color: Color(red: 99/255, green: 162/255, blue: 216/255), location: 0.47), .init(color: Color(red: 0/255, green: 145/255, blue: 230/255), location: 0.49), .init(color: Color(red: 21/255, green: 197/255, blue: 252/255), location: 1)]), startPoint: .top, endPoint: .bottom).rotationEffect(Angle(degrees: image == "More" ? 0 : -15)).frame(width: image == "More" ? 40 : 40, height: image == "Artists" ? 34 : 30).brightness(0.095).offset(y: image == "Artists" ? 2 : 0)
                                    }
                                }
                            ).mask(Image("\(image)_iTunes").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Music" ? 20 : (image == "Search" || image == "Genius") ? 25 : image == "Artists" ? 37.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.6), radius:2.5, x: 0, y:2.5)
                        }
                        HStack {
                            Spacer()
                            Text(image).foregroundColor(.white).font(.custom("Helvetica Neue Bold", size: 11))
                            Spacer()
                        }
                    }
                } else {
                    VStack(spacing: 2) {
                        Image("\(image)_iTunes").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Music" ? 20 : (image == "Search" || image == "Genius") ? 25 : image == "Artists" ? 37.5 : 30, height: 30).overlay(
                            LinearGradient(gradient: Gradient(colors: [Color(red: 157/255, green: 157/255, blue: 157/255), Color(red: 89/255, green: 89/255, blue: 89/255)]), startPoint: .top, endPoint: .bottom)
                        ).mask(Image("\(image)_iTunes").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Music" ? 20 : (image == "Search" || image == "Genius") ? 25 : image == "Artists" ? 37.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.75), radius: 0, x: 0, y: -1)
                        HStack {
                            Spacer()
                            Text(image).foregroundColor(Color(red: 168/255, green: 168/255, blue: 168/255)).font(.custom("Helvetica Neue Bold", size: 11))
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}


struct iTunes_Previews: PreviewProvider {
    static var previews: some View {
        iTunes()
    }
}
