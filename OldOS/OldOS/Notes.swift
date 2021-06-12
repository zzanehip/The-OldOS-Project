//
//  Notes.swift
//  OldOS
//
//  Created by Zane Kleinberg on 3/29/21.
//

import SwiftUI
import CoreData

struct Notes: View {
    @State var current_nav_view: String = "Main"
    @State var forward_or_backward: Bool = false
    @State var appear_or_disapear_animation: Bool = true
    @State var is_editing_note: Bool = false
    @State var added_note: Bool = false
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(
      entity: Note.entity(),
      sortDescriptors: [
        NSSortDescriptor(keyPath: \Note.creation_date, ascending: true)
      ]
    ) var notes: FetchedResults<Note>
    @State var selected_note: Note = Note()
    @ObservedObject var keyboard = KeyboardResponder()
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing:0) {
                    status_bar().background(Color.black).frame(minHeight: 24, maxHeight:24).zIndex(1)
                    notes_title_bar(title: current_nav_view == "Main" ? "Notes (\(notes.filter({$0.content != ""}).count))" : selected_note.title ?? "", back_action: {
                        is_editing_note = false; appear_or_disapear_animation = true; forward_or_backward = true;  withAnimation(.linear(duration: 0.28)) {current_nav_view = "Main"}
                    }, show_back: false, new_action: {
                        let note = Note(context: managedObjectContext)
                            note.title = ""
                            note.content = ""
                            note.creation_date = Date()
                            note.last_edited_date = Date()
                            selected_note = note
                            added_note = true
                        forward_or_backward = false; withAnimation(.linear(duration: 0.28)) {
                            current_nav_view = "Destination"
                        }
                    }, selectedTab: $current_nav_view, is_editing_note: $is_editing_note, forward_or_backward: $forward_or_backward).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 60, maxHeight:60).zIndex(1)
                    switch current_nav_view {
                    case "Main":
                        notes_main_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, selected_note: $selected_note, notes: notes).frame(width: geometry.size.width).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing))).clipped()
                    case "Destination":
                        notes_destination_view(content: selected_note.content ?? "", last_edited_date: selected_note.last_edited_date, appear_or_disapear_animation: $appear_or_disapear_animation, is_editing_note: $is_editing_note, selected_note: $selected_note, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, added_note: $added_note, keyboard: keyboard, notes: notes).frame(width: geometry.size.width).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing))).clipped()
                    default:
                        notes_main_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, selected_note: $selected_note, notes: notes).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    }
                }
            }.compositingGroup().clipped()
        }.onAppear() {
            UIScrollView.appearance().bounces = true
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
        }.onChange(of: keyboard.is_editing, perform: {_ in
            is_editing_note = keyboard.is_editing
        })

    }
    func saveContext() {
      do {
        try managedObjectContext.save()
      } catch {
        print("Error saving managed object context: \(error)")
      }
    }
    }

struct notes_main_view: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var selected_note: Note
    @Environment(\.managedObjectContext) var managedObjectContext
    var notes: FetchedResults<Note>
    static let long_format: DateFormatter = {
          let formatter = DateFormatter()
          formatter.dateFormat = "M/d/yy"
          return formatter
      }() //I've learned to love the Hacking With Swift way...recently
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    LazyVStack {
                        Spacer().frame(height: 5)
                        ForEach(notes.sorted(by: {($0.last_edited_date ?? Date()) > ($1.last_edited_date ?? Date())}).filter({$0.content != ""}), id:\.creation_date) {note in
                            Button(action: {
                                selected_note = note; forward_or_backward = false; withAnimation(.linear(duration: 0.28)) {                        current_nav_view = "Destination"}
                            }) {
                                VStack(spacing: 0) {
                                    Spacer()
                                    HStack {
                                        Text(note.title ?? "").font(.custom("Noteworthy-Bold", size: 18)).foregroundColor(Color(red: 160/255, green: 92/255, blue: 62/255)).padding(.leading, 12)
                                        Spacer()
                                        Text("\(note.last_edited_date ?? Date(), formatter: Self.long_format)").font(.custom("Helvetica Neue Regular", size: 14)).foregroundColor(Color(red: 99/255, green: 115/255, blue: 142/255)).padding(.trailing, 12)
                                        Image("UITableNext").padding(.trailing, 12)
                                    }
                                   Spacer()
                                Rectangle().fill(Color(red: 78/255, green: 90/255, blue: 130/255).opacity(0.3)).frame(width: geometry.size.width, height: 1)
                                }.frame(height: 44)
                            }
                        }
                    }
                }
            }.overlay(VStack {
                Image("NotesEdgeTop").resizable().scaledToFit().frame(width: geometry.size.width).clipped()
                Spacer()
                Image("NotesEdgeBottom").resizable().scaledToFit().frame(width: geometry.size.width).clipped()
            }).frame(width: geometry.size.width)
        }.background(Image("NotesBody").resizable().scaledToFill())
    }
    func saveContext() {
      do {
        try managedObjectContext.save()
      } catch {
        print("Error saving managed object context: \(error)")
      }
    }
}

