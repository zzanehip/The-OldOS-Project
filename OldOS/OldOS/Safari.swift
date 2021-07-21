//
//  Safari.swift
//  OldOS
//
//  Created by Zane Kleinberg on 2/20/21.
//

import SwiftUI
import WebKit
import Introspect
import SwiftUIPager
import Combine
struct Safari: View {
    @State var current_nav_view: String = "Main"
    @State var forward_or_backward = false
    @State var url_search: String = ""
    @State var google_search: String = ""
    @State var editing_state_url: String = "None"
    @State var editing_state_google: String = "None"
    @State var current_webpage_title: String = ""
    @State private var webViewHeight: CGFloat = .zero
    @State var offset: CGPoint = CGPoint(0,0)
    @State var first_load: Bool = true
    @State var selecting_tab: Bool = false
    @State var instant_background_change: Bool = false
    @State var can_tap_view: Bool = true
    @ObservedObject var views: ObservableArray<WebViewStore> = try! ObservableArray(array: [WebViewStore()]).observeChildrenChanges()
    @StateObject var page: Page = .first()
    @State var will_remove_object: WebViewStore = WebViewStore()
    @State var did_add_to_end: Bool = false
    @State var show_bookmarks: Bool = false
    @State var show_share:Bool = false
    @State var bookmark_name: String = ""
    @State var show_save_bookmark: Bool = false
    @State var is_editing_bookmarks: Bool = false
    @State var new_page_delay: Bool = false
    @Binding var instant_multitasking_change: Bool
    var items = Array(0..<1)
    
