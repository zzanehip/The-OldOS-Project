import Foundation

// Defines separators that are available for use in formatting
// phone number strings.
public enum PhoneFormatSeparator {
    case hyphen
    case plus
    case space
    case parenthesisLH
    case parenthesisRH
    case slash
    case backslash
    case pipe
    case asterisk
    
    public var value: String {
        switch self {
        case .hyphen: return "-"
        case .plus: return "+"
        case .space: return " "
        case .parenthesisLH: return "("
        case .parenthesisRH: return ")"
        case .slash: return "/"
        case .backslash: return "\\"
        case .pipe: return "|"
        case .asterisk: return "*"
        }
    }
}
