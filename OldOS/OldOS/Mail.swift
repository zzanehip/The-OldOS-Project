//
//  Mail.swift
//  OldOS
//
//  Created by Zane Kleinberg on 2/28/21.
//

import SwiftUI
import OAuth2
import MailCore
import CoreData
import Combine
import WebKit
import Contacts
import SwiftKeychain
import SwiftKeychainWrapper

struct Mail: View {
    @EnvironmentObject var EmailManager: EmailManager
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if EmailManager.account_email != "" {
                    Mail_Main()
                } else {
                    mail_add_account_view().transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom)))
                }
            }
        }
    }
}

struct Mail_Main: View {
    @State var current_nav_view: String = "Main"
    @State var forward_or_backward: Bool = false
    @State var show_alert:Bool = false
    @State var increase_brightness: Bool = false
    @State var selected_message: MCOIMAPMessage = MCOIMAPMessage()
    @State var show_compose: Bool = false
    @State var show_move: Bool = false
    @State var current_contact: CNContact = CNContact()
    @State var selected_mailbox: mail_folder_item = mail_folder_item(name: "Inbox", image: "inmbox", path: "INBOX")
    @EnvironmentObject var EmailManager: EmailManager
    var content = [list_row(title: "", content: AnyView(mail_content(image: "exchange"))), list_row(title: "", content: AnyView(mail_content(image: "mobileme"))), list_row(title: "", content: AnyView(mail_content(image: "gmail"))), list_row(title: "", content: AnyView(mail_content(image: "yahoo"))), list_row(title: "", content: AnyView(mail_content(image: "aol"))),  list_row(title: "", content: AnyView(mail_content_other()))]
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing:0) {
                    status_bar_in_app().frame(minHeight: 24, maxHeight:24).zIndex(1)
                    mail_title_bar(title: current_nav_view == "Destination" ? "\((EmailManager.emails.reversed().firstIndex(of: selected_message) ?? 1) + 1) of \(EmailManager.emails.count)": current_nav_view == "Destination_Other" ? selected_mailbox.name: current_nav_view == "Mailboxes" ? "Mailboxes" : current_nav_view.contains("Contact") ? "Sender" : current_nav_view == "Other" ? selected_mailbox.name : "Inbox (\(EmailManager.emails.filter({!$0.flags.contains(.seen)}).count))", current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 60, maxHeight:60).zIndex(1)
                    switch current_nav_view {
                    case "Main":
                        mail_inbox_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, selected_message: $selected_message).clipped().transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing))).onAppear() {
                            UIScrollView.appearance().bounces = true
                        }
                    case "Other":
                        mail_other_mailbox_view(selected_mailbox: $selected_mailbox, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, selected_message: $selected_message).clipped().transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing))).onAppear() {
                            UIScrollView.appearance().bounces = true
                        }
                    case "Destination":
                        mail_body_view(message: selected_message, current_contact: $current_contact, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).clipped().transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing))).onAppear() {
                            UIScrollView.appearance().bounces = true
                        }//.zIndex(2)
                    case "Destination_Other":
                        mail_other_body_view(message: selected_message, current_contact: $current_contact, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, selected_mailbox: $selected_mailbox).clipped().transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing))).onAppear() {
                            UIScrollView.appearance().bounces = true
                        }//.zIndex(2)
                    case "Mailboxes":
                        mail_mailbox_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, selected_mailbox: $selected_mailbox).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing))).onAppear() {
                            UIScrollView.appearance().bounces = true
                        }
                    case "Contact":
                        mail_contact_view(current_contact: current_contact, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).frame(height: geometry.size.height - 84).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing))).onAppear() {
                            UIScrollView.appearance().bounces = true
                        }.zIndex(2)
                    case "Contact_Other":
                        mail_contact_view(current_contact: current_contact, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).frame(height: geometry.size.height - 84).transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing))).onAppear() {
                            UIScrollView.appearance().bounces = true
                        }.zIndex(2)
                    default:
                        mail_inbox_view(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, selected_message: $selected_message).clipped().transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing))).onAppear() {
                            UIScrollView.appearance().bounces = true
                        }
                    }
                    mail_tool_bar(current_nav_view: $current_nav_view, show_compose: $show_compose, show_move: $show_move, delete_action: {
                        if selected_mailbox.path != "[Gmail]/Trash" {
                            let uidSet = MCOIndexSet(range: MCORange(location: UInt64(selected_message.uid ?? 0), length: 0))
                            let move_operation: MCOIMAPMoveMessagesOperation = EmailManager.imap_session.moveMessagesOperation(withFolder: "INBOX", uids: uidSet, destFolder: "[Gmail]/Trash")
                            move_operation.start {(error, move) in
                                if let idx = EmailManager.emails.firstIndex(of: selected_message) {
                                    EmailManager.emails.remove(at: idx)
                                }
                            }
                        }
                    }, geometry: geometry).frame(height: 45).offset(y: current_nav_view.contains("Contact") ? -45 : 0)
                }
                if show_compose{
                    mail_compose_view(show_compose: $show_compose).transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom))).zIndex(1).clipped().compositingGroup()
                }
                if show_move {
                    mail_move_email(show_move: $show_move, selected_mailbox: $selected_mailbox, selected_message: $selected_message, current_nav_view: $current_nav_view).transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom))).zIndex(1).clipped().compositingGroup()
                }
            }.compositingGroup().clipped()
        }.onAppear() {
            UIScrollView.appearance().bounces = true
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
            if !EmailManager.emails.isEmpty {
                DispatchQueue.global(qos: .background).async {
                    
                    do {
                        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("emails")
                        let key_archive = try NSKeyedArchiver.archivedData(withRootObject: Array(EmailManager.emails.suffix(50)), requiringSecureCoding: false)
                        try key_archive.write(to: path)
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
}

//**MARK: Adding Mail Accounts

struct mail_add_account_view: View {
    @State var current_nav_view: String?
    @State var forward_or_backward: Bool?
    @State var show_add_account: Bool = false
    @EnvironmentObject var EmailManager: EmailManager
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
                                startExternalGoogleSignIn()
                            }
                            Spacer()
                        }
                    }
                }
            }.compositingGroup().clipped()
        }
    }
    func startExternalGoogleSignIn() {
        
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        let oauth2 = app.oauth2

        oauth2.authConfig.authorizeEmbedded = false
        oauth2.authConfig.ui.useSafariView = false
        oauth2.authConfig.authorizeContext = nil
        
        do {
            let url = try oauth2.authorizeURL(params: nil)
            
            print("AUTH URL:", url.absoluteString)
            DispatchQueue.main.async {
                    UIApplication.shared.open(url, options: [:]) { ok in
                        if !ok { print("UIApplication.open returned false") }
                    }
                }
            
        } catch {
            print("OAuth start error:", error)
        }

        oauth2.afterAuthorizeOrFail = { params, error in
            if let error = error {
                print("OAuth failed:", error)
                return
            }
            if let idToken = oauth2.idToken, let email = emailFromIDToken(idToken) {
                DispatchQueue.main.async {
                    EmailManager.account_email = email
                    EmailManager.do_initial_setup()
                }
            }
        }
    }
    
    func emailFromIDToken(_ idToken: String?) -> String? {
        guard let id = idToken else { return nil }
        let parts = id.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var s = String(parts[1])
        s = s.replacingOccurrences(of: "-", with: "+")
             .replacingOccurrences(of: "_", with: "/")
        while s.count % 4 != 0 { s.append("=") }

        guard let data = Data(base64Encoded: s),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let email = json["email"] as? String else { return nil }
        return email
    }
}

struct mail_move_email: View {
    @Binding var show_move: Bool
    @Binding var selected_mailbox: mail_folder_item
    @Binding var selected_message: MCOIMAPMessage
    @Binding var current_nav_view: String
    @EnvironmentObject var EmailManager: EmailManager
    var body: some View {
        GeometryReader{ geometry in
            VStack(spacing: 0) {
                Spacer().frame(height:24)
                double_text_title_bar(top_text:"Move this message to a new mailbox.", title: "Mailboxes", cancel_action: {
                    withAnimation(.linear(duration:0.35)) {
                        show_move = false
                    }
                }, show_cancel: true).frame(minHeight: 90, maxHeight: 90)
                ZStack {
                    NoSepratorList {
                        Spacer().frame(height: 85)
                        ForEach(EmailManager.folders, id:\.id) { item in
                            Button(action:{
                                if item.path != "INBOX" && item.path != "[Gmail]/Drafts" {
                                    move_email(item)
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 0) {
                                    HStack(alignment: .center) {
                                        Spacer().frame(width:1, height: 44-0.95)
                                        Image(item.image).frame(width:25, height: 44-0.95)
                                        Text(item.name).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(item.path == "INBOX" || item.path == "[Gmail]/Drafts" ? Color(red: 128/255, green: 128/255, blue: 128/255) : .black).lineLimit(1).padding(.leading, 6).padding(.trailing, 40)
                                        Spacer()
                                        if item.path == "INBOX" {
                                            Text("\(EmailManager.emails.filter({!$0.flags.contains(.seen)}).count)").font(.custom("Helvetica Neue Bold", fixedSize: 15.5)).foregroundColor(.white).padding([.top, .bottom], 4).padding([.leading, .trailing], 6).background(HStack(spacing: 0) {
                                                Image("unreadbubble_left")
                                                Image("unreadbubble_center").frame(height: 21)
                                                Image("unreadbubble_right")
                                            }.offset(y: 1)).padding(.trailing, 12)
                                        }
                                    }.padding(.leading, 15)
                                    Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                    
                                }
                            }
                        }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 44).drawingGroup()
                        
                    }.background(Color.white)
                    VStack(spacing: 0) {
                        ZStack {
                            Rectangle().fill(LinearGradient([(Color(red: 229/255, green: 231/255, blue: 233/255), location: 0), (Color(red: 185/255, green: 193/255, blue: 199/255), location: 0.5), (Color(red: 167/255, green: 177/255, blue: 186/255), location: 0.5), (Color(red: 198/255, green: 204/255, blue: 209/255), location: 1)], from: .top, to: .bottom)).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 85, maxHeight: 85).opacity(0.9)
                            HStack {
                                Image("envelope").padding(.leading, 6)
                                VStack(alignment: .leading) {
                                    Text("\(selected_message.header.sender.displayName ?? selected_message.header.sender.mailbox ?? "")").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(0).shadow(color: Color.white.opacity(0.8), radius: 0, x: 0.0, y: 0.9).padding(.trailing, 6)
                                    Spacer().frame(height: 2)
                                    Text(selected_message.header.subject ?? "" == "" ? "(No Subject)" : selected_message.header.subject ?? "").font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 69/255, green: 70/255, blue: 71/255)).lineLimit(0).shadow(color: Color.white.opacity(0.8), radius: 0, x: 0.0, y: 0.9).padding(.trailing, 6)
                                }
                                Spacer()
                            }
                        }.frame(minHeight: 85, maxHeight: 85)
                        Rectangle().fill(Color(red: 162/255, green: 165/255, blue: 170/255)).frame(width: geometry.size.width, height: 1)
                        Spacer()
                    }
                }
            }
        }
    }
    
    func move_email(_ to_folder: mail_folder_item) {
        let uidSet = MCOIndexSet(range: MCORange(location: UInt64(selected_message.uid ?? 0), length: 0))
        let move_operation: MCOIMAPMoveMessagesOperation = EmailManager.imap_session.moveMessagesOperation(withFolder: "INBOX", uids: uidSet, destFolder: to_folder.path)
        move_operation.start {(error, move) in
            if let idx = EmailManager.emails.firstIndex(of: selected_message) {
                current_nav_view = "Main"
                EmailManager.emails.remove(at: idx)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    if current_nav_view == "Main" {
                        withAnimation(.linear(duration:0.35)) {
                            show_move = false
                        }
                    }
                }
            }
        }
    }
}

struct mail_folder_item: Identifiable {
    let id = UUID()
    let name: String
    let image: String
    let path: String
}