struct notes_destination_view: View {
    @State var content: String = ""
    @State var last_edited_date: Date?
    @State var show_delete: Bool = false
    @Binding var appear_or_disapear_animation: Bool
    @Binding var is_editing_note: Bool
    @Binding var selected_note: Note
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var added_note: Bool
    @ObservedObject var keyboard: KeyboardResponder
    var notes: FetchedResults<Note>
    @Environment(\.managedObjectContext) var managedObjectContext
    var body: some View {
        GeometryReader { geometry in
            ZStack {
            VStack(spacing: 0) {
                MultilineTextView(text: $content, selected_note: $selected_note, last_edited_date: $last_edited_date, geometry: geometry).padding(.bottom, keyboard.currentHeight).edgesIgnoringSafeArea(.bottom).animation(appear_or_disapear_animation == false ? .easeOut(duration: 0.17) : .linear(duration: 0.28)).compositingGroup()
            }.overlay(VStack {
                Image("edgeTopMarginThin").resizable().scaledToFit().frame(width: geometry.size.width + 4).clipped()
                Spacer()
                Image("gradBottomMarginThin").resizable().scaledToFit().frame(width: geometry.size.width + 4).clipped()
            }).overlay(VStack {
                Spacer()
                HStack(spacing: 0) {
                    Spacer()
                    Button(action:{
                        if selected_note != notes.sorted(by: {($0.last_edited_date ?? Date()) > ($1.last_edited_date ?? Date())}).first {
                            if let index = notes.sorted(by: {($0.last_edited_date ?? Date()) > ($1.last_edited_date ?? Date())}).firstIndex(of: selected_note) {
                                print(index)
                            selected_note = notes.sorted(by: {($0.last_edited_date ?? Date()) > ($1.last_edited_date ?? Date())})[index - 1]
                                content = selected_note.content ?? ""
                            }
                        }
                    }) {
                        Image("arrow left").opacity(selected_note != notes.sorted(by: {($0.last_edited_date ?? Date()) > ($1.last_edited_date ?? Date())}).first ? 1 : 0.5)
                    }
                    Spacer()
                    Button(action:{}) {
                        Image("email")
                    }
                    Spacer()
                    Button(action:{
                        
                        withAnimation() {
                            show_delete.toggle()
                        }
                        
                    }) {
                        Image("trash")
                    }
                    Spacer()
                    Button(action:{
                        if selected_note != notes.sorted(by: {($0.last_edited_date ?? Date()) > ($1.last_edited_date ?? Date())}).last {
                            if let index = notes.sorted(by: {($0.last_edited_date ?? Date()) > ($1.last_edited_date ?? Date())}).firstIndex(of: selected_note) {
                                print(index)
                            selected_note = notes.sorted(by: {($0.last_edited_date ?? Date()) > ($1.last_edited_date ?? Date())})[index + 1]
                                content = selected_note.content ?? ""
                            }
                        }
                    }) {
                        Image("arrow right").opacity(selected_note != notes.sorted(by: {($0.last_edited_date ?? Date()) > ($1.last_edited_date ?? Date())}).last ? 1 : 0.5)
                    }
                    Spacer()
                }.padding(.bottom, 15)
            })
            ZStack {
                if show_delete == true {
                    Color.black.opacity(0.35)
                    VStack(spacing:0) {
                        Spacer().foregroundColor(.clear).zIndex(0)
                        delete_note_view(cancel_action: {withAnimation{show_delete.toggle()}}, delete_action: {withAnimation() {
                            do {
                                try managedObjectContext.delete(selected_note)
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)) {
                                    current_nav_view = "Main"
                                }
                                
                            } catch {
                                print("Error saving managed object context: \(error)")
                            }
                        }}).frame(minHeight: geometry.size.height*(1/3.6), maxHeight: geometry.size.height*(1/3.6))
                    }.transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom)))
               }//We nest this in a VStack to get around type check errors
                }.zIndex(3)
        }
        }.background(Image("bodyMarginThin-568h").resizable().scaledToFill()).onDisappear() {
            appear_or_disapear_animation = true
        }.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                appear_or_disapear_animation = false
            }
        }.onDisappear() {
            if content != "" {
            if content != selected_note.content {
                selected_note.content = content
                selected_note.last_edited_date = Date()
                selected_note.title = String(content.prefix(30).filter { !"\n".contains($0)})
                saveContext()
            }
            } else {
                do {
                    try managedObjectContext.delete(selected_note)
                } catch {
                    print("Error saving managed object context: \(error)")
                }
            }
        }.onChange(of: keyboard.is_editing, perform: {_ in
            if content != "" {
            if keyboard.is_editing == false {
                if content != selected_note.content {
                    selected_note.content = content
                    selected_note.last_edited_date = Date()
                    selected_note.title = String(content.prefix(30).filter { !"\n".contains($0)})
                    last_edited_date = Date()
                    saveContext()
                }
            }
            }
        }).onChange(of: selected_note, perform: {_ in
            if added_note == true {
            content = ""
                added_note = false
            }
        })
        
    }
    func saveContext() {
      do {
        try managedObjectContext.save()
      } catch {
        print("Error saving managed object context: \(error)")
      }
    }
}

