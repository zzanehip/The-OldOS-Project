//
//  Stocks.swift
//  OldOS
//
//  Created by Zane Kleinberg on 5/15/21.
//

import SwiftUI

struct Stocks: View {
    @ObservedObject var stocks_observer = StocksObserver()
    @State var items = UserDefaults.standard.object(forKey: "stocks") as? [String]
    @State var selected_stock: stock?
    @State var show_settings:Bool = false
    @State var switch_to_settings: Bool = false
    @State var hide_stocks: Bool = false
    init() {
        for item in items ?? [] {
            stocks_observer.fetch_stocks(ticker: item, completion: { })
        }
        stocks_observer.stocks.sort(by: {$0.current_stock_data.symbol ?? "" < $1.current_stock_data.symbol ?? ""})
        
    }
    var body: some View {
        VStack(spacing: 0) {
            status_bar().background(Color.black).frame(minHeight: 24, maxHeight:24).zIndex(1)
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                stocks_settings(show_settings: $show_settings, switch_to_settings: $switch_to_settings, stocks_observer: stocks_observer).frame(width:geometry.size.width, height:geometry.size.height).rotation3DEffect(.degrees(show_settings == false ? 90 : 0), axis: (x: 0, y:1, z: 0), anchor: UnitPoint(0, 0.5)).offset(x:show_settings == false ? geometry.size.width/2 : 0).opacity(show_settings == false ? 0: 1)
                VStack {
                    Spacer().frame(height: 2)
                    stocks_header(stocks_observer: stocks_observer, items: $items, selected_stock: $selected_stock).frame(width: geometry.size.width - 12, height: geometry.size.height*2/3 - 7).cornerRadius(12)
                    Spacer().frame(height: 10)
                    stocks_footer(show_settings: $show_settings, switch_to_settings: $switch_to_settings, hide_stocks: $hide_stocks, company_name: "\(selected_stock?.current_stock_data.companyName ?? "")", open: "\(selected_stock?.current_stock_data.iexOpen ?? Double(0))", mkt_cap: suffixNumber(number: Double(selected_stock?.current_stock_data.marketCap ?? Int(0))), high: "\(selected_stock?.current_stock_data.high ?? Double(0))", f_high: "\(selected_stock?.current_stock_data.week52High ?? Double(0))", low: "\(selected_stock?.current_stock_data.low ?? Double(0))", f_low: "\(selected_stock?.current_stock_data.week52Low ?? Double(0))", vol: suffixNumber(number: Double(selected_stock?.current_stock_data.volume ?? Int(0))), avg_vol: suffixNumber(number: Double(selected_stock?.current_stock_data.volume ?? Int(0))), pe: "\(selected_stock?.current_stock_data.peRatio ?? Double(0))", yield: "—").frame(width: geometry.size.width - 12, height: geometry.size.height*1/3 - 7).cornerRadius(12)
                    Spacer().frame(height: 2)
                }.rotation3DEffect(.degrees(switch_to_settings == true ? -90 : 0), axis: (x: 0, y:1, z: 0), anchor: UnitPoint(1, 0.5)).offset(x:switch_to_settings == true ? -geometry.size.width/2 : 0).opacity(switch_to_settings == true ? 0 : 1).isHidden(hide_stocks)
            }
        }
        }.onAppear() {
            UIScrollView.appearance().bounces = true
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
        }.onChange(of: stocks_observer.stocks, perform: { value in
            if let idx = stocks_observer.stocks.firstIndex(where: {$0.current_stock_data.symbol == items?.first}) {
            selected_stock = stocks_observer.stocks[idx]
            }
        }).onChange(of: show_settings, perform: {_ in
            if show_settings == false {
                UIScrollView.appearance().bounces = true
            } else {
                UIScrollView.appearance().bounces = false
            }
        })
    }
}

struct stock: Identifiable, Equatable {
    let id = UUID()
    var current_stock_data: CurrentStockData
    static func == (lhs: stock, rhs: stock) -> Bool {
        return lhs.id == rhs.id
    }
}

class StocksObserver: ObservableObject {
    @Published var stocks = [stock]()
    func fetch_stocks(ticker: String, completion: @escaping (() -> Void)) {
            self.parse_current_stock_data(ticker: ticker, completion: { current_data in
                self.stocks.append(stock(current_stock_data: current_data))
                completion()
            })
    }