struct mail_mailbox_view: View {
    @EnvironmentObject var EmailManager: EmailManager
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var selected_mailbox: mail_folder_item
    var items = [mail_folder_item(name: "Inbox", image: "inmbox", path: "INBOX"), mail_folder_item(name: "Drafts", image: "draftsmbox", path: "[Gmail]/Drafts"), mail_folder_item(name: "Sent Mail", image: "sentmbox", path: "[Gmail]/Sent Mail"), mail_folder_item(name: "Trash", image: "trashmbox", path: "[Gmail]/Trash")]
    var body: some View {
        NoSepratorList {
            ForEach(EmailManager.folders, id:\.id) { item in
                Button(action:{
                    selected_mailbox = item
                    if selected_mailbox.path == item.path {
                        forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = item.name == "Inbox" ? "Main" : "Other"}
                    }
                }) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .center) {
                            Spacer().frame(width:1, height: 44-0.95)
                            Image(item.image).frame(width:25, height: 44-0.95)
                            Text(item.name).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 6).padding(.trailing, 40)
                            Spacer()
                            if item.path == "INBOX" {
                                Text("\(EmailManager.emails.filter({!$0.flags.contains(.seen)}).count)").font(.custom("Helvetica Neue Bold", fixedSize: 15.5)).foregroundColor(.white).padding([.top, .bottom], 4).padding([.leading, .trailing], 6).background(HStack(spacing: 0) {
                                    Image("unreadbubble_left")
                                    Image("unreadbubble_center").frame(height: 21)
                                    Image("unreadbubble_right")
                                }.offset(y: 1))
                            }
                            Image("UITableNext").padding(.trailing, 12)
                        }.padding(.leading, 15)
                        Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                        
                    }
                }
            }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 44).drawingGroup()
            
        }.background(Color.white)
    }
}

struct mail_contact_view: View {
    var current_contact: CNContact
    @State var phone_content = [list_row]()
    @State var email_content = [list_row]()
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                settings_main_list()
                ScrollView(showsIndicators: true) {
                    VStack {
                        HStack() {
                            if current_contact.imageDataAvailable == false {
                                Image("ABPicturePerson").padding(.leading, 22)
                            } else {
                                Image(uiImage: (UIImage(data: current_contact.imageData ?? Data()) ?? UIImage(named:"ABPicturePerson")) ?? UIImage()).resizable().aspectRatio(contentMode: .fill).background(Color(red: 246/255, green: 246/255, blue: 250/255)).frame(width: 66, height: 64).mask(Image("ABPictureOutline").compositingGroup() .background(Color.white).luminanceToAlpha()).overlay(Image("ABPictureOutline")).padding(.leading, 22)
                            }
                            Text(current_contact.name).font(.custom("Helvetica Neue Bold", fixedSize: 20)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).lineLimit(0).padding(.leading, 5)
                            Spacer()
                        }.padding(.top, 20)
                        Spacer().frame(height:20)
                        list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: email_content)
                        Spacer().frame(height:20)
                        list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: [list_row(title: "", content: AnyView(mail_contact_text_content(first_line: "Create New Contact", second_line: ""))), list_row(title: "", content: AnyView(mail_contact_text_content(first_line: "Add to Existing Contact", second_line: "")))])
                        HStack(spacing: 0) {
                        }
                        Spacer()
                    }
                }
            }
        }.onAppear() {
            for email in current_contact.emailAddresses {
                email_content.append(list_row(title: "", content: AnyView(contacts_destination_content_email(type:  CNLabeledValue<NSString>.localizedString(forLabel: email.label ?? "other") ?? "other", number: email.value as String))))
            }
        }
    }
}

struct mail_contact_text_content: View {
    var first_line: String
    var second_line: String
    var body: some View {
        HStack {
            Spacer()
            Text(first_line).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(Color(red: 85/255, green: 101/255, blue: 142/255)).multilineTextAlignment(.center).lineLimit(0)
            Spacer()
        }
    }
}

struct mail_compose_view: View {
    @EnvironmentObject var EmailManager: EmailManager
    @State var to_address: String = ""
    @State var cc_address: String = ""
    @State var bcc_address: String = ""
    @State var subject: String = ""
    @State var content: String = "\n\nSent from my iPhone"
    @State var show_cc_bcc: Bool = false
    @State var text_height: CGFloat = 0
    @EnvironmentObject var keyboard: OldOSKeyboardController
    @Binding var show_compose: Bool
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer().frame(height:24)
                mail_compose_title_bar(title: subject == "" ? "New Message" : subject, done_action: {
                                        withAnimation(.linear(duration:0.35)) {
                                            show_compose = false
                                        }}, clear_action: {if to_address != "" {EmailManager.sendEmail(to: [to_address], cc: [cc_address],bcc: [bcc_address], subject: subject, bodyPlain: content) {
                                            result in
                                                switch result {
                                                case .success:
                                                    withAnimation(.linear(duration:0.35)) {
                                                        show_compose = false
                                                    }
                                                    print("Email sent successfully!")
                                                case .failure(let error):
                                                    withAnimation(.linear(duration:0.35)) {
                                                        show_compose = false
                                                    }
                                                    print("Failed to send email: \(error.localizedDescription)")
                                                }
                                        }}}, show_done: true, show_clear: true, disabled: to_address == "").frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 60, maxHeight:60).zIndex(1)
                
                ScrollView {
                    VStack(spacing: 0) {
                        HStack {
                            Text("To:").font(.custom("Helvetica Neue Regular", fixedSize: 15)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).padding(.leading, 6)
                            TextField ("", text: $to_address, onEditingChanged: { focused in
                                if focused && cc_address == "" && bcc_address == "" {
                                    withAnimation(.linear(duration: 0.25)) {
                                        show_cc_bcc = false
                                    }
                                }
                                print(focused ? "focused" : "unfocused")
                            }).keyboardType(.emailAddress).autocapitalization(.none).disableAutocorrection(true).oldOSKeyboard(.email).font(.custom("Helvetica Neue Regular", fixedSize: 15)).foregroundColor(Color.black)
                            Spacer()
                        }.background(Color.white.frame(width: geometry.size.width, height: 50)).frame(width: geometry.size.width, height: 50)
                        Rectangle().fill(Color(red: 230/255,green: 230/255, blue:230/255)).frame(width: geometry.size.width, height: 1)
                        HStack {
                            Text(show_cc_bcc ? "Cc:" : "Cc/Bcc:").font(.custom("Helvetica Neue Regular", fixedSize: 15)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).padding(.leading, 6).animationsDisabled()
                            TextField ("", text: $cc_address, onEditingChanged: { focused in
                                if focused {
                                    withAnimation(.linear(duration: 0.25)) {
                                        show_cc_bcc = true
                                    }
                                }
                                print(focused ? "focused" : "unfocused")
                            }).keyboardType(.emailAddress).autocapitalization(.none).disableAutocorrection(true).oldOSKeyboard(.email).font(.custom("Helvetica Neue Regular", fixedSize: 15)).foregroundColor(Color.black)
                            Spacer()
                        }.background(Color.white.frame(width: geometry.size.width, height: 50)).frame(width: geometry.size.width, height: 50)
                        Rectangle().fill(Color(red: 230/255,green: 230/255, blue:230/255)).frame(width: geometry.size.width, height: 1)
                        if show_cc_bcc {
                            HStack {
                                Text("Bcc:").font(.custom("Helvetica Neue Regular", fixedSize: 15)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).padding(.leading, 6)
                                TextField ("", text: $bcc_address).keyboardType(.emailAddress).disableAutocorrection(true).autocapitalization(.none).oldOSKeyboard(.email).font(.custom("Helvetica Neue Regular", fixedSize: 15)).foregroundColor(Color.black)
                                Spacer()
                            }.background(Color.white.frame(width: geometry.size.width, height: 50)).frame(width: geometry.size.width, height: show_cc_bcc ? 50 : 0)
                            Rectangle().fill(Color(red: 230/255,green: 230/255, blue:230/255)).frame(width: geometry.size.width, height: 1)
                        }
                        HStack {
                            Text("Subject:").font(.custom("Helvetica Neue Regular", fixedSize: 15)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).padding(.leading, 6)
                            TextField ("", text: $subject, onEditingChanged: { focused in
                                if focused && cc_address == "" && bcc_address == "" {
                                    withAnimation(.linear(duration: 0.25)) {
                                        show_cc_bcc = false
                                    }
                                }
                                print(focused ? "focused" : "unfocused")
                            }).keyboardType(.default).oldOSKeyboard(.standard).font(.custom("Helvetica Neue Regular", fixedSize: 15)).foregroundColor(Color.black)
                            Spacer()
                        }.background(Color.white).frame(width: geometry.size.width, height: 50)
                        Rectangle().fill(Color(red: 230/255,green: 230/255, blue:230/255)).frame(width: geometry.size.width, height: 1)
                        mail_compose_textview(text: $content, text_height: $text_height, geometry: geometry).frame(width: geometry.size.width, height: text_height > geometry.size.height ? text_height : geometry.size.height).padding(.bottom, keyboard.currentHeight)
                    }.clipped()
                }.background(Color.white)
            }.frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

struct mail_compose_textview: UIViewRepresentable {
    @EnvironmentObject private var keyboard: OldOSKeyboardController
    
    @Binding var text: String
    @Binding var text_height: CGFloat
    var geometry: GeometryProxy
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont(name: "HelveticaNeue", size: 15.5)
        textView.textColor = .black
        textView.isUserInteractionEnabled = true
        textView.delegate = context.coordinator
        OldOSKeyboardInputSuppression.install(on: textView)
        textView.autocapitalizationType = .sentences
        textView.autocorrectionType = .yes
        textView.spellCheckingType = .no
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.widthAnchor.constraint(equalToConstant: geometry.size.width).isActive = true
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.parent = self
        let selectedRange = uiView.selectedRange
        if uiView.text != text { uiView.text = text }
        uiView.selectedRange = selectedRange
    }
    func makeCoordinator() -> Coordinator {
        Coordinator($text, self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var parent: mail_compose_textview
        init(_ text: Binding<String>, _ parent: mail_compose_textview) {
            self.parent = parent
            self.text = text
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.keyboard.activate(
                textView: textView,
                configuration: .standard
            )
        }

        func textViewDidChange(_ textView: UITextView) {
            self.text.wrappedValue = textView.text
            parent.text_height = textView.sizeThatFits(textView.bounds.size).height
            parent.keyboard.textDidChange(textView)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.keyboard.deactivate(textView: textView)
        }
    }
}

struct mail_compose_title_bar : View {
    var title:String
    public var done_action: (() -> Void)?
    public var clear_action: (() -> Void)?
    var show_done: Bool?
    var show_clear: Bool?
    var disabled: Bool
    var body :some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.49), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.49), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(title).ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", fixedSize: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).id(title).frame(maxWidth: 200)
                    Spacer()
                }
                Spacer()
            }
            if show_done == true {
                HStack {
                    tool_bar_rectangle_button(action: {done_action?()}, button_type: .blue_gray, content: "Cancel").padding(.leading, 5)
                    Spacer()
                }
            }
            if show_clear == true {
                HStack {
                    Spacer()
                    tool_bar_rectangle_button_gray_out(action: {clear_action?()}, button_type: .blue_gray, content: "Send", gray_out: disabled).padding(.trailing, 5)
                }
            }
        }
    }
}