struct delete_note_view: View {
    public var cancel_action: (() -> Void)?
    public var delete_action: (() -> Void)?
    private let background_gradient = LinearGradient(gradient: Gradient(colors: [Color.init(red: 70/255, green: 73/255, blue: 81/255), Color.init(red: 70/255, green: 73/255, blue: 81/255)]), startPoint: .top, endPoint: .bottom)
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                VStack(spacing:0) {
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 101/255, green: 100/255, blue: 100/255).opacity(0.88), Color.init(red: 31/255, green: 30/255, blue: 30/255).opacity(0.88)]), startPoint: .top, endPoint: .bottom)).innerShadowBottom(color: Color.white.opacity(0.98), radius: 0.1).border_top(width: 1, edges:[.top], color: Color.black).frame(height:30)
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 21/255, green: 20/255, blue: 20/255).opacity(0.88), Color.black.opacity(0.9)]), startPoint: .top, endPoint: .bottom))
                }.opacity(0.8)
                VStack {
                    Button(action:{
                        delete_action?()
                    }){
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5))
                            RoundedRectangle(cornerRadius: 9).fill(returnLinearGradient(.red)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.white.opacity(0.9), Color.white.opacity(0.25)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3)
                            Text("Delete Note").font(.custom("Helvetica Neue Bold", size: 18)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0.0, y: -0.6)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.bottom], 2.5).padding(.top, 28)
                    Spacer()
                    Button(action:{
                        cancel_action?()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 3/255, green: 3/255, blue: 3/255), Color.init(red: 21/255, green: 21/255, blue: 21/255), Color.init(red: 32/255, green: 32/255, blue: 32/255)]), startPoint: .top, endPoint: .bottom)).overlay(RoundedRectangle(cornerRadius: 12).stroke(LinearGradient(gradient: Gradient(colors:[Color.init(red: 83/255, green: 83/255, blue: 83/255),Color.init(red: 143/255, green: 143/255, blue: 143/255)]), startPoint: .top, endPoint: .bottom), lineWidth: 0.5)).opacity(0.6)
                            RoundedRectangle(cornerRadius: 9).fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 124/255, green: 124/255, blue: 124/255), location: 0), .init(color: Color(red: 26/255, green: 26/255, blue: 26/255), location: 0.50), .init(color: Color(red: 0/255, green: 0/255, blue: 0/255), location: 0.53), .init(color: Color(red: 0/255, green: 0/255, blue: 0/255), location: 1.0)]), startPoint: .top, endPoint: .bottom)).addBorder(LinearGradient(gradient: Gradient(colors:[Color.gray.opacity(0.9), Color.gray.opacity(0.35)]), startPoint: .top, endPoint: .bottom), width: 0.4, cornerRadius: 9).padding(3).opacity(0.6)
                            Text("Cancel").font(.custom("Helvetica Neue Bold", size: 18)).foregroundColor(Color.white).shadow(color: Color.black.opacity(0.9), radius: 0, x: 0.0, y: -0.9)
                        }.padding([.leading, .trailing], 25).frame(minHeight: 50, maxHeight:50)
                    }.padding([.bottom], 25)
                }
            }.drawingGroup()
        }
    }
}