    init(instant_multitasking_change: Binding<Bool>) {
        _instant_multitasking_change = instant_multitasking_change
        let userDefaults = UserDefaults.standard

        var webpages = (userDefaults.object(forKey: "webpages") as? [String:String] ?? ["0":"https://"]).sorted(by: >)
        if webpages.count > 1 {
        for i in 0..<(webpages.count-1) {
            views.array.append(WebViewStore())
        }
        }
        for item in webpages {
            if let url = URL(string:item.value) {
                views.array[Int(item.key) ?? 0].webView.load(URLRequest(url: url))
            }
        }

   }
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing:0) {
                    Spacer().frame(height:24)
                    Pager(page: page,
                          data: views.array,
                          id: \.id,
                          content: { index in
                            ZStack {
                                ScrollView([]) {
                                    VStack {
                                        Spacer().frame(height:76).offset(y: offset.height < 76 ? -offset.height : -76).drawingGroup()
                                        Webview(dynamicHeight: $webViewHeight, offset: $offset, selecting_tab:$selecting_tab, webview: index.webView)
                                            .frame(height:geometry.size.height - (24+45)).offset(y: offset.height < 76 ? -offset.height : -76)
                                    }
                                }.disabled(selecting_tab).simultaneousGesture(
                                    TapGesture()
                                        .onEnded({
                                            if selecting_tab == true, can_tap_view == true {
                                                if views.array.firstIndex(of: index) == page.index {
                                                    print(page)
                                                    if instant_background_change == false {
                                                        instant_background_change = true
                                                    } else {
                                                        DispatchQueue.main.asyncAfter(deadline:.now()+0.25) {
                                                            instant_background_change = false
                                                        }
                                                    }
                                                    withAnimation(.linear(duration:0.25)) {
                                                        page.update(.new(index: views.array.firstIndex(of: index) ?? 0))//This page update is ensurance if we get stuck
                                                        url_search = index.webView.url?.relativeString ?? ""
                                                        selecting_tab.toggle()
                                                    }
                                                } else {
                                                    withAnimation(.linear(duration:0.25)) {
                                                        page.update(.new(index: views.array.firstIndex(of: index) ?? 0))
                                                    }
                                                }
                                            }
                                        })).shadow(color:Color.black.opacity(0.4), radius: 3, x: 0, y:4).opacity(views.array.firstIndex(of: index) == page.index ? 1 : 0.2)
                                VStack {
                                    HStack {
                                        Button(action:{
                                            if views.array.count > 1 {
                                                withAnimation(.linear(duration:0.2)) {
                                                    will_remove_object = index
                                                }
                                                DispatchQueue.main.asyncAfter(deadline:.now()+0.21) {
                                                    if index == views.array.last {
                                                        withAnimation {
                                                            page.update(.previous)
                                                            if let rem_index = views.array.firstIndex(of: index) {
                                                                views.array.remove(at: rem_index)
                                                                let userDefaults = UserDefaults.standard
                                                                var webpage_dict = [String:String]()
                                                                var i = 0
                                                                for item in views.array {
                                                                    webpage_dict["\(i)"] = (item.webView.url?.relativeString != nil ? item.webView.url?.relativeString : "http")
                                                                    i += 1
                                                                }
                                                                var defaults_webpages = (userDefaults.object(forKey: "webpages") as? [String:String] ?? ["0":"https://"]).sorted(by: >)
                                                                if defaults_webpages != webpage_dict.sorted(by: >) {
                                                                userDefaults.setValue(webpage_dict, forKey: "webpages")
                                                                }
                                                            }
                                                        }
                                                    } else {
                                                        withAnimation {
                                                            if let rem_index = views.array.firstIndex(of: index) {
                                                                views.array.remove(at: rem_index)
                                                                let userDefaults = UserDefaults.standard
                                                                var webpage_dict = [String:String]()
                                                                var i = 0
                                                                for item in views.array {
                                                                    webpage_dict["\(i)"] = (item.webView.url?.relativeString != nil ? item.webView.url?.relativeString : "http")
                                                                    i += 1
                                                                }
                                                                var defaults_webpages = (userDefaults.object(forKey: "webpages") as? [String:String] ?? ["0":"https://"]).sorted(by: >)
                                                                if defaults_webpages != webpage_dict.sorted(by: >) {
                                                                userDefaults.setValue(webpage_dict, forKey: "webpages")
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            
                                        }) {
                                            Image("closebox").resizable().scaledToFill().frame(width:50, height:50)
                                        }.padding([.top], 80).padding([.trailing], 60).frame(width:60, height:60)
                                        Spacer()
                                    }
                                    Spacer()
                                }.disabled(!selecting_tab).opacity(selecting_tab == true ? views.array.firstIndex(of: index) == page.index ? views.array.count > 1 ? 1 : 0 : 0 : 0) //The magic of the turnery
                            }.scaleEffect(selecting_tab == true ? 0.55 : views.array.firstIndex(of: index) == page.index ? 1 : 0.55).zIndex(views.array.firstIndex(of: index) == page.index ? 1 : 0).opacity(will_remove_object == index ? 0 : 1).opacity(did_add_to_end == true ? index == views.array.last ? 0 : 1 : 1)}) .itemSpacing( -geometry.size.width*0.30).onDraggingBegan({
                                can_tap_view = false
                            }).onDraggingEnded({
                                can_tap_view = true
                            }).alignment(.center).preferredItemSize(CGSize(width: geometry.size.width, height: geometry.size.height - (24+45))).sensitivity(.high).allowsDragging(selecting_tab).multiplePagination().background(instant_background_change == true ? LinearGradient([Color(red: 149/255, green: 161/255, blue: 172/255), Color(red: 85/255, green: 105/255, blue: 121/255)], from: .top, to: .bottom) : LinearGradient([Color.clear], from: .top, to: .bottom))
                    Spacer().frame(minHeight:45, maxHeight:45)
                    
                }.clipped()
                VStack {
                    Spacer().frame(height:geometry.size.height*(1/9))
                    HStack {
                        Spacer()
                        Text(views.array[page.index].webView.title != "" ? (views.array[page.index].webView.title ?? "Untitled") :  "Untitled").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", size: 22)).shadow(color: Color.black.opacity(0.51), radius: 0, x: 0.0, y: -2/3).lineLimit(0).animation(instant_multitasking_change == true ? .default : .none)
                        Spacer()
                    }
                    Spacer().frame(height:10)
                    HStack {
                        Spacer()
                        Text(views.array[page.index].webView.url?.relativeString ?? "Untitled").foregroundColor(Color(red: 182/255, green: 188/255, blue: 192/255)).font(.custom("Helvetica Neue Bold", size: 16)).shadow(color: Color.black.opacity(0.51), radius: 0, x: 0.0, y: -2/3).lineLimit(0).animation(instant_multitasking_change == true ? .default : .none).opacity(views.array[page.index].webView.url?.relativeString != nil ? 1 : 0)
                        Spacer()
                    }.if(!instant_multitasking_change){$0.animationsDisabled()}
                    Spacer()
                }.opacity(selecting_tab == true ? 1 : 0)
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Spacer()
                        ForEach(views.array, id:\.id) { index in
                            Circle().fill(Color.white).frame(width:7.5, height:7.5).opacity(views.array.firstIndex(of: index) == page.index ? 1 : 0.25)
                        }.opacity(views.array.count > 1 ? 1 : 0)
                        Spacer()
                    }.if(!instant_multitasking_change){$0.animationsDisabled()}
                    Spacer().frame(height:geometry.size.height*(1.5/9))
                }.opacity(selecting_tab == true ? 1 : 0)
                ZStack {
                if editing_state_url != "None" || editing_state_google != "None" {
                    Color.black.opacity(0.75)
                }
                }
                VStack(spacing:0) {
                    status_bar_in_app().frame(minHeight: 24, maxHeight:24).zIndex(2)
                    safari_title_bar(forward_or_backward: $forward_or_backward, current_nav_view: $current_nav_view, url_search: $url_search, google_search: $google_search, editing_state_url: $editing_state_url, editing_state_google: $editing_state_google, webViewStore: views.array[page.index], current_webpage_title: views.array[page.index].webView.title ?? "").frame(minHeight: 60, maxHeight: 60).padding(.bottom, 5).offset(y: offset.height < 76 ? -offset.height : -76).zIndex(1).opacity(selecting_tab == true ? 0 : 1)
                    Spacer()
                }.clipped()
                if show_bookmarks {
                    bookmarks_view(show_bookmarks: $show_bookmarks, is_editing_bookmarks: $is_editing_bookmarks, webViewStore: views.array[page.index]).transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom))).zIndex(1)
                }
                VStack(spacing:0) {
                    Spacer()
                    tool_bar(webViewStore: views.array[page.index], selecting_tab: $selecting_tab, offset:$offset, instant_background_change: $instant_background_change, show_share: $show_share, show_bookmarks: $show_bookmarks, is_editing_bookmarks: $is_editing_bookmarks, new_tab_action: {
                        if new_page_delay == false {
                        if views.array.count < 8 {
                            did_add_to_end = true
                            new_page_delay = true
                            views.array.append(WebViewStore())
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.21) {
                                withAnimation {
                                    page.update(.moveToLast)
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.61) {
                                withAnimation(.linear(duration:0.25)) {
                                    did_add_to_end = false
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.86) {
                                if instant_background_change == false {
                                    instant_background_change = true
                                } else {
                                    DispatchQueue.main.asyncAfter(deadline:.now()+0.25) {
                                        instant_background_change = false
                                    }
                                }
                                withAnimation(.linear(duration:0.25)) {
                                    selecting_tab.toggle()
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.12) {
                                new_page_delay = false
                            }
                        }
                        }
                    }, editing_bookmarks_action:{
                        withAnimation() {
                            is_editing_bookmarks.toggle()
                        }
                    }, tab_image: "NavTab\(views.array.count != 1 ? String(views.array.count) : "")").frame(height: 45)
                }.zIndex(2)
                ZStack {
                if show_share == true {
                    Color.black.opacity(0.35)
                    VStack(spacing:0) {
                        Spacer().foregroundColor(.clear).zIndex(0)
                        share_view(cancel_action:{
                            withAnimation() {
                                show_share.toggle()
                            }
                        }, bookmark_action:{
                            withAnimation(.linear(duration:0.25)) {
                                show_share.toggle()
                            }
                            bookmark_name = views.array[page.index].webView.title ?? "Untitled"
                            DispatchQueue.main.asyncAfter(deadline:.now()+0.25) {
                                withAnimation(.linear(duration:0.25)) {
                                    show_save_bookmark.toggle()
                                }
                            }
                        }).frame(minHeight: geometry.size.height*(0.58), maxHeight: geometry.size.height*(0.58))
                    }.transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom)))
               }//We nest this in a VStack to get around type check errors
                }.zIndex(3)
                ZStack {
                    if show_save_bookmark == true {
                        add_bookmark_view(bookmark_name: $bookmark_name, url: views.array[page.index].webView.url ?? URL(string:"google.com")!, cancel_action:{withAnimation(){show_save_bookmark.toggle()}}, save_action:{
                            let userDefaults = UserDefaults.standard

                            // Read/Get Array of Strings
                            var bookmarks: [String:String] = userDefaults.object(forKey: "bookmarks") as? [String:String] ?? [String: String]()

                            // Append String to Array of Strings
                            bookmarks.updateValue(bookmark_name, forKey: views.array[page.index].webView.url?.relativeString ?? "")

                            // Write/Set Array of Strings
                            userDefaults.set(bookmarks, forKey: "bookmarks")
                            withAnimation() {
                            show_save_bookmark.toggle()
                            }
                        }).transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom)))
                    }
                }.zIndex(4)
            }.compositingGroup().clipped()//Having our view composed of 2 VStacks allows our webviews and titles to work independtly from each other.
        }.background(Color(red: 93/255, green: 99/255, blue: 103/255)).onAppear() {
            UIScrollView.appearance().bounces = true
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
        }.onReceive(views.array[page.index].objectWillChange) {_ in
            if editing_state_url == "None" {
            url_search = views.array[page.index].webView.url?.relativeString ?? ""
            }
            let userDefaults = UserDefaults.standard
            var webpage_dict = [String:String]()
            var i = 0
            for item in views.array {
                webpage_dict["\(i)"] = (item.webView.url?.relativeString != nil ? item.webView.url?.relativeString : "http")
                i += 1
            }
            var defaults_webpages = (userDefaults.object(forKey: "webpages") as? [String:String] ?? ["0":"https://"]).sorted(by: >)
            if defaults_webpages != webpage_dict.sorted(by: >) {
            userDefaults.setValue(webpage_dict, forKey: "webpages")
            }
        }.onChange(of: page.index) {_ in
            if editing_state_url == "None" {
            url_search = views.array[page.index].webView.url?.relativeString ?? ""
            }
            let userDefaults = UserDefaults.standard
            var webpage_dict = [String:String]()
            var i = 0
            for item in views.array {
                webpage_dict["\(i)"] = (item.webView.url?.relativeString != nil ? item.webView.url?.relativeString : "http")
                i += 1
            }
            var defaults_webpages = (userDefaults.object(forKey: "webpages") as? [String:String] ?? ["0":"https://"]).sorted(by: >)
            if defaults_webpages != webpage_dict.sorted(by: >) {
            userDefaults.setValue(webpage_dict, forKey: "webpages")
            }
        }
    }
}