struct mail_other_body_view: View {
    var message: MCOIMAPMessage
    @EnvironmentObject var EmailManager: EmailManager
    @State var webViewHeight: CGFloat = 0
    @State var lastScaleValue: CGFloat = 1.0
    @State var show_details: Bool = false
    @ObservedObject var contacts_observer = ContactStore()
    @Binding var current_contact: CNContact
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var selected_mailbox: mail_folder_item
    static let date_format: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM, d, yyyy h:mm a"
        return formatter
    }()
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Text("From:").font(.custom("Helvetica Neue Regular", fixedSize: 15)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).padding(.leading, 6)
                        Text("\(message.header.sender.displayName ?? message.header.sender.mailbox ?? "")").font(.custom("Helvetica Neue Regular", fixedSize: 15)).lineLimit(0).foregroundColor(.black).padding([.top, .bottom], 4).padding([.leading], 8).padding(.trailing, 22).background(Image("address_atom_disclosure").frame(height: 25)).onTapGesture() {
                            if let idx = contacts_observer.contacts.firstIndex(where: {$0.emailAddresses.map({$0.value as String}).contains( message.header.sender.mailbox ?? "")}) {
                                current_contact = contacts_observer.contacts[optional: idx] ?? CNContact()
                                if current_contact == contacts_observer.contacts[optional: idx] {
                                    forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Contact_Other"}
                                }
                            } else {
                                var contact = CNMutableContact()
                                contact.givenName = "\(message.header.sender.displayName ?? message.header.sender.mailbox ?? "")"
                                contact.emailAddresses = [CNLabeledValue(
                                                            label:CNLabelOther,
                                                            value:(message.header.sender.mailbox ?? "") as NSString)]
                                current_contact = contact
                                if current_contact == contact {
                                    forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Contact_Other"}}
                            }
                        }
                        Spacer()
                        Button(action:{
                            withAnimation(.linear(duration: 0.25)) {
                                show_details.toggle()
                            }
                        }) {
                            Text(show_details ? "Hide" : "Details").font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(Color(red: 33/255, green: 80/255, blue: 225/255)).padding(.trailing, 6)
                        }
                    }.background(Color.white.frame(width: geometry.size.width, height: 50)).frame(width: geometry.size.width, height: 50)
                    Rectangle().fill(Color(red: 230/255,green: 230/255, blue:230/255)).frame(width: geometry.size.width, height: 1)
                    VStack(spacing: 0) {
                        HStack {
                            Text("To:").font(.custom("Helvetica Neue Regular", fixedSize: 15)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).padding(.leading, 6)
                            Text("\((message.header.to?[optional: 0] as? MCOAddress)?.displayName ?? (message.header.to?[optional: 0] as? MCOAddress)?.mailbox ?? "")").font(.custom("Helvetica Neue Regular", fixedSize: 15)).lineLimit(0).foregroundColor(.black).padding([.top, .bottom], 4).padding([.leading], 8).padding(.trailing, 22).background(Image("address_atom_disclosure").frame(height: 25))
                            Spacer()
                        }.background(Color.white.frame(width: geometry.size.width, height: 50)).frame(width: geometry.size.width, height: 50)
                        Rectangle().fill(Color(red: 230/255,green: 230/255, blue:230/255)).frame(width: geometry.size.width, height: 1)
                    }.frame(width: geometry.size.width, height:  show_details ? 51 : 0).clipped()
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 0) {
                            Text(message.header.subject ?? "" == "" ? "(No Subject)" : message.header.subject ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 15)).multilineTextAlignment(.leading).foregroundColor(.black).fixedSize(horizontal: false, vertical: true).padding([.top], 6)
                            Spacer()
                        }.padding([.leading, .trailing], 6)
                        Spacer().frame(height: 6)
                        HStack(spacing: 0) {
                            Text("\((message.header.date ?? Date()), formatter: mail_body_view.date_format)").font(.custom("Helvetica Neue Regular", fixedSize: 14)).multilineTextAlignment(.leading).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).padding([.bottom], 6)
                            Spacer()
                        }.padding([.leading, .trailing], 6)
                    }.background(Color.white.frame(width: geometry.size.width)).frame(width: geometry.size.width)
                    Rectangle().fill(Color(red: 230/255,green: 230/255, blue:230/255)).frame(width: geometry.size.width, height: 1)
                    Rectangle().fill(Color.white)
                    ZStack(alignment: .top) {
                        if webViewHeight < geometry.size.height { //there  needs to be more math for this, but tahts for anotehr time
                            Color.white.frame(width: geometry.size.width, height: geometry.size.height)
                            // Color.white.edgesIgnoringSafeArea(.all)
                        }
                        WebViewEmailOther(message: message, imap_session: EmailManager.imap_session, geometry: geometry, webViewHeight: $webViewHeight, selected_mailbox: $selected_mailbox).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: webViewHeight, maxHeight: webViewHeight)
                    }
                    
                }.clipped().shadow(color: Color.black.opacity(0.65), radius: 8, x: 0, y: 0)
            }.background(Color(red: 93/255, green: 99/255, blue: 103/255).innerShadowBottom(color: Color.black.opacity(0.35), radius: 0.035))
        }
    }
}

struct mail_body_view: View {
    var message: MCOIMAPMessage
    @EnvironmentObject var EmailManager: EmailManager
    @State var webViewHeight: CGFloat = 0
    @State var lastScaleValue: CGFloat = 1.0
    @State var show_details: Bool = false
    @ObservedObject var contacts_observer = ContactStore()
    @Binding var current_contact: CNContact
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    static let date_format: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM, d, yyyy h:mm a"
        return formatter
    }()
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Text("From:").font(.custom("Helvetica Neue Regular", fixedSize: 15)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).padding(.leading, 6)
                        Text("\(message.header.sender.displayName ?? message.header.sender.mailbox ?? "")").font(.custom("Helvetica Neue Regular", fixedSize: 15)).lineLimit(0).foregroundColor(.black).padding([.top, .bottom], 4).padding([.leading], 8).padding(.trailing, 22).background(Image("address_atom_disclosure").frame(height: 25)).onTapGesture() {
                            if let idx = contacts_observer.contacts.firstIndex(where: {$0.emailAddresses.map({$0.value as String}).contains( message.header.sender.mailbox ?? "")}) {
                                current_contact = contacts_observer.contacts[optional: idx] ?? CNContact()
                                if current_contact == contacts_observer.contacts[optional: idx] {
                                    forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Contact"}
                                }
                            } else {
                                var contact = CNMutableContact()
                                contact.givenName = "\(message.header.sender.displayName ?? message.header.sender.mailbox ?? "")"
                                contact.emailAddresses = [CNLabeledValue(
                                                            label:CNLabelOther,
                                                            value:(message.header.sender.mailbox ?? "") as NSString)]
                                current_contact = contact
                                if current_contact == contact {
                                    forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Contact"}}
                            }
                        }
                        Spacer()
                        Button(action:{
                            withAnimation(.linear(duration: 0.25)) {
                                show_details.toggle()
                            }
                        }) {
                            Text(show_details ? "Hide" : "Details").font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(Color(red: 33/255, green: 80/255, blue: 225/255)).padding(.trailing, 6)
                        }
                    }.background(Color.white.frame(width: geometry.size.width, height: 50)).frame(width: geometry.size.width, height: 50)
                    Rectangle().fill(Color(red: 230/255,green: 230/255, blue:230/255)).frame(width: geometry.size.width, height: 1)
                    VStack(spacing: 0) {
                        HStack {
                            Text("To:").font(.custom("Helvetica Neue Regular", fixedSize: 15)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).padding(.leading, 6)
                            Text("\((message.header.to?[optional: 0] as? MCOAddress)?.displayName ?? (message.header.to?[optional: 0] as? MCOAddress)?.mailbox ?? "")").font(.custom("Helvetica Neue Regular", fixedSize: 15)).lineLimit(0).foregroundColor(.black).padding([.top, .bottom], 4).padding([.leading], 8).padding(.trailing, 22).background(Image("address_atom_disclosure").frame(height: 25))
                            Spacer()
                        }.background(Color.white.frame(width: geometry.size.width, height: 50)).frame(width: geometry.size.width, height: 50)
                        Rectangle().fill(Color(red: 230/255,green: 230/255, blue:230/255)).frame(width: geometry.size.width, height: 1)
                    }.frame(width: geometry.size.width, height:  show_details ? 51 : 0).clipped()
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 0) {
                            Text(message.header.subject ?? "" == "" ? "(No Subject)" : message.header.subject ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 15)).multilineTextAlignment(.leading).foregroundColor(.black).fixedSize(horizontal: false, vertical: true).padding([.top], 6)
                            Spacer()
                        }.padding([.leading, .trailing], 6)
                        Spacer().frame(height: 6)
                        HStack(spacing: 0) {
                            Text("\((message.header.date ?? Date()), formatter: mail_body_view.date_format)").font(.custom("Helvetica Neue Regular", fixedSize: 14)).multilineTextAlignment(.leading).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).padding([.bottom], 6)
                            Spacer()
                        }.padding([.leading, .trailing], 6)
                    }.background(Color.white.frame(width: geometry.size.width)).frame(width: geometry.size.width)
                    Rectangle().fill(Color(red: 230/255,green: 230/255, blue:230/255)).frame(width: geometry.size.width, height: 1)
                    Rectangle().fill(Color.white)
                    ZStack(alignment: .top) {
                        if webViewHeight < geometry.size.height { //there  needs to be more math for this, but thats for another time
                            Color.white.frame(width: geometry.size.width, height: geometry.size.height)
                        }
                        WebViewEmail(message: message, folder: "INBOX", imap_session: EmailManager.imap_session, geometry: geometry, webViewHeight: $webViewHeight).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: webViewHeight, maxHeight: webViewHeight)
                    }
                    
                }.clipped().shadow(color: Color.black.opacity(0.65), radius: 8, x: 0, y: 0)
            }.background(Color(red: 93/255, green: 99/255, blue: 103/255).innerShadowBottom(color: Color.black.opacity(0.35), radius: 0.035))
        }.onAppear() {
            let uidSet = MCOIndexSet(range: MCORange(location: UInt64(message.uid ?? 0), length: 0))
            var seen_operation: MCOIMAPOperation = EmailManager.imap_session.storeFlagsOperation(withFolder: "INBOX", uids: uidSet, kind: .add, flags: .seen)
            seen_operation.start {error in
                if error == nil {
                    if let idx = EmailManager.emails.firstIndex(of: message) {
                        message.flags.formUnion(.seen)
                        EmailManager.emails[idx] = message
                    }
                }
            }
        }
    }
}

struct mail_title_bar : View {
    @EnvironmentObject var EmailManager: EmailManager
    var title:String
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @State var instant_multitasking_change: Bool = false
    public var done_action: (() -> Void)?
    var show_done: Bool?
    var body :some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.49), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.49), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(title).ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", fixedSize: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).id(title).frame(maxWidth: 180)
                    Spacer()
                }
                Spacer()
            }
            if current_nav_view == "Main" || current_nav_view == "Other" {
                VStack {
                    Spacer()
                    HStack {
                        Button(action:{
                            forward_or_backward = true; withAnimation(.linear(duration: 0.28)){current_nav_view = "Mailboxes"}
                        }){
                            ZStack {
                                Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                                HStack(alignment: .center) {
                                    Text("Mailboxes").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                                }
                            }.padding(.leading, 6)
                        }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                        Spacer()
                    }
                    Spacer()
                }.offset(y:-0.5)
                
            }
            if current_nav_view == "Destination" {
                VStack {
                    Spacer()
                    HStack {
                        Button(action:{
                            forward_or_backward = true; withAnimation(.linear(duration: 0.28)){current_nav_view = "Main"}
                        }){
                            ZStack {
                                Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                                HStack(alignment: .center) {
                                    Text("Inbox (\(EmailManager.emails.filter({!$0.flags.contains(.seen)}).count))").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                                }
                            }.padding(.leading, 6)
                        }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                        Spacer()
                    }
                    Spacer()
                }.offset(y:-0.5)
                
            }
            if current_nav_view == "Destination_Other" {
                VStack {
                    Spacer()
                    HStack {
                        Button(action:{
                            forward_or_backward = true; withAnimation(.linear(duration: 0.28)){current_nav_view = "Other"}
                        }){
                            ZStack {
                                Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                                HStack(alignment: .center) {
                                    Text("Inbox (\(EmailManager.emails.filter({!$0.flags.contains(.seen)}).count))").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                                }
                            }.padding(.leading, 6)
                        }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                        Spacer()
                    }
                    Spacer()
                }.offset(y:-0.5)
                
            }
            if current_nav_view == "Contact" {
                VStack {
                    Spacer()
                    HStack {
                        Button(action:{
                            forward_or_backward = true; withAnimation(.linear(duration: 0.28)){current_nav_view = "Destination"}
                        }){
                            ZStack {
                                Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                                HStack(alignment: .center) {
                                    Text("Message").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                                }
                            }.padding(.leading, 6)
                        }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                        Spacer()
                    }
                    Spacer()
                }.offset(y:-0.5)
                
            }
            if current_nav_view == "Contact_Other" {
                VStack {
                    Spacer()
                    HStack {
                        Button(action:{
                            forward_or_backward = true; withAnimation(.linear(duration: 0.28)){current_nav_view = "Destination_Other"}
                        }){
                            ZStack {
                                Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                                HStack(alignment: .center) {
                                    Text("Message").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                                }
                            }.padding(.leading, 6)
                        }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                        Spacer()
                    }
                    Spacer()
                }.offset(y:-0.5)
                
            }
            if current_nav_view.contains("Destination") {
                HStack {
                    Spacer()
                    dual_segmented_control_image_button(instant_multitasking_change: $instant_multitasking_change, first_text: "arrowup", second_text: "arrowdown").frame(width: 95, height: 30).padding(.trailing, 6)
                }
            }
            if show_done == true {
                HStack {
                    Spacer()
                    tool_bar_rectangle_button(action: {done_action?()}, button_type: .blue, content: "Done").padding(.trailing, 5)
                }.offset(y:-0.5)
            }
        }
    }
}

