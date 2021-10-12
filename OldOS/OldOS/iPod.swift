//
//  iPod.swift
//  OldOS
//
//  Created by Zane Kleinberg on 2/2/21.
//

import SwiftUI
import MediaPlayer
import StoreKit
import SwiftUIPager

//**MARK: Main Views
let alphabet = ["Search", "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z", "#"]
struct iPod: View {
    @State var current_nav_view: String = "Main"
    @State var prior_nav_view_coverflow: String = "Main"
    @State var did_utilize_coverflow: Bool = false
    @State var selectedPage = 1
    @State var forward_or_backward = false
    @State var selectedTab = "Playlists"
    @State var view_height: CGFloat = 0
    @State var current_album: MPMediaItemCollection = MPMediaItemCollection.init(items: [])
    @State var albums: [MPMediaItemCollection] = [MPMediaItemCollection]()
    @State var artists_current_view: String = "Artists"
    @State var current_artist: String = ""
    @State var playlist_current_nav_view: String = "Playlists"
    @State var pre_nav_switch: String = "Main"
    @State var playlist: MPMediaItemCollection = MPMediaItemCollection.init(items: [])
    let rotation_publisher = NotificationCenter.default
        .publisher(for: UIDevice.orientationDidChangeNotification).makeConnectable()
        .autoconnect()
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing:0) {
                    switch current_nav_view {
                    case "Main":
                        status_bar_in_app(selected_page:selectedPage).frame(minHeight: 24, maxHeight:24).zIndex(1)
                        ipod_title_bar(forward_or_backward: $forward_or_backward, current_nav_view: $current_nav_view, artists_current_view: $artists_current_view, playlist_current_nav_view: $playlist_current_nav_view, selectedTab: $selectedTab, title:selectedTab == "Artists" ? artists_current_view != "Artists" ? (current_artist) : selectedTab :  selectedTab == "Playlists" ? playlist_current_nav_view != "Playlists" ? (playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String ?? "---") : selectedTab : selectedTab).frame(height: 60).if(pre_nav_switch == "Coverflow") {
                            $0.transition(.opacity)
                        }.transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)).combined(with: .opacity))
                        iPodTabView(selectedTab: $selectedTab, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, artists_current_view: $artists_current_view, current_album: $current_album, current_artist: $current_artist, albums: $albums, playlist: $playlist, playlist_current_nav_view: $playlist_current_nav_view).clipped().if(pre_nav_switch == "Coverflow") {
                            $0.transition(.opacity)
                        }.transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Now Playing":
                        status_bar().frame(minHeight: 24, maxHeight:24).zIndex(1)
                        iPodNowPlaying(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, view_height: $view_height).clipped().if(pre_nav_switch == "Coverflow") {
                            $0.transition(.opacity)
                        }.transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Coverflow":
                        CoverFlowView().transition(.opacity)
                    default:
                        status_bar_in_app(selected_page:selectedPage).frame(minHeight: 24, maxHeight:24).zIndex(1)
                        ipod_title_bar(forward_or_backward: $forward_or_backward, current_nav_view: $current_nav_view, artists_current_view: $artists_current_view, playlist_current_nav_view: $playlist_current_nav_view, selectedTab: $selectedTab, title:selectedTab).frame(height: 60)
                        iPodTabView(selectedTab: $selectedTab, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, artists_current_view: $artists_current_view, current_album: $current_album, current_artist: $current_artist, albums: $albums, playlist: $playlist, playlist_current_nav_view: $playlist_current_nav_view).clipped().transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal:  .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    }
                }.clipped()
            }.onAppear() {
                view_height = geometry.size.height
                UIScrollView.appearance().bounces = true
                UITableView.appearance().backgroundColor = .clear
                UITableView.appearance().showsVerticalScrollIndicator = false
            }.onDisappear() {
                UIScrollView.appearance().bounces = false
                UITableView.appearance().showsVerticalScrollIndicator = true
            }.onReceive(rotation_publisher) { _ in
                print("publish rot, ZK")
                if UIDevice.current.orientation.isPortrait {
                    if did_utilize_coverflow {
                        withAnimation() {
                            current_nav_view = prior_nav_view_coverflow
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
                            pre_nav_switch = prior_nav_view_coverflow
                        }
                    }
                }
                else if UIDevice.current.orientation.isLandscape {
                    if current_nav_view == "Now Playing" || current_nav_view == "Main" {
                        did_utilize_coverflow = true
                        prior_nav_view_coverflow = current_nav_view
                    }
                    pre_nav_switch = "Coverflow"
                    if pre_nav_switch == "Coverflow" {
                        withAnimation {
                            current_nav_view = "Coverflow"
                        }
                    }
                }
            }
        }
    }
}

var tabs = ["Playlists", "Artists", "Songs", "Videos", "More"]
struct iPodTabView : View {
    
    @Binding var selectedTab:String
    @State var edge = UIApplication.shared.windows.first?.safeAreaInsets
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var artists_current_view: String
    @Binding var current_album: MPMediaItemCollection
    @Binding var current_artist: String
    @Binding var albums: [MPMediaItemCollection]
    @Binding var playlist: MPMediaItemCollection
    @Binding var playlist_current_nav_view: String
    var body: some View{
        GeometryReader {geometry in
            VStack(spacing:0) {
                
                ScrollView([], showsIndicators: false) {
                    
                    switch selectedTab {
                    case "Playlists":
                        ipod_playlists(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, playlist: $playlist, playlist_current_nav_view: $playlist_current_nav_view).frame(height: geometry.size.height - 57)
                            .tag("Playlists")
                    case "Artists":
                        ipod_artists(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, artists_current_view: $artists_current_view, albums: $albums, current_album: $current_album, current_artist: $current_artist).frame(height: geometry.size.height - 57)
                            .tag("Artists")
                    case "Songs":
                        ipod_songs(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).frame(height: geometry.size.height - 57)
                            .tag("Songs")
                    case "Videos":
                        ipod_videos()
                            .tag("Videos")
                    case "More":
                        ipod_more().frame(height: geometry.size.height - 57).tag("More")
                    default:
                        ipod_playlists(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, playlist: $playlist, playlist_current_nav_view: $playlist_current_nav_view).frame(height: geometry.size.height - 57)
                            .tag("Playlists")
                    }
                }.background(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0), .init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0.5), .init(color: Color.white, location: 0.5), .init(color: Color.white, location: 1)]), startPoint: .top, endPoint: .bottom))
                // for bottom overflow...
                ZStack {
                    Rectangle().fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.02), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom)).frame(height:57)
                    HStack(spacing: 0){
                        
                        ForEach(tabs,id: \.self){image in
                            TabButton(image: image, selectedTab: $selectedTab, artists_current_view:$artists_current_view, playlist_current_nav_view: $playlist_current_nav_view, geometry: geometry)
                            
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




struct FlippedUpsideDown: ViewModifier {
    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle(degrees: 180))
            .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}
extension View{
    func flippedUpsideDown() -> some View{
        self.modifier(FlippedUpsideDown())
    }
}


//**MARK: Now Playing
struct iPodNowPlaying: View {
    @State var edge = UIApplication.shared.windows.first?.safeAreaInsets
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var view_height: CGFloat
    @State var album_artwork: UIImage = UIImage()
    @State var proxy_width: CGFloat = 0.0
    @State var proxy_height: CGFloat = 0.0
    @State var is_playing: MPMusicPlaybackState?
    @State var artist: String?
    @State var song: String?
    @State var album: String?
    @State var album_tracks = [MPMediaItem]()
    @State var switch_to_tracks: Bool = false
    @State var show_back_tracks: Bool = false
    @State var hide_album_image: Bool = false
    @State var playback_time: CGFloat = 0.0
    @State var show_timing_controls: Bool = true
    @State var flipper_background: Bool = false
    let song_publisher = NotificationCenter.default
        .publisher(for: .MPMusicPlayerControllerNowPlayingItemDidChange)
    let media_publisher = NotificationCenter.default
        .publisher(for: .MPMusicPlayerControllerPlaybackStateDidChange) //MPMusicPlayerControllerPlaybackStateDidChange
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            GeometryReader {geometry in
                VStack(spacing:0) {
                    now_playing_title_bar(forward_or_backward: $forward_or_backward, current_nav_view: $current_nav_view, artist: $artist, song: $song, album: $album, album_image: $album_artwork, switch_to_tracks: $switch_to_tracks, show_back_tracks: $show_back_tracks, hide_album_image: $hide_album_image, flipper_background: $flipper_background, title: "").frame(height: 60)
                    ZStack {
                        ZStack {
                            Image("NowPlayingTableBackground").resizable().scaledToFill().frame(width:proxy_width, height: proxy_height).clipped().rotation3DEffect(.degrees(show_back_tracks == false ? 90 : 0), axis: (x: 0, y:1, z: 0), anchor: UnitPoint(0, 0.5)).offset(x:show_back_tracks == false ? geometry.size.width/2 : 0).opacity(show_back_tracks == false ? 0.5: 1)
                            now_playing_tracks(tracks: $album_tracks, switch_to_tracks: $switch_to_tracks, show_back_tracks: $show_back_tracks, hide_album_image: $hide_album_image, flipper_background: $flipper_background).frame(width:proxy_width, height: proxy_height).rotation3DEffect(.degrees(show_back_tracks == false ? 90 : 0), axis: (x: 0, y:1, z: 0), anchor: UnitPoint(0, 0.5)).offset(x:show_back_tracks == false ? geometry.size.width/2 : 0).border_top(width: 1, edges: [.top], color: Color(red: 53/255, green: 53/255, blue: 53/255)).opacity(show_back_tracks == false ? 0.5: 1)
                        }.frame(width:proxy_width, height: proxy_height)
                        Image(uiImage: album_artwork).resizable().scaledToFill().frame(width:geometry.size.width).clipped().overlay(
                            GeometryReader { proxy in
                                Color.clear.hidden().onAppear() {
                                    proxy_width = proxy.size.width
                                    proxy_height = proxy.size.height
                                }
                            }
                        ).border_top(width: 1, edges: [.top], color: Color(red: 53/255, green: 53/255, blue: 53/255)).gesture(TapGesture(count: 2).onEnded({withAnimation(.easeIn(duration: 0.4)){switch_to_tracks.toggle();flipper_background.toggle()}
                                                                                                                                                            DispatchQueue.main.asyncAfter(deadline:.now()+0.39) { //maybe 0.45
                                                                                                                                                                withAnimation(.easeOut(duration: 0.4)){show_back_tracks.toggle()}
                                                                                                                                                            }
                                                                                                                                                            DispatchQueue.main.asyncAfter(deadline:.now()+0.8) {
                                                                                                                                                                hide_album_image = true
                                                                                                                                                            }}).exclusively(before: TapGesture(count: 1).onEnded({DispatchQueue.main.asyncAfter(deadline:.now() + 0.25) {self.show_timing_controls.toggle()}}))).overlay(
                                                                                                                                                                ZStack {
                                                                                                                                                                    Image(uiImage: album_artwork.withHorizontallyFlippedOrientation()).resizable().scaledToFill().frame(width:proxy_width, height: proxy_height).clipped().rotationEffect(.degrees(-180)).offset(y:proxy_height).opacity(switch_to_tracks == true ? 0.25 : 0.8)
                                                                                                                                                                    LinearGradient(gradient:Gradient(stops: [.init(color: Color(red: 10/255, green: 10/255, blue: 10/255).opacity(0.0), location:0), .init(color: Color(red: 0/255, green: 0/255, blue: 0/255).opacity(1.0), location: 0.28), .init(color: Color(red: 0/255, green: 0/255, blue: 0/255).opacity(1.0), location:1)]), startPoint: .top, endPoint: .bottom).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: proxy_height, maxHeight: proxy_height).clipped().offset(y:proxy_height)
                                                                                                                                                                    VStack {
                                                                                                                                                                        now_playing_timing_controls().frame(width:proxy_width, height:90)
                                                                                                                                                                        Spacer()
                                                                                                                                                                    }.isHidden(show_timing_controls)
                                                                                                                                                                }
                                                                                                                                                                
                                                                                                                                                            ).innerShadowBottomWithOffset(color: Color.black.opacity(0.9), radius: 0.0125, offset: proxy_height).rotation3DEffect(.degrees(switch_to_tracks == true ? -90 : 0), axis: (x: 0, y:1, z: 0), anchor: UnitPoint(1, 0.5)).offset(x:switch_to_tracks == true ? -geometry.size.width/2 : 0).isHidden(hide_album_image).opacity(switch_to_tracks == true ? 0.5: 1)
                        
                    }
                    now_playing_footer(is_playing: $is_playing).frame(minHeight: 110, maxHeight:110).clipped().zIndex(1)
                }
            }.onAppear() {
                let music_player = MPMusicPlayerController.systemMusicPlayer
                let current_song = music_player.nowPlayingItem
                let album_artwork_c = current_song?.artwork?.image(at: CGSize(width: 400, height: 400))
                album_artwork = album_artwork_c ?? UIImage(named:"noartplaceholder") ?? UIImage()
                artist = current_song?.artist
                song = current_song?.title
                album = current_song?.albumTitle
                let play_status = music_player.playbackState
                is_playing = play_status
                let mediaQuery = MPMediaQuery.songs()
                let predicate = MPMediaPropertyPredicate.init(value: current_song?.albumPersistentID, forProperty: MPMediaItemPropertyAlbumPersistentID)
                if predicate.value != nil {
                    mediaQuery.addFilterPredicate(predicate)
                    let album_songs = mediaQuery.items ?? []
                    album_tracks = album_songs
                }
                
                
                
            }  .onReceive(song_publisher) { (output) in
                let music_player = MPMusicPlayerController.systemMusicPlayer
                let current_song = music_player.nowPlayingItem
                let album_artwork_c = current_song?.artwork?.image(at: CGSize(width: 400, height: 400))
                album_artwork = album_artwork_c ?? UIImage(named:"noartplaceholder") ?? UIImage()
                artist = current_song?.artist
                song = current_song?.title
                album = current_song?.albumTitle
                let mediaQuery = MPMediaQuery.songs()
                DispatchQueue.main.asyncAfter(deadline: .now()+0.25) {
                    let music_player = MPMusicPlayerController.systemMusicPlayer
                    let current_song = music_player.nowPlayingItem
                    let predicate = MPMediaPropertyPredicate.init(value: current_song?.albumPersistentID, forProperty: MPMediaItemPropertyAlbumPersistentID)
                    if predicate.value != nil {
                        mediaQuery.addFilterPredicate(predicate)
                        let album_songs = mediaQuery.items ?? []
                        album_tracks = album_songs
                    }
                }
                
            }  .onReceive(media_publisher) { (output) in
                let music_player = MPMusicPlayerController.systemMusicPlayer
                let play_status = music_player.playbackState
                is_playing = play_status
                
            }
        }.compositingGroup() //Compositing group fixes some of the animation issues
    }
}