    func parse_current_stock_data(ticker: String, completion: @escaping ((CurrentStockData) -> Void)) {
        let developed_string = "https://cloud.iexapis.com/stable/stock/\(ticker)/quote?token=pk_5e28c8ffa36d4d3d87d10a5dd9373b9b"
        let forcast_url = URL(string: developed_string)!
        let request = URLRequest(url: forcast_url)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            
            if let error = error {
                print(error)
                return
            }
            
            // Parse JSON data
            if let data = data {
                let decoder = JSONDecoder()
                
                do {
                    let loanDataStore = try decoder.decode(CurrentStockData.self, from: data)
                    DispatchQueue.main.async {
                        completion(loanDataStore)
                    }
                    
                } catch {
                    print(error)
                }
            }
        })
        
        task.resume()
    }
}

struct stocks_settings_title_bar : View {
    public var done_action: (() -> Void)?
    public var new_action: (() -> Void)?
    var show_done: Bool?
    var body :some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.02), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025).opacity(0.8)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("Stocks").ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", size: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1)
                    Spacer()
                }
                Spacer()
            }
            if show_done == true {
            HStack {
                tool_bar_rectangle_button_background_image_weather(action:{new_action?()}, button_type: .blue_gray, content: "UIButtonBarPlus", use_image: true).padding(.leading, 8)
                Spacer()
            tool_bar_rectangle_button(action: {done_action?()}, button_type: .blue, content: "Done").padding(.trailing, 8)
            }
            }
        }
    }
}


struct stocks_settings: View {
    @State var to_delete: UUID = UUID()
    @State var selected_segment: Int = (UserDefaults.standard.object(forKey: "stock_mode") as? String ?? "Price" == "Price" ? 1 : (UserDefaults.standard.object(forKey: "stock_mode") as? String ?? "Price" == "%" ? 0 : 2))
    @State var show_add_location: Bool = false
    @State var will_delete:Bool = false
    @Binding var show_settings: Bool
    @Binding var switch_to_settings: Bool
    @ObservedObject var stocks_observer = StocksObserver()
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("Weather_Settings_BackgroundTile").resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .tile).frame(width:geometry.size.width, height: geometry.size.height)
                VStack {
                    stocks_settings_title_bar(done_action: {
                        withAnimation(.easeIn(duration: 0.4)){
                            show_settings.toggle()}
                        DispatchQueue.main.asyncAfter(deadline:.now()+0.39) {
                            withAnimation(.easeOut(duration: 0.4)){switch_to_settings.toggle()}
                        }
                        
                    }, new_action: {withAnimation(){show_add_location.toggle()}}, show_done: true).frame(height: 60)
                    Spacer().frame(height: 15)
                    
                    ScrollView {
                    ZStack {
                        
                        VStack(spacing: 0) {
                            ForEach(stocks_observer.stocks, id: \.id) { index in
                                VStack(alignment: .leading, spacing: 0) {
                                        Color.white.frame(height: 44-0.95)
                                    Rectangle().fill(will_delete == true ? Color.white : Color.black).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                    
                                }
                                
                            }.frame(height: 44).animationsDisabled()
                            Color.white.animationsDisabled()
                        }
                        
                        
                    NoSepratorList_NonLazy {
                        ForEach(stocks_observer.stocks, id: \.id) { index in
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(alignment: .center) {
                                    Spacer().frame(width:1, height: 44-0.95)
                                    if stocks_observer.stocks.count > 1 {
                                    Button(action:{
                                        withAnimation(.linear(duration:0.15)) {
                                            if to_delete != index.id {
                                                to_delete = index.id
                                            } else {
                                                to_delete = UUID()
                                            }
                                        }
                                    }) {
                                        ZStack {
                                            Image("UIRemoveControlMinus")
                                            Text("—").foregroundColor(.white).font(.system(size: 15, weight: .heavy, design: .default)).offset(y:to_delete == index.id ? -0.8 : -2).rotationEffect(.degrees(to_delete == index.id ? -90 : 0), anchor: .center).offset(y:to_delete == index.id ? -0.5 : 0)
                                        }
                                    }.transition(AnyTransition.asymmetric(insertion: .move(edge:.leading), removal: .move(edge:.leading)).combined(with: .opacity)).offset(x:-4)
                                }
                                    VStack(alignment: .leading, spacing: 1) {
                                    Text(index.current_stock_data.symbol ?? "").font(.custom("Helvetica Neue Bold", size: 18)).foregroundColor(.black).lineLimit(1)
                                        Text(index.current_stock_data.companyName ?? "").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1).fixedSize()
                                    }
                                    ZStack {
                                        HStack {
                                            Spacer()
                                            Image("UITableGrabber").padding(.trailing, 12)
                                        }
                                        HStack {
                                            Spacer()
                                            if to_delete == index.id, stocks_observer.stocks.count > 1 {
                                                tool_bar_rectangle_button(action: {will_delete = true; withAnimation() {
                                                }
                                                
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    will_delete = false //Set the background back
                                                }
                                                }, button_type: .red, content: "Delete").padding(.trailing, 12).transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge:.trailing)).combined(with: .opacity))
                                            }
                                        }
                                    }
                                }.padding([.leading], 8)
                                Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                
                            }
                            
                        }.frame(height: 44)
                    
                    }
                    }.cornerRadius(12)
                    }.cornerRadius(12).padding([.leading, .trailing], 12)
                    Spacer().frame(height: 15)
                    tri_control_big_bluegray_no_stroke(selected: $selected_segment, first_text: "%", second_text: "Price", third_text: "Mkt Cap").frame(width: geometry.size.width-24, height: 45)
                    Spacer().frame(height: 15)
                    Image("YahooFinance")
                    Spacer().frame(height: 15)
                }
            }
        }.onChange(of: selected_segment, perform: {_ in
            let userDefaults = UserDefaults.standard
            if selected_segment == 0 {
                userDefaults.setValue("%", forKey: "stock_mode")
            }
            if selected_segment == 1 {
                userDefaults.setValue("Price", forKey: "stock_mode")
            }
            if selected_segment == 2 {
                userDefaults.setValue("Mkt Cap", forKey: "stock_mode")
            }
        })
    }
}

