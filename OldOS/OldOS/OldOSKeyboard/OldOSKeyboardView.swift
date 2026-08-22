import SwiftUI

public struct OldOSKeyboard: View {
    @ObservedObject private var controller: OldOSKeyboardController

    @State private var activeKeyID: String?

    @State private var activePlacedKey: OldOSKeyboardPlacedKey?
    @State private var variantPlacedKey: OldOSKeyboardPlacedKey?
    @State private var longPressWorkItem: DispatchWorkItem?
    @State private var deleteWorkItem: DispatchWorkItem?
    @State private var deleteTimer: Timer?
    @State private var deleteRepeatCount: Int = 0
    @State private var releaseWorkItem: DispatchWorkItem?
    @State private var variantKeyID: String?
    @State private var selectedVariantIndex: Int = 0
    @State private var activePopupText: String?
    @State private var touchStartTime: TimeInterval?
    @State private var currentTouchPoint: CGPoint?

    @State private var dragReferencePoint: CGPoint?
    @State private var genericHasDragged = false

    @State private var foregroundTouchID: ObjectIdentifier?

    @State private var variantDragOrigin: CGPoint?
    @State private var variantHasDragged = false

    @State private var zephyrLastTouchBeganAt: TimeInterval?
    @State private var zephyrFilteredInterKeyInterval: TimeInterval = 0.35
    @State private var zephyrHasFilteredInterval = false
    @State private var zephyrMajorRadius: CGFloat = 6.5
    @State private var zephyrPriorTouchVectors: [OldOSZephyrPriorTouchVector] = []

    private static let productionZephyrHitTester: OldOSZephyrHitTester = {
        OldOSZephyrHitTester(languageModel: try? OldOSZephyrStaticLanguageModel.bundledUS())
    }()

    private let postReleasePressedVisualTime: TimeInterval = 0.030
    private let longPressDelay: TimeInterval = 0.375
    private let deleteInitialRepeatDelay: TimeInterval = 0.500
    private let deleteRepeatInterval: TimeInterval = 0.100
    private let deleteSustainedRepeatInterval: TimeInterval = 0.350
    private let deleteFastRepeatSwitchCount = 20
    private let initialDragThreshold: CGFloat = 18
    private let subsequentDragThreshold: CGFloat = 12

    private let portraitHitBuffer: CGFloat = 4

    public init(controller: OldOSKeyboardController) {
        self.controller = controller
    }

    public var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / OldOSKeyboardLayout.referenceSize.width
            let keys = OldOSKeyboardLayout.keys(
                plane: controller.keyplane,
                shift: controller.shiftState,
                configuration: controller.configuration,
                returnKeyEnabled: controller.returnKeyEnabled
            )