func areEqual (_ left: Any, _ right: Any) -> Bool {
    if  type(of: left) == type(of: right) &&
        String(describing: left) == String(describing: right) { return true }
    if let left = left as? [Any], let right = right as? [Any] { return left == right }
    if let left = left as? [AnyHashable: Any], let right = right as? [AnyHashable: Any] { return left == right }
    return false
}

extension Array where Element: Any {
    static func != (left: [Element], right: [Element]) -> Bool { return !(left == right) }
    static func == (left: [Element], right: [Element]) -> Bool {
        if left.count != right.count { return false }
        var right = right
        loop: for leftValue in left {
            for (rightIndex, rightValue) in right.enumerated() where areEqual(leftValue, rightValue) {
                right.remove(at: rightIndex)
                continue loop
            }
            return false
        }
        return true
    }
}
extension Dictionary where Value: Any {
    static func != (left: [Key : Value], right: [Key : Value]) -> Bool { return !(left == right) }
    static func == (left: [Key : Value], right: [Key : Value]) -> Bool {
        if left.count != right.count { return false }
        for element in left {
            guard   let rightValue = right[element.key],
                areEqual(rightValue, element.value) else { return false }
        }
        return true
    }
}

struct bookmarks_view: View {
    @Binding var show_bookmarks: Bool
    @Binding var is_editing_bookmarks: Bool
    @State var to_delete: String = ""
    var webViewStore: WebViewStore
    @ObservedObject var bm_observer = bookmarks_observer()
    var body: some View {
        VStack(spacing:0)  {
            Spacer().frame(minHeight: 24, maxHeight:24)
            generic_title_bar(title: "Bookmarks", done_action:{withAnimation(){show_bookmarks.toggle()}}, show_done: !is_editing_bookmarks).frame(minHeight: 60, maxHeight: 60)
            NoSepratorList {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center) {
                        Spacer().frame(width:1, height: 44-0.95)
                        Image("HistoryFolder").frame(width:25, height: 44-0.95)
                        Text("History").font(.custom("Helvetica Neue Bold", size: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 6).padding(.trailing, 40)
                        Spacer()
                        Image("UITableNext").padding(.trailing, 12)
                    }.padding(.leading, 15)
                    Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                    
                }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 44)
                ForEach((bm_observer.bookmarks ?? [:]).sorted(by: <), id: \.key) { key, value in
                    Button(action:{
                        if let url = URL(string: key) {
                        webViewStore.webView.load(URLRequest(url: url))
                            withAnimation() {
                                show_bookmarks.toggle()
                            }
                        }
                    }) {
                    VStack(alignment: .leading, spacing: 0) {
                        //Spacer().frame(height:4.5)
                        HStack(alignment: .center) {
                            Spacer().frame(width:1, height: 44-0.95)
                            if is_editing_bookmarks == true {
                                Button(action:{
                                    withAnimation(.linear(duration:0.15)) {
                                        if to_delete != key {
                                        to_delete = key
                                        } else {
                                            to_delete = ""
                                        }
                                    }
                                }) {
                                    ZStack {
                                    Image("UIRemoveControlMinus")
                                        Text("—").foregroundColor(.white).font(.system(size: 15, weight: .heavy, design: .default)).offset(y:to_delete == key ? -0.8 : -2).rotationEffect(.degrees(to_delete == key ? -90 : 0), anchor: .center).offset(y:to_delete == key ? -0.5 : 0)
                                    }
                                }.transition(AnyTransition.asymmetric(insertion: .move(edge:.leading), removal: .move(edge:.leading)).combined(with: .opacity)).offset(x:-2)
                            }
                            Image("Bookmark").frame(width:25, height: 44-0.95)
                            Text(value).font(.custom("Helvetica Neue Bold", size: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 6).padding(.trailing, 12)
                            if to_delete == key {
                                Spacer()
                                tool_bar_rectangle_button(action: {withAnimation() {
                                    bm_observer.bookmarks.removeValue(forKey: key)
                                }}, button_type: .red, content: "Delete").padding(.trailing, 12).transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge:.trailing)).combined(with: .opacity))
                            }
                        }.padding(.leading, 15)
                        //  Spacer().frame(height:9.5)
                        Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                        
                    }
                    }
                }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 44).drawingGroup()
            
            }.background(Color.white)
            Spacer().frame(minHeight: 45, maxHeight:45)
        }
    }
}