struct stocks_header: View {
    @ObservedObject var stocks_observer: StocksObserver
    @State var stock_mode = UserDefaults.standard.object(forKey: "stock_mode") as? String
    @Binding var items: [String]?
    @State var selected: Int = 0
    @State var overflow_quantity: Int = 0
    @Binding var selected_stock: stock?
    var horizontalSpacing: CGFloat = 10
    var body: some View {
        ZStack {
            GeometryReader{ geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(stocks_observer.stocks, id:\.id) { stock in
                            Button(action: {
                                selected_stock = stock
                            }) {
                            ZStack {
                                if (stocks_observer.stocks.firstIndex(of: stock) ?? 0) % 2 == 0 {
                                    Color(red: 171/255, green: 178/255, blue: 197/255).edgesIgnoringSafeArea(.all)
                                } else {
                                    Color(red: 140/255, green: 158/255, blue: 191/255).edgesIgnoringSafeArea(.all)
                                }
                                Path { path in

                                    let numberOfVerticalGridLines = Int((geometry.size.width) / self.horizontalSpacing)
                                    for index in 0...numberOfVerticalGridLines {
                                        let vOffset: CGFloat = CGFloat(index) * self.horizontalSpacing
                                        path.move(to: CGPoint(x: vOffset, y: 0))
                                        path.addLine(to: CGPoint(x: vOffset, y: 50))
                                    }

                                }
                                .stroke(Color.white.opacity(0.1), lineWidth: 2)
                                ZStack {
                                    if selected_stock == stock {
                                        Rectangle().fill(LinearGradient([(Color(red: 90/255, green: 107/255, blue: 135/255), location: 0), (Color(red: 35/255, green: 54/255, blue: 90/255), location: 0.5), (Color(red: 12/255, green: 26/255, blue: 54/255), location: 0.5), (Color(red: 12/255, green: 26/255, blue: 54/255), location: 1)], from: .top, to: .bottom)).frame(height: 50)
                                    }
                                } //This nested in a ZStack is not by choice, its to silence unable to type check
                                HStack(spacing: 0){
                                    Text("\(stock.current_stock_data.symbol ?? "")").font(.custom("Helvetica Neue Bold", size: 20)).textCase(.uppercase).foregroundColor(.white).shadow(color: Color.black.opacity(0.8), radius: 0.25, x: 0, y: -2/3).padding(.leading, 8)
                                    Spacer()
                                    Text("\(String(format: "%.2f", stock.current_stock_data.latestPrice ?? Double(0)))").font(.custom("Helvetica Neue Bold", size: 20)).textCase(.uppercase).foregroundColor(.white).shadow(color: Color.black.opacity(0.8), radius: 0.25, x: 0, y: -2/3).padding(.trailing, 8)
                                    
                                    stock_delta_capsule(content: "\(String((stock_mode ?? "Price") == "Price" ? String(format: "%.2f", stock.current_stock_data.change ?? Double(0)) : (stock_mode ?? "Price") == "%" ?                      "\(String(format: "%.2f", (stock.current_stock_data.changePercent ?? Double(0))*100))%" : suffixNumber(number: Double(selected_stock?.current_stock_data.marketCap ?? Int(0)))).replacingOccurrences(of: "-", with: ""))", color_indicator: String(format: "%.2f", stock.current_stock_data.change ?? Double(0)).contains("-") ? "red" : "green").frame(width: 87, height: 35).padding(.trailing, 8)
                                }
                            }.frame(height: 50)
                        }
                        }
                        if CGFloat((items?.count ?? 1)*50) < geometry.size.height {
                            ForEach(0..<overflow_quantity) { idx in
                                ZStack {
                                    if idx % 2 == 0 {
                                        Color(red: 171/255, green: 178/255, blue: 197/255).edgesIgnoringSafeArea(.all)
                                    } else {
                                        Color(red: 140/255, green: 158/255, blue: 191/255).edgesIgnoringSafeArea(.all)
                                    }
                                    Path { path in
                                        
                                        let numberOfVerticalGridLines = Int((geometry.size.width) / self.horizontalSpacing)
                                        for index in 0...numberOfVerticalGridLines {
                                            let vOffset: CGFloat = CGFloat(index) * self.horizontalSpacing
                                            path.move(to: CGPoint(x: vOffset, y: 0))
                                            path.addLine(to: CGPoint(x: vOffset, y: 50))
                                        }
                                        
                                    }
                                    .stroke(Color.white.opacity(0.1), lineWidth: 2)
                                }.frame(height: 50)
                            
                            }.id(overflow_quantity)
                        }
                    }.cornerRadius(12)
                }.onChange(of: items, perform: { value in
                    if (items?.count ?? 1) != 0 {
                overflow_quantity = Int(geometry.size.height/CGFloat((items?.count ?? 1)*30))
                    }
                }).onAppear() {
                    if (items?.count ?? 1) != 0 {
                overflow_quantity = Int(geometry.size.height/CGFloat((items?.count ?? 1)*30))
                    }
                }
            }
        }
    }
}


