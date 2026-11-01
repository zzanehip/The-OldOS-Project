import Foundation

// Kept independent of the view so calculations survive layout and orientation changes.
struct RetroCalculatorState: Codable {
    enum Operation: String, Codable {
        case add, subtract, multiply, divide, power, root
        var precedence: Int {
            switch self { case .add, .subtract: return 1; case .multiply, .divide: return 2; case .power, .root: return 3 }
        }
        func evaluate(_ lhs: Double, _ rhs: Double) -> Double {
            switch self {
            case .add: return lhs + rhs
            case .subtract: return lhs - rhs
            case .multiply: return lhs * rhs
            case .divide: return lhs / rhs
            case .power: return pow(lhs, rhs)
            case .root:
                if lhs < 0, rhs.rounded() == rhs, abs(rhs.truncatingRemainder(dividingBy: 2)) == 1 { return -pow(-lhs, 1 / rhs) }
                return pow(lhs, 1 / rhs)
            }
        }
    }
    var entry = "0" { didSet { resultValue = nil } }
    private var resultValue: Double?
    var memory: Double = 0
    var memoryStored = false
    var second = false
    var radians = false
    var scientific = false
    private(set) var allClear = true
    private var values: [Double] = []
    private var operators: [String] = []
    private var replaceEntry = true
    private var waitingForOperand = false
    private var currentOnStack = false
    private var completed = false
    private var repeatOperation: Operation?
    private var repeatOperand: Double = 0
    var value: Double {
        if let resultValue { return resultValue }
        if entry.hasSuffix("e+") || entry.hasSuffix("e-") { return Double(entry.dropLast(2)) ?? .nan }
        return Double(entry) ?? .nan
    }
    var selectedOperation: String? { waitingForOperand ? operators.last : nil }
    var digitLimit: Int { scientific ? 16 : 9 }
    var display: String {
        guard value.isFinite else { return "Error" }
        let separator = Locale.current.decimalSeparator ?? "."
        let visible = resultValue.map { formatted($0) } ?? entry
        guard !visible.contains("e") else { return visible.replacingOccurrences(of: ".", with: separator) }
        let parts = visible.split(separator: ".", omittingEmptySubsequences: false)
        let negative = visible.hasPrefix("-")
        let integer = String(parts[0]).replacingOccurrences(of: "-", with: "")
        let grouping = Locale.current.groupingSeparator ?? ","
        let digits = Array(integer)
        let grouped = digits.enumerated().map { index, character in
            (index > 0 && (digits.count - index) % 3 == 0 ? grouping : "") + String(character)
        }.joined()
        return (negative ? "-" : "") + grouped + (parts.count > 1 ? separator + parts[1] : "")
    }
    private func formatted(_ value: Double) -> String {
        guard value.isFinite else { return "Error" }
        if value == 0 { return "0" }
        return String(format: "%.*g", locale: Locale(identifier: "en_US_POSIX"), digitLimit, value)
            .replacingOccurrences(of: "e+0", with: "e+").replacingOccurrences(of: "e-0", with: "e-")
    }
    private mutating func resetExpression() {
        values = []; operators = []; currentOnStack = false; waitingForOperand = false
        completed = false; repeatOperation = nil; replaceEntry = true
    }
    private mutating func beginEntry() {
        if completed || !value.isFinite { resetExpression() }
        if currentOnStack { binary(.multiply) }
        if replaceEntry { entry = "0"; replaceEntry = false }
        waitingForOperand = false; allClear = false
    }
    mutating func digit(_ digit: String) {
        beginEntry()
        if entry.contains("e") {
            let exponent = entry.split(separator: "e", omittingEmptySubsequences: false).last ?? ""
            if exponent.filter(\.isNumber).count < 3 { entry += digit }
        } else if entry.filter(\.isNumber).count < digitLimit || entry == "0" {
            entry = entry == "0" ? digit : (entry == "-0" ? "-" + digit : entry + digit)
        }
    }
    mutating func decimal() {
        beginEntry()
        if !entry.contains("."), !entry.contains("e") { entry += "." }
    }
    mutating func deleteDigit() {
        guard !replaceEntry, !waitingForOperand, !entry.contains("e"), value.isFinite else { return }
        entry.removeLast()
        if entry.isEmpty || entry == "-" { entry = "0" }
    }
    mutating func paste(_ string: String) {
        let separator = Locale.current.decimalSeparator ?? "."
        let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: Locale.current.groupingSeparator ?? ",", with: "")
            .replacingOccurrences(of: separator, with: ".").replacingOccurrences(of: "−", with: "-")
        guard let number = Double(normalized), number.isFinite else { return }
        if completed { resetExpression() }
        entry = formatted(number); resultValue = number.isFinite ? number : nil
        replaceEntry = true; waitingForOperand = false; allClear = false
        if currentOnStack { values[values.count - 1] = number }
    }
    mutating func clear() {
        if allClear { resetExpression() }
        entry = "0"; replaceEntry = true; waitingForOperand = false; completed = false
        if currentOnStack, !values.isEmpty { values.removeLast() }
        currentOnStack = false; allClear = true
    }
    private mutating func pushCurrent() {
        if !currentOnStack { values.append(value) }
        currentOnStack = false
    }
    private mutating func reduce() {
        guard let name = operators.last, let op = Operation(rawValue: name), values.count >= 2 else { return }
        operators.removeLast()
        let rhs = values.removeLast(), lhs = values.removeLast()
        values.append(op.evaluate(lhs, rhs))
    }
    mutating func binary(_ op: Operation) {
        guard value.isFinite else { return }
        if waitingForOperand, let last = operators.last, last != "(" {
            operators.removeLast()
        } else {
            if completed { resetExpression() }
            pushCurrent()
        }
        while let last = operators.last, let previous = Operation(rawValue: last), previous.precedence >= op.precedence {
            reduce()
        }
        let number = values.last ?? 0
        entry = formatted(number); resultValue = number.isFinite ? number : nil
        if !value.isFinite { resetExpression(); replaceEntry = true; allClear = false; return }
        operators.append(op.rawValue); waitingForOperand = true; replaceEntry = true; allClear = false
    }
    mutating func equals() {
        guard value.isFinite else { return }
        if completed, let op = repeatOperation { setValue(op.evaluate(value, repeatOperand)); return }
        pushCurrent()
        if let last = operators.last, let op = Operation(rawValue: last) {
            repeatOperation = op; repeatOperand = values.last ?? value
        }
        while !operators.isEmpty {
            if operators.last == "(" { operators.removeLast() } else { reduce() }
        }
        let number = values.last ?? value
        entry = formatted(number); resultValue = number.isFinite ? number : nil; values = []
        completed = true; replaceEntry = true; waitingForOperand = false; allClear = false
    }
    mutating func openParenthesis() {
        if completed { resetExpression() }
        if !replaceEntry || currentOnStack { binary(.multiply) }
        operators.append("("); entry = "0"; replaceEntry = true; waitingForOperand = true; allClear = false
    }
    mutating func closeParenthesis() {
        guard operators.contains("("), !waitingForOperand else { return }
        pushCurrent()
        while operators.last != "(", !operators.isEmpty { reduce() }
        if operators.last == "(" { operators.removeLast() }
        let number = values.last ?? 0
        entry = formatted(number); resultValue = number.isFinite ? number : nil
        if !value.isFinite { resetExpression(); replaceEntry = true; allClear = false; return }
        currentOnStack = true; replaceEntry = true; waitingForOperand = false
    }
    private mutating func setValue(_ number: Double) {
        if !number.isFinite { resetExpression() }
        entry = formatted(number); resultValue = number.isFinite ? number : nil
        replaceEntry = true; waitingForOperand = false; allClear = false
        if currentOnStack, !values.isEmpty { values[values.count - 1] = number }
    }
    mutating func press(_ key: String) {
        if key.count == 1, key.first?.isNumber == true { digit(key); return }
        if let op = Operation(rawValue: key) { binary(op); return }
        switch key {
        case "decimal": decimal()
        case "c": clear()
        case "=": equals()
        case "(": openParenthesis()
        case ")": closeParenthesis()
        case "2nd": second.toggle()
        case "rad": radians.toggle()
        case "mc": memory = 0; memoryStored = false
        case "m+": if value.isFinite { memory += value; memoryStored = true; if !memory.isFinite { memory = 0 } }; replaceEntry = true
        case "m-": if value.isFinite { memory -= value; memoryStored = true; if !memory.isFinite { memory = 0 } }; replaceEntry = true
        case "mr": if completed { resetExpression() }; setValue(memory)
        case "+-":
            if let e = entry.firstIndex(of: "e"), !replaceEntry {
                let after = entry.index(after: e)
                if entry[after...].hasPrefix("-") { entry.remove(at: after) }
                else if entry[after...].hasPrefix("+") { entry.replaceSubrange(after...after, with: "-") }
                else { entry.insert("-", at: after) }
            } else if value.isFinite {
                let precise = resultValue.map { -$0 }
                entry = entry.hasPrefix("-") ? String(entry.dropFirst()) : "-" + entry
                resultValue = precise
                waitingForOperand = false; allClear = false
                if currentOnStack { values[values.count - 1] = value }
            }
        case "EE":
            if value.isFinite, !entry.contains("e") { entry += "e+"; replaceEntry = false; waitingForOperand = false; allClear = false }
        case "pi": if completed { resetExpression() }; setValue(.pi)
        case "Random": if completed { resetExpression() }; setValue(Double.random(in: 0..<1))
        default: unary(key)
        }
    }
    private mutating func unary(_ key: String) {
        guard value.isFinite else { return }
        let x = value, angle = radians ? x : x * .pi / 180
        let result: Double
        switch key {
        case "percent":
            if let op = operators.last, ["add", "subtract"].contains(op), let lhs = values.last { result = lhs * x / 100 }
            else { result = x / 100 }
        case "x(-1)": result = 1 / x
        case "x2": result = x * x
        case "x3": result = x * x * x
        case "sqrt": result = sqrt(x)
        case "factorial":
            if x >= 0, x.rounded() == x, x <= 170 { result = x < 2 ? 1 : (2...Int(x)).reduce(1.0) { $0 * Double($1) } }
            else { result = .nan }
        case "log": result = second ? log2(x) : log10(x)
        case "ln": result = log(x)
        case "ex": result = second ? pow(2, x) : exp(x)
        case "sin": result = second ? asin(x) * (radians ? 1 : 180 / .pi) : sin(angle)
        case "cos": result = second ? acos(x) * (radians ? 1 : 180 / .pi) : cos(angle)
        case "tan": result = second ? atan(x) * (radians ? 1 : 180 / .pi) : tan(angle)
        case "sinh": result = second ? asinh(x) : sinh(x)
        case "cosh": result = second ? acosh(x) : cosh(x)
        case "tanh": result = second ? atanh(x) : tanh(x)
        default: return
        }
        setValue(result)
    }
}

