import Foundation
import Combine
import Security
import CommonCrypto

struct OldOSPasscodeRecord: Codable, Equatable {
    var salt: Data
    var verifier: Data
    var rounds: UInt32 = 120_000
    var simple: Bool
    var grace: TimeInterval = 0
    var failures = 0
    var blockedUntil: Date?
}

protocol OldOSPasscodeVault {
    func load() throws -> Data?
    func save(_ data: Data) throws
    func remove() throws
}

struct OldOSKeychainPasscodeVault: OldOSPasscodeVault {
    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: (Bundle.main.bundleIdentifier ?? "OldOS") + ".passcode.v1",
         kSecAttrAccount as String: "local-passcode"]
    }
    func load() throws -> Data? {
        var q = query; q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
        return data
    }
    func save(_ data: Data) throws {
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var q = query; q[kSecValueData as String] = data
            q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let added = SecItemAdd(q as CFDictionary, nil)
            guard added == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(added)) }
        } else if status != errSecSuccess { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }
    func remove() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }
}

enum OldOSPasscodeHash {
    static func derive(_ text: String, salt: Data, rounds: UInt32) throws -> Data {
        let bytes = Array(text.utf8)
        var result = [UInt8](repeating: 0, count: 32)
        let status = bytes.withUnsafeBytes { password in
            salt.withUnsafeBytes { saltBytes in
                CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), password.baseAddress?.assumingMemoryBound(to: Int8.self), bytes.count,
                                    saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self), salt.count,
                                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), rounds, &result, result.count)
            }
        }
        guard status == kCCSuccess else { throw NSError(domain: "OldOS.Passcode", code: Int(status)) }
        return Data(result)
    }
    static func equal(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }
    static func valid(_ text: String, simple: Bool) -> Bool {
        simple ? text.utf8.count == 4 && text.utf8.allSatisfy { (48...57).contains($0) } : !text.isEmpty && text.utf8.count <= 128
    }
}

final class OldOSPasscodeStore: ObservableObject {
    enum Verification { case accepted, rejected, blocked(Date), cancelled, unavailable(String) }
    static let shared = OldOSPasscodeStore()
    @Published private(set) var record: OldOSPasscodeRecord?
    @Published private(set) var storageError: String?
    @Published private(set) var isLocked = true
    @Published var presentingUnlock = false
    @Published private(set) var inactive = false
    @Published private(set) var lockGeneration = 0
    @Published private(set) var preferredSimple: Bool
    private let vault: OldOSPasscodeVault
    private let defaults: UserDefaults
    private let crypto = DispatchQueue(label: "OldOS.Passcode.Crypto", qos: .userInitiated)
    private var authorizationGeneration = 0
    private var lockedAt = Date()
    private var forceAuthentication = true
    static let graceChoices: [TimeInterval] = [0, 60, 300, 900, 3600, 14400]
    var enabled: Bool { record != nil || storageError != nil }
    var simple: Bool { record?.simple ?? preferredSimple }
    var grace: TimeInterval { record?.grace ?? 0 }
    var failures: Int { record?.failures ?? 0 }
    var blockedUntil: Date? { record?.blockedUntil }

