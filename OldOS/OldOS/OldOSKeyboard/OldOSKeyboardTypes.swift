import SwiftUI
import UIKit

public enum OldOSKeyboardKeyplane: String, CaseIterable {
    case letters
    case numbers
    case symbols
}

public enum OldOSKeyboardType: String, CaseIterable, Equatable {
    case `default`
    case asciiCapable
    case numbersAndPunctuation
    case url
    case numberPad
    case phonePad
    case namePhonePad
    case emailAddress
    case decimalPad
    case alphabet
    case smsAddressing

    var initialPlane: OldOSKeyboardKeyplane {
        switch self {
        case .numbersAndPunctuation, .numberPad, .decimalPad, .phonePad, .smsAddressing:
            return .numbers
        default:
            return .letters
        }
    }

    var hasAlphabeticPlane: Bool {
        switch self {
        case .numberPad, .decimalPad, .phonePad:
            return false
        default:
            return true
        }
    }

    var allowsAutomaticCapitalization: Bool {
        switch self {
        case .emailAddress, .url, .numberPad, .decimalPad, .phonePad, .namePhonePad, .smsAddressing:
            return false
        default:
            return true
        }
    }

    var isNumberPadFamily: Bool {
        switch self {
        case .numberPad, .decimalPad, .phonePad, .namePhonePad, .smsAddressing:
            return true
        default:
            return false
        }
    }
}

extension OldOSKeyboardType {

    var uiKeyboardType: UIKeyboardType {
        switch self {
        case .default: return .default
        case .asciiCapable: return .asciiCapable
        case .numbersAndPunctuation: return .numbersAndPunctuation
        case .url: return .URL
        case .numberPad: return .numberPad
        case .phonePad: return .phonePad
        case .namePhonePad: return .namePhonePad
        case .emailAddress: return .emailAddress
        case .decimalPad: return .decimalPad
        case .alphabet: return .alphabet
        case .smsAddressing: return .namePhonePad
        }
    }
}

public enum OldOSKeyboardShiftState: Equatable {
    case off
    case on
    case locked
}

public enum OldOSKeyboardShiftOrigin: Equatable {
    case manual
    case automatic
}

public enum OldOSKeyboardReturnType: Equatable {
    case `default`
    case go
    case google
    case join
    case next
    case route
    case search
    case send
    case yahoo
    case done
    case emergencyCall

    var title: String {
        switch self {
        case .default: return "return"
        case .go: return "Go"
        case .google: return "Google"
        case .join: return "Join"
        case .next: return "Next"
        case .route: return "Route"
        case .search: return "Search"
        case .send: return "Send"
        case .yahoo: return "Yahoo!"
        case .done: return "Done"
        case .emergencyCall: return "Emergency Call"
        }
    }

    var usesBlueKey: Bool {
        self != .default
    }
}

extension OldOSKeyboardReturnType {
    var uiReturnKeyType: UIReturnKeyType {
        switch self {
        case .default: return .default
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
        }
    }
}

public enum OldOSKeyboardKeyKind: Hashable {
    case character
    case shift
    case delete
    case switchToNumbers
    case switchToSymbols
    case switchToLetters

    case planeChooser
    case globe
    case space
    case returnKey

    case empty
}

public enum OldOSKeyboardSecondaryLabelPosition: Hashable {
    case below
    case trailing
}

public enum OldOSKeyboardVariantDirection: Hashable {
    case automatic
    case left
    case right
}

public enum OldOSKeyboardPopupBias: Hashable {
    case none
    case left
    case right
}

public enum OldOSKeyboardKeyStyle: Hashable {
    case light
    case dark
    case blue

    case numberPadDark
    case numberPadLight
}

public struct OldOSKeyboardConfiguration: Equatable {
    public var keyboardType: OldOSKeyboardType
    public var returnType: OldOSKeyboardReturnType
    public var autocapitalization: Bool

    public var autocorrection: Bool
    public var enablesCapsLock: Bool
    public var playsKeyClicks: Bool
    public var doubleSpacePeriod: Bool
    public var showsGlobeKey: Bool
    public var dismissesOnReturn: Bool

    public var enablesReturnKeyAutomatically: Bool

