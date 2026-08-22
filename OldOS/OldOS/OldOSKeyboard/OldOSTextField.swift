import SwiftUI
import UIKit
import Introspect
import ObjectiveC
import WebKit

private final class OldOSIntrinsicUITextField: UITextField {
    var oldOSPreferredHeight: CGFloat = 22 {
        didSet { invalidateIntrinsicContentSize() }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: oldOSPreferredHeight)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: oldOSPreferredHeight)
    }
}

private final class OldOSNullInputView: UIView {
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 0)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: 0)
    }
}

enum OldOSKeyboardInputSuppression {
    static func install(on field: UITextField) {
        let changedInputView = !(field.inputView is OldOSNullInputView)
        if changedInputView {
            let nullInput = OldOSNullInputView(frame: .zero)
            nullInput.backgroundColor = .clear
            nullInput.isOpaque = false
            field.inputView = nullInput
        }
        field.inputAccessoryView = nil
        field.inputAssistantItem.leadingBarButtonGroups = []
        field.inputAssistantItem.trailingBarButtonGroups = []
        if changedInputView && field.isFirstResponder { field.reloadInputViews() }
    }

    static func install(on textView: UITextView) {
        let changedInputView = !(textView.inputView is OldOSNullInputView)
        if changedInputView {
            let nullInput = OldOSNullInputView(frame: .zero)
            nullInput.backgroundColor = .clear
            nullInput.isOpaque = false
            textView.inputView = nullInput
        }
        textView.inputAccessoryView = nil
        textView.inputAssistantItem.leadingBarButtonGroups = []
        textView.inputAssistantItem.trailingBarButtonGroups = []
        if changedInputView && textView.isFirstResponder { textView.reloadInputViews() }
    }
}

private extension OldOSKeyboardType {
    static func inferred(from type: UIKeyboardType) -> OldOSKeyboardType {
        switch type {
        case .asciiCapable: return .asciiCapable
        case .numbersAndPunctuation: return .numbersAndPunctuation
        case .URL: return .url
        case .numberPad: return .numberPad
        case .phonePad: return .phonePad
        case .namePhonePad: return .namePhonePad
        case .emailAddress: return .emailAddress
        case .decimalPad: return .decimalPad
        case .alphabet: return .alphabet
        case .asciiCapableNumberPad: return .numberPad
        case .twitter: return .default
        case .webSearch: return .url
        case .default: return .default
        @unknown default: return .default
        }
    }
}

private extension OldOSKeyboardReturnType {
    static func inferred(from type: UIReturnKeyType) -> OldOSKeyboardReturnType {
        switch type {
        case .go: return .go
        case .google: return .google
        case .join: return .join
        case .next: return .next
        case .route: return .route
        case .search: return .search
        case .send: return .send
        case .yahoo: return .yahoo
        case .done: return .done
        case .emergencyCall: return .emergencyCall
        case .continue: return .next
        case .default: return .default
        @unknown default: return .default
        }
    }
}

private extension OldOSKeyboardConfiguration {
    static func inferred(from field: UITextField) -> OldOSKeyboardConfiguration {
        let keyboardType = OldOSKeyboardType.inferred(from: field.keyboardType)
        let returnType = OldOSKeyboardReturnType.inferred(from: field.returnKeyType)

        let automaticReturn = field.enablesReturnKeyAutomatically
            || returnType == .search
            || (keyboardType == .url && returnType == .go)
        return OldOSKeyboardConfiguration(
            keyboardType: keyboardType,
            returnType: returnType,
            autocapitalization: field.autocapitalizationType != .none,
            autocorrection: field.autocorrectionType != .no
                && !field.isSecureTextEntry
                && keyboardType != .url
                && keyboardType != .emailAddress
                && keyboardType != .phonePad
                && keyboardType != .numberPad
                && keyboardType != .decimalPad,
            enablesCapsLock: true,
            playsKeyClicks: true,
            doubleSpacePeriod: keyboardType != .url,
            showsGlobeKey: false,

            dismissesOnReturn: returnType.usesBlueKey && returnType != .next,
            enablesReturnKeyAutomatically: automaticReturn
        )
    }

    static func inferred(from textView: UITextView) -> OldOSKeyboardConfiguration {
        let keyboardType = OldOSKeyboardType.inferred(from: textView.keyboardType)
        return OldOSKeyboardConfiguration(
            keyboardType: keyboardType,
            returnType: OldOSKeyboardReturnType.inferred(from: textView.returnKeyType),
            autocapitalization: textView.autocapitalizationType != .none,
            autocorrection: textView.autocorrectionType != .no
                && keyboardType != .url
                && keyboardType != .emailAddress
                && keyboardType != .phonePad
                && keyboardType != .numberPad
                && keyboardType != .decimalPad,
            enablesCapsLock: true,
            playsKeyClicks: true,
            doubleSpacePeriod: keyboardType != .url,
            showsGlobeKey: false,
            dismissesOnReturn: false,
            enablesReturnKeyAutomatically: textView.enablesReturnKeyAutomatically
        )
    }
}

@MainActor
private func dispatchOldOSReturn(on field: UITextField) {
    if let shouldReturn = field.delegate?.textFieldShouldReturn?(field) {
        guard shouldReturn else { return }
    }
    field.sendActions(for: .editingDidEndOnExit)
}

@MainActor
private final class OldOSKeyboardFieldAttachment: NSObject {
    weak var field: UITextField?
    weak var keyboard: OldOSKeyboardController?
    var explicitConfiguration: OldOSKeyboardConfiguration?