    init(vault: OldOSPasscodeVault = OldOSKeychainPasscodeVault(), defaults: UserDefaults = .standard) {
        self.vault = vault; self.defaults = defaults
        preferredSimple = defaults.object(forKey: "OldOS.Passcode.simple") as? Bool ?? true
        do {
            if defaults.object(forKey: "OldOS.Passcode.install") == nil {
                try vault.remove()
                defaults.set(UUID().uuidString, forKey: "OldOS.Passcode.install")
            }
            if let data = try vault.load() {
                let decoded = try JSONDecoder().decode(OldOSPasscodeRecord.self, from: data)
                guard decoded.salt.count >= 16, decoded.verifier.count == 32, decoded.rounds >= 10_000, decoded.rounds <= 1_000_000, decoded.failures >= 0,
                      Self.graceChoices.contains(decoded.grace) else { throw NSError(domain:"OldOS.Passcode",code:1) }
                record = decoded
            }
        } catch { storageError = "The passcode could not be loaded. Unlock your iPhone and reopen OldOS." }
    }
    func requiresPasscode(at date: Date = Date()) -> Bool {
        enabled && (forceAuthentication || grace == 0 || date.timeIntervalSince(lockedAt) >= grace || (blockedUntil ?? .distantPast) > date)
    }
    func sceneInactive() { inactive = true }
    func sceneActive() { inactive = false }
    func lockForBackground(at date: Date = Date()) {
        inactive = true
        if !isLocked { lockedAt = date }
        isLocked = true; presentingUnlock = false
        authorizationGeneration += 1; lockGeneration += 1
    }
    func completeUnlock() {
        forceAuthentication = false; isLocked = false; presentingUnlock = false
    }
    func cancelUnlock() { presentingUnlock = false }
    func setPreferredSimple(_ simple: Bool) {
        guard !enabled else { return }
        preferredSimple = simple; defaults.set(simple, forKey: "OldOS.Passcode.simple")
    }
    private func persist(_ value: OldOSPasscodeRecord) throws {
        try vault.save(JSONEncoder().encode(value)); record = value
    }
    func verify(_ passcode: String, at date: Date = Date(), completion: @escaping (Verification) -> Void) {
        guard let snapshot = record else { completion(.unavailable(storageError ?? "Passcode is not enabled.")); return }
        if let until = snapshot.blockedUntil, until > date { completion(.blocked(until)); return }
        let generation = authorizationGeneration
        crypto.async {
            let result = Result { try OldOSPasscodeHash.derive(passcode, salt: snapshot.salt, rounds: snapshot.rounds) }
            DispatchQueue.main.async {
                guard self.authorizationGeneration == generation else { completion(.cancelled); return }
                do {
                    let digest = try result.get()
                    var next = snapshot
                    if OldOSPasscodeHash.equal(digest, snapshot.verifier) {
                        next.failures = 0; next.blockedUntil = nil
                        try self.persist(next); completion(.accepted)
                    } else {
                        next.failures += 1
                        let delays: [Int: TimeInterval] = [6:60, 7:300, 8:900]
                        if next.failures >= 6 { next.blockedUntil = date.addingTimeInterval(delays[next.failures] ?? 3600) }
                        try self.persist(next)
                        if let until = next.blockedUntil, until > date { completion(.blocked(until)) }
                        else { completion(.rejected) }
                    }
                } catch { completion(.unavailable("The passcode could not be checked. Please try again.")) }
            }
        }
    }
    func setPasscode(_ text: String, simple: Bool, completion: @escaping (String?) -> Void) {
        guard OldOSPasscodeHash.valid(text, simple: simple) else { completion(simple ? "Enter a 4 digit passcode." : "Enter a passcode of up to 128 bytes."); return }
        var bytes = [UInt8](repeating: 0, count:32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { completion("Unable to create a passcode. Please try again."); return }
        let salt = Data(bytes), generation = authorizationGeneration, grace = self.grace
        crypto.async {
            let result = Result { try OldOSPasscodeHash.derive(text, salt: salt, rounds:120_000) }
            DispatchQueue.main.async {
                guard self.authorizationGeneration == generation else { completion("Passcode setup was cancelled."); return }
                do {
                    let value = OldOSPasscodeRecord(salt:salt,verifier:try result.get(),simple:simple,grace:grace)
                    try self.persist(value)
                    self.preferredSimple = simple; self.defaults.set(simple,forKey:"OldOS.Passcode.simple")
                    self.authorizationGeneration += 1; completion(nil)
                } catch { completion("The passcode could not be saved. Please try again.") }
            }
        }
    }
    func turnOff() -> String? {
        do { try vault.remove(); record = nil; storageError = nil; authorizationGeneration += 1; return nil }
        catch { return "The passcode could not be removed. Please try again." }
    }
    func setGrace(_ value: TimeInterval) -> String? {
        guard Self.graceChoices.contains(value), var next = record else { return nil }
        next.grace = value
        do { try persist(next); return nil } catch { return "The setting could not be saved." }
    }
    static func graceTitle(_ seconds: TimeInterval, short: Bool = false) -> String {
        switch seconds {
        case 60: return short ? "After 1 min." : "After 1 minute"
        case 300: return short ? "After 5 min." : "After 5 minutes"
        case 900: return short ? "After 15 min." : "After 15 minutes"
        case 3600: return "After 1 hour"
        case 14400: return "After 4 hours"
        default: return "Immediately"
        }
    }
}

#if canImport(UIKit)
import SwiftUI
import UIKit
import AudioToolbox
import AVFoundation

private enum OldOSPasscodeUnlockSound {
    private static let queue = DispatchQueue(label:"OldOS.Passcode.UnlockSound")
    private static var player: AVAudioPlayer?
    static func play() {
        queue.async {
            if player == nil, let url = Bundle.main.url(forResource:"unlock",withExtension:"aiff") { player = try? AVAudioPlayer(contentsOf:url) }
            player?.currentTime = 0
            player?.play()
        }
    }
}

struct OldOSPasscodeStatus: View {
    @ObservedObject private var store = OldOSPasscodeStore.shared
    var body: some View {
        HStack(spacing:10) {
            Text(store.enabled ? "On" : "Off").font(.custom("Helvetica Neue",fixedSize:17)).foregroundColor(Color(red:0.22,green:0.31,blue:0.47))
            Image("UITableNext")
        }.padding(.trailing,12)
    }
}

private struct PasscodePlainButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label }
}