    public init(
        keyboardType: OldOSKeyboardType = .default,
        returnType: OldOSKeyboardReturnType = .default,
        autocapitalization: Bool = true,
        autocorrection: Bool = true,
        enablesCapsLock: Bool = true,
        playsKeyClicks: Bool = true,
        doubleSpacePeriod: Bool = true,
        showsGlobeKey: Bool = false,
        dismissesOnReturn: Bool = false,
        enablesReturnKeyAutomatically: Bool = false
    ) {
        self.keyboardType = keyboardType
        self.returnType = returnType
        self.autocapitalization = autocapitalization
        self.autocorrection = autocorrection
        self.enablesCapsLock = enablesCapsLock
        self.playsKeyClicks = playsKeyClicks
        self.doubleSpacePeriod = doubleSpacePeriod
        self.showsGlobeKey = showsGlobeKey
        self.dismissesOnReturn = dismissesOnReturn
        self.enablesReturnKeyAutomatically = enablesReturnKeyAutomatically
    }

    public static let standard = OldOSKeyboardConfiguration()

    public static let search = OldOSKeyboardConfiguration(
        returnType: .search,

        autocorrection: true,
        dismissesOnReturn: true,
        enablesReturnKeyAutomatically: true
    )

    public static let email = OldOSKeyboardConfiguration(
        keyboardType: .emailAddress,
        autocapitalization: false,
        autocorrection: false
    )

    public static let url = OldOSKeyboardConfiguration(
        keyboardType: .url,
        returnType: .go,
        autocapitalization: false,
        autocorrection: false,
        doubleSpacePeriod: false,
        dismissesOnReturn: true,
        enablesReturnKeyAutomatically: true
    )
}

public struct OldOSKeyboardKey: Identifiable, Hashable {
    public let id: String
    public let label: String
    public let output: String?
    public let kind: OldOSKeyboardKeyKind
    public let style: OldOSKeyboardKeyStyle
    public let variants: [String]
    public let variantDirection: OldOSKeyboardVariantDirection
    public let popupBias: OldOSKeyboardPopupBias
    public let isEnabled: Bool
    public let secondaryLabel: String?
    public let secondaryLabelPosition: OldOSKeyboardSecondaryLabelPosition

    public init(
        id: String,
        label: String,
        output: String? = nil,
        kind: OldOSKeyboardKeyKind = .character,
        style: OldOSKeyboardKeyStyle = .light,
        variants: [String] = [],
        variantDirection: OldOSKeyboardVariantDirection = .automatic,
        popupBias: OldOSKeyboardPopupBias = .none,
        isEnabled: Bool = true,
        secondaryLabel: String? = nil,
        secondaryLabelPosition: OldOSKeyboardSecondaryLabelPosition = .below
    ) {
        self.id = id
        self.label = label
        self.output = output
        self.kind = kind
        self.style = style
        self.variants = variants
        self.variantDirection = variantDirection
        self.popupBias = popupBias
        self.isEnabled = isEnabled
        self.secondaryLabel = secondaryLabel
        self.secondaryLabelPosition = secondaryLabelPosition
    }

    func displayLabel(shift: OldOSKeyboardShiftState) -> String {
        guard kind == .character, let output else { return label }

        let outputIsAlphabetic = output.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
        guard outputIsAlphabetic else { return label }
        return label.uppercased()
    }

    func committedText(shift: OldOSKeyboardShiftState) -> String? {
        guard let output else { return nil }
        guard kind == .character else { return output }

        let isAlphabetic = output.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
        guard isAlphabetic else { return output }
        guard shift != .off else { return output.lowercased() }
        return output.uppercased()
    }

    var showsTapPopup: Bool {
        guard kind == .character, label.count == 1 else { return false }
        switch style {
        case .numberPadDark, .numberPadLight:
            return false
        default:
            return true
        }
    }
}

public struct OldOSKeyboardPlacedKey: Identifiable {
    public let key: OldOSKeyboardKey
    public let visualFrame: CGRect
    public let hitFrame: CGRect

    public var id: String { key.id }
    public var center: CGPoint {
        CGPoint(x: visualFrame.midX, y: visualFrame.midY)
    }
}
