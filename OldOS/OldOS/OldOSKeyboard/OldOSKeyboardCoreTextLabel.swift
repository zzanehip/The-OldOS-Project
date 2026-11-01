import SwiftUI
import UIKit
import CoreText

enum OldOSKeyboardCoreTextFont {
    case keyCaps
    case phonepadTwo
    case helveticaBold
}

struct OldOSCoreTextKeyLabel: UIViewRepresentable {
    let text: String
    let fontSize: CGFloat
    let foregroundColor: UIColor
    let fontKind: OldOSKeyboardCoreTextFont
    let etchedColor: UIColor?
    let etchedOffset: CGFloat
    let verticalAdjustment: CGFloat
    let kern: CGFloat
    let maximumTextWidth: CGFloat?

    init(
        _ text: String,
        fontSize: CGFloat,
        foregroundColor: UIColor,
        fontKind: OldOSKeyboardCoreTextFont = .keyCaps,
        maximumTextWidth: CGFloat? = nil,
        etchedColor: UIColor? = nil,
        etchedOffset: CGFloat = 1,
        verticalAdjustment: CGFloat = 0,
        kern: CGFloat = 0
    ) {
        self.text = text
        self.fontSize = fontSize
        self.foregroundColor = foregroundColor
        self.fontKind = fontKind
        self.maximumTextWidth = maximumTextWidth
        self.etchedColor = etchedColor
        self.etchedOffset = etchedOffset
        self.verticalAdjustment = verticalAdjustment
        self.kern = kern
    }

    func makeUIView(context: Context) -> OldOSCoreTextLabelView {
        let view = OldOSCoreTextLabelView(frame: .zero)
        view.backgroundColor = .clear
        view.isOpaque = false
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        apply(to: view)
        return view
    }

    func updateUIView(_ uiView: OldOSCoreTextLabelView, context: Context) {
        apply(to: uiView)
    }

    private func apply(to view: OldOSCoreTextLabelView) {
        view.text = text
        view.fontSize = fontSize
        view.foregroundColor = foregroundColor
        view.fontKind = fontKind
        view.etchedColor = etchedColor
        view.etchedOffset = etchedOffset
        view.verticalAdjustment = verticalAdjustment
        view.kern = kern
        view.maximumTextWidth = maximumTextWidth
        view.setNeedsDisplay()
    }
}

final class OldOSCoreTextLabelView: UIView {
    var text: String = ""
    var fontSize: CGFloat = 22
    var foregroundColor: UIColor = .black
    var fontKind: OldOSKeyboardCoreTextFont = .keyCaps
    var etchedColor: UIColor?
    var etchedOffset: CGFloat = 1
    var verticalAdjustment: CGFloat = 0
    var kern: CGFloat = 0
    var maximumTextWidth: CGFloat?

    override func draw(_ rect: CGRect) {
        guard !text.isEmpty, let context = UIGraphicsGetCurrentContext() else { return }

        let ctFont: CTFont
        switch fontKind {
        case .keyCaps:
            if let original = OldOSKeyboardFont.ctKeyCaps(fontSize) {
                ctFont = original
            } else {
                ctFont = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
            }
        case .phonepadTwo:
            if let original = OldOSKeyboardFont.ctPhonepadTwo(fontSize) {
                ctFont = original
            } else if let keyCaps = OldOSKeyboardFont.ctKeyCaps(fontSize) {
                ctFont = keyCaps
            } else {
                ctFont = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
            }
        case .helveticaBold:

            ctFont = CTFontCreateWithName("Helvetica-Bold" as CFString, fontSize, nil)
        }

        func makeLine(font: CTFont) -> CTLine {
            var attrs: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key(kCTFontAttributeName as String): font,
                NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): true
            ]
            if kern != 0 {
                attrs[NSAttributedString.Key(kCTKernAttributeName as String)] = kern
            }
            return CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
        }

        var drawingFont = ctFont
        var line = makeLine(font: drawingFont)
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        var lineWidth = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))

        if let maximumTextWidth, lineWidth > maximumTextWidth, maximumTextWidth > 0 {
            let fittedSize = max(12, fontSize * maximumTextWidth / lineWidth)
            drawingFont = CTFontCreateCopyWithAttributes(ctFont, fittedSize, nil, nil)
            line = makeLine(font: drawingFont)
            ascent = 0; descent = 0; leading = 0
            lineWidth = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
        }

        let deviceScale = window?.screen.scale ?? UIScreen.main.scale
        func pixelAlign(_ value: CGFloat) -> CGFloat {
            (value * deviceScale).rounded() / deviceScale
        }

        let x = pixelAlign((bounds.width - lineWidth) * 0.5)

        var baseline = (bounds.height - ascent + descent) * 0.5
        baseline -= verticalAdjustment
        baseline = pixelAlign(baseline)

        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1, y: -1)
        context.setShouldSmoothFonts(true)
        context.setShouldAntialias(true)

        if let etchedColor {
            context.textPosition = CGPoint(
                x: x,
                y: pixelAlign(baseline - etchedOffset)
            )
            context.setFillColor(etchedColor.cgColor)
            CTLineDraw(line, context)
        }

        context.textPosition = CGPoint(x: x, y: baseline)
        context.setFillColor(foregroundColor.cgColor)
        CTLineDraw(line, context)
        context.restoreGState()
    }
}