    init(
        field: UITextField,
        keyboard: OldOSKeyboardController,
        configuration: OldOSKeyboardConfiguration?
    ) {
        self.field = field
        self.keyboard = keyboard
        self.explicitConfiguration = configuration
        super.init()

        field.addTarget(self, action: #selector(editingDidBegin(_:)), for: .editingDidBegin)
        field.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
        field.addTarget(self, action: #selector(editingDidEnd(_:)), for: .editingDidEnd)
    }

    func update(
        keyboard: OldOSKeyboardController,
        configuration: OldOSKeyboardConfiguration?
    ) {
        self.keyboard = keyboard
        self.explicitConfiguration = configuration
    }

    @objc private func editingDidBegin(_ sender: UITextField) {
        guard let keyboard = keyboard else { return }
        let configuration = explicitConfiguration ?? .inferred(from: sender)
        keyboard.activate(
            textField: sender,
            configuration: configuration,
            onSubmit: { [weak sender] in
                guard let sender = sender else { return }
                dispatchOldOSReturn(on: sender)
            }
        )
    }

    @objc private func editingChanged(_ sender: UITextField) {
        keyboard?.textDidChange(sender)
    }

    @objc private func editingDidEnd(_ sender: UITextField) {
        keyboard?.deactivate(textField: sender)
    }
}

private var oldOSKeyboardAttachmentKey: UInt8 = 0

@MainActor
private func installOldOSKeyboardAttachment(
    on field: UITextField,
    keyboard: OldOSKeyboardController,
    configuration: OldOSKeyboardConfiguration?
) {
    OldOSKeyboardInputSuppression.install(on: field)

    if let existing = objc_getAssociatedObject(field, &oldOSKeyboardAttachmentKey)
        as? OldOSKeyboardFieldAttachment {
        existing.update(keyboard: keyboard, configuration: configuration)
    } else {
        let attachment = OldOSKeyboardFieldAttachment(
            field: field,
            keyboard: keyboard,
            configuration: configuration
        )
        objc_setAssociatedObject(
            field,
            &oldOSKeyboardAttachmentKey,
            attachment,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        if field.isFirstResponder {
            field.sendActions(for: .editingDidBegin)
        }
    }
}

@MainActor
final class OldOSKeyboardGlobalInputInterceptor: NSObject {
    weak var keyboard: OldOSKeyboardController?
    private var installed = false

    init(keyboard: OldOSKeyboardController) {
        self.keyboard = keyboard
        super.init()
    }

    func start() {
        guard !installed else { return }
        installed = true
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(textFieldDidBegin(_:)), name: UITextField.textDidBeginEditingNotification, object: nil)
        center.addObserver(self, selector: #selector(textFieldDidChange(_:)), name: UITextField.textDidChangeNotification, object: nil)
        center.addObserver(self, selector: #selector(textFieldDidEnd(_:)), name: UITextField.textDidEndEditingNotification, object: nil)
        center.addObserver(self, selector: #selector(textViewDidBegin(_:)), name: UITextView.textDidBeginEditingNotification, object: nil)
        center.addObserver(self, selector: #selector(textViewDidChange(_:)), name: UITextView.textDidChangeNotification, object: nil)
        center.addObserver(self, selector: #selector(textViewDidEnd(_:)), name: UITextView.textDidEndEditingNotification, object: nil)
    }

    func stop() {
        guard installed else { return }
        NotificationCenter.default.removeObserver(self)
        installed = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func textFieldDidBegin(_ note: Notification) {
        guard let field = note.object as? UITextField, let keyboard = keyboard else { return }

        OldOSKeyboardInputSuppression.install(on: field)

        let explicit = (objc_getAssociatedObject(field, &oldOSKeyboardAttachmentKey)
            as? OldOSKeyboardFieldAttachment)?.explicitConfiguration
        let configuration = explicit ?? .inferred(from: field)

        keyboard.activate(
            textField: field,
            configuration: configuration,
            onSubmit: { [weak field] in
                guard let field = field else { return }
                dispatchOldOSReturn(on: field)
            }
        )
    }

    @objc private func textFieldDidChange(_ note: Notification) {
        guard let field = note.object as? UITextField else { return }
        keyboard?.textDidChange(field)
    }

    @objc private func textFieldDidEnd(_ note: Notification) {
        guard let field = note.object as? UITextField else { return }
        keyboard?.deactivate(textField: field)
    }

    @objc private func textViewDidBegin(_ note: Notification) {
        guard let textView = note.object as? UITextView, let keyboard = keyboard else { return }
        OldOSKeyboardInputSuppression.install(on: textView)
        keyboard.activate(
            textView: textView,
            configuration: .inferred(from: textView)
        )
    }

    @objc private func textViewDidChange(_ note: Notification) {
        guard let textView = note.object as? UITextView else { return }
        keyboard?.textDidChange(textView)
    }

    @objc private func textViewDidEnd(_ note: Notification) {
        guard let textView = note.object as? UITextView else { return }
        keyboard?.deactivate(textView: textView)
    }
}

private extension View {
    func oldOSIntrospectTextField(
        customize: @escaping (UITextField) -> Void
    ) -> some View {
        inject(UIKitIntrospectionView(
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

private struct OldOSKeyboardAttachmentModifier: ViewModifier {
    @EnvironmentObject private var keyboard: OldOSKeyboardController
    let configuration: OldOSKeyboardConfiguration?

    func body(content: Content) -> some View {
        content.oldOSIntrospectTextField { field in
            installOldOSKeyboardAttachment(
                on: field,
                keyboard: keyboard,
                configuration: configuration
            )
        }
    }
}

public extension View {

    func oldOSKeyboard(
        _ configuration: OldOSKeyboardConfiguration? = nil
    ) -> some View {
        modifier(OldOSKeyboardAttachmentModifier(configuration: configuration))
    }
}

public struct OldOSTextField: UIViewRepresentable {
    @EnvironmentObject private var keyboard: OldOSKeyboardController

    @Binding private var text: String
    private let placeholder: String
    private let configuration: OldOSKeyboardConfiguration
    private let onSubmit: (() -> Void)?
    private let font: UIFont
    private let textColor: UIColor
    private let tintColor: UIColor
    private let height: CGFloat

    public init(
        _ placeholder: String,
        text: Binding<String>,
        configuration: OldOSKeyboardConfiguration = .standard,
        font: UIFont = UIFont(name: "Helvetica", size: 17) ?? .systemFont(ofSize: 17),
        textColor: UIColor = .black,
        tintColor: UIColor = UIColor(red: 0.20, green: 0.42, blue: 0.96, alpha: 1),
        height: CGFloat = 22,
        onSubmit: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.configuration = configuration
        self.font = font
        self.textColor = textColor
        self.tintColor = tintColor
        self.height = height
        self.onSubmit = onSubmit
    }

    private func applyInputTraits(to field: UITextField) {
        field.keyboardType = configuration.keyboardType.uiKeyboardType
        field.returnKeyType = configuration.returnType.uiReturnKeyType
        field.enablesReturnKeyAutomatically = configuration.enablesReturnKeyAutomatically
        field.autocapitalizationType = (configuration.autocapitalization && configuration.keyboardType.allowsAutomaticCapitalization) ? .sentences : .none
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public func makeUIView(context: Context) -> UITextField {
        let field = OldOSIntrinsicUITextField(frame: .zero)
        field.oldOSPreferredHeight = height
        field.delegate = context.coordinator
        field.text = text
        field.placeholder = placeholder
        field.font = font
        field.textColor = textColor
        field.tintColor = tintColor
        field.backgroundColor = .clear
        field.borderStyle = .none
        field.clearButtonMode = .never
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.smartQuotesType = .no
        field.smartDashesType = .no
        field.smartInsertDeleteType = .no
        applyInputTraits(to: field)
        field.contentVerticalAlignment = .center
        field.setContentHuggingPriority(.required, for: .vertical)
        field.setContentCompressionResistancePriority(.required, for: .vertical)

        OldOSKeyboardInputSuppression.install(on: field)

        field.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingChanged(_:)),
            for: .editingChanged
        )
        return field
    }

    public func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        if uiView.text != text { uiView.text = text }
        uiView.placeholder = placeholder
        uiView.font = font
        uiView.textColor = textColor
        uiView.tintColor = tintColor
        applyInputTraits(to: uiView)
        if let field = uiView as? OldOSIntrinsicUITextField {
            field.oldOSPreferredHeight = height
        }
    }

    public final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: OldOSTextField

        init(parent: OldOSTextField) {
            self.parent = parent
        }

        @objc func editingChanged(_ sender: UITextField) {
            parent.text = sender.text ?? ""
            parent.keyboard.textDidChange(sender)
        }

        public func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.keyboard.activate(
                textField: textField,
                configuration: parent.configuration,
                onSubmit: parent.onSubmit
            )
        }

        public func textFieldDidEndEditing(_ textField: UITextField) {
            parent.keyboard.deactivate(textField: textField)
        }

        public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            guard parent.keyboard.returnKeyEnabled else { return false }
            parent.onSubmit?()
            if parent.configuration.dismissesOnReturn {
                textField.resignFirstResponder()
            }
            return false
        }
    }
}

@MainActor
final class OldOSWebKitKeyboardBridge: NSObject, WKScriptMessageHandler {
    private static let handlerName = "oldOSKeyboardWebKit"
    private static var associatedBridgeKey: UInt8 = 0
    private static let scriptMarker = "OLDOS_WEBKIT_KEYBOARD"

    private weak var webView: WKWebView?
    private weak var keyboard: OldOSKeyboardController?
    private weak var activeInputView: UIView?
    private var activeFrame: WKFrameInfo?
    private var activeDescriptor: FieldDescriptor?
    private var activeToken: String?
    private var activatedToken: String?
    private var activationGeneration: Int = 0

    private struct FieldDescriptor {
        let token: String
        let tagName: String
        let inputType: String
        let inputMode: String
        let enterKeyHint: String
        let autocapitalize: String
        let autocorrect: String
        let spellcheck: Bool
        let hasForm: Bool
        let isMultiline: Bool
        let isContentEditable: Bool

        init?(body: [String: Any]) {
            guard let token = body["token"] as? String else { return nil }
            self.token = token
            self.tagName = (body["tag"] as? String ?? "").lowercased()
            self.inputType = (body["type"] as? String ?? "").lowercased()
            self.inputMode = (body["inputMode"] as? String ?? "").lowercased()
            self.enterKeyHint = (body["enterKeyHint"] as? String ?? "").lowercased()
            self.autocapitalize = (body["autocapitalize"] as? String ?? "").lowercased()
            self.autocorrect = (body["autocorrect"] as? String ?? "").lowercased()
            self.spellcheck = body["spellcheck"] as? Bool ?? true
            self.hasForm = body["hasForm"] as? Bool ?? false
            self.isMultiline = body["multiline"] as? Bool ?? false
            self.isContentEditable = body["contentEditable"] as? Bool ?? false
        }

        var keyboardType: OldOSKeyboardType {
            switch inputMode {
            case "numeric": return .numberPad
            case "decimal": return .decimalPad
            case "tel": return .phonePad
            case "email": return .emailAddress
            case "url": return .url
            default: break
            }

            switch inputType {
            case "number": return .numberPad
            case "tel": return .phonePad
            case "email": return .emailAddress
            case "url": return .url
            default: return .default
            }
        }

        var returnType: OldOSKeyboardReturnType {
            switch enterKeyHint {
            case "go": return .go
            case "next", "previous": return .next
            case "search": return .search
            case "send": return .send
            case "done": return .done
            case "enter", "return": return .default
            default: break
            }

            if inputType == "search" { return .search }
            if isMultiline { return .default }
            if hasForm || inputType == "url" || inputType == "email" { return .go }
            return .done
        }

        var shouldAutocapitalize: Bool {
            if keyboardType == .url || keyboardType == .emailAddress || keyboardType == .numberPad || keyboardType == .decimalPad || keyboardType == .phonePad {
                return false
            }
            switch autocapitalize {
            case "none", "off", "false": return false
            default: return true
            }
        }

        var shouldAutocorrect: Bool {
            if inputType == "password" { return false }
            if keyboardType == .url || keyboardType == .emailAddress || keyboardType == .numberPad || keyboardType == .decimalPad || keyboardType == .phonePad {
                return false
            }
            if !spellcheck { return false }
            switch autocorrect {
            case "off", "false", "no": return false
            default: return true
            }
        }

        var configuration: OldOSKeyboardConfiguration {
            OldOSKeyboardConfiguration(
                keyboardType: keyboardType,
                returnType: returnType,
                autocapitalization: shouldAutocapitalize,
                autocorrection: shouldAutocorrect,
                enablesCapsLock: true,
                playsKeyClicks: true,
                doubleSpacePeriod: keyboardType != .url && keyboardType != .emailAddress,
                showsGlobeKey: false,

                dismissesOnReturn: false,
                enablesReturnKeyAutomatically: false
            )
        }

        var wantsAdjacentFocus: Bool {
            enterKeyHint == "next" || enterKeyHint == "previous"
        }

        var wantsNativeNewline: Bool {
            isMultiline && !["done", "go", "search", "send", "next", "previous"].contains(enterKeyHint)
        }
    }

    private init(webView: WKWebView, keyboard: OldOSKeyboardController) {
        self.webView = webView
        self.keyboard = keyboard
        super.init()
    }

    static func prepare(configuration: WKWebViewConfiguration) {
        let controller = configuration.userContentController
        guard !controller.userScripts.contains(where: { $0.source.contains(scriptMarker) }) else { return }
        controller.addUserScript(
            WKUserScript(
                source: bootstrapJavaScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
        )
    }

    @discardableResult
    static func install(
        on webView: WKWebView,
        keyboard: OldOSKeyboardController
    ) -> OldOSWebKitKeyboardBridge {
        prepare(configuration: webView.configuration)

        if let existing = objc_getAssociatedObject(webView, &associatedBridgeKey)
            as? OldOSWebKitKeyboardBridge {
            existing.keyboard = keyboard
            existing.webView = webView
            existing.reinjectCurrentDocument()
            return existing
        }

        let bridge = OldOSWebKitKeyboardBridge(webView: webView, keyboard: keyboard)
        let userContentController = webView.configuration.userContentController

        userContentController.removeScriptMessageHandler(forName: handlerName)
        userContentController.add(bridge, name: handlerName)

        objc_setAssociatedObject(
            webView,
            &associatedBridgeKey,
            bridge,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        bridge.reinjectCurrentDocument()
        return bridge
    }

    func reinjectCurrentDocument() {
        webView?.evaluateJavaScript(Self.bootstrapJavaScript, completionHandler: nil)
    }

    func navigationStarted() {
        guard activeToken != nil else { return }
        activationGeneration &+= 1
        activeToken = nil
        activatedToken = nil
        activeDescriptor = nil
        activeFrame = nil
        activeInputView = nil
        keyboard?.hide()
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == Self.handlerName,
              let body = message.body as? [String: Any],
              let event = body["event"] as? String
        else { return }

        switch event {
        case "focus":
            guard let descriptor = FieldDescriptor(body: body) else { return }
            activeToken = descriptor.token
            activatedToken = nil
            activeDescriptor = descriptor
            activeFrame = message.frameInfo
            activationGeneration &+= 1
            scheduleActivation(generation: activationGeneration)

        case "input":
            guard let token = body["token"] as? String,
                  token == activeToken,
                  let inputView = activeInputView
            else { return }
            keyboard?.textDidChange(inputView: inputView)

        case "blur":
            guard let token = body["token"] as? String,
                  token == activeToken
            else { return }
            deactivateCurrentEditor()

        default:
            break
        }
    }

    private func scheduleActivation(generation: Int) {

        let delays: [TimeInterval] = [0, 0.015, 0.05, 0.12]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self,
                      generation == self.activationGeneration,
                      self.activeToken != nil
                else { return }
                self.activateFocusedWebEditorIfAvailable()
            }
        }
    }

    private func activateFocusedWebEditorIfAvailable() {
        guard let webView = webView,
              let descriptor = activeDescriptor,
              activatedToken != descriptor.token,
              let responderView = firstResponder(in: webView),
              responderView is UITextInput,
              responderView is UIKeyInput
        else { return }

        activeInputView = responderView
        activatedToken = descriptor.token
        let token = descriptor.token
        keyboard?.activate(
            inputView: responderView,
            configuration: descriptor.configuration,
            onSubmit: { [weak self] in
                self?.handleReturn(forToken: token)
            }
        )
    }

    private func deactivateCurrentEditor() {
        activationGeneration &+= 1
        if let inputView = activeInputView {
            keyboard?.deactivate(inputView: inputView)
        }
        activeInputView = nil
        activeDescriptor = nil
        activeFrame = nil
        activeToken = nil
        activatedToken = nil
    }

    private func handleReturn(forToken token: String) {
        guard token == activeToken,
              let descriptor = activeDescriptor
        else { return }

        if descriptor.wantsNativeNewline {
            (activeInputView as? UIKeyInput)?.insertText("\n")
            if let inputView = activeInputView {
                keyboard?.textDidChange(inputView: inputView)
            }
            return
        }

        guard let webView = webView else { return }
        let frame = activeFrame
        let generation = activationGeneration

        webView.evaluateJavaScript(
            Self.returnJavaScript,
            in: frame,
            in: .page
        ) { [weak self] _ in
            guard let self = self,
                  generation == self.activationGeneration,
                  token == self.activeToken
            else { return }

            if descriptor.wantsAdjacentFocus { return }
            self.keyboard?.hide()
            self.activeInputView = nil
            self.activeDescriptor = nil
            self.activeFrame = nil
            self.activeToken = nil
            self.activatedToken = nil
            self.activationGeneration &+= 1
        }
    }

    private func firstResponder(in root: UIView) -> UIView? {
        if root.isFirstResponder { return root }
        for child in root.subviews {
            if let found = firstResponder(in: child) { return found }
        }
        return nil
    }

    private static let returnJavaScript = #"""
(function () {
    const bridge = window.__oldOSKeyboardBridge;
    if (!bridge || typeof bridge.handleReturn !== "function") {
        return { handled: false, reason: "bridge-missing" };
    }
    return bridge.handleReturn();
})();
"""#

    private static let bootstrapJavaScript = #"""
void "OLDOS_WEBKIT_KEYBOARD";
(function () {
    if (window.__oldOSKeyboardBridgeInstalled) {
        if (window.__oldOSKeyboardBridge && typeof window.__oldOSKeyboardBridge.prepareTree === "function") {
            window.__oldOSKeyboardBridge.prepareTree(document);
        }
        return;
    }
    window.__oldOSKeyboardBridgeInstalled = true;

    const HANDLER = "oldOSKeyboardWebKit";
    const originalInputModes = new WeakMap();
    const elementTokens = new WeakMap();
    const frameSeed = Math.random().toString(36).slice(2);
    let tokenCounter = 0;

    function post(payload) {
        try {
            const handler = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers[HANDLER];
            if (handler) handler.postMessage(payload);
        } catch (_) {}
    }

    function editableRoot(node) {
        if (!(node instanceof Element)) return null;

        if (node instanceof HTMLInputElement) {
            const type = (node.type || "text").toLowerCase();
            const allowed = ["text", "search", "url", "email", "tel", "number", "password"];
            return allowed.indexOf(type) !== -1 && !node.disabled && !node.readOnly ? node : null;
        }

        if (node instanceof HTMLTextAreaElement) {
            return !node.disabled && !node.readOnly ? node : null;
        }

        if (node.isContentEditable) {
            let root = node;
            while (root.parentElement && root.parentElement.isContentEditable) {
                root = root.parentElement;
            }
            return root;
        }

        const closest = node.closest("input, textarea, [contenteditable]");
        if (closest && closest !== node) return editableRoot(closest);
        return null;
    }

    function rememberAndSuppressInputMode(element) {
        if (!element) return;
        const current = element.getAttribute("inputmode");
        const normalized = (current || "").toLowerCase();

        if (!originalInputModes.has(element)) {
            originalInputModes.set(element, current || "");
        } else if (normalized !== "none") {
            originalInputModes.set(element, current || "");
        }

        if (normalized !== "none") {
            element.setAttribute("inputmode", "none");
        }
    }

    function prepareTree(root) {
        if (!root) return;
        if (root instanceof Element) {
            const editable = editableRoot(root);
            if (editable === root) rememberAndSuppressInputMode(editable);
        }
        if (root.querySelectorAll) {
            root.querySelectorAll("input, textarea, [contenteditable]").forEach(function (candidate) {
                const editable = editableRoot(candidate);
                if (editable) rememberAndSuppressInputMode(editable);
            });
        }
    }

    function descriptorFor(element, token) {
        const isInput = element instanceof HTMLInputElement;
        const isTextArea = element instanceof HTMLTextAreaElement;
        const inputType = isInput ? (element.type || "text").toLowerCase() : "";
        const originalInputMode = (originalInputModes.get(element) || "").toLowerCase();
        const enterKeyHint = ((element.getAttribute("enterkeyhint") || element.enterKeyHint || "") + "").toLowerCase();
        const autocapitalize = ((element.getAttribute("autocapitalize") || element.autocapitalize || "") + "").toLowerCase();
        const autocorrect = ((element.getAttribute("autocorrect") || "") + "").toLowerCase();
        const spellcheck = element.spellcheck !== false;
        const multiline = isTextArea || element.isContentEditable;

        return {
            event: "focus",
            token: token,
            tag: (element.tagName || "").toLowerCase(),
            type: inputType,
            inputMode: originalInputMode,
            enterKeyHint: enterKeyHint,
            autocapitalize: autocapitalize,
            autocorrect: autocorrect,
            spellcheck: spellcheck,
            hasForm: !!element.form,
            multiline: multiline,
            contentEditable: !!element.isContentEditable
        };
    }

    function tokenFor(element) {
        let token = elementTokens.get(element);
        if (!token) {
            token = frameSeed + ":" + (++tokenCounter);
            elementTokens.set(element, token);
        }
        return token;
    }

    function currentlyActiveEditable() {
        return editableRoot(document.activeElement);
    }

    function visibleEditableElements() {
        const result = [];
        const seen = new Set();
        document.querySelectorAll("input, textarea, [contenteditable]").forEach(function (candidate) {
            const element = editableRoot(candidate);
            if (!element || seen.has(element)) return;
            const style = window.getComputedStyle(element);
            const rect = element.getBoundingClientRect();
            if (style.display === "none" || style.visibility === "hidden" || rect.width === 0 || rect.height === 0) return;
            if (element.tabIndex < 0) return;
            seen.add(element);
            result.push(element);
        });
        return result;
    }

    function focusAdjacent(element, direction) {
        const fields = visibleEditableElements();
        const index = fields.indexOf(element);
        if (index < 0) return false;
        const nextIndex = index + direction;
        if (nextIndex < 0 || nextIndex >= fields.length) return false;
        fields[nextIndex].focus();
        return true;
    }

    function keyboardEvent(type) {
        try {
            return new KeyboardEvent(type, {
                key: "Enter",
                code: "Enter",
                keyCode: 13,
                which: 13,
                charCode: type === "keypress" ? 13 : 0,
                bubbles: true,
                cancelable: true
            });
        } catch (_) {
            const event = document.createEvent("Event");
            event.initEvent(type, true, true);
            return event;
        }
    }

    function handleReturn() {
        const element = currentlyActiveEditable();
        if (!element) return { handled: false, reason: "no-active-editor" };

        const hint = ((element.getAttribute("enterkeyhint") || element.enterKeyHint || "") + "").toLowerCase();
        if (hint === "next") {
            return { handled: focusAdjacent(element, 1), keepKeyboard: true };
        }
        if (hint === "previous") {
            return { handled: focusAdjacent(element, -1), keepKeyboard: true };
        }

        const multiline = element instanceof HTMLTextAreaElement || element.isContentEditable;
        if (multiline && ["done", "go", "search", "send"].indexOf(hint) === -1) {
            return { handled: false, nativeNewline: true };
        }

        let prevented = false;
        try {
            const down = keyboardEvent("keydown");
            prevented = !element.dispatchEvent(down) || down.defaultPrevented;

            if (!prevented) {
                const press = keyboardEvent("keypress");
                prevented = !element.dispatchEvent(press) || press.defaultPrevented;
            }

            if (!prevented) {
                if (element.form) {
                    if (typeof element.form.requestSubmit === "function") {
                        const submitter = element.form.querySelector('button[type="submit"], input[type="submit"], button:not([type])');
                        if (submitter) element.form.requestSubmit(submitter);
                        else element.form.requestSubmit();
                    } else if (typeof element.form.submit === "function") {
                        element.form.submit();
                    }
                } else {
                    element.dispatchEvent(new Event("change", { bubbles: true }));
                }
            }

            element.dispatchEvent(keyboardEvent("keyup"));
        } catch (_) {}

        if (document.activeElement === element && typeof element.blur === "function") {
            element.blur();
        }
        return { handled: true, prevented: prevented };
    }

    document.addEventListener("focusin", function (event) {
        const element = editableRoot(event.target);
        if (!element) return;
        rememberAndSuppressInputMode(element);
        const token = frameSeed + ":" + (++tokenCounter);
        elementTokens.set(element, token);
        post(descriptorFor(element, token));
    }, true);

    document.addEventListener("input", function (event) {
        const element = editableRoot(event.target);
        if (!element) return;
        post({ event: "input", token: tokenFor(element) });
    }, true);

    document.addEventListener("focusout", function (event) {
        const element = editableRoot(event.target);
        if (!element) return;
        const token = tokenFor(element);
        setTimeout(function () {
            const active = currentlyActiveEditable();
            if (active && active !== element) return;
            post({ event: "blur", token: token });
        }, 0);
    }, true);

    const observer = new MutationObserver(function (records) {
        records.forEach(function (record) {
            if (record.type === "attributes") {
                const editable = editableRoot(record.target);
                if (editable) rememberAndSuppressInputMode(editable);
            } else {
                record.addedNodes.forEach(function (node) {
                    if (node.nodeType === Node.ELEMENT_NODE || node.nodeType === Node.DOCUMENT_FRAGMENT_NODE) {
                        prepareTree(node);
                    }
                });
            }
        });
    });

    observer.observe(document, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ["inputmode", "type", "contenteditable", "disabled", "readonly"]
    });

    window.__oldOSKeyboardBridge = {
        prepareTree: prepareTree,
        handleReturn: handleReturn
    };

    prepareTree(document);
})();
"""#
}

@MainActor
enum OldOSClassicTextInteraction {
    private static var coordinatorKey: UInt8 = 0

    static func install(on inputView: UIView, keyboard: OldOSKeyboardController) {
        guard inputView is UITextInput else { return }
        if let coordinator = objc_getAssociatedObject(inputView, &coordinatorKey)
            as? OldOSTextInteractionCoordinator {
            coordinator.keyboard = keyboard
            coordinator.activate()
            return
        }
        let coordinator = OldOSTextInteractionCoordinator(inputView: inputView, keyboard: keyboard)
        objc_setAssociatedObject(
            inputView,
            &coordinatorKey,
            coordinator,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        coordinator.activate()
    }

    static func deactivate(on inputView: UIView) {
        (objc_getAssociatedObject(inputView, &coordinatorKey)
            as? OldOSTextInteractionCoordinator)?.deactivate()
    }
}

@MainActor
private final class OldOSVariableDelayLoupeGesture: UILongPressGestureRecognizer {
    weak var textInputView: UIView?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {

        if let view = textInputView,
           let input = view as? UITextInput,
           let selection = input.selectedTextRange,
           selection.isEmpty,
           let touch = touches.first {
            let caret = input.caretRect(for: selection.start)
            let p = touch.location(in: view)
            let caretPoint = CGPoint(x: caret.midX, y: caret.midY)
            minimumPressDuration = hypot(p.x - caretPoint.x, p.y - caretPoint.y) <= 50 ? 0.25 : 0.50
        } else {
            minimumPressDuration = 0.50
        }
        super.touchesBegan(touches, with: event)
    }
}

@MainActor
private final class OldOSSelectionHandleView: UIView {
    enum Kind { case start, end }

    let kind: Kind
    var onPan: ((UIPanGestureRecognizer) -> Void)?

    private let outerStem = UIView()
    private let innerStem = UIView()
    private let dotContainer = UIView()
    private let dotImage = UIImageView(image: UIImage(named: "kb-drag-dot"))
    private let panGesture = UIPanGestureRecognizer()
    private let sourceContainerSize: CGFloat = 100

    private let caretBlue = UIColor(red: 0.26, green: 0.42, blue: 0.95, alpha: 1)

    init(kind: Kind) {
        self.kind = kind
        super.init(frame: CGRect(x: 0, y: 0, width: sourceContainerSize, height: sourceContainerSize))
        isUserInteractionEnabled = true
        backgroundColor = .clear
        clipsToBounds = false

        outerStem.backgroundColor = caretBlue.withAlphaComponent(0.5)
        innerStem.backgroundColor = caretBlue
        outerStem.isUserInteractionEnabled = false
        innerStem.isUserInteractionEnabled = false

        dotContainer.backgroundColor = .clear
        dotContainer.clipsToBounds = false
        dotContainer.isUserInteractionEnabled = false
        dotImage.contentMode = .scaleToFill
        dotImage.isUserInteractionEnabled = false
        dotContainer.addSubview(dotImage)

        addSubview(outerStem)
        addSubview(innerStem)
        addSubview(dotContainer)

        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        panGesture.cancelsTouchesInView = true
        panGesture.addTarget(self, action: #selector(panned(_:)))
        addGestureRecognizer(panGesture)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func panned(_ gesture: UIPanGestureRecognizer) {
        onPan?(gesture)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        dotContainer.frame.insetBy(dx: -30, dy: -24).contains(point)
    }

    func place(at caretRect: CGRect, in window: UIWindow) {
        let stemWidth: CGFloat = 3
        let lineHeight = max(1, caretRect.height)
        let endpointY = kind == .start ? caretRect.minY : caretRect.maxY

        frame = CGRect(
            x: caretRect.midX - sourceContainerSize / 2,
            y: endpointY - sourceContainerSize / 2,
            width: sourceContainerSize,
            height: sourceContainerSize
        )

        let localCaretX = caretRect.midX - frame.minX
        let localCaretTop = caretRect.minY - frame.minY
        let stemFrame = CGRect(
            x: localCaretX - stemWidth / 2,
            y: localCaretTop,
            width: stemWidth,
            height: lineHeight
        )
        outerStem.frame = stemFrame
        innerStem.frame = stemFrame.insetBy(dx: 1, dy: 0)

        let dotSize = CGSize(width: 15, height: 15)
        let dotX = round(localCaretX - dotSize.width / 2)
        let dotY: CGFloat = kind == .start
            ? localCaretTop - 13
            : stemFrame.maxY
        dotContainer.frame = CGRect(origin: CGPoint(x: dotX, y: dotY), size: dotSize)
        let imageSize = dotImage.image?.size ?? CGSize(width: 15, height: 17)
        dotImage.frame = CGRect(x: 0.5, y: 0, width: imageSize.width, height: imageSize.height)
    }

    func grabberCenter(in view: UIView) -> CGPoint {
        convert(CGPoint(x: dotContainer.frame.midX, y: dotContainer.frame.midY), to: view)
    }

    func setDotHiddenForMagnifierCapture(_ hidden: Bool) {
        dotContainer.isHidden = hidden
    }
}

@MainActor
private final class OldOSSelectionHighlightView: UIView {
    private var selectionRects: [CGRect] = []
    private var selectionColor: UIColor = .clear

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(
        windowRects: [CGRect],
        color: UIColor,
        visibleFrame: CGRect,
        in window: UIWindow
    ) {
        frame = window.bounds
        selectionColor = color
        selectionRects = windowRects.compactMap { sourceRect in
            let clipped = sourceRect.intersection(visibleFrame)
            guard !clipped.isNull, !clipped.isInfinite,
                  clipped.width > 0, clipped.height > 0 else { return nil }
            return window.convert(clipped, to: self)
        }
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), !selectionRects.isEmpty else { return }
        context.setFillColor(selectionColor.cgColor)
        for selectionRect in selectionRects {
            context.fill(selectionRect)
        }
    }
}

@MainActor
private final class OldOSMagnifierView: UIView {
    enum Kind {
        case caret
        case ranged
    }

    private(set) var kind: Kind
    private let lowImageView = UIImageView()
    private let contentImageView = UIImageView()
    private let highImageView = UIImageView()
    private let maskImage: UIImage?

    var contentFocusPointInBounds: CGPoint {
        switch kind {
        case .caret:
            return CGPoint(x: 63.5, y: 65.5)
        case .ranged:
            return CGPoint(x: 72.5, y: 21.0)
        }
    }

    let sourceMagnification: CGFloat = 1.2

    var isRangedMagnifier: Bool {
        if case .ranged = kind { return true }
        return false
    }

    init(kind: Kind) {
        self.kind = kind
        let size: CGSize
        switch kind {
        case .caret:
            size = CGSize(width: 127, height: 127)
            lowImageView.image = UIImage(named: "kb-loupe-lo")
            highImageView.image = UIImage(named: "kb-loupe-hi")
            maskImage = UIImage(named: "kb-loupe-mask")
        case .ranged:

            size = CGSize(width: 145, height: 59)
            lowImageView.image = UIImage(named: "kb-magnifier-ranged-lo")
            highImageView.image = UIImage(named: "kb-magnifier-ranged-hi")
            maskImage = UIImage(named: "kb-magnifier-ranged-mask")
        }
        super.init(frame: CGRect(origin: .zero, size: size))
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
        clipsToBounds = false

        [lowImageView, contentImageView, highImageView].forEach {
            $0.frame = bounds
            $0.contentMode = .scaleToFill
            $0.isUserInteractionEnabled = false
            addSubview($0)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        lowImageView.frame = bounds
        contentImageView.frame = bounds
        highImageView.frame = bounds
    }

    func setSnapshot(_ image: UIImage?) {
        guard let image, let maskImage else {
            contentImageView.image = nil
            return
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false
        let size = bounds.size
        contentImageView.image = UIGraphicsImageRenderer(size: size, format: format).image { rendererContext in
            let rect = CGRect(origin: .zero, size: size)
            image.draw(in: rect)

            switch kind {
            case .caret:

                maskImage.draw(in: rect, blendMode: .destinationIn, alpha: 1)

            case .ranged:

                guard let rawMask = maskImage.cgImage else { return }
                let ctx = rendererContext.cgContext
                ctx.saveGState()
                ctx.setBlendMode(.destinationIn)
                ctx.draw(rawMask, in: rect)
                ctx.restoreGState()
            }
        }
    }

    func appear(from animationPoint: CGPoint, animated: Bool) {
        guard let superview else { return }
        let terminalCenter = center
        if !animated {
            transform = .identity
            alpha = 1
            return
        }
        let localAnimation = (superview is UIWindow)
            ? animationPoint
            : superview.convert(animationPoint, from: nil)
        let dx = localAnimation.x - terminalCenter.x
        let dy = localAnimation.y - terminalCenter.y
        transform = CGAffineTransform(translationX: dx * 0.75, y: dy * 0.75)
            .scaledBy(x: 0.25, y: 0.25)
        alpha = 1
        UIView.animate(
            withDuration: 0.075,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseOut, .allowUserInteraction],
            animations: { self.transform = .identity }
        )
    }

    func disappear(toward animationPoint: CGPoint, animated: Bool, completion: @escaping () -> Void) {
        guard animated, let superview else {
            removeFromSuperview()
            completion()
            return
        }
        let terminalCenter = center
        let localAnimation = (superview is UIWindow)
            ? animationPoint
            : superview.convert(animationPoint, from: nil)
        let dx = localAnimation.x - terminalCenter.x
        let dy = localAnimation.y - terminalCenter.y
        UIView.animate(
            withDuration: 0.075,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseIn, .allowUserInteraction],
            animations: {
                self.transform = CGAffineTransform(translationX: dx * 0.75, y: dy * 0.75)
                    .scaledBy(x: 0.25, y: 0.25)
            },
            completion: { _ in
                self.removeFromSuperview()
                completion()
            }
        )
    }
}

@MainActor
private final class OldOSCalloutBarButton: UIButton {
    enum Position { case single, left, middle, right }

    var replacementText: String?
    var actionBlock: (() -> Void)?
    var position: Position = .single

    init(title: String, position: Position) {
        self.position = position
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(.white, for: .normal)
        titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 14) ?? UIFont.boldSystemFont(ofSize: 14)
        titleLabel?.textAlignment = .center
        titleLabel?.shadowColor = UIColor.black.withAlphaComponent(0.5)
        titleLabel?.shadowOffset = CGSize(width: 0, height: -1)

        switch position {
        case .left:
            titleEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: -3)
        case .right:
            titleEdgeInsets = UIEdgeInsets(top: 0, left: -3, bottom: 0, right: 3)
        case .middle, .single:
            titleEdgeInsets = .zero
        }
        adjustsImageWhenHighlighted = false
        configureBackgrounds()
        addTarget(self, action: #selector(pressed), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func sourceStretchable(_ name: String, leftCapWidth: CGFloat) -> UIImage? {
        guard let image = UIImage(named: name) else { return nil }
        let rightCapWidth = max(0, image.size.width - leftCapWidth - 1)
        return image.resizableImage(
            withCapInsets: UIEdgeInsets(
                top: 0,
                left: leftCapWidth,
                bottom: 0,
                right: rightCapWidth
            ),
            resizingMode: .stretch
        )
    }

    private func configureBackgrounds() {
        let normal: UIImage?
        let highlighted: UIImage?
        switch position {
        case .single:
            normal = sourceStretchable("UICalloutBarSingle", leftCapWidth: 10)
            highlighted = sourceStretchable("UICalloutBarSingleHi", leftCapWidth: 10)
        case .left:
            normal = sourceStretchable("UICalloutBarLeft", leftCapWidth: 10)
            highlighted = sourceStretchable("UICalloutBarLeftHi", leftCapWidth: 10)
        case .middle:
            normal = UIImage(named: "UICalloutBarMiddle")?.resizableImage(
                withCapInsets: .zero, resizingMode: .stretch)
            highlighted = UIImage(named: "UICalloutBarMiddleHi")?.resizableImage(
                withCapInsets: .zero, resizingMode: .stretch)
        case .right:
            normal = sourceStretchable("UICalloutBarRight", leftCapWidth: 10)
            highlighted = sourceStretchable("UICalloutBarRightHi", leftCapWidth: 10)
        }
        setBackgroundImage(normal, for: .normal)
        setBackgroundImage(highlighted, for: .highlighted)
    }

    @objc private func pressed() {
        actionBlock?()
    }
}

@MainActor
private final class OldOSCalloutBarView: UIView {
    struct Item {
        let title: String
        let replacementText: String?
        let isInteractive: Bool
        let action: () -> Void

        init(
            title: String,
            replacementText: String?,
            isInteractive: Bool = true,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.replacementText = replacementText
            self.isInteractive = isInteractive
            self.action = action
        }
    }

    enum ArrowDirection { case bottom, top }

    private let bodyView = UIView()
    private let shadowView = UIView()
    private let arrow = UIImageView()
    private let arrowHighlight = UIImageView()
    private var buttons: [OldOSCalloutBarButton] = []
    private var separators: [UIImageView] = []
    private var items: [Item] = []
    private(set) var arrowDirection: ArrowDirection = .bottom
    private(set) var targetPoint: CGPoint = .zero
    private var bodyFrame: CGRect = .zero

    var onDismiss: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        clipsToBounds = false
        shadowView.isUserInteractionEnabled = false
        bodyView.backgroundColor = .clear

        addSubview(shadowView)
        addSubview(arrow)
        addSubview(arrowHighlight)
        addSubview(bodyView)
        arrowHighlight.isHidden = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    static func naturalWidth(for title: String) -> CGFloat {
        let font = UIFont(name: "Helvetica-Bold", size: 14) ?? UIFont.boldSystemFont(ofSize: 14)
        let measured = ceil((title as NSString).size(withAttributes: [.font: font]).width)
        return max(16, measured) + 32
    }

    func configure(items: [Item]) {
        self.items = items
        buttons.forEach { $0.removeFromSuperview() }
        separators.forEach { $0.removeFromSuperview() }
        buttons.removeAll(keepingCapacity: true)
        separators.removeAll(keepingCapacity: true)

        for (index, item) in items.enumerated() {
            let position: OldOSCalloutBarButton.Position
            if items.count == 1 { position = .single }
            else if index == 0 { position = .left }
            else if index == items.count - 1 { position = .right }
            else { position = .middle }

            let button = OldOSCalloutBarButton(title: item.title, position: position)
            button.replacementText = item.replacementText
            button.actionBlock = item.action
            button.isUserInteractionEnabled = item.isInteractive
            if item.isInteractive {
                button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: [.touchDown, .touchDragEnter])
                button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
            }
            bodyView.addSubview(button)
            buttons.append(button)

            if index > 0 {
                let cut = UIImageView(image: UIImage(named: "UICalloutBarCut"))
                cut.isUserInteractionEnabled = false
                bodyView.addSubview(cut)
                separators.append(cut)
            }
        }
    }

    func place(targetRect: CGRect, visibleFrame: CGRect) {
        guard !items.isEmpty else { return }
        let bodyHeight: CGFloat = 38
        let bottomArrowSize = UIImage(named: "UICalloutBarArrowBottom")?.size
            ?? CGSize(width: 24, height: 17)
        let topArrowSize = UIImage(named: "UICalloutBarArrowTop")?.size
            ?? CGSize(width: 24, height: 12)

        let naturalWidths = items.map { Self.naturalWidth(for: $0.title) }
        let naturalBodyWidth = naturalWidths.reduce(0, +)
        let sourceSideMargin: CGFloat = 10
        let availableBodyWidth = max(1, visibleFrame.width - 2 * sourceSideMargin)
        let bodyWidth = min(naturalBodyWidth, availableBodyWidth)
        let compression = naturalBodyWidth > 0 ? min(1, bodyWidth / naturalBodyWidth) : 1

        let target = CGPoint(x: targetRect.midX, y: targetRect.midY)
        let belowArrowTotal = bodyHeight + bottomArrowSize.height
        let aboveRoom = targetRect.minY - visibleFrame.minY
        let belowRoom = visibleFrame.maxY - targetRect.maxY
        let useAbove = aboveRoom >= belowArrowTotal || aboveRoom >= belowRoom
        arrowDirection = useAbove ? .bottom : .top

        let arrowSize = useAbove ? bottomArrowSize : topArrowSize
        var bodyX = target.x - bodyWidth / 2
        bodyX = min(max(bodyX, visibleFrame.minX + sourceSideMargin),
                    visibleFrame.maxX - sourceSideMargin - bodyWidth)
        let bodyY: CGFloat
        if useAbove {
            let proposed = targetRect.minY - bottomArrowSize.height - bodyHeight + 1
            let maximum = max(visibleFrame.minY,
                              visibleFrame.maxY - bodyHeight - bottomArrowSize.height + 1)
            bodyY = min(max(proposed, visibleFrame.minY), maximum)
        } else {
            let proposed = targetRect.maxY + topArrowSize.height - 1
            let minimum = min(visibleFrame.maxY - bodyHeight,
                              visibleFrame.minY + topArrowSize.height - 1)
            bodyY = min(max(proposed, minimum), visibleFrame.maxY - bodyHeight)
        }

        let arrowCenterX = min(
            max(target.x, bodyX + 12),
            bodyX + bodyWidth - 12
        )
        targetPoint = CGPoint(x: target.x, y: useAbove ? targetRect.minY : targetRect.maxY)

        let unionMinX = min(bodyX, arrowCenterX - arrowSize.width / 2)
        let unionMaxX = max(bodyX + bodyWidth, arrowCenterX + arrowSize.width / 2)
        let unionMinY = useAbove ? bodyY : bodyY - topArrowSize.height + 1
        let unionMaxY = useAbove ? bodyY + bodyHeight + bottomArrowSize.height - 1 : bodyY + bodyHeight
        frame = CGRect(x: unionMinX, y: unionMinY,
                       width: unionMaxX - unionMinX, height: unionMaxY - unionMinY).integral

        bodyFrame = CGRect(x: bodyX - frame.minX, y: bodyY - frame.minY,
                           width: bodyWidth, height: bodyHeight).integral
        bodyView.frame = bodyFrame

        let arrowY: CGFloat = useAbove
            ? bodyFrame.maxY - 3.5
            : bodyFrame.minY - topArrowSize.height + 3.5
        arrow.frame = CGRect(
            x: arrowCenterX - frame.minX - arrowSize.width / 2,
            y: arrowY,
            width: arrowSize.width,
            height: arrowSize.height
        ).integral
        arrow.image = UIImage(named: useAbove ? "UICalloutBarArrowBottom" : "UICalloutBarArrowTop")
        arrowHighlight.frame = arrow.frame
        arrowHighlight.image = UIImage(named: useAbove ? "UICalloutBarArrowBottomHi" : "UICalloutBarArrowTopHi")

        var x: CGFloat = 0
        for (index, button) in buttons.enumerated() {
            let width = index == buttons.count - 1
                ? max(1, bodyWidth - x)
                : max(1, naturalWidths[index] * compression)
            button.frame = CGRect(x: x, y: 0, width: width, height: bodyHeight).integral
            if index > 0, index - 1 < separators.count {
                let cut = separators[index - 1]
                let cutWidth = cut.image?.size.width ?? 2
                cut.frame = CGRect(x: x - cutWidth / 2, y: 0,
                                   width: cutWidth, height: bodyHeight)
            }
            x += width
        }

        layoutSourceShadow(bodyFrame: bodyFrame)
    }

    private func layoutSourceShadow(bodyFrame: CGRect) {
        shadowView.subviews.forEach { $0.removeFromSuperview() }
        shadowView.frame = CGRect(x: bodyFrame.minX, y: bodyFrame.maxY - 1,
                                  width: bodyFrame.width, height: 17)
        let left = UIImageView(image: UIImage(named: "UICalloutBarShadowLeft"))
        let middle = UIImageView(image: UIImage(named: "UICalloutBarShadowMiddle"))
        let right = UIImageView(image: UIImage(named: "UICalloutBarShadowRight"))
        let leftW = left.image?.size.width ?? 11
        let rightW = right.image?.size.width ?? 11
        left.frame = CGRect(x: 0, y: 0, width: leftW, height: 17)
        right.frame = CGRect(x: max(0, bodyFrame.width - rightW), y: 0, width: rightW, height: 17)
        middle.frame = CGRect(x: leftW, y: 0,
                              width: max(0, bodyFrame.width - leftW - rightW), height: 17)
        middle.contentMode = .scaleToFill
        [left, middle, right].forEach { shadowView.addSubview($0) }

        sendSubviewToBack(shadowView)
        insertSubview(arrow, aboveSubview: shadowView)
        insertSubview(arrowHighlight, aboveSubview: arrow)
        bringSubviewToFront(bodyView)
    }

    func appear(animated: Bool = true) {
        if !animated {
            alpha = 1
            return
        }
        alpha = 0
        UIView.animate(withDuration: 0.20, delay: 0,
                       options: [.beginFromCurrentState, .curveEaseInOut, .allowUserInteraction]) {
            self.alpha = 1
        }
    }

    func fade(animated: Bool = true, completion: (() -> Void)? = nil) {
        let finish = {
            self.removeFromSuperview()
            completion?()
        }
        guard animated else { finish(); return }
        UIView.animate(withDuration: 0.20, delay: 0,
                       options: [.beginFromCurrentState, .curveEaseInOut, .allowUserInteraction],
                       animations: { self.alpha = 0 },
                       completion: { _ in finish() })
    }

    @objc private func buttonTouchDown(_ sender: OldOSCalloutBarButton) {
        let arrowMidX = arrow.frame.midX
        let buttonRect = bodyView.convert(sender.frame, to: self)
        arrowHighlight.isHidden = !buttonRect.contains(CGPoint(x: arrowMidX, y: bodyFrame.midY))
        arrow.isHidden = !arrowHighlight.isHidden
    }

    @objc private func buttonTouchUp(_ sender: OldOSCalloutBarButton) {
        arrowHighlight.isHidden = true
        arrow.isHidden = false
    }
}

@MainActor
private final class OldOSTextEffectsClipHostView: UIView {
    private var localLCDClip: CGRect = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = true
        clipsToBounds = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func updateLCDClip(_ lcdFrame: CGRect, in window: UIWindow) {
        frame = window.bounds
        let local = convert(lcdFrame.intersection(window.bounds), from: window)
        localLCDClip = local

        let mask = CAShapeLayer()
        mask.frame = bounds
        if !local.isNull, !local.isInfinite, local.width > 0, local.height > 0 {
            mask.path = UIBezierPath(rect: local).cgPath
        } else {
            mask.path = UIBezierPath(rect: .zero).cgPath
        }
        mask.fillColor = UIColor.black.cgColor
        layer.mask = mask
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, alpha > 0.01, isUserInteractionEnabled,
              localLCDClip.contains(point) else { return nil }
        for child in subviews.reversed() where !child.isHidden && child.alpha > 0.01 && child.isUserInteractionEnabled {
            let childPoint = child.convert(point, from: self)
            if let hit = child.hitTest(childPoint, with: event) { return hit }
        }
        return nil
    }
}

@MainActor
private final class OldOSTextInteractionCoordinator: NSObject, UIGestureRecognizerDelegate {
    weak var inputView: UIView?
    weak var keyboard: OldOSKeyboardController?

    private let loupeGesture = OldOSVariableDelayLoupeGesture()
    private let singleTapGesture = UITapGestureRecognizer()
    private let doubleTapGesture = UITapGestureRecognizer()
    private let tripleTapGesture = UITapGestureRecognizer()

    private weak var callout: OldOSCalloutBarView?
    private weak var caretMagnifier: OldOSMagnifierView?
    private weak var rangedMagnifier: OldOSMagnifierView?
    private weak var startHandle: OldOSSelectionHandleView?
    private weak var endHandle: OldOSSelectionHandleView?
    private weak var selectionHighlightView: OldOSSelectionHighlightView?
    private weak var textEffectsHost: OldOSTextEffectsClipHostView?

    private enum SelectionPresentationMode {
        case selection
        case replacement
    }

    private var selectionPresentationMode: SelectionPresentationMode = .selection
    private var activeHandle: OldOSSelectionHandleView.Kind?
    private weak var activeHandleGesture: UIPanGestureRecognizer?
    private var dragFixedPosition: UITextPosition?
    private var active = false
    private var observers: [NSObjectProtocol] = []
    private var displayLink: CADisplayLink?
    private var previousSelectionSignature: String?
    private var wasFirstResponderAtTap = false
    private var isSnapshotting = false

    private var rangeTouchOffset: CGPoint = .zero

    private var rangedTouchOffsetFromMagnificationPoint: CGFloat = 0

    private let sourceSelectionBlue = UIColor(red: 0, green: 0.33, blue: 0.65, alpha: 0.20)
    private let sourceReplacementRed = UIColor(red: 1, green: 0, blue: 0, alpha: 0.15)
    private var originalInputTintColor: UIColor?
    private var inputTintIsSuppressed = false

    private var suppressedSystemDoubleTaps: [ObjectIdentifier: (UIGestureRecognizer, Bool)] = [:]

    private var suppressedSystemViews: [ObjectIdentifier: UIView] = [:]
    private var suppressedSystemLayers: [ObjectIdentifier: CALayer] = [:]

    private let checker = UITextChecker()

    init(inputView: UIView, keyboard: OldOSKeyboardController) {
        self.inputView = inputView
        self.keyboard = keyboard
        super.init()
        configureGestures()
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
        displayLink?.invalidate()
    }

    func activate() {
        guard !active, let inputView else { return }
        active = true
        installGesturesIfNeeded(on: inputView)
        suppressSystemDoubleTapRecognizers(in: inputView)
        installObservers()
        startDisplayLink()
        suppressModernChrome()
        refreshSelectionChrome()
    }

    func deactivate() {
        guard active else { return }
        active = false
        hideCallout(animated: false)
        hideMagnifiers(animated: false)
        removeSelectionHandles()
        removeSelectionHighlight()
        restoreInputTint()
        restoreSuppressedSystemDoubleTaps()
        restoreSuppressedSystemChrome()
        textEffectsHost?.removeFromSuperview()
        textEffectsHost = nil
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
        displayLink?.invalidate()
        displayLink = nil
        previousSelectionSignature = nil
    }

    private func configureGestures() {
        loupeGesture.addTarget(self, action: #selector(loupeGestureChanged(_:)))
        loupeGesture.delegate = self
        loupeGesture.allowableMovement = 8
        loupeGesture.cancelsTouchesInView = true
        loupeGesture.textInputView = inputView

        singleTapGesture.addTarget(self, action: #selector(singleTap(_:)))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.cancelsTouchesInView = false
        singleTapGesture.delaysTouchesEnded = false
        singleTapGesture.delegate = self

        doubleTapGesture.addTarget(self, action: #selector(doubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.cancelsTouchesInView = true
        doubleTapGesture.delegate = self

        tripleTapGesture.addTarget(self, action: #selector(tripleTap(_:)))
        tripleTapGesture.numberOfTapsRequired = 3
        tripleTapGesture.cancelsTouchesInView = true
        tripleTapGesture.delegate = self

        singleTapGesture.require(toFail: doubleTapGesture)
        doubleTapGesture.require(toFail: tripleTapGesture)
    }

    private func installGesturesIfNeeded(on view: UIView) {
        let originals = view.gestureRecognizers ?? []
        [loupeGesture, singleTapGesture, doubleTapGesture, tripleTapGesture].forEach {
            if $0.view !== view { view.addGestureRecognizer($0) }
        }

        for recognizer in originals {
            guard recognizer !== loupeGesture,
                  recognizer !== singleTapGesture,
                  recognizer !== doubleTapGesture,
                  recognizer !== tripleTapGesture else { continue }
            if let longPress = recognizer as? UILongPressGestureRecognizer {
                longPress.require(toFail: loupeGesture)
            }
        }
        suppressSystemDoubleTapRecognizers(in: view)
    }

    private func installObservers() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: UIMenuController.willShowMenuNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.hideSystemMenuImmediately() }
        })

    }

    private func startDisplayLink() {
        displayLink?.invalidate()
        let link = CADisplayLink(target: self, selector: #selector(displayLinkTick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func displayLinkTick() {
        guard active else { return }
        if let inputView, let window = inputView.window, textEffectsHost != nil {
            _ = textEffectsHostView(in: window)
        }
        suppressModernChrome()
        if let inputView { suppressSystemDoubleTapRecognizers(in: inputView) }
        let signature = selectionSignature()
        if signature != previousSelectionSignature {
            previousSelectionSignature = signature
            refreshSelectionChrome()
        } else if startHandle != nil || endHandle != nil || callout != nil || selectionHighlightView != nil {

            updateHandleFrames()
            if let inputView,
               let input = inputView as? UITextInput,
               let range = input.selectedTextRange, !range.isEmpty {
                updateSelectionHighlight(for: range)
            }
            if let callout, let target = currentMenuTargetRect() {
                callout.place(targetRect: target, visibleFrame: textEffectsVisibleFrame())
                applyTextEffectsLCDClip(to: callout)
            }
        }

        if caretMagnifier != nil,
           loupeGesture.state == .began || loupeGesture.state == .changed,
           let inputView {
            updateCaretMagnifier(magnificationPoint: loupeGesture.location(in: inputView))
        } else if rangedMagnifier != nil, activeHandle != nil {
            updateRangedMagnifier()
        }
    }

    private func selectionSignature() -> String? {
        guard let inputView,
              let input = inputView as? UITextInput,
              let range = input.selectedTextRange else { return nil }
        let a = input.offset(from: input.beginningOfDocument, to: range.start)
        let b = input.offset(from: input.beginningOfDocument, to: range.end)
        return "\(a):\(b)"
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard active, let inputView, inputView.isFirstResponder,
              let input = inputView as? UITextInput else { return false }

        if gestureRecognizer === loupeGesture {

            if let range = input.selectedTextRange, !range.isEmpty {
                let p = gestureRecognizer.location(in: inputView)
                if let endpoints = selectionEndpointRects(in: inputView) {
                    let ds = hypot(p.x - endpoints.start.midX, p.y - endpoints.start.midY)
                    let de = hypot(p.x - endpoints.end.midX, p.y - endpoints.end.midY)
                    if min(ds, de) <= 20 { return false }
                }
            }
            return true
        }
        if gestureRecognizer === singleTapGesture {
            wasFirstResponderAtTap = inputView.isFirstResponder
            return true
        }
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if gestureRecognizer === singleTapGesture || otherGestureRecognizer === singleTapGesture {
            return true
        }
        return false
    }

    @objc private func singleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, let inputView,
              let input = inputView as? UITextInput else { return }
        let p = gesture.location(in: inputView)
        enterSelectionPresentationMode()
        hideCallout(animated: true)

        DispatchQueue.main.async { [weak self, weak inputView] in
            guard let self, let inputView,
                  self.active,
                  let input = inputView as? UITextInput,
                  let range = input.selectedTextRange else { return }
            let rect = range.isEmpty
                ? input.caretRect(for: range.start)
                : input.firstRect(for: range)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            if self.wasFirstResponderAtTap,
               hypot(p.x - center.x, p.y - center.y) < 25 {
                self.showCommands()
            }
            self.refreshSelectionChrome()
        }
    }

    @objc private func doubleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, let inputView,
              let input = inputView as? UITextInput else { return }
        keyboard?.oldOSPrepareForTextInteraction()
        enterSelectionPresentationMode()
        hideCallout(animated: false)
        let point = gesture.location(in: inputView)
        guard let position = input.closestPosition(to: point),
              let range = wordRange(around: position, input: input) else { return }
        input.selectedTextRange = range
        refreshSelectionChrome()
        showCommands()
    }

    @objc private func tripleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, let inputView,
              let input = inputView as? UITextInput else { return }
        keyboard?.oldOSPrepareForTextInteraction()
        enterSelectionPresentationMode()
        hideCallout(animated: false)
        let point = gesture.location(in: inputView)
        guard let position = input.closestPosition(to: point) else { return }
        let tokenizer = input.tokenizer
        let range = tokenizer.rangeEnclosingPosition(
            position,
            with: .paragraph,
            inDirection: UITextDirection.storage(.forward)
        ) ?? tokenizer.rangeEnclosingPosition(
            position,
            with: .line,
            inDirection: UITextDirection.storage(.forward)
        )
        guard let range else { return }
        input.selectedTextRange = range
        refreshSelectionChrome()
        showCommands()
    }

    @objc private func loupeGestureChanged(_ gesture: UILongPressGestureRecognizer) {
        guard let inputView, let input = inputView as? UITextInput else { return }

        let magnificationPoint = gesture.location(in: inputView)
        switch gesture.state {
        case .began:
            keyboard?.oldOSPrepareForTextInteraction()
            enterSelectionPresentationMode()
            hideCallout(animated: false)
            removeSelectionHandles()
            if let position = input.closestPosition(to: magnificationPoint),
               let collapsed = input.textRange(from: position, to: position) {
                input.selectedTextRange = collapsed
            }
            showCaretMagnifier(
                magnificationPoint: magnificationPoint,
                animated: true
            )

        case .changed:
            if let position = input.closestPosition(to: magnificationPoint),
               let collapsed = input.textRange(from: position, to: position) {
                input.selectedTextRange = collapsed
            }
            autoscrollIfNeeded(point: magnificationPoint)
            updateCaretMagnifier(magnificationPoint: magnificationPoint, refreshSnapshot: false)

        case .ended, .cancelled, .failed:

            if let position = input.closestPosition(to: magnificationPoint),
               let collapsed = input.textRange(from: position, to: position) {
                input.selectedTextRange = collapsed
            }
            updateCaretMagnifier(magnificationPoint: magnificationPoint)
            hideCaretMagnifier(
                animated: gesture.state == .ended,
                animationPoint: magnificationPoint
            ) { [weak self] in
                guard let self, self.active else { return }
                self.refreshSelectionChrome()
                self.showCommands()
            }
        default:
            break
        }
    }

    private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let inputView,
              let input = inputView as? UITextInput else { return }
        let touchPoint = gesture.location(in: inputView)

        if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            let finalAnimationPoint = activeSelectionEdgePoint(in: inputView) ?? touchPoint
            activeHandle = nil
            activeHandleGesture = nil
            dragFixedPosition = nil
            rangeTouchOffset = .zero
            rangedTouchOffsetFromMagnificationPoint = 0
            hideRangedMagnifier(
                animated: gesture.state == .ended,
                animationPoint: finalAnimationPoint
            ) { [weak self] in
                guard let self, self.active else { return }
                self.refreshSelectionChrome()
                self.showCommands()
            }
            return
        }

        switch gesture.state {
        case .began:
            guard let existing = input.selectedTextRange, !existing.isEmpty,
                  let handle = gesture.view as? OldOSSelectionHandleView else { return }
            enterSelectionPresentationMode()
            activeHandle = handle.kind
            activeHandleGesture = gesture

            dragFixedPosition = handle.kind == .start ? existing.end : existing.start
            keyboard?.oldOSPrepareForTextInteraction()
            hideCallout(animated: false)
            refreshSelectionChrome()

            if let magnifierPoint = activeSelectionEdgePoint(in: inputView) {
                let raw = CGPoint(
                    x: magnifierPoint.x - touchPoint.x,
                    y: magnifierPoint.y - touchPoint.y
                )
                rangeTouchOffset = CGPoint(
                    x: raw.x,
                    y: min(50, max(-50, raw.y))
                )
                rangedTouchOffsetFromMagnificationPoint = max(0, round(rangeTouchOffset.y))
            } else {
                rangeTouchOffset = .zero
                rangedTouchOffsetFromMagnificationPoint = 0
            }
            showRangedMagnifier(animated: true)

        case .changed:
            guard let activeHandle,
                  let fixed = dragFixedPosition else { return }

            let adjustedPoint = CGPoint(
                x: touchPoint.x + rangeTouchOffset.x,
                y: touchPoint.y + rangeTouchOffset.y
            )
            guard let position = input.closestPosition(to: adjustedPoint) else { return }
            let compare = input.compare(position, to: fixed)
            let newStart: UITextPosition
            let newEnd: UITextPosition
            if activeHandle == .start {
                if compare == .orderedAscending {
                    newStart = position; newEnd = fixed
                } else {
                    newStart = fixed; newEnd = position
                    self.activeHandle = .end
                }
            } else {
                if compare == .orderedDescending {
                    newStart = fixed; newEnd = position
                } else {
                    newStart = position; newEnd = fixed
                    self.activeHandle = .start
                }
            }
            if let newRange = input.textRange(from: newStart, to: newEnd) {
                input.selectedTextRange = newRange
            }
            autoscrollIfNeeded(point: adjustedPoint)
            refreshSelectionChrome()
            updateRangedMagnifier(refreshSnapshot: false)

        default:
            break
        }
    }

    private func wordRange(around position: UITextPosition, input: UITextInput) -> UITextRange? {
        let tokenizer = input.tokenizer
        return tokenizer.rangeEnclosingPosition(
            position,
            with: .word,
            inDirection: UITextDirection.storage(.forward)
        ) ?? tokenizer.rangeEnclosingPosition(
            position,
            with: .word,
            inDirection: UITextDirection.storage(.backward)
        )
    }

    private func currentSelectedText() -> String? {
        guard let inputView,
              let input = inputView as? UITextInput,
              let range = input.selectedTextRange,
              !range.isEmpty else { return nil }
        return input.text(in: range)
    }

    private func canPerform(_ selectorName: String) -> Bool {
        guard let inputView else { return false }
        return inputView.canPerformAction(Selector((selectorName)), withSender: self)
    }

    private func perform(_ selectorName: String, reshowSelectionCommands: Bool = false) {
        guard let inputView else { return }
        enterSelectionPresentationMode()
        hideCallout(animated: true)
        UIApplication.shared.sendAction(Selector((selectorName)), to: inputView, from: self, for: nil)
        hideSystemMenuImmediately()

        refreshSelectionChrome()
        suppressModernChrome()
        DispatchQueue.main.async { [weak self] in
            guard let self, self.active else { return }
            self.refreshSelectionChrome()
            if reshowSelectionCommands { self.showCommands() }
        }
    }

    private func canPromptForReplace() -> Bool {
        guard let inputView,
              let input = inputView as? UITextInput,
              let selection = input.selectedTextRange,
              !selection.isEmpty,
              let selectedText = input.text(in: selection),
              !selectedText.isEmpty,
              selectedText.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else { return false }

        if let field = inputView as? UITextField {
            guard field.isEnabled, !field.isSecureTextEntry else { return false }
            return true
        }
        if let view = inputView as? UITextView {
            guard view.isEditable else { return false }
            return true
        }

        return canPerform("cut:")
    }

    private func sourceCommandItems(for selected: UITextRange) -> [OldOSCalloutBarView.Item] {
        var items: [OldOSCalloutBarView.Item] = []

        if !selected.isEmpty {
            if canPerform("cut:") {
                items.append(.init(title: "Cut", replacementText: nil) { [weak self] in
                    self?.perform("cut:")
                })
            }
            if canPerform("copy:") {
                items.append(.init(title: "Copy", replacementText: nil) { [weak self] in
                    self?.perform("copy:")
                })
            }
        } else {
            if canPerform("select:") {
                items.append(.init(title: "Select", replacementText: nil) { [weak self] in
                    self?.perform("select:", reshowSelectionCommands: true)
                })
            }
            if canPerform("selectAll:") {
                items.append(.init(title: "Select All", replacementText: nil) { [weak self] in
                    self?.perform("selectAll:", reshowSelectionCommands: true)
                })
            }
        }

        if canPerform("paste:") {
            items.append(.init(title: "Paste", replacementText: nil) { [weak self] in
                self?.perform("paste:")
            })
        }

        if canPromptForReplace() {
            items.append(.init(title: "Replace...", replacementText: nil) { [weak self] in
                self?.showReplacementCommands()
            })
        }
        return items
    }

    private func showCommands() {
        guard active,
              let inputView,
              inputView.isFirstResponder,
              let input = inputView as? UITextInput,
              let selected = input.selectedTextRange else { return }
        keyboard?.oldOSPrepareForTextInteraction()
        enterSelectionPresentationMode()
        hideSystemMenuImmediately()
        refreshSelectionChrome()

        let items = sourceCommandItems(for: selected)
        guard !items.isEmpty else {
            hideCallout(animated: true)
            return
        }
        showCallout(items: items)
    }

    private func showReplacementCommands() {
        let candidates = replacementCandidates()
        guard !candidates.isEmpty else {

            let noReplacements = OldOSCalloutBarView.Item(
                title: "No Replacements Found",
                replacementText: nil,
                isInteractive: false,
                action: {}
            )
            showCallout(items: [noReplacements])
            selectionPresentationMode = .replacement
            refreshSelectionChrome()
            return
        }
        let items = candidates.map { candidate in
            OldOSCalloutBarView.Item(
                title: candidate,
                replacementText: candidate,
                action: { [weak self] in self?.applyReplacement(candidate) }
            )
        }

        showCallout(items: items)
        selectionPresentationMode = .replacement
        refreshSelectionChrome()
    }

    private func showCallout(items: [OldOSCalloutBarView.Item]) {
        guard let inputView, let window = inputView.window,
              let target = currentMenuTargetRect() else { return }
        hideCallout(animated: false)

        let visible = textEffectsVisibleFrame()
        let maximumBodyWidth = max(1, visible.width - 20)
        var fitted = items

        while fitted.count > 1 {
            let width = fitted.reduce(CGFloat.zero) { partial, item in
                partial + OldOSCalloutBarView.naturalWidth(for: item.title)
            }
            if width <= maximumBodyWidth { break }
            fitted.removeLast()
        }
        guard !fitted.isEmpty else { return }

        let bar = OldOSCalloutBarView(frame: .zero)
        bar.configure(items: fitted)
        bar.place(targetRect: target, visibleFrame: visible)
        let host = textEffectsHostView(in: window)
        host.addSubview(bar)
        applyTextEffectsLCDClip(to: bar)
        host.bringSubviewToFront(bar)
        callout = bar
        bar.appear(animated: true)
    }

    private func hideCallout(animated: Bool) {
        guard let callout else { return }
        self.callout = nil
        callout.fade(animated: animated)
    }

    private func applyReplacement(_ text: String) {
        guard let inputView,
              let input = inputView as? UITextInput,
              let range = input.selectedTextRange,
              !range.isEmpty else { return }
        enterSelectionPresentationMode()
        hideCallout(animated: true)
        input.selectedTextRange = range
        if let keyInput = inputView as? UIKeyInput {
            keyInput.insertText(text)
        } else {
            input.replace(range, withText: text)
        }
        DispatchQueue.main.async { [weak self] in self?.refreshSelectionChrome() }
    }

    private func replacementCandidates() -> [String] {
        guard let inputView,
              let input = inputView as? UITextInput,
              let selection = input.selectedTextRange,
              !selection.isEmpty,
              let selectedText = input.text(in: selection),
              !selectedText.isEmpty,
              let fullRange = input.textRange(from: input.beginningOfDocument, to: input.endOfDocument),
              let fullText = input.text(in: fullRange) else { return [] }

        let start = input.offset(from: input.beginningOfDocument, to: selection.start)
        let length = input.offset(from: selection.start, to: selection.end)
        guard start >= 0, length > 0 else { return [] }
        let nsRange = NSRange(location: start, length: length)

        let primary = inputView.textInputMode?.primaryLanguage ?? "en_US"
        let language = primary.replacingOccurrences(of: "-", with: "_")
        let guesses = checker.guesses(forWordRange: nsRange, in: fullText, language: language)
            ?? checker.guesses(forWordRange: nsRange, in: fullText, language: "en_US")
            ?? []

        var seen = Set<String>()
        var output: [String] = []
        for guess in guesses {
            guard guess.caseInsensitiveCompare(selectedText) != .orderedSame else { continue }
            let key = guess.lowercased()
            guard seen.insert(key).inserted else { continue }
            output.append(guess)

            if output.count >= 6 { break }
        }
        return output
    }

    private func enterSelectionPresentationMode() {
        guard selectionPresentationMode != .selection else { return }
        selectionPresentationMode = .selection
        refreshSelectionChrome()
    }

    private func refreshSelectionChrome() {
        guard active,
              let inputView,
              let input = inputView as? UITextInput,
              let range = input.selectedTextRange else {
            removeSelectionHandles()
            removeSelectionHighlight()
            restoreInputTint()
            return
        }

        if range.isEmpty {
            removeSelectionHighlight()
            restoreInputTint()

            if activeHandleGesture != nil || activeHandle != nil {
                updateHandleFrames()
            } else {
                removeSelectionHandles()
            }
            return
        }

        suppressModernChrome()
        suppressInputTintForClassicSelection()
        updateSelectionHighlight(for: range)

        if selectionPresentationMode == .replacement || caretMagnifier != nil {

            removeSelectionHandles()
        } else {
            showSelectionHandles()
        }
    }

    private func suppressInputTintForClassicSelection() {
        guard let inputView else { return }
        if !inputTintIsSuppressed {
            originalInputTintColor = inputView.tintColor
            inputTintIsSuppressed = true
        }
        inputView.tintColor = .clear
    }

    private func restoreInputTint() {
        guard inputTintIsSuppressed, let inputView else { return }
        if let originalInputTintColor {
            inputView.tintColor = originalInputTintColor
        }
        originalInputTintColor = nil
        inputTintIsSuppressed = false
    }

    private func updateSelectionHighlight(for range: UITextRange) {
        guard let inputView, let window = inputView.window,
              let input = inputView as? UITextInput else { return }

        let sourceRects = input.selectionRects(for: range)
            .map { inputView.convert($0.rect, to: window) }
            .filter { !$0.isNull && !$0.isInfinite && $0.width > 0 && $0.height > 0 }

        guard !sourceRects.isEmpty else {
            removeSelectionHighlight()
            return
        }

        let highlight = selectionHighlightView ?? {
            let view = OldOSSelectionHighlightView(frame: window.bounds)
            textEffectsHostView(in: window).addSubview(view)
            selectionHighlightView = view
            return view
        }()

        let editorFrame = inputView.convert(inputView.bounds, to: window)
        var visible = textEffectsVisibleFrame().intersection(editorFrame)
        if visible.isNull || visible.isInfinite { visible = textEffectsVisibleFrame() }
        let color = selectionPresentationMode == .replacement
            ? sourceReplacementRed
            : sourceSelectionBlue
        highlight.update(windowRects: sourceRects, color: color, visibleFrame: visible, in: window)

        if let startHandle { startHandle.superview?.bringSubviewToFront(startHandle) }
        if let endHandle { endHandle.superview?.bringSubviewToFront(endHandle) }
        if let callout { callout.superview?.bringSubviewToFront(callout) }
        if let caretMagnifier { caretMagnifier.superview?.bringSubviewToFront(caretMagnifier) }
        if let rangedMagnifier { rangedMagnifier.superview?.bringSubviewToFront(rangedMagnifier) }
    }

    private func removeSelectionHighlight() {
        selectionHighlightView?.removeFromSuperview()
        selectionHighlightView = nil
    }

    private func showSelectionHandles() {
        guard let inputView, let window = inputView.window else { return }
        let start = startHandle ?? {
            let v = OldOSSelectionHandleView(kind: .start)
            v.onPan = { [weak self] gesture in self?.handlePan(gesture) }
            textEffectsHostView(in: window).addSubview(v)
            startHandle = v
            return v
        }()
        let end = endHandle ?? {
            let v = OldOSSelectionHandleView(kind: .end)
            v.onPan = { [weak self] gesture in self?.handlePan(gesture) }
            textEffectsHostView(in: window).addSubview(v)
            endHandle = v
            return v
        }()
        updateHandleFrames()
        start.superview?.bringSubviewToFront(start)
        end.superview?.bringSubviewToFront(end)
        if let callout { callout.superview?.bringSubviewToFront(callout) }
    }

    private func updateHandleFrames() {
        guard let inputView, let window = inputView.window,
              let endpoints = selectionEndpointRects(in: window) else { return }
        startHandle?.place(at: endpoints.start, in: window)
        endHandle?.place(at: endpoints.end, in: window)

        let editorFrame = inputView.convert(inputView.bounds, to: window)
        var visible = textEffectsVisibleFrame().intersection(editorFrame)
        if visible.isNull || visible.isInfinite { visible = textEffectsVisibleFrame() }
        let tolerance = visible.insetBy(dx: -10, dy: -10)
        startHandle?.isHidden = !tolerance.intersects(endpoints.start)
        endHandle?.isHidden = !tolerance.intersects(endpoints.end)
    }

    private func removeSelectionHandles() {
        startHandle?.removeFromSuperview()
        endHandle?.removeFromSuperview()
        startHandle = nil
        endHandle = nil
    }

    private func selectionEndpointRects(in view: UIView) -> (start: CGRect, end: CGRect)? {
        guard let inputView,
              let input = inputView as? UITextInput,
              let range = input.selectedTextRange else { return nil }
        let startLocal = input.caretRect(for: range.start)
        let endLocal = input.caretRect(for: range.end)
        return (
            inputView.convert(startLocal, to: view),
            inputView.convert(endLocal, to: view)
        )
    }

    private func currentMenuTargetRect() -> CGRect? {
        guard let inputView, let window = inputView.window,
              let input = inputView as? UITextInput,
              let range = input.selectedTextRange else { return nil }

        if range.isEmpty {
            let caret = input.caretRect(for: range.start)
            return inputView.convert(caret, to: window)
        }

        let rects = input.selectionRects(for: range)
            .map { inputView.convert($0.rect, to: window) }
            .filter { !$0.isNull && !$0.isInfinite && $0.width.isFinite && $0.height.isFinite }
        if let first = rects.first {
            return rects.dropFirst().reduce(first) { $0.union($1) }
        }
        let fallback = input.firstRect(for: range)
        return inputView.convert(fallback, to: window)
    }

    private func showCaretMagnifier(magnificationPoint localPoint: CGPoint, animated: Bool) {
        guard let inputView, let window = inputView.window else { return }
        hideMagnifiers(animated: false)
        let point = inputView.convert(localPoint, to: window)
        let magnifier = OldOSMagnifierView(kind: .caret)
        placeCaretMagnifier(magnifier, around: point)
        let host = textEffectsHostView(in: window)
        host.addSubview(magnifier)
        applyTextEffectsLCDClip(to: magnifier)
        caretMagnifier = magnifier
        updateMagnifierSnapshot(magnifier, magnificationPoint: point)
        host.bringSubviewToFront(magnifier)
        magnifier.appear(from: point, animated: animated)
    }

    private func updateCaretMagnifier(
        magnificationPoint localPoint: CGPoint,
        refreshSnapshot: Bool = true
    ) {
        guard let inputView, let window = inputView.window, let magnifier = caretMagnifier else { return }
        let point = inputView.convert(localPoint, to: window)
        placeCaretMagnifier(magnifier, around: point)
        if refreshSnapshot {
            updateMagnifierSnapshot(magnifier, magnificationPoint: point)
        }
    }

    private func placeCaretMagnifier(_ magnifier: OldOSMagnifierView, around point: CGPoint) {
        let visible = textEffectsVisibleFrame()
        let size = magnifier.bounds.size

        var center = CGPoint(x: point.x, y: point.y - 75)
        center.x = min(max(center.x, visible.minX + size.width / 2),
                       visible.maxX - size.width / 2)
        if center.y - size.height / 2 < visible.minY {
            center.y = max(visible.minY + size.height / 2, point.y + 32)
        }
        center.y = min(center.y, visible.maxY - size.height / 2)
        magnifier.center = center
        applyTextEffectsLCDClip(to: magnifier)
    }

    private func hideCaretMagnifier(animated: Bool, animationPoint: CGPoint, completion: @escaping () -> Void) {
        guard let inputView, let window = inputView.window, let magnifier = caretMagnifier else {
            completion(); return
        }
        caretMagnifier = nil
        let point = inputView.convert(animationPoint, to: window)
        magnifier.disappear(toward: point, animated: animated, completion: completion)
    }

    private func activeSelectionEdgePoint(in view: UIView) -> CGPoint? {
        guard let inputView,
              let input = inputView as? UITextInput,
              let range = input.selectedTextRange,
              let activeHandle else { return nil }
        let position = activeHandle == .start ? range.start : range.end
        let edge = input.caretRect(for: position)
        guard !edge.isNull, !edge.isInfinite,
              edge.minX.isFinite, edge.midY.isFinite else { return nil }
        return inputView.convert(CGPoint(x: edge.minX, y: edge.midY), to: view)
    }

    private func rangedSnappedPoint(from localMagnificationPoint: CGPoint) -> CGPoint {
        guard let inputView,
              let input = inputView as? UITextInput,
              let range = input.selectedTextRange else { return localMagnificationPoint }

        var result = localMagnificationPoint
        guard var position = input.closestPosition(to: localMagnificationPoint) else { return result }
        if input.compare(position, to: range.start) == .orderedAscending {
            position = range.start
        } else if input.compare(position, to: range.end) == .orderedDescending {
            position = range.end
        }
        let caret = input.caretRect(for: position)
        if !caret.isNull, !caret.isInfinite,
           caret.minY.isFinite, caret.height.isFinite {
            result.y = round(caret.minY + caret.height / 1.3)
        }
        return result
    }

    private func showRangedMagnifier(animated: Bool) {
        guard let inputView, let window = inputView.window,
              let localMagnificationPoint = activeSelectionEdgePoint(in: inputView) else { return }
        hideMagnifiers(animated: false)

        let magnificationPoint = inputView.convert(localMagnificationPoint, to: window)
        let localSnapped = rangedSnappedPoint(from: localMagnificationPoint)
        let snapped = inputView.convert(localSnapped, to: window)
        let magnifier = OldOSMagnifierView(kind: .ranged)
        placeRangedMagnifier(magnifier, magnificationPoint: magnificationPoint)
        let host = textEffectsHostView(in: window)
        host.addSubview(magnifier)
        applyTextEffectsLCDClip(to: magnifier)
        rangedMagnifier = magnifier
        updateMagnifierSnapshot(magnifier, magnificationPoint: snapped)
        host.bringSubviewToFront(magnifier)
        magnifier.appear(from: magnificationPoint, animated: animated)
    }

    private func updateRangedMagnifier(refreshSnapshot: Bool = true) {
        guard let inputView, let window = inputView.window, let magnifier = rangedMagnifier,
              let localMagnificationPoint = activeSelectionEdgePoint(in: inputView) else { return }
        let magnificationPoint = inputView.convert(localMagnificationPoint, to: window)
        let localSnapped = rangedSnappedPoint(from: localMagnificationPoint)
        let snapped = inputView.convert(localSnapped, to: window)
        placeRangedMagnifier(magnifier, magnificationPoint: magnificationPoint)
        if refreshSnapshot {
            updateMagnifierSnapshot(magnifier, magnificationPoint: snapped)
        }
    }

    private func placeRangedMagnifier(
        _ magnifier: OldOSMagnifierView,
        magnificationPoint point: CGPoint
    ) {
        let visible = textEffectsVisibleFrame()
        let halfHeight = magnifier.bounds.height * 0.5
        var magnifierOffsetFromTouch: CGFloat = 48
        var offset = rangedTouchOffsetFromMagnificationPoint + magnifierOffsetFromTouch
        var centerY = point.y - offset

        if centerY - halfHeight < visible.minY {
            let overflow = visible.minY - (centerY - halfHeight)
            magnifierOffsetFromTouch -= overflow
            offset = rangedTouchOffsetFromMagnificationPoint + magnifierOffsetFromTouch
            centerY = point.y - offset
        }

        magnifier.center = CGPoint(
            x: round(point.x) + 0.5,
            y: round(centerY) + 0.5
        )
        applyTextEffectsLCDClip(to: magnifier)
    }

    private func hideRangedMagnifier(animated: Bool, animationPoint localAnimationPoint: CGPoint, completion: @escaping () -> Void) {
        guard let inputView, let window = inputView.window, let magnifier = rangedMagnifier else {
            completion(); return
        }
        rangedMagnifier = nil
        let point = inputView.convert(localAnimationPoint, to: window)
        magnifier.disappear(toward: point, animated: animated, completion: completion)
    }

    private func hideMagnifiers(animated: Bool) {
        if let caret = caretMagnifier {
            caretMagnifier = nil
            if animated { caret.fadeOutAndRemove(duration: 0.075) }
            else { caret.removeFromSuperview() }
        }
        if let ranged = rangedMagnifier {
            rangedMagnifier = nil
            if animated { ranged.fadeOutAndRemove(duration: 0.075) }
            else { ranged.removeFromSuperview() }
        }
    }

    private func updateMagnifierSnapshot(_ magnifier: OldOSMagnifierView, magnificationPoint: CGPoint) {
        guard !isSnapshotting, let inputView, let window = inputView.window else { return }

        suppressModernChrome()
        isSnapshotting = true

        let oldMagnifierHidden = magnifier.isHidden
        let oldCalloutHidden = callout?.isHidden
        let oldStartHidden = startHandle?.isHidden
        let oldEndHidden = endHandle?.isHidden

        magnifier.isHidden = true
        callout?.isHidden = true
        if magnifier.isRangedMagnifier {

            startHandle?.setDotHiddenForMagnifierCapture(true)
            endHandle?.setDotHiddenForMagnifierCapture(true)
        } else {
            startHandle?.isHidden = true
            endHandle?.isHidden = true
        }

        defer {
            magnifier.isHidden = oldMagnifierHidden
            if let oldCalloutHidden { callout?.isHidden = oldCalloutHidden }
            if magnifier.isRangedMagnifier {
                startHandle?.setDotHiddenForMagnifierCapture(false)
                endHandle?.setDotHiddenForMagnifierCapture(false)
            } else {
                if let oldStartHidden { startHandle?.isHidden = oldStartHidden }
                if let oldEndHidden { endHandle?.isHidden = oldEndHidden }
            }
            isSnapshotting = false
        }

        let lensSize = magnifier.bounds.size
        guard lensSize.width > 0, lensSize.height > 0 else { return }

        let apertureCenter = magnifier.contentFocusPointInBounds
        var sourcePoint = CGPoint(
            x: magnificationPoint.x - window.bounds.minX,
            y: magnificationPoint.y - window.bounds.minY
        )
        if magnifier.isRangedMagnifier {

            sourcePoint.y -= 8.0
        }

        let scale = magnifier.sourceMagnification
        guard scale > 0, scale.isFinite,
              sourcePoint.x.isFinite, sourcePoint.y.isFinite else { return }

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false

        if !magnifier.isRangedMagnifier {
            let lensImage = UIGraphicsImageRenderer(size: lensSize, format: format).image { rendererContext in
                let ctx = rendererContext.cgContext
                ctx.translateBy(x: apertureCenter.x, y: apertureCenter.y)
                ctx.scaleBy(x: scale, y: scale)
                ctx.translateBy(x: -sourcePoint.x, y: -sourcePoint.y)
                ctx.clip(to: textEffectsLCDFrame())
                window.layer.render(in: ctx)
            }
            magnifier.setSnapshot(lensImage)
            return
        }

        let lcd = textEffectsLCDFrame().intersection(window.bounds)
        guard !lcd.isNull, !lcd.isEmpty, lcd.width > 0, lcd.height > 0 else { return }

        var captured = false
        let lcdImage = UIGraphicsImageRenderer(size: lcd.size, format: format).image { _ in

            let translatedWindowRect = CGRect(
                x: window.bounds.minX - lcd.minX,
                y: window.bounds.minY - lcd.minY,
                width: window.bounds.width,
                height: window.bounds.height
            )
            captured = window.drawHierarchy(
                in: translatedWindowRect,
                afterScreenUpdates: false
            )
        }

        guard captured else { return }

        let sourcePointInLCD = CGPoint(
            x: sourcePoint.x - lcd.minX,
            y: sourcePoint.y - lcd.minY
        )

        let lensImage = UIGraphicsImageRenderer(size: lensSize, format: format).image { rendererContext in
            let ctx = rendererContext.cgContext
            ctx.translateBy(x: apertureCenter.x, y: apertureCenter.y)
            ctx.scaleBy(x: scale, y: scale)
            ctx.translateBy(x: -sourcePointInLCD.x, y: -sourcePointInLCD.y)
            lcdImage.draw(at: .zero)
        }

        magnifier.setSnapshot(lensImage)
    }

    private func autoscrollIfNeeded(point: CGPoint) {

        guard let inputView else { return }
        let scrollView: UIScrollView?
        if let tv = inputView as? UITextView { scrollView = tv }
        else { scrollView = inputView.ancestorScrollViewForTextInteraction() }
        guard let scrollView else { return }

        let p = inputView.convert(point, to: scrollView)
        let edgeBand: CGFloat = 30
        var dy: CGFloat = 0
        if p.y < scrollView.bounds.minY + edgeBand {
            dy = -max(1, (scrollView.bounds.minY + edgeBand - p.y) / 6)
        } else if p.y > scrollView.bounds.maxY - edgeBand {
            dy = max(1, (p.y - (scrollView.bounds.maxY - edgeBand)) / 6)
        }
        guard dy != 0 else { return }
        var offset = scrollView.contentOffset
        let minY = -scrollView.adjustedContentInset.top
        let maxY = max(minY,
                       scrollView.contentSize.height - scrollView.bounds.height
                       + scrollView.adjustedContentInset.bottom)
        offset.y = min(max(offset.y + dy, minY), maxY)
        if offset.y != scrollView.contentOffset.y {
            scrollView.setContentOffset(offset, animated: false)
        }
    }

    private func suppressSystemDoubleTapRecognizers(in root: UIView) {
        var stack: [UIView] = [root]
        while let view = stack.popLast() {
            for recognizer in view.gestureRecognizers ?? [] {
                guard recognizer !== singleTapGesture,
                      recognizer !== doubleTapGesture,
                      recognizer !== tripleTapGesture,
                      recognizer !== loupeGesture,
                      let tap = recognizer as? UITapGestureRecognizer,
                      tap.numberOfTouchesRequired == 1,
                      tap.numberOfTapsRequired == 2 else { continue }
                let id = ObjectIdentifier(recognizer)
                if suppressedSystemDoubleTaps[id] == nil {
                    suppressedSystemDoubleTaps[id] = (recognizer, recognizer.isEnabled)
                }
                recognizer.isEnabled = false
            }
            stack.append(contentsOf: view.subviews)
        }
    }

    private func restoreSuppressedSystemDoubleTaps() {
        for (_, state) in suppressedSystemDoubleTaps {
            state.0.isEnabled = state.1
        }
        suppressedSystemDoubleTaps.removeAll(keepingCapacity: false)
    }

    private func hideSystemMenuImmediately() {
        UIMenuController.shared.setMenuVisible(false, animated: false)
        suppressModernChrome()
    }

    private func suppressModernChrome() {
        guard active, !isSnapshotting else { return }

        let windows: [UIWindow]
        if #available(iOS 15.0, *) {
            windows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
        } else {
            windows = UIApplication.shared.windows
        }
        for window in windows {

            if #available(iOS 17.0, *) {
                suppressSelectionDisplayInteractions(in: window)
            }
            suppressModernChrome(in: window)
            suppressModernLayers(in: window.layer)
        }
    }

    @available(iOS 17.0, *)
    private func suppressSelectionDisplayInteractions(in root: UIView?) {
        guard let root else { return }
        var stack: [UIView] = [root]
        while let view = stack.popLast() {
            for interaction in view.interactions {
                if let display = interaction as? UITextSelectionDisplayInteraction {

                    suppressSystemView(display.highlightView)
                    for handle in display.handleViews {
                        suppressSystemView(handle)
                    }
                }
            }
            stack.append(contentsOf: view.subviews)
        }
    }

    private func suppressSystemView(_ view: UIView) {
        guard !NSStringFromClass(type(of: view)).contains("OldOS") else { return }
        let id = ObjectIdentifier(view)
        if suppressedSystemViews[id] == nil, !view.isHidden {
            suppressedSystemViews[id] = view
            view.isHidden = true
        } else if suppressedSystemViews[id] != nil {
            view.isHidden = true
        }
    }

    private func suppressSystemLayer(_ layer: CALayer) {
        let id = ObjectIdentifier(layer)
        if suppressedSystemLayers[id] == nil, !layer.isHidden {
            suppressedSystemLayers[id] = layer
            layer.isHidden = true
        } else if suppressedSystemLayers[id] != nil {
            layer.isHidden = true
        }
    }

    private func suppressModernChrome(in view: UIView) {
        for child in view.subviews {
            let name = NSStringFromClass(type(of: child))
            if !name.contains("OldOS") && shouldSuppressSystemClassName(name) {
                suppressSystemView(child)
                continue
            }
            suppressModernChrome(in: child)
        }
    }

    private func suppressModernLayers(in layer: CALayer) {
        for child in layer.sublayers ?? [] {
            let className = NSStringFromClass(type(of: child))
            let debugName = child.name ?? ""
            let delegateName: String = {
                guard let view = child.delegate as? UIView else { return "" }
                return NSStringFromClass(type(of: view))
            }()
            let combined = className + " " + debugName + " " + delegateName
            if !combined.contains("OldOS") && shouldSuppressSystemGrabberName(combined) {
                suppressSystemLayer(child)
                continue
            }
            suppressModernLayers(in: child)
        }
    }

    private func shouldSuppressSystemClassName(_ name: String) -> Bool {
        let tokens = [
            "UIEditMenu", "UICalloutBar", "UITextMagnifier", "Loupe", "Magnifier",
            "UISelectionGrabber", "SelectionGrabber", "SelectionHandle",
            "SelectionKnob", "SelectionDot", "UITextSelectionHighlight",
            "SelectionHighlight"
        ]
        return tokens.contains(where: name.contains)
    }

    private func shouldSuppressSystemGrabberName(_ name: String) -> Bool {
        let tokens = [
            "UISelectionGrabber", "SelectionGrabber", "SelectionHandle",
            "SelectionKnob", "SelectionDot"
        ]
        return tokens.contains(where: name.contains)
    }

    private func restoreSuppressedSystemChrome() {
        for view in suppressedSystemViews.values {
            view.isHidden = false
        }
        suppressedSystemViews.removeAll(keepingCapacity: false)
        for layer in suppressedSystemLayers.values {
            layer.isHidden = false
        }
        suppressedSystemLayers.removeAll(keepingCapacity: false)
    }

    private func applyTextEffectsLCDClip(to view: UIView) {
        guard let inputView, let window = inputView.window else {
            view.layer.mask = nil
            return
        }
        let host = textEffectsHostView(in: window)
        host.updateLCDClip(textEffectsLCDFrame(), in: window)
        view.layer.mask = nil
    }

    private func textEffectsHostView(in window: UIWindow) -> OldOSTextEffectsClipHostView {
        if let host = textEffectsHost, host.superview === window {
            host.updateLCDClip(textEffectsLCDFrame(), in: window)
            window.bringSubviewToFront(host)
            return host
        }
        textEffectsHost?.removeFromSuperview()
        let host = OldOSTextEffectsClipHostView(frame: window.bounds)
        window.addSubview(host)
        host.updateLCDClip(textEffectsLCDFrame(), in: window)
        window.bringSubviewToFront(host)
        textEffectsHost = host
        return host
    }

    private func textEffectsLCDFrame() -> CGRect {
        guard let inputView, let window = inputView.window else { return .zero }
        return keyboard?.oldOSVirtualLCDFrame(in: window) ?? window.bounds
    }

    private func textEffectsVisibleFrame() -> CGRect {
        guard let inputView, let window = inputView.window else { return .zero }
        return keyboard?.oldOSTextEffectsVisibleFrame(in: window) ?? window.bounds
    }
}

private extension UIView {
    var hasWebKitAncestorForClassicTextInteraction: Bool {
        var view: UIView? = self
        while let current = view {
            let name = NSStringFromClass(type(of: current))
            if name.contains("WK") || name.contains("WebKit") || name.contains("WebView") {
                return true
            }
            view = current.superview
        }
        return false
    }

    func ancestorScrollViewForTextInteraction() -> UIScrollView? {
        var v = superview
        while let current = v {
            if let scroll = current as? UIScrollView { return scroll }
            v = current.superview
        }
        return nil
    }

    func fadeOutAndRemove(duration: TimeInterval) {
        UIView.animate(withDuration: duration, animations: { self.alpha = 0 }) { _ in
            self.removeFromSuperview()
        }
    }
}