struct WebViewEmail: UIViewRepresentable {
    let message: MCOIMAPMessage
    let folder: String
    let imap_session: MCOIMAPSession
    let geometry: GeometryProxy
    @Binding var webViewHeight: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let jscript = """
        var meta=document.createElement('meta');
        meta.name='viewport'; meta.content='width=\(Int(geometry.size.width))';
        document.head.appendChild(meta);
        var style=document.createElement('style');
        style.innerHTML='img{max-width:100%;height:auto} body{font-family:Helvetica,Arial,sans-serif;margin:8px} pre{white-space:pre-wrap}';
        document.head.appendChild(style);
        """
        let userScript = WKUserScript(source: jscript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let uctrl = WKUserContentController()
        uctrl.addUserScript(userScript)

        let cfg = WKWebViewConfiguration()
        cfg.userContentController = uctrl

        let web = WKWebView(frame: CGRect(x: 0, y: 0, width: geometry.size.width, height: 1), configuration: cfg)
        web.scrollView.isScrollEnabled = false
        web.navigationDelegate = context.coordinator
        web.scrollView.delegate = context.coordinator
        web.loadHTMLString("<em style='color:#666'>Loading…</em>", baseURL: nil)
        return web
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.loadUrgentIfNeeded(into: webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
        let parent: WebViewEmail
        var parsedOp: MCOIMAPFetchParsedContentOperation?
        var didStartForUID: UInt32 = 0

        init(_ parent: WebViewEmail) { self.parent = parent }

        func loadUrgentIfNeeded(into web: WKWebView) {
            guard didStartForUID != parent.message.uid else { return }
            didStartForUID = parent.message.uid

            parsedOp?.cancel()
            parsedOp = nil

            let op = parent.imap_session.fetchParsedMessageOperation(
                withFolder: parent.folder,
                uid: parent.message.uid,
                urgent: true
            )

            parsedOp = op
            op?.start { [weak self] (error: Error?, parser: MCOMessageParser?) in
                guard let self else { return }
                if let error {
                    DispatchQueue.main.async {
                        web.loadHTMLString("<pre>\(Self.escape(error.localizedDescription))</pre>", baseURL: nil)
                    }
                    return
                }
                guard let parser else {
                    DispatchQueue.main.async {
                        web.loadHTMLString("<em style='color:#666'>No content</em>", baseURL: nil)
                    }
                    return
                }

                var html = parser.htmlBodyRendering()
                if (html?.isEmpty ?? true) {
                    let plain = parser.plainTextRendering()
                    html = "<pre>\(Self.escape(plain ?? ""))</pre>"
                }

                DispatchQueue.main.async {
                    web.loadHTMLString(html ?? "", baseURL: nil)
                }
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, _ in
                guard let self else { return }
                if let n = result as? NSNumber {
                    self.parent.webViewHeight = CGFloat(truncating: n)
                }
            }
        }

        func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
            scrollView.pinchGestureRecognizer?.isEnabled = false
        }

        private static func escape(_ s: String) -> String {
            s.replacingOccurrences(of: "&", with: "&amp;")
             .replacingOccurrences(of: "<", with: "&lt;")
             .replacingOccurrences(of: ">", with: "&gt;")
        }
    }
}



struct WebViewEmailOther: UIViewRepresentable {
    var message: MCOIMAPMessage
    var imap_session: MCOIMAPSession
    var geometry: GeometryProxy
    @Binding var webViewHeight: CGFloat
    @Binding var selected_mailbox: mail_folder_item
    var webView: WKWebView?
    init(message: MCOIMAPMessage, imap_session: MCOIMAPSession, geometry: GeometryProxy, webViewHeight: Binding<CGFloat>, selected_mailbox: Binding<mail_folder_item>) {
        self.message = message
        self.imap_session = imap_session
        self.geometry = geometry
        _webViewHeight = webViewHeight
        _selected_mailbox = selected_mailbox
        let jscript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=\(geometry.size.width)'); document.getElementsByTagName('head')[0].appendChild(meta);" //make this better for images
        let userScript = WKUserScript(source: jscript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let wkUController = WKUserContentController()
        wkUController.addUserScript(userScript)
        let wkWebConfig = WKWebViewConfiguration()
        wkWebConfig.userContentController = wkUController
        webView = WKWebView(frame: CGRect(geometry.size.width, geometry.size.height), configuration: wkWebConfig)
        webView?.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        webView?.contentMode = .scaleAspectFit
        webView?.scrollView.isScrollEnabled = false
        webView?.scrollView.minimumZoomScale = 1.0
        webView?.scrollView.maximumZoomScale = 1.0
    }
    func makeUIView(context: Context) -> WKWebView {
        webView?.navigationDelegate = context.coordinator
        webView?.scrollView.delegate = context.coordinator
        return webView ?? WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        fetch()
    }
    func fetch() {
        let fetchOperation : MCOIMAPFetchParsedContentOperation = imap_session.fetchParsedMessageOperation(withFolder: selected_mailbox.path, uid: UInt32(message.uid ?? 0))
        fetchOperation.start {(error, parser) in
            webView?.loadHTMLString((parser?.htmlBodyRendering() ?? ""), baseURL: nil)
        }
    }
    class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
        var parent: WebViewEmailOther
        
        init(_ parent: WebViewEmailOther) {
            self.parent = parent
        }
        public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
            scrollView.pinchGestureRecognizer?.isEnabled = false
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let changeFontFamilyScript = "document.getElementsByTagName(\'body\')[0].style.fontFamily = \"Helvetica, sans-serif\";"
            webView.evaluateJavaScript(changeFontFamilyScript) { (response, error) in
                debugPrint("Am here")
            }
            webView.evaluateJavaScript("document.readyState", completionHandler: { (complete, error) in
                if complete != nil {
                    webView.evaluateJavaScript("document.body.scrollWidth", completionHandler: { (width, error) in
                        if (width as? CGFloat ?? self.parent.geometry.size.width) > self.parent.geometry.size.width + 20 {
                            webView.evaluateJavaScript("document.documentElement.outerHTML", completionHandler: { (html, error) in
                                webView.loadHTMLString((html as? String ?? "").HTMLImageCorrector(), baseURL: nil)
                            })
                        }
                    })
                    webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { (height, error) in
                        self.parent.webView?.frame.size.height = height as? CGFloat ?? 0
                        self.parent.webViewHeight = height as? CGFloat ?? 0
                        self.parent.webView?.setNeedsDisplay()
                    })
                }
                
            })
        }
        
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

extension String {
    
    func HTMLImageCorrector() -> String {
        var HTMLToBeReturned = self
        while HTMLToBeReturned.range(of: "(?<=width=\")[^\" height]+", options: .regularExpression) != nil{
            if let match = HTMLToBeReturned.range(of: "(?<=width=\")[^\" height]+", options: .regularExpression) {
                HTMLToBeReturned.removeSubrange(match)
                if let match2 = HTMLToBeReturned.range(of: "(?<=height=\")[^\"]+", options: .regularExpression) {
                    HTMLToBeReturned.removeSubrange(match2)
                    let string2del = "width=\"\" height=\"\""
                    HTMLToBeReturned = HTMLToBeReturned.replacingOccurrences(of: string2del, with: "style=\"width: 100%\"")
                }
            }
            
        }
        
        return HTMLToBeReturned
    }
}

struct mail_inbox_view: View {
    @State var search: String = ""
    @State var editing_state: String = "None"
    @State var refersh_text: Bool = false
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var selected_message: MCOIMAPMessage
    @EnvironmentObject var EmailManager: EmailManager
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Color.white.edgesIgnoringSafeArea(.all)
                LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0), .init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0.5), .init(color: Color.white, location: 0.5), .init(color: Color.white, location: 1)]), startPoint: .top, endPoint: .bottom)
                ScrollView {
                    VStack(spacing: 0) {
                        ipod_search(search: $search, no_right_padding: editing_state != "None" ? true : false, editing_state:$editing_state).id("Search").frame(height:44)
                        if EmailManager.emails.reversed().filter({!$0.flags.contains(.deleted)}).isEmpty {
                            Rectangle().fill(Color.white).frame(width: geometry.size.width, height: geometry.size.height - 44)
                        } else {
                        ForEach(EmailManager.emails.reversed().filter({!$0.flags.contains(.deleted)}), id: \.uid) {message in
                            mail_message_view(message: message, imap_session: EmailManager.imap_session).frame(width: geometry.size.width, height: 82).id(message.uid).onTapGesture {
                                selected_message = message
                                if selected_message == message {
                                    forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Destination"}
                                }
                            }
                        }
                        }
                        Button(action: {EmailManager.fetch_past_emails()}) {
                            ZStack {
                                Rectangle().fill(Color.white).frame(width: geometry.size.width, height: 82)
                                VStack(spacing: 0) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            HStack() {
                                                Text("Load More Messages...").font(.custom("Helvetica Neue Bold", fixedSize: 18)).lineLimit(1).foregroundColor(Color(red: 58/255, green: 111/255, blue: 209/255))
                                                Spacer()
                                            }
                                            Spacer().frame(height: 1)
                                            HStack() {
                                                Text("\(EmailManager.total_email_quantity.delimiter) messsages total, \(EmailManager.total_unread_quantity.delimiter) unread").font(.custom("Helvetica Neue Regular", fixedSize: 14)).lineLimit(2).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255))
                                                Spacer()
                                            }
                                        }.padding(.leading, 32).offset(y: -2)
                                        Image("UITableNext").padding(.trailing, 12)
                                    }.frame(width: geometry.size.width, height: 81)
                                    Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                                }
                            }.frame(width: geometry.size.width, height: 82)
                        }
                    }  .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
        }
    }
}

struct mail_other_mailbox_view: View {
    @Binding var selected_mailbox: mail_folder_item
    @State var search: String = ""
    @State var editing_state: String = "None"
    @State var refersh_text: Bool = false
    @State var emails: [MCOIMAPMessage] = []
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var selected_message: MCOIMAPMessage
    @EnvironmentObject var EmailManager: EmailManager
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Color.white.edgesIgnoringSafeArea(.all)
                LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0), .init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0.5), .init(color: Color.white, location: 0.5), .init(color: Color.white, location: 1)]), startPoint: .top, endPoint: .bottom)
                ScrollView {
                    VStack(spacing: 0) {
                        ipod_search(search: $search, no_right_padding: editing_state != "None" ? true : false, editing_state:$editing_state).id("Search").frame(height:44)
                        if emails.isEmpty {
                            Rectangle().fill(Color.white).frame(width: geometry.size.width, height: geometry.size.height - 44)
                        } else {
                        ForEach(emails.reversed().filter({!$0.flags.contains(.deleted)}), id: \.uid) {message in
                            mail_other_message_view(message: message, imap_session: EmailManager.imap_session, selected_mailbox: $selected_mailbox).frame(width: geometry.size.width, height: 82).id(message.uid).onTapGesture {
                                selected_message = message
                                if selected_message == message {
                                    forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Destination_Other"}
                                }
                            }
                        }
                        }
                    }  .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
        }.onAppear() {
                let statusOperation: MCOIMAPFolderInfoOperation = EmailManager.imap_session.folderInfoOperation(selected_mailbox.path)
                statusOperation.start { (err, status) -> Void in
                    print("called progress",status?.uidNext, self.emails.last?.uid)
                    let folder : String = "INBOX"
                    let uids : MCOIndexSet = MCOIndexSet(range: MCORange(location: UInt64(((status?.messageCount ?? 49) < 49 ? 49 : (status?.messageCount ?? 49)) - 49), length: 50))
                    let requestKind:MCOIMAPMessagesRequestKind = [.headers, .extraHeaders, .fullHeaders, .structure, .flags]
                    let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("emails")
                    var quantity: UInt32 = 0
                    let fetchOperation : MCOIMAPFetchMessagesOperation = EmailManager.imap_session.fetchMessagesByNumberOperation(withFolder: self.selected_mailbox.path, requestKind: requestKind, numbers: uids)
                    let pre_fetchOperation : MCOIMAPFetchMessagesOperation = EmailManager.imap_session.fetchMessagesByNumberOperation(withFolder: self.selected_mailbox.path, requestKind: requestKind, numbers: uids)
                    pre_fetchOperation.start {  (err, msg, vanished) -> Void in
                        fetchOperation.start { (err, msg, vanished) -> Void in
                            print("error from server \(err)")
                            print("fetched \(msg?.count) messages")
                            for message in msg ?? [] {
                                if !self.emails.map{$0.uid}.contains(message.uid) {
                                    if !message.flags.contains(.deleted) {
                                        self.emails.append(message)
                                        if self.emails.count >= 50 {
                                            self.emails.removeFirst()
                                        }
                                    }
                                    else {
                                        if let idx = self.emails.firstIndex(where: {$0.uid == message.uid}) {
                                            self.emails[idx] = message
                                        }
                                    }
                                }
                            }
                        }
                        fetchOperation.progress = { (current: UInt32) in
                        }
                    }
                }
         //   }
        }
    }
}

