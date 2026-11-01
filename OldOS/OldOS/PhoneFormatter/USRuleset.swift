import Foundation

// This extension defines rulesets for phone numbers within the United States
public extension PNFormatRuleset {
    
    // Formats phone numbers:
    //  .local: 123-4567
    //  .domestic: 123-456-7890
    // .international: +1 234-567-8901
    static func usHyphen() -> [PhoneFormatRuleset] {
        return [
            PNFormatRuleset(.local, rules: [
                PNFormatRule(3, separator: .hyphen)
                ], maxLength: 7),
            PNFormatRuleset(.domestic, rules: [
                PNFormatRule(3, separator: .hyphen),
                PNFormatRule(6, separator: .hyphen)
                ], maxLength: 10),
            PNFormatRuleset(.international, rules: [
                PNFormatRule(0, separator: .plus),
                PNFormatRule(1, separator: .space),
                PNFormatRule(4, separator: .hyphen),
                PNFormatRule(7, separator: .hyphen)
                ], maxLength: 11)
        ]
    }
    
    // Formats phone numbers:
    //  .local: 123-4567
    //  .domestic: (123) 456-7890
    // .international: +1 (234) 567-8901
    static func usParethesis() -> [PhoneFormatRuleset] {
        return [
            PNFormatRuleset(.local, rules: [
                PNFormatRule(3, separator: .hyphen)
                ], maxLength: 7),
            PNFormatRuleset(.domestic, rules: [
                PNFormatRule(0, separator: .parenthesisLH),
                PNFormatRule(3, separator: .parenthesisRH),
                PNFormatRule(3, separator: .space, priority: 1),
                PNFormatRule(6, separator: .hyphen)
                ], maxLength: 10),
            PNFormatRuleset(.international, rules: [
                PNFormatRule(1, separator: .space, priority: 0),
                PNFormatRule(1, separator: .parenthesisLH, priority: 1),
                PNFormatRule(4, separator: .parenthesisRH),
                PNFormatRule(4, separator: .space, priority: 1),
                PNFormatRule(7, separator: .hyphen)
                ], maxLength: 10)
        ]
    }
    
    static func start_with_one() -> [PhoneFormatRuleset] {
        return [
            PNFormatRuleset(.local, rules: [
                PNFormatRule(1, separator: .space, priority: 0),
                PNFormatRule(1, separator: .parenthesisLH, priority: 1),
                PNFormatRule(4, separator: .parenthesisRH, priority: 0),
                PNFormatRule(4, separator: .space, priority: 1),
                PNFormatRule(7, separator: .hyphen)
                ], maxLength: 11),
            PNFormatRuleset(.domestic, rules: [
                PNFormatRule(1, separator: .space, priority: 0),
                PNFormatRule(1, separator: .parenthesisLH),
                PNFormatRule(4, separator: .parenthesisRH),
                PNFormatRule(4, separator: .space, priority: 1),
                PNFormatRule(7, separator: .hyphen)
                ], maxLength: 11),
            PNFormatRuleset(.international, rules: [
                PNFormatRule(1, separator: .space, priority: 0),
                PNFormatRule(1, separator: .parenthesisLH, priority: 1),
                PNFormatRule(4, separator: .parenthesisRH),
                PNFormatRule(4, separator: .space, priority: 1),
                PNFormatRule(7, separator: .hyphen)
                ], maxLength: 11)
        ]
    }
    
}