#if canImport(UIKit)
import SwiftUI
import UIKit
import Combine
import CoreText
import AudioToolbox

private final class RetroCalculatorStore: ObservableObject {
    static let shared = RetroCalculatorStore()
    @Published var state: RetroCalculatorState {
        didSet { if let data = try? JSONEncoder().encode(state) { UserDefaults.standard.set(data, forKey: "OldOS.Calculator.state.v1") } }
    }
    init() {
        state = UserDefaults.standard.data(forKey: "OldOS.Calculator.state.v1")
            .flatMap { try? JSONDecoder().decode(RetroCalculatorState.self, from: $0) } ?? RetroCalculatorState()
    }
}

struct Calculator: View {
    @ObservedObject private var store = RetroCalculatorStore.shared
    @State private var orientation = UIDevice.current.orientation
    private var landscape: Bool { orientation.isLandscape }
    var body: some View {
        GeometryReader { geometry in
            let size = landscape ? CGSize(width: geometry.size.height, height: geometry.size.width) : geometry.size
            VStack(spacing: 0) {
                status_bar().frame(height: 24).zIndex(1)
                RetroCalculatorFace(state: $store.state, scientific: landscape)
            }
            .frame(width: size.width, height: size.height)
            .rotationEffect(.degrees(landscape ? (orientation == .landscapeLeft ? 90 : -90) : 0))
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .clipped()
        .onAppear {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            store.state.scientific = landscape
        }
        .onDisappear { UIDevice.current.endGeneratingDeviceOrientationNotifications() }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            let next = UIDevice.current.orientation
            guard next.isPortrait || next.isLandscape else { return }
            withAnimation(.easeInOut(duration: 0.3)) { orientation = next; store.state.scientific = next.isLandscape }
        }
    }
}

