//
//  AppStore.swift
//  OldOS
//
//  Created by Zane Kleinberg on 3/15/21.
//

import SwiftUI
import WebKit
import FeedKit
import Foundation
import SDWebImageSwiftUI
import SwiftUIPager

struct AppStore: View {
    @State var current_nav_view: String = "Main"
    @State var forward_or_backward: Bool = false
    @State var selectedTab = "Featured"
    @State var selected_segment: Int = 0
    @State var selected_segment_25: Int = 0
    @StateObject var featured_observer = FeaturedApplicationsObserver()
    @StateObject var top_paid_and_free_observer = TopPaidAndFreeApplicationsObserver()
    @State var featured_show_application: Bool = false
    @State var featured_selected_application: Application_Data.Results?
    @State var top25_show_application: Bool = false
    @State var top25_selected_application: Application_Data.Results?
    @State var categories_current_view: String = "Main"
    @State var categories_selected_application: Application_Data.Results?
    @State var selected_category: app_category_datetype = app_category_datetype(name: "", genre_id: "", image_url: nil)
    @State var search_results = [Application_Data.Results]()
    @State var search_show_application: Bool = false
    @State var search_selected_application: Application_Data.Results?
    @State var editing_state: String = "None"
    @Binding var instant_multitasking_change: Bool
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing:0) {
                    status_bar_in_app().frame(minHeight: 24, maxHeight:24).zIndex(1)
                    app_store_title_bar(title: (selectedTab != "Featured" || featured_show_application == false) ? (selectedTab != "Top 25" || top25_show_application == false) ? (selectedTab != "Search" || search_show_application == false) ? (selectedTab == "Categories" && categories_current_view == "Main") ? selectedTab : (selectedTab == "Categories" && categories_current_view == "Category") ? selected_category.name : selectedTab == "Updates" ? selectedTab : "Info" : "Info" : "Info" : "Info", selected_segment: $selected_segment, selected_segment_25: $selected_segment_25, forward_or_backward: $forward_or_backward, selectedTab: $selectedTab, featured_show_application: $featured_show_application, top25_show_application: $top25_show_application, categories_current_view: $categories_current_view, search_results: $search_results, search_show_application: $search_show_application, search_selected_application: $search_selected_application, editing_state: $editing_state, show_edit: false, show_plus: false, instant_multitasking_change: $instant_multitasking_change).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 60, maxHeight:60).zIndex(1)
                    AppStoreTabView(selectedTab: $selectedTab, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, selected_segment: $selected_segment, selected_segment_25: $selected_segment_25, featured_observer: featured_observer, top_paid_and_free_observer: top_paid_and_free_observer, featured_show_application: $featured_show_application, featured_selected_application: $featured_selected_application, top25_show_application: $top25_show_application, top25_selected_application: $top25_selected_application, categories_current_view: $categories_current_view, categories_selected_application: $categories_selected_application, selected_category: $selected_category, search_results: $search_results, search_show_application: $search_show_application, search_selected_application: $search_selected_application, editing_state: $editing_state).clipped()
                }
            }.compositingGroup().clipped()
        }.onAppear() {
            UIScrollView.appearance().bounces = true
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
        }
    }
}

//struct AppStore_Previews: PreviewProvider {
//    static var previews: some View {
//        AppStore()
//    }
//}

var appstore_tabs = ["Featured", "Categories", "Top 25", "Search", "Updates"]
struct AppStoreTabView : View {
    
    @Binding var selectedTab:String
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var selected_segment: Int
    @Binding var selected_segment_25: Int
    @StateObject var featured_observer: FeaturedApplicationsObserver
    @StateObject var top_paid_and_free_observer: TopPaidAndFreeApplicationsObserver
    @Binding var featured_show_application: Bool
    @Binding var featured_selected_application: Application_Data.Results?
    @Binding var top25_show_application: Bool
    @Binding var top25_selected_application: Application_Data.Results?
    @Binding var categories_current_view: String
    @Binding var categories_selected_application: Application_Data.Results?
    @Binding var selected_category: app_category_datetype
    @Binding var search_results: [Application_Data.Results]
    @Binding var search_show_application: Bool
    @Binding var search_selected_application: Application_Data.Results?
    @Binding var editing_state: String
    var body: some View{
        GeometryReader {geometry in
            VStack(spacing:0) {
                
                ScrollView([], showsIndicators: false) {
                    switch selectedTab {
                    case "Featured":
                        switch featured_show_application {
                        case false:
                            featured_applications(featured_observer: featured_observer, selected_segment: $selected_segment, featured_show_application: $featured_show_application, featured_selected_application: $featured_selected_application, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).frame(height: geometry.size.height - 57).tag("Featured").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                        case true:
                            app_destination(featured_selected_application: $featured_selected_application).frame(height: geometry.size.height - 57).tag("Featured").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                        }
                    case "Categories":
                        switch categories_current_view {
                        case "Main":
                            app_store_categories(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, categories_current_view: $categories_current_view, categories_selected_application: $categories_selected_application, selected_category: $selected_category).frame(height: geometry.size.height - 57)
                                .tag("Categories").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                        case "Category":
                            category_destination(selected_category: $selected_category, categories_current_view: $categories_current_view, categories_selected_application: $categories_selected_application, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward) .tag("Categories").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                        case "Destination":
                            app_destination(featured_selected_application: $categories_selected_application).frame(height: geometry.size.height - 57).tag("Categories").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                        default:
                            app_store_categories(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, categories_current_view: $categories_current_view, categories_selected_application: $categories_selected_application, selected_category: $selected_category).frame(height: geometry.size.height - 57)
                                .tag("Categories").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                        }
                    case "Top 25":
                        switch top25_show_application {
                        case false:
                            top_25_applications(top_paid_and_free_observer: top_paid_and_free_observer, selected_segment_25: $selected_segment_25, top25_show_application: $top25_show_application, top25_selected_application: $top25_selected_application, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).frame(height: geometry.size.height - 57)
                                .tag("Top 25").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                        case true:
                            app_destination(featured_selected_application: $top25_selected_application).frame(height: geometry.size.height - 57).tag("Top 25").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                        }
                    case "Search":
                        switch search_show_application {
                        case false:
                            search_applications(search_results: $search_results, search_show_application: $search_show_application, search_selected_application: $search_selected_application, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, editing_state: $editing_state).frame(height: geometry.size.height - 57).tag("Search").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                        case true:
                            app_destination(featured_selected_application: $search_selected_application).frame(height: geometry.size.height - 57).tag("Search").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                        }
                    case "Updates":
                        updatable_applications().frame(height: geometry.size.height - 57)
                            .tag("Updates")
                    default:
                        blank_appstore_view().frame(height: geometry.size.height - 57)
                            .tag("Featured")
                    }
                }.background(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0), .init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0.5), .init(color: Color.white, location: 0.5), .init(color: Color.white, location: 1)]), startPoint: .top, endPoint: .bottom))
                // for bottom overflow...
                ZStack {
                    Rectangle().fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.02), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom)).frame(height:57)
                    HStack(spacing: 0){
                        
                        ForEach(appstore_tabs,id: \.self){image in
                            TabButton_AppStore(image: image, selectedTab: $selectedTab, geometry: geometry)
                            
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

//** MARK: App Store Updates:

struct updatable_applications: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing:0) {
                ScrollView(showsIndicators: true) {
                        ZStack {
                            Text("All Apps Are Up to Date").multilineTextAlignment(.center).foregroundColor(Color(red: 48/255, green: 57/255, blue: 70/255)).font(.custom("Helvetica Neue Bold", fixedSize: 16)).shadow(color: Color.white.opacity(0.7), radius: 0, x: 0.0, y: 0.9)
                        }.frame(width:geometry.size.width, height:geometry.size.height)
                    }
            }
        }.background(Color(red: 152/255, green: 152/255, blue: 152/255))
    }
}

//** MARK: App Store Search

