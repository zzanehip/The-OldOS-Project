import Foundation

/// Defines the rule sets associated with a given phone number type.
/// e.g. international/domestic/local
public protocol PhoneFormatRuleset {
    
    /// The type of phone number formatting to which these rules apply
    var type: PhoneFormatType { get set }
    
    /// A collection of rules to apply for this phone number type.
    var rules: [PhoneNumberFormatRule] { get set }
    
    /// The maximum length a number using this format ruleset should be. (Inclusive)
    var maxLength: Int { get set }
}

public extension PhoneFormatRuleset {
    
    /// Given a phone number string '1234567'. Any formatting rules to be applied to the start of the phone number string (index 0) would be retrieved by calling this function and passing 0 as the index. If any rules apply they will be returned in ascending order of priority.
    ///
    /// - Parameter index: The index (0 based) for a phone number where formatting is to be applied using the rules for this ruleset.
    /// - Returns: If found returns an array of rules sorted in ascending order of priority. Else nil.
    func rules(for index: Int) -> [PhoneNumberFormatRule]? {
        return rules.filter({ $0.index == index }).sorted(by: ({ $0.priority < $1.priority }))
    }
    
    /// Given an index within a phone number string, this function will fetch all the rules for the requested index and concatenate all applicable rule separator values into a single string in ascending order of priority.
    ///
    /// - Parameter index: The index of a phone number string in which to add a separator character(s).
    /// - Returns: If rules are found that apply to the requested index, the separator values will be returned, else nil.
    func separator(for index: Int) -> String? {
        
        // check for rules
        guard let rules = rules(for: index) else {
            return nil
        }
        
        // if there's only one rule, return it's separator value
        guard rules.count > 1 else {
            return rules.first?.separator.value
        }
        
        // concatenate the separator values and return the joined string
        return rules.map({ $0.separator.value }).joined()
    }
}

/// Default implementation of the PhoneFormatRuleset. 
open class PNFormatRuleset: PhoneFormatRuleset {
    public var type: PhoneFormatType
    public var rules: [PhoneNumberFormatRule]
    public var maxLength: Int
    
    public init(_ type: PhoneFormatType, rules: [PhoneNumberFormatRule], maxLength: Int) {
        self.type = type
        self.rules = rules
        self.maxLength = maxLength
    }
}
