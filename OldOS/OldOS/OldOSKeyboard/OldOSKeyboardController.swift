import Foundation
import SwiftUI
import UIKit
import AVFoundation
import QuartzCore

@MainActor
private final class OldOSAutocorrectPromptView: UIView {
    enum Placement {
        case belowTypedText
        case aboveTypedText
    }

    enum Appearance {
        case standard
        case notes
    }

    private let typedContainer = UIView()
    private let typedLabel = UILabel()
    private let typedBackgroundLayer = CAShapeLayer()
    private let typedRuledLineLayer = CAShapeLayer()

    private let correctionContainer = UIView()
    private let correctionFillView = UIView()
    private let suggestionLabel = UILabel()
    private let rejectButton = UIButton(type: .custom)
    private let bubbleLayer = CAShapeLayer()
    private let viewportClipLayer = CAShapeLayer()

    private var typedWidth: CGFloat
    private let typedHeight: CGFloat
    private var typedTextLeftInset: CGFloat
    private var typedOriginX: CGFloat
    private var correctionWidth: CGFloat
    private var correctionOriginX: CGFloat
    private var placement: Placement
    private let correctionHeight: CGFloat = 30
    private let typedText: String
    private let suggestion: String
    private let documentBackgroundColor: UIColor
    private let appearance: Appearance

    private var isNotesAppearance: Bool { appearance == .notes }

    private static func notesBackgroundImage() -> UIImage? {
        UIImage(named: "kb-notes-bg")
    }

    fileprivate static func notesTextureColor(fallback: UIColor) -> UIColor {
        guard let image = notesBackgroundImage() else { return fallback }
        return UIColor(patternImage: image)
    }

    private var typedTextAnimationView: UIView?
    private var correctionAnimationView: UIView?

    var onReject: (() -> Void)?
    var onAcceptanceCompleted: (() -> Void)?

    init(
        suggestion: String,
        typedText: String,
        typedWidth: CGFloat,
        typedHeight: CGFloat,
        typedTextLeftInset: CGFloat,
        typedOriginX: CGFloat,
        correctionWidth: CGFloat,
        correctionOriginX: CGFloat,
        placement: Placement,
        documentBackgroundColor: UIColor,
        appearance: Appearance
    ) {
        self.typedWidth = typedWidth
        self.typedHeight = typedHeight
        self.typedTextLeftInset = typedTextLeftInset
        self.typedOriginX = typedOriginX
        self.correctionWidth = correctionWidth
        self.correctionOriginX = correctionOriginX
        self.placement = placement
        self.typedText = typedText
        self.suggestion = suggestion
        self.documentBackgroundColor = documentBackgroundColor
        self.appearance = appearance
        super.init(frame: .zero)

        isOpaque = false
        backgroundColor = .clear
        clipsToBounds = false

        let typedFill: UIColor
        let outlineColor: UIColor
        let correctionFill: UIColor
        let correctionTextColor: UIColor
        let sourceTextColor: UIColor

        if appearance == .notes {

            typedFill = Self.notesTextureColor(
                fallback: UIColor(red: 242/255, green: 229/255, blue: 157/255, alpha: 1)
            )
            correctionFill = Self.notesTextureColor(
                fallback: UIColor(red: 246/255, green: 232/255, blue: 158/255, alpha: 1)
            )
            outlineColor = UIColor(red: 187/255, green: 135/255, blue: 64/255, alpha: 1)
            correctionTextColor = UIColor(red: 160/255, green: 92/255, blue: 62/255, alpha: 1)
            sourceTextColor = UIColor(red: 67/255, green: 54/255, blue: 42/255, alpha: 1)
        } else {
            typedFill = UIColor(red: 190/255, green: 199/255, blue: 216/255, alpha: 1)
            correctionFill = UIColor(white: 0.965, alpha: 1)
            outlineColor = UIColor(red: 126/255, green: 151/255, blue: 190/255, alpha: 1)
            correctionTextColor = UIColor(red: 23/255, green: 103/255, blue: 181/255, alpha: 1)
            sourceTextColor = UIColor(white: 0.08, alpha: 1)
        }

        typedContainer.isOpaque = true
        typedContainer.backgroundColor = typedFill
        typedContainer.isUserInteractionEnabled = false

        typedContainer.clipsToBounds = true

        typedBackgroundLayer.fillColor = isNotesAppearance
            ? UIColor.clear.cgColor
            : typedFill.cgColor
        typedBackgroundLayer.strokeColor = outlineColor.cgColor
        typedBackgroundLayer.lineWidth = 1
        typedBackgroundLayer.contentsScale = UIScreen.main.scale

        typedRuledLineLayer.contentsScale = UIScreen.main.scale
        typedRuledLineLayer.lineWidth = 1
        typedRuledLineLayer.strokeColor = UIColor(
            red: 183/255,
            green: 186/255,
            blue: 173/255,
            alpha: 1
        ).cgColor
        typedRuledLineLayer.isHidden = !isNotesAppearance
        typedContainer.layer.addSublayer(typedRuledLineLayer)
        typedContainer.layer.addSublayer(typedBackgroundLayer)

        typedLabel.text = typedText
        typedLabel.textColor = sourceTextColor
        typedLabel.backgroundColor = .clear
        typedLabel.font = appearance == .notes
            ? (UIFont(name: "Noteworthy-Bold", size: 19) ?? UIFont.systemFont(ofSize: 19))
            : (UIFont(name: "Helvetica", size: 17) ?? UIFont.systemFont(ofSize: 17))
        typedLabel.textAlignment = .left
        typedLabel.lineBreakMode = .byClipping
        typedContainer.addSubview(typedLabel)
        addSubview(typedContainer)

        correctionContainer.isOpaque = false
        correctionContainer.backgroundColor = .clear
        correctionContainer.clipsToBounds = false

        correctionContainer.layer.shadowColor = UIColor.black.cgColor
        correctionContainer.layer.shadowOpacity = 0.20
        correctionContainer.layer.shadowRadius = 1.0
        correctionContainer.layer.shadowOffset = CGSize(width: 0, height: 1)
        correctionContainer.layer.masksToBounds = false

        correctionFillView.isOpaque = true
        correctionFillView.isUserInteractionEnabled = false
        correctionFillView.backgroundColor = correctionFill
        correctionContainer.addSubview(correctionFillView)

        addSubview(correctionContainer)

        bubbleLayer.fillColor = isNotesAppearance
            ? UIColor.clear.cgColor
            : correctionFill.cgColor
        bubbleLayer.strokeColor = outlineColor.cgColor
        bubbleLayer.lineWidth = 1
        bubbleLayer.contentsScale = UIScreen.main.scale
        correctionContainer.layer.addSublayer(bubbleLayer)

        suggestionLabel.text = suggestion
        suggestionLabel.textColor = correctionTextColor
        suggestionLabel.backgroundColor = .clear
        suggestionLabel.font = appearance == .notes
            ? (UIFont(name: "Noteworthy-Bold", size: 19) ?? UIFont.systemFont(ofSize: 19))
            : (UIFont(name: "Helvetica", size: 17) ?? UIFont.systemFont(ofSize: 17))
        suggestionLabel.textAlignment = .left
        suggestionLabel.lineBreakMode = .byClipping
        correctionContainer.addSubview(suggestionLabel)

        rejectButton.accessibilityLabel = "Reject correction"
        rejectButton.backgroundColor = .clear
        if appearance == .notes {
            rejectButton.setImage(UIImage(named: "kb-autocorrection-cancel-notes"), for: .normal)
            rejectButton.setImage(UIImage(named: "kb-autocorrection-cancel-notes"), for: .highlighted)
        } else {
            rejectButton.setImage(UIImage(named: "kb-autocorrection-cancel"), for: .normal)
            rejectButton.setImage(UIImage(named: "kb-autocorrection-cancel-hi"), for: .highlighted)
        }
        rejectButton.imageView?.contentMode = .center
        rejectButton.addTarget(self, action: #selector(rejectTapped), for: .touchUpInside)
        correctionContainer.addSubview(rejectButton)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    static func naturalCorrectionWidth(
        for suggestion: String,
        appearance: Appearance
    ) -> CGFloat {
        let font = appearance == .notes
            ? (UIFont(name: "Noteworthy-Bold", size: 19) ?? UIFont.systemFont(ofSize: 19))
            : (UIFont(name: "Helvetica", size: 17) ?? UIFont.systemFont(ofSize: 17))
        let textWidth = (suggestion as NSString).size(withAttributes: [.font: font]).width
        let horizontalPromptInset: CGFloat = 3
        let correctionHeight: CGFloat = 30
        let promptExtraWidth = correctionHeight * 0.75
        return ceil(max(45, textWidth + horizontalPromptInset * 2 + promptExtraWidth))
    }

    static func size(
        for suggestion: String,
        typedWidth: CGFloat,
        typedHeight: CGFloat,
        appearance: Appearance
    ) -> CGSize {
        let correctionWidth = naturalCorrectionWidth(
            for: suggestion,
            appearance: appearance
        )
        return CGSize(
            width: max(correctionWidth, typedWidth),
            height: typedHeight + 30
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let correctionY: CGFloat
        let typedY: CGFloat
        switch placement {
        case .belowTypedText:
            typedY = 0
            correctionY = typedHeight
        case .aboveTypedText:
            correctionY = 0
            typedY = correctionHeight
        }

        typedContainer.frame = CGRect(
            x: typedOriginX,
            y: typedY,
            width: min(max(0, bounds.width - typedOriginX), max(0, typedWidth)),
            height: typedHeight
        )
        correctionContainer.frame = CGRect(
            x: correctionOriginX,
            y: correctionY,
            width: min(max(0, bounds.width - correctionOriginX), max(0, correctionWidth)),
            height: correctionHeight
        )

        let pixel = 1 / max(1, UIScreen.main.scale)
        typedBackgroundLayer.frame = typedContainer.bounds
        typedBackgroundLayer.path = UIBezierPath(
            rect: typedContainer.bounds.insetBy(dx: pixel / 2, dy: pixel / 2)
        ).cgPath

        if isNotesAppearance {

            let lineY = round(typedContainer.bounds.height * 0.7833) + pixel / 2 + 0.5
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: 0, y: lineY))
            linePath.addLine(to: CGPoint(x: typedContainer.bounds.width, y: lineY))
            typedRuledLineLayer.frame = typedContainer.bounds
            typedRuledLineLayer.path = linePath.cgPath
            typedRuledLineLayer.isHidden = false
        } else {
            typedRuledLineLayer.path = nil
            typedRuledLineLayer.isHidden = true
        }

        typedLabel.frame = CGRect(
            x: typedTextLeftInset,

            y: 0,
            width: max(0, typedContainer.bounds.width - typedTextLeftInset),
            height: typedContainer.bounds.height
        )

        let rect = correctionContainer.bounds.insetBy(dx: pixel / 2, dy: pixel / 2)
        let radius = max(0, rect.height / 2)
        let p = UIBezierPath()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        p.addArc(
            withCenter: CGPoint(x: rect.maxX - radius, y: rect.midY),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: .pi / 2,
            clockwise: true
        )
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.close()
        bubbleLayer.path = p.cgPath
        bubbleLayer.frame = correctionContainer.bounds
        correctionContainer.layer.shadowPath = p.cgPath

        correctionFillView.frame = correctionContainer.bounds
        let fillMask = CAShapeLayer()
        fillMask.frame = correctionFillView.bounds
        fillMask.path = p.cgPath
        correctionFillView.layer.mask = fillMask

        let rejectHitSize: CGFloat = 22
        rejectButton.frame = CGRect(
            x: correctionContainer.bounds.width - rejectHitSize - 2,
            y: floor((correctionHeight - rejectHitSize) / 2),
            width: rejectHitSize,
            height: rejectHitSize
        )
        let correctionTextInset: CGFloat = 2.5
        let correctionTextYOffset: CGFloat = isNotesAppearance ? -2 : -1
        suggestionLabel.frame = CGRect(
            x: correctionTextInset,
            y: correctionTextYOffset,
            width: max(0, rejectButton.frame.minX - correctionTextInset),
            height: correctionHeight
        )
    }

    fileprivate func updateGeometry(
        typedWidth: CGFloat,
        typedTextLeftInset: CGFloat,
        typedOriginX: CGFloat,
        correctionWidth: CGFloat,
        correctionOriginX: CGFloat,
        placement: Placement
    ) {
        self.typedWidth = max(0, typedWidth)
        self.typedTextLeftInset = typedTextLeftInset
        self.typedOriginX = max(0, typedOriginX)
        self.correctionWidth = max(0, correctionWidth)
        self.correctionOriginX = max(0, correctionOriginX)
        self.placement = placement
        setNeedsLayout()
    }

    fileprivate func setVisibleWindowClipRect(_ rect: CGRect?, in window: UIWindow) {
        guard let rect else {
            layer.mask = nil
            return
        }
        let local = convert(rect, from: window).intersection(bounds)
        viewportClipLayer.frame = bounds
        viewportClipLayer.contentsScale = UIScreen.main.scale
        if local.isNull || local.width <= 0 || local.height <= 0 {
            viewportClipLayer.path = UIBezierPath(rect: .zero).cgPath
        } else {
            viewportClipLayer.path = UIBezierPath(rect: local).cgPath
        }
        layer.mask = viewportClipLayer
    }

    private func makeAnimationTextView(
        text: String,
        frame: CGRect,
        backgroundColor: UIColor,
        textColor: UIColor,
        leftInset: CGFloat
    ) -> UIView {
        let view = UIView(frame: frame)
        view.isOpaque = backgroundColor.cgColor.alpha >= 0.999
        view.backgroundColor = backgroundColor
        view.isUserInteractionEnabled = false
        view.clipsToBounds = true

        let label = UILabel(frame: CGRect(
            x: leftInset,
            y: -1,
            width: max(0, frame.width - leftInset),
            height: frame.height
        ))
        label.text = text
        label.textColor = textColor
        label.backgroundColor = .clear
        label.font = isNotesAppearance
            ? (UIFont(name: "Noteworthy-Bold", size: 19) ?? UIFont.systemFont(ofSize: 19))
            : (UIFont(name: "Helvetica", size: 17) ?? UIFont.systemFont(ofSize: 17))
        label.textAlignment = .left
        label.lineBreakMode = .byClipping
        view.addSubview(label)
        return view
    }

    func animateAcceptance() {
        onReject = nil
        isUserInteractionEnabled = false
        layoutIfNeeded()

        let targetFrame = typedContainer.frame
        let font = isNotesAppearance
            ? (UIFont(name: "Noteworthy-Bold", size: 19) ?? UIFont.systemFont(ofSize: 19))
            : (UIFont(name: "Helvetica", size: 17) ?? UIFont.systemFont(ofSize: 17))

        let animationTextPadding: CGFloat = 3.0
        let correctionTextWidth = ceil(
            (suggestion as NSString).size(withAttributes: [.font: font]).width
        )
        let naturalMovingWidth = max(1, correctionTextWidth + animationTextPadding * 2)

        let movingWidth = min(naturalMovingWidth, max(0, correctionContainer.bounds.width))

        let movingStartX = correctionContainer.frame.minX
            + suggestionLabel.frame.minX
            - animationTextPadding
        let movingHeight = max(18, min(typedHeight, ceil(font.lineHeight)))
        let movingStartY = correctionContainer.frame.midY - movingHeight / 2
        let movingStartFrame = CGRect(
            x: movingStartX,
            y: movingStartY,
            width: movingWidth,
            height: movingHeight
        )

        let typedAnimationFrame = targetFrame

        let typedAnimation = makeAnimationTextView(
            text: typedText,
            frame: typedAnimationFrame,
            backgroundColor: documentBackgroundColor,
            textColor: isNotesAppearance
                ? UIColor(red: 67/255, green: 54/255, blue: 42/255, alpha: 1)
                : UIColor(white: 0.08, alpha: 1),
            leftInset: 3
        )

        let correctionAnimation = makeAnimationTextView(
            text: suggestion,
            frame: movingStartFrame,
            backgroundColor: isNotesAppearance
                ? Self.notesTextureColor(
                    fallback: UIColor(red: 246/255, green: 232/255, blue: 158/255, alpha: 1)
                )
                : .white,
            textColor: isNotesAppearance
                ? UIColor(red: 160/255, green: 92/255, blue: 62/255, alpha: 1)
                : UIColor(white: 0.08, alpha: 1),
            leftInset: animationTextPadding
        )
        let correctionAnimationLabel = correctionAnimation.subviews.compactMap { $0 as? UILabel }.first
        var correctionAnimationBlackLabel: UILabel?
        if isNotesAppearance, let brownLabel = correctionAnimationLabel {
            let blackLabel = UILabel(frame: brownLabel.frame)
            blackLabel.text = brownLabel.text
            blackLabel.textColor = UIColor(white: 0.08, alpha: 1)
            blackLabel.backgroundColor = .clear
            blackLabel.font = brownLabel.font
            blackLabel.textAlignment = brownLabel.textAlignment
            blackLabel.lineBreakMode = brownLabel.lineBreakMode
            blackLabel.alpha = 0
            correctionAnimation.addSubview(blackLabel)
            correctionAnimationBlackLabel = blackLabel
        }

        typedTextAnimationView = typedAnimation
        correctionAnimationView = correctionAnimation

        insertSubview(typedAnimation, belowSubview: correctionContainer)
        insertSubview(correctionAnimation, belowSubview: correctionContainer)
        typedContainer.removeFromSuperview()
        correctionContainer.alpha = 0

        let targetOrigin = CGPoint(
            x: targetFrame.minX,
            y: targetFrame.midY - movingHeight / 2
        )

        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                var movingWordFrame = correctionAnimation.frame
                movingWordFrame.origin = targetOrigin
                correctionAnimation.frame = movingWordFrame

                if self.isNotesAppearance {

                    correctionAnimationLabel?.alpha = 0
                    correctionAnimationBlackLabel?.alpha = 1
                }

            },
            completion: { _ in
                let completion = self.onAcceptanceCompleted
                self.onAcceptanceCompleted = nil
                self.removeFromSuperview()
                completion?()
            }
        )
    }

    func animateDismissal() {
        onReject = nil
        isUserInteractionEnabled = false
        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: { self.alpha = 0 },
            completion: { _ in self.removeFromSuperview() }
        )
    }

    @objc private func rejectTapped() {
        onReject?()
    }
}