struct search_applications: View {
    @Binding var search_results: [Application_Data.Results]
    @Binding var search_show_application: Bool
    @Binding var search_selected_application: Application_Data.Results?
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var editing_state: String
    var body: some View {
        GeometryReader { geometry in
            ZStack {
            VStack(spacing:0) {
                ScrollView(showsIndicators: true) {
                        LazyVStack {
                            ForEach(search_results, id:\.trackID) { application in
                                Button(action:{search_selected_application = application;forward_or_backward = false; withAnimation(.linear(duration: 0.28)) {search_show_application = true}}) {
                                    VStack(spacing: 0) {
                                        Spacer()
                                        HStack {
                                            WebImage(url: application.artworkUrl512).resizable().placeholder {
                                                Rectangle().foregroundColor(.gray)
                                            }.frame(width:60, height: 60).cornerRadius(60*90/512).padding(.leading, 12).shadow(color: Color.black.opacity(0.55), radius: 0.85, x: 0, y: 1.75)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(application.artistName ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                Text(application.trackName ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                HStack(spacing: 2) {
                                                    ForEach(0..<Int(application.averageUserRating)) { _ in
                                                        ZStack {
                                                            Image("UserRatingBorderedStarsForeground")
                                                        }
                                                    }.offset(y:4)
                                                    ForEach(0..<(5-Int(application.averageUserRating) < 0 ? 0 : 5-Int(application.averageUserRating))) { _ in
                                                        ZStack {
                                                            Image("UserRatingBorderedStarsBackground")
                                                        }
                                                    }.offset(y:4)
                                                    Spacer().frame(width: 2)
                                                    Text("\(String(application.userRatingCount).filter("0123456789.".contains)) Ratings").font(.custom("Helvetica Neue Regular", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                }
                                            }
                                            Spacer()
                                            HStack(spacing: 6) { //Nest in another HStack for variable spacing
                                                Image("UniversalGlyph").opacity(application.features.contains("iosUniversal") ? 1 : 0).offset(y:1)
                                                Text(application.formattedPrice ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 12)).textCase(.uppercase).foregroundColor(Color(red: 74/255, green: 74/255, blue: 74/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                Image("UITableNext")
                                            }.padding(.trailing, 12)
                                        }
                                        Spacer()
                                        Rectangle().fill((search_results.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 134/255, green: 134/255, blue: 137/255) : Color(red: 152/255, green: 152/255, blue: 155/255)).frame(height:1)
                                        Rectangle().fill((search_results.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 189/255, green: 189/255, blue: 191/255) : Color(red: 172/255, green: 172/255, blue: 175/255)).frame(height:1)
                                    }.background((search_results.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 152/255, green: 152/255, blue: 152/255) : Color(red: 173/255, green: 173/255, blue: 176/255))
                                }.frame(height: 80)
                            }
                        }
                        Spacer().frame(height: 20)
                    }
            }
                if editing_state == "Active" || editing_state == "Active_Empty" {
                Color.black.opacity(0.9).edgesIgnoringSafeArea(.all)
                }
        }
        }.background(Color(red: 152/255, green: 152/255, blue: 152/255))
    }
}

class app_category_datetype: ObservableObject, Identifiable {
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


class app_categories_observer: ObservableObject {
    @Published var categories = [app_category_datetype]()
    
    init() {
        self.categories = [
            app_category_datetype(name: "Books", genre_id: "6018", image_url: nil),
            app_category_datetype(name: "Business", genre_id: "6000", image_url: nil),
            app_category_datetype(name: "Education", genre_id: "6017", image_url: nil),
            app_category_datetype(name: "Entertainment", genre_id: "6016", image_url: nil),
            app_category_datetype(name: "Finance", genre_id: "6015", image_url: nil),
            app_category_datetype(name: "Food & Drink", genre_id: "6023", image_url: nil),
            app_category_datetype(name: "Games", genre_id: "6014", image_url: nil),
            app_category_datetype(name: "Health & Fitness", genre_id: "6013", image_url: nil),
            app_category_datetype(name: "Kids", genre_id: "7010", image_url: nil),
            app_category_datetype(name: "Lifestyle", genre_id: "6012", image_url: nil),
            app_category_datetype(name: "Magazines & Newspapers", genre_id: "6021", image_url: nil),
            app_category_datetype(name: "Medical", genre_id: "6020", image_url: nil),
            app_category_datetype(name: "Music", genre_id: "7010", image_url: nil),
            app_category_datetype(name: "Navigation", genre_id: "6010", image_url: nil),
            app_category_datetype(name: "News", genre_id: "6009", image_url: nil),
            app_category_datetype(name: "Photo & Video", genre_id: "6008", image_url: nil),
            app_category_datetype(name: "Productivity", genre_id: "6007", image_url: nil),
            app_category_datetype(name: "Reference", genre_id: "6006", image_url: nil),
            app_category_datetype(name: "Shopping", genre_id: "6024", image_url: nil),
            app_category_datetype(name: "Social Networking", genre_id: "6005", image_url: nil),
            app_category_datetype(name: "Sports", genre_id: "6004", image_url: nil),
            app_category_datetype(name: "Travel", genre_id: "6003", image_url: nil),
            app_category_datetype(name: "Utilities", genre_id: "6002", image_url: nil),
            app_category_datetype(name: "Weather", genre_id: "6001", image_url: nil)
        ]
    }
}

//** MARK: App Store Categories

struct app_store_categories: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var categories_current_view: String
    @Binding var categories_selected_application: Application_Data.Results?
    @Binding var selected_category: app_category_datetype
    @ObservedObject var categories_obs = app_categories_observer()
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing:0) {
                ScrollView(showsIndicators: true) {
                    LazyVStack {
                        ForEach(categories_obs.categories) { category in
                            Button(action:{
                                selected_category = category; forward_or_backward = false; withAnimation(.linear(duration: 0.28)) {if selected_category.genre_id == category.genre_id {categories_current_view = "Category"}}
                            }) {
                                VStack(spacing: 0) {
                                    Spacer()
                                    HStack {
                                        WebImage(url: category.image_url).resizable().placeholder {
                                            Rectangle().foregroundColor(.gray)
                                        }.frame(width:60, height: 60).cornerRadius(60*90/512).padding(.leading, 12).shadow(color: Color.black.opacity(0.55), radius: 0.85, x: 0, y: 1.75)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(category.name).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                        }
                                        Spacer()
                                        HStack(spacing: 6) { //Nest in another HStack for variable spacing
                                            Image("UITableNext")
                                        }.padding(.trailing, 12)
                                    }
                                    Spacer()
                                    Rectangle().fill((categories_obs.categories.firstIndex(where: {$0.id == category.id}) ?? 0) % 2  == 0 ? Color(red: 134/255, green: 134/255, blue: 137/255) : Color(red: 152/255, green: 152/255, blue: 155/255)).frame(height:1)
                                    Rectangle().fill((categories_obs.categories.firstIndex(where: {$0.id == category.id}) ?? 0) % 2  == 0 ? Color(red: 189/255, green: 189/255, blue: 191/255) : Color(red: 172/255, green: 172/255, blue: 175/255)).frame(height:1)
                                }.background((categories_obs.categories.firstIndex(where: {$0.id == category.id}) ?? 0) % 2  == 0 ? Color(red: 152/255, green: 152/255, blue: 152/255) : Color(red: 173/255, green: 173/255, blue: 176/255))
                            }.frame(height: 80)
                        }
                    }
                    Spacer().frame(height: 20)
                    Text("Redeem").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9).frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 252/255, green: 253/255, blue: 253/255), Color(red: 232/255, green: 235/255, blue: 241/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0.5).cornerRadius(9).strokeRoundedRectangle(9, Color(red: 133/255, green: 133/255, blue: 135/255), lineWidth: 0.5)
                    Spacer().frame(height: 10)
                    Text("Apple ID: OldOS@mac.com").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9).frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 252/255, green: 253/255, blue: 253/255), Color(red: 232/255, green: 235/255, blue: 241/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0.5).cornerRadius(9).strokeRoundedRectangle(9, Color(red: 133/255, green: 133/255, blue: 135/255), lineWidth: 0.5)
                    Spacer().frame(height: 30)
                    Text("Apple Media Services Terms and\nConditions...").multilineTextAlignment(.center).foregroundColor(Color(red: 48/255, green: 57/255, blue: 70/255)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).shadow(color: Color.white.opacity(0.7), radius: 0, x: 0.0, y: 0.9).padding(.bottom, 30)
                }
            }.onAppear() {
                for category in categories_obs.categories {
                    fetch_first_image_for_category(id: category.genre_id, completion: { result in
                        if let index = categories_obs.categories.firstIndex(where: {$0.id == category.id}) {
                            categories_obs.categories[index].image_url = result
                            categories_obs.objectWillChange.send()
                        }
                    })
                }
            }
        }.background(Color(red: 152/255, green: 152/255, blue: 152/255))
    }
}

func fetch_first_image_for_category(id: String, completion: @escaping (URL) -> Void) {
    let paid_url = URL(string: "http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/sf=143441/genre=\(id)/xml")!
    let paid_parser = FeedParser(URL: paid_url)
    paid_parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
        DispatchQueue.main.async {
            switch result {
            case .success(let feed):
                let first_entry = feed.atomFeed?.entries?.first
                fetch_application_data_atom(first_entry ?? AtomFeedEntry(), completion: { result in
                    DispatchQueue.main.async {
                        completion(result.artworkUrl512)
                    }
                })
            case .failure(let error):
                print(error)
                completion(URL(string:"google.com")!)
            }
        }
    }
}