struct OldOSPasscodeNavigationHeader: View {
    let title: String
    var back: (() -> Void)? = nil
    var backTitle = "General"
    var cancel: (() -> Void)? = nil
    var nextTitle: String? = nil
    var next: (() -> Void)? = nil
    var nextEnabled = true
    var body: some View {
        ZStack {
            generic_title_bar(title:"")
            GeometryReader { geometry in
                let left: CGFloat = cancel != nil ? 81 : back == nil ? 10 : backTitle == "General" ? 89 : 117
                let right: CGFloat = nextTitle == nil ? 10 : 75
                let naturalWidth = (title as NSString).size(withAttributes:[.font:UIFont(name:"HelveticaNeue-Bold",size:22) ?? .boldSystemFont(ofSize:22)]).width
                let width = max(1,min(naturalWidth,geometry.size.width-left-right))
                Text(title).font(.custom("Helvetica Neue Bold",fixedSize:22)).foregroundColor(.white)
                    .shadow(color:.black.opacity(0.21),radius:0,y:-1)
                    .lineLimit(1).minimumScaleFactor(0.75).frame(width:width,height:60)
                    .position(x:min(max(geometry.size.width/2,left+width/2),geometry.size.width-right-width/2),y:30)
            }.allowsHitTesting(false)
            HStack {
                if let back {
                    Button(action:back) {
                        Image("Button2").resizable(capInsets:EdgeInsets(top:0,leading:30,bottom:0,trailing:20))
                            .frame(width:backTitle == "General" ? 154 : 210,height:66).scaleEffect(0.5)
                            .frame(width:backTitle == "General" ? 77 : 105,height:33)
                            .overlay(Text(backTitle).font(.custom("Helvetica Neue Bold",fixedSize:13)).foregroundColor(.white).shadow(color:.black.opacity(0.45),radius:0,y:-0.6).offset(y:-1))
                    }.buttonStyle(PasscodePlainButton())
                }
                if let cancel { tool_bar_rectangle_button(action:cancel,button_type:.blue_gray,content:"Cancel") }
                Spacer()
                if let nextTitle {
                    tool_bar_rectangle_button(action:next,button_type:.blue_gray,content:nextTitle)
                        .opacity(nextEnabled ? 1 : 0.5).allowsHitTesting(nextEnabled)
                }
            }.padding(.horizontal,6)
        }.frame(height:60)
    }
}

private struct PasscodeConfirmStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.background(
            Image(configuration.isPressed ? "passcode-UIPasscodeFieldButtonPressed" : "passcode-UIPasscodeFieldButton")
                .resizable(capInsets:EdgeInsets(top:10,leading:7,bottom:10,trailing:7))
        )
    }
}

private struct PasscodeDigitFields: View {
    let count: Int
    var settings = false
    var body: some View {
        HStack(spacing:10) {
            ForEach(0..<4) { index in
                Image("passcode-UIPasscodeFieldBackground")
                    .resizable(capInsets:EdgeInsets(top:10,leading:10,bottom:10,trailing:10))
                    .frame(width:63,height:52)
                    .brightness(settings ? 0.06 : 0)
                    .background(Color.white.opacity(settings ? 1 : 0.75))
                    .overlay {
                        if index < count { Circle().fill(Color.black).frame(width:16,height:16) }
                    }
                    .accessibilityLabel("Passcode digit \(index + 1)")
                    .accessibilityValue(index < count ? "Entered" : "Empty")
            }
        }.frame(width:282,height:52)
    }
}

private struct PasscodeNumericKeypad: View {
    let hasText: Bool
    let unlocking: Bool
    let action: (String) -> Void
    let cancel: () -> Void
    let emergency: () -> Void
    private let keys = ["1","2","3","4","5","6","7","8","9","emergency","0","delete"]
    var body: some View {
        ZStack(alignment:.topLeading) {
            (unlocking ? Color.black.opacity(0.2) : Color(red:0.38,green:0.42,blue:0.48)).frame(width:320,height:216)
            Image("passcode-DeviceLockKeypad").resizable().frame(width:320,height:216)
            VStack(spacing:0) {
                ForEach(0..<4) { row in
                    HStack(spacing:0) {
                        ForEach(0..<3) { column in
                            let index = row*3+column
                            let frame = OldOSPasscodeKeypadGeometry.cell(index)
                            Button {
                                RetroClockAudio.pickerTick()
                                let key = keys[index]
                                if key == "emergency" { if unlocking { emergency() } }
                                else if key == "delete", !hasText, unlocking { cancel() }
                                else { action(key) }
                            } label: {
                                ZStack {
                                    Color.clear
                                    if index == 9, unlocking { Text("Emergency\nCall").multilineTextAlignment(.center).font(.custom("Helvetica-Bold",fixedSize:13)).foregroundColor(.white).shadow(color:.black,radius:0,y:-1) }
                                    if index == 11 {
                                        if !hasText && unlocking { Text("Cancel").font(.custom("Helvetica-Bold",fixedSize:14)).foregroundColor(.white).shadow(color:.black,radius:0,y:-1) }
                                        else if hasText || !unlocking { Image("passcode-DeviceLockKeypadDelete") }
                                    }
                                }.frame(width:frame.width,height:frame.height).contentShape(Rectangle())
                            }
                            .buttonStyle(PasscodeKeyStyle(frame:frame))
                            .frame(width:frame.width,height:frame.height).contentShape(Rectangle())
                            .disabled(index == 9 && !unlocking || index == 11 && !hasText && !unlocking)
                            .accessibilityLabel(index == 9 ? "Emergency Call" : index == 11 ? (hasText ? "Delete" : "Cancel") : keys[index])
                        }
                    }
                }
            }
        }.frame(width:320,height:216)
    }
    private struct PasscodeKeyStyle: ButtonStyle {
        let frame: CGRect
        func makeBody(configuration: Configuration) -> some View {
            configuration.label.background(alignment:.topLeading) {
                Image("passcode-DeviceLockKeypadPressed").resizable().frame(width:320,height:216)
                    .offset(x:-frame.minX,y:-frame.minY).opacity(configuration.isPressed ? 1 : 0)
                    .allowsHitTesting(false)
                    .transaction { transaction in transaction.animation = nil; transaction.disablesAnimations = true }
            }.frame(width:frame.width,height:frame.height).clipped().contentShape(Rectangle())
        }
    }
}