@MainActor
public final class OldOSKeyboardController: ObservableObject {
    @Published public var isVisible = false
    @Published public var keyplane: OldOSKeyboardKeyplane = .letters
    @Published public var shiftState: OldOSKeyboardShiftState = .off
    @Published public private(set) var shiftOrigin: OldOSKeyboardShiftOrigin = .manual
    @Published public var configuration: OldOSKeyboardConfiguration = .standard
    @Published public var returnKeyEnabled = true

    @Published public private(set) var currentHeight: CGFloat = 0
    @Published public private(set) var isEditing = false

    private var simulatedLCDFrameInWindow: CGRect?

    weak var activeInputView: UIView?
    private var submitAction: (() -> Void)?
    private var renderedKeyboardHeight: CGFloat = OldOSKeyboardLayout.referenceSize.height
    private var clickPlayer: AVAudioPlayer?
    private var globalInputInterceptor: OldOSKeyboardGlobalInputInterceptor?

    private struct PendingAutocorrection {
        let original: String
        let replacement: String
        let normalizedOriginal: String
        let normalizedReplacement: String
        let startOffset: Int
        let endOffset: Int
    }

    private lazy var autocorrectionLanguageModel: OldOSZephyrStaticLanguageModel? = {
        try? OldOSZephyrStaticLanguageModel.bundledUS()
    }()
    private var pendingAutocorrection: PendingAutocorrection?
    private weak var autocorrectionPrompt: OldOSAutocorrectPromptView?

    private var autocorrectionScrollObservations: [NSKeyValueObservation] = []
    private var autocorrectionReanchorScheduled = false
    private var autocorrectionGeneration: Int = 0
    private let autocorrectionPromptDelay: TimeInterval = 0.200
    private var rejectedAutocorrections: [String: Int] = [:]

    private var qualityFilterRememberedCandidate: String = ""

    private var currentWordTouchEvidence: [OldOSZephyrAutocorrectionTouchEvidence] = []

    private var pendingZephyrErasedKeyHistory: [UInt8] = []

    private let learnedDictionaryDefaultsKey = "OldOS.iOS43.DynamicDictionary.en_US.v2"
    private lazy var learnedWordFrequencies: [String: Int] =
        UserDefaults.standard.dictionary(forKey: learnedDictionaryDefaultsKey) as? [String: Int] ?? [:]

    private let punctuationThatImmediatelyReturnsToLetters: Set<String> = ["'", "’"]
    private var returnToLettersAfterNextSpace = false

    private var shiftLockReady = false
    private var shiftLockFirstTapTime: TimeInterval = 0
    private var shiftTouchInProgress = false
    private var shiftTouchLockedOnDown = false
    private var shiftWasShifted = false
    private var shiftStateBeforeTouch: OldOSKeyboardShiftState = .off
    private var shiftOriginBeforeTouch: OldOSKeyboardShiftOrigin = .manual

    public init() {
        prepareClickSound()
    }

    func startGlobalInputInterception() {
        if globalInputInterceptor == nil {
            globalInputInterceptor = OldOSKeyboardGlobalInputInterceptor(keyboard: self)
        }
        globalInputInterceptor?.start()
    }

    func stopGlobalInputInterception() {
        globalInputInterceptor?.stop()
        globalInputInterceptor = nil
    }

    public func show() {
        withAnimation(.easeInOut(duration: 0.30)) {
            isVisible = true
            currentHeight = renderedKeyboardHeight
        }
        isEditing = true
    }

    public func hide() {
        if let inputView = activeInputView {
            OldOSClassicTextInteraction.deactivate(on: inputView)
        }
        clearAutocorrection()
        qualityFilterRememberedCandidate = ""
        currentWordTouchEvidence.removeAll(keepingCapacity: true)
        pendingZephyrErasedKeyHistory.removeAll(keepingCapacity: true)
        returnToLettersAfterNextSpace = false
        withAnimation(.easeInOut(duration: 0.30)) {
            isVisible = false
            currentHeight = 0
        }
        isEditing = false
        activeInputView?.resignFirstResponder()
        activeInputView = nil
        submitAction = nil
    }

    func setRenderedKeyboardHeight(_ height: CGFloat) {
        renderedKeyboardHeight = max(0, height)
        if isVisible { currentHeight = renderedKeyboardHeight }
        scheduleAutocorrectionPromptReanchor()
    }

    func setSimulatedLCDFrameInWindow(_ frame: CGRect?) {
        guard let frame, frame.width > 0, frame.height > 0 else {
            simulatedLCDFrameInWindow = nil
            scheduleAutocorrectionPromptReanchor()
            return
        }

        simulatedLCDFrameInWindow = frame
        scheduleAutocorrectionPromptReanchor()
    }

    func oldOSVirtualLCDFrame(in window: UIWindow) -> CGRect {
        let rawLCD = simulatedLCDFrameInWindow ?? window.bounds
        let lcdIntersection = rawLCD.intersection(window.bounds)
        return (!lcdIntersection.isNull && !lcdIntersection.isInfinite
                && lcdIntersection.width > 0 && lcdIntersection.height > 0)
            ? lcdIntersection
            : window.bounds
    }

    func oldOSTextEffectsVisibleFrame(in window: UIWindow) -> CGRect {
        let lcd = oldOSVirtualLCDFrame(in: window)
        let keyboardTop = isVisible
            ? max(lcd.minY, lcd.maxY - max(0, currentHeight))
            : lcd.maxY
        return CGRect(
            x: lcd.minX,
            y: lcd.minY,
            width: lcd.width,
            height: max(0, keyboardTop - lcd.minY)
        )
    }

    func oldOSPrepareForTextInteraction() {
        clearAutocorrection()
    }

    func activate(
        textField: UITextField,
        configuration: OldOSKeyboardConfiguration,
        onSubmit: (() -> Void)?
    ) {
        activate(inputView: textField, configuration: configuration, onSubmit: onSubmit)
    }

    func activate(
        textView: UITextView,
        configuration: OldOSKeyboardConfiguration,
        onSubmit: (() -> Void)? = nil
    ) {
        activate(inputView: textView, configuration: configuration, onSubmit: onSubmit)
    }