struct now_playing_timing_controls: View {
    @State var track_position: Double = 0
    @State var playback_remaining_duratation: Double?
    @State var playback_progress_duration: Double?
    @State var duration_full: Double?
    @State var should_update_from_timer: Bool? = true
    @State var shuffle: Bool?
    @State var repeat_mode: Int?
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                Color.black.opacity(0.5).frame(width: geometry.size.width, height:geometry.size.height).innerShadowBottomView(color: Color.white.opacity(0.6), radius: 0.0275).border_bottom(width: 1, edges:[.bottom], color: Color.black)
                VStack {
                    HStack {
                        Text(formatTimeFor(seconds: playback_progress_duration ?? 0)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).padding(.leading, 15)
                        CustomSlider(type: "Song", should_update_from_timer: $should_update_from_timer, duration: $duration_full, value: $track_position,  range: (0, 100)) { modifiers in
                            ZStack {
                                
                                LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 205/255, green: 220/255, blue: 241/255), location: 0), .init(color: Color(red: 125/255, green: 174/255, blue: 245/255), location: 0.5), .init(color: Color(red: 45/255, green: 111/255, blue: 198/255), location: 0.5), .init(color: Color(red: 50/255, green: 151/255, blue: 236/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 8).cornerRadius(4.25).padding(.leading, 4).modifier(modifiers.barLeft)
                                
                                LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 218/255, green: 218/255, blue: 218/255), location: 0), .init(color: Color(red: 166/255, green: 166/255, blue: 166/255), location: 0.19), .init(color: Color(red: 204/255, green: 204/255, blue: 204/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 8).cornerRadius(4.25).padding(.trailing, 4).modifier(modifiers.barRight)
                                ZStack {
                                    Image("volume-slider-fat-knob").resizable().scaledToFill()
                                }.modifier(modifiers.knob)
                            }
                        }.frame(height: 20)
                        Text("-\(formatTimeFor(seconds: playback_remaining_duratation ?? 0))").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).shadow(color: Color.black.opacity(0.75), radius: 0, x: 0.0, y: -1).padding(.trailing, 15)
                    }
                    HStack {
                        Button(action:{
                            let music_player = MPMusicPlayerController.systemMusicPlayer
                            repeat_mode = ((repeat_mode ?? 0) < 2 ? (repeat_mode ?? 0) + 2 : ((repeat_mode ?? 0) == 3) ? ((repeat_mode ?? 0) - 1) : 1)
                            music_player.repeatMode = MPMusicRepeatMode(rawValue: repeat_mode ?? 0)!
                            
                        }) {
                            Image((repeat_mode ?? 0) == 1 ? "repeat_off" : (repeat_mode ?? 0) == 2 ? "repeat_on_1" : (repeat_mode ?? 0) == 3 ? "repeat_on" : "repeat_off").animation(.none)
                        }.padding(.leading, 20)
                        Spacer()
                        Button(action:{}) {
                            Image("nowplaying_atom")
                        }
                        Spacer()
                        Button(action:{
                            shuffle?.toggle()
                            let music_player = MPMusicPlayerController.systemMusicPlayer
                            music_player.shuffleMode = (((shuffle == false ? MPMusicShuffleMode(rawValue: 1) : MPMusicShuffleMode(rawValue: 2))!))
                            
                        }) {
                            Image(shuffle == false ? "shuffle_off" : "shuffle_on")
                        }.padding(.trailing, 20)
                    }
                }
            }.frame(width: geometry.size.width, height:geometry.size.height).onReceive(timer) { _ in
                if should_update_from_timer == true {
                    DispatchQueue.global(qos: .background).async {
                        let music_player = MPMusicPlayerController.systemMusicPlayer
                        let current_song = music_player.nowPlayingItem
                        shuffle = (music_player.shuffleMode.rawValue == 1 ? false : true)
                        playback_progress_duration = music_player.currentPlaybackTime
                        playback_remaining_duratation = (current_song?.playbackDuration ?? 0) - music_player.currentPlaybackTime
                        duration_full = (current_song?.playbackDuration ?? 0)
                        track_position = music_player.currentPlaybackTime/(current_song?.playbackDuration ?? 1)*100
                    }
                }
            }.onAppear() {
                if should_update_from_timer == true {
                    DispatchQueue.global(qos: .background).async {
                        let music_player = MPMusicPlayerController.systemMusicPlayer
                        let current_song = music_player.nowPlayingItem
                        shuffle = (music_player.shuffleMode.rawValue == 1 ? false : true)
                        repeat_mode = music_player.repeatMode.rawValue
                        playback_progress_duration = music_player.currentPlaybackTime
                        playback_remaining_duratation = (current_song?.playbackDuration ?? 0) - music_player.currentPlaybackTime
                        duration_full = (current_song?.playbackDuration ?? 0)
                        track_position = music_player.currentPlaybackTime/(current_song?.playbackDuration ?? 1)*100
                    }
                }
            }.onChange(of: track_position) { _ in
                playback_progress_duration = track_position/100*(duration_full ?? 0)
                playback_remaining_duratation = (duration_full ?? 0) - (playback_progress_duration ?? 0)
            }
        }
    }
}
struct now_playing_tracks: View {
    @Binding var tracks: [MPMediaItem]
    @State var new_track_delay: Bool = false
    @State var current_song: MPMediaItem?
    @State var current_track_rating: Int?
    @Binding var switch_to_tracks: Bool
    @Binding var show_back_tracks: Bool
    @Binding var hide_album_image: Bool
    @Binding var flipper_background: Bool
    let song_publisher = NotificationCenter.default
        .publisher(for: .MPMusicPlayerControllerNowPlayingItemDidChange)
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing:0) {
                HStack {
                    rating_view(rating: $current_track_rating)
                }.background(LinearGradient(gradient:Gradient(stops: [.init(color: Color(red: 0/255, green: 0/255, blue: 0/255).opacity(1.0), location:0), .init(color: Color(red: 0/255, green: 0/255, blue: 0/255).opacity(1.0), location: 0.35), .init(color: Color(red: 26/255, green: 26/255, blue: 26/255), location:1)]), startPoint: .top, endPoint: .bottom).frame(width: geometry.size.width, height:44)).frame(width: geometry.size.width, height:44)
                ScrollView(showsIndicators: false) {
                    LazyVStack {
                        ForEach(removeDuplicates(tracks), id: \.persistentID) { track in
                            Button(action:{
                                if new_track_delay == false {
                                    new_track_delay = true
                                    play_song(song: track)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    new_track_delay = false
                                }
                            }) {
                                VStack {
                                    if track == removeDuplicates(tracks)[0] {
                                        Rectangle().fill(Color(red: 65/255, green: 64/255, blue: 65/255)).frame(height:2)
                                    }
                                    Spacer()
                                    HStack {
                                        HStack {
                                            Text("\(String(track.albumTrackNumber)).").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).padding(.leading, 5).padding(.trailing, 5).multilineTextAlignment(.leading)
                                            Spacer()
                                        }.frame(width:60)
                                        Text(track.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).padding(.leading, 14)
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Text(formatTimeFor(seconds: track.playbackDuration)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).padding(.trailing, 5).padding(.leading, 5).multilineTextAlignment(.trailing)
                                        }.frame(width:60)
                                    }
                                    Spacer()
                                    Rectangle().fill(Color(red: 65/255, green: 64/255, blue: 65/255)).frame(height:2)
                                }.overlay(
                                    ZStack {
                                        HStack(alignment:.center) {
                                            Rectangle().fill(Color(red: 65/255, green: 64/255, blue: 65/255)).frame(width:2).padding(.leading, 65)
                                            Spacer()
                                        }
                                        HStack(alignment:.center) {
                                            Spacer()
                                            Rectangle().fill(Color(red: 65/255, green: 64/255, blue: 65/255)).frame(width:2).padding(.trailing, 65)
                                        }
                                        if track == current_song {
                                            HStack(alignment:.center) {
                                                Image("play").resizable().renderingMode(.template).scaledToFit().foregroundColor(Color(red: 54/255, green: 98/255, blue: 214/255)).frame(height:10).padding(.leading, 40)
                                                Spacer()
                                            }
                                        }
                                    }
                                    
                                ).background((removeDuplicates(tracks).firstIndex(of: track) ?? 0) % 2  == 0 ? Color.clear : Color.black.opacity(0.2))
                            }.frame(height: 44)
                        }
                    }
                }.onReceive(song_publisher) { (output) in
                    let music_player = MPMusicPlayerController.systemMusicPlayer
                    let current = music_player.nowPlayingItem
                    current_song = current
                    let current_rating = current?.rating
                    current_track_rating = current_rating
                }.onAppear() {
                    let music_player = MPMusicPlayerController.systemMusicPlayer
                    let current = music_player.nowPlayingItem
                    current_song = current
                    let current_rating = current?.rating
                    current_track_rating = current_rating
                }.onChange(of: current_track_rating) { rating in
                    let music_player = MPMusicPlayerController.systemMusicPlayer
                    let current = music_player.nowPlayingItem
                    current?.setValue(rating, forKey: "rating")
                }
            }.simultaneousGesture(TapGesture(count: 2).onEnded({withAnimation(.easeIn(duration: 0.4)){show_back_tracks.toggle()}
                                                                DispatchQueue.main.asyncAfter(deadline:.now()) {
                                                                    hide_album_image = false
                                                                }
                                                                DispatchQueue.main.asyncAfter(deadline:.now()+0.39) { //maybe 0.45
                                                                    withAnimation(.easeOut(duration: 0.4)){switch_to_tracks.toggle()}
                                                                }
                                                                DispatchQueue.main.asyncAfter(deadline:.now()+0.48) {
                                                                    withAnimation(.easeIn(duration: 0.4)){flipper_background.toggle()}
                                                                }}))
        }
    }
}

//Thanks to HackingWithSwift for a convient way to do ratings — I use this in so many apps.

struct rating_view: View {
    @Binding var rating: Int?
    
    var label = ""
    
    var maximumRating = 5
    
    
    var body: some View {
        ForEach(1..<maximumRating + 1) { number in
            ZStack {
                ZStack {
                    Image(number > (rating ?? 0) ? "star_empty" : "star_filled").resizable().scaledToFit().frame(width: number > (rating ?? 0) ? 6 : 20, height: number > (rating ?? 0) ? 6 : 40)
                }.frame(width:40, height: 40).contentShape(Rectangle())
                .onTapGesture {
                    self.rating = number
                }
            }
        }
    }
}

func play_song(song: MPMediaItem) {
    let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    SKCloudServiceController().requestCapabilities { (capability:SKCloudServiceCapability, err:Error?) in
        
        guard err == nil else {
            print("error in capability check is \(err!)")
            return
        }
        
        if capability.contains(SKCloudServiceCapability.musicCatalogPlayback) {
            print("user has Apple Music subscription")
            musicPlayer.setQueue(with: MPMediaItemCollection(items: [song]))
            musicPlayer.prepareToPlay { (error) in
                if error != nil && error!.localizedDescription == "The operation couldn’t be completed. (MPCPlayerRequestErrorDomain error 1.)" {
                } else {
                    musicPlayer.play()
                }
            }
        }
        
        if capability.contains(SKCloudServiceCapability.musicCatalogSubscriptionEligible) {
            print("user does not have subscription")
        }
        
    }
}


func removeDuplicates(_ arrayOfDicts: [MPMediaItem]) -> [MPMediaItem] {
    var removeDuplicates = [MPMediaItem]()
    var arrOfDict = [String]()
    for dict in arrayOfDicts {
        if let title = dict.title, !arrOfDict.contains(title) {
            removeDuplicates.append(dict)
            arrOfDict.append(title)
        }
    }
    return removeDuplicates
}

func removeDuplicates_Collection(_ arrayOfDicts: [MPMediaItemCollection]) -> [MPMediaItemCollection] {
    var removeDuplicates = [MPMediaItemCollection]()
    var arrOfDict = [String]()
    for dict in arrayOfDicts {
        if let title = dict.representativeItem?.albumTitle, !arrOfDict.contains(title) {
            removeDuplicates.append(dict)
            arrOfDict.append(title)
        }
    }
    return removeDuplicates
}
func getHoursMinutesSecondsFrom(seconds: Double) -> (hours: Int, minutes: Int, seconds: Int) {
    let secs = Int(seconds)
    let hours = secs / 3600
    let minutes = (secs % 3600) / 60
    let seconds = (secs % 3600) % 60
    return (hours, minutes, seconds)
}
func formatTimeFor(seconds: Double) -> String {
    let result = getHoursMinutesSecondsFrom(seconds: seconds)
    let hoursString = "\(result.hours)"
    var minutesString = "\(result.minutes)"
    var secondsString = "\(result.seconds)"
    if secondsString.count == 1 {
        secondsString = "0\(result.seconds)"
    }
    var time = "\(hoursString):"
    if result.hours >= 1 {
        time.append("\(minutesString):\(secondsString)")
    }
    else {
        time = "\(minutesString):\(secondsString)"
    }
    return time
}

func formatTimeForMinutes(seconds: Double) -> String {
    let result = getHoursMinutesSecondsFrom(seconds: seconds)
    let hoursString = "\(result.hours)"
    var minutesString = "\(result.minutes)"
    var secondsString = "\(result.seconds)"
    if secondsString.count == 1 {
        secondsString = "0\(result.seconds)"
    }
    var time = "\(hoursString):"
    if result.hours >= 1 {
        time.append("\(minutesString)")
    }
    else {
        time = "\(minutesString)"
    }
    return time
}


