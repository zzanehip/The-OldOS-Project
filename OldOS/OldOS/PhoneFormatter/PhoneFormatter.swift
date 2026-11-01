import Foundation

/// Handles formatting of a string according to format rules supplied at instantiation
open class PhoneFormatter {
    
    // a list of format rulesets to be applied
    internal var rulesets: [PhoneFormatRuleset]
    
    public init(rulesets: [PhoneFormatRuleset]) {
        self.rulesets = rulesets
    }
    
    // Given an index, determine which type of ruleset should be applied to the phone number string
    func type(for index: Int) -> PhoneFormatType? {
        
        // filter out rulesets where our index exceeds the max length of the defined rule
        // then sort them in ascending order of maxLength... then get the shortest that applies
        return rulesets.filter({ index <= $0.maxLength }).sorted(by: {$0.maxLength < $1.maxLength}).first?.type
    }
    
    // gets the appropriate format ruleset based on the type of
    // formatting desired (international/domestic/local)
    func ruleset(for type: PhoneFormatType) -> PhoneFormatRuleset? {
        return rulesets.filter({ $0.type == type }).first
    }
    
    // formats a string using the format rule provided at initialization
    public func format(number: String) -> String {
        
        // strip non numeric characters
        let n = number//.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // bail if we have an empty string, or if no ruleset is defined to handle formatting
        guard n.count > 0, let type = type(for: n.count), let ruleset = ruleset(for: type) else {
            return n
        }
        
        // this is the string we'll return
        var formatted = ""
        
        // enumerate the numeric string
        for (i,character) in n.enumerated() {
            
            // bail if user entered more numbers than allowed for our formatting ruleset
            guard i <= ruleset.maxLength else {
                break
            }
            
            // if there is a separator defined to be inserted at this index then add it to the formatted string
            if let separator = ruleset.separator(for: i) {
                formatted+=separator
            }
            
            // now append the character
            formatted+="\(character)"
        }
        
        return formatted
    }
}