struct category_destination: View {
    @State var top_free_applications = [Application_Data.Results]() //<-
    @State var top_paid_applications = [Application_Data.Results]()
    @State var new_applications = [Application_Data.Results]()
    @State var selected_segment_25: Int = 0
    @Binding var selected_category: app_category_datetype
    @Binding var categories_current_view: String
    @Binding var categories_selected_application: Application_Data.Results?
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing:0) {
                ZStack {
                    LinearGradient([Color(red: 192/255, green: 201/255, blue: 207/255), Color(red: 171/255, green: 183/255, blue: 191/255)], from: .top, to: .bottom).innerShadowBottom(color: Color.white.opacity(0.26), radius: 0.025).frame(width: geometry.size.width, height: 45)
                    tri_segmented_control_gray(selected: $selected_segment_25, first_text: "Paid", second_text: "Free", third_text: "Release Date", should_animate: false).frame(width: geometry.size.width-24, height: 30)
                }
                ScrollView(showsIndicators: true) {
                    if selected_segment_25 == 0 {
                        LazyVStack {
                            if top_paid_applications.isEmpty {
                                Spacer().frame(height:geometry.size.height)
                            } else {
                            ForEach(top_paid_applications, id:\.trackID) { application in
                                Button(action:{categories_selected_application = application;forward_or_backward = false; withAnimation(.linear(duration: 0.28)) {categories_current_view = "Destination"}}) {
                                    VStack(spacing: 0) {
                                        Spacer()
                                        HStack {
                                            WebImage(url: application.artworkUrl512).resizable().placeholder {
                                                Rectangle().foregroundColor(.gray)
                                            }.frame(width:60, height: 60).cornerRadius(60*90/512).padding(.leading, 12).shadow(color: Color.black.opacity(0.55), radius: 0.85, x: 0, y: 1.75)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(application.artistName ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                Text("\(Int((top_paid_applications.firstIndex(where: {$0.id == application.id}) ?? 0) + 1)). \(application.trackName ?? "---")").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                HStack(spacing: 2) {
                                                    ForEach(0..<Int(application.averageUserRating)) { _ in
                                                        ZStack {
                                                            Image("UserRatingBorderedStarsForeground")
                                                        }
                                                    }.offset(y:4)
                                                    ForEach(0..<(5-Int(application.averageUserRating) < 0 ? 0 : 5-Int(application.averageUserRating))) { _ in
                                                        ZStack {
                                                            Image("UserRatingBorderedStarsBackground")
                                                        }
                                                    }.offset(y:4)
                                                    Spacer().frame(width: 2)
                                                    Text("\(String(application.userRatingCount).filter("0123456789.".contains)) Ratings").font(.custom("Helvetica Neue Regular", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                }
                                            }
                                            Spacer()
                                            HStack(spacing: 6) { //Nest in another HStack for variable spacing
                                                Image("UniversalGlyph").opacity(application.features.contains("iosUniversal") ? 1 : 0).offset(y:1)
                                                Text(application.formattedPrice ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 12)).textCase(.uppercase).foregroundColor(Color(red: 74/255, green: 74/255, blue: 74/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                Image("UITableNext")
                                            }.padding(.trailing, 12)
                                        }
                                        Spacer()
                                        Rectangle().fill((top_paid_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 134/255, green: 134/255, blue: 137/255) : Color(red: 152/255, green: 152/255, blue: 155/255)).frame(height:1)
                                        Rectangle().fill((top_paid_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 189/255, green: 189/255, blue: 191/255) : Color(red: 172/255, green: 172/255, blue: 175/255)).frame(height:1)
                                    }.background((top_paid_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 152/255, green: 152/255, blue: 152/255) : Color(red: 173/255, green: 173/255, blue: 176/255))
                                }.frame(height: 80)
                            }
                        }
                        Spacer().frame(height: 20)
                        Text("Apple ID: OldOS@mac.com").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9).frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 226/255, green: 225/255, blue: 225/255), Color(red: 185/255, green: 185/255, blue: 185/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0.5).cornerRadius(9).strokeRoundedRectangle(9, Color(red: 133/255, green: 133/255, blue: 135/255), lineWidth: 0.5)
                        Spacer().frame(height: 30)
                        Text("iTunes Store Terms and Conditions...").multilineTextAlignment(.center).foregroundColor(Color(red: 40/255, green: 50/255, blue: 56/255)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).shadow(color: Color.white.opacity(0.7), radius: 0, x: 0.0, y: 0.9).padding(.bottom, 30)
                        } } else if selected_segment_25 == 1 {
                        LazyVStack {
                            if top_free_applications.isEmpty {
                                Spacer().frame(height:geometry.size.height)
                            } else {
                            ForEach(top_free_applications, id:\.trackID) { application in
                                Button(action:{categories_selected_application = application;forward_or_backward = false; withAnimation(.linear(duration: 0.28)) {categories_current_view = "Destination"}}) {
                                    VStack(spacing: 0) {
                                        Spacer()
                                        HStack {
                                            WebImage(url: application.artworkUrl512).resizable().placeholder {
                                                Rectangle().foregroundColor(.gray)
                                            }.frame(width:60, height: 60).cornerRadius(60*90/512).padding(.leading, 12).shadow(color: Color.black.opacity(0.55), radius: 0.85, x: 0, y: 1.75)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(application.artistName ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                Text("\(Int((top_free_applications.firstIndex(where: {$0.id == application.id}) ?? 0) + 1)). \(application.trackName ?? "---")").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                HStack(spacing: 2) {
                                                    ForEach(0..<Int(application.averageUserRating)) { _ in
                                                        ZStack {
                                                            Image("UserRatingBorderedStarsForeground")
                                                        }
                                                    }.offset(y:4)
                                                    ForEach(0..<(5-Int(application.averageUserRating) < 0 ? 0 : 5-Int(application.averageUserRating))) { _ in
                                                        ZStack {
                                                            Image("UserRatingBorderedStarsBackground")
                                                        }
                                                    }.offset(y:4)
                                                    Spacer().frame(width: 2)
                                                    Text("\(String(application.userRatingCount).filter("0123456789.".contains)) Ratings").font(.custom("Helvetica Neue Regular", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                }
                                            }
                                            Spacer()
                                            HStack(spacing: 6) { //Nest in another HStack for variable spacing
                                                Image("UniversalGlyph").opacity(application.features.contains("iosUniversal") ? 1 : 0).offset(y:1)
                                                Text(application.formattedPrice ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 12)).textCase(.uppercase).foregroundColor(Color(red: 74/255, green: 74/255, blue: 74/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                Image("UITableNext")
                                            }.padding(.trailing, 12)
                                        }
                                        Spacer()
                                        Rectangle().fill((top_free_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 134/255, green: 134/255, blue: 137/255) : Color(red: 152/255, green: 152/255, blue: 155/255)).frame(height:1)
                                        Rectangle().fill((top_free_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 189/255, green: 189/255, blue: 191/255) : Color(red: 172/255, green: 172/255, blue: 175/255)).frame(height:1)
                                    }.background((top_free_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 152/255, green: 152/255, blue: 152/255) : Color(red: 173/255, green: 173/255, blue: 176/255))
                                }.frame(height: 80)
                            }
                        }
                        Spacer().frame(height: 20)
                        Text("Apple ID: OldOS@mac.com").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9).frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 226/255, green: 225/255, blue: 225/255), Color(red: 185/255, green: 185/255, blue: 185/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0.5).cornerRadius(9).strokeRoundedRectangle(9, Color(red: 133/255, green: 133/255, blue: 135/255), lineWidth: 0.5)
                        Spacer().frame(height: 30)
                        Text("iTunes Store Terms and Conditions...").multilineTextAlignment(.center).foregroundColor(Color(red: 40/255, green: 50/255, blue: 56/255)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).shadow(color: Color.white.opacity(0.7), radius: 0, x: 0.0, y: 0.9).padding(.bottom, 30)
                        } }else if selected_segment_25 == 2 {
                        LazyVStack {
                            if new_applications.isEmpty {
                                Spacer().frame(height:geometry.size.height)
                            } else {
                            ForEach(new_applications, id:\.trackID) { application in
                                Button(action:{categories_selected_application = application;forward_or_backward = false; withAnimation(.linear(duration: 0.28)) {categories_current_view = "Destination"}}) {
                                    VStack(spacing: 0) {
                                        Spacer()
                                        HStack {
                                            WebImage(url: application.artworkUrl512).resizable().placeholder {
                                                Rectangle().foregroundColor(.gray)
                                            }.frame(width:60, height: 60).cornerRadius(60*90/512).padding(.leading, 12).shadow(color: Color.black.opacity(0.55), radius: 0.85, x: 0, y: 1.75)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(application.artistName ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                Text("\(Int((new_applications.firstIndex(where: {$0.id == application.id}) ?? 0) + 1)). \(application.trackName ?? "---")").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                HStack(spacing: 2) {
                                                    ForEach(0..<Int(application.averageUserRating)) { _ in
                                                        ZStack {
                                                            Image("UserRatingBorderedStarsForeground")
                                                        }
                                                    }.offset(y:4)
                                                    ForEach(0..<(5-Int(application.averageUserRating) < 0 ? 0 : 5-Int(application.averageUserRating))) { _ in
                                                        ZStack {
                                                            Image("UserRatingBorderedStarsBackground")
                                                        }
                                                    }.offset(y:4)
                                                    Spacer().frame(width: 2)
                                                    Text("\(String(application.userRatingCount).filter("0123456789.".contains)) Ratings").font(.custom("Helvetica Neue Regular", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                }
                                            }
                                            Spacer()
                                            HStack(spacing: 6) { //Nest in another HStack for variable spacing
                                                Image("UniversalGlyph").opacity(application.features.contains("iosUniversal") ? 1 : 0).offset(y:1)
                                                Text(application.formattedPrice ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 12)).textCase(.uppercase).foregroundColor(Color(red: 74/255, green: 74/255, blue: 74/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                Image("UITableNext")
                                            }.padding(.trailing, 12)
                                        }
                                        Spacer()
                                        Rectangle().fill((new_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 134/255, green: 134/255, blue: 137/255) : Color(red: 152/255, green: 152/255, blue: 155/255)).frame(height:1)
                                        Rectangle().fill((new_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 189/255, green: 189/255, blue: 191/255) : Color(red: 172/255, green: 172/255, blue: 175/255)).frame(height:1)
                                    }.background((new_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 152/255, green: 152/255, blue: 152/255) : Color(red: 173/255, green: 173/255, blue: 176/255))
                                }.frame(height: 80)
                            }
                        }
                        Spacer().frame(height: 20)
                        Text("Apple ID: OldOS@mac.com").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9).frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 226/255, green: 225/255, blue: 225/255), Color(red: 185/255, green: 185/255, blue: 185/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0.5).cornerRadius(9).strokeRoundedRectangle(9, Color(red: 133/255, green: 133/255, blue: 135/255), lineWidth: 0.5)
                        Spacer().frame(height: 30)
                        Text("iTunes Store Terms and Conditions...").multilineTextAlignment(.center).foregroundColor(Color(red: 40/255, green: 50/255, blue: 56/255)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).shadow(color: Color.white.opacity(0.7), radius: 0, x: 0.0, y: 0.9).padding(.bottom, 30)
                        }
                    }
                }
            }
        }.background(Color(red: 152/255, green: 152/255, blue: 152/255)).onAppear() {
            DispatchQueue.main.async {
                //Top Free
                let id = selected_category.genre_id
                let free_url = URL(string: "http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/topfreeapplications/sf=143441/limit=25/genre=\(id)/xml")!
                let free_parser = FeedParser(URL: free_url)
                free_parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let feed):
                            let rssFeed = feed.atomFeed
                            for item in rssFeed?.entries ?? [] {
                                fetch_application_data_atom(item, completion: { result in
                                    DispatchQueue.main.async {
                                        
                                        self.top_free_applications.append(result)
                                    }
                                })
                            }
                        case .failure(let error):
                            print(error)
                        }
                    }
                }
                //Top Paid
                let paid_url = URL(string: "http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/sf=143441/limit=25/genre=\(id)/xml")!
                let paid_parser = FeedParser(URL: paid_url)
                paid_parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let feed):
                            let rssFeed = feed.atomFeed
                            for item in rssFeed?.entries ?? [] {
                                fetch_application_data_atom(item, completion: { result in
                                    DispatchQueue.main.async {
                                        
                                        self.top_paid_applications.append(result)
                                    }
                                })
                            }
                        case .failure(let error):
                            print(error)
                            print("were here bad")
                        }
                    }
                }
                //Most Recent
                let new_url = URL(string: "http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/newapplications/sf=143441/limit=25/genre=\(id)/xml")!
                let new_parser = FeedParser(URL: new_url)
                new_parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let feed):
                            let rssFeed = feed.atomFeed
                            for item in rssFeed?.entries ?? [] {
                                fetch_application_data_atom(item, completion: { result in
                                    DispatchQueue.main.async {
                                        
                                        self.new_applications.append(result)
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
}

//** MARK: App Store Top 25

struct top_25_applications: View {
    @StateObject var top_paid_and_free_observer: TopPaidAndFreeApplicationsObserver
    @Binding var selected_segment_25: Int
    @Binding var top25_show_application: Bool
    @Binding var top25_selected_application: Application_Data.Results?
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing:0) {
                ScrollView(showsIndicators: true) {
                    if selected_segment_25 == 0 {
                        LazyVStack {
                            if top_paid_and_free_observer.top_paid_applications.isEmpty {
                                Spacer().frame(height:geometry.size.height)
                            } else {
                            ForEach(top_paid_and_free_observer.top_paid_applications, id:\.trackID) { application in
                                Button(action:{top25_selected_application = application;forward_or_backward = false; withAnimation(.linear(duration: 0.28)) {top25_show_application = true}}) {
                                    VStack(spacing: 0) {
                                        Spacer()
                                        HStack {
                                            WebImage(url: application.artworkUrl512).resizable().placeholder {
                                                Rectangle().foregroundColor(.gray)
                                            }.frame(width:60, height: 60).cornerRadius(60*90/512).padding(.leading, 12).shadow(color: Color.black.opacity(0.55), radius: 0.85, x: 0, y: 1.75)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(application.artistName ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                Text("\(Int((top_paid_and_free_observer.top_paid_applications.firstIndex(where: {$0.id == application.id}) ?? 0) + 1)). \(application.trackName ?? "---")").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                HStack(spacing: 2) {
                                                    ForEach(0..<Int(application.averageUserRating)) { _ in
                                                        ZStack {
                                                            Image("UserRatingBorderedStarsForeground")
                                                        }
                                                    }.offset(y:4)
                                                    ForEach(0..<(5-Int(application.averageUserRating) < 0 ? 0 : 5-Int(application.averageUserRating))) { _ in
                                                        ZStack {
                                                            Image("UserRatingBorderedStarsBackground")
                                                        }
                                                    }.offset(y:4)
                                                    Spacer().frame(width: 2)
                                                    Text("\(String(application.userRatingCount).filter("0123456789.".contains)) Ratings").font(.custom("Helvetica Neue Regular", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                }
                                            }
                                            Spacer()
                                            HStack(spacing: 6) { //Nest in another HStack for variable spacing
                                                Image("UniversalGlyph").opacity(application.features.contains("iosUniversal") ? 1 : 0).offset(y:1)
                                                Text(application.formattedPrice ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 12)).textCase(.uppercase).foregroundColor(Color(red: 74/255, green: 74/255, blue: 74/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                Image("UITableNext")
                                            }.padding(.trailing, 12)
                                        }
                                        Spacer()
                                        Rectangle().fill((top_paid_and_free_observer.top_paid_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 134/255, green: 134/255, blue: 137/255) : Color(red: 152/255, green: 152/255, blue: 155/255)).frame(height:1)
                                        Rectangle().fill((top_paid_and_free_observer.top_paid_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 189/255, green: 189/255, blue: 191/255) : Color(red: 172/255, green: 172/255, blue: 175/255)).frame(height:1)
                                    }.background((top_paid_and_free_observer.top_paid_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 152/255, green: 152/255, blue: 152/255) : Color(red: 173/255, green: 173/255, blue: 176/255))
                                }.frame(height: 80)
                            }
                        }
                        Spacer().frame(height: 20)
                        Text("Apple ID: OldOS@mac.com").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9).frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 226/255, green: 225/255, blue: 225/255), Color(red: 185/255, green: 185/255, blue: 185/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0.5).cornerRadius(9).strokeRoundedRectangle(9, Color(red: 133/255, green: 133/255, blue: 135/255), lineWidth: 0.5)
                        Spacer().frame(height: 30)
                        Text("iTunes Store Terms and Conditions...").multilineTextAlignment(.center).foregroundColor(Color(red: 40/255, green: 50/255, blue: 56/255)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).shadow(color: Color.white.opacity(0.7), radius: 0, x: 0.0, y: 0.9).padding(.bottom, 30)
                        } } else if selected_segment_25 == 1 {
                        LazyVStack {
                            if top_paid_and_free_observer.top_free_applications.isEmpty {
                                Spacer().frame(height:geometry.size.height)
                            } else {
                            ForEach(top_paid_and_free_observer.top_free_applications, id:\.trackID) { application in
                                Button(action:{top25_selected_application = application;forward_or_backward = false; withAnimation(.linear(duration: 0.28)) {top25_show_application = true}}) {
                                    VStack(spacing: 0) {
                                        Spacer()
                                        HStack {
                                            WebImage(url: application.artworkUrl512).resizable().placeholder {
                                                Rectangle().foregroundColor(.gray)
                                            }.frame(width:60, height: 60).cornerRadius(60*90/512).padding(.leading, 12).shadow(color: Color.black.opacity(0.55), radius: 0.85, x: 0, y: 1.75)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(application.artistName ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                Text("\(Int((top_paid_and_free_observer.top_free_applications.firstIndex(where: {$0.id == application.id}) ?? 0) + 1)). \(application.trackName ?? "---")").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                HStack(spacing: 2) {
                                                    ForEach(0..<Int(application.averageUserRating)) { _ in
                                                        ZStack {
                                                            Image("UserRatingBorderedStarsForeground")
                                                        }
                                                    }.offset(y:4)
                                                    ForEach(0..<(5-Int(application.averageUserRating) < 0 ? 0 : 5-Int(application.averageUserRating))) { _ in
                                                        ZStack {
                                                            Image("UserRatingBorderedStarsBackground")
                                                        }
                                                    }.offset(y:4)
                                                    Spacer().frame(width: 2)
                                                    Text("\(String(application.userRatingCount).filter("0123456789.".contains)) Ratings").font(.custom("Helvetica Neue Regular", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                }
                                            }
                                            Spacer()
                                            HStack(spacing: 6) { //Nest in another HStack for variable spacing
                                                Image("UniversalGlyph").opacity(application.features.contains("iosUniversal") ? 1 : 0).offset(y:1)
                                                Text(application.formattedPrice ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 12)).textCase(.uppercase).foregroundColor(Color(red: 74/255, green: 74/255, blue: 74/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                Image("UITableNext")
                                            }.padding(.trailing, 12)
                                        }
                                        Spacer()
                                        Rectangle().fill((top_paid_and_free_observer.top_free_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 134/255, green: 134/255, blue: 137/255) : Color(red: 152/255, green: 152/255, blue: 155/255)).frame(height:1)
                                        Rectangle().fill((top_paid_and_free_observer.top_free_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 189/255, green: 189/255, blue: 191/255) : Color(red: 172/255, green: 172/255, blue: 175/255)).frame(height:1)
                                    }.background((top_paid_and_free_observer.top_free_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 152/255, green: 152/255, blue: 152/255) : Color(red: 173/255, green: 173/255, blue: 176/255))
                                }.frame(height: 80)
                            }
                        }
                        Spacer().frame(height: 20)
                        Text("Apple ID: OldOS@mac.com").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9).frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 226/255, green: 225/255, blue: 225/255), Color(red: 185/255, green: 185/255, blue: 185/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0.5).cornerRadius(9).strokeRoundedRectangle(9, Color(red: 133/255, green: 133/255, blue: 135/255), lineWidth: 0.5)
                        Spacer().frame(height: 30)
                        Text("iTunes Store Terms and Conditions...").multilineTextAlignment(.center).foregroundColor(Color(red: 40/255, green: 50/255, blue: 56/255)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).shadow(color: Color.white.opacity(0.7), radius: 0, x: 0.0, y: 0.9).padding(.bottom, 30)
                        } } else if selected_segment_25 == 2 {
                        LazyVStack {
                            if top_paid_and_free_observer.top_grossing_applications.isEmpty {
                                Spacer().frame(height:geometry.size.height)
                            } else {
                            ForEach(top_paid_and_free_observer.top_grossing_applications, id:\.trackID) { application in
                                Button(action:{top25_selected_application = application;forward_or_backward = false; withAnimation(.linear(duration: 0.28)) {top25_show_application = true}}) {
                                    VStack(spacing: 0) {
                                        Spacer()
                                        HStack {
                                            WebImage(url: application.artworkUrl512).resizable().placeholder {
                                                Rectangle().foregroundColor(.gray)
                                            }.frame(width:60, height: 60).cornerRadius(60*90/512).padding(.leading, 12).shadow(color: Color.black.opacity(0.55), radius: 0.85, x: 0, y: 1.75)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(application.artistName ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                Text("\(Int((top_paid_and_free_observer.top_grossing_applications.firstIndex(where: {$0.id == application.id}) ?? 0) + 1)). \(application.trackName ?? "---")").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                HStack(spacing: 2) {
                                                    ForEach(0..<Int(application.averageUserRating)) { _ in
                                                        ZStack {
                                                            Image("UserRatingBorderedStarsForeground")
                                                        }
                                                    }.offset(y:4)
                                                    ForEach(0..<(5-Int(application.averageUserRating) < 0 ? 0 : 5-Int(application.averageUserRating))) { _ in
                                                        ZStack {
                                                            Image("UserRatingBorderedStarsBackground")
                                                        }
                                                    }.offset(y:4)
                                                    Spacer().frame(width: 2)
                                                    Text("\(String(application.userRatingCount).filter("0123456789.".contains)) Ratings").font(.custom("Helvetica Neue Regular", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                }
                                            }
                                            Spacer()
                                            HStack(spacing: 6) { //Nest in another HStack for variable spacing
                                                Image("UniversalGlyph").opacity(application.features.contains("iosUniversal") ? 1 : 0).offset(y:1)
                                                Text(application.formattedPrice ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 12)).textCase(.uppercase).foregroundColor(Color(red: 74/255, green: 74/255, blue: 74/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                Image("UITableNext")
                                            }.padding(.trailing, 12)
                                        }
                                        Spacer()
                                        Rectangle().fill((top_paid_and_free_observer.top_grossing_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 134/255, green: 134/255, blue: 137/255) : Color(red: 152/255, green: 152/255, blue: 155/255)).frame(height:1)
                                        Rectangle().fill((top_paid_and_free_observer.top_grossing_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 189/255, green: 189/255, blue: 191/255) : Color(red: 172/255, green: 172/255, blue: 175/255)).frame(height:1)
                                    }.background((top_paid_and_free_observer.top_grossing_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 152/255, green: 152/255, blue: 152/255) : Color(red: 173/255, green: 173/255, blue: 176/255))
                                }.frame(height: 80)
                            }
                        }
                        Spacer().frame(height: 20)
                        Text("Apple ID: OldOS@mac.com").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9).frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 226/255, green: 225/255, blue: 225/255), Color(red: 185/255, green: 185/255, blue: 185/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0.5).cornerRadius(9).strokeRoundedRectangle(9, Color(red: 133/255, green: 133/255, blue: 135/255), lineWidth: 0.5)
                        Spacer().frame(height: 30)
                        Text("iTunes Store Terms and Conditions...").multilineTextAlignment(.center).foregroundColor(Color(red: 40/255, green: 50/255, blue: 56/255)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).shadow(color: Color.white.opacity(0.7), radius: 0, x: 0.0, y: 0.9).padding(.bottom, 30)
                        } }
                }
            }
        }.background(Color(red: 152/255, green: 152/255, blue: 152/255))
    }
}

//** MARK: App Destination

struct app_destination: View {
    @Binding var featured_selected_application: Application_Data.Results?
    @StateObject var page: Page = .first()
    func format_iso_date(_ date: String) -> String {
        let iso_formatter = ISO8601DateFormatter()
        let iso_date = iso_formatter.date(from: date) ?? Date()
        let date_formater = DateFormatter()
        date_formater.dateFormat = "MMM dd, yyyy"
        return date_formater.string(from: iso_date)
    }
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing:0) {
                ScrollView(showsIndicators: true) {
                    LazyVStack {
                        ZStack(alignment: .top) {
                            Rectangle().fill(LinearGradient([(color: Color(red: 152/255, green: 152/255, blue: 152/255), location: 0), (color: Color(red: 200/255, green: 202/255, blue: 204/255), location: 0.70)], from: .top, to: .bottom)).frame(width: geometry.size.width, height: 80)
                            HStack(alignment: .top) {
                                ZStack {
                                    WebImage(url: featured_selected_application?.artworkUrl512).resizable().placeholder {
                                        Rectangle().foregroundColor(.gray)
                                    }.frame(width:60, height: 60).cornerRadius(60*90/512).clipped().shadow(color: Color.black.opacity(0.55), radius: 0.65, x: 0, y: 0.75).mask(LinearGradient([(color: Color.clear, location: 0), (color: Color.clear, location: 0.78), (color: Color.white.opacity(0.4), location: 1)], from: .top, to: .bottom)).rotationEffect(.degrees(-180)).offset(y:61).rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0)).padding(.leading, 12)//.opacity(0.15)
                                    WebImage(url: featured_selected_application?.artworkUrl512).resizable().placeholder {
                                        Rectangle().foregroundColor(.gray)
                                    }.frame(width:60, height: 60).cornerRadius(60*90/512).padding(.leading, 12).shadow(color: Color.black.opacity(0.55), radius: 0.85, x: 0, y: 1.75)
                                }.frame(height:90).clipped().offset(y:-1)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(featured_selected_application?.trackName ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 20)).foregroundColor(.black).lineLimit(0).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(featured_selected_application?.artistName ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(0).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                            HStack(spacing: 2) {
                                                ForEach(0..<Int(featured_selected_application?.averageUserRating ?? 4)) { _ in
                                                    ZStack {
                                                        Image("UserRatingBorderedStarsForeground")
                                                    }
                                                }.offset(y:4)
                                                ForEach(0..<(5-Int(featured_selected_application?.averageUserRating ?? 4) < 0 ? 0 : 5-Int(featured_selected_application?.averageUserRating ?? 0))) { _ in
                                                    ZStack {
                                                        Image("UserRatingBorderedStarsBackground")
                                                    }
                                                }.offset(y:4)
                                                Spacer().frame(width: 2)
                                                Text("\(String(featured_selected_application?.userRatingCount ?? 0).filter("0123456789.".contains)) Ratings").font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(1)
                                            }
                                        }
                                        Spacer()
                                        tool_bar_rectangle_button_custom_radius(action: {
                                            guard let id = featured_selected_application?.id else {return}
                                            if let url = URL(string: "itms-apps://apple.com/app/id\(id)") {
                                                UIApplication.shared.open(url)
                                            }
                                        }, button_type: .app_store, content: "  \(featured_selected_application?.formattedPrice ?? "")  ", height_modifier: -5, radius: 3.5).textCase(.uppercase).padding(.trailing, 4)
                                    }
                                }.frame(height:90)
                                Spacer()
                            }
                        }
                        Spacer().frame(height: 10)
                        Text( featured_selected_application?.description ?? "").font(.custom("Helvetica Neue Regular", fixedSize: 12)).frame(width: geometry.size.width-24)
                        Pager(page: page, data: featured_selected_application?.screenshotUrls ?? [], id: \.self) { url in
                            WebImage(url: url).resizable().scaledToFit().border(Color.white.opacity(0.85), width: 1).shadow(color: Color.black.opacity(0.4), radius: 2.5, x: 0, y: 1).padding(.bottom, 10)
                        }.multiplePagination() .preferredItemSize(CGSize(width: geometry.size.width-80, height: geometry.size.height - 60)) .itemSpacing(2.5).frame(width: geometry.size.width, height:geometry.size.height).background(Color(red: 143/255, green: 145/255, blue: 146/255).overlay(LinearGradient([(color: Color(red: 0, green: 0, blue: 0).opacity(0.23), location: 0), (color: Color(red: 0, green: 0, blue: 0).opacity(0.0), location: 0.015), (color: Color(red: 0, green: 0, blue: 0).opacity(0.0), location: 0.985), (color: Color(red: 0, green: 0, blue: 0).opacity(0.23), location: 1)], from: .top, to: .bottom))).overlay(VStack {
                            Spacer()
                            HStack(spacing: 10) {
                                Spacer()
                                ForEach(featured_selected_application?.screenshotUrls ?? [], id: \.self) { index in
                                    Circle().fill(Color.white).frame(width:7.5, height:7.5).opacity((featured_selected_application?.screenshotUrls ?? []).firstIndex(of: index) == page.index ? 1 : 0.25)
                                }
                                Spacer()
                            }.animationsDisabled().padding(.bottom, 17.5)
                        })
                        HStack {
                            Text("\(String(featured_selected_application?.userRatingCount ?? 0).filter("0123456789.".contains)) Ratings").font(.custom("Helvetica Neue Bold", fixedSize: 15)).foregroundColor(.black).lineLimit(1).padding(.leading, 12)
                            HStack(spacing: 2) {
                                ForEach(0..<Int(featured_selected_application?.averageUserRating ?? 4)) { _ in
                                    ZStack {
                                        Image("UserRatingBorderedStarsForeground")
                                    }
                                }.offset(y:4)
                                ForEach(0..<(5-Int(featured_selected_application?.averageUserRating ?? 4) < 0 ? 0 : 5-Int(featured_selected_application?.averageUserRating ?? 0))) { _ in
                                    ZStack {
                                        Image("UserRatingBorderedStarsBackground")
                                    }
                                }.offset(y:4)
                            }
                            Spacer()
                            Image("UITableNext").padding(.trailing, 12)
                        }.frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 252/255, green: 253/255, blue: 253/255), Color(red: 232/255, green: 235/255, blue: 241/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0).cornerRadius(9).strokeRoundedRectangle(9, Color.white, lineWidth: 0.5)
                        HStack(spacing: 0) {
                            ZStack {
                                Text("Tell a Friend").font(.custom("Helvetica Neue Bold", fixedSize: 15))
                            }.frame(width: geometry.size.width/2 - 18, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 252/255, green: 253/255, blue: 253/255), Color(red: 232/255, green: 235/255, blue: 241/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0).cornerRadius(9).strokeRoundedRectangle(9, Color.white, lineWidth: 0.5)
                            Spacer()
                            ZStack {
                                Text("App Support").font(.custom("Helvetica Neue Bold", fixedSize: 15))
                            }.frame(width: geometry.size.width/2 - 18, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 252/255, green: 253/255, blue: 253/255), Color(red: 232/255, green: 235/255, blue: 241/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0).cornerRadius(9).strokeRoundedRectangle(9, Color.white, lineWidth: 0.5)
                        }.padding([.leading, .trailing], 12)
                        Spacer().frame(height: 20)
                        HStack(alignment: .top, spacing: 10) {
                            HStack(alignment: .top, spacing: 0) {
                                Spacer()
                                Text("Company").multilineTextAlignment(.trailing).font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(Color(red: 100/255, green: 101/255, blue: 102/255))
                            }.frame(width: geometry.size.width/3)
                            Text("\(featured_selected_application?.sellerName ?? "")\n\(featured_selected_application?.sellerURL?.relativeString ?? "")").font(.custom("Helvetica Neue Regular", fixedSize: 12)).foregroundColor(.black)
                            Spacer()
                        }
                        VStack {
                            Spacer().frame(height: 10)
                            HStack(alignment: .top) {
                                HStack(alignment: .top, spacing: 0) {
                                    Spacer()
                                    Text("Updated").multilineTextAlignment(.trailing).font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(Color(red: 100/255, green: 101/255, blue: 102/255))
                                }.frame(width: geometry.size.width/3)
                                Text("\(format_iso_date(featured_selected_application?.currentVersionReleaseDate ?? ""))").font(.custom("Helvetica Neue Regular", fixedSize: 12)).foregroundColor(.black)//fix to formated current release version
                                Spacer()
                            }
                            HStack(alignment: .top) {
                                HStack(alignment: .top, spacing: 0) {
                                    Spacer()
                                    Text("Version").multilineTextAlignment(.trailing).font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(Color(red: 100/255, green: 101/255, blue: 102/255))
                                }.frame(width: geometry.size.width/3)
                                Text("\(featured_selected_application?.version ?? "")").font(.custom("Helvetica Neue Regular", fixedSize: 12)).foregroundColor(.black)
                                Spacer()
                            }
                            HStack(alignment: .top) {
                                HStack(alignment: .top, spacing: 0) {
                                    Spacer()
                                    Text("Size").multilineTextAlignment(.trailing).font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(Color(red: 100/255, green: 101/255, blue: 102/255))
                                }.frame(width: geometry.size.width/3)
                                Text("\(String(format:"%.1f", Double((Double(featured_selected_application?.fileSizeBytes ?? "0") ?? 0)/1000000))) MB").font(.custom("Helvetica Neue Regular", fixedSize: 12)).foregroundColor(.black)
                                Spacer()
                            }
                            Spacer().frame(height: 10)
                            HStack(alignment: .top) {
                                HStack(alignment: .top, spacing: 0) {
                                    Spacer()
                                    Text("Rating").multilineTextAlignment(.trailing).font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(Color(red: 100/255, green: 101/255, blue: 102/255))
                                }.frame(width: geometry.size.width/3)
                                VStack(alignment: .leading) {
                                    Text((featured_selected_application?.advisories ?? [] == []) ? "\(featured_selected_application?.contentAdvisoryRating ?? "")" : "Rated \(featured_selected_application?.contentAdvisoryRating ?? "") for the following:").font(.custom("Helvetica Neue Regular", fixedSize: 12)).foregroundColor(.black)
                                    ForEach(featured_selected_application?.advisories ?? [], id: \.self) { advisory in
                                        Text("\(advisory ?? "")").font(.custom("Helvetica Neue Regular", fixedSize: 12)).foregroundColor(.black).fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                Spacer()
                            }.padding(.bottom, 5)
                        }
                    }.background(Color(red: 200/255, green: 202/255, blue: 204/255))
                }
            }
        }.background(LinearGradient([(color: Color(red: 152/255, green: 152/255, blue: 152/255), location: 0), (color: Color(red: 152/255, green: 152/255, blue: 152/255), location: 0.5), (color: Color(red: 200/255, green: 202/255, blue: 204/255), location: 0.5), (color: Color(red: 200/255, green: 202/255, blue: 204/255), location: 1)], from: .top, to: .bottom))
    }
}