struct now_playing_footer: View {
    @ObservedObject private var volObserver = VolumeObserver()
    @Binding var is_playing: MPMusicPlaybackState?
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                VStack(spacing:0) {
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 71/255, green: 70/255, blue: 70/255).opacity(0.825), Color.init(red: 16/255, green: 15/255, blue: 15/255).opacity(0.875)]), startPoint: .top, endPoint: .bottom)).innerShadowBottom(color: Color.white.opacity(0.6), radius: 0.05).border_top(width: 1, edges:[.top], color: Color.black)
                    Rectangle().fill(Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255).opacity(0.97))
                }
                VStack(spacing:0) {
                    HStack(alignment:.center) {
                        Spacer()
                        Button(action:{
                            let music_player = MPMusicPlayerController.systemMusicPlayer
                            if music_player.currentPlaybackTime < TimeInterval(5) {
                                music_player.skipToPreviousItem()
                            } else {
                                music_player.skipToBeginning()
                            }
                        }) {
                            Image("prevtrack").resizable().scaledToFit().frame(width:31, height: 23)
                        }
                        Spacer()
                        Button(action:{
                            if is_playing?.rawValue != 1 {
                                let music_player = MPMusicPlayerController.systemMusicPlayer
                                music_player.play()
                            } else {
                                let music_player = MPMusicPlayerController.systemMusicPlayer
                                music_player.pause()
                            }
                            
                        }) {
                            Image(is_playing?.rawValue == 1 ? "pause" : "play").resizable().scaledToFit().frame(width:30, height: 26)
                        }
                        Spacer()
                        Button(action:{
                            
                            let music_player = MPMusicPlayerController.systemMusicPlayer
                            music_player.skipToNextItem()
                            
                        }) {
                            Image("nexttrack").resizable().scaledToFit().frame(width:31, height: 23)
                        }
                        Spacer()
                    }.frame(height:55)
                    Spacer().frame(height:5)
                    ZStack {
                        CustomSlider(type: "Volume", value: $volObserver.volume.double,  range: (0, 100)) { modifiers in
                            ZStack {
                                
                                LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 205/255, green: 220/255, blue: 241/255), location: 0), .init(color: Color(red: 125/255, green: 174/255, blue: 245/255), location: 0.5), .init(color: Color(red: 45/255, green: 111/255, blue: 198/255), location: 0.5), .init(color: Color(red: 50/255, green: 151/255, blue: 236/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 8.5).cornerRadius(4.25).padding(.leading, 4).modifier(modifiers.barLeft)
                                
                                LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 218/255, green: 218/255, blue: 218/255), location: 0), .init(color: Color(red: 166/255, green: 166/255, blue: 166/255), location: 0.19), .init(color: Color(red: 204/255, green: 204/255, blue: 204/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 8.5).cornerRadius(4.25).padding(.trailing, 4).modifier(modifiers.barRight)
                                ZStack {
                                    Image("volume-slider-fat-knob").resizable().scaledToFill()
                                    
                                }.modifier(modifiers.knob)
                            }
                        }.frame(height: 25).padding([.top, .bottom]).padding([.leading, .trailing], 30).padding(.bottom,15)
                    }.frame(height:50)
                }.frame(height:110)
            }
        }
    }
}

//**MARK: Playlists

struct ipod_playlists: View {
    @EnvironmentObject var MusicObserver: MusicObserver
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var playlist: MPMediaItemCollection
    @Binding var playlist_current_nav_view: String
    var body: some View {
        VStack(spacing:0) {
            switch playlist_current_nav_view {
            case "Playlists":
                SkeuomorphicList_Playlists(MusicObserver: MusicObserver, playlist: $playlist, forward_or_backward: $forward_or_backward, playlist_current_nav_view: $playlist_current_nav_view, current_nav_view: $current_nav_view).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Playlist_Desination":
                ipod_playlists_desination(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, playlist: $playlist).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            default:
                SkeuomorphicList_Playlists(MusicObserver: MusicObserver, playlist: $playlist, forward_or_backward: $forward_or_backward, playlist_current_nav_view: $playlist_current_nav_view, current_nav_view: $current_nav_view).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            }
        }.offset(y:-1.2)
    }
}

struct SkeuomorphicList_Playlists: View {
    var MusicObserver: MusicObserver
    @Binding var playlist: MPMediaItemCollection
    @Binding var forward_or_backward: Bool
    @Binding var playlist_current_nav_view: String
    @Binding var current_nav_view: String
    @State var editing_state: String = "None"
    @State var search = ""
    var body: some View {
        ZStack(alignment: .top) {
            List {
                ipod_search(search: $search, no_right_padding: true, editing_state: $editing_state).id("Search").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height:44).hideRowSeparator()
                ForEach(MusicObserver.playists, id: \.persistentID) { playlist in
                    Button(action:{
                        self.playlist = playlist
                        if   self.playlist == playlist, playlist.items.count != 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                forward_or_backward = false; withAnimation(.linear(duration: 0.28)){playlist_current_nav_view = "Playlist_Desination"}
                            }
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer().frame(height:4.5)
                            HStack() {
                                Text(playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 11).padding(.trailing, 40)
                                Spacer()
                                Image("UITableNext").padding(.trailing, 12)
                            }
                            Spacer().frame(height:9.5)
                            Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                            
                        }
                    }.padding(.top, playlist == MusicObserver.playists.first ? 2.5 : 0)
                }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).drawingGroup()
            }
            if editing_state == "Active_Empty" {
                Color.black.opacity(0.9).edgesIgnoringSafeArea(.all).offset(y: 44)
            }
            if editing_state == "Active" {
                Color.white.edgesIgnoringSafeArea(.all).offset(y: 44)
                List {
                    if MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search)}.count != 0 {
                        Section(header: generic_text_list_header(letter: "Artists (\(MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search)}.count) \(result_results_collection(MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search)})))").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                            ForEach(MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search) }, id: \.persistentID) { artist in
                                Button(action:{
                                }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        HStack() {
                                            Image(uiImage: artist.representativeItem?.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95)
                                            Text(artist.representativeItem?.artist ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 6).padding(.trailing, 40)
                                            Spacer()
                                            Image("UITableNext").padding(.trailing, 12)
                                        }
                                        Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                        
                                    }
                                }
                            }.hideRowSeparator_larger().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 60).drawingGroup()
                        }
                    }
                    if MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search)}.count != 0 {
                        Section(header: generic_text_list_header(letter: "Songs (\(MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search)}.count) \(result_results(MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search)})))").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                            ForEach(MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search) }, id: \.persistentID) { song in
                                Button(action:{
                                    let musicPlayer = MPMusicPlayerController.systemMusicPlayer
                                    SKCloudServiceController().requestCapabilities { (capability:SKCloudServiceCapability, err:Error?) in
                                        
                                        guard err == nil else {
                                            print("error in capability check is \(err!)")
                                            return
                                        }
                                        
                                        if capability.contains(SKCloudServiceCapability.musicCatalogPlayback) {
                                            print("user has Apple Music subscription")
                                            musicPlayer.nowPlayingItem = nil
                                            musicPlayer.setQueue(with: MPMediaItemCollection(items:[song]))
                                            musicPlayer.prepareToPlay { (error) in
                                                if error != nil && error!.localizedDescription == "The operation couldn’t be completed. (MPCPlayerRequestErrorDomain error 1.)" {
                                                } else {
                                                    musicPlayer.play()
                                                    forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
                                                }
                                            }
                                        }
                                        
                                        if capability.contains(SKCloudServiceCapability.musicCatalogSubscriptionEligible) {
                                            print("user does not have subscription")
                                        }
                                        
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        HStack() {
                                            Image(uiImage: song.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95)
                                            VStack(alignment: .leading, spacing: 0) {
                                                Text(song.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                                                Spacer().frame(height:1)
                                                Text("\(song.albumTitle ?? "---") - \(song.artist ?? "---")")
                                                    .font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(.cgLightGray).lineLimit(1)
                                            }.padding(.leading, 6).padding(.trailing, 40)
                                            Spacer()
                                            Image("UITableNext").padding(.trailing, 12)
                                        }
                                        Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                        
                                    }
                                }
                            }.hideRowSeparator_larger().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 60).drawingGroup()
                        }
                    }
                }.offset(y: 44)
            }
        }
    }
    
}

func result_results(_ array: [MPMediaItem]) -> String {
    if array.count == 1 {
        return "Result"
    } else {
        return "Results"
    }
}

func result_results_collection(_ array: [MPMediaItemCollection]) -> String {
    if array.count == 1 {
        return "Result"
    } else {
        return "Results"
    }
}

struct ipod_playlists_desination: View {
    @EnvironmentObject var MusicObserver: MusicObserver
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var playlist: MPMediaItemCollection
    var body: some View {
        VStack(spacing:0) {
            SkeuomorphicList_Playlists_Destination(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, playlist: $playlist, MusicObserver: MusicObserver)
        }.offset(y:-1.2)
    }
}

struct SkeuomorphicList_Playlists_Destination: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var playlist: MPMediaItemCollection
    var MusicObserver: MusicObserver
    @State var editing_state: String = "None"
    @State var search = ""
    var body: some View {
        ZStack(alignment:.top) {
            List {
                ipod_search(search: $search, no_right_padding: true, editing_state:$editing_state).id("Search").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height:44).hideRowSeparator()
                VStack(spacing:0) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(LinearGradient(gradient: Gradient(colors: [Color(red: 229/255, green: 230/255, blue: 231/255), Color(red: 210/255, green: 210/255, blue: 213/255)]), startPoint: .top, endPoint: .bottom))
                            Text("Edit").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red:154/255, green:154/255, blue:154/255), lineWidth: 1)
                        ).padding(.leading, 8).padding([.top], 8).padding(.bottom, 2)
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(LinearGradient(gradient: Gradient(colors: [Color(red: 229/255, green: 230/255, blue: 231/255), Color(red: 210/255, green: 210/255, blue: 213/255)]), startPoint: .top, endPoint: .bottom))
                            Text("Clear").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red:154/255, green:154/255, blue:154/255), lineWidth: 1)
                        ).padding([.top], 8).padding(.bottom, 2)
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(LinearGradient(gradient: Gradient(colors: [Color(red: 229/255, green: 230/255, blue: 231/255), Color(red: 210/255, green: 210/255, blue: 213/255)]), startPoint: .top, endPoint: .bottom))
                            Text("Delete").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red:154/255, green:154/255, blue:154/255), lineWidth: 1)
                        ).padding(.trailing, 8).padding([.top], 8).padding(.bottom, 2)
                    }.offset(y:-2)
                    Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height:44).hideRowSeparator()
                Button(action:{
                    let musicPlayer = MPMusicPlayerController.systemMusicPlayer
                    SKCloudServiceController().requestCapabilities { (capability:SKCloudServiceCapability, err:Error?) in
                        
                        guard err == nil else {
                            print("error in capability check is \(err!)")
                            return
                        }
                        
                        if capability.contains(SKCloudServiceCapability.musicCatalogPlayback) {
                            print("user has Apple Music subscription")
                            musicPlayer.nowPlayingItem = nil
                            musicPlayer.setQueue(with: MPMediaItemCollection(items: playlist.items.shuffled()))
                            musicPlayer.prepareToPlay { (error) in
                                if error != nil && error!.localizedDescription == "The operation couldn’t be completed. (MPCPlayerRequestErrorDomain error 1.)" {
                                } else {
                                    musicPlayer.play()
                                    forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
                                }
                            }
                        }
                        
                        if capability.contains(SKCloudServiceCapability.musicCatalogSubscriptionEligible) {
                            print("user does not have subscription")
                        }
                        
                    }
                }) {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer().frame(height:4.5)
                        HStack() {
                            
                            ZStack(alignment: .leading) {
                                HStack {
                                    Text("Shuffle").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                                    Image("shuffle_icon")
                                }
                            }.padding(.leading, 11).padding(.trailing, 40)
                        }.frame(minHeight: 44-0.95-9, maxHeight:44-0.95-9)
                        Spacer().frame(height:4.5)
                        Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                    }
                }.frame(minHeight: 44, maxHeight:44).listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).hideRowSeparator()
                ForEach(playlist.items ?? [], id: \.persistentID) { song in
                    Button(action:{
                        let musicPlayer = MPMusicPlayerController.systemMusicPlayer
                        SKCloudServiceController().requestCapabilities { (capability:SKCloudServiceCapability, err:Error?) in
                            
                            guard err == nil else {
                                print("error in capability check is \(err!)")
                                return
                            }
                            
                            if capability.contains(SKCloudServiceCapability.musicCatalogPlayback) {
                                print("user has Apple Music subscription")
                                musicPlayer.nowPlayingItem = nil
                                musicPlayer.setQueue(with: MPMediaItemCollection(items: playlist.items.wrap(around: song)))
                                musicPlayer.prepareToPlay { (error) in
                                    if error != nil && error!.localizedDescription == "The operation couldn’t be completed. (MPCPlayerRequestErrorDomain error 1.)" {
                                    } else {
                                        musicPlayer.play()
                                        forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
                                    }
                                }
                            }
                            
                            if capability.contains(SKCloudServiceCapability.musicCatalogSubscriptionEligible) {
                                print("user does not have subscription")
                            }
                            
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer().frame(height:4.5)
                            HStack() {
                                
                                VStack(alignment: .leading) {
                                    Text(song.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                                    Spacer().frame(height:1)
                                    Text("\(song.albumTitle ?? "---") - \(song.artist ?? "---")")
                                        .font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(.cgLightGray).lineLimit(1)
                                }.padding(.leading, 11)
                                if song == MPMusicPlayerController.systemMusicPlayer.nowPlayingItem {
                                    Spacer()
                                    Image("NowPlayingListItemIcon")
                                }
                            }.padding(.trailing, 11)
                            Spacer().frame(height:4.5)
                            Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                        }
                        
                    }.padding(.top, song == (playlist.items ?? []).first ? 2.5 : 0)
                }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).drawingGroup()
            }
            if editing_state == "Active_Empty" {
                Color.black.opacity(0.9).edgesIgnoringSafeArea(.all).offset(y: 44)
            }
            if editing_state == "Active" {
                Color.white.edgesIgnoringSafeArea(.all).offset(y: 44)
                List {
                    if MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search)}.count != 0 {
                        Section(header: generic_text_list_header(letter: "Artists (\(MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search)}.count) \(result_results_collection(MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search)})))").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                            ForEach(MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search) }, id: \.persistentID) { artist in
                                Button(action:{
                                }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        HStack() {
                                            Image(uiImage: artist.representativeItem?.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95)
                                            Text(artist.representativeItem?.artist ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 6).padding(.trailing, 40)
                                            Spacer()
                                            Image("UITableNext").padding(.trailing, 12)
                                        }
                                        Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                        
                                    }
                                }
                            }.hideRowSeparator_larger().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 60).drawingGroup()
                        }
                    }
                    if MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search)}.count != 0 {
                        Section(header: generic_text_list_header(letter: "Songs (\(MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search)}.count) \(result_results(MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search)})))").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                            ForEach(MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search) }, id: \.persistentID) { song in
                                Button(action:{
                                    let musicPlayer = MPMusicPlayerController.systemMusicPlayer
                                    SKCloudServiceController().requestCapabilities { (capability:SKCloudServiceCapability, err:Error?) in
                                        
                                        guard err == nil else {
                                            print("error in capability check is \(err!)")
                                            return
                                        }
                                        
                                        if capability.contains(SKCloudServiceCapability.musicCatalogPlayback) {
                                            print("user has Apple Music subscription")
                                            musicPlayer.nowPlayingItem = nil
                                            musicPlayer.setQueue(with: MPMediaItemCollection(items:[song]))
                                            musicPlayer.prepareToPlay { (error) in
                                                if error != nil && error!.localizedDescription == "The operation couldn’t be completed. (MPCPlayerRequestErrorDomain error 1.)" {
                                                } else {
                                                    musicPlayer.play()
                                                    forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
                                                }
                                            }
                                        }
                                        
                                        if capability.contains(SKCloudServiceCapability.musicCatalogSubscriptionEligible) {
                                            print("user does not have subscription")
                                        }
                                        
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        HStack() {
                                            Image(uiImage: song.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95)
                                            VStack(alignment: .leading, spacing: 0) {
                                                Text(song.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                                                Spacer().frame(height:1)
                                                Text("\(song.albumTitle ?? "---") - \(song.artist ?? "---")")
                                                    .font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(.cgLightGray).lineLimit(1)
                                            }.padding(.leading, 6).padding(.trailing, 40)
                                            Spacer()
                                            Image("UITableNext").padding(.trailing, 12)
                                        }
                                        Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                        
                                    }
                                }
                            }.hideRowSeparator_larger().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 60).drawingGroup()
                        }
                    }
                }.offset(y: 44)
            }
            
        }
        
    }
}