extension StringProtocol where Index == String.Index {
    var partialRangeOfFirstLine: PartialRangeUpTo<String.Index> {
        return ..<(rangeOfCharacter(from: .newlines)?.lowerBound ?? endIndex)
    }
    var rangeOfFirstLine: Range<Index> {
        return startIndex..<partialRangeOfFirstLine.upperBound
    }
    var firstLine: SubSequence {
        return self[partialRangeOfFirstLine]
    }
}

final class KeyboardResponder: ObservableObject {
    @Published private(set) var currentHeight: CGFloat = 0
    @Published private(set) var keyboardAnimationDuration: Double = 0
    @Published private(set) var is_editing: Bool = false
    private var notificationCenter: NotificationCenter
    init(center: NotificationCenter = .default) {
       notificationCenter = center
       notificationCenter.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
       notificationCenter.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    deinit {
       notificationCenter.removeObserver(self)
    }
    @objc func keyBoardWillShow(notification: Notification) {
            is_editing = true
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                currentHeight = keyboardSize.height
                keyboardAnimationDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
            }
        }

        @objc func keyBoardWillHide(notification: Notification) {
            is_editing = false
            currentHeight = 0
        }
}


struct destination_header: View {
    @Binding var selected_note: Note
    @Binding var last_edited_date: Date?
    static let long_format: DateFormatter = {
          let formatter = DateFormatter()
          formatter.dateFormat = "MMM d  h:mm a"
          return formatter
      }() //I've learned to love the Hacking With Swift way...recently
    var body: some View {
        HStack {
            Text(numberOfDaysBetween(last_edited_date ?? Date(), Date()) == 0 ? "Today" : numberOfDaysBetween(last_edited_date ?? Date(), Date()) == 1 ? "1 day ago" : "\(numberOfDaysBetween(last_edited_date ?? Date(), Date())) days ago").font(.custom("Helvetica Neue Bold", size: 14)).foregroundColor(Color(red: 161/255, green: 93/255, blue: 68/255)).padding(.leading, 32)
            Spacer()
            Text(last_edited_date ?? Date(), formatter: Self.long_format).font(.custom("Helvetica Neue Regular", size: 14)).foregroundColor(Color(red: 161/255, green: 93/255, blue: 68/255)).padding(.trailing, 8)
        }.padding(.top, 10).padding(.bottom, 15).background(Color.clear)
    }
    func numberOfDaysBetween(_ start: Date, _ end: Date) -> Int {
         return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
     }
}

struct MultilineTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var selected_note: Note
    @Binding var last_edited_date: Date?
    var geometry: GeometryProxy?
    var view = DALinedTextView()
    func makeUIView(context: Context) -> DALinedTextView {
        view.isScrollEnabled = true
        view.isEditable = true
        view.isUserInteractionEnabled = true
        view.alwaysBounceVertical = true
        view.isUserInteractionEnabled = true
        view.isScrollEnabled = true
        view.backgroundColor = .clear
        view.font = UIFont(name: "Noteworthy-Bold", size: 19)
        view.delegate = context.coordinator
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.tintColor = UIColor(red: 113/255, green: 93/255, blue: 81/255, alpha: 1)
        let header_hosting_controller = UIHostingController(rootView: destination_header(selected_note: $selected_note, last_edited_date: $last_edited_date))
        view.addSubview(header_hosting_controller.view)
        header_hosting_controller.view.translatesAutoresizingMaskIntoConstraints = false
         let constraints = [
            header_hosting_controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            header_hosting_controller.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            header_hosting_controller.view.widthAnchor.constraint(equalTo: view.widthAnchor),
         ]
        
         NSLayoutConstraint.activate(constraints)
        header_hosting_controller.view.backgroundColor = UIColor.clear
        view.textContainerInset = UIEdgeInsets(40, 28, 30, 3)
        return view
    }

    func updateUIView(_ uiView: DALinedTextView, context: Context) {
        uiView.text = text
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MultilineTextView
        
        init(_ parent: MultilineTextView) {
            self.parent = parent
        }
        func textViewDidChange(_ textView: UITextView) {
                   print("text now: \(String(describing: textView.text!))")
                   self.parent.text = textView.text
            self.parent.selected_note.title = String(textView.text.prefix(30).filter { !"\n".contains($0)})
               }
    }
    
}