//** MARK: App Store Featured

struct featured_applications: View {
    @StateObject var featured_observer: FeaturedApplicationsObserver
    @Binding var selected_segment: Int
    @Binding var featured_show_application: Bool
    @Binding var featured_selected_application: Application_Data.Results?
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing:0) {
                ScrollView(showsIndicators: true) {
                    if selected_segment == 0 {
                        LazyVStack {
                            if featured_observer.featured_applications.isEmpty {
                                Spacer().frame(height:geometry.size.height)
                            } else {
                            ForEach(featured_observer.featured_applications, id:\.trackID) { application in
                                Button(action:{featured_selected_application = application;forward_or_backward = false; withAnimation(.linear(duration: 0.28)) {featured_show_application = true}}) {
                                    VStack(spacing: 0) {
                                        Spacer()
                                        HStack {
                                            WebImage(url: application.artworkUrl512).resizable().placeholder {
                                                Rectangle().foregroundColor(.gray)
                                            }.frame(width:60, height: 60).cornerRadius(60*90/512).padding(.leading, 12).shadow(color: Color.black.opacity(0.55), radius: 0.85, x: 0, y: 1.75)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(application.artistName ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                Text(application.trackName ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                HStack(spacing: 2) {
                                                    ForEach(0..<Int(application.averageUserRating)) { _ in
                                                        ZStack {
                                                            Image("UserRatingBorderedStarsForeground")
                                                        }
                                                    }.offset(y:4)
                                                    ForEach(0..<(5-Int(application.averageUserRating) < 0 ? 0 : 5-Int(application.averageUserRating))) { _ in
                                                        ZStack {
                                                            Image("UserRatingBorderedStarsBackground")
                                                        }
                                                    }.offset(y:4)
                                                    Spacer().frame(width: 2)
                                                    Text("\(String(application.userRatingCount).filter("0123456789.".contains)) Ratings").font(.custom("Helvetica Neue Regular", fixedSize: 12)).foregroundColor(Color(red: 58/255, green: 58/255, blue: 58/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                }
                                            }
                                            Spacer()
                                            HStack(spacing: 6) { //Nest in another HStack for variable spacing
                                                Image("UniversalGlyph").opacity(application.features.contains("iosUniversal") ? 1 : 0).offset(y:1)
                                                Text(application.formattedPrice ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 12)).textCase(.uppercase).foregroundColor(Color(red: 74/255, green: 74/255, blue: 74/255)).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                                                Image("UITableNext")
                                            }.padding(.trailing, 12)
                                        }
                                        Spacer()
                                        Rectangle().fill((featured_observer.featured_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 134/255, green: 134/255, blue: 137/255) : Color(red: 152/255, green: 152/255, blue: 155/255)).frame(height:1)
                                        Rectangle().fill((featured_observer.featured_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 189/255, green: 189/255, blue: 191/255) : Color(red: 172/255, green: 172/255, blue: 175/255)).frame(height:1)
                                    }.background((featured_observer.featured_applications.firstIndex(where: {$0.id == application.id}) ?? 0) % 2  == 0 ? Color(red: 152/255, green: 152/255, blue: 152/255) : Color(red: 173/255, green: 173/255, blue: 176/255))
                                }.frame(height: 80)
                            }
                        }
                        Spacer().frame(height: 20)
                        Text("Redeem").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9).frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 252/255, green: 253/255, blue: 253/255), Color(red: 232/255, green: 235/255, blue: 241/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0.5).cornerRadius(9).strokeRoundedRectangle(9, Color(red: 133/255, green: 133/255, blue: 135/255), lineWidth: 0.5)
                        Spacer().frame(height: 10)
                        Text("Apple ID: OldOS@mac.com").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.black).lineLimit(1).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9).frame(width: geometry.size.width - 24, height: 50).ps_innerShadow(.roundedRectangle(9, LinearGradient([Color(red: 252/255, green: 253/255, blue: 253/255), Color(red: 232/255, green: 235/255, blue: 241/255)], from: .top, to: .bottom)), radius:5/3, offset: CGPoint(0, 1/3), intensity: 0.5).cornerRadius(9).strokeRoundedRectangle(9, Color(red: 133/255, green: 133/255, blue: 135/255), lineWidth: 0.5)
                        Spacer().frame(height: 30)
                        Text("Apple Media Services Terms and\nConditions...").multilineTextAlignment(.center).foregroundColor(Color(red: 48/255, green: 57/255, blue: 70/255)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).shadow(color: Color.white.opacity(0.7), radius: 0, x: 0.0, y: 0.9).padding(.bottom, 30)
                        } } else {
                        VStack {
                            Spacer()
                            Image("geniusatom").resizable().scaledToFit().frame(width: 70)
                            Spacer().frame(height: 15)
                            Text("You do not currently have any\nrecommendations.").multilineTextAlignment(.center).font(.custom("Helvetica Neue Bold", fixedSize: 17)).foregroundColor(.black).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                            Spacer().frame(height: 25)
                            Text("To start seeing recommendations,\nteach Genius about your tastes by\ndownloading apps.").multilineTextAlignment(.center).font(.custom("Helvetica Neue Regular", fixedSize: 17)).foregroundColor(Color(red: 100/255, green: 101/255, blue: 102/255)).shadow(color: Color.white.opacity(0.4), radius: 0, x: 0.0, y: 0.9)
                            Spacer()
                        }.frame(width: geometry.size.width, height: geometry.size.height).background(LinearGradient(gradient: Gradient(stops: [.init(color: Color.white, location: 0), .init(color: Color(red: 200/255, green: 202/255, blue: 204/255), location: 1)]), startPoint: .top, endPoint: .bottom))
                    }
                }
            }
        }.background(Color(red: 152/255, green: 152/255, blue: 152/255))
    }
}