struct shuffle_bottom_divider: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height:4.5)
            HStack() {
                
                VStack(alignment: .leading) {
                    Spacer()
                    HStack {
                        Text("Shuffle").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                        Image("shuffle_icon")
                    }
                    Spacer()
                }.padding(.leading, 11).padding(.trailing, 40)
            }
            Spacer().frame(height:4.5)
            Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
        }.frame(maxHeight:44)
    }
}

extension Array where Element : Equatable {
    func wrap(around selectedElement: Element) -> Array<Element> {
        
        var oldArray = [Element]()
        var priorElements = [Element]()
        var newArray = [Element]()
        
        for element in self {
            if element == selectedElement || oldArray.count > 0 {
                oldArray.append(element)
            } else {
                priorElements.append(element)
            }
            newArray = oldArray + priorElements
        }
        return newArray
    }
    func shuffled() -> [Iterator.Element] {
        let shuffledArray = (self as? NSArray)?.shuffled()
        let outputArray = shuffledArray as? [Iterator.Element]
        return outputArray ?? []
    }
    mutating func shuffle() {
        if let selfShuffled = self.shuffled() as? Self {
            self = selfShuffled
        }
    }
}

//**MARK: Artists


struct ipod_artists: View {
    @EnvironmentObject var MusicObserver: MusicObserver
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var artists_current_view: String
    @Binding var albums: [MPMediaItemCollection]
    @Binding var current_album: MPMediaItemCollection
    @Binding var current_artist: String
    @State var editing_state: String = "None"
    var body: some View {
        VStack(spacing:0) {
            switch artists_current_view {
            case "Artists":
                SkeuomorphicList_Artists(forward_or_backward: $forward_or_backward, artists_current_view: $artists_current_view, albums: $albums, current_artist: $current_artist, current_nav_view: $current_nav_view, editing_state: $editing_state, MusicObserver: MusicObserver, indexes: Array(Set(MusicObserver.artists.compactMap({
                    
                    String(alphabet.contains(String($0.representativeItem?.artist?.prefix(1) ?? "")) ? ($0.representativeItem?.artist?.prefix(1) ?? "") : "#")
                    
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
                    
                })).modifier(VerticalIndex(indexableList: alphabet, indexes: Array(Set(MusicObserver.artists.compactMap({
                    
                    String(alphabet.contains(String($0.representativeItem?.artist?.prefix(1) ?? "")) ? ($0.representativeItem?.artist?.prefix(1) ?? "") : "#")
                    
                }))), editing_state: $editing_state)).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Artist_Albums":
                artists_destination(artists_current_view: $artists_current_view, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, albums: $albums, current_album: $current_album).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Artist_Album_Songs":
                albums_destination(album: $current_album, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            default:
                SkeuomorphicList_Artists(forward_or_backward: $forward_or_backward, artists_current_view: $artists_current_view, albums: $albums, current_artist: $current_artist, current_nav_view: $current_nav_view, editing_state: $editing_state, MusicObserver: MusicObserver, indexes: Array(Set(MusicObserver.artists.compactMap({
                    
                    String(alphabet.contains(String($0.representativeItem?.artist?.prefix(1) ?? "")) ? ($0.representativeItem?.artist?.prefix(1) ?? "") : "#")
                    
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
                    
                })).modifier(VerticalIndex(indexableList: alphabet, indexes: Array(Set(MusicObserver.artists.compactMap({
                    
                    String(alphabet.contains(String($0.representativeItem?.artist?.prefix(1) ?? "")) ? ($0.representativeItem?.artist?.prefix(1) ?? "") : "#")
                    
                }))), editing_state: $editing_state)).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            }
        }.offset(y:-1.2)
    }
}

struct SkeuomorphicList_Artists: View {
    @Binding var forward_or_backward: Bool
    @Binding var artists_current_view: String
    @Binding var albums: [MPMediaItemCollection]
    @Binding var current_artist: String
    @Binding var current_nav_view: String
    @Binding var editing_state: String
    var MusicObserver: MusicObserver
    var indexes: [String]
    @State var search = ""
    var body: some View {
        ZStack(alignment: .top) {
            List {
                ipod_search(search: $search, no_right_padding: editing_state != "None" ? true : false, editing_state:$editing_state).id("Search").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height:44).hideRowSeparator()
                ForEach(indexes, id: \.self) { letter in
                    Section(header: alpha_list_header(letter: letter).id(letter) .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                        ForEach(MusicObserver.artists.filter({(artist) -> Bool in
                            String(alphabet.contains(String(artist.representativeItem?.artist?.prefix(1) ?? "")) ? (artist.representativeItem?.artist?.prefix(1) ?? "") : "#") == letter
                            
                        }), id: \.persistentID) { artist in
                            Button(action:{
                                let q = MPMediaQuery.albums()
                                let predicate = MPMediaPropertyPredicate.init(value: artist.representativeItem?.artistPersistentID, forProperty: MPMediaItemPropertyArtistPersistentID)
                                q.addFilterPredicate(predicate)
                                albums = q.collections ?? []
                                current_artist = artist.representativeItem?.artist ?? ""
                                if albums.count != 0, current_artist == artist.representativeItem?.artist ?? "" {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        forward_or_backward = false; withAnimation(.linear(duration: 0.28)){artists_current_view = "Artist_Albums"}
                                    }
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Spacer()
                                    HStack() {
                                        Text(artist.representativeItem?.artist ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 11).padding(.trailing, 40)
                                        Spacer()
                                    }
                                    Spacer().frame(height:9.5)
                                    Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all).opacity(artist == MusicObserver.artists.filter({(artist) -> Bool in
                                        String(alphabet.contains(String(artist.representativeItem?.artist?.prefix(1) ?? "")) ? (artist.representativeItem?.artist?.prefix(1) ?? "") : "#") == letter
                                        
                                    }).last ? 1 : 1 )
                                }
                            }
                        }.hideRowSeparator()
                    }
                }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).drawingGroup()
                HStack {
                    Spacer()
                    Text("\(MusicObserver.artists.count) Artists").font(.custom("Helvetica Neue Regular", fixedSize: 20)).foregroundColor(.cgLightGray).lineLimit(1)
                    Spacer()
                }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            if editing_state == "Active_Empty" {
                Color.black.opacity(0.9).edgesIgnoringSafeArea(.all).offset(y: 44)
            }
            if editing_state == "Active" {
                Color.white.edgesIgnoringSafeArea(.all).offset(y: 44)
                List {
                    if MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search)}.count != 0 {
                        Section(header: generic_text_list_header(letter: "Artists (\(MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search)}.count) \(result_results_collection(MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search)})))").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                            ForEach(MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search) }, id: \.persistentID) { artist in
                                Button(action:{
                                }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        HStack() {
                                            Image(uiImage: artist.representativeItem?.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95)
                                            Text(artist.representativeItem?.artist ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 6).padding(.trailing, 40)
                                            Spacer()
                                            Image("UITableNext").padding(.trailing, 12)
                                        }
                                        Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                        
                                    }
                                }
                            }.hideRowSeparator_larger().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 60).drawingGroup()
                        }
                    }
                    if MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search)}.count != 0 {
                        Section(header: generic_text_list_header(letter: "Songs (\(MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search)}.count) \(result_results(MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search)})))").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                            ForEach(MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search) }, id: \.persistentID) { song in
                                Button(action:{
                                    let musicPlayer = MPMusicPlayerController.systemMusicPlayer
                                    SKCloudServiceController().requestCapabilities { (capability:SKCloudServiceCapability, err:Error?) in
                                        
                                        guard err == nil else {
                                            print("error in capability check is \(err!)")
                                            return
                                        }
                                        
                                        if capability.contains(SKCloudServiceCapability.musicCatalogPlayback) {
                                            print("user has Apple Music subscription")
                                            musicPlayer.nowPlayingItem = nil
                                            musicPlayer.setQueue(with: MPMediaItemCollection(items:[song]))
                                            musicPlayer.prepareToPlay { (error) in
                                                if error != nil && error!.localizedDescription == "The operation couldn’t be completed. (MPCPlayerRequestErrorDomain error 1.)" {
                                                } else {
                                                    musicPlayer.play()
                                                    forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
                                                }
                                            }
                                        }
                                        
                                        if capability.contains(SKCloudServiceCapability.musicCatalogSubscriptionEligible) {
                                            print("user does not have subscription")
                                        }
                                        
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        HStack() {
                                            Image(uiImage: song.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95)
                                            VStack(alignment: .leading, spacing: 0) {
                                                Text(song.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                                                Spacer().frame(height:1)
                                                Text("\(song.albumTitle ?? "---") - \(song.artist ?? "---")")
                                                    .font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(.cgLightGray).lineLimit(1)
                                            }.padding(.leading, 6).padding(.trailing, 40)
                                            Spacer()
                                            Image("UITableNext").padding(.trailing, 12)
                                        }
                                        //  Spacer().frame(height:9.5)
                                        Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                        
                                    }
                                }
                            }.hideRowSeparator_larger().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 60).drawingGroup()
                        }
                    }
                }.offset(y: 44)
            }
            
        }
        
    }
}



struct artists_destination: View {
    @EnvironmentObject var MusicObserver: MusicObserver
    @Binding var artists_current_view: String
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var albums: [MPMediaItemCollection]
    @Binding var current_album: MPMediaItemCollection
    var body: some View {
        VStack(spacing:0) {
            SkeuomorphicList_Artists_Destination(albums: albums, current_album: $current_album, forward_or_backward: $forward_or_backward, artists_current_view: $artists_current_view, current_nav_view: $current_nav_view, MusicObserver: MusicObserver)
        }
    }
}