class bookmarks_observer: ObservableObject {
    @Published var bookmarks: [String:String] {
        didSet {
            UserDefaults.standard.set(bookmarks, forKey: "bookmarks")
        }
    }
    
    init() {
        self.bookmarks = UserDefaults.standard.object(forKey: "bookmarks") as? [String:String] ?? [:]
    }
}

struct share_view: View {
    public var cancel_action: (() -> Void)?
    public var bookmark_action: (() -> Void)?
    private let background_gradient = LinearGradient(gradient: Gradient(colors: [Color.init(red: 70/255, green: 73/255, blue: 81/255), Color.init(red: 70/255, green: 73/255, blue: 81/255)]), startPoint: .top, endPoint: .bottom)
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                VStack(spacing:0) {
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 166/255, green: 171/255, blue: 179/255).opacity(0.88), Color.init(red: 122/255, green: 127/255, blue: 138/255).opacity(0.88)]), startPoint: .top, endPoint: .bottom)).innerShadowBottom(color: Color.white.opacity(0.98), radius: 0.1).border_top(width: 1, edges:[.top], color: Color.black).frame(height:30)
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 96/255, green: 101/255, blue: 111/255).opacity(0.88), Color.init(red: 96/255, green: 101/255, blue: 111/255).opacity(0.9)]), startPoint: .top, endPoint: .bottom))
                }
                VStack {
                    Button(action:{
                        bookmark_action?()
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color.clear).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5)).ps_innerShadow(.roundedRectangle(12, background_gradient), radius:5/3, offset: CGPoint(0, 1/3), intensity: 1)
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 235/255, green: 235/255, blue: 236/255), location: 0), .init(color: Color(red: 208/255, green: 209/255, blue: 211/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Add Bookmark").font(.custom("Helvetica Neue Bold", size: 18)).foregroundColor(Color.black).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.bottom], 2.5).padding(.top, 28)
                    Button(action:{
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color.clear).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5)).ps_innerShadow(.roundedRectangle(12, background_gradient), radius:5/3, offset: CGPoint(0, 1/3), intensity: 1)
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 235/255, green: 235/255, blue: 236/255), location: 0), .init(color: Color(red: 208/255, green: 209/255, blue: 211/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Add to Home Screen").font(.custom("Helvetica Neue Bold", size: 18)).foregroundColor(Color.black).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.top, .bottom], 2.5)
                    Button(action:{
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color.clear).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5)).ps_innerShadow(.roundedRectangle(12, background_gradient), radius:5/3, offset: CGPoint(0, 1/3), intensity: 1)
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 235/255, green: 235/255, blue: 236/255), location: 0), .init(color: Color(red: 208/255, green: 209/255, blue: 211/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Mail Link to this Page").font(.custom("Helvetica Neue Bold", size: 18)).foregroundColor(Color.black).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.top, .bottom], 2.5)
                    Button(action:{
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color.clear).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5)).ps_innerShadow(.roundedRectangle(12, background_gradient), radius:5/3, offset: CGPoint(0, 1/3), intensity: 1)
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 235/255, green: 235/255, blue: 236/255), location: 0), .init(color: Color(red: 208/255, green: 209/255, blue: 211/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 0.52), .init(color: Color(red: 192/255, green: 193/255, blue: 196/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Print").font(.custom("Helvetica Neue Bold", size: 18)).foregroundColor(Color.black).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.top, .bottom], 2.5)
                    Spacer()
                    Button(action:{
                      cancel_action?()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(Color.clear).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5)).ps_innerShadow(.roundedRectangle(12, background_gradient), radius:5/3, offset: CGPoint(0, 1/3), intensity: 1)
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient([(color: Color(red: 107/255, green: 113/255, blue:119/255), location: 0), (color: Color(red: 53/255, green: 62/255, blue:69/255), location: 0.50), (color: Color(red: 41/255, green: 48/255, blue:57/255), location: 0.50), (color: Color(red: 56/255, green: 62/255, blue:71/255), location: 1)], from: .top, to: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.gray.opacity(0.9), Color.gray.opacity(0.35)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3).opacity(0.6)
                            Text("Cancel").font(.custom("Helvetica Neue Bold", size: 18)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0.0, y: -0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.bottom], 25)
                }
            }.drawingGroup()
        }
    }
}

