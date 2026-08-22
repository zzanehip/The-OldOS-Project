import Foundation

// defines the separators that should be inserted in a phone number string
// and the indexes where they should be applied
public protocol PhoneNumberFormatRule {
    
    // the index in a phone number where this separator should be applied
    var index: Int { get set }
    
    // the priority in which this rule should be applied. Sorted in inverse, 0 is highest priority, higher numbers are lower priority
    var priority: Int { get set }
    
    // the separator to use at this index
    var separator: PhoneFormatSeparator { get set }
}

/// Default implementation of PhoneNumberFormatRule
open class PNFormatRule: PhoneNumberFormatRule {
    public var index: Int
    public var priority: Int
    public var separator: PhoneFormatSeparator
    
    public init(_ index: Int, separator: PhoneFormatSeparator, priority: Int = 0) {
        self.index = index
        self.separator = separator
        self.priority = priority
    }
}