struct Notes_Previews: PreviewProvider {
    static var previews: some View {
        Notes()
    }
}

struct notes_title_bar : View {
    var title:String
    public var done_action: (() -> Void)?
    var show_done: Bool?
    public var back_action: (() -> Void)?
    var show_back: Bool?
    public var new_action: (() -> Void)?
    @Binding var selectedTab: String
    @Binding var is_editing_note: Bool
    @Binding var forward_or_backward: Bool
    var body :some View {
        ZStack {
            Image("NotesTopBar")
                .resizable()
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(title).ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", size: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)).combined(with: .opacity)).id(title).frame(maxWidth: selectedTab == "Destination" ? 200 : .infinity)
                    Spacer()
                }
                Spacer()
            }
            if selectedTab == "Destination" {
            VStack {
                Spacer()
                HStack {
                    Button(action:{back_action?()}) {
                    ZStack {
                        Image("NotesBack").frame(width: 55, height: 33).scaledToFill()
                        HStack(alignment: .center) {
                            Text("Notes").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", size: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                        }
                    }.padding(.leading, 5)
                    }
                    Spacer()
                }
                Spacer()
            }
            }
                HStack {
                    Spacer()
                    if !is_editing_note {
                        tool_bar_rectangle_button_background_image_notes(action:{new_action?()}, button_type: .blue_gray, content: "UIButtonBarPlus", use_image: true).padding(.trailing, 5)
                    } else {
                        tool_bar_rectangle_button_background_image_notes_text(action:{hideKeyboard()}, button_type: .blue_gray, content: "Done", use_image: true).padding(.trailing, 5)
                    }
                }
            
        }
    }
}

struct tool_bar_rectangle_button_background_image_notes: View {
    public var action: (() -> Void)?
    var button_type: tool_bar_button_type
    var content: String
    var use_image: Bool?
    private let gray_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    private let blue_gradient = LinearGradient([(color: Color(red: 120/255, green: 158/255, blue:237/255), location: 0), (color: Color(red: 55/255, green: 110/255, blue:224/255), location: 0.51), (color: Color(red: 34/255, green: 96/255, blue:221/255), location: 0.52), (color: Color(red: 36/255, green: 100/255, blue:224/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        Button(action:{action?()}) {
            ZStack {
                Image("header button").frame(width: 32, height: 32).scaledToFill()
                Image(content).resizable().scaledToFit().frame(width: 13).padding([.leading, .trailing], 11)
                
            }
        }.frame(width: 32, height: 32)
    }
}

struct tool_bar_rectangle_button_background_image_notes_text: View {
    public var action: (() -> Void)?
    var button_type: tool_bar_button_type
    var content: String
    var use_image: Bool?
    private let gray_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    private let blue_gradient = LinearGradient([(color: Color(red: 120/255, green: 158/255, blue:237/255), location: 0), (color: Color(red: 55/255, green: 110/255, blue:224/255), location: 0.51), (color: Color(red: 34/255, green: 96/255, blue:221/255), location: 0.52), (color: Color(red: 36/255, green: 100/255, blue:224/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        Button(action:{action?()}) {
            ZStack {
                Image("header button").frame(width: 60, height: 32).scaledToFill()
                Text(content).font(.custom("Helvetica Neue Bold", size: 13.25)).foregroundColor(.white).shadow(color: Color.black.opacity(0.75), radius: 1, x: 0, y: -0.25).lineLimit(0).padding([.leading, .trailing], 11)
                
            }
        }.frame(width: 60, height: 32)
    }
}