struct add_bookmark_view: View {
    @State var current_nav_view: String = ""
    @State var forward_or_backward: Bool = false
    @Binding var bookmark_name: String
    @State var editing_state_title: String = "None"
    var url: URL
    public var cancel_action: (() -> Void)?
    public var save_action: (() -> Void)?
    var body: some View {
        VStack(spacing:0) {
            Spacer().frame(height:24)
        ZStack {
            settings_main_list()
            VStack(spacing:0) {
                generic_title_bar_cancel_save(title: "Add Bookmark", cancel_action: {cancel_action?()}, save_action:{save_action?()}, show_cancel: true, show_save: true).frame(height: 60)
                ScrollView {
                    VStack {
                        Spacer().frame(height:20)
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10)
                                                                                            .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25))
                            VStack(spacing:0) {
                            ZStack {
                                Rectangle().fill(Color.clear).frame(height:50).border_bottom(width: 1.25, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))
                                HStack {
                                    TextField("Title", text: $bookmark_name){
                                        save_action?()
                                    }.font(.custom("Helvetica Neue Regular", size: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.leading, 12)
                                    if bookmark_name.count != 0 {
                                        Button(action:{bookmark_name = ""}) {
                                            Image("UITextFieldClearButton")
                                        }.fixedSize().padding(.trailing,12)
                                    }
                                }
                            }.frame(height: 50)
                                ZStack {
                                    Rectangle().fill(Color.clear).frame(height:50)
                                    HStack {
                                        Text(url.relativeString).font(.custom("Helvetica Neue Regular", size: 18)).foregroundColor(Color(red: 143/255, green: 143/255, blue: 143/255)).padding(.leading, 12)
                                        Spacer()
                                    }
                                }.frame(height: 50)
                            }
                        }.frame(height: 100).padding([.leading, .trailing], 12)
                        
                        Spacer().frame(height:20)
                        list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: [list_row(title: "", content: AnyView(bookmark_content()))])
                    }
                }
            }
        }
    }
}
}