struct stock_delta_capsule: View {
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
                    Text(content).font(.custom("Helvetica Neue Bold", size: 20)).textCase(.uppercase).multilineTextAlignment(.trailing).foregroundColor(.white).shadow(color: Color.black.opacity(0.8), radius: 0.25, x: 0, y: -2/3).padding(.trailing, 5).minimumScaleFactor(0.5).lineLimit(0)
                }.frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

struct stocks_footer: View {
    @Binding var show_settings:Bool
    @Binding var switch_to_settings: Bool
    @Binding var hide_stocks: Bool
    var company_name: String
    var open: String
    var mkt_cap: String
    var high: String
    var f_high: String
    var low: String
    var f_low: String
    var vol: String
    var avg_vol: String
    var pe: String
    var yield: String
    var body: some View {
        ZStack {
            GeometryReader{ geometry in
                ZStack {
                    VStack(spacing: 0) {
                    Rectangle().fill(LinearGradient([(Color(red: 59/255, green: 73/255, blue: 112/255), location: 0), (Color(red: 28/255, green: 44/255, blue: 89/255), location: 0.5), (Color(red: 19/255, green: 34/255, blue: 82/255), location: 0.5), (Color(red: 19/255, green: 34/255, blue: 82/255), location: 1)], from: .top, to: .bottom))
                        Rectangle().fill(LinearGradient([(Color(red: 90/255, green: 107/255, blue: 135/255), location: 0), (Color(red: 35/255, green: 54/255, blue: 90/255), location: 0.5), (Color(red: 12/255, green: 26/255, blue: 54/255), location: 0.5), (Color(red: 12/255, green: 26/255, blue: 54/255), location: 1)], from: .top, to: .bottom)).frame(height: 45).overlay(HStack {
                            Image("ViewStockButton").padding(.leading, 8)
                            Spacer()
                            Button(action: {
                                withAnimation(.easeIn(duration: 0.4)){
                                    withAnimation(.easeIn(duration: 0.4)){switch_to_settings.toggle()}
                                    DispatchQueue.main.asyncAfter(deadline:.now()+0.4) { //maybe 0.45
                                        withAnimation(.easeOut(duration: 0.4)){show_settings.toggle()}
                                    }
                                }
                            }) {
                            Image("InfoButton").padding(.trailing, 8)
                            }
                        })
                    }
                    VStack(spacing: 0) {
                        Text("\(company_name)").font(.custom("Helvetica Neue Bold", size: 18)).foregroundColor(.white)
                        stocks_footer_grid(geometry: geometry, open: open, mkt_cap: mkt_cap, high: high, f_high: f_high, low: low, f_low: f_low, vol: vol, avg_vol: avg_vol, pe: pe, yield: yield)
                    }.padding(.bottom, 45)
                }
            }
        }
    }
}
//Thx stackoverflow
func suffixNumber(number:Double) -> String {

    var num:Double = number
    let sign = ((num < 0) ? "-" : "" )

    num = fabs(num);

    if (num < 1000.0){
        return "\(sign)\(num)"
    }

    let exp:Int = Int(log10(num) / 3.0 ); //log10(1000));

    let units:[String] = ["K","M","B","T","P","E"]

    let roundedNum:Double = round(10 * num / pow(1000.0,Double(exp))) / 10

    return "\(sign)\(roundedNum)\(units[exp-1])"
}