enum OldOSPasscodeKeypadGeometry {
    static func cell(_ index:Int) -> CGRect {
        let column = index%3, row = index/3
        return CGRect(x:CGFloat(column)*107,y:CGFloat(row)*54,width:column == 2 ? 106 : 107,height:54)
    }
}

struct OldOSLockTransitionGeometry {
    let width: CGFloat
    let height: CGFloat
    let progress: CGFloat
    let departure: CGFloat
    var headerHeight: CGFloat = 110
    var footerHeight: CGFloat = 110
    var keyboardHeight: CGFloat { width / 320 * 216 }
    var footerTop: CGFloat { height-footerHeight-keyboardHeight*progress+(keyboardHeight+footerHeight)*departure }
    var keypadTop: CGFloat { height-keyboardHeight*progress+(keyboardHeight+footerHeight)*departure }
    var fieldOffset: CGFloat { -width*(1-progress) }
    var sliderOffset: CGFloat { width*progress }
}

private struct PasscodeRevealKey: EnvironmentKey { static let defaultValue: CGFloat = 1 }
private struct PasscodeDepartureKey: EnvironmentKey { static let defaultValue: CGFloat = 0 }
private extension EnvironmentValues {
    var oldOSPasscodeReveal: CGFloat { get { self[PasscodeRevealKey.self] } set { self[PasscodeRevealKey.self] = newValue } }
    var oldOSPasscodeDeparture: CGFloat { get { self[PasscodeDepartureKey.self] } set { self[PasscodeDepartureKey.self] = newValue } }
}
struct OldOSPasscodeReveal: AnimatableModifier {
    var progress: CGFloat
    var departure: CGFloat = 0
    var animatableData: AnimatablePair<CGFloat,CGFloat> {
        get { AnimatablePair(progress,departure) }
        set { progress = newValue.first; departure = newValue.second }
    }
    func body(content: Content) -> some View { content.environment(\.oldOSPasscodeReveal,progress).environment(\.oldOSPasscodeDeparture,departure) }
}