struct SkeuomorphicList_Artists_Destination: View {
    var albums: [MPMediaItemCollection]
    @Binding var current_album: MPMediaItemCollection
    @Binding var forward_or_backward: Bool
    @Binding var artists_current_view: String
    @Binding var current_nav_view: String
    var MusicObserver: MusicObserver
    @State var editing_state: String = "None"
    @State var search = ""
    var body: some View {
        ZStack(alignment: .top) {
            List {
                ipod_search(search: $search, no_right_padding: true, editing_state:$editing_state).id("Search").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height:44).hideRowSeparator()
                ForEach(albums, id: \.persistentID) { album in
                    Button(action:{
                        current_album = album
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.25) {
                            forward_or_backward = false; withAnimation(.linear(duration: 0.28)){artists_current_view = "Artist_Album_Songs"}
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 0) {
                            //Spacer().frame(height:4.5)
                            HStack() {
                                Image(uiImage: album.representativeItem?.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95)
                                Text(album.representativeItem?.albumTitle ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 6).padding(.trailing, 40)
                                Spacer()
                                Image("UITableNext").padding(.trailing, 12)
                            }
                            //  Spacer().frame(height:9.5)
                            Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                            
                        }
                    }//.padding(.top, album == albums.first ? 2.5 : 0)
                }.hideRowSeparator_larger().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 60).drawingGroup()
            }.background(Color.white)
            if editing_state == "Active_Empty" {
                Color.black.opacity(0.9).edgesIgnoringSafeArea(.all).offset(y: 44)
            }
            if editing_state == "Active" {
                Color.white.edgesIgnoringSafeArea(.all).offset(y: 44)
                List {
                    if MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search)}.count != 0 {
                        Section(header: generic_text_list_header(letter: "Artists (\(MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search)}.count) \(result_results_collection(MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search)})))").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                            ForEach(MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search) }, id: \.persistentID) { artist in
                                Button(action:{
                                }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        //Spacer().frame(height:4.5)
                                        HStack() {
                                            Image(uiImage: artist.representativeItem?.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95)
                                            Text(artist.representativeItem?.artist ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 6).padding(.trailing, 40)
                                            Spacer()
                                            Image("UITableNext").padding(.trailing, 12)
                                        }
                                        //  Spacer().frame(height:9.5)
                                        Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                        
                                    }
                                }
                            }.hideRowSeparator_larger().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 60).drawingGroup()
                        }
                    }
                    if MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search)}.count != 0 {
                        Section(header: generic_text_list_header(letter: "Songs (\(MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search)}.count) \(result_results(MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search)})))").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                            ForEach(MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search) }, id: \.persistentID) { song in
                                Button(action:{
                                    let musicPlayer = MPMusicPlayerController.systemMusicPlayer
                                    SKCloudServiceController().requestCapabilities { (capability:SKCloudServiceCapability, err:Error?) in
                                        
                                        guard err == nil else {
                                            print("error in capability check is \(err!)")
                                            return
                                        }
                                        
                                        if capability.contains(SKCloudServiceCapability.musicCatalogPlayback) {
                                            print("user has Apple Music subscription")
                                            musicPlayer.nowPlayingItem = nil
                                            musicPlayer.setQueue(with: MPMediaItemCollection(items: [song]))
                                            musicPlayer.prepareToPlay { (error) in
                                                if error != nil && error!.localizedDescription == "The operation couldn’t be completed. (MPCPlayerRequestErrorDomain error 1.)" {
                                                } else {
                                                    musicPlayer.play()
                                                    forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
                                                }
                                            }
                                        }
                                        
                                        if capability.contains(SKCloudServiceCapability.musicCatalogSubscriptionEligible) {
                                            print("user does not have subscription")
                                        }
                                        
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        //Spacer().frame(height:4.5)
                                        HStack() {
                                            Image(uiImage: song.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95)
                                            VStack(alignment: .leading, spacing: 0) {
                                                Text(song.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                                                Spacer().frame(height:1)
                                                Text("\(song.albumTitle ?? "---") - \(song.artist ?? "---")")
                                                    .font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(.cgLightGray).lineLimit(1)
                                            }.padding(.leading, 6).padding(.trailing, 40)
                                            Spacer()
                                            Image("UITableNext").padding(.trailing, 12)
                                        }
                                        //  Spacer().frame(height:9.5)
                                        Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                        
                                    }
                                }
                            }.hideRowSeparator_larger().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 60).drawingGroup()
                        }
                    }
                }.offset(y: 44)
            }
            
        }
    }
}


struct albums_destination: View {
    @Binding var album: MPMediaItemCollection
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                LazyVStack {
                    
                    HStack() {
                        ZStack(alignment: .top) {
                            Image(uiImage: album.representativeItem?.artwork?.image(at: CGSize(width: 400, height: 400))  ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 100, height: 100)
                            Image(uiImage: (album.representativeItem?.artwork?.image(at: CGSize(width: 400, height: 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).withHorizontallyFlippedOrientation()).resizable().scaledToFill().frame(width:100, height: 100).clipped().rotationEffect(.degrees(-180)).offset(y:100).opacity(0.15)
                        }.frame(height: 120).clipped().padding(.leading, 6)
                        VStack(alignment:.leading) {
                            Text(album.representativeItem?.artist ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.black).lineLimit(1).multilineTextAlignment(.leading)
                            Text(album.representativeItem?.albumTitle ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 20)).foregroundColor(.black).lineLimit(1).multilineTextAlignment(.leading)
                            Text("Released \((album.representativeItem?.value(forProperty: "year") as? NSNumber)?.stringValue ?? "")").font(.custom("Helvetica Neue Bold", fixedSize: 10)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1).multilineTextAlignment(.leading)
                            Text("\(removeDuplicates(album.items ?? []).count) Songs, \(formatTimeForMinutes(seconds: album.representativeItem?.playbackDuration ?? 0)) Mins.").font(.custom("Helvetica Neue Bold", fixedSize: 10)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1).multilineTextAlignment(.leading)
                            Spacer()
                        }.padding(.top, 10)
                        Spacer()
                    }.background(LinearGradient(gradient: Gradient(colors: [Color(red: 248/255, green: 248/255, blue: 248/255), Color(red: 236/255, green: 236/255, blue: 236/255)]), startPoint: .top, endPoint: .bottom)).frame(height:120).padding(.bottom, 0)
                    
                    ForEach(removeDuplicates(album.items ?? []), id: \.persistentID) { track in
                        Button(action:{
                            let musicPlayer = MPMusicPlayerController.systemMusicPlayer
                            SKCloudServiceController().requestCapabilities { (capability:SKCloudServiceCapability, err:Error?) in
                                
                                guard err == nil else {
                                    print("error in capability check is \(err!)")
                                    return
                                }
                                
                                if capability.contains(SKCloudServiceCapability.musicCatalogPlayback) {
                                    print("user has Apple Music subscription")
                                    musicPlayer.nowPlayingItem = nil
                                    musicPlayer.setQueue(with: MPMediaItemCollection(items: [track]))
                                    musicPlayer.prepareToPlay { (error) in
                                        if error != nil && error!.localizedDescription == "The operation couldn’t be completed. (MPCPlayerRequestErrorDomain error 1.)" {
                                        } else {
                                            musicPlayer.play()
                                            forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
                                        }
                                    }
                                }
                                
                                if capability.contains(SKCloudServiceCapability.musicCatalogSubscriptionEligible) {
                                    print("user does not have subscription")
                                }
                                
                            }
                        }) {
                            VStack {
                                if track == removeDuplicates(album.items ?? [])[0] {
                                    Rectangle().fill(Color(red: 228/255, green: 228/255, blue: 228/255)).frame(height:2)
                                }
                                Spacer()
                                HStack {
                                    HStack {
                                        Spacer()
                                        Text("\(String(track.albumTrackNumber))").font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.black).lineLimit(1).multilineTextAlignment(.leading)
                                        Spacer()
                                    }.frame(width:40)
                                    Text(track.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.black).lineLimit(1).padding(.leading, 14)
                                    Spacer()
                                    if track == MPMusicPlayerController.systemMusicPlayer.nowPlayingItem {
                                        Image("NowPlayingListItemIcon").padding(.trailing, 5)
                                    }
                                    HStack {
                                        Text(formatTimeFor(seconds: track.playbackDuration)).font(.custom("Helvetica Neue Bold", fixedSize: 15)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1).multilineTextAlignment(.trailing)
                                    }.frame(width:40)
                                }
                                Spacer()
                                Rectangle().fill(Color(red: 228/255, green: 228/255, blue: 228/255)).frame(height:2)
                            }.overlay(
                                ZStack {
                                    HStack(alignment:.center) {
                                        Rectangle().fill(Color(red: 228/255, green: 228/255, blue: 228/255)).frame(width:2).padding(.leading, 45)
                                        Spacer()
                                    }
                                    HStack(alignment:.center) {
                                        Spacer()
                                        Rectangle().fill(Color(red: 228/255, green: 228/255, blue: 228/255)).frame(width:2).padding(.trailing, 45)
                                    }
                                }
                                
                            ).background((removeDuplicates(album.items ?? []).firstIndex(of: track) ?? 0) % 2  == 0 ? Color.white : Color(red: 243/255, green: 243/255, blue: 243/255))
                        }.frame(height: 44)
                    }
                }.drawingGroup()
            }.background((removeDuplicates(album.items ?? []).count) % 2  == 0 ? Color.white : Color(red: 240/255, green: 240/255, blue: 240/255))
        }
    }
    func get_release_date(_ date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        let yearString = dateFormatter.string(from: date)
        return yearString
    }
}


//**MARK: Songs

struct ipod_songs: View {
    @EnvironmentObject var MusicObserver: MusicObserver
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @State var editing_state: String = "None"
    var body: some View {
        VStack(spacing:0) {
            SkeuomorphicList_Songs(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, editing_state: $editing_state, MusicObserver: MusicObserver, indexes: Array(Set(MusicObserver.songs.compactMap({
                
                String(alphabet.contains(String($0.title?.prefix(1) ?? "")) ? ($0.title?.prefix(1) ?? "") : "#")
                
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
                
            })).modifier(VerticalIndex(indexableList: alphabet, indexes: Array(Set(MusicObserver.songs.compactMap({
                
                String(alphabet.contains(String($0.title?.prefix(1) ?? "")) ? ($0.title?.prefix(1) ?? "") : "#")
                
            }))), editing_state: $editing_state))
        }.offset(y:-1.2)
    }
}

struct SkeuomorphicList_Songs: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var editing_state:String
    var MusicObserver: MusicObserver
    var indexes: [String]
    @State var search = ""
    var body: some View {
        ZStack(alignment:.top) {
            List {
                ipod_search(search: $search, no_right_padding: editing_state != "None" ? true : false, editing_state:$editing_state).id("Search").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height:44).hideRowSeparator()
                shuffle(songs: MusicObserver.songs, forward_or_backward: $forward_or_backward, current_nav_view: $current_nav_view).listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).hideRowSeparator()
                ForEach(indexes, id: \.self) { letter in
                    Section(header: alpha_list_header(letter: letter).id(letter) .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                        ForEach(MusicObserver.songs.filter({(song) -> Bool in
                            String(alphabet.contains(String(song.title?.prefix(1) ?? "")) ? (song.title?.prefix(1) ?? "") : "#") == letter
                            
                        }), id: \.persistentID) { song in
                            Button(action:{
                                let musicPlayer = MPMusicPlayerController.systemMusicPlayer
                                SKCloudServiceController().requestCapabilities { (capability:SKCloudServiceCapability, err:Error?) in
                                    
                                    guard err == nil else {
                                        print("error in capability check is \(err!)")
                                        return
                                    }
                                    
                                    if capability.contains(SKCloudServiceCapability.musicCatalogPlayback) {
                                        print("user has Apple Music subscription")
                                        musicPlayer.nowPlayingItem = nil
                                        musicPlayer.setQueue(with: MPMediaItemCollection(items: [song]))
                                        musicPlayer.prepareToPlay { (error) in
                                            if error != nil && error!.localizedDescription == "The operation couldn’t be completed. (MPCPlayerRequestErrorDomain error 1.)" {
                                            } else {
                                                musicPlayer.play()
                                                forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
                                            }
                                        }
                                    }
                                    
                                    if capability.contains(SKCloudServiceCapability.musicCatalogSubscriptionEligible) {
                                        print("user does not have subscription")
                                    }
                                    
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Spacer().frame(height:4.5)
                                    HStack() {
                                        
                                        VStack(alignment: .leading) {
                                            Text(song.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                                            Spacer().frame(height:1)
                                            Text("\(song.albumTitle ?? "---") - \(song.artist ?? "---")")
                                                .font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(.cgLightGray).lineLimit(1)
                                        }.padding(.leading, 11)
                                        if song == MPMusicPlayerController.systemMusicPlayer.nowPlayingItem {
                                            Spacer()
                                            Image("NowPlayingListItemIcon")
                                        }
                                    }.padding(.trailing, 40)
                                    Spacer().frame(height:4.5)
                                    Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all).opacity(song == MusicObserver.songs.filter({(song) -> Bool in
                                        String(alphabet.contains(String(song.title?.prefix(1) ?? "")) ? (song.title?.prefix(1) ?? "") : "#") == letter
                                        
                                    }).last ? 1 : 1 )
                                }
                            }
                        }.hideRowSeparator()
                    }
                }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).drawingGroup()
                HStack {
                    Spacer()
                    Text("\(MusicObserver.songs.count) Songs").font(.custom("Helvetica Neue Regular", fixedSize: 20)).foregroundColor(.cgLightGray).lineLimit(1)
                    Spacer()
                }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            if editing_state == "Active_Empty" {
                Color.black.opacity(0.9).edgesIgnoringSafeArea(.all).offset(y: 44)
            }
            if editing_state == "Active" {
                Color.white.edgesIgnoringSafeArea(.all).offset(y: 44)
                List {
                    if MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search)}.count != 0 {
                        Section(header: generic_text_list_header(letter: "Artists (\(MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search)}.count) \(result_results_collection(MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search)})))").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                            ForEach(MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search) }, id: \.persistentID) { artist in
                                Button(action:{
                                }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        HStack() {
                                            Image(uiImage: artist.representativeItem?.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95)
                                            Text(artist.representativeItem?.artist ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 6).padding(.trailing, 40)
                                            Spacer()
                                            Image("UITableNext").padding(.trailing, 12)
                                        }
                                        Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                        
                                    }
                                }
                            }.hideRowSeparator_larger().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 60).drawingGroup()
                        }
                    }
                    if MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search)}.count != 0 {
                        Section(header: generic_text_list_header(letter: "Songs (\(MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search)}.count) \(result_results(MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search)})))").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                            ForEach(MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search) }, id: \.persistentID) { song in
                                Button(action:{
                                    let musicPlayer = MPMusicPlayerController.systemMusicPlayer
                                    SKCloudServiceController().requestCapabilities { (capability:SKCloudServiceCapability, err:Error?) in
                                        
                                        guard err == nil else {
                                            print("error in capability check is \(err!)")
                                            return
                                        }
                                        
                                        if capability.contains(SKCloudServiceCapability.musicCatalogPlayback) {
                                            print("user has Apple Music subscription")
                                            musicPlayer.nowPlayingItem = nil
                                            musicPlayer.setQueue(with: MPMediaItemCollection(items: [song]))
                                            musicPlayer.prepareToPlay { (error) in
                                                if error != nil && error!.localizedDescription == "The operation couldn’t be completed. (MPCPlayerRequestErrorDomain error 1.)" {
                                                } else {
                                                    musicPlayer.play()
                                                    forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
                                                }
                                            }
                                        }
                                        
                                        if capability.contains(SKCloudServiceCapability.musicCatalogSubscriptionEligible) {
                                            print("user does not have subscription")
                                        }
                                        
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        HStack() {
                                            Image(uiImage: song.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95)
                                            VStack(alignment: .leading, spacing: 0) {
                                                Text(song.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                                                Spacer().frame(height:1)
                                                Text("\(song.albumTitle ?? "---") - \(song.artist ?? "---")")
                                                    .font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(.cgLightGray).lineLimit(1)
                                            }.padding(.leading, 6).padding(.trailing, 40)
                                            Spacer()
                                            Image("UITableNext").padding(.trailing, 12)
                                        }
                                        Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                        
                                    }
                                }
                            }.hideRowSeparator_larger().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 60).drawingGroup()
                        }
                    }
                }.offset(y: 44)
            }
            
        }
    }
}