class TopPaidAndFreeApplicationsObserver: ObservableObject { //<-
    @Published var top_free_applications = [Application_Data.Results]() //<-
    @Published var top_paid_applications = [Application_Data.Results]()
    @Published var top_grossing_applications = [Application_Data.Results]()
    init() {
        parse_data()
    }
    func parse_data() {
        print("parsing data")
        //Top Free
        let free_url = URL(string: "https://rss.applemarketingtools.com/api/v2/us/apps/top-free/25/apps.rss")!
        let free_parser = FeedParser(URL: free_url)
        free_parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let feed):
                    let rssFeed = feed.rssFeed
                    for item in rssFeed?.items ?? [] {
                        fetch_application_data(item, completion: { result in
                            DispatchQueue.main.async {
                                
                                self.top_free_applications.append(result)
                            
                            }
                        })
                    }
                case .failure(let error):
                    print(error)
                    print("were here bad")
                }
            }
        }
        //Top Paid
        let paid_url = URL(string: "https://rss.applemarketingtools.com/api/v2/us/apps/top-paid/25/apps.rss")!
        let paid_parser = FeedParser(URL: paid_url)
        paid_parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let feed):
                    let rssFeed = feed.rssFeed
                    for item in rssFeed?.items ?? [] {
                        fetch_application_data(item, completion: { result in
                            DispatchQueue.main.async {
                                
                                self.top_paid_applications.append(result)
                            
                            }
                        })
                    }
                case .failure(let error):
                    print(error)
                    print("were here bad")
                }
            }
        }
        //Top Grossing
        let grossing_url = URL(string: "https://rss.applemarketingtools.com/api/v2/us/apps/top-grossing/25/apps.rss")!
        let grossing_parser = FeedParser(URL: grossing_url)
        grossing_parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let feed):
                    let rssFeed = feed.rssFeed
                    for item in rssFeed?.items ?? [] {
                        fetch_application_data(item, completion: { result in
                            DispatchQueue.main.async {
                                
                                self.top_grossing_applications.append(result)
                            
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


//Until the Apple RSS feed is back up and running, we will use a feed stored on the Internet Archive.
//EDIT as of 3/19 this is live again, who knows what the deal was, but keep an eye out for if it stops working.
class FeaturedApplicationsObserver: ObservableObject {
    @Published var featured_applications = [Application_Data.Results]()
    
    init() {
        parse_data()
    }
    func parse_data() {
        print("parsing data")
        let url = URL(string: "https://rss.applemarketingtools.com/api/v2/new-apps-we-love/25/apps.rss")! //If it continues to not work switch to 10
        let parser = FeedParser(URL: url)
        parser.parseAsync(queue: DispatchQueue.global(qos: .userInitiated)) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let feed):
                    let rssFeed = feed.rssFeed
                    for item in rssFeed?.items ?? [] {
                        fetch_application_data(item, completion: { result in
                            DispatchQueue.main.async {
                                
                                self.featured_applications.append(result)
                            
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
func fetch_application_data(_ application: RSSFeedItem, completion: @escaping (Application_Data.Results) -> Void) {
    //Our first step is to fetch the ID of the application, a trick we can do is to grab it from the URL...
    var id = ""
    if let id_range = application.link?.range(of: "(?<=id)[^?]+", options: .regularExpression) {
        id = (application.link?.substring(with: id_range) ?? "").filter("0123456789.".contains) //We do the filter to make sure we don't get any accidental chars
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
            guard let compiled_object = parseJsonData(data: data) else {
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
func fetch_application_data_atom(_ application: AtomFeedEntry, completion: @escaping (Application_Data.Results) -> Void) {
    //Our first step is to fetch the ID of the application, a trick we can do is to grab it from the URL...
    var id = ""
    if let id_range = application.id?.range(of: "(?<=id)[^?]+", options: .regularExpression) {
        id = (application.id?.substring(with: id_range) ?? "").filter("0123456789.".contains) //We do the filter to make sure we don't get any accidental chars
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
            guard let compiled_object = parseJsonData(data: data) else {
                return
            }
            if compiled_object.isEmpty == false {
                completion(compiled_object[0])
            }
        }
    })
    
    task.resume()
}

func parseJsonData(data: Data) -> [Application_Data.Results]? {
    
    var application_data = [Application_Data.Results]()
    
    let decoder = JSONDecoder()
    
    do {
        let loanDataStore = try decoder.decode(Application_Data.self, from: data)
        application_data = loanDataStore.results
        
    } catch {
        print(error)
    }
    
    return application_data
}


struct Application_Data: Codable {
    struct Results: Codable, Identifiable {
        var id: Int {return trackID}
        let screenshotUrls: [URL]
        let ipadScreenshotUrls: [URL]
        let appletvScreenshotUrls: [URL]
        let artworkUrl60: URL
        let artworkUrl512: URL
        let artworkUrl100: URL
        let artistViewURL: URL?
        let supportedDevices: [String]
        let advisories: [String]
        let isGameCenterEnabled: Bool
        let features: [String]
        let kind: String
        let minimumOsVersion: String
        let trackCensoredName: String
        let languageCodesISO2A: [String]
        let fileSizeBytes: String
        let sellerURL: URL?
        let formattedPrice: String?
        let contentAdvisoryRating: String
        let averageUserRatingForCurrentVersion: Double
        let userRatingCountForCurrentVersion: Int
        let averageUserRating: Double
        let trackViewURL: URL
        let trackContentRating: String
        let releaseNotes: String?
        let currentVersionReleaseDate: String
        let trackID: Int
        let trackName: String
        let releaseDate: String
        let sellerName: String
        let primaryGenreName: String
        let genreIds: [String]
        let isVppDeviceBasedLicensingEnabled: Bool
        let primaryGenreID: Int
        let currency: String
        let description: String
        let artistID: Date
        let artistName: String
        let genres: [String]
        let price: Double?
        let bundleID: String
        let version: String
        let wrapperType: String
        let userRatingCount: Int
        
        private enum CodingKeys: String, CodingKey {
            case screenshotUrls
            case ipadScreenshotUrls
            case appletvScreenshotUrls
            case artworkUrl60
            case artworkUrl512
            case artworkUrl100
            case artistViewURL = "artistViewUrl"
            case supportedDevices
            case advisories
            case isGameCenterEnabled
            case features
            case kind
            case minimumOsVersion
            case trackCensoredName
            case languageCodesISO2A
            case fileSizeBytes
            case sellerURL = "sellerUrl"
            case formattedPrice
            case contentAdvisoryRating
            case averageUserRatingForCurrentVersion
            case userRatingCountForCurrentVersion
            case averageUserRating
            case trackViewURL = "trackViewUrl"
            case trackContentRating
            case releaseNotes
            case currentVersionReleaseDate
            case trackID = "trackId"
            case trackName
            case releaseDate
            case sellerName
            case primaryGenreName
            case genreIds
            case isVppDeviceBasedLicensingEnabled
            case primaryGenreID = "primaryGenreId"
            case currency
            case description
            case artistID = "artistId"
            case artistName
            case genres
            case price
            case bundleID = "bundleId"
            case version
            case wrapperType
            case userRatingCount
        }
    }
    
    let resultCount: Int
    let results: [Results]
}

// MARK: - Item
struct Item {
    let title: String
    let link, guid: String
    let itemDescription: String
}


struct app_store_title_bar : View {
    var title:String
    @Binding var selected_segment: Int
    @Binding var selected_segment_25: Int
    @Binding var forward_or_backward: Bool
    @Binding var selectedTab:String
    @Binding var featured_show_application: Bool
    @Binding var top25_show_application: Bool
    @Binding var categories_current_view: String
    @Binding var search_results: [Application_Data.Results]
    @Binding var search_show_application: Bool
    @Binding var search_selected_application: Application_Data.Results?
    @State var search: String = ""
    @State var place_holder = ""
    var no_right_padding: Bool?
    @Binding var editing_state: String
    private let gradient = LinearGradient([.white, .white], to: .trailing)
    private let cancel_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    var show_edit: Bool
    var show_plus: Bool
    public var edit_action: (() -> Void)?
    public var plus_action: (() -> Void)?
    @Binding var instant_multitasking_change: Bool
    var body :some View {
        GeometryReader {geometry in
            ZStack {
                LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.49), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.49), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if (selectedTab != "Featured" || featured_show_application == true) && (selectedTab != "Top 25" || top25_show_application == true) && (selectedTab != "Search" || search_show_application == true) {
                            Text(title).ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", fixedSize: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)).combined(with: .opacity)).id(title).frame(maxWidth: (selectedTab == "Categories" && categories_current_view == "Category") ? 175 : .infinity)
                        } else if selectedTab == "Featured" {
                            dual_segmented_control(selected: $selected_segment, instant_multitasking_change: $instant_multitasking_change, first_text: "New", second_text: "Genius", should_animate: false).frame(width: 220, height: 30)
                        } else if selectedTab == "Top 25" {
                            tri_segmented_control(selected: $selected_segment_25, instant_multitasking_change: $instant_multitasking_change, first_text: "Paid", second_text: "Free", third_text: "Top Grossing", should_animate: false).frame(width: geometry.size.width-24, height: 30)
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
                                                        guard let search_string = search.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {return}
                                                        guard let url = URL(string: "https://itunes.apple.com/search?term=\(search_string)&country=us&entity=software") else {return}
                                                        print(url, "ZSK")
                                                        let request = URLRequest(url: url)
                                                        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
                                                            
                                                            if let error = error {
                                                                print(error)
                                                                return
                                                            }
                                                            
                                                            // Parse JSON data
                                                            if let data = data {
                                                                guard let compiled_object = parseJsonData(data: data) else {
                                                                    return
                                                                }
                                                                if compiled_object.isEmpty == false {
                                                                    search_results = compiled_object
                                                                }
                                                            }
                                                        })
                                                        
                                                        task.resume()
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
                        }
                        Spacer()
                    }
                    Spacer()
                }
                if selectedTab == "Featured", featured_show_application == true {
                    VStack {
                        Spacer()
                        HStack {
                            Button(action:{
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)){featured_show_application = false}
                            }){
                                ZStack {
                                    Image("Button_wp4").resizable().aspectRatio(contentMode: .fit).frame(width:84, height: 34.33783783783784)
                                    HStack(alignment: .center) {
                                        Text("App Store").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1).offset(x: 1)
                                    }
                                }.padding(.leading, 6)
                            }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                            Spacer()
                        }
                        Spacer()
                    }.offset(y:-0.5)
                    
                }
                if selectedTab == "Top 25", top25_show_application == true {
                    VStack {
                        Spacer()
                        HStack {
                            Button(action:{
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)){top25_show_application = false}
                            }){
                                ZStack {
                                    Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                                    HStack(alignment: .center) {
                                        Text("Top 25").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
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
                                        Text("Categories").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1).offset(x: 1)
                                    }
                                }.padding(.leading, 6)
                            }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                            Spacer()
                        }
                        Spacer()
                    }.offset(y:-0.5)
                    
                }
                
                if selectedTab == "Search", search_show_application == true {
                    VStack {
                        Spacer()
                        HStack {
                            Button(action:{
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)){search_show_application = false}
                            }){
                                ZStack {
                                    Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                                    HStack(alignment: .center) {
                                        Text("Search").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
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



struct TabButton_AppStore : View {
    
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
                            Image("UITabBarFeaturedSelected2").resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : 30.5, height: 30.5)
                        } else {
                            ZStack {
                                Image("\(image)_Store").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : 30.5, height: 30.5).overlay(
                                    LinearGradient(gradient: Gradient(colors: [Color(red: 205/255, green: 233/255, blue: 249/255), Color(red: 75/255, green: 220/255, blue: 251/255)]), startPoint: .top, endPoint: .bottom)
                                ).mask(Image("\(image)_Store").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : 30.5, height: 30.5)).offset(y:-0.5)
                                
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
                                ).mask(Image("\(image)_Store").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.6), radius:2.5, x: 0, y:2.5)
                            }
                        }
                        HStack {
                            if image != "Categories" {
                                Spacer()
                            }
                            Text(image).foregroundColor(.white).font(.custom("Helvetica Neue Bold", fixedSize: 11))
                            if image != "Categories" {
                                Spacer()
                            }
                        }.frame(maxWidth: geometry.size.width/5 - 5)
                    }
                } else {
                    VStack(spacing: 2) {
                        Image("\(image)_Store").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : 30, height: 30).overlay(
                            LinearGradient(gradient: Gradient(colors: [Color(red: 157/255, green: 157/255, blue: 157/255), Color(red: 89/255, green: 89/255, blue: 89/255)]), startPoint: .top, endPoint: .bottom)
                        ).mask(Image("\(image)_Store").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.75), radius: 0, x: 0, y: -1)
                        // Image(uiImage: UIImage(named:"\(image)_iPod")?.stroked() ?? UIImage())
                        HStack {
                            if image != "Categories" {
                                Spacer()
                            }
                            Text(image).foregroundColor(Color(red: 168/255, green: 168/255, blue: 168/255)).font(.custom("Helvetica Neue Bold", fixedSize: 11))
                            if image != "Categories" {
                                Spacer()
                            }
                        }.frame(maxWidth: geometry.size.width/5 - 5)
                    }
                }
            }
        }
    }
}

struct blank_appstore_view: View {
    var body: some View {
        Text("")
    }
}