private struct PasscodeEntryPanel: View {
    @Environment(\.oldOSPasscodeReveal) private var reveal
    @Environment(\.oldOSPasscodeDeparture) private var departure
    @Binding var text: String
    let simple: Bool
    let unlocking: Bool
    let prompt: String
    let failure: String?
    let busy: Bool
    let cancel: () -> Void
    let submit: () -> Void
    let emergency: () -> Void
    var phaseID = 0
    var active = true
    private var keyboardConfiguration: OldOSKeyboardConfiguration {
        OldOSKeyboardConfiguration(keyboardType:.asciiCapable,returnType:unlocking ? .emergencyCall : .default,autocapitalization:false,
                                   autocorrection:false,playsKeyClicks:true,doubleSpacePeriod:false,dismissesOnReturn:false,appearance:unlocking ? .lockScreen : .standard)
    }
    private var numericConfiguration: OldOSKeyboardConfiguration {
        OldOSKeyboardConfiguration(keyboardType:.numberPad,returnType:.default,autocapitalization:false,
                                   autocorrection:false,playsKeyClicks:true,doubleSpacePeriod:false,dismissesOnReturn:false,numberPadShowsDelete:true)
    }
    private var numericText: Binding<String> {
        Binding(get:{text},set:{ value in
            guard !busy else { return }
            let digits = String(value.filter { $0.isASCII && $0.isNumber }.prefix(4))
            guard digits != text else { return }
            text = digits
            if digits.count == 4 { submit() }
        })
    }
    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width/320,geometry.size.height/(simple ? 352 : 240))
            let width = geometry.size.width/scale
            let height = geometry.size.height/scale
            let motion = OldOSLockTransitionGeometry(width:geometry.size.width,height:geometry.size.height,progress:reveal,departure:departure)
            let fieldY = unlocking ? (motion.footerTop+55)/scale : 96
            ZStack(alignment:.topLeading) {
                if unlocking {
                    if failure != nil {
                        Image("passcode-DeviceLockTitleViewRedBackground")
                            .resizable().frame(width:width,height:110/scale).opacity(reveal).offset(y:-110*departure/scale)
                    }
                    Image(failure == nil ? "passcode-DeviceLockEntryFieldBackground" : "passcode-DeviceLockFailedEntryBackground")
                        .resizable().frame(width:width,height:110/scale).opacity(reveal).offset(y:motion.footerTop/scale)
                }
                ZStack(alignment:.topLeading) {
                    Text(prompt).font(.custom(unlocking ? "Helvetica Neue" : "Helvetica Neue Bold",fixedSize:unlocking ? 36 : 16))
                        .lineLimit(1).minimumScaleFactor(0.6).foregroundColor(unlocking ? .white : Color(red:76/255,green:86/255,blue:108/255))
                        .shadow(color:unlocking ? .black : .white.opacity(0.7),radius:0,y:unlocking ? -1 : 1)
                        .frame(width:width-20,height:50).position(x:width/2,y:unlocking ? 55/scale-110*departure/scale : 44)
                        .opacity(unlocking ? reveal : 1)
                    Group {
                        if simple {
                            PasscodeDigitFields(count:text.count,settings:!unlocking)
                        } else if unlocking {
                            HStack(spacing:4) {
                                if active { secureField(fontSize:31,height:40).frame(maxWidth:.infinity) }
                                Button(action:text.isEmpty ? cancel : submit) {
                                    Text(text.isEmpty ? "Cancel" : "OK").font(.custom("Helvetica-Bold",fixedSize:14))
                                        .foregroundColor(.white).shadow(color:.black,radius:0,y:-1).frame(width:60,height:32)
                                }.buttonStyle(PasscodeConfirmStyle()).disabled(busy)
                            }.padding(.horizontal,10).frame(width:282,height:52)
                                .background {
                                    Image("passcode-UIPasscodeFieldBackground_Opaque")
                                        .resizable(capInsets:EdgeInsets(top:10,leading:5,bottom:10,trailing:5))
                                        .frame(height:53).frame(height:51,alignment:.top).clipped().frame(height:52,alignment:.top)
                                }
                                .background(Color(white:0.25))
                        } else {
                            secureField(fontSize:22,height:40)
                                .padding(.horizontal,10).frame(width:300,height:44)
                                .background(Color.white).clipShape(RoundedRectangle(cornerRadius:10))
                                .overlay(RoundedRectangle(cornerRadius:10).stroke(Color(white:0.64),lineWidth:1))
                        }
                    }.position(x:width/2+(unlocking ? motion.fieldOffset/scale : 0),y:fieldY)
                    if let failure {
                        Text(failure).font(.custom("Helvetica Neue Bold",fixedSize:13)).foregroundColor(.white)
                            .padding(.horizontal,12).frame(height:26)
                            .background(Image("passcode-PasscodeFailure").resizable(capInsets:EdgeInsets(top:5,leading:10,bottom:5,trailing:10)))
                            .position(x:width/2,y:unlocking ? max(130/scale,motion.footerTop/scale-20) : 150).opacity(unlocking ? reveal*(1-departure) : 1)
                    }
                }.frame(width:width,height:height,alignment:.topLeading).id(phaseID)
                    .transition(.asymmetric(insertion:.move(edge:.trailing),removal:.move(edge:.leading)))
                if simple && unlocking {
                    PasscodeNumericKeypad(hasText:!text.isEmpty,unlocking:true,action:{ key in
                        guard active, !busy else { return }
                        if key == "delete" { if !text.isEmpty { text.removeLast() } }
                        else if text.count < 4 { text += key; if text.count == 4 { submit() } }
                    },cancel:cancel,emergency:emergency)
                    .compositingGroup()
                    .position(x:width/2,y:(motion.keypadTop+motion.keyboardHeight/2)/scale)
                }
                if simple && !unlocking {
                    OldOSTextField("",text:numericText,configuration:numericConfiguration,font:.systemFont(ofSize:16),textColor:.clear,tintColor:.clear,height:52,
                                   focusOnAppear:true,secureEntry:true,onSubmit:nil)
                        .frame(width:282,height:52).position(x:width/2,y:96).accessibilityHidden(true)
                }
            }.frame(width:width,height:height,alignment:.topLeading).scaleEffect(scale,anchor:.topLeading)
        }.clipped()
    }
    private func secureField(fontSize:CGFloat,height:CGFloat) -> some View {
        OldOSTextField("",text:$text,configuration:keyboardConfiguration,font:UIFont(name:"Helvetica",size:fontSize) ?? .systemFont(ofSize:fontSize),height:height,focusOnAppear:true,secureEntry:true,onSubmit:unlocking ? emergency : submit)
    }
}