struct mail_message_view: View {
    var message: MCOIMAPMessage
    var imap_session: MCOIMAPSession
    var toggleBinding: Binding<String>!
    @ObservedObject var body_placeholder = Body_Placeholder()
    @EnvironmentObject var EmailManager: EmailManager
    let it = PassthroughSubject<Void, Never>()
    init(message: MCOIMAPMessage, imap_session: MCOIMAPSession) {
        self.message = message
        self.imap_session = imap_session
        self.body_placeholder.message = message
        self.body_placeholder.imap_session = imap_session
        self.body_placeholder.fetch()
        
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle().fill(Color.white).frame(width: geometry.size.width, height: 82)
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack() {
                                Text(message.header.sender?.displayName ?? message.header.sender?.mailbox ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 18)).lineLimit(1).foregroundColor(.black)
                                Spacer()
                                if message.header.date.relativeTime.contains("AM") || message.header.date.relativeTime.contains("PM") {
                                    HStack(spacing: 0) {
                                        Text(message.header.date.relativeTime.replacingOccurrences(of: "AM", with: "").replacingOccurrences(of: "PM", with: "")).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(Color(red: 58/255, green: 111/255, blue: 209/255))
                                        Text(message.header.date.relativeTime.contains("AM") ? "AM" : "PM").font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(Color(red: 58/255, green: 111/255, blue: 209/255))
                                    }
                                } else {
                                    Text(message.header.date.relativeTime).font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(Color(red: 58/255, green: 111/255, blue: 209/255))
                                }
                            }
                            Spacer().frame(height: 1)
                            Text(message.header.subject ?? "" == "" ? "(No Subject)" : message.header.subject ?? "").font(.custom("Helvetica Neue Regular", fixedSize: 14)).lineLimit(1).foregroundColor(.black)
                            let message_body = message.header.extraHeaderValue(forName: "body") == nil ? body_placeholder.value : message.header.extraHeaderValue(forName: "body") ?? ""
                            Text(message_body.components(separatedBy: "\n").count < 2 ? message_body + "\n" : message_body).font(.custom("Helvetica Neue Regular", fixedSize: 14)).lineLimit(2).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).fixedSize(horizontal: false, vertical: true)
                        }.padding(.leading, 32).offset(y: -2)
                        Image("UITableNext").padding(.trailing, 12)
                    }.frame(width: geometry.size.width, height: 81).overlay(
                        HStack {
                            if !message.flags.contains(.seen) {
                                Circle().fill(LinearGradient([Color(red: 143/255, green: 176/255, blue: 241/255), Color(red: 44/255, green: 80/255, blue: 166/255)], from: .top, to: .bottom)).frame(width: 12.5, height: 12.5).strokeCircle(LinearGradient([Color(red: 125/255, green: 157/255, blue: 220/255), Color(red: 38/255, green: 72/255, blue: 158/255)], from:.top, to:.bottom), lineWidth: 0.75).padding(.leading, 9.375)
                            }
                            Spacer()
                        }
                    )
                    Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                }
            }.frame(width: geometry.size.width, height: 82)
        }
        .onChange(of: body_placeholder.value) { _ in
            if body_placeholder.value != "" && message.header.extraHeaderValue(forName: "body") == nil {
                EmailManager.emails[EmailManager.emails.firstIndex(where: {$0.uid == message.uid}) ?? 0].header.setExtraHeaderValue(body_placeholder.value, forName: "body")
            }
        }
        
    }
}

struct mail_other_message_view: View {
    var message: MCOIMAPMessage
    var imap_session: MCOIMAPSession
    var toggleBinding: Binding<String>!
    @Binding var selected_mailbox: mail_folder_item
    @ObservedObject var body_placeholder: Body_Placeholder_Other = Body_Placeholder_Other()
    @EnvironmentObject var EmailManager: EmailManager
    let it = PassthroughSubject<Void, Never>()
    init(message: MCOIMAPMessage, imap_session: MCOIMAPSession, selected_mailbox: Binding<mail_folder_item>) {
        self.message = message
        self.imap_session = imap_session
        _selected_mailbox = selected_mailbox
        self.body_placeholder.selected_mailbox = selected_mailbox.wrappedValue
        self.body_placeholder.message = message
        self.body_placeholder.imap_session = imap_session
        self.body_placeholder.fetch()
        
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle().fill(Color.white).frame(width: geometry.size.width, height: 82)
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack() {
                                Text(message.header.sender?.displayName ?? message.header.sender?.mailbox ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 18)).lineLimit(1).foregroundColor(.black)
                                Spacer()
                                if message.header.date.relativeTime.contains("AM") || message.header.date.relativeTime.contains("PM") {
                                    HStack(spacing: 0) {
                                        Text(message.header.date.relativeTime.replacingOccurrences(of: "AM", with: "").replacingOccurrences(of: "PM", with: "")).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(Color(red: 58/255, green: 111/255, blue: 209/255))
                                        Text(message.header.date.relativeTime.contains("AM") ? "AM" : "PM").font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(Color(red: 58/255, green: 111/255, blue: 209/255))
                                    }
                                } else {
                                    Text(message.header.date.relativeTime).font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(Color(red: 58/255, green: 111/255, blue: 209/255))
                                }
                            }
                            Spacer().frame(height: 1)
                            Text(message.header.subject ?? "" == "" ? "(No Subject)" : message.header.subject ?? "").font(.custom("Helvetica Neue Regular", fixedSize: 14)).lineLimit(1).foregroundColor(.black)
                            let message_body = message.header.extraHeaderValue(forName: "body") == nil ? body_placeholder.value : message.header.extraHeaderValue(forName: "body") ?? ""
                            Text(message_body.components(separatedBy: "\n").count < 2 ? message_body + "\n" : message_body).font(.custom("Helvetica Neue Regular", fixedSize: 14)).lineLimit(2).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).fixedSize(horizontal: false, vertical: true)
                        }.padding(.leading, 32).offset(y: -2)
                        Image("UITableNext").padding(.trailing, 12)
                    }.frame(width: geometry.size.width, height: 81).overlay(
                        HStack {
                            if !message.flags.contains(.seen) {
                                Circle().fill(LinearGradient([Color(red: 143/255, green: 176/255, blue: 241/255), Color(red: 44/255, green: 80/255, blue: 166/255)], from: .top, to: .bottom)).frame(width: 12.5, height: 12.5).strokeCircle(LinearGradient([Color(red: 125/255, green: 157/255, blue: 220/255), Color(red: 38/255, green: 72/255, blue: 158/255)], from:.top, to:.bottom), lineWidth: 0.75).padding(.leading, 9.375)
                            }
                            Spacer()
                        }
                    )
                    Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                }
            }.frame(width: geometry.size.width, height: 82)
        }
        
    }
}

class Body_Placeholder:ObservableObject {
    @Published var value: String = ""
    var message: MCOIMAPMessage?
    var imap_session: MCOIMAPSession?
    init() {
        
    }
    func fetch() {
        if value == "" && message?.header.extraHeaderValue(forName: "body") == nil {
            print("called fetch here")
            let body_operation =  imap_session?.plainTextBodyRenderingOperation(with: message, folder: "INBOX")
            body_operation?.start { [self] result, error in
                self.value = result ?? ""
            }
        }
    }
}

class Body_Placeholder_Other:ObservableObject {
    @Published var value: String = ""
    var selected_mailbox: mail_folder_item?
    var message: MCOIMAPMessage?
    var imap_session: MCOIMAPSession?
    func fetch() {
        if value == "" && message?.header.extraHeaderValue(forName: "body") == nil {
            print("called fetch here")
            let body_operation =  imap_session?.plainTextBodyRenderingOperation(with: message, folder: selected_mailbox?.path)
            body_operation?.start { [self] result, error in
                self.value = result ?? ""
            }
        }
    }
}

struct SignInSheet: View {
    @EnvironmentObject var email: EmailManager
    @Environment(\.dismiss) private var dismiss
    @State private var authInFlight = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Sign in to Gmail").font(.title2).bold()
            Text("We’ll open a secure Google window.")
                .multilineTextAlignment(.center)

            Button(authInFlight ? "Opening…" : "Continue with Google") {
                startAuth()
            }
            .disabled(authInFlight)
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear { if !authInFlight { startAuth() } }
    }

    private func startAuth() {
        guard !authInFlight else { return }
        authInFlight = true
        dismiss()
        debugOAuth(email.oauth2)
        let ctx = email.oauth2.authConfig.authorizeContext
        print("authorizeContext:", String(describing: ctx))
        email.oauth2.authorize { _, error in
            DispatchQueue.main.async {
                authInFlight = false
                if let error = error {
                    print("OAuth authorize error:", error)
                    return
                }
                email.do_initial_setup()
            }
        }
    }
}

extension Subscribers.Completion {
    func error() throws -> Failure {
        if case let .failure(error) = self {
            return error
        }
        throw ErrorFunctionThrowsError.error
    }
    private enum ErrorFunctionThrowsError: Error { case error }
}

typealias Account = (email: String, name: String, description: String)

final class EmailManager: ObservableObject {

    @Published var emails: [MCOIMAPMessage] = []
    @Published var token: String = ""
    @Published var total_email_quantity = 0
    @Published var total_unread_quantity = 0
    @Published var download_progress: CGFloat = 0
    @Published var download_quantity = 1
    @Published var downloaded_number = 0
    @Published var hide_downloader: Bool = true
    @Published var show_checking: Bool = false
    @Published var folders: [mail_folder_item] = [
        mail_folder_item(name: "Inbox",     image: "inmbox",   path: "INBOX"),
        mail_folder_item(name: "Drafts",    image: "draftsmbox", path: "[Gmail]/Drafts"),
        mail_folder_item(name: "Sent Mail", image: "sentmbox", path: "[Gmail]/Sent Mail"),
        mail_folder_item(name: "Trash",     image: "trashmbox", path: "[Gmail]/Trash")
    ]
    var did_initial_fetch: Bool = false

    @Published var last_updated_date: Date = UserDefaults.standard.object(forKey: "mail_last_updated_date") as? Date ?? Date() {
        didSet { UserDefaults.standard.set(last_updated_date, forKey: "mail_last_updated_date") }
    }
    @Published var account_email: String = UserDefaults.standard.object(forKey: "mail_account_email") as? String ?? "" {
        didSet { UserDefaults.standard.set(account_email, forKey: "mail_account_email") }
    }
    @Published var account_name: String = UserDefaults.standard.object(forKey: "mail_account_name") as? String ?? "" {
        didSet { UserDefaults.standard.set(account_name, forKey: "mail_account_name") }
    }
    @Published var account_description: String = UserDefaults.standard.object(forKey: "mail_account_description") as? String ?? "" {
        didSet { UserDefaults.standard.set(account_description, forKey: "mail_account_description") }
    }
    