struct stocks_footer_grid: View {
    var geometry: GeometryProxy
    var open: String
    var mkt_cap: String
    var high: String
    var f_high: String
    var low: String
    var f_low: String
    var vol: String
    var avg_vol: String
    var pe: String
    var yield: String
    var body: some View {
        GeometryReader{ proxy in
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                
                HStack(spacing: 0) {
                    Text("Open:").font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white)
                    Spacer()
                }.frame(width: geometry.size.width/2 - 20).padding(.leading, 20).overlay(
                    HStack {
                        Text(open).font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white).padding(.leading, 60)
                        Spacer()
                    }.frame(width: geometry.size.width/2 - 20).padding(.leading, 20)
                )
                
                HStack(spacing: 0) {
                    Text("Mkt Cap:").font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white)
                    Spacer()
                }.frame(width: geometry.size.width/2 - 20).padding(.trailing, 20).overlay(
                    HStack {
                        Text(mkt_cap).font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white).padding(.leading, 80)
                        Spacer()
                    }.frame(width: geometry.size.width/2 - 20).padding(.trailing, 20)
                )
                
                
            }.frame(height: proxy.size.height/5 - 2)
            Rectangle().fill(Color.white.opacity(0.25)).frame(width: geometry.size.width, height: 2)
            HStack(spacing: 0) {
                
                HStack(spacing: 0) {
                    Text("High:").font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white)
                    Spacer()
                }.frame(width: geometry.size.width/2 - 20).padding(.leading, 20).overlay(
                    HStack {
                        Text(high).font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white).padding(.leading, 60)
                        Spacer()
                    }.frame(width: geometry.size.width/2 - 20).padding(.leading, 20)
                )
                
                HStack(spacing: 0) {
                    Text("52w High:").font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white)
                    Spacer()
                }.frame(width: geometry.size.width/2 - 20).padding(.trailing, 20).overlay(
                    HStack {
                        Text(f_high).font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white).padding(.leading, 80)
                        Spacer()
                    }.frame(width: geometry.size.width/2 - 20).padding(.trailing, 20)
                )
                
            }.frame(height: proxy.size.height/5 - 2)
            Rectangle().fill(Color.white.opacity(0.25)).frame(width: geometry.size.width, height: 2)
            HStack(spacing: 0) {
                
                HStack(spacing: 0) {
                    Text("Low:").font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white)
                    Spacer()
                }.frame(width: geometry.size.width/2 - 20).padding(.leading, 20).overlay(
                    HStack {
                        Text(low).font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white).padding(.leading, 60)
                        Spacer()
                    }.frame(width: geometry.size.width/2 - 20).padding(.leading, 20)
                )
                
                HStack(spacing: 0) {
                    Text("52w Low:").font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white)
                    Spacer()
                }.frame(width: geometry.size.width/2 - 20).padding(.trailing, 20).overlay(
                    HStack {
                        Text(f_low).font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white).padding(.leading, 80)
                        Spacer()
                    }.frame(width: geometry.size.width/2 - 20).padding(.trailing, 20)
                )
                
            }.frame(height: proxy.size.height/5 - 2)
            Rectangle().fill(Color.white.opacity(0.25)).frame(width: geometry.size.width, height: 2)
            HStack(spacing: 0) {
                
                HStack(spacing: 0) {
                    Text("Vol:").font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white)
                    Spacer()
                }.frame(width: geometry.size.width/2 - 20).padding(.leading, 20).overlay(
                    HStack {
                        Text(vol).font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white).padding(.leading, 60)
                        Spacer()
                    }.frame(width: geometry.size.width/2 - 20).padding(.leading, 20)
                )
                
                HStack(spacing: 0) {
                    Text("Avg Vol:").font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white)
                    Spacer()
                }.frame(width: geometry.size.width/2 - 20).padding(.trailing, 20).overlay(
                    HStack {
                        Text(avg_vol).font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white).padding(.leading, 80)
                        Spacer()
                    }.frame(width: geometry.size.width/2 - 20).padding(.trailing, 20)
                )
                
            }.frame(height: proxy.size.height/5 - 2)
            Rectangle().fill(Color.white.opacity(0.25)).frame(width: geometry.size.width, height: 2)
            HStack(spacing: 0) {
                
                HStack(spacing: 0) {
                    Text("P/E:").font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white)
                    Spacer()
                }.frame(width: geometry.size.width/2 - 20).padding(.leading, 20).overlay(
                    HStack {
                        Text(pe).font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white).padding(.leading, 60)
                        Spacer()
                    }.frame(width: geometry.size.width/2 - 20).padding(.leading, 20)
                )
                
                HStack(spacing: 0) {
                    Text("Yield:").font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white)
                    Spacer()
                }.frame(width: geometry.size.width/2 - 20).padding(.trailing, 20).overlay(
                    HStack {
                        Text(yield).font(.custom("Helvetica Neue Bold", size: 15)).foregroundColor(.white).padding(.leading, 80)
                        Spacer()
                    }.frame(width: geometry.size.width/2 - 20).padding(.trailing, 20)
                )
                
            }.frame(height: proxy.size.height/5 - 2)
            }
        }
    }
}