#if canImport(UIKit)
extension View {
    func showKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct enter_bookmark_title_content: View {
    @Binding var bookmark_name: String
    var body: some View {
        HStack {
            TextField("Title", text: $bookmark_name).font(.custom("Helvetica Neue Regular", size: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.leading, 12)
        
    }
}
}

struct bookmark_content: View {
    var body: some View {
        HStack {
            Text("Bookmarks").font(.custom("Helvetica Neue Regular", size: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255)).padding(.leading, 12)
            Spacer()
            //Image(systemName: "chevron.right").foregroundColor(Color(red: 127/255, green: 127/255, blue: 127/255)).padding(.trailing, 12)
            Image("UITableNext").padding(.trailing, 12)
        
    }
}
}

extension View {
    
    func animationsDisabled() -> some View {
        return self.transaction { (tx: inout Transaction) in
            tx.disablesAnimations = true
            tx.animation = nil
        }.animation(nil)
    }
}

extension View {
    public func introspectScrollView2(customize: @escaping (UIScrollView) -> ()) -> some View {
        return inject(UIKitIntrospectionView(
            selector: { introspectionView in
                guard let viewHost = Introspect.findViewHost(from: introspectionView) else {
                    return nil
                }
                if let scrollView = Introspect.previousSibling(containing: UIScrollView.self, from: viewHost) {
                    return scrollView
                }else if let superView = viewHost.superview {
                    return Introspect.previousSibling(containing: UIScrollView.self, from: superView)
                }
                return nil
            },
            customize: customize
        ))
    }
}

struct Webview : UIViewRepresentable {
    @Binding var dynamicHeight: CGFloat
    @Binding var offset: CGPoint
    @Binding var selecting_tab: Bool
    var webview: WKWebView = WKWebView()
    var oldContentOffset = CGPoint.zero
    var originalcenter = CGPoint.zero
    class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
        var parent: Webview
        
        init(_ parent: Webview) {
            self.parent = parent
            self.parent.originalcenter = parent.webview.scrollView.subviews[0].center
        }
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if parent.selecting_tab == false {
                var offset = scrollView.contentOffset
                parent.offset = offset
                
                if offset.y < 76 {
                    parent.webview.scrollView.subviews[0].center.y = parent.originalcenter.y  + offset.y
                } else if offset.y > 76 {
                    parent.webview.scrollView.subviews[0].center.y = parent.originalcenter.y + 76
                    parent.webview.scrollView.contentInset = UIEdgeInsets(0, 0, 76, 0)
                }
                
            }
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(WKNavigationActionPolicy(rawValue: WKNavigationActionPolicy.allow.rawValue + 2)!)
        }
        
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView  {
        webview.navigationDelegate = context.coordinator
        webview.scrollView.delegate = context.coordinator
        webview.scrollView.backgroundColor = UIColor(red: 93/255, green: 99/255, blue: 103/255, alpha: 1.0)
        webview.configuration.suppressesIncrementalRendering = true
        webview.customUserAgent = "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8A293 Safari/6531.22.7"
        return webview
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        webview.scrollView.backgroundColor = UIColor(red: 93/255, green: 99/255, blue: 103/255, alpha: 1.0)
    }
}

//Thanks to https://stackoverflow.com/questions/57459727/why-an-observedobject-array-is-not-updated-in-my-swiftui-application for this genius solution to a problem I've encountered on various projects. This let's us be notified of changes to published vars inside an array, which itself is a published var.
class ObservableArray<T>: ObservableObject {
    
    
    @Published var array:[T] = []
    var cancellables = [AnyCancellable]()
    
    init(array: [T]) {
        self.array = array
        
    }
    
    func observeChildrenChanges<T: ObservableObject>() -> ObservableArray<T> {
        let array2 = array as! [T]
        array2.forEach({
            let c = $0.objectWillChange.sink(receiveValue: { _ in self.objectWillChange.send() })
            
            // Important: You have to keep the returned value allocated,
            // otherwise the sink subscription gets cancelled
            self.cancellables.append(c)
        })
        return self as! ObservableArray<T>
    }
    
    
}

public class WebViewStore: ObservableObject, Identifiable, Equatable {
    public static func == (lhs: WebViewStore, rhs: WebViewStore) -> Bool {
        return lhs.webView == rhs.webView
    }
    
    @Published public var webView: WKWebView {
        didSet {
            setupObservers()
        }
    }
    
    public init(webView: WKWebView = WKWebView()) {
        self.webView = webView
        setupObservers()
    }
    
    private func setupObservers() {
        func subscriber<Value>(for keyPath: KeyPath<WKWebView, Value>) -> NSKeyValueObservation {
            return webView.observe(keyPath, options: [.prior]) { _, change in
                if change.isPrior {
                    self.objectWillChange.send()
                }
            }
        }
        // Setup observers for all KVO compliant properties
        observers = [
            subscriber(for: \.title),
            subscriber(for: \.url),
            subscriber(for: \.isLoading),
            subscriber(for: \.estimatedProgress),
            subscriber(for: \.hasOnlySecureContent),
            subscriber(for: \.serverTrust),
            subscriber(for: \.canGoBack),
            subscriber(for: \.canGoForward),
            subscriber(for: \.scrollView.contentSize)
        ]
    }
    
    private var observers: [NSKeyValueObservation] = []
    