struct OldOSUnlockPasscodeView: View {
    @Environment(\.oldOSPasscodeReveal) private var reveal
    @Environment(\.oldOSPasscodeDeparture) private var departure
    @ObservedObject private var store = OldOSPasscodeStore.shared
    @StateObject private var keyboard = OldOSKeyboardController()
    @State private var text = ""
    @State private var busy = false
    @State private var wrong = false
    @State private var failedAttempts = 0
    @State private var message: String?
    var active = true
    let unlocked: () -> Void
    @State private var requestID = UUID()
    var body: some View {
        VStack(spacing:0) {
            Color.clear.frame(height:24).allowsHitTesting(false)
            TimelineView(.periodic(from:.now,by:1)) { context in
                let blocked = (store.blockedUntil ?? .distantPast) > context.date
                PasscodeEntryPanel(text:$text,simple:store.simple,unlocking:true,
                                   prompt:blocked ? "iPhone is disabled" : wrong ? "Wrong Passcode" : "Enter Passcode",
                                   failure:blocked ? retryMessage(at:context.date) : wrong ? attemptMessage : nil,
                                   busy:busy,cancel:cancel,submit:submit,
                                   emergency:{ message = "Use your iPhone’s system lock screen to make an emergency call." },active:active)
                    .disabled(blocked)
                    .overlay(alignment:.bottomTrailing) {
                        if blocked { Button("Cancel",action:cancel).foregroundColor(.white).padding(20) }
                    }
            }
        }
        .oldOSKeyboardHost(keyboard,presentationProgress:store.simple ? nil : reveal,departure:departure)
        .ignoresSafeArea(.keyboard)
        .overlay { if let message { ZStack { Color.black.opacity(0.4).ignoresSafeArea(); skeumorphic_alert(title:"Passcode",subtitle:message,dismiss_action:{self.message=nil}) } } }
        .onAppear { keyboard.configuration.appearance = .lockScreen }
        .onChange(of:active) { active in if !active { resetEntry() } }
        .onDisappear { resetEntry() }
    }
    private func resetEntry() { requestID = UUID(); text = ""; wrong = false; failedAttempts = 0; busy = false; keyboard.hide(); RetroClockAudio.stopPickerTicks() }
    private func cancel() { requestID = UUID(); keyboard.hide(); store.cancelUnlock() }
    private var attemptMessage: String { "\(failedAttempts) Failed Passcode Attempt\(failedAttempts == 1 ? "" : "s")" }
    private func retryMessage(at date: Date) -> String {
        let minutes = max(1,Int(ceil((store.blockedUntil ?? date).timeIntervalSince(date)/60)))
        return "try again in \(minutes) minute\(minutes == 1 ? "" : "s")"
    }
    private func submit() {
        guard active, store.presentingUnlock, !store.inactive, !busy, !text.isEmpty else { return }
        let request = requestID
        busy = true
        store.verify(text) { result in
            guard requestID == request, active, store.presentingUnlock, !store.inactive else { return }
            busy = false; text = ""
            switch result {
            case .accepted:
                wrong = false; busy = true; keyboard.hide()
                RetroClockAudio.stopPickerTicks { OldOSPasscodeUnlockSound.play() }
                unlocked()
            case .rejected: failedAttempts = store.failures; wrong = true
            case .blocked: failedAttempts = store.failures; keyboard.hide(); wrong = true
            case .unavailable(let error): message = error
            case .cancelled: break
            }
        }
    }
}

final class OldOSPasscodeSettingsSession: ObservableObject {
    enum Operation { case authenticate, enable, change, disable, changeSimple(Bool) }
    struct Request: Identifiable {
        let id = UUID()
        let operation: Operation
    }
    @Published private(set) var request: Request?
    @Published var authorized = false
    @Published private(set) var toggleRevision = 0
    private(set) var generation = 0
    func enter() {
        guard !authorized, request == nil, !OldOSPasscodeStore.shared.inactive else { return }
        guard OldOSPasscodeStore.shared.enabled else { authorized = true; return }
        present(.authenticate)
    }
    func present(_ operation: Operation) {
        guard request == nil else { return }
        withAnimation(.easeInOut(duration:0.3)) { request = Request(operation:operation) }
    }
    func dismiss() { withAnimation(.easeInOut(duration:0.3)) { toggleRevision += 1; request = nil } }
    func reset() {
        generation += 1; authorized = false
        var transaction = Transaction(); transaction.disablesAnimations = true
        withTransaction(transaction) { toggleRevision += 1; request = nil }
    }
}