struct shuffle: View {
    var songs: [MPMediaItem]
    @Binding var forward_or_backward: Bool
    @Binding var current_nav_view: String
    var body: some View {
        Button(action:{
            let musicPlayer = MPMusicPlayerController.systemMusicPlayer
            SKCloudServiceController().requestCapabilities { (capability:SKCloudServiceCapability, err:Error?) in
                
                guard err == nil else {
                    print("error in capability check is \(err!)")
                    return
                }
                
                if capability.contains(SKCloudServiceCapability.musicCatalogPlayback) {
                    print("user has Apple Music subscription")
                    musicPlayer.nowPlayingItem = nil
                    musicPlayer.setQueue(with: MPMediaItemCollection(items: songs.shuffled()))
                    musicPlayer.prepareToPlay { (error) in
                        if error != nil && error!.localizedDescription == "The operation couldn’t be completed. (MPCPlayerRequestErrorDomain error 1.)" {
                        } else {
                            musicPlayer.play()
                            forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
                        }
                    }
                }
                
                if capability.contains(SKCloudServiceCapability.musicCatalogSubscriptionEligible) {
                    print("user does not have subscription")
                }
                
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height:4.5 + 0.95/2)
                HStack() {
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Shuffle").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                            Image("shuffle_icon")
                        }
                    }.padding(.leading, 11).padding(.trailing, 40)
                }
                Spacer().frame(height:4.5 + 0.95/2)
            }
        }
    }
}




//**MARK: Videos

struct ipod_videos: View {
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            VStack() {
                HStack {
                    Image("no_videos_icon").resizable().scaledToFit().padding([.leading, .trailing], 70)
                }
                Spacer().frame(height:35)
                HStack {
                    Spacer()
                    Text("No Videos") .font(.custom("Helvetica Neue Bold", fixedSize: 20))
                        .foregroundColor(Color(red: 98/255, green: 106/255, blue: 121/255))
                    Spacer()
                }
                Spacer().frame(height:20)
                HStack {
                    Spacer()
                    Text("You can download videos from iTunes.") .font(.custom("Helvetica Neue Bold", fixedSize: 14))
                        .foregroundColor(Color(red: 98/255, green: 106/255, blue: 121/255))
                    Spacer().frame(width:5)
                    ZStack {
                        Circle().fill(Color(red: 125/255, green: 127/255, blue: 133/255)).frame(width: 14, height: 14)
                        Arrow().frame(width:7.5, height: 7.5).foregroundColor(.white)
                    }
                    Spacer()
                }
            }
        }
    }
}

//I can't beleive I am doing this.

struct Arrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.size.width/2, y: 0))
        path.addLine(to: CGPoint(x: rect.size.width/2, y: rect.size.height/3))
        path.addLine(to: CGPoint(x: 0, y: rect.size.height/3))
        path.addLine(to: CGPoint(x: 0, y: rect.size.height/3*2))
        path.addLine(to: CGPoint(x: rect.size.width/2, y: rect.size.height/3*2))
        path.addLine(to: CGPoint(x: rect.size.width/2, y: rect.size.height))
        path.addLine(to: CGPoint(x: rect.size.width, y: rect.size.height/2))
        path.closeSubpath()
        
        return path
    }
}

//**MARK: More

struct ipod_more: View {
    var bar_items = ["Albums": "BarAlbums", "Audiobooks": "BarAudioBooks", "Composers":"BarComposers", "Genres": "BarGenres", "iTunes U": "BarITunesU", "Podcasts":"BarPodcasts"]
    var body: some View {
        NoSepratorList {
            ForEach(bar_items.sorted(by: <), id: \.key) { key, value in
                VStack(alignment: .leading, spacing: 0) {
                    //Spacer().frame(height:4.5)
                    HStack(alignment: .center) {
                        Spacer().frame(width:1, height: 44-0.95)
                        Image(value).frame(width:25, height: 44-0.95)
                        Text(key).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 6).padding(.trailing, 40)
                        Spacer()
                        Image("UITableNext").padding(.trailing, 12)
                    }.padding(.leading, 15)
                    //  Spacer().frame(height:9.5)
                    Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                    
                }
            }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 44).drawingGroup()
            
        }.background(Color.white)
    }
}

//**MARK: Music Observer

class MusicObserver: ObservableObject {
    
    @Published var allowMusicLibraryAccess: Bool = false
    @Published var songs: [MPMediaItem]
    @Published var playists: [MPMediaItemCollection]
    @Published var artists: [MPMediaItemCollection]
    @Published var ab: [MPMediaItemCollection]
    init() {
        self.songs = [MPMediaItem]()
        self.playists = [MPMediaItemCollection]()
        self.artists = [MPMediaItemCollection]()
        self.ab = [MPMediaItemCollection]()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { //We do this to ensure the transition works, and music library is loaded soon after
            self.initAllowMusicLibraryAccess()
        }
    }
    
    private func initAllowMusicLibraryAccess() -> Void {
        MPMediaLibrary.requestAuthorization { status in
            if status == .authorized {
                DispatchQueue.main.async {
                    SKCloudServiceController.requestAuthorization { status2 in
                        if  SKCloudServiceController.authorizationStatus() == .authorized {
                            self.allowMusicLibraryAccess = true
                            
                            //** Loading Albums
                            let ab = MPMediaQuery.albums()
                            self.ab = ab.collections ?? []
                            
                            //** Loading Playlists
                            let p = MPMediaQuery.playlists()
                            self.playists = p.collections ?? []
                            
                            //** Loading Artists
                            let a = MPMediaQuery.artists()
                            self.artists = a.collections ?? []
                            
                            //** Loading Songs
                            let s = MPMediaQuery.songs()
                            s.addFilterPredicate(MPMediaPropertyPredicate(value:false,
                                                                          forProperty:MPMediaItemPropertyIsCloudItem,
                                                                          comparisonType:.equalTo))
                            self.songs = s.items ?? []
                            
                        }
                    }
                }
            }
        }
    }
}

//**MARK: CoverFlow Views
struct containerCoverflow: View {
    //  var geometry: GeometryProxy
    var body: some View {
        CoverFlowView()
    }
}

struct CoverFlowView: View {
    @EnvironmentObject var MusicObserver: MusicObserver
    @State var current_album: MPMediaItemCollection = MPMediaItemCollection.init(items: [])
    @State var is_showing_back: Bool = false
    //  var geometry: GeometryProxy
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                CoverFlow_Sub(geometry: geometry, albums: MusicObserver.ab, current_album: $current_album, is_showing_back: $is_showing_back).frame(width: geometry.size.height, height: geometry.size.width) //.rotationEffect(.degrees(-90))
                VStack {
                    status_bar().frame(width: geometry.size.height, height: 24)
                    Spacer()
                    HStack(alignment: .bottom) {
                        Image("CoverFlowPlayIndicator").padding(.leading, 8)
                        Spacer()
                        VStack {
                            Text(current_album.representativeItem?.artist ?? "Unknown").font(.custom("Helvetica Neue Bold", fixedSize: 15)).foregroundColor(.white).multilineTextAlignment(.center).lineLimit(0)
                            Text(current_album.representativeItem?.albumTitle ?? "Unknown").font(.custom("Helvetica Neue Bold", fixedSize: 15)).foregroundColor(.white).multilineTextAlignment(.center).lineLimit(0)
                        }.isHidden(is_showing_back)
                        Spacer()
                        Image("CoverFlowInfoIcon").padding(.trailing, 8)
                    }.padding(.bottom, 10)
                }.frame(width: geometry.size.height, height: geometry.size.width)
            }.frame(width: geometry.size.width, height: geometry.size.height)
        }.rotationEffect(.degrees(UIDevice.current.orientation == .landscapeLeft ? 90 : -90)).onAppear() {
            let music_player = MPMusicPlayerController.systemMusicPlayer
            current_album = MusicObserver.ab[optional: MusicObserver.ab.firstIndex(where: {
                $0.representativeItem?.albumPersistentID == music_player.nowPlayingItem?.albumPersistentID
            }) ?? 0] ?? MPMediaItemCollection.init(items: [])
        }
        
    }
}


struct coverflow_selected_item: View {
    @State var current_song: MPMediaItem?
    @State var new_track_delay: Bool = false
    @Binding var current_album: MPMediaItemCollection
    let song_publisher = NotificationCenter.default
        .publisher(for: .MPMusicPlayerControllerNowPlayingItemDidChange)
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("NowPlayingTableBackground").resizable().scaledToFill().frame(width:geometry.size.width, height: geometry.size.height).clipped()
                VStack(spacing: 0) {
                    ZStack {
                        Rectangle().fill(LinearGradient([Color(red: 171/255, green: 183/255, blue: 209/255), Color(red: 120/255, green: 144/255, blue: 188/255)], from: .top, to: .bottom)).frame(width: geometry.size.width, height: 50)
                        HStack(spacing: 0) {
                            VStack(alignment: .leading) {
                                Text(current_album.representativeItem?.artist ?? "Unknown").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.white).lineLimit(0)
                                Text(current_album.representativeItem?.albumTitle ?? "Unknown").font(.custom("Helvetica Neue Bold", fixedSize: 20)).foregroundColor(.white).lineLimit(0)
                            }.padding([.leading, .trailing], 5)
                            Spacer()
                            Image(uiImage: current_album.representativeItem?.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 50, height: 50)
                        }.frame(width: geometry.size.width, height: 50)
                    }.frame(width: geometry.size.width, height: 50)
                    ScrollView(showsIndicators: false) {
                        LazyVStack {
                            ForEach(removeDuplicates(current_album.items), id: \.persistentID) { track in
                                Button(action:{
                                    if new_track_delay == false {
                                        new_track_delay = true
                                        play_song(song: track)
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        new_track_delay = false
                                    }
                                }) {
                                    VStack {
                                        if track == removeDuplicates(current_album.items)[0] {
                                            Rectangle().fill(Color(red: 65/255, green: 64/255, blue: 65/255)).frame(height:2)
                                        }
                                        Spacer()
                                        HStack {
                                            HStack {
                                                Text("\(String(track.albumTrackNumber)).").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).padding(.leading, 5).padding(.trailing, 5).multilineTextAlignment(.leading)
                                                Spacer()
                                            }.frame(width:60)
                                            Text(track.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).padding(.leading, 14)
                                            Spacer()
                                            HStack {
                                                Spacer()
                                                Text(formatTimeFor(seconds: track.playbackDuration)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).padding(.trailing, 5).padding(.leading, 5).multilineTextAlignment(.trailing)
                                            }.frame(width:60)
                                        }
                                        Spacer()
                                        Rectangle().fill(Color(red: 65/255, green: 64/255, blue: 65/255)).frame(height:2)
                                    }.overlay(
                                        ZStack {
                                            HStack(alignment:.center) {
                                                Rectangle().fill(Color(red: 65/255, green: 64/255, blue: 65/255)).frame(width:2).padding(.leading, 65)
                                                Spacer()
                                            }
                                            HStack(alignment:.center) {
                                                Spacer()
                                                Rectangle().fill(Color(red: 65/255, green: 64/255, blue: 65/255)).frame(width:2).padding(.trailing, 65)
                                            }
                                            if track == current_song {
                                                HStack(alignment:.center) {
                                                    Image("play").resizable().renderingMode(.template).scaledToFit().foregroundColor(Color(red: 54/255, green: 98/255, blue: 214/255)).frame(height:10).padding(.leading, 40)
                                                    Spacer()
                                                }
                                            }
                                        }
                                        
                                    ).background((removeDuplicates(current_album.items).firstIndex(of: track) ?? 0) % 2  == 0 ? Color.clear : Color.black.opacity(0.2))
                                }.frame(height: 44)
                            }
                        }
                    }
                }
            }.frame(width: geometry.size.width, height: geometry.size.height).border_bottom(width: 1, edges: [.top, .leading, .trailing], color: Color.white)
        }.onReceive(song_publisher) { (output) in
            let music_player = MPMusicPlayerController.systemMusicPlayer
            let current = music_player.nowPlayingItem
            current_song = current
        }.onAppear() {
            let music_player = MPMusicPlayerController.systemMusicPlayer
            let current = music_player.nowPlayingItem
            current_song = current
        }
    }
}

struct TapView: UIViewRepresentable {
    var tappedCallback: (() -> Void)
    