    public subscript<T>(dynamicMember keyPath: KeyPath<WKWebView, T>) -> T {
        webView[keyPath: keyPath]
    }
}



struct tool_bar: View {
    var webViewStore: WebViewStore
    @Binding var selecting_tab: Bool
    @Binding var offset: CGPoint
    @Binding var instant_background_change: Bool
    @Binding var show_share:Bool
    @Binding var show_bookmarks: Bool
    @Binding var is_editing_bookmarks:Bool
    public var new_tab_action: (() -> Void)?
    public var editing_bookmarks_action: (() -> Void)?
    var tab_image: String
    var body: some View {
        ZStack {
            LinearGradient([(color: Color(red: 230/255, green: 230/255, blue: 230/255), location: 0), (color: Color(red: 180/255, green: 191/255, blue: 206/255), location: 0.04), (color: Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.51), (color: Color(red: 126/255, green: 148/255, blue: 176/255), location: 0.51), (color: Color(red: 110/255, green: 132/255, blue: 162/255), location: 1)], from: .top, to: .bottom).border_bottom(width: 1, edges: [.top], color: Color(red: 45/255, green: 48/255, blue: 51/255))//I just discovered it was much easier to do this...duh
            if !show_bookmarks {
            if !selecting_tab {
                HStack {
                    tool_bar_button(image:"NavBack", action: {
                        webViewStore.webView.goBack()
                    }).opacity(webViewStore.webView.canGoBack == true ? 1 : 0.25)
                    tool_bar_button(image:"NavForward", action: {
                        webViewStore.webView.goForward()
                    }).opacity(webViewStore.webView.canGoForward == true ? 1 : 0.25)
                    tool_bar_button(image:"NavAction", action: {
                        withAnimation() {
                            show_share.toggle()
                        }
                    })
                    tool_bar_button(image:"NavBookmarks", action: {
                        withAnimation() {
                            show_bookmarks.toggle()
                        }
                    })
                    tool_bar_button(image:tab_image) {
                        offset = CGPoint(0,0)
                        if instant_background_change == false {
                            instant_background_change = true
                        } else {
                            DispatchQueue.main.asyncAfter(deadline:.now()+0.25) {
                                instant_background_change = false
                            }
                        }
                        withAnimation(.linear(duration:0.25)) {
                            selecting_tab.toggle()
                        }
                    }
                }.transition(.opacity)
            } else {
                HStack {
                    tool_bar_rectangle_button(action: {new_tab_action?()}, button_type: .blue_gray, content: "New Page").padding(.leading, 5)
                    Spacer()
                    tool_bar_rectangle_button(action: {
                                                offset = CGPoint(0,0)
                                                if instant_background_change == false {
                                                    instant_background_change = true
                                                } else {
                                                    DispatchQueue.main.asyncAfter(deadline:.now()+0.25) {
                                                        instant_background_change = false
                                                    }
                                                }
                                                withAnimation(.linear(duration:0.25)) {
                                                    selecting_tab.toggle()
                                                }}, button_type: .blue, content: "Done").padding(.trailing, 5)
                }.transition(.opacity)
            }
            } else {
                HStack {
                    tool_bar_rectangle_button(action: {editing_bookmarks_action?()}, button_type: is_editing_bookmarks == false ? .blue_gray : .blue, content: is_editing_bookmarks == false ? " Edit " : "Done").padding(.leading, 5)
                    Spacer()
                    if is_editing_bookmarks == true {
                        tool_bar_rectangle_button(action: {}, button_type: .blue_gray, content: "New Folder").padding(.trailing, 5)
                    }
                }.transition(.opacity)
            }
        }
    }
}



struct safari_title_bar : View {
    @Binding var forward_or_backward: Bool
    @Binding var current_nav_view: String
    @Binding var url_search: String
    @Binding var google_search: String
    @Binding var editing_state_url: String
    @Binding var editing_state_google: String
    @State var progress: Double = 1.0
    var webViewStore: WebViewStore
    var current_webpage_title: String
    var no_right_padding: Bool?
    private let gradient = LinearGradient([.white, .white], to: .trailing)
    private let cancel_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    var body :some View {
        GeometryReader{ geometry in
            ZStack {
                LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.49), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.49), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(current_webpage_title != "" ? current_webpage_title : "Untitled").foregroundColor(Color(red: 62/255, green: 69/255, blue: 79/255)).font(.custom("Helvetica Neue Bold", size: 14)).shadow(color: Color.white.opacity(0.51), radius: 0, x: 0.0, y: 2/3).padding([.leading, .trailing], 24)
                        Spacer()
                    }
                    HStack {
                        if editing_state_google == "None" {
                            ZStack {
                                RoundedRectangle(cornerRadius:6).fill(progress == 1.0 ? LinearGradient([(color: Color.white, location: 0)], from: .top, to: .bottom) : progress == 0.0 ? LinearGradient([(color: Color.white, location: 0)], from: .top, to: .bottom) : LinearGradient([(color: Color(red: 129/255, green: 184/255, blue:237/255), location: 0), (color: Color(red: 96/255, green: 168/255, blue:236/255), location: 0.50), (color: Color(red: 71/255, green: 148/255, blue:233/255), location: 0.50), (color: Color(red: 104/255, green: 194/255, blue:233/255), location: 1)], from: .top, to: .bottom)).brightness(0.1).frame(width:editing_state_url == "None" ? geometry.size.width*2/3-18.5 : geometry.size.width - 79.5).padding(.leading, 2.5).padding(.trailing, 1)
                                url_search_bar(url_search: $url_search, editing_state_url: $editing_state_url, progress: $progress, webViewStore: webViewStore).frame(width:editing_state_url == "None" ? geometry.size.width*2/3-15 : geometry.size.width - 76)
                            }
                        }
                        if editing_state_url == "None" {
                            ZStack {
                            google_search_bar(google_search: $google_search, url_search: $url_search, editing_state_google: $editing_state_google, webViewStore: webViewStore).frame(width:editing_state_google == "None" ? geometry.size.width*1/3: geometry.size.width - 76)
                            }
                        }
                        if editing_state_url != "None" || editing_state_google != "None" {
                            Spacer().frame(width:69)
                        }
                        
                    }
                    Spacer()
                }
            }
        }.overlay(
            ZStack {
                if editing_state_google != "None" || editing_state_url != "None" {
                    VStack {
                        Spacer()
                    HStack {
                        Spacer()
                        Button(action:{hideKeyboard()}) {
                            ZStack {
                                Text("Cancel").font(.custom("Helvetica Neue Bold", size: 13.25)).foregroundColor(.white).shadow(color: Color.black.opacity(0.75), radius: 1, x: 0, y: -0.25)
                            }.frame(width: 59, height: 32).ps_innerShadow(.roundedRectangle(5.5, cancel_gradient), radius:0.8, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                            .padding(.trailing, 12)
                        }.frame(width: 59, height: 32).padding(.top, 34)
                    }
                    }.transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                }
            })
    }
}

