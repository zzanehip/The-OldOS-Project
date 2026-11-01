import SwiftUI
import UIKit
import CoreText
import CoreGraphics

enum OldOSKeyboardFont {
    static let originalPostScriptName = ".PhoneKeyCaps"

    private static let originalCGFont: CGFont? = {
        guard let url = Bundle.main.url(forResource: "PhoneKeyCaps", withExtension: "ttf") else {
            print("OldOSKeyboard: PhoneKeyCaps.ttf is not present in the app bundle")
            return nil
        }

        guard let provider = CGDataProvider(url: url as CFURL) else {
            print("OldOSKeyboard: could not create CGDataProvider for PhoneKeyCaps.ttf")
            return nil
        }

        guard let font = CGFont(provider) else {
            print("OldOSKeyboard: CoreGraphics could not parse PhoneKeyCaps.ttf")
            return nil
        }

        #if DEBUG
        let psName = font.postScriptName as String? ?? "<unknown>"
        print("OldOSKeyboard: directly loaded PhoneKeyCaps.ttf as CGFont; PostScript name = \(psName)")
        #endif

        return font
    }()

    private static let phonepadTwoCGFont: CGFont? = {
        guard let url = Bundle.main.url(forResource: "PhonepadTwo", withExtension: "ttf") else {
            print("OldOSKeyboard: PhonepadTwo.ttf is not present in the app bundle")
            return nil
        }

        guard let provider = CGDataProvider(url: url as CFURL) else {
            print("OldOSKeyboard: could not create CGDataProvider for PhonepadTwo.ttf")
            return nil
        }

        guard let font = CGFont(provider) else {
            print("OldOSKeyboard: CoreGraphics could not parse PhonepadTwo.ttf")
            return nil
        }

        #if DEBUG
        let psName = font.postScriptName as String? ?? "<unknown>"
        print("OldOSKeyboard: directly loaded PhonepadTwo.ttf as CGFont; PostScript name = \(psName)")
        #endif

        return font
    }()

    static var hasOriginalKeyCapsFont: Bool {
        originalCGFont != nil
    }

    static func ctKeyCaps(_ size: CGFloat) -> CTFont? {
        guard let graphicsFont = originalCGFont else { return nil }
        return CTFontCreateWithGraphicsFont(graphicsFont, size, nil, nil)
    }

    static func ctPhonepadTwo(_ size: CGFloat) -> CTFont? {
        guard let graphicsFont = phonepadTwoCGFont else { return nil }
        return CTFontCreateWithGraphicsFont(graphicsFont, size, nil, nil)
    }

    static func keyCaps(_ size: CGFloat) -> Font {
        if let ctFont = ctKeyCaps(size) {
            return Font(ctFont)
        }

        return .custom("Helvetica-Bold", size: size)
    }

    static func debugPrintLoadedFont(_ size: CGFloat = 22) {
        guard let ctFont = ctKeyCaps(size) else {
            print("OldOSKeyboard: PhoneKeyCaps direct-load FAILED")
            return
        }

        let psName = CTFontCopyPostScriptName(ctFont) as String
        let family = CTFontCopyFamilyName(ctFont) as String
        print("OldOSKeyboard: CTFont direct-load OK; postScript=\(psName), family=\(family), size=\(CTFontGetSize(ctFont))")
    }

    static let shiftSmall = "\u{F7E2}"
    static let shiftLarge = "\u{F7E3}"
    static let deleteMedium = "\u{F7E4}"
    static let deleteWide = "\u{E008}"
    static let deleteNarrow = "\u{E00A}"
    static let globe = "\u{E005}"
    static let search = "\u{F7F3}"
}