    func activate(
        inputView: UIView,
        configuration: OldOSKeyboardConfiguration,
        onSubmit: (() -> Void)?
    ) {
        guard inputView is UITextInput else { return }
        clearAutocorrection()
        qualityFilterRememberedCandidate = ""
        currentWordTouchEvidence.removeAll(keepingCapacity: true)
        pendingZephyrErasedKeyHistory.removeAll(keepingCapacity: true)
        returnToLettersAfterNextSpace = false
        activeInputView = inputView
        OldOSClassicTextInteraction.install(on: inputView, keyboard: self)
        self.configuration = configuration
        submitAction = onSubmit
        keyplane = configuration.keyboardType.initialPlane
        shiftState = .off
        shiftOrigin = .manual
        resetShiftTouchTracking()
        updateAutomaticShift()
        refreshReturnKeyEnabled()
        show()
    }

    func deactivate(textField: UITextField) {
        deactivate(inputView: textField)
    }

    func deactivate(textView: UITextView) {
        deactivate(inputView: textView)
    }

    func deactivate(inputView: UIView) {
        guard activeInputView === inputView else { return }
        OldOSClassicTextInteraction.deactivate(on: inputView)
        clearAutocorrection()
        qualityFilterRememberedCandidate = ""
        currentWordTouchEvidence.removeAll(keepingCapacity: true)
        pendingZephyrErasedKeyHistory.removeAll(keepingCapacity: true)
        returnToLettersAfterNextSpace = false
        activeInputView = nil
        submitAction = nil

        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.activeInputView == nil else { return }
            withAnimation(.easeInOut(duration: 0.30)) {
                self.isVisible = false
                self.currentHeight = 0
            }
            self.isEditing = false
        }
    }

    private func updateReturnToLettersBehaviorAfterNonLetterPlaneCommit(_ text: String) {
        guard configuration.keyboardType.hasAlphabeticPlane, keyplane != .letters else {
            returnToLettersAfterNextSpace = false
            return
        }

        if punctuationThatImmediatelyReturnsToLetters.contains(text) {
            returnToLettersAfterNextSpace = false
            keyplane = .letters
            updateAutomaticShift()
        } else {
            returnToLettersAfterNextSpace = true
        }
    }

    public func commit(
        _ key: OldOSKeyboardKey,
        zephyrTouchEvidence: OldOSZephyrAutocorrectionTouchEvidence? = nil
    ) {
        guard key.isEnabled else { return }
        switch key.kind {
        case .character:
            guard let text = key.committedText(shift: shiftState) else { return }
            let committedFromPunctuationPlane = keyplane != .letters
            let isASCIIAlphabetic = text.unicodeScalars.count == 1
                && text.unicodeScalars.allSatisfy {
                    ($0.value >= 65 && $0.value <= 90) || ($0.value >= 97 && $0.value <= 122)
                }

            if text.rangeOfCharacter(from: CharacterSet.letters.inverted) != nil {
                let accepted = acceptPendingAutocorrectionIfValid()
                if !accepted { learnCurrentTypedWordIfAppropriate() }
            }

            if isASCIIAlphabetic {
                recordAutocorrectionTouchEvidence(
                    zephyrTouchEvidence,
                    forCommittedText: text
                )
            }
            insert(text)

            if committedFromPunctuationPlane {
                updateReturnToLettersBehaviorAfterNonLetterPlaneCommit(text)
            } else {
                returnToLettersAfterNextSpace = false
            }

            if shiftState == .on {
                shiftState = .off
                shiftOrigin = .manual
            }
            if text.unicodeScalars.allSatisfy({ CharacterSet.letters.contains($0) }) {
                scheduleAutocorrectionUpdate()
            } else {
                clearAutocorrection()
                qualityFilterRememberedCandidate = ""
                if text != "'" && text != "’" {
                    currentWordTouchEvidence.removeAll(keepingCapacity: true)
                    pendingZephyrErasedKeyHistory.removeAll(keepingCapacity: true)
                }
            }
            playClick()
        case .space:
            commitSpace()
            playClick()
        case .returnKey:
            returnToLettersAfterNextSpace = false
            let accepted = acceptPendingAutocorrectionIfValid()
            if !accepted { learnCurrentTypedWordIfAppropriate() }

            if activeInputView is UITextView, configuration.returnType == .default {
                insert("\n")
                updateAutomaticShift()
            } else {
                submitAction?()
                if configuration.dismissesOnReturn { hide() }
            }
            qualityFilterRememberedCandidate = ""
            currentWordTouchEvidence.removeAll(keepingCapacity: true)
            pendingZephyrErasedKeyHistory.removeAll(keepingCapacity: true)
            playClick()
        case .shift:
            tapShift()
        case .delete:
            returnToLettersAfterNextSpace = false
            deleteBackward()
            playClick()
        case .switchToNumbers:
            returnToLettersAfterNextSpace = false
            keyplane = .numbers
            shiftState = .off
            shiftOrigin = .manual
            playClick()
        case .switchToSymbols:
            returnToLettersAfterNextSpace = false
            keyplane = .symbols
            shiftState = .off
            shiftOrigin = .manual
            playClick()
        case .switchToLetters:
            returnToLettersAfterNextSpace = false
            keyplane = .letters
            updateAutomaticShift()
            playClick()
        case .planeChooser:
            returnToLettersAfterNextSpace = false

            keyplane = keyplane == .symbols ? .numbers : .symbols
            shiftState = .off
            shiftOrigin = .manual
            playClick()
        case .empty:
            break
        case .globe:

            playClick()
        }
    }

    public func commitVariant(_ variant: String) {
        clearAutocorrection()
        currentWordTouchEvidence.removeAll(keepingCapacity: true)
        pendingZephyrErasedKeyHistory.removeAll(keepingCapacity: true)
        let committedFromPunctuationPlane = keyplane != .letters
        insert(variant)
        if committedFromPunctuationPlane {
            updateReturnToLettersBehaviorAfterNonLetterPlaneCommit(variant)
        } else {
            returnToLettersAfterNextSpace = false
        }
        if shiftState == .on {
            shiftState = .off
            shiftOrigin = .manual
        }
        playClick()
    }

    public func deleteBackward() {
        clearAutocorrection()
        updateTouchEvidenceForBackwardDelete()
        (activeInputView as? UIKeyInput)?.deleteBackward()
        updateAutomaticShift()
        refreshReturnKeyEnabled()
    }

    public func repeatDelete() {
        deleteBackward()
        playClick()
    }

    public func repeatDeleteWord() {
        deleteWordBackward()
        playClick()
    }

    private func deleteWordBackward() {
        currentWordTouchEvidence.removeAll(keepingCapacity: true)
        pendingZephyrErasedKeyHistory.removeAll(keepingCapacity: true)
        guard let field = activeInputView as? UITextInput else { return }

        guard let selection = field.selectedTextRange else {
            field.deleteBackward()
            updateAutomaticShift()
            refreshReturnKeyEnabled()
            return
        }

        if !selection.isEmpty {
            field.deleteBackward()
            updateAutomaticShift()
            refreshReturnKeyEnabled()
            return
        }

        let caret = selection.start
        let backward = UITextDirection.storage(.backward)
        let caretOffset = field.offset(from: field.beginningOfDocument, to: caret)

        var deletionStart: UITextPosition?
        var probe = caret

        for _ in 0..<4 {
            guard let candidate = field.tokenizer.position(
                from: probe,
                toBoundary: .word,
                inDirection: backward
            ) else { break }

            let candidateOffset = field.offset(
                from: field.beginningOfDocument,
                to: candidate
            )
            let probeOffset = field.offset(
                from: field.beginningOfDocument,
                to: probe
            )

            if candidateOffset >= probeOffset {
                guard let previous = field.position(from: probe, offset: -1) else { break }
                probe = previous
                continue
            }

            deletionStart = candidate

            if let range = field.textRange(from: candidate, to: caret),
               let chunk = field.text(in: range),
               chunk.rangeOfCharacter(from: .alphanumerics) != nil {
                break
            }

            probe = candidate
        }

        if var start = deletionStart {
            let selectedRange = field.textRange(from: start, to: caret)
            let selectedText = selectedRange.flatMap { field.text(in: $0) } ?? ""
            let alreadyIncludesTrailingSeparator = selectedText.last.map { $0.isWhitespace } ?? false

            if !alreadyIncludesTrailingSeparator {
                while let previous = field.position(from: start, offset: -1),
                      let separatorRange = field.textRange(from: previous, to: start),
                      let separator = field.text(in: separatorRange),
                      !separator.isEmpty,
                      separator.allSatisfy({ $0.isWhitespace }) {
                    start = previous
                }
            }

            let startOffset = field.offset(from: field.beginningOfDocument, to: start)
            if startOffset < caretOffset,
               let range = field.textRange(from: start, to: caret) {
                field.selectedTextRange = range
                field.deleteBackward()
                updateAutomaticShift()
                refreshReturnKeyEnabled()
                return
            }
        }

        field.deleteBackward()
        updateAutomaticShift()
        refreshReturnKeyEnabled()
    }

    func textDidChange(_ textField: UITextField) {
        textDidChange(inputView: textField)
    }

    func textDidChange(_ textView: UITextView) {
        textDidChange(inputView: textView)
    }

    func textDidChange(inputView: UIView) {
        guard activeInputView === inputView else { return }
        updateAutomaticShift()
        refreshReturnKeyEnabled()
        scheduleAutocorrectionUpdate()
    }

    public func updateAutomaticShift() {
        guard configuration.keyboardType.hasAlphabeticPlane else {
            shiftState = .off
            shiftOrigin = .manual
            return
        }
        guard configuration.autocapitalization, configuration.keyboardType.allowsAutomaticCapitalization else {
            if shiftState != .locked {
                shiftState = .off
                shiftOrigin = .manual
            }
            return
        }
        guard shiftState != .locked else { return }

        let before = textBeforeCursor()
        let trimmed = before.trimmingCharacters(in: .whitespacesAndNewlines)

        let shouldShift =
            trimmed.isEmpty ||
            before.hasSuffix("\n") ||
            before.hasSuffix(". ") ||
            before.hasSuffix("! ") ||
            before.hasSuffix("? ")

        shiftState = shouldShift ? .on : .off
        shiftOrigin = shouldShift ? .automatic : .manual
    }

    private func insert(_ text: String) {
        (activeInputView as? UIKeyInput)?.insertText(text)
        refreshReturnKeyEnabled()
    }

    private func commitSpace() {
        let shouldReturnToLetters = returnToLettersAfterNextSpace
            && keyplane != .letters
            && configuration.keyboardType.hasAlphabeticPlane
        returnToLettersAfterNextSpace = false

        let accepted = acceptPendingAutocorrectionIfValid()
        if !accepted { learnCurrentTypedWordIfAppropriate() }
        if configuration.doubleSpacePeriod {
            let before = textBeforeCursor()
            if before.hasSuffix(" "),
               let previous = before.dropLast().last,
               !previous.isWhitespace,
               !".!?".contains(previous) {
                (activeInputView as? UIKeyInput)?.deleteBackward()
                (activeInputView as? UIKeyInput)?.insertText(". ")
                if shouldReturnToLetters { keyplane = .letters }
                updateAutomaticShift()
                refreshReturnKeyEnabled()
                return
            }
        }
        (activeInputView as? UIKeyInput)?.insertText(" ")
        qualityFilterRememberedCandidate = ""
        currentWordTouchEvidence.removeAll(keepingCapacity: true)
        pendingZephyrErasedKeyHistory.removeAll(keepingCapacity: true)
        if shouldReturnToLetters { keyplane = .letters }
        updateAutomaticShift()
        refreshReturnKeyEnabled()
    }

    private var autocorrectionIsAllowedForCurrentInput: Bool {
        guard configuration.autocorrection,
              configuration.keyboardType.hasAlphabeticPlane,
              keyplane == .letters,
              activeInputView != nil
        else { return false }

        if let field = activeInputView as? UITextField, field.isSecureTextEntry {
            return false
        }
        return true
    }

    private struct AutocorrectionContextSignature: Equatable {
        let original: String
        let startOffset: Int
        let endOffset: Int
    }

    private func scheduleAutocorrectionUpdate() {
        let hadVisiblePrompt = autocorrectionPrompt != nil

        autocorrectionGeneration &+= 1
        pendingAutocorrection = nil

        guard autocorrectionIsAllowedForCurrentInput else {
            autocorrectionPrompt?.removeFromSuperview()
            autocorrectionPrompt = nil
            return
        }
        let generation = autocorrectionGeneration

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard generation == self.autocorrectionGeneration,
                  self.autocorrectionIsAllowedForCurrentInput
            else { return }

            guard let context = self.currentAutocorrectionWordContext() else {
                self.autocorrectionPrompt?.removeFromSuperview()
                self.autocorrectionPrompt = nil
                return
            }

            let signature = context.signature
            let delay = hadVisiblePrompt ? 0 : self.autocorrectionPromptDelay
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self,
                      generation == self.autocorrectionGeneration,
                      self.autocorrectionIsAllowedForCurrentInput,
                      let latest = self.currentAutocorrectionWordContext(),
                      latest.signature == signature
                else { return }

                self.refreshAutocorrectionPrompt(
                    generation: generation,
                    context: latest
                )
            }
        }
    }

    private func refreshAutocorrectionPrompt(
        generation: Int,
        context: AutocorrectionWordContext
    ) {
        guard generation == autocorrectionGeneration else { return }

        guard let resolved = resolvedAutocorrectionCandidate(for: context) else {
            clearAutocorrection()
            return
        }
        let candidate = resolved.candidate
        let casedReplacement = resolved.replacement

        guard let latest = currentAutocorrectionWordContext(),
              latest.signature == context.signature
        else { return }

        let pending = PendingAutocorrection(
            original: context.original,
            replacement: casedReplacement,
            normalizedOriginal: context.normalized,
            normalizedReplacement: candidate.sortKey,
            startOffset: context.startOffset,
            endOffset: context.endOffset
        )

        guard showAutocorrectionPrompt(
            replacement: casedReplacement,
            typedText: context.original,
            wordRange: context.range
        ) else { return }

        pendingAutocorrection = pending
    }

    private struct ResolvedAutocorrectionCandidate {
        let candidate: OldOSZephyrStaticLanguageModel.AutocorrectionCandidate
        let replacement: String
    }

    private func resolvedAutocorrectionCandidate(
        for context: AutocorrectionWordContext
    ) -> ResolvedAutocorrectionCandidate? {
        guard let model = autocorrectionLanguageModel else { return nil }

        if dynamicDictionaryAcceptsExactWord(context.original) {
            return nil
        }

        let liveBeam = model.ztLiveBeamCandidates(
            for: context.original,
            touchEvidence: currentWordTouchEvidence,
            learnedSurfaces: learnedWordFrequencies,
            includePredictStroke: true
        )

        let rawLiveCandidates = sourceRankedCandidates(
            deduplicatedCandidates(liveBeam.candidates),
            original: context.original
        )
        let qualityInput = applySourceMismatchFilters(
            rawLiveCandidates,
            original: context.original
        )
        let filteredLiveCandidate = selectQualityCandidate(
            qualityInput,
            for: context.original
        )

        let filteredLiveCandidates = filteredLiveCandidate.map { [$0] } ?? []
        let needsSpellCheck = sourceDoesNeedSpellCheck(
            rawCandidates: rawLiveCandidates,
            filteredCandidates: filteredLiveCandidates,
            original: context.original
        )

        if needsSpellCheck {
            let spellCandidates = sourceFilteredSpellCheckCandidates(
                for: context.original,
                model: model
            )
            if sourceShouldUseSpellCheckCandidates(
                rawCandidates: rawLiveCandidates,
                spellCandidates: spellCandidates,
                original: context.original
            ), let spellCandidate = spellCandidates.first {
                let replacement = applySourceCaseChanges(
                    spellCandidate,
                    matching: context.original
                )
                guard replacement != context.original else { return nil }
                return ResolvedAutocorrectionCandidate(
                    candidate: spellCandidate,
                    replacement: replacement
                )
            }
        }

        guard let candidate = filteredLiveCandidate else { return nil }
        let replacement = applySourceCaseChanges(candidate, matching: context.original)
        guard replacement != context.original else { return nil }
        return ResolvedAutocorrectionCandidate(candidate: candidate, replacement: replacement)
    }

    private let sourceIPhoneSpellCheckOmega: Double = 0.001

    private func sourceDoesNeedSpellCheck(
        rawCandidates: [OldOSZephyrStaticLanguageModel.AutocorrectionCandidate],
        filteredCandidates: [OldOSZephyrStaticLanguageModel.AutocorrectionCandidate],
        original: String
    ) -> Bool {
        if let first = rawCandidates.first {

            let omegaLog = sourceCandidateOmegaLog(first, original: original)
            if omegaLog > log(sourceIPhoneSpellCheckOmega) {
                return false
            }

        }

        _ = filteredCandidates
        return true
    }

    private func sourceSpellFallbackCandidates(
        for original: String,
        model: OldOSZephyrStaticLanguageModel
    ) -> [OldOSZephyrStaticLanguageModel.AutocorrectionCandidate] {
        model.autocorrectionCandidates(for: original, limit: 512).map { candidate in
            OldOSZephyrStaticLanguageModel.AutocorrectionCandidate(
                word: candidate.word,
                sortKey: candidate.sortKey,
                editDistance: candidate.editDistance,
                lexicalScore: candidate.lexicalScore,
                surfaceOrder: candidate.surfaceOrder,
                capitalizationMask: candidate.capitalizationMask,
                recordFlags: candidate.recordFlags,
                wordFlags: candidate.wordFlags,
                hasExplicitSurfaceForm: candidate.hasExplicitSurfaceForm,
                isDynamic: candidate.isDynamic,
                dynamicUserFrequency: candidate.dynamicUserFrequency,
                ztCameFromSpellFallback: true,

                spellCheckQuality: 1.0 / Double(candidate.editDistance + 1)
            )
        }
    }

    private func sourceFilteredSpellCheckCandidates(
        for original: String,
        model: OldOSZephyrStaticLanguageModel
    ) -> [OldOSZephyrStaticLanguageModel.AutocorrectionCandidate] {
        var candidates = sourceSpellFallbackCandidates(for: original, model: model)

        candidates = deduplicatedCandidates(candidates)
        candidates = candidates.filter {
            passesSourceCandidateFilters($0.word, original: original)
        }
        candidates = sourceRankedCandidates(candidates, original: original)

        guard let first = candidates.first else { return [] }

        if first.word.caseInsensitiveCompare(original) == .orderedSame {
            return []
        }
        if first.word.contains(where: { $0.isWhitespace }) {
            return []
        }
        return candidates
    }

    private func sourceShouldUseSpellCheckCandidates(
        rawCandidates: [OldOSZephyrStaticLanguageModel.AutocorrectionCandidate],
        spellCandidates: [OldOSZephyrStaticLanguageModel.AutocorrectionCandidate],
        original: String
    ) -> Bool {
        guard let spellFirst = spellCandidates.first else { return false }
        guard let rawFirst = rawCandidates.first else { return true }

        if rawFirst.word.contains(where: { $0.isWhitespace }) {
            return true
        }

        _ = original
        return spellFirst.lexicalScore > rawFirst.lexicalScore
    }

    private struct AutocorrectionWordContext {
        let original: String
        let normalized: String
        let startOffset: Int
        let endOffset: Int
        let range: UITextRange

        var signature: AutocorrectionContextSignature {
            AutocorrectionContextSignature(
                original: original,
                startOffset: startOffset,
                endOffset: endOffset
            )
        }
    }

    private func textInputLength(_ value: String) -> Int {
        (value as NSString).length
    }

    private func currentAutocorrectionWordContext() -> AutocorrectionWordContext? {
        guard let field = activeInputView as? UITextInput,
              let selection = field.selectedTextRange,
              selection.isEmpty
        else { return nil }

        let caret = selection.start
        let beforeRange = field.textRange(
            from: field.beginningOfDocument,
            to: caret
        )
        guard let beforeRange,
              let before = field.text(in: beforeRange)
        else { return nil }

        let surface = OldOSZephyrStaticLanguageModel.currentAutocorrectionSurfacePrefix(
            in: before
        )
        guard let normalized = OldOSZephyrStaticLanguageModel.autocorrectionLookupKey(for: surface),
              normalized.utf8.count >= 1
        else { return nil }

        let surfaceLength = textInputLength(surface)
        guard surfaceLength > 0,
              let start = field.position(from: caret, offset: -surfaceLength),
              let range = field.textRange(from: start, to: caret),
              let original = field.text(in: range),
              textInputLength(original) == surfaceLength,
              OldOSZephyrStaticLanguageModel.autocorrectionLookupKey(for: original) == normalized
        else { return nil }

        return AutocorrectionWordContext(
            original: original,
            normalized: normalized,
            startOffset: field.offset(from: field.beginningOfDocument, to: start),
            endOffset: field.offset(from: field.beginningOfDocument, to: caret),
            range: range
        )
    }

    @discardableResult
    private func acceptPendingAutocorrectionIfValid() -> Bool {

        if pendingAutocorrection == nil,
           autocorrectionIsAllowedForCurrentInput,
           let context = currentAutocorrectionWordContext(),
           let resolved = resolvedAutocorrectionCandidate(for: context) {
            pendingAutocorrection = PendingAutocorrection(
                original: context.original,
                replacement: resolved.replacement,
                normalizedOriginal: context.normalized,
                normalizedReplacement: resolved.candidate.sortKey,
                startOffset: context.startOffset,
                endOffset: context.endOffset
            )
        }

        guard let pending = pendingAutocorrection,
              let inputView = activeInputView,
              let field = inputView as? UITextInput,
              let selection = field.selectedTextRange,
              selection.isEmpty,
              field.offset(from: field.beginningOfDocument, to: selection.start) == pending.endOffset,
              let start = field.position(
                  from: field.beginningOfDocument,
                  offset: pending.startOffset
              ),
              let end = field.position(
                  from: field.beginningOfDocument,
                  offset: pending.endOffset
              ),
              let range = field.textRange(from: start, to: end),
              let current = field.text(in: range),
              current == pending.original
        else {
            clearAutocorrection()
            return false
        }

        let promptForAcceptance = takeAutocorrectionPromptForAnimation()

        let commitAcceptedCorrection = { [weak self, weak inputView] in
            guard let self,
                  let inputView,
                  let field = inputView as? UITextInput
            else { return }
            self.finishAcceptedAutocorrection(
                pending,
                in: inputView,
                textInput: field
            )
        }

        if let promptForAcceptance {
            promptForAcceptance.onAcceptanceCompleted = commitAcceptedCorrection
            promptForAcceptance.animateAcceptance()
        } else {
            commitAcceptedCorrection()
        }
        return true
    }

    private func adjustedSelectionOffsetAfterAutocorrectionCommit(
        _ offset: Int,
        pending: PendingAutocorrection
    ) -> Int {
        let replacementLength = textInputLength(pending.replacement)
        let originalLength = pending.endOffset - pending.startOffset
        let delta = replacementLength - originalLength

        if offset <= pending.startOffset { return offset }
        if offset >= pending.endOffset { return offset + delta }

        return pending.startOffset + replacementLength
    }

    private func finishAcceptedAutocorrection(
        _ pending: PendingAutocorrection,
        in inputView: UIView,
        textInput field: UITextInput
    ) {
        guard let start = field.position(
                from: field.beginningOfDocument,
                offset: pending.startOffset
              ),
              let end = field.position(
                from: field.beginningOfDocument,
                offset: pending.endOffset
              ),
              let range = field.textRange(from: start, to: end),
              let current = field.text(in: range),
              current == pending.original
        else {
            return
        }

        let selectionStartOffset: Int?
        let selectionEndOffset: Int?
        if let selection = field.selectedTextRange {
            selectionStartOffset = field.offset(from: field.beginningOfDocument, to: selection.start)
            selectionEndOffset = field.offset(from: field.beginningOfDocument, to: selection.end)
        } else {
            selectionStartOffset = nil
            selectionEndOffset = nil
        }

        field.selectedTextRange = range
        if let keyInput = inputView as? UIKeyInput {
            keyInput.insertText(pending.replacement)
        } else {
            field.replace(range, withText: pending.replacement)
        }

        let replacementEndOffset = pending.startOffset + textInputLength(pending.replacement)

        if let selectionStartOffset,
           let selectionEndOffset,
           let newSelectionStart = field.position(
                from: field.beginningOfDocument,
                offset: adjustedSelectionOffsetAfterAutocorrectionCommit(
                    selectionStartOffset,
                    pending: pending
                )
           ),
           let newSelectionEnd = field.position(
                from: field.beginningOfDocument,
                offset: adjustedSelectionOffsetAfterAutocorrectionCommit(
                    selectionEndOffset,
                    pending: pending
                )
           ),
           let adjustedSelection = field.textRange(from: newSelectionStart, to: newSelectionEnd) {
            field.selectedTextRange = adjustedSelection
        } else if let caret = field.position(
            from: field.beginningOfDocument,
            offset: replacementEndOffset
        ), let collapsed = field.textRange(from: caret, to: caret) {
            field.selectedTextRange = collapsed
        }

        increaseLearnedFrequency(pending.replacement, by: 1)

        if activeInputView === inputView {
            updateAutomaticShift()
            refreshReturnKeyEnabled()
        }
    }

    private func rejectPendingAutocorrection() {
        guard let pending = pendingAutocorrection else {
            clearAutocorrection()
            return
        }
        let key = rejectionKey(
            original: pending.normalizedOriginal,
            replacement: pending.normalizedReplacement
        )
        rejectedAutocorrections[key, default: 0] += 1
        increaseLearnedFrequency(pending.original, by: 2)
        let promptForDismissal = takeAutocorrectionPromptForAnimation()
        promptForDismissal?.animateDismissal()
    }

    private func rejectionKey(original: String, replacement: String) -> String {
        original.lowercased() + "\u{1f}" + replacement.lowercased()
    }

    private func currentTouchEvidenceASCIIString() -> String {
        String(bytes: currentWordTouchEvidence.map(\.committedLowercaseASCII), encoding: .utf8) ?? ""
    }

    private func recordAutocorrectionTouchEvidence(
        _ evidence: OldOSZephyrAutocorrectionTouchEvidence?,
        forCommittedText text: String
    ) {
        guard let scalar = text.lowercased().unicodeScalars.first,
              text.lowercased().unicodeScalars.count == 1,
              scalar.value >= 97,
              scalar.value <= 122
        else {
            currentWordTouchEvidence.removeAll(keepingCapacity: true)
            pendingZephyrErasedKeyHistory.removeAll(keepingCapacity: true)
            return
        }

        let liveSurface = OldOSZephyrStaticLanguageModel.currentAutocorrectionSurfacePrefix(
            in: textBeforeCursor()
        )
        let liveKey = OldOSZephyrStaticLanguageModel.autocorrectionLookupKey(for: liveSurface) ?? ""
        if liveKey != currentTouchEvidenceASCIIString() {
            currentWordTouchEvidence.removeAll(keepingCapacity: true)
            pendingZephyrErasedKeyHistory.removeAll(keepingCapacity: true)
        }

        guard let evidence,
              evidence.committedLowercaseASCII == UInt8(scalar.value)
        else {

            currentWordTouchEvidence.removeAll(keepingCapacity: true)
            pendingZephyrErasedKeyHistory.removeAll(keepingCapacity: true)
            return
        }
        let enrichedEvidence = evidence.withErasedKeyHistory(pendingZephyrErasedKeyHistory)
        currentWordTouchEvidence.append(enrichedEvidence)
        pendingZephyrErasedKeyHistory.removeAll(keepingCapacity: true)
    }

    private func updateTouchEvidenceForBackwardDelete() {
        let liveSurface = OldOSZephyrStaticLanguageModel.currentAutocorrectionSurfacePrefix(
            in: textBeforeCursor()
        )
        guard let liveKey = OldOSZephyrStaticLanguageModel.autocorrectionLookupKey(for: liveSurface),
              liveKey == currentTouchEvidenceASCIIString(),
              let erasedEvidence = currentWordTouchEvidence.last
        else {
            currentWordTouchEvidence.removeAll(keepingCapacity: true)
            pendingZephyrErasedKeyHistory.removeAll(keepingCapacity: true)
            return
        }

        if pendingZephyrErasedKeyHistory.count > 1 {
            pendingZephyrErasedKeyHistory.removeFirst()
        }
        pendingZephyrErasedKeyHistory.append(erasedEvidence.committedLowercaseASCII)
        currentWordTouchEvidence.removeLast()
    }

    private struct TouchAlignmentQuality {
        let editCount: Int
        let relativePhysicalLogLikelihood: Double
        let spellingOperationLogLikelihood: Double
        let sortKeyOnlyExtensions: Int
        let repeatedInputDrops: Int
        let arbitraryInputDrops: Int
        let substitutions: Int
        let transpositions: Int
    }

    private func betterTouchAlignment(
        _ lhs: TouchAlignmentQuality?,
        _ rhs: TouchAlignmentQuality
    ) -> TouchAlignmentQuality {
        guard let lhs else { return rhs }
        if rhs.editCount != lhs.editCount {
            return rhs.editCount < lhs.editCount ? rhs : lhs
        }

        if rhs.arbitraryInputDrops != lhs.arbitraryInputDrops {
            return rhs.arbitraryInputDrops < lhs.arbitraryInputDrops ? rhs : lhs
        }
        let rhsPathScore = rhs.relativePhysicalLogLikelihood
            + OldOSZephyrHitTester.letterTypingSpellPowerPhone * rhs.spellingOperationLogLikelihood
        let lhsPathScore = lhs.relativePhysicalLogLikelihood
            + OldOSZephyrHitTester.letterTypingSpellPowerPhone * lhs.spellingOperationLogLikelihood
        if rhsPathScore != lhsPathScore {
            return rhsPathScore > lhsPathScore ? rhs : lhs
        }
        if rhs.sortKeyOnlyExtensions != lhs.sortKeyOnlyExtensions {
            return rhs.sortKeyOnlyExtensions < lhs.sortKeyOnlyExtensions ? rhs : lhs
        }
        return rhs
    }

    private func sourceTouchAlignmentQuality(
        for candidate: OldOSZephyrStaticLanguageModel.AutocorrectionCandidate,
        original: String
    ) -> TouchAlignmentQuality? {
        guard let originalKey = OldOSZephyrStaticLanguageModel.autocorrectionLookupKey(for: original)
        else { return nil }

        let input = Array(originalKey.utf8)
        let output = Array(candidate.sortKey.utf8)
        let hasLiveTouchEvidence = input.count == currentWordTouchEvidence.count
            && zip(input, currentWordTouchEvidence).allSatisfy({ $0.0 == $0.1.committedLowercaseASCII })

        let sortKeyExtensionProbability: (Int) -> Double = { prefixLength in
            let table: [Double] = [0.001, 0.03, 0.0005, 0.0004, 0.0005, 0.0006]
            return table[min(max(0, prefixLength), table.count - 1)]
        }

        let unknownOrdinaryLetterProbability = 0.00004

        let zero = TouchAlignmentQuality(
            editCount: 0,
            relativePhysicalLogLikelihood: 0,
            spellingOperationLogLikelihood: 0,
            sortKeyOnlyExtensions: 0,
            repeatedInputDrops: 0,
            arbitraryInputDrops: 0,
            substitutions: 0,
            transpositions: 0
        )
        var table = Array(
            repeating: Array<TouchAlignmentQuality?>(repeating: nil, count: output.count + 1),
            count: input.count + 1
        )
        table[0][0] = zero

        func droppingInput(_ previous: TouchAlignmentQuality, at inputIndex: Int, outputIndex: Int) -> TouchAlignmentQuality {
            let dropped = input[inputIndex]
            let repeatsPrevious = inputIndex > 0 && input[inputIndex - 1] == dropped
            let repeatsNext = inputIndex + 1 < input.count && input[inputIndex + 1] == dropped
            let repeatsOutputLeft = outputIndex > 0 && output[outputIndex - 1] == dropped
            let repeated = repeatsPrevious || repeatsNext || repeatsOutputLeft
            return TouchAlignmentQuality(
                editCount: previous.editCount + 1,
                relativePhysicalLogLikelihood: previous.relativePhysicalLogLikelihood,
                spellingOperationLogLikelihood: previous.spellingOperationLogLikelihood
                    + log(unknownOrdinaryLetterProbability),
                sortKeyOnlyExtensions: previous.sortKeyOnlyExtensions,
                repeatedInputDrops: previous.repeatedInputDrops + (repeated ? 1 : 0),
                arbitraryInputDrops: previous.arbitraryInputDrops + (repeated ? 0 : 1),
                substitutions: previous.substitutions,
                transpositions: previous.transpositions
            )
        }

        if !input.isEmpty {
            for i in 1...input.count {
                if let previous = table[i - 1][0] {
                    table[i][0] = droppingInput(previous, at: i - 1, outputIndex: 0)
                }
            }
        }
        if !output.isEmpty {
            for j in 1...output.count {
                if let previous = table[0][j - 1] {
                    table[0][j] = TouchAlignmentQuality(
                        editCount: previous.editCount + 1,
                        relativePhysicalLogLikelihood: previous.relativePhysicalLogLikelihood,
                        spellingOperationLogLikelihood: previous.spellingOperationLogLikelihood
                            + log(sortKeyExtensionProbability(j - 1)),
                        sortKeyOnlyExtensions: previous.sortKeyOnlyExtensions + 1,
                        repeatedInputDrops: previous.repeatedInputDrops,
                        arbitraryInputDrops: previous.arbitraryInputDrops,
                        substitutions: previous.substitutions,
                        transpositions: previous.transpositions
                    )
                }
            }
        }

        if !input.isEmpty, !output.isEmpty {
            for i in 1...input.count {
                for j in 1...output.count {
                    var best: TouchAlignmentQuality?

                    if let previous = table[i - 1][j] {
                        best = betterTouchAlignment(best, droppingInput(previous, at: i - 1, outputIndex: j))
                    }

                    if let previous = table[i][j - 1] {
                        best = betterTouchAlignment(
                            best,
                            TouchAlignmentQuality(
                                editCount: previous.editCount + 1,
                                relativePhysicalLogLikelihood: previous.relativePhysicalLogLikelihood,
                                spellingOperationLogLikelihood: previous.spellingOperationLogLikelihood
                                    + log(sortKeyExtensionProbability(j - 1)),
                                sortKeyOnlyExtensions: previous.sortKeyOnlyExtensions + 1,
                                repeatedInputDrops: previous.repeatedInputDrops,
                                arbitraryInputDrops: previous.arbitraryInputDrops,
                                substitutions: previous.substitutions,
                                transpositions: previous.transpositions
                            )
                        )
                    }

                    if let previous = table[i - 1][j - 1] {
                        let same = input[i - 1] == output[j - 1]
                        let physicalDelta: Double
                        if same || !hasLiveTouchEvidence {
                            physicalDelta = 0
                        } else {
                            physicalDelta = currentWordTouchEvidence[i - 1]
                                .relativePhysicalLogLikelihood(for: output[j - 1]) ?? -Double.infinity
                        }
                        if physicalDelta.isFinite {
                            best = betterTouchAlignment(
                                best,
                                TouchAlignmentQuality(
                                    editCount: previous.editCount + (same ? 0 : 1),
                                    relativePhysicalLogLikelihood: previous.relativePhysicalLogLikelihood + physicalDelta,
                                    spellingOperationLogLikelihood: previous.spellingOperationLogLikelihood,
                                    sortKeyOnlyExtensions: previous.sortKeyOnlyExtensions,
                                    repeatedInputDrops: previous.repeatedInputDrops,
                                    arbitraryInputDrops: previous.arbitraryInputDrops,
                                    substitutions: previous.substitutions + (same ? 0 : 1),
                                    transpositions: previous.transpositions
                                )
                            )
                        }
                    }

                    if i >= 2,
                       j >= 2,
                       input[i - 2] == output[j - 1],
                       input[i - 1] == output[j - 2],
                       let previous = table[i - 2][j - 2] {
                        best = betterTouchAlignment(
                            best,
                            TouchAlignmentQuality(
                                editCount: previous.editCount + 1,
                                relativePhysicalLogLikelihood: previous.relativePhysicalLogLikelihood,
                                spellingOperationLogLikelihood: previous.spellingOperationLogLikelihood,
                                sortKeyOnlyExtensions: previous.sortKeyOnlyExtensions,
                                repeatedInputDrops: previous.repeatedInputDrops,
                                arbitraryInputDrops: previous.arbitraryInputDrops,
                                substitutions: previous.substitutions,
                                transpositions: previous.transpositions + 1
                            )
                        )
                    }

                    table[i][j] = best
                }
            }
        }

        return table[input.count][output.count]
    }

    private func sourceTouchRelativeLogLikelihood(
        for candidate: OldOSZephyrStaticLanguageModel.AutocorrectionCandidate,
        original: String
    ) -> Double? {
        sourceTouchAlignmentQuality(for: candidate, original: original)?.relativePhysicalLogLikelihood
    }

    private func sourceCandidateOmegaLog(
        _ candidate: OldOSZephyrStaticLanguageModel.AutocorrectionCandidate,
        original: String
    ) -> Double {

        if let liveOmega = candidate.ztOmegaLogLikelihood {
            return liveOmega
        }
        let path = sourceTouchAlignmentQuality(for: candidate, original: original)
        let touchLog = path?.relativePhysicalLogLikelihood ?? 0
        return touchLog
            + OldOSZephyrHitTester.letterTypingSpellPowerPhone * candidate.lexicalScore
    }

    private func sourceCandidateSortsBefore(
        _ lhs: OldOSZephyrStaticLanguageModel.AutocorrectionCandidate,
        _ rhs: OldOSZephyrStaticLanguageModel.AutocorrectionCandidate,
        original: String
    ) -> Bool {
        let lhsSpellFallback = lhs.ztCameFromSpellFallback
        let rhsSpellFallback = rhs.ztCameFromSpellFallback

        if !lhsSpellFallback && !rhsSpellFallback {
            if lhs.ztErasedStrokeCount != rhs.ztErasedStrokeCount {
                return lhs.ztErasedStrokeCount < rhs.ztErasedStrokeCount
            }

            let lhsOmegaLog = sourceCandidateOmegaLog(lhs, original: original)
            let rhsOmegaLog = sourceCandidateOmegaLog(rhs, original: original)
            if lhsOmegaLog != rhsOmegaLog { return lhsOmegaLog > rhsOmegaLog }

            if lhs.ztPredictedSymbolCount != rhs.ztPredictedSymbolCount {
                return lhs.ztPredictedSymbolCount < rhs.ztPredictedSymbolCount
            }
        } else if lhsSpellFallback && rhsSpellFallback {

            let lhsPath = sourceTouchAlignmentQuality(for: lhs, original: original)
            let rhsPath = sourceTouchAlignmentQuality(for: rhs, original: original)

            if let lhsPath, let rhsPath,
               lhsPath.arbitraryInputDrops != rhsPath.arbitraryInputDrops {
                return lhsPath.arbitraryInputDrops < rhsPath.arbitraryInputDrops
            }

            let lhsOmegaLog = sourceCandidateOmegaLog(lhs, original: original)
            let rhsOmegaLog = sourceCandidateOmegaLog(rhs, original: original)
            if lhsOmegaLog != rhsOmegaLog { return lhsOmegaLog > rhsOmegaLog }

            if let lhsPath, let rhsPath,
               lhsPath.sortKeyOnlyExtensions != rhsPath.sortKeyOnlyExtensions {
                return lhsPath.sortKeyOnlyExtensions < rhsPath.sortKeyOnlyExtensions
            }

            if let lhsQuality = lhs.spellCheckQuality,
               let rhsQuality = rhs.spellCheckQuality,
               lhsQuality != rhsQuality {
                return lhsQuality > rhsQuality
            }
        } else {

            return !lhsSpellFallback
        }

        if lhs.editDistance != rhs.editDistance { return lhs.editDistance < rhs.editDistance }
        if lhs.lexicalScore != rhs.lexicalScore { return lhs.lexicalScore > rhs.lexicalScore }
        if lhs.surfaceOrder != rhs.surfaceOrder { return lhs.surfaceOrder < rhs.surfaceOrder }
        return lhs.word < rhs.word
    }

    private func sourceRankedCandidates(
        _ candidates: [OldOSZephyrStaticLanguageModel.AutocorrectionCandidate],
        original: String
    ) -> [OldOSZephyrStaticLanguageModel.AutocorrectionCandidate] {
        candidates.sorted { lhs, rhs in

            if lhs.isDynamic || rhs.isDynamic {
                if lhs.isDynamic != rhs.isDynamic,
                   lhs.word.caseInsensitiveCompare(rhs.word) == .orderedSame {
                    return !lhs.isDynamic
                }
                if lhs.isDynamic && rhs.isDynamic,
                   lhs.dynamicUserFrequency != rhs.dynamicUserFrequency {
                    return lhs.dynamicUserFrequency > rhs.dynamicUserFrequency
                }
            }
            return sourceCandidateSortsBefore(lhs, rhs, original: original)
        }
    }

    private func selectQualityCandidate(
        _ candidates: [OldOSZephyrStaticLanguageModel.AutocorrectionCandidate],
        for original: String
    ) -> OldOSZephyrStaticLanguageModel.AutocorrectionCandidate? {
        let viable = candidates.filter { candidate in
            guard passesSourceCandidateFilters(candidate.word, original: original) else { return false }
            let key = rejectionKey(original: original, replacement: candidate.word)
            return rejectedAutocorrections[key, default: 0] < 3
        }
        guard !viable.isEmpty else { return nil }

        let ranked = sourceRankedCandidates(viable, original: original)

        guard let first = ranked.first else { return nil }

        if dynamicDictionaryAcceptsExactWord(original) {
            return nil
        }

        let inputStringsExactlyEqual = true
        let firstDisplay = applySourceCaseChanges(first, matching: original)
        if inputStringsExactlyEqual && firstDisplay == original {
            return nil
        }

        let matchesRememberedCandidate = firstDisplay == qualityFilterRememberedCandidate

        guard sourceFirstCandidateIsSignificantlyBetter(
            ranked,
            comparisonString: original,
            inputStringsExactlyEqual: inputStringsExactlyEqual,
            matchesRememberedCandidate: matchesRememberedCandidate
        ) else {
            return nil
        }

        qualityFilterRememberedCandidate = firstDisplay
        return first
    }

    private func sourceFirstCandidateIsSignificantlyBetter(
        _ candidates: [OldOSZephyrStaticLanguageModel.AutocorrectionCandidate],
        comparisonString: String,
        inputStringsExactlyEqual: Bool,
        matchesRememberedCandidate: Bool
    ) -> Bool {
        guard let first = candidates.first else { return false }

        let firstDisplay = applySourceCaseChanges(first, matching: comparisonString)
        let special = sourceHasPrecomposedDiacriticLetters(firstDisplay)
            || sourceHasSeparatedDiacritics(firstDisplay)
            || sourceContainsWordMedialPunctuation(firstDisplay)

        let inputLength = sourceStringLength(comparisonString)
        let candidateLength = sourceStringLength(firstDisplay)
        let delta = candidateLength - inputLength

        let startsWithInput = firstDisplay.hasPrefix(comparisonString)

        var completionGateOK = true
        if !special && startsWithInput && !matchesRememberedCandidate {
            let minimumInputLength: Int
            if delta <= 1 {
                minimumInputLength = 8
            } else if delta == 2 {
                minimumInputLength = 6
            } else {
                minimumInputLength = 4
            }
            completionGateOK = inputLength >= minimumInputLength
        }

        if candidates.count == 1 && completionGateOK { return true }
        if !inputStringsExactlyEqual { return true }

        if startsWithInput {
            return sourceQualityDominancePasses(
                candidates,
                original: comparisonString,
                completionGateOK: completionGateOK
            )
        }

        if delta <= 0 { return true }
        if special { return true }

        return sourceQualityDominancePasses(
            candidates,
            original: comparisonString,
            completionGateOK: completionGateOK
        )
    }

    private func sourceQualityDominancePasses(
        _ candidates: [OldOSZephyrStaticLanguageModel.AutocorrectionCandidate],
        original: String,
        completionGateOK: Bool
    ) -> Bool {
        guard candidates.count > 1, completionGateOK else { return false }

        let first = candidates[0]
        let second = candidates[1]

        let firstDisplay = applySourceCaseChanges(first, matching: original)
        let secondDisplay = applySourceCaseChanges(second, matching: original)
        if firstDisplay.caseInsensitiveCompare(secondDisplay) == .orderedSame {
            return true
        }

        let firstOmegaLog = sourceCandidateOmegaLog(first, original: original)
        let secondOmegaLog = sourceCandidateOmegaLog(second, original: original)
        guard firstOmegaLog.isFinite, secondOmegaLog.isFinite else { return false }

        return (firstOmegaLog - secondOmegaLog) > log(2.7)
    }

    private func sourceStringLength(_ value: String) -> Int {
        value.unicodeScalars.count
    }

    private func sourceContainsWordMedialPunctuation(_ value: String) -> Bool {
        value.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x27, 0x2019, 0x26, 0x05F3, 0x05F4:
                return true
            default:
                return false
            }
        }
    }

    private func sourceHasPrecomposedDiacriticLetters(_ value: String) -> Bool {
        value.unicodeScalars.contains { scalar in
            guard CharacterSet.letters.contains(scalar) else { return false }
            return String(scalar).decomposedStringWithCanonicalMapping.unicodeScalars.count > 1
        }
    }

    private func sourceHasSeparatedDiacritics(_ value: String) -> Bool {
        value.unicodeScalars.contains { CharacterSet.nonBaseCharacters.contains($0) }
    }

    private func sourceIsSingleAdjacentTransposition(_ lhs: [UInt8], _ rhs: [UInt8]) -> Bool {
        guard lhs.count == rhs.count, lhs.count >= 2 else { return false }
        var mismatches: [Int] = []
        for index in lhs.indices where lhs[index] != rhs[index] {
            mismatches.append(index)
            if mismatches.count > 2 { return false }
        }
        guard mismatches.count == 2,
              mismatches[1] == mismatches[0] + 1
        else { return false }
        let a = mismatches[0]
        let b = mismatches[1]
        return lhs[a] == rhs[b] && lhs[b] == rhs[a]
    }

    private func passesSourceCandidateFilters(_ candidate: String, original: String) -> Bool {
        guard !candidate.isEmpty else { return false }
        var apostrophes = 0
        for scalar in candidate.unicodeScalars {
            if scalar.value >= 97 && scalar.value <= 122 { continue }
            if scalar.value >= 65 && scalar.value <= 90 { continue }
            if scalar.value == 0x27 || scalar.value == 0x2019 { apostrophes += 1; continue }
            return false
        }
        return apostrophes <= 1 && !original.isEmpty
    }

    private func sourceWordMedialPunctuationCount(_ value: String) -> Int {
        value.unicodeScalars.reduce(into: 0) { count, scalar in
            switch scalar.value {
            case 0x27, 0x2019, 0x26, 0x05F3, 0x05F4:
                count += 1
            default:
                break
            }
        }
    }

    private func applySourceMismatchFilters(
        _ candidates: [OldOSZephyrStaticLanguageModel.AutocorrectionCandidate],
        original: String
    ) -> [OldOSZephyrStaticLanguageModel.AutocorrectionCandidate] {
        guard let normalized = OldOSZephyrStaticLanguageModel.autocorrectionLookupKey(for: original)
        else { return [] }

        var filtered = candidates.filter { passesSourceCandidateFilters($0.word, original: original) }

        let inputPunctuation = sourceWordMedialPunctuationCount(original)
        if inputPunctuation > 0 {
            filtered = filtered.filter {
                sourceWordMedialPunctuationCount($0.word) >= inputPunctuation
            }
        }

        if filtered.contains(where: { $0.sortKey == normalized }) {
            filtered = filtered.filter { $0.sortKey == normalized }
        }

        return filtered
    }

    private func deduplicatedCandidates(
        _ candidates: [OldOSZephyrStaticLanguageModel.AutocorrectionCandidate]
    ) -> [OldOSZephyrStaticLanguageModel.AutocorrectionCandidate] {
        var best: [String: OldOSZephyrStaticLanguageModel.AutocorrectionCandidate] = [:]
        for candidate in candidates {

            let key = candidate.word.lowercased()
                + "\u{1f}" + candidate.sortKey
                + "\u{1f}" + (candidate.isDynamic ? "D" : "S")
            if let existing = best[key] {
                let candidateLive = candidate.ztOmegaLogLikelihood != nil
                let existingLive = existing.ztOmegaLogLikelihood != nil
                let candidateBetter: Bool
                if candidateLive != existingLive {
                    candidateBetter = candidateLive
                } else if let candidateOmega = candidate.ztOmegaLogLikelihood,
                          let existingOmega = existing.ztOmegaLogLikelihood,
                          candidateOmega != existingOmega {
                    candidateBetter = candidateOmega > existingOmega
                } else {
                    candidateBetter = candidate.editDistance < existing.editDistance
                        || (candidate.editDistance == existing.editDistance
                            && candidate.dynamicUserFrequency > existing.dynamicUserFrequency)
                        || (candidate.editDistance == existing.editDistance
                            && candidate.dynamicUserFrequency == existing.dynamicUserFrequency
                            && candidate.lexicalScore > existing.lexicalScore)
                        || (candidate.editDistance == existing.editDistance
                            && candidate.dynamicUserFrequency == existing.dynamicUserFrequency
                            && candidate.lexicalScore == existing.lexicalScore
                            && candidate.surfaceOrder < existing.surfaceOrder)
                }
                if candidateBetter { best[key] = candidate }
            } else {
                best[key] = candidate
            }
        }
        return Array(best.values)
    }

    private func dynamicLearningKey(_ surface: String) -> String {
        surface.replacingOccurrences(of: "’", with: "'")
            .precomposedStringWithCanonicalMapping
    }

    private func dynamicDictionaryAcceptsExactWord(_ surface: String) -> Bool {

        learnedWordFrequencies[dynamicLearningKey(surface), default: 0] > 2
    }

    private func dynamicAutocorrectionCandidates(
        for originalSurface: String
    ) -> [OldOSZephyrStaticLanguageModel.AutocorrectionCandidate] {
        guard let originalSortKey = OldOSZephyrStaticLanguageModel.autocorrectionLookupKey(for: originalSurface)
        else { return [] }
        let maximum = originalSortKey.utf8.count == 1 ? 0 : (originalSortKey.utf8.count >= 7 ? 2 : 1)
        var result: [OldOSZephyrStaticLanguageModel.AutocorrectionCandidate] = []

        for (learnedSurface, frequency) in learnedWordFrequencies where frequency > 2 {
            guard dynamicLearningKey(learnedSurface) != dynamicLearningKey(originalSurface),
                  let learnedSortKey = OldOSZephyrStaticLanguageModel.autocorrectionLookupKey(for: learnedSurface),
                  learnedSortKey.utf8.allSatisfy({ $0 >= 97 && $0 <= 122 }),
                  let distance = boundedOSADistance(originalSortKey, learnedSortKey, maximum: maximum)
            else { continue }

            result.append(.init(
                word: learnedSurface,
                sortKey: learnedSortKey,
                editDistance: distance,
                lexicalScore: -Double(distance),
                isDynamic: true,
                dynamicUserFrequency: frequency
            ))
        }
        return result
    }

    private func boundedOSADistance(_ lhs: String, _ rhs: String, maximum: Int) -> Int? {
        let a = Array(lhs.utf8), b = Array(rhs.utf8)
        guard abs(a.count - b.count) <= maximum else { return nil }
        var previousPrevious: [Int]? = nil
        var previous = Array(0...b.count)
        var previousByte: UInt8? = nil
        for (i0, ca) in a.enumerated() {
            var current = Array(repeating: 0, count: b.count + 1)
            current[0] = i0 + 1
            var rowMinimum = current[0]
            if !b.isEmpty {
                for j in 1...b.count {
                    let cost = ca == b[j - 1] ? 0 : 1
                    var value = min(current[j - 1] + 1, previous[j] + 1, previous[j - 1] + cost)
                    if i0 > 0, j > 1,
                       let pp = previousPrevious,
                       let pb = previousByte,
                       ca == b[j - 2], pb == b[j - 1] {
                        value = min(value, pp[j - 2] + 1)
                    }
                    current[j] = value
                    rowMinimum = min(rowMinimum, value)
                }
            }
            if rowMinimum > maximum { return nil }
            previousPrevious = previous
            previous = current
            previousByte = ca
        }
        let distance = previous[b.count]
        return distance <= maximum ? distance : nil
    }

    private func learnCurrentTypedWordIfAppropriate() {
        guard autocorrectionIsAllowedForCurrentInput,
              let context = currentAutocorrectionWordContext(),
              context.normalized.utf8.count >= 2
        else { return }
        increaseLearnedFrequency(context.original, by: 1)
    }

    private func increaseLearnedFrequency(_ word: String, by amount: Int) {
        let key = dynamicLearningKey(word)
        guard !key.isEmpty else { return }
        learnedWordFrequencies[key, default: 0] = max(0, learnedWordFrequencies[key, default: 0] + amount)
        UserDefaults.standard.set(learnedWordFrequencies, forKey: learnedDictionaryDefaultsKey)
    }

    private func applySourceCaseChanges(
        _ candidate: OldOSZephyrStaticLanguageModel.AutocorrectionCandidate,
        matching original: String
    ) -> String {
        var result = candidate.word

        let originalLetters = original.filter { $0.isLetter }
        if originalLetters.count > 1,
           originalLetters == originalLetters.uppercased(),
           originalLetters != originalLetters.lowercased() {
            return result.uppercased()
        }

        if candidate.hasDictionaryCapitalization {
            return result
        }

        if let first = original.first, first.isUppercase,
           let resultFirst = result.first {
            result = String(resultFirst).uppercased() + String(result.dropFirst())
        }
        return result
    }

    private func autocorrectionAppearance(for inputView: UIView) -> OldOSAutocorrectPromptView.Appearance {

        let className = NSStringFromClass(type(of: inputView))
        if className.contains("DALinedTextView") { return .notes }
        if let textView = inputView as? UITextView,
           textView.font?.fontName.lowercased().contains("noteworthy") == true {
            return .notes
        }
        return .standard
    }

    private func autocorrectionDocumentBackgroundColor(
        for inputView: UIView,
        appearance: OldOSAutocorrectPromptView.Appearance
    ) -> UIColor {
        if appearance == .notes {

            _ = inputView
            return OldOSAutocorrectPromptView.notesTextureColor(
                fallback: UIColor(red: 246/255, green: 232/255, blue: 158/255, alpha: 1)
            )
        }
        return .white
    }

    private struct AutocorrectionPromptGeometry {
        let frame: CGRect
        let typedWidth: CGFloat
        let typedHeight: CGFloat
        let typedTextLeftInset: CGFloat
        let typedOriginX: CGFloat
        let correctionWidth: CGFloat
        let correctionOriginX: CGFloat
        let placement: OldOSAutocorrectPromptView.Placement
    }

    private func autocorrectionVisibleEditorRect(
        for inputView: UIView,
        in window: UIWindow,
        lcd: CGRect
    ) -> CGRect? {
        let localRect: CGRect
        if let textField = inputView as? UITextField {
            let editing = textField.editingRect(forBounds: textField.bounds)
            localRect = editing.width > 0 && editing.height > 0
                ? editing
                : textField.textRect(forBounds: textField.bounds)
        } else {

            localRect = inputView.bounds
        }

        var visible = inputView.convert(localRect, to: window)
        guard !visible.isNull,
              !visible.isInfinite,
              visible.origin.x.isFinite,
              visible.origin.y.isFinite,
              visible.width > 0,
              visible.height > 0
        else { return nil }

        var ancestor = inputView.superview
        while let view = ancestor, view !== window {
            if view.clipsToBounds || view is UIScrollView {
                let clip = view.convert(view.bounds, to: window)
                if !clip.isNull, !clip.isInfinite, clip.width > 0, clip.height > 0 {
                    visible = visible.intersection(clip)
                    if visible.isNull || visible.width <= 0 || visible.height <= 0 {
                        return nil
                    }
                }
            }
            ancestor = view.superview
        }

        visible = visible.intersection(lcd)
        guard !visible.isNull,
              visible.width > 0,
              visible.height > 0
        else { return nil }
        return visible
    }

    private func autocorrectionPromptGeometry(
        replacement: String,
        typedText: String,
        wordRange: UITextRange,
        inputView: UIView,
        field: UITextInput,
        window: UIWindow,
        appearance: OldOSAutocorrectPromptView.Appearance
    ) -> AutocorrectionPromptGeometry? {
        let localWordRect = field.firstRect(for: wordRange)
        guard !localWordRect.isNull,
              !localWordRect.isInfinite,
              localWordRect.origin.x.isFinite,
              localWordRect.origin.y.isFinite,
              localWordRect.size.width.isFinite,
              localWordRect.size.height.isFinite,
              localWordRect.width >= 0,
              localWordRect.height >= 0
        else { return nil }

        let wordRect = inputView.convert(localWordRect, to: window)
        let localCaretRect = field.caretRect(for: wordRange.end)
        let convertedCaretRect = inputView.convert(localCaretRect, to: window)
        let hasUsableCaret = !convertedCaretRect.isNull
            && !convertedCaretRect.isInfinite
            && convertedCaretRect.minX.isFinite
            && convertedCaretRect.minY.isFinite
            && convertedCaretRect.height > 0

        let rawCaretX = hasUsableCaret ? convertedCaretRect.minX : wordRect.maxX
        guard rawCaretX.isFinite else { return nil }

        let typedHeight = max(
            18,
            min(
                30,
                ceil(
                    max(
                        wordRect.height,
                        max(hasUsableCaret ? convertedCaretRect.height : 0, 22)
                    )
                )
            )
        )

        let hasAuthoritativeEditorFont: Bool
        let typedFont: UIFont
        if let textField = inputView as? UITextField, let font = textField.font {
            typedFont = font
            hasAuthoritativeEditorFont = true
        } else if let textView = inputView as? UITextView, let font = textView.font {
            typedFont = font
            hasAuthoritativeEditorFont = true
        } else {

            typedFont = UIFont(name: "Helvetica", size: 17) ?? UIFont.systemFont(ofSize: 17)
            hasAuthoritativeEditorFont = false
        }
        let renderedTextWidth = ceil(
            (typedText as NSString).size(withAttributes: [.font: typedFont]).width
        )

        let lcd = simulatedLCDFrameInWindow ?? window.bounds
        guard let editorVisible = autocorrectionVisibleEditorRect(
            for: inputView,
            in: window,
            lcd: lcd
        ) else { return nil }

        let editorMinX = max(editorVisible.minX, lcd.minX)
        let editorMaxX = min(editorVisible.maxX, lcd.maxX)
        guard editorMaxX > editorMinX else { return nil }

        let textFieldCaretWasOutsideVisibleRect = inputView is UITextField
            && (rawCaretX < editorMinX || rawCaretX > editorMaxX)
        let caretX: CGFloat
        if inputView is UITextField {
            caretX = min(max(rawCaretX, editorMinX), editorMaxX)
        } else {
            caretX = rawCaretX
        }

        let liveAdvance = caretX - wordRect.minX
        let sameLine: Bool = {
            guard hasUsableCaret else { return true }
            let tolerance = max(2, typedHeight * 0.60)
            return abs(convertedCaretRect.midY - wordRect.midY) <= tolerance
        }()
        let advanceTolerance = max(4, renderedTextWidth * 0.25)
        let sourceTextLeftX: CGFloat
        if textFieldCaretWasOutsideVisibleRect, hasAuthoritativeEditorFont {
            sourceTextLeftX = caretX - renderedTextWidth
        } else if sameLine, liveAdvance > 0,
                  (!hasAuthoritativeEditorFont
                    || abs(liveAdvance - renderedTextWidth) <= advanceTolerance) {
            sourceTextLeftX = wordRect.minX
        } else if hasAuthoritativeEditorFont {
            sourceTextLeftX = caretX - renderedTextWidth
        } else {

            sourceTextLeftX = liveAdvance > 0
                ? wordRect.minX
                : caretX - renderedTextWidth
        }

        let sourceLineRect: CGRect = {
            if hasUsableCaret, convertedCaretRect.height > 0 {
                return CGRect(
                    x: caretX,
                    y: convertedCaretRect.minY,
                    width: max(1, convertedCaretRect.width),
                    height: convertedCaretRect.height
                )
            }
            return wordRect
        }()
        let verticalTolerance: CGFloat = 1
        guard sourceLineRect.maxY >= editorVisible.minY - verticalTolerance,
              sourceLineRect.minY <= editorVisible.maxY + verticalTolerance
        else { return nil }

        let sourceInset: CGFloat = 1.5
        let typedTrailingOverhang: CGFloat = 1.0
        let naturalTypedLeft = sourceTextLeftX - sourceInset
        let naturalTypedRight = caretX + typedTrailingOverhang
        let typedLeftX = max(naturalTypedLeft, editorMinX)
        let typedRightX = min(naturalTypedRight, editorMaxX)
        guard typedRightX > typedLeftX else { return nil }

        let typedWidth = typedRightX - typedLeftX

        let typedTextLeftInset = sourceTextLeftX - typedLeftX

        let naturalCorrectionWidth = OldOSAutocorrectPromptView.naturalCorrectionWidth(
            for: replacement,
            appearance: appearance
        )

        let correctionMinX = editorMinX
        let correctionMaxX = editorMaxX
        let usableCorrectionSpan = max(0, correctionMaxX - correctionMinX)
        guard usableCorrectionSpan > 0 else { return nil }

        let correctionWidth = min(naturalCorrectionWidth, usableCorrectionSpan)
        let preferredCorrectionLeftX = typedLeftX
        let latestCorrectionLeftX = correctionMaxX - correctionWidth
        let correctionLeftX = max(
            correctionMinX,
            min(preferredCorrectionLeftX, latestCorrectionLeftX)
        )
        let correctionRightX = correctionLeftX + correctionWidth

        let promptLeftX = min(typedLeftX, correctionLeftX)
        let promptRightX = max(typedRightX, correctionRightX)
        let overallWidth = max(0, promptRightX - promptLeftX)
        let typedOriginX = typedLeftX - promptLeftX
        let correctionOriginX = correctionLeftX - promptLeftX

        let correctionHeight: CGFloat = 30
        let keyboardTop = max(lcd.minY, lcd.maxY - currentHeight)
        let canPlaceBelow = sourceLineRect.maxY + correctionHeight <= keyboardTop
        let placement: OldOSAutocorrectPromptView.Placement = canPlaceBelow
            ? .belowTypedText
            : .aboveTypedText

        var y: CGFloat
        switch placement {
        case .belowTypedText:
            y = sourceLineRect.maxY - typedHeight
        case .aboveTypedText:
            y = sourceLineRect.minY - correctionHeight
        }
        let totalHeight = typedHeight + correctionHeight
        y = min(max(y, lcd.minY), max(lcd.minY, keyboardTop - totalHeight))

        return AutocorrectionPromptGeometry(
            frame: CGRect(
                x: promptLeftX,
                y: y,
                width: overallWidth,
                height: totalHeight
            ),
            typedWidth: typedWidth,
            typedHeight: typedHeight,
            typedTextLeftInset: min(typedTextLeftInset, max(0, typedWidth - 1)),
            typedOriginX: typedOriginX,
            correctionWidth: correctionWidth,
            correctionOriginX: correctionOriginX,
            placement: placement
        )
    }

    private func showAutocorrectionPrompt(
        replacement: String,
        typedText: String,
        wordRange: UITextRange
    ) -> Bool {
        guard let inputView = activeInputView,
              let field = inputView as? UITextInput,
              let window = inputView.window
        else { return false }

        let appearance = autocorrectionAppearance(for: inputView)
        guard let geometry = autocorrectionPromptGeometry(
            replacement: replacement,
            typedText: typedText,
            wordRange: wordRange,
            inputView: inputView,
            field: field,
            window: window,
            appearance: appearance
        ) else { return false }

        autocorrectionPrompt?.removeFromSuperview()
        stopAutocorrectionGeometryTracking()

        let prompt = OldOSAutocorrectPromptView(
            suggestion: replacement,
            typedText: typedText,
            typedWidth: geometry.typedWidth,
            typedHeight: geometry.typedHeight,
            typedTextLeftInset: geometry.typedTextLeftInset,
            typedOriginX: geometry.typedOriginX,
            correctionWidth: geometry.correctionWidth,
            correctionOriginX: geometry.correctionOriginX,
            placement: geometry.placement,
            documentBackgroundColor: autocorrectionDocumentBackgroundColor(
                for: inputView,
                appearance: appearance
            ),
            appearance: appearance
        )
        prompt.frame = geometry.frame
        prompt.onReject = { [weak self] in
            self?.rejectPendingAutocorrection()
        }
        window.addSubview(prompt)
        if inputView is UITextView {
            let lcd = simulatedLCDFrameInWindow ?? window.bounds
            let clip = autocorrectionVisibleEditorRect(for: inputView, in: window, lcd: lcd)
            prompt.setVisibleWindowClipRect(clip, in: window)
        } else {
            prompt.setVisibleWindowClipRect(nil, in: window)
        }
        window.bringSubviewToFront(prompt)
        autocorrectionPrompt = prompt
        startAutocorrectionGeometryTracking(for: inputView)
        return true
    }

    private func startAutocorrectionGeometryTracking(for inputView: UIView) {
        stopAutocorrectionGeometryTracking()

        var scrollViews: [UIScrollView] = []
        var seen: Set<ObjectIdentifier> = []

        func appendScrollView(_ scrollView: UIScrollView) {
            let identifier = ObjectIdentifier(scrollView)
            if seen.insert(identifier).inserted {
                scrollViews.append(scrollView)
            }
        }

        var descendants: [UIView] = [inputView]
        while let current = descendants.popLast() {
            if let scrollView = current as? UIScrollView {
                appendScrollView(scrollView)
            }
            descendants.append(contentsOf: current.subviews)
        }

        var ancestor = inputView.superview
        while let current = ancestor {
            if let scrollView = current as? UIScrollView {
                appendScrollView(scrollView)
            }
            ancestor = current.superview
        }

        autocorrectionScrollObservations = scrollViews.map { scrollView in
            scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
                DispatchQueue.main.async { [weak self] in
                    self?.scheduleAutocorrectionPromptReanchor()
                }
            }
        }
    }

    private func stopAutocorrectionGeometryTracking() {
        autocorrectionScrollObservations.forEach { $0.invalidate() }
        autocorrectionScrollObservations.removeAll(keepingCapacity: true)
        autocorrectionReanchorScheduled = false
    }

    private func scheduleAutocorrectionPromptReanchor() {
        guard autocorrectionPrompt != nil,
              !autocorrectionReanchorScheduled
        else { return }
        autocorrectionReanchorScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.autocorrectionReanchorScheduled = false
            self.reanchorAutocorrectionPromptIfNeeded()
        }
    }

    private func reanchorAutocorrectionPromptIfNeeded() {
        guard let prompt = autocorrectionPrompt,
              let pending = pendingAutocorrection,
              let inputView = activeInputView,
              let field = inputView as? UITextInput,
              let window = inputView.window,
              let start = field.position(
                  from: field.beginningOfDocument,
                  offset: pending.startOffset
              ),
              let end = field.position(
                  from: field.beginningOfDocument,
                  offset: pending.endOffset
              ),
              let range = field.textRange(from: start, to: end),
              let current = field.text(in: range),
              current == pending.original
        else {
            autocorrectionPrompt?.isHidden = true
            return
        }

        let appearance = autocorrectionAppearance(for: inputView)
        guard let geometry = autocorrectionPromptGeometry(
            replacement: pending.replacement,
            typedText: pending.original,
            wordRange: range,
            inputView: inputView,
            field: field,
            window: window,
            appearance: appearance
        ) else {
            prompt.isHidden = true
            return
        }

        prompt.isHidden = false
        prompt.updateGeometry(
            typedWidth: geometry.typedWidth,
            typedTextLeftInset: geometry.typedTextLeftInset,
            typedOriginX: geometry.typedOriginX,
            correctionWidth: geometry.correctionWidth,
            correctionOriginX: geometry.correctionOriginX,
            placement: geometry.placement
        )
        prompt.frame = geometry.frame
        if inputView is UITextView {
            let lcd = simulatedLCDFrameInWindow ?? window.bounds
            let clip = autocorrectionVisibleEditorRect(for: inputView, in: window, lcd: lcd)
            prompt.setVisibleWindowClipRect(clip, in: window)
        } else {
            prompt.setVisibleWindowClipRect(nil, in: window)
        }
        prompt.layoutIfNeeded()
        window.bringSubviewToFront(prompt)
    }

    private func takeAutocorrectionPromptForAnimation() -> OldOSAutocorrectPromptView? {
        autocorrectionGeneration &+= 1
        pendingAutocorrection = nil
        stopAutocorrectionGeometryTracking()
        let prompt = autocorrectionPrompt
        autocorrectionPrompt = nil
        return prompt
    }

    private func clearAutocorrection() {
        autocorrectionGeneration &+= 1
        pendingAutocorrection = nil
        stopAutocorrectionGeometryTracking()
        autocorrectionPrompt?.removeFromSuperview()
        autocorrectionPrompt = nil
    }

    func beginShiftTouch(at timestamp: TimeInterval) {
        guard !shiftTouchInProgress else { return }

        shiftTouchInProgress = true
        shiftStateBeforeTouch = shiftState
        shiftOriginBeforeTouch = shiftOrigin

        if configuration.enablesCapsLock,
           shiftLockReady,
           timestamp >= shiftLockFirstTapTime,
           timestamp - shiftLockFirstTapTime < 0.300 {

            shiftLockReady = false
            shiftTouchLockedOnDown = true
            shiftWasShifted = true
            shiftState = .locked
            shiftOrigin = .manual
            return
        }

        shiftLockReady = true
        shiftLockFirstTapTime = timestamp
        shiftTouchLockedOnDown = false
        shiftWasShifted = shiftState != .off
        shiftState = .on
        shiftOrigin = .manual
    }

    func endShiftTouch() {
        guard shiftTouchInProgress else { return }

        if !shiftTouchLockedOnDown {
            shiftState = shiftWasShifted ? .off : .on
            shiftOrigin = .manual
        }

        shiftTouchInProgress = false
        shiftTouchLockedOnDown = false
        playClick()
    }

    func shiftTouchDidSlideOff(keepingShiftForCharacter: Bool) {
        guard shiftTouchInProgress else { return }
        shiftLockReady = false

        if keepingShiftForCharacter {
            shiftState = .on
            shiftOrigin = .manual
        } else {
            shiftState = shiftStateBeforeTouch
            shiftOrigin = shiftOriginBeforeTouch
        }

        shiftTouchInProgress = false
        shiftTouchLockedOnDown = false
    }

    func cancelShiftTouch() {
        guard shiftTouchInProgress else { return }
        shiftLockReady = false
        shiftState = shiftStateBeforeTouch
        shiftOrigin = shiftOriginBeforeTouch
        shiftTouchInProgress = false
        shiftTouchLockedOnDown = false
    }

    private func resetShiftTouchTracking() {
        shiftLockReady = false
        shiftLockFirstTapTime = 0
        shiftTouchInProgress = false
        shiftTouchLockedOnDown = false
        shiftWasShifted = false
        shiftStateBeforeTouch = shiftState
        shiftOriginBeforeTouch = shiftOrigin
    }

    private func tapShift() {
        let now = Date.timeIntervalSinceReferenceDate
        beginShiftTouch(at: now)
        endShiftTouch()
    }

    public var uikitShiftVisualState: Int {
        switch shiftState {
        case .off:
            return 3
        case .locked:
            return 4
        case .on:
            return shiftOrigin == .automatic ? 7 : 6
        }
    }

    var zephyrTextBeforeCursor: String {
        textBeforeCursor()
    }

    private func textBeforeCursor() -> String {
        guard
            let field = activeInputView as? UITextInput,
            let range = field.selectedTextRange
        else { return fieldText }
        return field.text(in: field.textRange(from: field.beginningOfDocument, to: range.start) ?? range) ?? fieldText
    }

    private var fieldText: String {
        guard let field = activeInputView as? UITextInput,
              let fullRange = field.textRange(from: field.beginningOfDocument, to: field.endOfDocument)
        else { return "" }
        return field.text(in: fullRange) ?? ""
    }

    private func refreshReturnKeyEnabled() {
        if configuration.enablesReturnKeyAutomatically {
            returnKeyEnabled = !fieldText.isEmpty
        } else {
            returnKeyEnabled = true
        }
    }

    private func prepareClickSound() {
        guard let url = Bundle.main.url(forResource: "Tock", withExtension: "aiff") else { return }
        clickPlayer = try? AVAudioPlayer(contentsOf: url)
        clickPlayer?.prepareToPlay()
    }

    private func playClick() {
        guard configuration.playsKeyClicks else { return }
        if clickPlayer == nil { prepareClickSound() }
        clickPlayer?.currentTime = 0
        clickPlayer?.play()
    }
}