struct url_search_bar: View {
    @Binding var url_search: String
    @Binding var editing_state_url: String
    @Binding var progress: Double
    var webViewStore: WebViewStore
    private let gradient = LinearGradient([.white, .white], to: .trailing)
    private let cancel_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        HStack {
            Spacer(minLength: 5)
            HStack (alignment: .center,
                    spacing: 10) {
                
                TextField ("", text: $url_search, onEditingChanged: { (changed) in
                    if changed  {
                        withAnimation() {
                            if url_search.count == 0 {
                            editing_state_url = "Active_Empty"
                            } else {
                                editing_state_url = "Active"
                            }
                        }
                    } else {
                        withAnimation() {
                            editing_state_url = "None"
                        }
                    }
                }) {
                    //print(url_search, "here 0")
                    if url_search.hasPrefix("https://") || url_search.hasPrefix("http://") {
                        guard let url = URL(string: "\(url_search)") else { return }
                     //   print("here 1")
                        self.webViewStore.webView.load(URLRequest(url: url))
                        url_search = self.webViewStore.webView.url?.relativeString ?? ""
                    } else if url_search.contains("www") {
                        guard let url = URL(string: "https://\(url_search)") else { return }
                       // print("here 2")
                        self.webViewStore.webView.load(URLRequest(url: url))
                        url_search = self.webViewStore.webView.url?.relativeString ?? ""
                    } else {
                        guard let url = URL(string: "https://\(url_search)") else { return }
                      //  print("here 3")
                        self.webViewStore.webView.load(URLRequest(url: url))
                        url_search =  self.webViewStore.webView.url?.relativeString ?? ""
                        //searchTextOnGoogle(urlString)
                    }
                    withAnimation() {
                        editing_state_url = "None"
                    }
                }.keyboardType(.URL).disableAutocorrection(true).autocapitalization(.none).foregroundColor(editing_state_url == "None" ? Color(red: 102/255, green: 102/255, blue: 102/255) : Color.black)
                if editing_state_url == "Active",  url_search.count != 0 {
                    Button(action:{url_search = ""}) {
                        Image("UITextFieldClearButton")
                    }.fixedSize()
                }
                if editing_state_url == "None" {
                    Button(action:{webViewStore.webView.reload()}) {
                        Image("AddressViewReload")
                    }
                }
            }
            
            .padding([.top,.bottom], 5)
            .padding(.leading, 5)
            .cornerRadius(6)
            Spacer(minLength: 8)
        } .ps_innerShadow(.roundedRectangle(6, LinearGradient([(color: Color.clear, location: progress != 1 ? progress : 0), (color: .white, progress != 1 ? progress : 0)], from: .leading, to: .trailing)), radius:1.8, offset: CGPoint(0, 1), intensity: 0.5).strokeRoundedRectangle(6, Color(red: 84/255, green: 108/255, blue: 138/255), lineWidth: 0.65).padding(.leading, 2.5).padding(.trailing, 1).onReceive(webViewStore.objectWillChange) {_ in
            progress = webViewStore.webView.estimatedProgress
        }
    }
}
extension View {
    public func introspectTextField2(customize: @escaping (UITextField) -> ()) -> some View {
        return inject(UIKitIntrospectionView(
            selector: { introspectionView in
                guard let viewHost = Introspect.findViewHost(from: introspectionView) else {
                    return nil
                }
                return Introspect.previousSibling(containing: UITextField.self, from: viewHost)
            },
            customize: customize
        ))
    }
}

struct google_search_bar: View {
    @Binding var google_search: String
    @Binding var url_search: String
    @Binding var editing_state_google: String
    var webViewStore: WebViewStore
    private let gradient = LinearGradient([.white, .white], to: .trailing)
    private let cancel_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        HStack {
            Spacer(minLength: 5)
            HStack (alignment: .center,
                    spacing: 10) {
                TextField ("Google", text: $google_search, onEditingChanged: { (changed) in
                    if changed  {
                        withAnimation() {
                            if editing_state_google.isEmpty {
                                editing_state_google = "Active_Empty"
                            } else {
                                editing_state_google = "Active"
                            }
                        }
                    } else {
                        withAnimation() {
                            editing_state_google = "None"
                        }
                    }
                }) {
                    let link = google_search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                    guard let url = URL(string: "https://google.com/search?q=\(String(link ?? ""))") else { return }
                    self.webViewStore.webView.load(URLRequest(url:url))
                    url_search =  self.webViewStore.webView.url?.relativeString ?? ""
                    google_search = ""
                    withAnimation() {
                        editing_state_google = "None"
                    }
                }.keyboardType(.alphabet).disableAutocorrection(true)
                if google_search.count != 0, editing_state_google == "Active" {
                    Button(action:{google_search = ""}) {
                        Image("UITextFieldClearButton")
                    }.fixedSize()
                }
            }
            
            .padding([.top,.bottom], 5)
            .padding(.leading, 5)
            .cornerRadius(40)
            Spacer(minLength: 8)
        } .ps_innerShadow(.capsule(gradient), radius:1.8, offset: CGPoint(0, 1), intensity: 0.6).strokeCapsule(Color(red: 84/255, green: 108/255, blue: 138/255), lineWidth: 0.65).padding(.leading, 1).padding(.trailing, 2.5)
    }
}

//
//struct Safari_Previews: PreviewProvider {
//    static var previews: some View {
//        Safari()
//    }
//}
//
//