    func makeUIView(context: Context) -> UIView {
        let v = UIView(frame: .zero)
        let gesture = SingleTouchDownGestureRecognizer(target: context.coordinator,
                                                       action: #selector(Coordinator.tapped))
        v.addGestureRecognizer(gesture)
        return v
    }
    
    class Coordinator: NSObject {
        var tappedCallback: (() -> Void)
        
        init(tappedCallback: @escaping (() -> Void)) {
            self.tappedCallback = tappedCallback
        }
        
        @objc func tapped(gesture:UITapGestureRecognizer) {
            self.tappedCallback()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(tappedCallback:self.tappedCallback)
    }
    
    func updateUIView(_ uiView: UIView,
                      context: Context) {
    }
}

class SingleTouchDownGestureRecognizer: UIGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if self.state == .possible {
            self.state = .recognized
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        self.state = .failed
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        self.state = .failed
    }
}

struct CoverFlow_Sub: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = UIViewController
    
    
    var VC = UIViewController()
    var geometry: GeometryProxy
    var albums: [MPMediaItemCollection]
    @Binding var current_album: MPMediaItemCollection
    @Binding var is_showing_back: Bool
    var v2 = UIView()
    var v3 = UIView()
    var backside: UIHostingController<coverflow_selected_item>?
    var carousel = iCarousel()
    var v = UIView()
    init(geometry: GeometryProxy, albums: [MPMediaItemCollection], current_album: Binding<MPMediaItemCollection>, is_showing_back: Binding<Bool>) {
        self.geometry = geometry
        self.albums = albums
        _current_album = current_album
        _is_showing_back = is_showing_back
        backside = UIHostingController(rootView: coverflow_selected_item(current_album: $current_album))
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        VC.view.frame = CGRect(x:0, y: 0, width: geometry.size.height, height: geometry.size.width)
        v3.frame = CGRect(x: 0, y: 0, width: geometry.size.height, height: geometry.size.width)
        carousel.frame = CGRect(x: 0, y:0, width: geometry.size.height, height: geometry.size.width)
        carousel.dataSource = context.coordinator
        carousel.delegate = context.coordinator
        carousel.type = .coverFlow2
        v2.frame = CGRect(0, 0, geometry.size.height * 3/5, geometry.size.width - 24)
        backside?.view.frame = CGRect(0, 0, geometry.size.height * 0.5, geometry.size.width - 24)
        v2.backgroundColor = .red
        VC.view.addSubview(v3)
        v3.addSubview(carousel)
        v3.addSubview(backside?.view ?? UIView())
        backside?.view.alpha = 0.5
        backside?.view.center = CGPoint(geometry.size.height/2, geometry.size.width/2 + 12)
        backside?.view.isHidden = true
        let music_player = MPMusicPlayerController.systemMusicPlayer
        carousel.currentItemIndex = albums.firstIndex(where: {
            $0.representativeItem?.albumPersistentID == music_player.nowPlayingItem?.albumPersistentID
        }) ?? 0
        v.frame = CGRect(x: 0, y:0, width: geometry.size.height, height: geometry.size.width)
        let gesture = SingleTouchDownGestureRecognizer(target: context.coordinator,
                                                       action: #selector(Coordinator.flip_back))
        v.addGestureRecognizer(gesture)
        
        return VC
    }
    
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, iCarouselDelegate, iCarouselDataSource {
        var parent: CoverFlow_Sub
        init(_ parent: CoverFlow_Sub) {
            self.parent = parent
        }
        func numberOfItems(in carousel: iCarousel) -> Int {
            return parent.albums.count
        }
        
        @objc func flip_back() {
            print("flip back")
            parent.v.removeFromSuperview()
            if #available(iOS 15, *) {
                UIView.transition(with: self.parent.backside?.view ?? UIView(), duration: 1.0, options: [UIDevice.current.orientation == .landscapeLeft ? .transitionFlipFromBottom : .transitionFlipFromTop, .showHideTransitionViews], animations: {
                    self.parent.backside?.view.isHidden = true
                    self.parent.backside?.view.alpha = 0
                })
            } else {
                UIView.transition(with: self.parent.backside?.view ?? UIView(), duration: 1.0, options: [.transitionFlipFromLeft, .showHideTransitionViews], animations: {
                    self.parent.backside?.view.alpha = 0
                })
            }
            UIView.transition(with: (parent.carousel.currentItemView!) ?? UIView(), duration: 1.0, options: [.allowAnimatedContent, .transitionFlipFromLeft, .showHideTransitionViews], animations: {
                self.parent.carousel.currentItemView!.clipsToBounds = false
                self.parent.carousel.currentItemView!.alpha = 1.0
            })
            if #available(iOS 15, *) {
                //
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.parent.backside?.view.isHidden = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.parent.carousel.isUserInteractionEnabled = true
                withAnimation(.linear(duration: 0.1)) {
                    self.parent.is_showing_back = false
                }
            }
        }
        
        func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
            parent.current_album = parent.albums[carousel.currentItemIndex]
        }
        
        func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
            
            parent.current_album = parent.albums[index]
            if parent.current_album == parent.albums[index] {
                parent.v3.insertSubview(parent.v, belowSubview: parent.backside?.view ?? UIView())
                carousel.isUserInteractionEnabled = false
                withAnimation(.linear(duration: 0.1)) {
                    parent.is_showing_back = true
                }
                UIView.transition(with: (carousel.currentItemView!) ?? UIView(), duration: 1.0, options: [.transitionFlipFromRight, .allowAnimatedContent, .showHideTransitionViews], animations: {
                    carousel.currentItemView!.alpha = 0.0
                    self.parent.carousel.currentItemView!.clipsToBounds = false
                })
                
                if #available(iOS 15, *) {
                    
                    
                    UIView.transition(with: self.parent.backside?.view ?? UIView(), duration: 1.0, options: [UIDevice.current.orientation == .landscapeLeft ? .transitionFlipFromTop : .transitionFlipFromBottom, .showHideTransitionViews], animations: {
                        self.parent.backside?.view.isHidden = false
                        self.parent.backside?.view.alpha = 1.0
                    })
                } else {
                    
                    UIView.transition(with: self.parent.backside?.view ?? UIView(), duration: 1.0, options: [.transitionFlipFromRight, .allowAnimatedContent, .showHideTransitionViews], animations: {
                        self.parent.backside?.view.isHidden = false
                        self.parent.backside?.view.alpha = 1.0
                    })
                }
            }
            print("tap")
        }
        
        func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
            var view = UIHostingController(rootView: ios_14_image_hosting(image: (parent.albums[index].representativeItem?.artwork?.image(at: CGSize(250, 250)) ?? UIImage(named: "noartplaceholder")) ?? UIImage()))
            view.view.frame = CGRect(0, 0, 250, 250)
            return view.view
            
        }
        
        
    }
    
    
}

struct ios_14_image_hosting: View {
    var image: UIImage
    var body: some View {
        ZStack {
            Image(uiImage: image).resizable().frame(width:250, height: 250).opacity(0.7).rotationEffect(.degrees(-180)).offset(y:250).rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            Image(uiImage: image).resizable().frame(width:250, height: 250).innerShadowBottomWithOffset(color: Color.black.opacity(0.9), radius: 0.0125, offset: 250)
        }.frame(height:250)
    }
}



func resizeCoverFlowImage(image: UIImage, newWidth: CGFloat) -> UIImage {
    
    let scale = newWidth / image.size.width
    let newHeight = image.size.height * scale
    UIGraphicsBeginImageContext(CGSize(newWidth, newHeight))
    image.draw(in: CGRect(0, 0, newWidth, newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage ?? UIImage()
}




//**MARK: Common

struct ipod_search: View {
    @Binding var search: String
    @State var place_holder = ""
    var no_right_padding: Bool?
    @Binding var editing_state: String
    private let gradient = LinearGradient([.white, .white], to: .trailing)
    private let cancel_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        ZStack {
            Rectangle().fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 252/255, green: 250/255, blue: 250/255), location: 0), .init(color: Color(red: 224/255, green: 228/255, blue: 231/255), location: 0.04), .init(color: Color(red: 180/255, green: 190/255, blue: 198/255), location: 1)]), startPoint: .top, endPoint: .bottom)).border_top(width: 0.75, edges: [.top], color: Color(red: 163/255, green: 173/255, blue: 182/255))
            VStack {
                Spacer()
                HStack {
                    HStack {
                        Spacer(minLength: 5)
                        HStack (alignment: .center,
                                spacing: 10) {
                            Image("search_icon").resizable().font(Font.title.weight(.medium)).frame(width: 15, height: 15).padding(.leading, 5)
                            
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
                    } .ps_innerShadow(.capsule(gradient), radius:1.6, offset: CGPoint(0, 1), intensity: 0.7).strokeCapsule(Color(red: 166/255, green: 166/255, blue: 166/255), lineWidth: 0.33).padding(.leading, 5.5).padding(.trailing, no_right_padding == true ? 5.5 : 35)
                    if editing_state != "None" {
                        Button(action:{hideKeyboard()}) {
                            ZStack {
                                Text("Cancel").font(.custom("Helvetica Neue Bold", fixedSize: 13.25)).foregroundColor(.white).shadow(color: Color.black.opacity(0.75), radius: 1, x: 0, y: -0.25)
                            }.frame(width: 59, height: 32).ps_innerShadow(.roundedRectangle(5.5, cancel_gradient), radius:0.8, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                            .padding(.trailing, 5)
                        }.frame(width: 59, height: 32).transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing))).fixedSize()
                    }
                }
                Spacer()
            }
        }
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct HideRowSeparatorModifier: ViewModifier {
    
    static let defaultListRowHeight: CGFloat = 44
    
    var insets: EdgeInsets
    var background: Color
    
    init(insets: EdgeInsets, background: Color) {
        self.insets = insets
        
        var alpha: CGFloat = 0
        UIColor(background).getWhite(nil, alpha: &alpha)
        assert(alpha == 1, "Setting background to a non-opaque color will result in separators remaining visible.")
        self.background = background
    }
    
    func body(content: Content) -> some View {
        content
            .padding(insets)
            .frame(
                minWidth: 0, maxWidth: .infinity,
                minHeight: Self.defaultListRowHeight,
                alignment: .leading
            )
            .listRowInsets(EdgeInsets())
            .background(background)
    }
}

struct HideRowSeparatorModifier_Larger: ViewModifier {
    
    static let defaultListRowHeight: CGFloat = 60
    
    var insets: EdgeInsets
    var background: Color
    
    init(insets: EdgeInsets, background: Color) {
        self.insets = insets
        
        var alpha: CGFloat = 0
        UIColor(background).getWhite(nil, alpha: &alpha)
        assert(alpha == 1, "Setting background to a non-opaque color will result in separators remaining visible.")
        self.background = background
    }
    
    func body(content: Content) -> some View {
        content
            .padding(insets)
            .frame(
                minWidth: 0, maxWidth: .infinity,
                minHeight: Self.defaultListRowHeight,
                alignment: .leading
            )
            .listRowInsets(EdgeInsets())
            .background(background)
    }
}

extension EdgeInsets {
    
    static let defaultListRowInsets = Self(top: 0, leading: 0, bottom: 0, trailing: 0)
}

extension View {
    
    func hideRowSeparator(
        insets: EdgeInsets = .defaultListRowInsets,
        background: Color = .white
    ) -> some View {
        modifier(HideRowSeparatorModifier(
            insets: insets,
            background: background
        ))
    }
    func hideRowSeparator_larger(
        insets: EdgeInsets = .defaultListRowInsets,
        background: Color = .white
    ) -> some View {
        modifier(HideRowSeparatorModifier_Larger(
            insets: insets,
            background: background
        ))
    }
}

struct HideRowSeparator_Previews: PreviewProvider {
    
    static var previews: some View {
        List {
            ForEach(0..<10) { _ in
                Text("Text")
                    .hideRowSeparator()
            }
        }
        .previewLayout(.sizeThatFits)
    }
}
struct VerticalIndex: ViewModifier {
    let indexableList: [String]
    var indexes: [String]
    @State var selected: Bool = false
    @State var offset = CGSize.zero
    @State var offset_h: CGFloat = 0.0
    @Binding var editing_state: String
    func body(content: Content) -> some View {
        var body: some View {
            ScrollViewReader { scrollProxy in
                ZStack {
                    content
                    if selected {
                        HStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 24/2).fill(Color(red: 106/255, green: 115/255, blue: 125/255).opacity(0.5)).frame(width:24).padding(.trailing, 12-5).padding([.top], 13).padding(.bottom, 30)
                        }
                    }
                    VStack {
                        ForEach(indexableList, id: \.self) { letter in
                            HStack {
                                Spacer()
                                if letter == "Search" {
                                    Button(action: {
                                        scrollProxy.scrollTo(letter, anchor: .top)
                                        if let index = indexableList.firstIndex(of: letter) {
                                            print(index)
                                        }
                                    }, label: {
                                        Image(systemName: "magnifyingglass")
                                            .font(.custom("Helvetica Neue Bold", fixedSize: 13.25)).frame(width:14, height: 16.5)
                                            .foregroundColor(Color(red: 106/255, green: 115/255, blue: 125/255))
                                            .padding(.trailing, 12)
                                    })
                                } else {
                                    Button(action: {
                                        if indexes.contains(letter) {
                                            scrollProxy.scrollTo(letter, anchor: .top)
                                            if let index = indexableList.firstIndex(of: letter) {
                                                print(index)
                                            }
                                        }
                                    }, label: {
                                        Text(letter)
                                            .font(.custom("Helvetica Neue Bold", fixedSize: 13.25)).frame(width:14, height: 16.5)
                                            .foregroundColor(Color(red: 106/255, green: 115/255, blue: 125/255))
                                            .padding(.trailing, 12)
                                    })
                                }
                            }
                        }
                    }.padding(.bottom, 17).onLongPressGesture(minimumDuration: 0, pressing: { inProgress in
                        selected = inProgress
                    }) {
                        selected = false
                    }.simultaneousGesture(
                        DragGesture()
                            .onChanged { gesture in
                                if gesture.location.y/((offset_h-17)/CGFloat(indexableList.count)) > 0, gesture.location.y/((offset_h-17)/CGFloat(indexableList.count)) <= 28 {
                                    let location = gesture.location.y/((offset_h-17)/CGFloat(indexableList.count))
                                    if indexes.contains(indexableList[Int(location)]) || indexableList[Int(location)] == "Search" {
                                        // Here's essentially what we're doing here. Our goal is to convert our sliding location to an integer value that corresponds to a letter. What we do is divide our current location by the size of each letter section. This number should be 16.5, what we set above. We still, reguardless, calculate it. For example, if our location is 200, this would equate to nearly 12 letters (12.12). We round this down to 12 and arrive at the letter M -> M is 13th letter in alphabet and array.count-1 = M. This works as 0 <= x < 1 equals A.
                                        scrollProxy.scrollTo(indexableList[Int(location)], anchor: .top)
                                    }
                                }
                            }
                    ).overlay(
                        GeometryReader { proxy in
                            Color.clear.hidden().onAppear() {
                                offset_h = proxy.size.height
                                print(offset_h, (offset_h-17)/CGFloat(indexableList.count))
                            }
                        }
                    ).isHidden(editing_state != "None" ? true : false)
                }
            }
        }
        return body
    }
}


struct TabButton : View {
    