private struct RetroCalculatorKey: Identifiable {
    let id: String
    let frame: CGRect
    let artworkFrame: CGRect
    let sheet: String
    let scientific: Bool
    var label: String {
        ["c":"Clear", "mc":"Memory clear", "mr":"Memory recall", "m+":"Memory add", "m-":"Memory subtract", "+-":"Change sign", "=":"Equals", "decimal":"Decimal point", "x(-1)":"Reciprocal", "x2":"Square", "x3":"Cube", "power":"Power", "root":"Root", "factorial":"Factorial", "sqrt":"Square root", "rad":"Radians or degrees", "EE":"Exponent", "Random":"Random number", "2nd":"Second functions" ][id] ?? id
    }
    func imageName(state: RetroCalculatorState, pressed: Bool, decimalSeparator: String = Locale.current.decimalSeparator ?? ".") -> String? {
        var name = id
        if name == "power" { name = "yx" }; if name == "root" { name = "x(-y)" }
        if id == "c" { name = state.allClear ? "ac" : "c" }
        if id == "decimal", decimalSeparator == "," { name = "comma" }
        if scientific {
            if id == "2nd", state.second { name = "2ndOn" }
            if id == "rad", state.radians { name = "deg" }
            if state.second { name = ["sin":"asin", "cos":"acos", "tan":"atan", "sinh":"asinh", "cosh":"acosh", "tanh":"atanh", "log":"log2", "ex":"2x"][id] ?? name }
        }
        if !scientific { name += "Basic" }
        if pressed { return "calc-" + name + "Pressed" }
        return name != id && !["yx", "x(-y)"].contains(name) && name != id + "Basic" ? "calc-" + name : nil
    }
    // The original controller uses cell origins (4,2), pitch (78,61) in portrait;
    // (1,3), pitch (60,40) for both landscape halves. Zero and equals span cells.
    static func keys(scientific: Bool, width: CGFloat = 480) -> [Self] {
        let basic = [["mc","m+","m-","mr"],["c","+-","divide","multiply"],["7","8","9","subtract"],["4","5","6","add"],["1","2","3","="],["0","0","decimal","="]]
        let advanced = [["2nd","(",")","percent"],["x(-1)","x2","x3","power"],["factorial","sqrt","root","log"],["sin","cos","tan","ln"],["sinh","cosh","tanh","ex"],["rad","pi","EE","Random"]]
        var result: [Self] = []
        for (half, rows) in (scientific ? [advanced, basic] : [basic]).enumerated() {
            for row in 0..<6 { for col in 0..<4 {
                let id = rows[row][col]
                if (id == "0" && col == 1) || (id == "=" && row == 5) { continue }
                let w: CGFloat = scientific ? 60 : 78, h: CGFloat = scientific ? 40 : 61
                let columns: CGFloat = id == "0" ? 2 : 1
                let rows: CGFloat = id == "=" ? 2 : 1
                let source = CGRect(x: (scientific ? 1 : 4) + CGFloat(col) * w,
                                    y: (scientific ? 3 : 2) + CGFloat(row) * h,
                                    width: w * columns, height: h * rows)
                let pitch = scientific ? (width - 60) / 7 : w
                let centerX = scientific ? 31 + (CGFloat(half * 4 + col) + (columns - 1) / 2) * pitch : source.midX
                let target = CGRect(x: centerX - pitch * columns / 2, y: source.minY,
                                    width: pitch * columns, height: source.height)
                result.append(Self(id: id, frame: target, artworkFrame: source,
                                   sheet: scientific ? (half == 0 ? "calc-scientificKeypad" : "calc-landscapeKeypad") : "calc-basicKeypad",
                                   scientific: scientific))
            } }
        }
        return result
    }
}