    private var idleOperation: MCOIMAPIdleOperation?

    var imap_session = MCOIMAPSession()
    var imap_fetch_session = MCOIMAPSession()

    let oauth2: OAuth2CodeGrant

    init(oauth2:OAuth2CodeGrant) {
        self.oauth2 = oauth2
        if account_email != "" {
            print(account_email)
            withFreshAccessToken { token in
                print(token)
                guard let token else {
                    print("EmailManager: no token yet. Trigger sign-in first.")
                    return
                }
                self.configureIMAPSessions(with: token)
                self.load_email_cache()
                self.setup_mailcore_idle_operation()
                self.get_unread_count()
                self.fetch_folders()
            }
        }
    }
    
    func suspendBackgroundMailOps() {
        idleOperation?.interruptIdle()
        imap_fetch_session.cancelAllOperations()
    }

    func resumeBackgroundMailOps() {
        setup_mailcore_idle_operation()
    }

    func do_initial_setup() {
        withFreshAccessToken { token in
            guard let token else { return }
            self.configureIMAPSessions(with: token)
            self.load_email_cache()
            self.setup_mailcore_idle_operation()
            self.get_unread_count()
            self.fetch_folders()
        }
    }

    func fixMCVOIPfor16() {
        if imap_session.responds(to: Selector(("setVoIPEnabled:"))) {
            imap_session.setValue(false, forKey: "voIPEnabled")
        } else {
            imap_session.isVoIPEnabled = false
        }
        if imap_fetch_session.responds(to: Selector(("setVoIPEnabled:"))) {
            imap_fetch_session.setValue(false, forKey: "voIPEnabled")
        } else {
            imap_fetch_session.isVoIPEnabled = false
        }
    }

    private func withFreshAccessToken(_ cb: @escaping (String?) -> Void) {
        if oauth2.hasUnexpiredAccessToken() {
            cb(oauth2.accessToken)
            return
        }
        if oauth2.refreshToken != nil {
            oauth2.doRefreshToken { _, error in
                if let error { print("OAuth refresh error: \(error)") }
                DispatchQueue.main.async { cb(error == nil ? self.oauth2.accessToken : nil) }
            }
        } else {
            cb(nil)
        }
    }

    private func configureIMAPSessions(with accessToken: String) {
        imap_session = MCOIMAPSession()
        fixMCVOIPfor16()
        imap_session.hostname = "imap.gmail.com"
        imap_session.username = account_email
        imap_session.port = 993
        imap_session.connectionType = .TLS
        imap_session.authType = .xoAuth2
        imap_session.oAuth2Token = accessToken
        imap_session.connectionLogger = { (connectionID, type, data) in
            if let data, let s = String(data: data, encoding: .utf8) {
                print("IMAP[\(connectionID)]: \(s)")
            }
        }
        imap_session.allowsFolderConcurrentAccessEnabled = true

        imap_fetch_session = MCOIMAPSession()
        fixMCVOIPfor16()
        imap_fetch_session.hostname = "imap.gmail.com"
        imap_fetch_session.username = account_email
        imap_fetch_session.port = 993
        imap_fetch_session.connectionType = .TLS
        imap_fetch_session.authType = .xoAuth2
        imap_fetch_session.oAuth2Token = accessToken
        imap_fetch_session.allowsFolderConcurrentAccessEnabled = true
    }

    private func reconfigureOnAuthFailure() {
        withFreshAccessToken { token in
            guard let token else { return }
            self.configureIMAPSessions(with: token)
            self.setup_mailcore_idle_operation()
        }
    }

    func load_email_cache() {
        do {
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("emails")
            let data = try Data(contentsOf: path)
            let temp_email_holder: [MCOIMAPMessage] =
                (try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [MCOIMAPMessage]) ?? []
            self.emails = temp_email_holder
            fetch_most_recent_emails()
        } catch {
            fetch_most_recent_emails()
            print("Cache load error: \(error.localizedDescription)")
        }
    }

    func fetch_folders() {
        withFreshAccessToken { token in
            guard let token else { return }
            self.imap_session.oAuth2Token = token

            let op = self.imap_session.fetchAllFoldersOperation()
            op?.start { error, rawFolders in
                if let error {
                    print("fetch_folders error: \(error)")
                    return
                }
                guard let folders = rawFolders as? [MCOIMAPFolder] else {
                    print("fetch_folders: unexpected folders type")
                    return
                }

                let filtered = folders.filter { f in
                    let p = f.path ?? ""
                    return p != "[Gmail]" && p != "[Gmail]/All Mail"
                }

                DispatchQueue.main.async {
                    for f in filtered {
                        let path = f.path ?? ""
                        if !self.folders.map({ $0.path }).contains(path) {
                            let name = path.replacingOccurrences(of: "[Gmail]/", with: "")
                            self.folders.append(
                                mail_folder_item(name: name, image: "mailbox", path: path)
                            )
                        }
                    }
                }
            }
        }
    }