    var image : String
    @Binding var selectedTab : String
    @Binding var artists_current_view: String
    @Binding var playlist_current_nav_view: String
    var geometry: GeometryProxy
    var body: some View{
        Button(action: {
            playlist_current_nav_view = "Playlists"
            artists_current_view = "Artists"
            selectedTab = image
        }) {
            ZStack {
                if selectedTab == image {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.1)).frame(width: geometry.size.width/5 - 5, height: 51).blendMode(.screen)
                    VStack(spacing: 2) {
                        ZStack {
                            Image("\(image)_iPod").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Songs" ? 20.5 : image == "Artists" ? 37.5 : 30.5, height: 30.5).overlay(
                                LinearGradient(gradient: Gradient(colors: [Color(red: 205/255, green: 233/255, blue: 249/255), Color(red: 75/255, green: 220/255, blue: 251/255)]), startPoint: .top, endPoint: .bottom)
                            ).mask(Image("\(image)_iPod").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Songs" ? 20.5 : image == "Artists" ? 37.5 : 30.5, height: 30.5)).offset(y:-0.5)
                            
                            Image("\(image)_iPod").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Songs" ? 20 : image == "Artists" ? 37.5 : 30, height: 30).overlay(
                                ZStack {
                                    if image == "More" {
                                        LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0/255, green: 145/255, blue: 230/255), location: 0), .init(color: Color(red: 21/255, green: 197/255, blue: 252/255), location: 1)]), startPoint: .top, endPoint: .bottom).rotationEffect(Angle(degrees: image == "More" ? 0 : -15)).frame(width: image == "More" ? 40 : 40, height: image == "More" ? 10 : 30).brightness(0.095)
                                    } else {
                                        LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 197/255, green: 210/255, blue: 229/255), location: 0), .init(color: Color(red: 99/255, green: 162/255, blue: 216/255), location: 0.47), .init(color: Color(red: 0/255, green: 145/255, blue: 230/255), location: 0.49), .init(color: Color(red: 21/255, green: 197/255, blue: 252/255), location: 1)]), startPoint: .top, endPoint: .bottom).rotationEffect(Angle(degrees: image == "More" ? 0 : -15)).frame(width: image == "More" ? 40 : 40, height: image == "Artists" ? 34 : 30).brightness(0.095).offset(y: image == "Artists" ? 2 : 0)
                                    }
                                }
                            ).mask(Image("\(image)_iPod").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Songs" ? 20 : image == "Artists" ? 37.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.6), radius:2.5, x: 0, y:2.5)
                        }
                        HStack {
                            Spacer()
                            Text(image).foregroundColor(.white).font(.custom("Helvetica Neue Bold", fixedSize: 11))
                            Spacer()
                        }
                    }
                } else {
                    VStack(spacing: 2) {
                        Image("\(image)_iPod").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Songs" ? 20 : image == "Artists" ? 37.5 : 30, height: 30).overlay(
                            LinearGradient(gradient: Gradient(colors: [Color(red: 157/255, green: 157/255, blue: 157/255), Color(red: 89/255, green: 89/255, blue: 89/255)]), startPoint: .top, endPoint: .bottom)
                        ).mask(Image("\(image)_iPod").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Songs" ? 20 : image == "Artists" ? 37.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.75), radius: 0, x: 0, y: -1)
                        HStack {
                            Spacer()
                            Text(image).foregroundColor(Color(red: 168/255, green: 168/255, blue: 168/255)).font(.custom("Helvetica Neue Bold", fixedSize: 11))
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}



struct alpha_list_header: View {
    var letter: String
    var body: some View {
        ZStack {
            Rectangle().fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 148/255, green: 162/255, blue: 173/255), location: 0), .init(color: Color(red: 177/255, green: 186/255, blue: 195/255), location: 0.52), .init(color: Color(red: 183/255, green: 192/255, blue: 199/255), location: 0.93), .init(color: Color(red: 148/255, green: 158/255, blue: 166/255), location: 0.97), .init(color: Color(red: 152/255, green: 163/255, blue: 170/255), location: 1)]), startPoint: .top, endPoint: .bottom)).border_gradient(width: 2.4, edges: [.top], color: LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 176/255, green: 186/255, blue: 194/255), location: 0), .init(color: Color(red: 176/255, green: 186/255, blue: 194/255), location: 0.45), .init(color: Color(red: 165/255, green: 177/255, blue: 186/255), location: 0.5), .init(color: Color(red: 165/255, green: 177/255, blue: 186/255), location: 1)]), startPoint: .top, endPoint: .bottom)).border_gradient(width: 1.2, edges: [.top], color: LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 122/255, green: 134/255, blue: 142/255), location: 0), .init(color: Color(red: 122/255, green: 134/255, blue: 143/255), location: 0.45), .init(color: Color(red: 140/255, green: 152/255, blue: 160/255), location: 0.5), .init(color: Color(red: 140/255, green: 152/255, blue: 160/255), location: 1)]), startPoint: .top, endPoint: .bottom)).edgesIgnoringSafeArea([.leading, .trailing])
            HStack {
                Text(letter).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.white).shadow(color: Color(red: 94/255, green: 90/255, blue: 90/255).opacity(0.75), radius: 0, x: 0, y: 1.2).padding(.leading, 12)
                Spacer()
            }
        }
    }
}

struct generic_text_list_header: View {
    var letter: String
    var body: some View {
        ZStack {
            Rectangle().fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 148/255, green: 162/255, blue: 173/255), location: 0), .init(color: Color(red: 177/255, green: 186/255, blue: 195/255), location: 0.52), .init(color: Color(red: 183/255, green: 192/255, blue: 199/255), location: 0.93), .init(color: Color(red: 148/255, green: 158/255, blue: 166/255), location: 0.97), .init(color: Color(red: 152/255, green: 163/255, blue: 170/255), location: 1)]), startPoint: .top, endPoint: .bottom)).border_gradient(width: 2.4, edges: [.top], color: LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 176/255, green: 186/255, blue: 194/255), location: 0), .init(color: Color(red: 176/255, green: 186/255, blue: 194/255), location: 0.45), .init(color: Color(red: 165/255, green: 177/255, blue: 186/255), location: 0.5), .init(color: Color(red: 165/255, green: 177/255, blue: 186/255), location: 1)]), startPoint: .top, endPoint: .bottom)).border_gradient(width: 1.2, edges: [.top], color: LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 122/255, green: 134/255, blue: 142/255), location: 0), .init(color: Color(red: 122/255, green: 134/255, blue: 143/255), location: 0.45), .init(color: Color(red: 140/255, green: 152/255, blue: 160/255), location: 0.5), .init(color: Color(red: 140/255, green: 152/255, blue: 160/255), location: 1)]), startPoint: .top, endPoint: .bottom)).edgesIgnoringSafeArea([.leading, .trailing])
            HStack {
                Text(letter).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.white).shadow(color: Color(red: 94/255, green: 90/255, blue: 90/255).opacity(0.75), radius: 0, x: 0, y: 1.2).padding(.leading, 12).textCase(.none)
                Spacer()
            }
        }
    }
}


struct ipod_title_bar : View {
    @Binding var forward_or_backward: Bool
    @Binding var current_nav_view: String
    @Binding var artists_current_view: String
    @Binding var playlist_current_nav_view: String
    @Binding var selectedTab:String
    var title:String
    var body :some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.49), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.49), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(title).ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", fixedSize: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)).combined(with: .opacity)).id(title).frame(maxWidth: 180).lineLimit(0)
                    Spacer()
                }
                Spacer()
            }
            if MPMusicPlayerController.systemMusicPlayer.nowPlayingItem != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action:{forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"};UITableViewCell.appearance().backgroundColor = .clear}) {
                            ZStack {
                                Image("now_playing_icon").resizable().scaledToFit().frame(width:67, height: 40)
                                VStack(alignment: .center, spacing: 0) {
                                    Text("Now").font(.custom("Helvetica Neue Bold", fixedSize: 11)).foregroundColor(.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0.0, y: -1).multilineTextAlignment(.center)
                                    Text("Playing").font(.custom("Helvetica Neue Bold", fixedSize: 11)).foregroundColor(.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0.0, y: -1).multilineTextAlignment(.center)
                                }.offset(x:-3)
                            }.padding(.trailing, 5.5)
                        }
                    }
                    Spacer()
                }
            }
            if artists_current_view != "Artists", selectedTab == "Artists" {
                VStack {
                    Spacer()
                    HStack {
                        Button(action:{
                            forward_or_backward = true; withAnimation(.linear(duration: 0.28)){artists_current_view = (artists_current_view == "Artist_Albums" ? "Artists" : "Artist_Albums")}
                        }){
                            ZStack {
                                Image(artists_current_view == "Artist_Albums" ? "Button2" : "Button_wp4").resizable().scaledToFit().frame(width:84*(33/34.33783783783784), height: 33)
                                HStack(alignment: .center) {
                                    Text(artists_current_view == "Artist_Albums" ? "Artists" : title).foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1).offset(x: 1).frame(maxWidth: 75).lineLimit(0)
                                }
                            }.padding(.leading, 5.5)
                        }
                        Spacer()
                    }
                    Spacer()
                }.offset(y:-0.5)
            }
            if playlist_current_nav_view != "Playlists", selectedTab == "Playlists" {
                VStack {
                    Spacer()
                    HStack {
                        Button(action:{
                            forward_or_backward = true; withAnimation(.linear(duration: 0.28)){playlist_current_nav_view = "Playlists"}
                        }){
                            ZStack {
                                Image("Button_wp4").resizable().scaledToFit().frame(width:84*(33/34.33783783783784), height: 33)
                                HStack(alignment: .center) {
                                    Text("Playlists").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1).offset(x: 1).frame(maxWidth: 75).lineLimit(0)
                                }
                            }.padding(.leading, 5.5)
                        }
                        Spacer()
                    }
                    Spacer()
                }.offset(y:-0.5)
            }
            
        }
    }
}

struct now_playing_title_bar : View {
    @Binding var forward_or_backward: Bool
    @Binding var current_nav_view: String
    @Binding var artist: String?
    @Binding var song: String?
    @Binding var album: String?
    @Binding var album_image: UIImage
    @Binding var switch_to_tracks: Bool
    @Binding var show_back_tracks: Bool
    @Binding var hide_album_image: Bool
    @State var momentary_disable: Bool = false
    @Binding var flipper_background: Bool
    var title:String
    var body :some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.02), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
            HStack {
                Button(action:{forward_or_backward = true; withAnimation(.linear(duration: 0.28)){current_nav_view = "Main"}}) {
                    ZStack {
                        Image("button_back_ipod2").resizable().scaledToFit().frame(width:102/(69/34.33783783783784), height: 34.33783783783784)
                        Image("UINavigationBarBackArrow").resizable().scaledToFit().frame(width:23, height: 19).padding(.leading, 2)
                    }.padding(.leading, 8)
                }
                Spacer()
                VStack(spacing:0) {
                    Spacer()
                    Text(artist ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color(red: 159/255, green: 159/255, blue: 159/255)).shadow(color: Color.black.opacity(0.8), radius: 0, x: 0.0, y: -1).multilineTextAlignment(.center).lineLimit(1)
                    Text(song ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.white).shadow(color: Color.black.opacity(0.8), radius: 0, x: 0.0, y: -1).multilineTextAlignment(.center).lineLimit(1)
                    Text(album ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color(red: 159/255, green: 159/255, blue: 159/255)).shadow(color: Color.black.opacity(0.8), radius: 0, x: 0.0, y: -1).multilineTextAlignment(.center).lineLimit(1)
                    Spacer()
                }.offset(y:-1)
                Spacer()
                ZStack {
                    Button(action:{
                        momentary_disable = true
                        if switch_to_tracks == false { //maybe + 0.1 -> orig 0.5
                            withAnimation(.easeIn(duration: 0.4)){switch_to_tracks.toggle();flipper_background.toggle()}
                            DispatchQueue.main.asyncAfter(deadline:.now()+0.39) { //maybe 0.45
                                withAnimation(.easeOut(duration: 0.4)){show_back_tracks.toggle()}
                            }
                            DispatchQueue.main.asyncAfter(deadline:.now()+0.8) {
                                momentary_disable = false
                                hide_album_image = true
                            }
                        } else {
                            withAnimation(.easeIn(duration: 0.4)){show_back_tracks.toggle()}
                            DispatchQueue.main.asyncAfter(deadline:.now()) {
                                hide_album_image = false
                            }
                            DispatchQueue.main.asyncAfter(deadline:.now()+0.39) { //maybe 0.45
                                withAnimation(.easeOut(duration: 0.4)){switch_to_tracks.toggle()}
                            }
                            DispatchQueue.main.asyncAfter(deadline:.now()+0.48) {
                                withAnimation(.easeIn(duration: 0.4)){flipper_background.toggle()}
                            }
                            DispatchQueue.main.asyncAfter(deadline:.now()+0.8) {
                                momentary_disable = false
                            }
                        }
                    }) {
                        ZStack {
                            HStack {
                                Spacer()
                                Image("NowPlayingFlipperBackground").resizable().scaledToFit().frame(width:37.5, height: 37.5).clipped().opacity(flipper_background == false ? 0 : 1).offset(x: (37.5-34.33783783783784)/2, y: -(37.5-34.33783783783784)/12)
                            }
                            HStack {
                                Spacer()
                                Image(uiImage: album_image).resizable().scaledToFit().frame(width:34.33783783783784, height: 34.33783783783784).clipped().rotation3DEffect(.degrees(show_back_tracks == false ? 90 : 0), axis: (x: 0, y:1, z: 0), anchor: UnitPoint(0, 0.5)).offset(x:show_back_tracks == false ? 34.33783783783784/2 : 0).opacity(show_back_tracks == false ? 0.5: 1)
                            }
                            HStack {
                                Spacer()
                                Image("NowPlayingAlbumInfo").resizable().scaledToFit().frame(width:34.33783783783784, height: 34.33783783783784).clipped().rotation3DEffect(.degrees(switch_to_tracks == true ? -90 : 0), axis: (x: 0, y:1, z: 0), anchor: UnitPoint(1, 0.5)).offset(x:switch_to_tracks == true ? -34.33783783783784/2 : 0)
                            }
                        }
                    }.disabled(momentary_disable)
                }.frame(width:102/(69/34.33783783783784)).padding(.trailing, 8) //I, personally, didn't want to do it this way...but this is how Apple did it. Why???
            }
        }
    }
}




func isDigit(c: Character) -> Bool {
    return "0" <= c && c <= "9"
}

func sortedLettersFirst(lhs: String, rhs: String) -> Bool {
    for (lc, rc) in zip(lhs, rhs) {
        if lc == rc { continue }
        
        if isDigit(c: lc) && !isDigit(c: rc) {
            return false
        }
        if !isDigit(c: lc) && isDigit(c: rc) {
            return true
        }
        return lc < rc
    }
    return lhs.count < rhs.count
}