            ZStack(alignment: .topLeading) {
                OldOSKeyboardBackground(scale: scale)
                    .frame(
                        width: OldOSKeyboardLayout.referenceSize.width * scale,
                        height: OldOSKeyboardLayout.referenceSize.height * scale
                    )

                ForEach(keys) { placed in

                    let popupOwnsSourceKey = activePlacedKey?.id == placed.id &&
                        (variantPlacedKey != nil || placed.key.showsTapPopup)

                    if !popupOwnsSourceKey {
                        keyView(placed, scale: scale)
                    }
                }

                if let active = activePlacedKey,
                   active.key.showsTapPopup,
                   variantPlacedKey == nil {
                    tapPopup(for: active, scale: scale)
                        .allowsHitTesting(false)
                        .zIndex(200)
                }

                if let variant = variantPlacedKey,
                   !variant.key.variants.isEmpty {
                    accentPopover(for: variant, scale: scale)
                        .allowsHitTesting(false)
                        .zIndex(300)
                }

                OldOSKeyboardTouchSurface(logicalScale: scale) { sample in
                    handleNativeTouchSample(sample, keys: keys)
                }
                .frame(
                    width: OldOSKeyboardLayout.referenceSize.width * scale,
                    height: OldOSKeyboardLayout.referenceSize.height * scale
                )
                .zIndex(1000)
            }
        }
        .aspectRatio(
            OldOSKeyboardLayout.referenceSize.width / OldOSKeyboardLayout.referenceSize.height,
            contentMode: .fit
        )
        .accessibilityElement(children: .contain)
        .onChange(of: controller.isVisible) { visible in
            if visible {
                resetZephyrSession()
            }
        }
    }

    @ViewBuilder
    private func keyView(_ placed: OldOSKeyboardPlacedKey, scale: CGFloat) -> some View {
        let frame = placed.visualFrame
        let pressed = activeKeyID == placed.id

        ZStack {

            let popupOwnsPressedVisual = pressed
                && placed.key.showsTapPopup
                && activePlacedKey?.id == placed.id
                && variantPlacedKey == nil

            let visualPressed = popupOwnsPressedVisual ? false : pressed

            keyBackground(
                for: placed,
                pressed: visualPressed,
                scale: scale
            )

            if isNumberPadStyle(placed.key.style) {
                numberPadLabel(for: placed, pressed: pressed, scale: scale)
            } else {
                switch placed.key.kind {
                case .shift:
                    shiftGlyph(pressed: pressed, scale: scale)
                case .planeChooser:
                    planeChooserGlyph(selected: controller.keyplane == .symbols, pressed: pressed, scale: scale)
                case .delete:
                    deleteGlyph(pressed: pressed, scale: scale)
                case .globe:
                    OldOSCoreTextKeyLabel(
                        OldOSKeyboardFont.globe,
                        fontSize: 21 * scale,
                        foregroundColor: modifierGlyphUIColor(pressed: pressed),
                        etchedColor: pressed
                            ? UIColor.white.withAlphaComponent(0.336)
                            : UIColor.black.withAlphaComponent(0.52),
                        etchedOffset: nonCharacterEtchedOffset(scale: scale)
                    )
                case .empty:
                    EmptyView()
                default:
                    OldOSCoreTextKeyLabel(
                        placed.key.displayLabel(shift: controller.shiftState),
                        fontSize: labelFontSize(for: placed.key) * scale,
                        foregroundColor: labelUIColor(for: placed.key, pressed: visualPressed),
                        etchedColor: labelShadowUIColor(for: placed.key, pressed: visualPressed),
                        etchedOffset: etchedOffset(for: placed.key, scale: scale),
                        verticalAdjustment: 1 * scale
                    )
                }
            }
        }
        .frame(width: frame.width * scale, height: frame.height * scale)
        .position(x: frame.midX * scale, y: frame.midY * scale)
        .accessibilityLabel(accessibilityLabel(for: placed.key))
    }

    @ViewBuilder
    private func keyBackground(
        for placed: OldOSKeyboardPlacedKey,
        pressed: Bool,
        scale: CGFloat
    ) -> some View {
        let row = rowIndex(for: placed.visualFrame)
        let key = placed.key

        if isNumberPadStyle(key.style) {
            OldOSNumberPadKeyBackground(
                light: key.style == .numberPadLight,
                pressed: pressed && key.isEnabled,
                disabled: !key.isEnabled,
                bottomLeft: placed.visualFrame.minY >= 162 && placed.visualFrame.minX < 1,
                bottomRight: placed.visualFrame.minY >= 162 && placed.visualFrame.maxX > 319,
                scale: scale
            )
        } else {
            OldOSKeyCapBackground(
                treatment: treatment(for: key, pressed: pressed),
                row: row,
                scale: scale
            )
        }
    }

    private func rowIndex(for frame: CGRect) -> Int {
        if frame.minY < 60 { return 0 }
        if frame.minY < 114 { return 1 }
        if frame.minY < 168 { return 2 }
        return 3
    }

    private func treatment(
        for key: OldOSKeyboardKey,
        pressed: Bool
    ) -> OldOSKeyCapTreatment {
        if key.kind == .space {
            return pressed ? .spacePressed : .light
        }

        if key.kind == .returnKey {
            if key.style == .blue && key.isEnabled {
                return pressed ? .light : .blue
            }
            return pressed ? .light : .dark
        }

        if key.kind == .shift {

            switch controller.uikitShiftVisualState {
            case 4:
                return .blue
            case 3:
                return pressed ? .light : .dark
            default:
                return .dark
            }
        }

        switch key.style {
        case .light:
            return pressed ? .blue : .light
        case .dark:
            return pressed ? .light : .dark
        case .blue:
            return pressed ? .light : .blue
        case .numberPadDark:
            return pressed ? .light : .dark
        case .numberPadLight:
            return pressed ? .dark : .light
        }
    }

    private func isNumberPadStyle(_ style: OldOSKeyboardKeyStyle) -> Bool {
        style == .numberPadDark || style == .numberPadLight
    }

    @ViewBuilder
    private func numberPadLabel(for placed: OldOSKeyboardPlacedKey, pressed: Bool, scale: CGFloat) -> some View {
        let key = placed.key
        let lightFace = key.style == .numberPadLight
        let enabled = key.isEnabled
        let mainColor: UIColor = {
            if !enabled {
                return UIColor.white.withAlphaComponent(0.30)
            }
            if lightFace {
                return UIColor(red: 0.28, green: 0.31, blue: 0.36, alpha: 1)
            }
            return UIColor.white.withAlphaComponent(0.97)
        }()
        let secondaryColor = enabled
            ? (lightFace ? UIColor.black.withAlphaComponent(0.50) : UIColor.white.withAlphaComponent(0.62))
            : UIColor.white.withAlphaComponent(0.22)

        if key.kind == .delete {
            OldOSCoreTextKeyLabel(
                OldOSKeyboardFont.deleteWide,
                fontSize: 22 * scale,
                foregroundColor: lightFace
                    ? UIColor(red: 0.32, green: 0.36, blue: 0.42, alpha: 1)
                    : UIColor.white.withAlphaComponent(0.97),
                etchedColor: lightFace
                    ? UIColor.white.withAlphaComponent(0.45)
                    : UIColor.black.withAlphaComponent(0.45),
                etchedOffset: nonCharacterEtchedOffset(scale: scale)
            )
        } else if key.kind == .empty {
            EmptyView()
        } else if key.id == "phone-more" {

            OldOSCoreTextKeyLabel(
                "+*#",
                fontSize: 22 * scale,
                foregroundColor: mainColor,
                fontKind: .phonepadTwo,
                etchedColor: UIColor.black.withAlphaComponent(lightFace ? 0.12 : 0.38),
                etchedOffset: 1 * scale,
                kern: 3 * scale
            )
        } else if ["+", "*", "#"].contains(key.label), key.id.hasPrefix("phone-alt-") {

            OldOSCoreTextKeyLabel(
                key.label,
                fontSize: 42 * scale,
                foregroundColor: mainColor,
                fontKind: .phonepadTwo,
                etchedColor: UIColor.black.withAlphaComponent(lightFace ? 0.12 : 0.38),
                etchedOffset: 1 * scale,
                verticalAdjustment: 3 * scale
            )
        } else if let secondary = key.secondaryLabel {
            switch key.secondaryLabelPosition {
            case .below:
                ZStack {
                    OldOSCoreTextKeyLabel(
                        key.displayLabel(shift: controller.shiftState),
                        fontSize: 25 * scale,
                        foregroundColor: mainColor,
                        etchedColor: UIColor.black.withAlphaComponent(lightFace ? 0.12 : 0.38),
                        etchedOffset: 1 * scale
                    )
                    .position(x: placed.visualFrame.width / 2 * scale, y: 19 * scale)

                    OldOSCoreTextKeyLabel(
                        secondary,
                        fontSize: 9 * scale,
                        foregroundColor: secondaryColor,
                        etchedColor: nil,
                        etchedOffset: 0
                    )
                    .position(x: placed.visualFrame.width / 2 * scale, y: 38 * scale)
                }
                .frame(width: placed.visualFrame.width * scale, height: placed.visualFrame.height * scale)

            case .trailing:
                ZStack {
                    OldOSCoreTextKeyLabel(
                        key.displayLabel(shift: controller.shiftState),
                        fontSize: 27 * scale,
                        foregroundColor: mainColor,
                        etchedColor: UIColor.black.withAlphaComponent(lightFace ? 0.12 : 0.38),
                        etchedOffset: 1 * scale
                    )
                    .position(x: (placed.visualFrame.width / 2 - 6) * scale, y: placed.visualFrame.height / 2 * scale)

                    OldOSCoreTextKeyLabel(
                        secondary,
                        fontSize: 17 * scale,
                        foregroundColor: secondaryColor,
                        etchedColor: nil,
                        etchedOffset: 0
                    )
                    .position(x: (placed.visualFrame.width / 2 + 15) * scale, y: (placed.visualFrame.height / 2 + 1) * scale)
                }
                .frame(width: placed.visualFrame.width * scale, height: placed.visualFrame.height * scale)
            }
        } else {
            let size: CGFloat = key.label.count > 1 ? 17 : 27
            OldOSCoreTextKeyLabel(
                key.displayLabel(shift: controller.shiftState),
                fontSize: size * scale,
                foregroundColor: mainColor,
                etchedColor: UIColor.black.withAlphaComponent(lightFace ? 0.12 : 0.38),
                etchedOffset: 1 * scale
            )
        }
    }

    @ViewBuilder
    private func planeChooserGlyph(selected: Bool, pressed: Bool, scale: CGFloat) -> some View {
        if selected {
            let arrowWidth: CGFloat = 19.0
            let arrowHeight: CGFloat = 14.75
            ZStack {
                OldOSFilledShiftArrow()
                    .fill(Color.white.opacity(0.29))
                    .frame(width: arrowWidth * scale, height: arrowHeight * scale)
                    .blur(radius: 6.4 * scale)
                OldOSFilledShiftArrow()
                    .fill(Color.white.opacity(0.50))
                    .frame(width: arrowWidth * scale, height: arrowHeight * scale)
                    .blur(radius: 2.8 * scale)
                OldOSFilledShiftArrow()
                    .fill(Color.white)
                    .frame(width: arrowWidth * scale, height: arrowHeight * scale)
            }
        } else {
            OldOSCoreTextKeyLabel(
                OldOSKeyboardFont.shiftSmall,
                fontSize: 23 * scale,
                foregroundColor: pressed
                    ? UIColor.black.withAlphaComponent(0.88)
                    : UIColor.white.withAlphaComponent(0.98),
                etchedColor: pressed
                    ? UIColor.white.withAlphaComponent(0.336)
                    : UIColor.black.withAlphaComponent(0.496),
                etchedOffset: nonCharacterEtchedOffset(scale: scale)
            )
        }
    }

    @ViewBuilder
    private func shiftGlyph(pressed: Bool, scale: CGFloat) -> some View {

        let sourceState = controller.uikitShiftVisualState
        let selected = sourceState != 3
        let glyph = sourceState == 4
            ? OldOSKeyboardFont.shiftLarge
            : OldOSKeyboardFont.shiftSmall

        ZStack {
            if selected {

                let arrowWidth: CGFloat = 19.0
                let arrowHeight: CGFloat = 14.75

                OldOSFilledShiftArrow()
                    .fill(Color.white.opacity(sourceState == 4 ? 0.34 : 0.29))
                    .frame(width: arrowWidth * scale, height: arrowHeight * scale)
                    .blur(radius: 6.4 * scale)

                OldOSFilledShiftArrow()
                    .fill(Color.white.opacity(sourceState == 4 ? 0.58 : 0.50))
                    .frame(width: arrowWidth * scale, height: arrowHeight * scale)
                    .blur(radius: 2.8 * scale)

                OldOSFilledShiftArrow()
                    .fill(Color.white)
                    .frame(width: arrowWidth * scale, height: arrowHeight * scale)
            } else {

                OldOSCoreTextKeyLabel(
                    glyph,
                    fontSize: 23 * scale,
                    foregroundColor: pressed
                        ? UIColor.black.withAlphaComponent(0.88)
                        : UIColor.white.withAlphaComponent(0.98),
                    etchedColor: pressed
                        ? UIColor.white.withAlphaComponent(0.336)
                        : UIColor.black.withAlphaComponent(0.496),
                    etchedOffset: nonCharacterEtchedOffset(scale: scale)
                )
            }
        }
    }

    @ViewBuilder
    private func deleteGlyph(pressed: Bool, scale: CGFloat) -> some View {

        OldOSCoreTextKeyLabel(
            OldOSKeyboardFont.deleteWide,
            fontSize: 22 * scale,
            foregroundColor: pressed
                ? UIColor(red: 0.335, green: 0.365, blue: 0.412, alpha: 1.0)
                : UIColor.white.withAlphaComponent(0.97),
            etchedColor: pressed
                ? UIColor.white.withAlphaComponent(0.336)
                : UIColor.black.withAlphaComponent(0.496),
            etchedOffset: nonCharacterEtchedOffset(scale: scale)
        )
    }

    private func etchedOffset(for key: OldOSKeyboardKey, scale: CGFloat) -> CGFloat {
        switch key.kind {
        case .character, .space:
            return 1 * scale
        default:
            return nonCharacterEtchedOffset(scale: scale)
        }
    }

    private func nonCharacterEtchedOffset(scale: CGFloat) -> CGFloat {
        -1 * scale
    }

    private func labelFontSize(for key: OldOSKeyboardKey) -> CGFloat {
        switch key.kind {
        case .character:
            return key.label.count > 1 ? 16 : 22
        case .space, .returnKey, .switchToLetters, .switchToNumbers, .switchToSymbols:
            return 16
        default:
            return 14
        }
    }

    private func labelUIColor(for key: OldOSKeyboardKey, pressed: Bool) -> UIColor {
        if !key.isEnabled {
            return UIColor(red: 0.72, green: 0.74, blue: 0.76, alpha: 1)
        }

        if key.kind == .space {
            return pressed
                ? UIColor.white.withAlphaComponent(0.96)
                : UIColor(red: 0.29, green: 0.33, blue: 0.39, alpha: 1)
        }

        if key.kind == .returnKey {

            if pressed && key.style != .blue {
                return UIColor(red: 0.335, green: 0.365, blue: 0.412, alpha: 1.0)
            }
            return key.style == .blue && !pressed
                ? UIColor.white.withAlphaComponent(0.98)
                : (pressed ? UIColor.black.withAlphaComponent(0.88) : UIColor.white.withAlphaComponent(0.98))
        }

        if key.style == .light {
            return pressed
                ? UIColor.white.withAlphaComponent(0.98)
                : UIColor.black.withAlphaComponent(0.94)
        }

        return pressed
            ? UIColor.black.withAlphaComponent(0.88)
            : UIColor.white.withAlphaComponent(0.98)
    }

    private func labelShadowUIColor(for key: OldOSKeyboardKey, pressed: Bool) -> UIColor? {
        if key.kind == .space {

            if !key.isEnabled { return UIColor.black.withAlphaComponent(0.42) }
            return pressed
                ? UIColor.black.withAlphaComponent(0.45)
                : UIColor.white.withAlphaComponent(0.62)
        }

        if !key.isEnabled {
            let alpha: CGFloat = key.kind == .character ? 0.42 : 0.336
            return UIColor.black.withAlphaComponent(alpha)
        }

        let base: UIColor
        if key.style == .light {
            base = pressed
                ? UIColor.black.withAlphaComponent(0.34)
                : UIColor.white.withAlphaComponent(0.72)
        } else {
            base = pressed
                ? UIColor.white.withAlphaComponent(0.42)
                : UIColor.black.withAlphaComponent(0.72)
        }

        guard key.kind != .character else { return base }

        return base.withAlphaComponent(base.cgColor.alpha * 0.8)
    }

    private func modifierGlyphUIColor(pressed: Bool) -> UIColor {
        pressed
            ? UIColor.black.withAlphaComponent(0.82)
            : UIColor.white.withAlphaComponent(0.97)
    }

    private func accessibilityLabel(for key: OldOSKeyboardKey) -> String {
        switch key.kind {
        case .shift: return "Shift"
        case .planeChooser: return "More symbols"
        case .delete: return "Delete"
        case .globe: return "Next keyboard"
        case .empty: return ""
        default: return key.label
        }
    }

    private enum TapPopupEdge {
        case left
        case center
        case right
        case straight
    }

    private struct TapPopupGeometry {
        let imageName: String
        let canvas: CGSize
        let left: CGFloat
        let top: CGFloat
        let labelCenterX: CGFloat
        let labelCenterY: CGFloat
    }

    private func tapPopupGeometry(for placed: OldOSKeyboardPlacedKey) -> TapPopupGeometry {
        let literal = placed.key.output ?? placed.key.label
        let usesStraightUtilityPopup =
            (controller.keyplane == .numbers || controller.keyplane == .symbols) &&
            placed.visualFrame.minY < 162 &&
            [".", ",", "?", "!", "'"].contains(literal)

        let edge: TapPopupEdge
        if usesStraightUtilityPopup {

            edge = .straight
        } else {
            switch placed.key.popupBias {
            case .right:

                edge = .left
            case .left:

                edge = .right
            case .none:
                edge = .center
            }
        }

        let bottomY = placed.visualFrame.maxY

        switch edge {
        case .left:

            let size = CGSize(width: 86, height: 114)
            let left: CGFloat = 0
            return TapPopupGeometry(
                imageName: "kb-popup-114-36-right-flipped",
                canvas: size,
                left: left,
                top: bottomY - size.height + 3,
                labelCenterX: 23.45,
                labelCenterY: 40.0
            )

        case .right:

            let size = CGSize(width: 86, height: 114)
            let left: CGFloat = 320 - size.width
            return TapPopupGeometry(
                imageName: "kb-popup-114-36-left-flipped",
                canvas: size,
                left: left,
                top: bottomY - size.height + 3,
                labelCenterX: 62.55,
                labelCenterY: 40.0
            )

        case .center:
            let size = CGSize(width: 102, height: 114)
            return TapPopupGeometry(
                imageName: "kb-std-active-bg-pop-center",
                canvas: size,
                left: placed.visualFrame.midX - 50.75,
                top: bottomY - size.height,
                labelCenterX: 50.75,
                labelCenterY: 40
            )

        case .straight:

            let size = CGSize(width: 110, height: 114)
            return TapPopupGeometry(
                imageName: "kb-popup-114-36-straight-flipped",
                canvas: size,
                left: placed.visualFrame.midX - size.width / 2,
                top: bottomY - size.height,
                labelCenterX: size.width / 2,
                labelCenterY: 40
            )
        }
    }

    @ViewBuilder
    private func tapPopup(for placed: OldOSKeyboardPlacedKey, scale: CGFloat) -> some View {
        let g = tapPopupGeometry(for: placed)

        ZStack(alignment: .topLeading) {
            Image(g.imageName)
                .resizable()
                .interpolation(.high)
                .frame(width: g.canvas.width * scale, height: g.canvas.height * scale)

            OldOSCoreTextKeyLabel(
                activePopupText ?? placed.key.displayLabel(shift: controller.shiftState),
                fontSize: 38 * scale,
                foregroundColor: UIColor.black.withAlphaComponent(0.94),
                etchedColor: UIColor.white.withAlphaComponent(0.52),
                etchedOffset: 1 * scale
            )
            .frame(width: 56 * scale, height: 52 * scale)
            .position(x: g.labelCenterX * scale, y: g.labelCenterY * scale)
        }
        .frame(width: g.canvas.width * scale, height: g.canvas.height * scale)
        .position(
            x: (g.left + g.canvas.width / 2) * scale,
            y: (g.top + g.canvas.height / 2) * scale
        )
    }

    private struct AccentGeometry {
        let left: CGFloat
        let top: CGFloat
        let width: CGFloat
        let cellLayoutWidth: CGFloat
        let cellLayoutOriginX: CGFloat
        let height: CGFloat
        let tubeHeight: CGFloat
        let cellWidth: CGFloat
        let horizontalPadding: CGFloat
        let stringWidth: CGFloat
        let stemX: CGFloat
        let grabberX: CGFloat
        let grabberY: CGFloat
        let shellAssetOverride: String?
        let movedToFitLCD: Bool
    }

    private func displayedVariants(for key: OldOSKeyboardKey) -> [String] {
        var values = key.variants
        guard values.count > 1 else { return values }

        let literal = key.output ?? key.label
        guard let literalIndex = values.firstIndex(of: literal) else { return values }

        switch key.variantDirection {
        case .right:
            if literalIndex != 0 { values.reverse() }
        case .left:
            if literalIndex != values.count - 1 { values.reverse() }
        case .automatic:
            break
        }
        return values
    }

    private func accentGeometry(for placed: OldOSKeyboardPlacedKey, count: Int) -> AccentGeometry {
        let literal = placed.key.output ?? placed.key.label

        let stringWidth: CGFloat
        if literal == "." || literal == "@" {
            stringWidth = 45
        } else {
            stringWidth = count > 10 ? 27 : 32
        }

        let cellWidth = stringWidth
        let horizontalPadding: CGFloat = 31
        let baseContentWidth = CGFloat(count) * stringWidth + 40

        let isGenericTwoCell = count == 2 && abs(stringWidth - 32) < 0.001

        let isLeftEdgeAccent = literal == "-"
        let isRightEdgeAccent = literal == "\"" || literal == "0"

        let edgeTubeExtension: CGFloat
        if isLeftEdgeAccent {
            edgeTubeExtension = 0
        } else if isRightEdgeAccent {
            edgeTubeExtension = 0
        } else {
            edgeTubeExtension = 0
        }
        let width: CGFloat = baseContentWidth + edgeTubeExtension

        let cellLayoutWidth: CGFloat = baseContentWidth

        let tubeHeight: CGFloat = 75
        let totalHeight: CGFloat = 122

        let sourceY = placed.visualFrame.minY
        let yOffset: CGFloat = sourceY < 34 ? 58 : 68
        let zeroYOffset: CGFloat = literal == "0" ? -4 : 0
        let top = sourceY - yOffset - 8 + zeroYOffset

        let grabberY: CGFloat = placed.visualFrame.minY < 54 ? 44 : 50

        let grabberX: CGFloat
        let stemLocalX: CGFloat
        switch placed.key.variantDirection {
        case .right:

            grabberX = -12
            stemLocalX = grabberX + 49.5
        case .left:

            grabberX = width - 88
            stemLocalX = grabberX + 49.5
        case .automatic:
            grabberX = (width - 100) / 2
            stemLocalX = width / 2
        }

        let edgeOvershoot: CGFloat = 0.5
        let left: CGFloat
        if isLeftEdgeAccent {
            left = placed.visualFrame.midX - stemLocalX - edgeOvershoot
        } else if isRightEdgeAccent {
            left = placed.visualFrame.midX - stemLocalX + edgeOvershoot
        } else {
            left = placed.visualFrame.midX - stemLocalX
        }

        let edgeCellInset: CGFloat = 2

        let edgeCellCenter = 20 + stringWidth / 2
        let cellLayoutOriginX: CGFloat
        if isLeftEdgeAccent {
            cellLayoutOriginX = stemLocalX - edgeCellCenter  + edgeCellInset
        } else if isRightEdgeAccent {
            let rightmostCellCenter = baseContentWidth - edgeCellCenter
            cellLayoutOriginX = stemLocalX - rightmostCellCenter - edgeCellInset
        } else {
            cellLayoutOriginX = 0
        }

        let shellAssetOverride: String? = nil

        return AccentGeometry(
            left: left,
            top: top,
            width: width,
            cellLayoutWidth: cellLayoutWidth,
            cellLayoutOriginX: cellLayoutOriginX,
            height: totalHeight,
            tubeHeight: tubeHeight,
            cellWidth: cellWidth,
            horizontalPadding: horizontalPadding,
            stringWidth: stringWidth,
            stemX: stemLocalX,
            grabberX: grabberX,
            grabberY: grabberY,
            shellAssetOverride: shellAssetOverride,
            movedToFitLCD: false
        )
    }

    private func accentGrabberName(
        for key: OldOSKeyboardKey,
        geometry: AccentGeometry
    ) -> String {

        if geometry.movedToFitLCD {
            return "kb-accented-mid-grabber"
        }

        switch key.variantDirection {
        case .right:
            return "kb-accented-right-grabber"
        case .left:
            return "kb-accented-left-grabber"
        case .automatic:
            return "kb-accented-mid-grabber"
        }
    }

    @ViewBuilder
    private func accentPopover(for placed: OldOSKeyboardPlacedKey, scale: CGFloat) -> some View {
        let variants = displayedVariants(for: placed.key)
        let g = accentGeometry(for: placed, count: variants.count)
        let sourceCharacterY: CGFloat = 18
        let sourceCharacterHeight: CGFloat = 44

        ZStack(alignment: .topLeading) {

            OldOSAccentShellView(
                width: g.width,
                grabberName: accentGrabberName(for: placed.key, geometry: g),
                grabberX: g.grabberX,
                grabberY: g.grabberY,
                assetNameOverride: g.shellAssetOverride,
                scale: scale
            )
            .frame(width: g.width * scale, height: g.height * scale)
            .position(x: g.width / 2 * scale, y: g.height / 2 * scale)

            ForEach(Array(variants.enumerated()), id: \.offset) { index, variant in
                let centerX = accentCellCenterX(
                    index: index,
                    stringWidth: g.stringWidth,
                    direction: placed.key.variantDirection,
                    tubeWidth: g.cellLayoutWidth
                ) + g.cellLayoutOriginX

                ZStack {

                    OldOSAccentCellBackground(
                        selected: index == selectedVariantIndex,
                        scale: scale
                    )

                    .frame(
                        width: max(24, g.stringWidth - 2) * scale,
                        height: 38 * scale
                    )

                    OldOSCoreTextKeyLabel(
                        variant,
                        fontSize: 24 * scale,
                        foregroundColor: index == selectedVariantIndex
                            ? UIColor.white.withAlphaComponent(0.98)
                            : UIColor.black.withAlphaComponent(0.94),
                        fontKind: .helveticaBold,
                        maximumTextWidth: max(18, g.stringWidth - 6) * scale,
                        etchedColor: index == selectedVariantIndex
                            ? UIColor.black.withAlphaComponent(0.34)
                            : nil,
                        etchedOffset: 1 * scale
                    )
                }
                .frame(width: g.stringWidth * scale, height: sourceCharacterHeight * scale)
                .clipped()
                .position(
                    x: centerX * scale,
                    y: (sourceCharacterY + sourceCharacterHeight / 2) * scale
                )
            }
        }
        .frame(width: g.width * scale, height: g.height * scale)

        .clipShape(
            OldOSHorizontalInsetClip(
                leftInset: max(0, -g.left) * scale,
                rightInset: max(0, g.left + g.width - 320) * scale
            )
        )
        .position(
            x: (g.left + g.width / 2) * scale,
            y: (g.top + g.height / 2) * scale
        )
    }

    private struct OldOSHorizontalInsetClip: Shape {
        let leftInset: CGFloat
        let rightInset: CGFloat

        func path(in rect: CGRect) -> Path {
            let x = min(max(0, leftInset), rect.width)
            let right = min(max(x, rect.width - max(0, rightInset)), rect.width)
            return Path(CGRect(x: x, y: 0, width: max(0, right - x), height: rect.height))
        }
    }

    private func handleNativeTouchSample(
        _ sample: OldOSKeyboardTouchSample,
        keys: [OldOSKeyboardPlacedKey]
    ) {
        switch sample.phase {
        case .began:
            var interactionKeys = keys
            if let currentID = foregroundTouchID, currentID != sample.touchID {
                commitForegroundTouchBeforeIncomingTouch(
                    incomingTimestamp: sample.timestamp
                )

                interactionKeys = placedKeysForCurrentControllerState()
            }

            foregroundTouchID = sample.touchID
            touchChanged(
                at: sample.location,
                keys: interactionKeys,
                timestamp: sample.timestamp,
                majorRadius: sample.majorRadius,
                isBeginning: true
            )

        case .moved:
            guard foregroundTouchID == sample.touchID else { return }
            touchChanged(
                at: sample.location,
                keys: keys,
                timestamp: sample.timestamp,
                majorRadius: sample.majorRadius,
                isBeginning: false
            )

        case .ended:
            guard foregroundTouchID == sample.touchID else { return }
            touchEnded(
                at: sample.location,
                keys: keys,
                timestamp: sample.timestamp,
                majorRadius: sample.majorRadius
            )
            foregroundTouchID = nil

        case .cancelled:
            guard foregroundTouchID == sample.touchID else { return }
            controller.cancelShiftTouch()
            cancelActiveKey()
            touchStartTime = nil
            foregroundTouchID = nil
        }
    }

    private func commitForegroundTouchBeforeIncomingTouch(
        incomingTimestamp: TimeInterval
    ) {
        guard foregroundTouchID != nil else { return }

        let point = currentTouchPoint ?? activePlacedKey?.center ?? .zero
        let radius = zephyrMajorRadius

        touchEnded(
            at: point,
            keys: [],
            timestamp: incomingTimestamp,
            majorRadius: radius
        )

        foregroundTouchID = nil
    }

    private func placedKeysForCurrentControllerState() -> [OldOSKeyboardPlacedKey] {
        OldOSKeyboardLayout.keys(
            plane: controller.keyplane,
            shift: controller.shiftState,
            configuration: controller.configuration,
            returnKeyEnabled: controller.returnKeyEnabled
        )
    }

    private func touchChanged(
        at point: CGPoint,
        keys: [OldOSKeyboardPlacedKey],
        timestamp: TimeInterval,
        majorRadius: CGFloat,
        isBeginning: Bool
    ) {
        releaseWorkItem?.cancel()
        releaseWorkItem = nil
        if touchStartTime == nil {
            touchStartTime = Date.timeIntervalSinceReferenceDate
        }
        currentTouchPoint = point
        zephyrMajorRadius = majorRadius

        if isBeginning {
            updateZephyrInterKeyInterval(at: timestamp)
            dragReferencePoint = point
            genericHasDragged = false
        }

        if let placed = variantPlacedKey {
            updateVariantSelection(point: point, placed: placed)
            return
        }

        if !isBeginning {
            let reference = dragReferencePoint ?? point
            let threshold = genericHasDragged ? subsequentDragThreshold : initialDragThreshold
            let dx = abs(point.x - reference.x)
            let dy = abs(point.y - reference.y)
            guard dx >= threshold || dy >= threshold else { return }

            dragReferencePoint = point
            genericHasDragged = true

            cancelLongPress()
        }

        guard let candidate = hitTest(
            point: point,
            keys: keys,
            majorRadius: majorRadius
        ) else {
            deactivateActiveKeyForDrag()
            return
        }

        if isBeginning || activeKeyID != candidate.id {
            if let old = activePlacedKey, old.key.kind == .shift {
                controller.shiftTouchDidSlideOff(
                    keepingShiftForCharacter: !isBeginning && candidate.key.kind == .character
                )
            }
            setActiveKey(candidate, timestamp: timestamp)
        }
    }

    private func touchEnded(
        at point: CGPoint,
        keys: [OldOSKeyboardPlacedKey],
        timestamp: TimeInterval,
        majorRadius: CGFloat
    ) {
        touchStartTime = nil
        zephyrMajorRadius = majorRadius
        cancelLongPress()
        cancelDeleteRepeat()

        if let placed = variantPlacedKey {
            let variants = displayedVariants(for: placed.key)
            if !variants.isEmpty, selectedVariantIndex >= 0, selectedVariantIndex < variants.count {
                controller.commitVariant(variants[selectedVariantIndex])
                finalizeZephyrStroke(at: point, placed: placed)
            }
            resetTouchState(after: 0.025)
            return
        }

        guard let placed = activePlacedKey else {
            resetTouchState(after: 0)
            return
        }
        let key = placed.key

        if key.kind == .shift {
            controller.endShiftTouch()
        } else if key.kind != .delete {
            let touchEvidence = isZephyrAlphabetic(key)
                ? zephyrAutocorrectionTouchEvidence(
                    at: point,
                    committed: placed,
                    keys: keys,
                    majorRadius: majorRadius
                )
                : nil
            controller.commit(key, zephyrTouchEvidence: touchEvidence)
        }
        finalizeZephyrStroke(at: point, placed: placed)

        resetTouchState(after: postReleasePressedVisualTime)
    }

    private func hitTest(
        point: CGPoint,
        keys: [OldOSKeyboardPlacedKey],
        majorRadius: CGFloat
    ) -> OldOSKeyboardPlacedKey? {
        let now = Date.timeIntervalSinceReferenceDate
        let buffer = sourceHitBuffer(now: now)
        let keyboardBounds = CGRect(
            x: -buffer,
            y: -buffer,
            width: 320 + 2 * buffer,
            height: 216 + 2 * buffer
        )
        guard keyboardBounds.contains(point) else { return nil }

        if controller.keyplane == .letters {

            if let special = keys.first(where: {
                $0.key.kind != .character && $0.hitFrame.contains(point)
            }) {
                return special
            }

            let alphabeticPlaced = keys.filter { isZephyrAlphabetic($0.key) }
            let inAlphabeticRegion = alphabeticPlaced.contains { $0.hitFrame.contains(point) }
            if inAlphabeticRegion,
               let adaptive = zephyrHitTest(
                    point: point,
                    alphabeticKeys: alphabeticPlaced,
                    majorRadius: majorRadius
               ) {
                return adaptive
            }
        }

        if let exact = keys.first(where: { $0.hitFrame.contains(point) }) {
            return exact
        }

        return keys.min { lhs, rhs in
            distanceSquared(point, lhs.center) < distanceSquared(point, rhs.center)
        }
    }

    private func zephyrHitTest(
        point: CGPoint,
        alphabeticKeys: [OldOSKeyboardPlacedKey],
        majorRadius: CGFloat
    ) -> OldOSKeyboardPlacedKey? {
        guard !alphabeticKeys.isEmpty else { return nil }

        let areas = alphabeticKeys.map(zephyrKeyArea)
        let context = controller.zephyrTextBeforeCursor
        let prefix = OldOSZephyrStaticLanguageModel.currentASCIIWordPrefix(in: context)
        let profile = OldOSZephyrTouchProfile(
            interKeyInterval: zephyrFilteredInterKeyInterval,
            majorRadius: majorRadius,
            priorTouchVectors: zephyrPriorTouchVectors
        )

        guard let decision = Self.productionZephyrHitTester.decision(
            at: point,
            keys: areas,
            wordPrefix: prefix,
            profile: profile,
            useLanguage: true,
            forceShift: controller.shiftState != .off
        ) else { return nil }

        return alphabeticKeys.first(where: { $0.id == decision.winner.id })
    }

    private func zephyrAutocorrectionTouchEvidence(
        at point: CGPoint,
        committed: OldOSKeyboardPlacedKey,
        keys: [OldOSKeyboardPlacedKey],
        majorRadius: CGFloat
    ) -> OldOSZephyrAutocorrectionTouchEvidence? {
        let alphabeticKeys = keys.filter { isZephyrAlphabetic($0.key) }
        guard !alphabeticKeys.isEmpty else { return nil }

        let profile = OldOSZephyrTouchProfile(
            interKeyInterval: zephyrFilteredInterKeyInterval,
            majorRadius: majorRadius,
            priorTouchVectors: zephyrPriorTouchVectors
        )
        return OldOSZephyrHitTester.autocorrectionTouchEvidence(
            at: point,
            keys: alphabeticKeys.map { zephyrKeyArea($0) },
            committedKeyID: committed.id,
            profile: profile
        )
    }

    private func zephyrKeyArea(_ placed: OldOSKeyboardPlacedKey) -> OldOSZephyrKeyArea {
        let lower = (placed.key.output ?? placed.key.label).lowercased()
        let upper = (placed.key.output ?? placed.key.label).uppercased()
        return OldOSZephyrKeyArea(
            id: placed.id,
            frame: placed.hitFrame,
            lower: lower,
            upper: upper,
            isAlphabetic: true,
            isEnabled: placed.key.isEnabled
        )
    }

    private func isZephyrAlphabetic(_ key: OldOSKeyboardKey) -> Bool {
        guard key.kind == .character else { return false }
        let value = (key.output ?? key.label).lowercased()
        guard value.unicodeScalars.count == 1, let scalar = value.unicodeScalars.first else { return false }
        return scalar.value >= 97 && scalar.value <= 122
    }

    private func updateZephyrInterKeyInterval(at timestamp: TimeInterval) {
        defer { zephyrLastTouchBeganAt = timestamp }
        guard let previous = zephyrLastTouchBeganAt else { return }
        let sample = max(0, timestamp - previous)
        guard sample.isFinite, sample > 0 else { return }

        if zephyrHasFilteredInterval {
            let alpha = OldOSZephyrHitTester.interKeyIntervalFilterAlpha
            zephyrFilteredInterKeyInterval = alpha * zephyrFilteredInterKeyInterval
                + (1 - alpha) * sample
        } else {
            zephyrFilteredInterKeyInterval = sample
            zephyrHasFilteredInterval = true
        }
    }

    private func finalizeZephyrStroke(at point: CGPoint, placed: OldOSKeyboardPlacedKey) {
        if isZephyrAlphabetic(placed.key) {
            let area = zephyrKeyArea(placed)
            let error = OldOSZephyrHitTester.errorVector(touch: point, key: area)
            zephyrPriorTouchVectors = OldOSZephyrHitTester.branchPriorTouchCache(
                appending: error,
                to: zephyrPriorTouchVectors
            )
            return
        }

        switch placed.key.kind {
        case .shift, .globe:

            break
        default:

            zephyrPriorTouchVectors.removeAll(keepingCapacity: true)
        }
    }

    private func resetZephyrSession() {
        foregroundTouchID = nil
        zephyrLastTouchBeganAt = nil
        zephyrFilteredInterKeyInterval = 0.35
        zephyrHasFilteredInterval = false
        zephyrMajorRadius = 6.5
        zephyrPriorTouchVectors.removeAll(keepingCapacity: true)
    }

    private func sourceHitBuffer(now: TimeInterval) -> CGFloat {
        guard let start = touchStartTime else { return portraitHitBuffer }
        let elapsed = max(0, now - start)
        if elapsed <= 0.1 { return portraitHitBuffer }
        if elapsed >= 0.8 { return 0 }
        return portraitHitBuffer * CGFloat((0.8 - elapsed) / 0.7)
    }

    private func distanceSquared(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return dx * dx + dy * dy
    }

    private func setActiveKey(_ placed: OldOSKeyboardPlacedKey, timestamp: TimeInterval) {
        releaseWorkItem?.cancel()
        releaseWorkItem = nil
        cancelLongPress()
        cancelDeleteRepeat()

        variantKeyID = nil
        variantPlacedKey = nil
        variantDragOrigin = nil
        variantHasDragged = false
        selectedVariantIndex = 0

        activeKeyID = placed.id
        activePlacedKey = placed
        activePopupText = placed.key.displayLabel(shift: controller.shiftState)

        guard placed.key.isEnabled else { return }

        if placed.key.kind == .shift {
            controller.beginShiftTouch(at: timestamp)

            activePopupText = placed.key.displayLabel(shift: controller.shiftState)
            return
        }

        if placed.key.kind == .delete {
            controller.commit(placed.key)
            scheduleDeleteRepeat()
            return
        }

        if !placed.key.variants.isEmpty {
            let id = placed.id
            let work = DispatchWorkItem {
                guard activePlacedKey?.id == id else { return }
                variantKeyID = id
                variantPlacedKey = placed
                selectedVariantIndex = defaultVariantIndex(for: placed.key)

                variantDragOrigin = currentTouchPoint
                variantHasDragged = false
            }
            longPressWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + longPressDelay, execute: work)
        }
    }

    private func defaultVariantIndex(for key: OldOSKeyboardKey) -> Int {
        let variants = displayedVariants(for: key)
        guard let output = key.output else { return 0 }
        if let index = variants.firstIndex(of: output) { return index }
        if let index = variants.firstIndex(of: key.label) { return index }
        return 0
    }

    private func deactivateActiveKeyForDrag() {
        if activePlacedKey?.key.kind == .shift {
            controller.shiftTouchDidSlideOff(keepingShiftForCharacter: false)
        }
        activeKeyID = nil
        activePlacedKey = nil
        activePopupText = nil
        variantKeyID = nil
        variantPlacedKey = nil
        variantDragOrigin = nil
        variantHasDragged = false
        selectedVariantIndex = 0
        cancelLongPress()
        cancelDeleteRepeat()
    }

    private func cancelActiveKey() {
        if activePlacedKey?.key.kind == .shift { controller.cancelShiftTouch() }
        activeKeyID = nil
        activePlacedKey = nil
        activePopupText = nil
        variantKeyID = nil
        variantPlacedKey = nil
        variantDragOrigin = nil
        variantHasDragged = false
        currentTouchPoint = nil
        dragReferencePoint = nil
        genericHasDragged = false
        selectedVariantIndex = 0
        cancelLongPress()
        cancelDeleteRepeat()
    }

    private func resetTouchState(after delay: TimeInterval) {
        releaseWorkItem?.cancel()

        let work = DispatchWorkItem {
            activeKeyID = nil
            activePlacedKey = nil
            activePopupText = nil
            touchStartTime = nil
            variantKeyID = nil
            variantPlacedKey = nil
            variantDragOrigin = nil
            variantHasDragged = false
            currentTouchPoint = nil
            dragReferencePoint = nil
            genericHasDragged = false
            selectedVariantIndex = 0
            releaseWorkItem = nil
        }
        releaseWorkItem = work

        if delay <= 0 {
            work.perform()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        }
    }

    private func cancelLongPress() {
        longPressWorkItem?.cancel()
        longPressWorkItem = nil
    }

    private func scheduleDeleteRepeat() {
        deleteRepeatCount = 0

        let work = DispatchWorkItem {
            guard activePlacedKey?.key.kind == .delete else { return }
            controller.repeatDelete()
            deleteRepeatCount = 1
            installDeleteTimer(interval: deleteRepeatInterval)
        }
        deleteWorkItem = work
        DispatchQueue.main.asyncAfter(
            deadline: .now() + deleteInitialRepeatDelay,
            execute: work
        )
    }

    private func installDeleteTimer(interval: TimeInterval) {
        deleteTimer?.invalidate()
        let timer = Timer(timeInterval: interval, repeats: true) { _ in
            guard activePlacedKey?.key.kind == .delete else {
                cancelDeleteRepeat()
                return
            }

            let preFireCount = deleteRepeatCount
            if preFireCount >= deleteFastRepeatSwitchCount {
                controller.repeatDeleteWord()
            } else {
                controller.repeatDelete()
            }
            deleteRepeatCount += 1

            if preFireCount == deleteFastRepeatSwitchCount {
                installDeleteTimer(interval: deleteSustainedRepeatInterval)
            }
        }
        deleteTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func cancelDeleteRepeat() {
        deleteWorkItem?.cancel()
        deleteWorkItem = nil
        deleteTimer?.invalidate()
        deleteTimer = nil
        deleteRepeatCount = 0
    }

    private func updateVariantSelection(point: CGPoint, placed: OldOSKeyboardPlacedKey) {
        let count = displayedVariants(for: placed.key).count
        guard count > 0 else { return }

        let g = accentGeometry(for: placed, count: count)

        if variantDragOrigin == nil {
            variantDragOrigin = point
            return
        }

        if let origin = variantDragOrigin {
            let threshold: CGFloat = variantHasDragged ? 12 : 18
            let dx = abs(point.x - origin.x)
            let dy = abs(point.y - origin.y)
            if dx < threshold && dy < threshold { return }
            variantHasDragged = true
        }

        let localX = point.x - g.left
        let localY = point.y - g.top
        let threshold: CGFloat = variantHasDragged ? 12 : 18

        if localY < -threshold || localY > g.height + threshold {
            selectedVariantIndex = -1
            return
        }

        let stringWidth = g.stringWidth
        for index in 0..<count {
            let centerX = accentCellCenterX(
                index: index,
                stringWidth: stringWidth,
                direction: placed.key.variantDirection,
                tubeWidth: g.cellLayoutWidth
            ) + g.cellLayoutOriginX
            if localX >= centerX - stringWidth / 2
                && localX <= centerX + stringWidth / 2 {
                selectedVariantIndex = index
                return
            }
        }

        let firstCenter = accentCellCenterX(
            index: 0, stringWidth: stringWidth,
            direction: placed.key.variantDirection, tubeWidth: g.cellLayoutWidth
        ) + g.cellLayoutOriginX
        let lastCenter = accentCellCenterX(
            index: count - 1, stringWidth: stringWidth,
            direction: placed.key.variantDirection, tubeWidth: g.cellLayoutWidth
        ) + g.cellLayoutOriginX
        selectedVariantIndex = abs(localX - firstCenter) <= abs(localX - lastCenter) ? 0 : count - 1
    }

    private func accentCellCenterX(
        index: Int,
        stringWidth: CGFloat,
        direction: OldOSKeyboardVariantDirection,
        tubeWidth: CGFloat
    ) -> CGFloat {
        let edgeCenter = 20 + stringWidth / 2
        switch direction {
        case .left:
            return tubeWidth - edgeCenter - CGFloat(index) * stringWidth
        case .right, .automatic:
            return edgeCenter + CGFloat(index) * stringWidth
        }
    }

}