struct Stocks_Previews: PreviewProvider {
    static var previews: some View {
        Stocks()
    }
}


struct CurrentStockData: Codable {
  let symbol: String?
  let companyName: String?
  let primaryExchange: String?
  let calculationPrice: String?
  let `open`: Double?
  let openTime: Date?
  let openSource: String?
  let close: Double?
  let closeTime: Date?
  let closeSource: String?
  let high: Double?
  let highTime: Date?
  let highSource: String?
  let low: Double?
  let lowTime: Date?
  let lowSource: String?
  let latestPrice: Double?
  let latestSource: String?
  let latestTime: String?
  let latestUpdate: Date?
  let latestVolume: Int?
  let delayedPrice: Double?
  let delayedPriceTime: Date?
  let oddLotDelayedPrice: Double?
  let oddLotDelayedPriceTime: Date?
  let extendedPrice: Double?
  let extendedChange: Double?
  let extendedChangePercent: Double?
  let extendedPriceTime: Date?
  let previousClose: Double?
  let previousVolume: Int?
  let change: Double?
  let changePercent: Double?
  let volume: Int?
  let avgTotalVolume: Int?
  let iexOpen: Double?
  let iexOpenTime: Date?
  let iexClose: Double?
  let iexCloseTime: Date?
  let marketCap: Int?
  let peRatio: Double?
  let week52High: Double?
  let week52Low: Double?
  let ytdChange: Double?
  let lastTradeTime: Date?
  let isUSMarketOpen: Bool?
}