private struct RetroCalculatorFace: View {
    @Binding var state: RetroCalculatorState
    let scientific: Bool
    @State private var pressed: String?
    @State private var menu = false
    var body: some View {
        GeometryReader { geometry in
            let scale = scientific ? min(geometry.size.width / 480, geometry.size.height / 300) : geometry.size.width / 320
            // Extra landscape width becomes space between columns, not a second
            // artwork scale. The display and its text use this same uniform scale.
            let width: CGFloat = scientific ? geometry.size.width / scale : 320
            let keypadHeight: CGFloat = scientific ? 241 : 371
            let height = max(keypadHeight + 40, geometry.size.height / scale)
            let displayHeight = height - keypadHeight
            ZStack(alignment: .topLeading) {
                Image("calc-displayBackgroundSlice").resizable().frame(width: width, height: displayHeight)
                display(width: width, height: displayHeight)
                keypad(width: width, height: keypadHeight).offset(y: displayHeight)
            }
            .frame(width: width, height: height, alignment: .topLeading)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            .background(Image("calc-landscapeBackground").resizable(resizingMode: .tile))
        }.clipped()
    }
    private func display(width: CGFloat, height: CGFloat) -> some View {
        let valueHeight = min(height, scientific ? 59 : 89)
        return ZStack(alignment: .bottomTrailing) {
            if menu { Image("calc-displayBackgroundSliceSelected").resizable().frame(width: width, height: height) }
            Text(state.display)
                .font(Font(OldOSKeyboardFont.ctPhonepadTwo(valueHeight * 0.9 * 76 / 80) ?? CTFontCreateWithName("Helvetica" as CFString, valueHeight * 0.85, nil)))
                .foregroundColor(.black).shadow(color: .white.opacity(0.6), radius: 0, x: 0, y: 1)
                .lineLimit(1).minimumScaleFactor(0.35)
                .frame(width: width - (scientific ? 64 : 20), height: valueHeight * 0.9, alignment: .trailing)
                .padding(.trailing, scientific ? 6 : 10).padding(.bottom, -valueHeight * 0.02)
                .accessibilityLabel("Result").accessibilityValue(state.display)
            if scientific {
                Text(state.radians ? "Rad" : "Deg").font(.custom("Helvetica", fixedSize: 12))
                    .foregroundColor(.black.opacity(0.65)).position(x: 25, y: height - 16)
            }
            if menu {
                HStack(spacing: 0) {
                    menuButton("Copy") { UIPasteboard.general.string = state.display; menu = false }
                    if UIPasteboard.general.hasStrings { Divider().frame(height: 28); menuButton("Paste") { state.paste(UIPasteboard.general.string ?? ""); menu = false } }
                }
                .background(LinearGradient(colors: [Color(white: 0.36), .black], startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 7)).overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.6), lineWidth: 1))
                .position(x: width / 2, y: 20)
            }
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 20).onEnded { drag in
            if abs(drag.translation.width) > abs(drag.translation.height) { state.deleteDigit(); menu = false }
        })
        .onLongPressGesture { menu = true }
        .onTapGesture(count: 2) { menu = true }
        .onTapGesture { if menu { menu = false } }
    }
    private func menuButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(title).font(.custom("Helvetica-Bold", fixedSize: 14)).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8) }.buttonStyle(CalculatorUnfadedButtonStyle())
    }
    // Reposition crops from the original sheet at their native aspect ratio.
    // This preserves every baked-in glyph, corner, reflection and key shadow.
    private func originalKeyArtwork(_ key: RetroCalculatorKey) -> some View {
        Group {
            if key.id == "0" {
                // Preserve the zero glyph and both rounded ends. Only the empty
                // one-point center strip grows to span the first two columns.
                Image("calc-zero-key-normal")
                    .resizable(capInsets: EdgeInsets(top: 0, leading: 60, bottom: 0, trailing: 59))
                    .frame(width: key.frame.width / 2 + 60, height: 40)
            } else {
                ZStack(alignment: .topLeading) {
                    Image(key.sheet).resizable().frame(width: 240, height: 241)
                        .offset(x: -key.artworkFrame.minX, y: -key.artworkFrame.minY)
                }
                .frame(width: key.artworkFrame.width, height: key.artworkFrame.height, alignment: .topLeading)
                .clipped()
            }
        }
    }

    private func keyOverlay(_ asset: String, key: RetroCalculatorKey) -> some View {
        Group {
            if scientific && key.id == "0" {
                Image(asset).resizable(capInsets: EdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 10))
                    .frame(width: key.frame.width / 2 + 50, height: 28)
            } else {
                Image(asset)
            }
        }
        // The scientific sheet's caps are centered two points left of the
        // touch-cell midpoint. Its 2nd image also includes a transparent bottom.
        .offset(x: key.sheet == "calc-scientificKeypad" ? -2 : 0,
                y: key.sheet == "calc-scientificKeypad" && key.id == "2nd" ? 0.5 : 0)
    }

    private func keypad(width: CGFloat, height: CGFloat) -> some View {
        let keys = RetroCalculatorKey.keys(scientific: scientific, width: width)
        return ZStack(alignment: .topLeading) {
            if scientific {
                if abs(width - 480) < 0.01 {
                    HStack(spacing: 0) { Image("calc-scientificKeypad").resizable().frame(width: 240, height: 241); Image("calc-landscapeKeypad").resizable().frame(width: 240, height: 241) }
                } else {
                    Image("calc-landscapeBackground").resizable(resizingMode: .tile).frame(width: width, height: height)
                }
            } else { Image("calc-basicKeypad").resizable().frame(width: 320, height: 371) }
            ForEach(keys) { key in
                ZStack {
                    if scientific && abs(width - 480) >= 0.01 { originalKeyArtwork(key) }
                    if let asset = key.imageName(state: state, pressed: pressed == key.id) { keyOverlay(asset, key: key) }
                    if state.selectedOperation == key.id || (key.id == "mr" && state.memoryStored) {
                        Image(scientific ? "calc-sciRing" : "calc-basicRing")
                            .offset(x: key.sheet == "calc-scientificKeypad" ? -2 : 0)
                    }
                }
                .frame(width: key.frame.width, height: key.frame.height)
                .position(x: key.frame.midX, y: key.frame.midY)
                .accessibilityElement(children: .ignore).accessibilityLabel(key.label)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { state.press(key.id); menu = false }
            }
            CalculatorTouchSurface(keys: keys, pressed: $pressed) { key in state.press(key); menu = false }
                .frame(width: width, height: height).accessibilityHidden(true)
        }.frame(width: width, height: height).clipped()
    }
}