private struct OldOSLCDFrameReporter: UIViewRepresentable {
    let keyboard: OldOSKeyboardController

    final class ReporterView: UIView {
        weak var keyboard: OldOSKeyboardController?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            reportFrame()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            reportFrame()
        }

        private func reportFrame() {
            guard let window else { return }
            let frame = convert(bounds, to: window)
            Task { @MainActor [weak keyboard] in
                keyboard?.setSimulatedLCDFrameInWindow(frame)
            }
        }
    }

    func makeUIView(context: Context) -> ReporterView {
        let view = ReporterView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.keyboard = keyboard
        return view
    }

    func updateUIView(_ uiView: ReporterView, context: Context) {
        uiView.keyboard = keyboard
        uiView.setNeedsLayout()
    }
}

public struct OldOSKeyboardHostModifier: ViewModifier {
    @ObservedObject var keyboard: OldOSKeyboardController
    let horizontalInset: CGFloat
    let bottomInset: CGFloat

    public func body(content: Content) -> some View {
        ZStack {
            content

            GeometryReader { proxy in
                let displayHeight = max(0, proxy.size.height - bottomInset)
                let keyboardWidth = max(0, proxy.size.width - horizontalInset * 2)
                let keyboardHeight = keyboardWidth * OldOSKeyboardLayout.referenceSize.height
                    / OldOSKeyboardLayout.referenceSize.width

                ZStack(alignment: .top) {

                    OldOSLCDFrameReporter(keyboard: keyboard)
                        .frame(width: keyboardWidth, height: displayHeight)
                        .allowsHitTesting(false)

                    VStack(spacing: 0) {
                    ZStack(alignment: .bottom) {
                        if keyboard.isVisible {
                            OldOSKeyboard(controller: keyboard)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, horizontalInset)
                                .transition(.move(edge: .bottom))
                                .zIndex(1000)
                        }
                    }
                    .frame(
                        width: proxy.size.width,
                        height: displayHeight,
                        alignment: .bottom
                    )

                    .clipped()

                        Spacer(minLength: 0)
                    }
                }
                .onAppear {
                    keyboard.setRenderedKeyboardHeight(keyboardHeight)
                    keyboard.startGlobalInputInterception()
                }
                .onDisappear {
                    keyboard.stopGlobalInputInterception()
                }
                .onChange(of: keyboardHeight) { newHeight in
                    keyboard.setRenderedKeyboardHeight(newHeight)
                }
            }
            .allowsHitTesting(keyboard.isVisible)
        }
        .environmentObject(keyboard)
    }
}