struct OldOSPasscodeSettingsView: View {
    @ObservedObject private var store = OldOSPasscodeStore.shared
    @ObservedObject var session: OldOSPasscodeSettingsSession
    let requirePasscode: () -> Void
    var body: some View {
        ZStack {
            settings_main_list()
            if session.authorized || !store.enabled {
            ScrollView {
                VStack(spacing:25) {
                    PasscodeSettingsGroup {
                        Button { session.present(store.enabled ? .disable : .enable) } label: {
                            Text(store.enabled ? "Turn Passcode Off" : "Turn Passcode On")
                                .font(.custom("Helvetica Neue Bold",fixedSize:18)).frame(maxWidth:.infinity,minHeight:50)
                        }.buttonStyle(PasscodePlainButton()).foregroundColor(.black)
                    }
                    PasscodeSettingsGroup {
                        Button { session.present(.change) } label: {
                            Text("Change Passcode").font(.custom("Helvetica Neue Bold",fixedSize:18)).frame(maxWidth:.infinity,minHeight:50)
                        }.buttonStyle(PasscodePlainButton()).foregroundColor(store.enabled ? .black : .gray).disabled(!store.enabled)
                    }
                    PasscodeSettingsGroup {
                        Button(action:requirePasscode) {
                            HStack {
                                Text("Require Passcode").font(.custom("Helvetica Neue Bold",fixedSize:18)); Spacer()
                                Text(OldOSPasscodeStore.graceTitle(store.grace,short:true)).font(.custom("Helvetica Neue",fixedSize:16))
                                    .foregroundColor(Color(red:0.22,green:0.31,blue:0.47))
                                Image("UITableNext")
                            }.padding(.horizontal,12).frame(height:50)
                        }.buttonStyle(PasscodePlainButton()).foregroundColor(.black).disabled(!store.enabled).opacity(store.enabled ? 1 : 0.5)
                    }
                    VStack(spacing:8) {
                        PasscodeSettingsGroup {
                            HStack {
                                Text("Simple Passcode").font(.custom("Helvetica Neue Bold",fixedSize:18)); Spacer()
                                toggle(on:store.simple,onChanged:{ value in
                                    if store.enabled { session.present(.changeSimple(value)) }
                                    else { store.setPreferredSimple(value) }
                                }).id("\(store.simple)-\(session.toggleRevision)")
                            }.padding(.horizontal,12).frame(height:50)
                        }
                        Text("A simple passcode is a 4 digit number.").font(.custom("Helvetica Neue",fixedSize:15))
                            .foregroundColor(Color(red:76/255,green:86/255,blue:108/255)).shadow(color:.white,radius:0,y:1).multilineTextAlignment(.center)
                    }
                }.padding(.horizontal,12).padding(.vertical,15)
            }
            }
        }
        .allowsHitTesting(session.authorized && session.request == nil)
        .onAppear { session.enter() }
        .onChange(of:store.inactive) { inactive in if !inactive { session.enter() } }
    }
}

struct OldOSPasscodeGraceView: View {
    @ObservedObject private var store = OldOSPasscodeStore.shared
    @State private var message: String?
    let back: () -> Void
    var body: some View {
        ZStack {
            settings_main_list()
            ScrollView {
                VStack(spacing:8) {
                    PasscodeSettingsGroup {
                        VStack(spacing:0) {
                            ForEach(OldOSPasscodeStore.graceChoices,id:\.self) { choice in
                                Button {
                                    message = store.setGrace(choice)
                                    if message == nil { back() }
                                } label: {
                                    HStack {
                                        Text(OldOSPasscodeStore.graceTitle(choice)).font(.custom("Helvetica Neue Bold",fixedSize:18)); Spacer()
                                        if store.grace == choice { Image("UIPreferencesBlueCheck") }
                                    }.padding(.horizontal,12).frame(height:50)
                                }.buttonStyle(PasscodePlainButton()).foregroundColor(.black)
                                if choice != OldOSPasscodeStore.graceChoices.last { Divider() }
                            }
                        }
                    }
                    Text("Shorter times are more secure").font(.custom("Helvetica Neue",fixedSize:15))
                        .foregroundColor(Color(red:76/255,green:86/255,blue:108/255)).shadow(color:.white,radius:0,y:1)
                }.padding(.horizontal,12).padding(.vertical,15)
            }
        }.overlay { if let message { ZStack { Color.black.opacity(0.4); skeumorphic_alert(title:"Passcode Lock",subtitle:message,dismiss_action:{self.message=nil}) } } }
    }
}

private struct PasscodeSettingsGroup<Content:View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content.background(Color.white).clipShape(RoundedRectangle(cornerRadius:10))
            .overlay(RoundedRectangle(cornerRadius:10).stroke(Color(red:171/255,green:171/255,blue:171/255),lineWidth:1.25))
    }
}