private struct CalculatorUnfadedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label }
}

// A single touch owns the keypad; moving off a key cancels its pressed image.
// No modern SwiftUI button dimming or long-press drag behavior is introduced.
private struct CalculatorTouchSurface: UIViewRepresentable {
    let keys: [RetroCalculatorKey]
    @Binding var pressed: String?
    let action: (String) -> Void
    func makeUIView(context: Context) -> Surface { let view = Surface(); view.backgroundColor = .clear; view.isMultipleTouchEnabled = false; return view }
    func updateUIView(_ view: Surface, context: Context) { view.keys = keys; view.changed = { pressed = $0 }; view.action = action }
    final class Surface: UIView {
        var keys: [RetroCalculatorKey] = []
        var changed: ((String?) -> Void)?
        var action: ((String) -> Void)?
        private var active: String?
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let p = touches.first?.location(in: self) else { return }
            active = keys.first { $0.frame.contains(p) }?.id; changed?(active)
            if active != nil { AudioServicesPlaySystemSound(1104) }
        }
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let p = touches.first?.location(in: self) else { return }
            changed?(keys.first { $0.frame.contains(p) }?.id == active ? active : nil)
        }
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            defer { active = nil; changed?(nil) }
            guard let p = touches.first?.location(in: self), let active, keys.first(where: { $0.frame.contains(p) })?.id == active else { return }
            action?(active)
        }
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { active = nil; changed?(nil) }
    }
}
#endif