public extension View {

    func oldOSKeyboardHost(
        _ keyboard: OldOSKeyboardController,
        horizontalInset: CGFloat = 0,
        bottomInset: CGFloat = 0
    ) -> some View {
        modifier(
            OldOSKeyboardHostModifier(
                keyboard: keyboard,
                horizontalInset: horizontalInset,
                bottomInset: bottomInset
            )
        )
    }
}

private struct OldOSFilledShiftArrow: Shape {
    func path(in rect: CGRect) -> Path {

        let w = rect.width
        let h = rect.height
        let cx = rect.midX
        let headBottom = rect.minY + h * 0.64
        let shaftHalf = w * 0.205
        let top = rect.minY + h * 0.015
        let bottom = rect.maxY - h * 0.015

        var p = Path()
        p.move(to: CGPoint(x: cx, y: top))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.015, y: headBottom))
        p.addLine(to: CGPoint(x: cx + shaftHalf, y: headBottom))
        p.addLine(to: CGPoint(x: cx + shaftHalf, y: bottom))
        p.addLine(to: CGPoint(x: cx - shaftHalf, y: bottom))
        p.addLine(to: CGPoint(x: cx - shaftHalf, y: headBottom))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.015, y: headBottom))
        p.closeSubpath()
        return p
    }
}

private struct OldOSPressedDeleteTag: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let r = min(4.0, h * 0.20)
        let pointX = w * 0.13
        let shoulderX = w * 0.30

        var p = Path()
        p.move(to: CGPoint(x: shoulderX, y: 0))
        p.addLine(to: CGPoint(x: w - r, y: 0))
        p.addQuadCurve(
            to: CGPoint(x: w, y: r),
            control: CGPoint(x: w, y: 0)
        )
        p.addLine(to: CGPoint(x: w, y: h - r))
        p.addQuadCurve(
            to: CGPoint(x: w - r, y: h),
            control: CGPoint(x: w, y: h)
        )
        p.addLine(to: CGPoint(x: shoulderX, y: h))
        p.addQuadCurve(
            to: CGPoint(x: pointX, y: h * 0.67),
            control: CGPoint(x: shoulderX * 0.88, y: h)
        )
        p.addLine(to: CGPoint(x: 0, y: h * 0.50))
        p.addLine(to: CGPoint(x: pointX, y: h * 0.33))
        p.addQuadCurve(
            to: CGPoint(x: shoulderX, y: 0),
            control: CGPoint(x: shoulderX * 0.88, y: 0)
        )
        p.closeSubpath()
        return p
    }
}