struct OldOSPasscodeSettingsSheet: View {
    private enum Step: Int { case oldCode, newCode, confirm }
    @ObservedObject private var store = OldOSPasscodeStore.shared
    @ObservedObject var session: OldOSPasscodeSettingsSession
    @StateObject private var keyboard = OldOSKeyboardController()
    let request: OldOSPasscodeSettingsSession.Request
    let gateAccepted: () -> Void
    let gateCancelled: () -> Void
    @State private var step: Step
    @State private var targetSimple: Bool
    @State private var text = ""
    @State private var first = ""
    @State private var busy = false
    @State private var phase = 0
    @State private var advancing = false
    @State private var failure: String?
    @State private var message: String?
    init(session:OldOSPasscodeSettingsSession,request:OldOSPasscodeSettingsSession.Request,gateAccepted:@escaping () -> Void = {},gateCancelled:@escaping () -> Void) {
        self.session = session; self.request = request; self.gateAccepted = gateAccepted; self.gateCancelled = gateCancelled
        if case .enable = request.operation { _step = State(initialValue:.newCode) }
        else { _step = State(initialValue:.oldCode) }
        if case .changeSimple(let value) = request.operation { _targetSimple = State(initialValue:value) }
        else { _targetSimple = State(initialValue:OldOSPasscodeStore.shared.simple) }
    }
    private var simple: Bool { step == .oldCode ? store.simple : targetSimple }
    private var title: String {
        switch request.operation {
        case .authenticate: return "Enter Passcode"
        case .disable: return "Turn off Passcode"
        case .enable: return "Set Passcode"
        case .change,.changeSimple: return "Change Passcode"
        }
    }
    private var prompt: String {
        if step == .confirm { return "Re-enter your passcode" }
        if step == .newCode { return store.enabled ? "Enter your new passcode" : "Enter a passcode" }
        return "Enter your passcode"
    }
    private var nextTitle: String {
        if step == .confirm { return "Done" }
        if case .disable = request.operation { return "Done" }
        return "Next"
    }
    var body: some View {
        VStack(spacing:0) {
            OldOSPasscodeNavigationHeader(title:title,cancel:cancel,nextTitle:simple ? nil : nextTitle,next:submit,nextEnabled:!text.isEmpty && !busy && !advancing)
            ZStack {
                settings_main_list()
                TimelineView(.periodic(from:.now,by:1)) { context in
                    let blocked = (store.blockedUntil ?? .distantPast) > context.date && step == .oldCode
                    PasscodeEntryPanel(text:$text,simple:simple,unlocking:false,prompt:prompt,
                                       failure:blocked ? retryMessage(at:context.date) : failure,busy:busy || advancing,
                                       cancel:cancel,submit:submit,emergency:{},phaseID:phase)
                        .disabled(blocked)
                }
            }
        }
        .clipped().oldOSKeyboardHost(keyboard).ignoresSafeArea(.keyboard)
        .overlay { if let message { ZStack { Color.black.opacity(0.4); skeumorphic_alert(title:"Passcode Lock",subtitle:message,dismiss_action:{self.message=nil}) } } }
        .onDisappear { text = ""; first = ""; keyboard.hide(); RetroClockAudio.stopPickerTicks() }
    }
    private func retryMessage(at date:Date) -> String {
        let minutes = max(1,Int(ceil((store.blockedUntil ?? date).timeIntervalSince(date)/60)))
        return "Try again in \(minutes) minute\(minutes == 1 ? "" : "s")."
    }
    private func changeStep(_ next:Step) {
        advancing = true
        withAnimation(.easeInOut(duration:0.25)) { text = ""; failure = nil; step = next; phase += 1 }
        let phase = self.phase
        DispatchQueue.main.asyncAfter(deadline:.now()+0.25) {
            if self.phase == phase { advancing = false }
        }
    }
    private func cancel() {
        guard !busy else { return }
        text = ""; first = ""; session.dismiss()
        if case .authenticate = request.operation {
            let generation = session.generation
            DispatchQueue.main.asyncAfter(deadline:.now()+0.3) {
                if session.generation == generation { gateCancelled() }
            }
        }
    }
    private func finish() { first = ""; session.authorized = true; session.dismiss() }
    private func submit() {
        guard !busy, !advancing, !text.isEmpty else { return }
        if step == .newCode {
            guard OldOSPasscodeHash.valid(text,simple:targetSimple) else { failure = "Enter a valid passcode."; return }
            first = text; changeStep(.confirm); return
        }
        if step == .confirm {
            guard text == first else { first = ""; changeStep(.newCode); failure = "Passcodes did not match. Try again."; return }
            busy = true
            store.setPasscode(text,simple:targetSimple) { error in
                guard session.request?.id == request.id else { return }
                busy = false
                if let error { message = error; changeStep(.newCode) } else { finish() }
            }
            return
        }
        busy = true
        store.verify(text) { result in
            guard session.request?.id == request.id else { return }
            busy = false; text = ""
            switch result {
            case .accepted:
                switch request.operation {
                case .authenticate:
                    session.authorized = true; gateAccepted(); finish()
                case .disable:
                    if let error = store.turnOff() { message = error } else { finish() }
                case .change,.changeSimple,.enable: changeStep(.newCode)
                }
            case .rejected: failure = "\(store.failures) Failed Passcode Attempt\(store.failures == 1 ? "" : "s")"
            case .blocked: keyboard.hide(); failure = "Try again later."
            case .unavailable(let error): message = error
            case .cancelled: break
            }
        }
    }
}

#endif