    func setup_mailcore_idle_operation() {
        withFreshAccessToken { token in
            guard let token else { return }
            self.imap_fetch_session.oAuth2Token = token

            let idle_operation = self.imap_fetch_session.idleOperation(
                withFolder: "INBOX",
                lastKnownUID: UInt32(self.emails.last?.uid ?? 0)
            )
            idle_operation?.start { error in
                if let error {
                    print("IDLE error: \(error)")
                    self.reconfigureOnAuthFailure()
                    return
                }
                let statusOperation = self.imap_fetch_session.folderInfoOperation("INBOX")
                statusOperation?.start { (_, _) in
                    let startUID = UInt64(self.emails.last?.uid ?? 0) + 1
                    let uids = MCOIndexSet(range: MCORangeMake(startUID, 50))
                    let requestKind: MCOIMAPMessagesRequestKind = [.headers, .extraHeaders, .fullHeaders, .structure, .flags]

                    let pre = self.imap_fetch_session.fetchMessagesOperation(withFolder: "INBOX",
                                                                             requestKind: requestKind,
                                                                             uids: uids)
                    pre?.start { (_, msg, _) in
                        self.download_quantity = msg?.count ?? 1
                        if (msg?.count ?? 0) != 0 {
                            self.hide_downloader = false
                            self.show_checking = true
                        }

                        let fetch = self.imap_fetch_session.fetchMessagesOperation(withFolder: "INBOX",
                                                                                   requestKind: requestKind,
                                                                                   uids: uids)
                        fetch?.start { (err, msg, _) in
                            if let err { print("IDLE fetch error: \(err)") }
                            for message in msg ?? [] {
                                if !self.emails.map({ $0.uid }).contains(message.uid) {
                                    self.emails.append(contentsOf: msg ?? [])
                                } else if let idx = self.emails.firstIndex(where: { $0.uid == message.uid }) {
                                    if self.emails[idx].flags != message.flags {
                                        self.emails[idx].flags = message.flags
                                    }
                                }
                            }
                        }
                        self.last_updated_date = Date()
                        pre?.progress = { _ in }

                        fetch?.progress = { (current: UInt32) in
                            self.show_checking = false
                            self.downloaded_number = Int(current)
                            withAnimation {
                                self.download_progress = CGFloat(self.downloaded_number) / CGFloat(self.download_quantity)
                                if self.download_progress == 1 {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        self.hide_downloader = true
                                        self.download_quantity = 0
                                        self.download_progress = 0
                                        self.downloaded_number = 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func get_unread_count() {
        withFreshAccessToken { token in
            guard let token else { return }
            self.imap_session.oAuth2Token = token

            let op = self.imap_session.folderStatusOperation("INBOX")
            op?.start { (_, status) in
                self.total_unread_quantity = Int(status?.unseenCount ?? 0)
            }
        }
    }

    func perform_refresh_emails(batchSize: UInt64 = 50) {
        withFreshAccessToken { token in
            guard let token else { return }

            self.imap_session.authType = .xoAuth2
            self.imap_session.username = self.account_email
            self.imap_session.oAuth2Token = token

            let infoOp = self.imap_session.folderInfoOperation("INBOX")
            infoOp?.start { [weak self] (_, info) in
                guard let self = self, let info = info else { return }

                self.total_email_quantity = Int(info.messageCount)
                let serverUidNext = info.uidNext
                let localMaxUID: UInt32 = self.emails.reduce(0) { max($0, $1.uid) }

                guard serverUidNext > localMaxUID + 1 else {
                    self.last_updated_date = Date()
                    return
                }

                let deltaCount = UInt64(serverUidNext - (localMaxUID + 1))
                let length = min(batchSize, deltaCount)
                let start  = UInt64(localMaxUID + 1)

                let uids = MCOIndexSet(range: MCORange(location: start, length: length))
                
                guard let uids = uids else {return}
                
                self.fetchAndMerge(uids: uids)
            }
        }
    }

    func fetch_most_recent_emails(batchSize: UInt64 = 50) {
        withFreshAccessToken { token in
            guard let token else { return }

            self.imap_session.authType = .xoAuth2
            self.imap_session.username = self.account_email
            self.imap_session.oAuth2Token = token

            let infoOp = self.imap_session.folderInfoOperation("INBOX")
            infoOp?.start { [weak self] (_, info) in
                guard let self = self, let info = info else { return }

                self.total_email_quantity = Int(info.messageCount)
                let serverUidNext = info.uidNext

                let localMaxUID = self.emails.reduce(UInt32(0)) { max($0, $1.uid) }

                if localMaxUID == 0 {
                    let total = serverUidNext > 0 ? UInt64(serverUidNext - 1) : 0
                    guard total > 0 else { return }

                    let length: UInt64 = min(batchSize, total)
                    let start = UInt64(serverUidNext) - length
                    let uids = MCOIndexSet(range: MCORange(location: start, length: length))
                    
                    guard let uids = uids else {return}

                    self.fetchAndMerge(uids: uids)
                    return
                }

                if serverUidNext <= localMaxUID + 1 {
                    return
                }

                let deltaCount = UInt64(serverUidNext - (localMaxUID + 1))
                let length = min(batchSize, deltaCount)
                let start = UInt64(localMaxUID + 1)
                let uids = MCOIndexSet(range: MCORange(location: start, length: length))
                
                guard let uids = uids else {return}

                self.fetchAndMerge(uids: uids)
            }
        }
    }

    private func fetchAndMerge(uids: MCOIndexSet) {
        self.hide_downloader = false
        self.show_checking = true
        self.download_quantity = Int(uids.count())

        let kind: MCOIMAPMessagesRequestKind = [.headers, .extraHeaders, .structure, .flags]
        let op = self.imap_session.fetchMessagesOperation(withFolder: "INBOX", requestKind: kind, uids: uids)

        op?.start { [weak self] (err, msgs, _) in
            guard let self = self else { return }
            if let err = err { print("fetchAndMerge error:", err); }

            let bound = 200
            let incoming = (msgs ?? []).filter { !$0.flags.contains(.deleted) }

            var existingUIDs = Set(self.emails.map { $0.uid })

            for m in incoming.sorted(by: { $0.uid < $1.uid }) {
                if !existingUIDs.contains(m.uid) {
                    self.emails.append(m)
                    existingUIDs.insert(m.uid)
                } else if let idx = self.emails.firstIndex(where: { $0.uid == m.uid }) {
                    if self.emails[idx].flags != m.flags {
                        self.emails[idx].flags = m.flags
                    }
                }
            }

            if self.emails.count > bound {
                self.emails.sort(by: { $0.uid < $1.uid })
                self.emails = Array(self.emails.suffix(bound))
            }

            self.show_checking = false
            self.last_updated_date = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.hide_downloader = true
                self.download_quantity = 0
                self.download_progress = 0
                self.downloaded_number = 0
            }
        }

        op?.progress = { [weak self] (current: UInt32) in
            guard let self = self, self.download_quantity > 0 else { return }
            self.downloaded_number = Int(current)
            withAnimation {
                self.download_progress = CGFloat(self.downloaded_number) / CGFloat(self.download_quantity)
            }
        }
    }


    func fetch_past_emails() {
        withFreshAccessToken { token in
            guard let token else { return }
            self.imap_session.oAuth2Token = token

            let statusOperation = self.imap_session.folderStatusOperation("INBOX")
            statusOperation?.start { (_, _) in
                let computed_uid = max(1, Int(self.emails.first?.uid ?? 0) - 26)
                let min_range: UInt64 = UInt64(computed_uid)
                let max_range: UInt64 = UInt64(self.emails.first?.uid ?? 0)
                if min_range != max_range {
                    let uids = MCOIndexSet(range: MCORange(location: min_range, length: 25))
                    let kind: MCOIMAPMessagesRequestKind = [.headers, .extraHeaders, .fullHeaders, .structure, .flags]

                    let fetch = self.imap_session.fetchMessagesOperation(withFolder: "INBOX",
                                                                         requestKind: kind,
                                                                         uids: uids)
                    fetch?.start { (err, msg, _) in
                        if let err { print("fetch_past error: \(err)") }
                        self.emails.insert(contentsOf: msg ?? [], at: 0)
                    }
                }
            }
        }
    }

    func resetup_imap_session(completion: @escaping ()->()) {
        withFreshAccessToken { token in
            guard let token else { return }
            self.configureIMAPSessions(with: token)
            completion()
        }
    }
    func setup_imap_session() {
        withFreshAccessToken { token in
            guard let token else { return }
            self.configureIMAPSessions(with: token)
        }
    }

    func re_establish_OAuth(completion: @escaping ()->()) {
        let loader = OAuth2DataLoader(oauth2: oauth2)
        loader.alsoIntercept403 = true
        if oauth2.hasUnexpiredAccessToken() == false {
            oauth2.doRefreshToken { _,_ in
                DispatchQueue.main.async {
                    self.token = self.oauth2.accessToken ?? ""
                    self.imap_session.cancelAllOperations()
                    self.configureIMAPSessions(with: self.token)
                    self.setup_mailcore_idle_operation()
                    self.resetup_imap_session { completion() }
                }
            }
            oauth2.afterAuthorizeOrFail = { _, error in
                if let error { print("OAuth afterAuthorizeOrFail: \(error)") }
            }
            self.imap_fetch_session.oAuth2Token = token
        } else {
            completion()
        }
    }
    func establish_OAuth() {
        let loader = OAuth2DataLoader(oauth2: oauth2)
        loader.alsoIntercept403 = true
        if oauth2.accessToken == nil {
            if oauth2.refreshToken == nil {
                do {
                    let url = try oauth2.authorizeURL(params: nil)
                    try oauth2.authorizer.openAuthorizeURLInBrowser(url)
                } catch { print(error) }
            } else {
                oauth2.doRefreshToken { _,_ in }
            }
        } else if oauth2.hasUnexpiredAccessToken() == false {
            oauth2.doRefreshToken { _,_ in }
        }
        oauth2.afterAuthorizeOrFail = { _, error in
            if let error { print("OAuth afterAuthorizeOrFail: \(error)") }
        }
        token = oauth2.accessToken ?? ""
    }
    func initial_establish_OAuth(completion: @escaping ()->()) {
        let loader = OAuth2DataLoader(oauth2: oauth2)
        loader.alsoIntercept403 = true
        if oauth2.accessToken == nil {
            if oauth2.refreshToken == nil {
                do {
                    let url = try oauth2.authorizeURL(params: nil)
                    try oauth2.authorizer.openAuthorizeURLInBrowser(url)
                } catch { print(error) }
            } else {
                oauth2.doRefreshToken { _,_ in }
            }
        } else if oauth2.hasUnexpiredAccessToken() == false {
            oauth2.doRefreshToken { _,_ in }
        }
        oauth2.afterAuthorizeOrFail = { _, error in
            if let error { print("OAuth afterAuthorizeOrFail: \(error)") }
        }
        token = oauth2.accessToken ?? ""
        completion()
    }

    func retrieve_emails() {
        withFreshAccessToken { token in
            guard let token else { return }
            self.imap_session.oAuth2Token = token

            let folder = "INBOX"
            let uids = MCOIndexSet(range: MCORangeMake(1, 50))
            let kind: MCOIMAPMessagesRequestKind = [.headers, .extraHeaders, .fullHeaders, .structure, .flags]

            DispatchQueue.global(qos: .background).async {
                do {
                    let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent("emails")
                    let data = try Data(contentsOf: path)
                    let temp: [MCOIMAPMessage] =
                        (try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [MCOIMAPMessage]) ?? []
                    DispatchQueue.main.async { self.emails = temp }
                } catch {
                    print("Cache read error: \(error.localizedDescription)")
                }

                if self.emails.isEmpty {
                    let fetch = self.imap_session.fetchMessagesOperation(withFolder: folder,
                                                                         requestKind: kind,
                                                                         uids: uids)
                    let statusOp = self.imap_session.folderStatusOperation("INBOX")
                    statusOp?.start { (_, status) in
                        print(status?.uidNext as Any)
                    }
                    fetch?.start { (err, msg, _) in
                        if let err { print("retrieve_emails error: \(err)") }
                        self.emails = msg ?? []
                        do {
                            let key_archive = try NSKeyedArchiver.archivedData(withRootObject: msg ?? [],
                                                                               requiringSecureCoding: false)
                            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                                .appendingPathComponent("emails")
                            try key_archive.write(to: path)
                        } catch { print("Cache write error: \(error)") }
                    }
                }
            }
        }
    }

    func update_emails() {
        withFreshAccessToken { token in
            guard let token else { return }
            self.imap_session.oAuth2Token = token

            let requestKind: MCOIMAPMessagesRequestKind = .headers
            let uids = MCOIndexSet(range: MCORangeMake(1, 64))
            let update = self.imap_session.syncMessages(withFolder: "INBOX",
                                                        requestKind: requestKind,
                                                        uids: uids,
                                                        modSeq: UInt64(self.emails.last?.modSeqValue ?? 0))
            update?.start { (err, msg, _) in
                if let err { print("update_emails error: \(err)") }
                DispatchQueue.global(qos: .background).async {
                    self.emails.append(contentsOf: msg ?? [])
                }
            }
        }
    }
    func update_emails_2() {
        withFreshAccessToken { token in
            guard let token else { return }
            self.imap_session.oAuth2Token = token

            let statusOp = self.imap_session.folderStatusOperation("INBOX")
            statusOp?.start { (_, status) in
                let kind: MCOIMAPMessagesRequestKind = [.headers, .extraHeaders, .fullHeaders, .structure, .flags]
                let uids = MCOIndexSet(range: MCORangeMake(
                    UInt64(self.emails.last?.uid ?? 0),
                    UInt64(status?.uidNext ?? 0))
                )
                let update = self.imap_session.syncMessages(withFolder: "INBOX",
                                                            requestKind: kind,
                                                            uids: uids,
                                                            modSeq: UInt64(self.emails.last?.modSeqValue ?? 0))
                update?.start { (err, msg, _) in
                    if let err { print("update_emails_2 error: \(err)") }
                    DispatchQueue.global(qos: .background).async {
                        self.emails.append(contentsOf: msg ?? [])
                    }
                }
            }
        }
    }

    func sendEmail(to: [String],
                   cc: [String] = [],
                   bcc: [String] = [],
                   subject: String,
                   bodyPlain: String,
                   completion: @escaping (Result<Void, Error>) -> Void)
    {
        withFreshAccessToken { token in
            guard let token else {
                completion(.failure(NSError(domain: "oauth", code: 1,
                                            userInfo: [NSLocalizedDescriptionKey: "No OAuth token"])))
                return
            }

            let builder = MCOMessageBuilder()
            let fromAddr = MCOAddress(displayName: self.account_name.isEmpty ? nil : self.account_name,
                                      mailbox: self.account_email)
            builder.header.from = fromAddr
            builder.header.to = to.map { MCOAddress(mailbox: $0) }
            builder.header.cc = cc.map { MCOAddress(mailbox: $0) }
            builder.header.bcc = bcc.map { MCOAddress(mailbox: $0) }
            builder.header.subject = subject
            builder.textBody = bodyPlain

            guard let rfc822 = builder.data() else {
                completion(.failure(NSError(domain: "smtp", code: 2,
                                            userInfo: [NSLocalizedDescriptionKey: "Failed to build message"])))
                return
            }

            let smtp = MCOSMTPSession()
            smtp.hostname = "smtp.gmail.com"
            smtp.port = 465
            smtp.connectionType = .TLS
            smtp.username = self.account_email
            smtp.authType = .xoAuth2
            smtp.oAuth2Token = token
            smtp.connectionLogger = { (connectionID, type, data) in
                if let data, let s = String(data: data, encoding: .utf8) {
                    print("SMTP[\(connectionID)]: \(s)")
                }
            }

            let op = smtp.sendOperation(with: rfc822)
            op?.start { error in
                if let error {
                    print("SMTP send error: \(error.localizedDescription)")
                    self.withFreshAccessToken { newToken in
                        guard let newToken else { return completion(.failure(error)) }
                        smtp.oAuth2Token = newToken
                        let retry = smtp.sendOperation(with: rfc822)
                        retry?.start { retryErr in
                            if let retryErr { completion(.failure(retryErr)) }
                            else { completion(.success(())) }
                        }
                    }
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func signOut() {
        oauth2.forgetTokens()
        
        account_email = ""
        account_name = ""
        account_description = ""
        token = ""
        
        imap_session.disconnectOperation().start { _ in }
        imap_fetch_session.disconnectOperation().start { _ in }
        
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("emails")
        try? FileManager.default.removeItem(at: path)
        
        print("Signed out and cleared local data.")
    }
    
}

extension UserDefaults {
    func set(date: Date?, forKey key: String){ self.set(date, forKey: key) }
    func date(forKey key: String) -> Date? { return self.value(forKey: key) as? Date }
}

extension Date {
    var calendarDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        return formatter.string(from: self)
    }
    var timeDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
    var yearsFromNow: Int {
        return Calendar.current.dateComponents([.year], from: self, to: Date()).year!
    }
    var monthsFromNow: Int {
        return Calendar.current.dateComponents([.month], from: self, to: Date()).month!
    }
    var weeksFromNow: Int {
        return Calendar.current.dateComponents([.weekOfYear], from: self, to: Date()).weekOfYear!
    }
    var daysFromNow: Int {
        return Calendar.current.dateComponents([.day], from: self, to: Date()).day!
    }
    var isInYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    var hoursFromNow: Int {
        return Calendar.current.dateComponents([.hour], from: self, to: Date()).hour!
    }
    var minutesFromNow: Int {
        return Calendar.current.dateComponents([.minute], from: self, to: Date()).minute!
    }
    var secondsFromNow: Int {
        return Calendar.current.dateComponents([.second], from: self, to: Date()).second!
    }
    var relativeTime: String {
        if daysFromNow > 0 && daysFromNow <= 7 {
            if isInYesterday {
                return "Yesterday"
            } else {
                return DateFormatter().weekdaySymbols[Calendar.current.component(.weekday, from: self) - 1]
            }
            
        }
        if daysFromNow <= 0 {
            if Calendar.current.isDateInToday(self) {
                let formatter = DateFormatter()
                formatter.dateFormat = "h:mm a"
                return formatter.string(from: self)
            } else {
                return "Yesterday"
            }
        }
        else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d/yy"
            return formatter.string(from: self)
        }
        return ""
    }
}

struct mail_content_view: View {
    var body: some View {
        Spacer()
    }
}

struct mail_tool_bar: View {
    @Binding var current_nav_view: String
    @Binding var show_compose: Bool
    @Binding var show_move: Bool
    var delete_action: (() -> Void)?
    @EnvironmentObject var EmailManager: EmailManager
    var geometry:GeometryProxy
    var body: some View {
        ZStack {
            LinearGradient([(color: Color(red: 230/255, green: 230/255, blue: 230/255), location: 0), (color: Color(red: 180/255, green: 191/255, blue: 206/255), location: 0.04), (color: Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.51), (color: Color(red: 126/255, green: 148/255, blue: 176/255), location: 0.51), (color: Color(red: 110/255, green: 132/255, blue: 162/255), location: 1)], from: .top, to: .bottom).border_bottom(width: 1, edges: [.top], color: Color(red: 45/255, green: 48/255, blue: 51/255))//I just discovered it was much easier to do this...duh
            HStack {
                if current_nav_view == "Main" || current_nav_view == "Mailboxes" || current_nav_view == "Other" {
                    Button(action:{
                        EmailManager.perform_refresh_emails()
                    }) {
                        Image("UIButtonBarRefresh").shadow(color: Color.black.opacity(0.41), radius: 0, x: 0.0, y: -1)
                    }.padding(.leading, 12)
                    Spacer()
                    if EmailManager.hide_downloader {
                        Group {
                            Text("Updated").font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(.white).shadow(color: Color.black.opacity(0.41), radius: 0, x: 0.0, y: -1).offset(x:1)
                            Text(EmailManager.last_updated_date.calendarDate).font(.custom("Helvetica Neue Regular", fixedSize: 12)).foregroundColor(.white).shadow(color: Color.black.opacity(0.41), radius: 0, x: 0.0, y: -1)
                            Text(EmailManager.last_updated_date.timeDate).font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(.white).shadow(color: Color.black.opacity(0.41), radius: 0, x: 0.0, y: -1).offset(x:-1)
                        }
                    } else {
                        if EmailManager.show_checking {
                            HStack(spacing: 3) {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.9, anchor: .center)
                                Text("Checking for Mail..").font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(.white).shadow(color: Color.black.opacity(0.41), radius: 0, x: 0.0, y: -1).offset(x:1)
                            }
                        } else {
                            VStack(spacing: 5) {
                                Text("Downloading \(EmailManager.downloaded_number) of \(EmailManager.download_quantity)").font(.custom("Helvetica Neue Bold", fixedSize: 12)).foregroundColor(.white).shadow(color: Color.black.opacity(0.41), radius: 0, x: 0.0, y: -1)
                                ZStack {
                                    Image("mail_progressbkgnd").frame(width: geometry.size.width/1.9, height: 11)
                                    HStack(spacing: 0) {
                                        Image("mail_progressfill").frame(width: (geometry.size.width/1.9 - 2.25)*EmailManager.download_progress, height: 8, alignment: .leading).padding(.leading, 0).padding(.trailing, (geometry.size.width/1.9 - 2.25) - (geometry.size.width/1.9 - 2.25)*EmailManager.download_progress)
                                    }.frame(width: geometry.size.width/1.9 - 2.25, height: 8).offset(y: -0.665)
                                }
                            }
                        }
                    }
                    Spacer()
                    Button(action:{
                        withAnimation(.linear(duration:0.35)) {
                            show_compose = true
                        }
                    }) {
                        Image("UIButtonBarCompose").shadow(color: Color.black.opacity(0.41), radius: 0, x: 0.0, y: -1)
                    }.padding(.trailing, 12)
                } else {
                    Button(action:{
                        EmailManager.perform_refresh_emails()
                    }) {
                        Image("UIButtonBarRefresh").shadow(color: Color.black.opacity(0.41), radius: 0, x: 0.0, y: -1)
                    }.padding(.leading, 12)
                    Spacer()
                    Button(action:{
                        withAnimation(.linear(duration:0.35)) {
                            show_move = true
                        }
                    }) {
                        Image("UIButtonBarOrganize").shadow(color: Color.black.opacity(0.41), radius: 0, x: 0.0, y: -1)
                    }
                    Spacer()
                    Button(action:{
                        delete_action?()
                    }) {
                        Image("UIButtonBarTrash").shadow(color: Color.black.opacity(0.41), radius: 0, x: 0.0, y: -1)
                    }
                    Spacer()
                    Button(action:{
                    }) {
                        Image("UIButtonBarReply").shadow(color: Color.black.opacity(0.41), radius: 0, x: 0.0, y: -1)
                    }
                    Spacer()
                    Button(action:{
                        withAnimation(.linear(duration:0.35)) {
                            show_compose = true
                        }
                    }) {
                        Image("UIButtonBarCompose").shadow(color: Color.black.opacity(0.41), radius: 0, x: 0.0, y: -1)
                    }.padding(.trailing, 12)
                }
            }.transition(.opacity)
        }
        
    }
}

struct setup_mail_view: View {
    @Binding var current_nav_view: String?
    @Binding var forward_or_backward: Bool?
    @Binding var show_alert:Bool
    @Binding var increase_brightness: Bool
    var content = [list_row(title: "", content: AnyView(mail_content(image: "exchange"))), list_row(title: "", content: AnyView(mail_content(image: "mobileme"))), list_row(title: "", content: AnyView(mail_content(image: "gmail"))), list_row(title: "", content: AnyView(mail_content(image: "yahoo"))), list_row(title: "", content: AnyView(mail_content(image: "aol"))),  list_row(title: "", content: AnyView(mail_content_other()))]
    var body: some View {
        ZStack {
            settings_main_list()
            VStack(spacing:0) {
                status_bar_in_app().frame(minHeight: 24, maxHeight:24).zIndex(1)
                generic_title_bar(title: "Welcome to Mail").frame(height: 60)
                ScrollView {
                    VStack {
                        Spacer().frame(height: 15)
                        list_section_content_only_large(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content:content)
                        Spacer()
                    }
                }
            }
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

extension Int {
    private static var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        
        return numberFormatter
    }()
    
    var delimiter: String {
        return Int.numberFormatter.string(from: NSNumber(value: self)) ?? ""
    }
}

func debugOAuth(_ o: OAuth2) {
    print("=== OAUTH DEBUG ===")
    print("Type:", type(of: o))
    print("clientId:", o.clientId ?? "nil")
    print("authURL:", o.authURL.absoluteString)
    print("tokenURL:", o.tokenURL?.absoluteString)
    print("redirectURIs:", o.redirect ?? "")
    print("scopes:", (o as? OAuth2CodeGrant)?.scope ?? "nil")
    print("====================")
}

//struct mail_account_adder: View {
//    @State var account_name: String = ""
//    @State var account_email: String = ""
//    @State var account_description: String = ""
//    @State var account_password: String = ""
//    @State private var showSignIn = false
//    @Binding var show_add_account: Bool
//    @EnvironmentObject var EmailManager: EmailManager
//    @State private var authInFlight = false
//    var body: some View {
//        VStack(spacing: 0) {
//            Spacer().frame(height: 24)
//            generic_title_bar_cancel_next(title: "Gmail", cancel_action: {
//                withAnimation(.linear(duration:0.35)) {
//                    show_add_account = false
//                }
//            }, save_action: {
////                if account_email != "" && account_name != "" && account_description != "" {
////                    EmailManager.account_email = account_email
////                    EmailManager.account_name = account_name
////                    EmailManager.account_description = account_description
////                    let saveSuccessful: Bool = KeychainWrapper.standard.set(account_password, forKey: "email_password")
////                    if account_email == EmailManager.account_email && account_name == EmailManager.account_name && account_description == EmailManager.account_description && saveSuccessful {
////                        print("doing initial setup")
////                        EmailManager.do_initial_setup()
////                    }
////                }
//              //  startAuth()
//
//               // if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
//                    startExternalGoogleSignIn()
//               // }
//
//            }, show_cancel: true, show_save: true).frame(height: 60)
//            ZStack {
//                settings_main_list()
//                VStack(spacing: 0) {
//                    ZStack {
//                        RoundedRectangle(cornerRadius: 10).fill(Color.white).overlay(RoundedRectangle(cornerRadius: 10)
//                                                                                        .stroke(Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1.25))
//                        VStack(spacing:0) {
//                            ZStack {
//                                Rectangle().fill(Color.clear).frame(height:50).border_bottom(width: 1.25, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))
//                                HStack {
//                                    Text("Name").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).padding(.leading, 12)
//                                    TextField("John Appleseed", text: $account_name).font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255))
//                                }
//                            }.frame(height: 50)
//                            ZStack {
//                                Rectangle().fill(Color.clear).frame(height:50).border_bottom(width: 1.25, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))
//                                HStack {
//                                    Text("Address").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).padding(.leading, 12)
//                                    TextField("example@gmail.com", text: $account_email).font(.custom("Helvetica Neue Regular", fixedSize: 18)).keyboardType(.emailAddress).autocapitalization(.none).disableAutocorrection(true).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255))
//                                }
//                            }.frame(height: 50)
//                            ZStack {
//                                Rectangle().fill(Color.clear).frame(height:50).border_bottom(width: 1.25, edges: [.bottom], color: Color(red: 171/255, green: 171/255, blue: 171/255))
//                                HStack {
//                                    Text("Password").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).padding(.leading, 12)
//                                    SecureField("Required", text: $account_password).font(.custom("Helvetica Neue Regular", fixedSize: 18)).keyboardType(.default).autocapitalization(.none).disableAutocorrection(true).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255))
//                                }
//                            }.frame(height: 50)
//                            ZStack {
//                                Rectangle().fill(Color.clear).frame(height:50)
//                                HStack {
//                                    Text("Description").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).padding(.leading, 12)
//                                    TextField("My Gmail Account", text: $account_description).font(.custom("Helvetica Neue Regular", fixedSize: 18)).foregroundColor(Color(red: 62/255, green: 83/255, blue: 131/255))
//                                }
//                            }.frame(height: 50)
//                        }
//                    }.frame(height:200).padding([.leading, .trailing], 12).padding(.top, 8)
//                    Spacer().frame(height: 15)
//                    Group {
//                    Text("To sign in, please either enable less secure apps or generate an app specific password.\n") +
//                        Text("Learn more.").underline()
//                    }.multilineTextAlignment(.center).lineLimit(nil).foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Regular", fixedSize: 15)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24).onTapGesture {
//                        guard let url = URL(string: "https://www.youtube.com/watch?v=Ee7PDsbfOUI") else { return }
//                        UIApplication.shared.open(url)
//                    }
//                    Spacer()
//                }
//            }
//        }
//    }
//    private func startAuth() {
//        guard !authInFlight else { return }
//        authInFlight = true
//        debugOAuth(EmailManager.oauth2)
//        let ctx = EmailManager.oauth2.authConfig.authorizeContext
//        print("authorizeContext:", String(describing: ctx))
//        EmailManager.oauth2.authorize { _, error in
//            DispatchQueue.main.async {
//                authInFlight = false
//                if let error = error {
//                    print("OAuth authorize error:", error)
//                    return
//                }
//
//                var email = emailFromIDToken(EmailManager.oauth2.idToken)
//
//                  func startWith(email: String) {
//                      DispatchQueue.main.async {
//                          EmailManager.account_email = email
//                          EmailManager.do_initial_setup()
//                      }
//                  }
//
//                if let e = email {
//                    startWith(email: e)
//                }
//            }
//        }
//    }
//
//    func startExternalGoogleSignIn() {
//
//        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
//        let oauth2 = app.oauth2
//
//        oauth2.authConfig.authorizeEmbedded = false
//        oauth2.authConfig.ui.useSafariView = false
//        oauth2.authConfig.authorizeContext = nil
//
//        do {
//            let url = try oauth2.authorizeURL(params: nil)
//
//            print("AUTH URL:", url.absoluteString)
//            DispatchQueue.main.async {
//                    UIApplication.shared.open(url, options: [:]) { ok in
//                        if !ok { print("UIApplication.open returned false") }
//                    }
//                }
//
//        } catch {
//            print("OAuth start error:", error)
//        }
//
//        oauth2.afterAuthorizeOrFail = { params, error in
//            if let error = error {
//                print("OAuth failed:", error)
//                return
//            }
//            if let idToken = oauth2.idToken, let email = emailFromIDToken(idToken) {
//                DispatchQueue.main.async {
//                    EmailManager.account_email = email
//                    EmailManager.do_initial_setup()
//                }
//            }
//        }
//    }
//
//    func emailFromIDToken(_ idToken: String?) -> String? {
//        guard let id = idToken else { return nil }
//        let parts = id.split(separator: ".")
//        guard parts.count >= 2 else { return nil }
//        var s = String(parts[1])
//        s = s.replacingOccurrences(of: "-", with: "+")
//             .replacingOccurrences(of: "_", with: "/")
//        while s.count % 4 != 0 { s.append("=") }
//
//        guard let data = Data(base64Encoded: s),
//              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//              let email = json["email"] as? String else { return nil }
//        return email
//    }
//}
