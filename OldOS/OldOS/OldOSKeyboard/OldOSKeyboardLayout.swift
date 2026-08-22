import SwiftUI

public enum OldOSKeyboardLayout {
    public static let referenceSize = CGSize(width: 320, height: 216)

    private static let rowSlotY: [CGFloat] = [10, 64, 118, 172]
    private static let rowPitch: CGFloat = 54
    private static let faceHeight: CGFloat = 38

    private struct VariantInfo {
        let values: [String]
        let direction: OldOSKeyboardVariantDirection
    }

    public static func keys(
        plane: OldOSKeyboardKeyplane,
        shift: OldOSKeyboardShiftState,
        configuration: OldOSKeyboardConfiguration,
        returnKeyEnabled: Bool = true
    ) -> [OldOSKeyboardPlacedKey] {
        switch configuration.keyboardType {
        case .default, .asciiCapable, .alphabet, .numbersAndPunctuation:
            return standardKeys(
                plane: plane,
                shift: shift,
                configuration: configuration,
                returnKeyEnabled: returnKeyEnabled
            )

        case .emailAddress:
            return emailKeys(
                plane: plane,
                shift: shift,
                configuration: configuration,
                returnKeyEnabled: returnKeyEnabled
            )

        case .url:
            return urlKeys(
                plane: plane,
                shift: shift,
                configuration: configuration,
                returnKeyEnabled: returnKeyEnabled
            )

        case .numberPad:
            return fixedNumberPad(decimal: false)

        case .decimalPad:
            return fixedNumberPad(decimal: true)

        case .phonePad:
            return phonePad(plane: plane)

        case .namePhonePad:
            if plane == .letters {
                return namePhonePadLetters(
                    shift: shift,
                    configuration: configuration,
                    returnKeyEnabled: returnKeyEnabled
                )
            }
            return namePhonePadNumbers()

        case .smsAddressing:

            if plane == .letters {
                return namePhonePadLetters(
                    shift: shift,
                    configuration: configuration,
                    returnKeyEnabled: returnKeyEnabled
                )
            }
            return namePhonePadNumbers()
        }
    }

    private static func standardKeys(
        plane: OldOSKeyboardKeyplane,
        shift: OldOSKeyboardShiftState,
        configuration: OldOSKeyboardConfiguration,
        returnKeyEnabled: Bool
    ) -> [OldOSKeyboardPlacedKey] {
        switch plane {
        case .letters:
            return standardLetters(
                shift: shift,
                configuration: configuration,
                returnKeyEnabled: returnKeyEnabled
            )
        case .numbers:
            return standardNumbers(configuration: configuration, returnKeyEnabled: returnKeyEnabled)
        case .symbols:
            return standardSymbols(configuration: configuration, returnKeyEnabled: returnKeyEnabled)
        }
    }

    private static func standardLetters(
        shift: OldOSKeyboardShiftState,
        configuration: OldOSKeyboardConfiguration,
        returnKeyEnabled: Bool
    ) -> [OldOSKeyboardPlacedKey] {
        var result = alphabeticThreeRows(shift: shift)
        result += standardBottomRow(
            configuration: configuration,
            leftKind: .switchToNumbers,
            leftTitle: configuration.showsGlobeKey ? "123" : ".?123",
            returnKeyEnabled: returnKeyEnabled
        )
        return result
    }

    private static func standardNumbers(
        configuration: OldOSKeyboardConfiguration,
        returnKeyEnabled: Bool
    ) -> [OldOSKeyboardPlacedKey] {
        var result: [OldOSKeyboardPlacedKey] = []
        result += tenKeyRow(Array("1234567890").map(String.init), row: 0, prefix: "std-num")
        result += tenKeyRow(["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""], row: 1, prefix: "std-num")

        result.append(placed(
            OldOSKeyboardKey(id: "switch-symbols", label: "#+=", kind: .switchToSymbols, style: .dark),
            visual: utilityModifierFrame(slotX: 0, slotWidth: 46),
            hit: CGRect(x: 0, y: 108, width: 46, height: rowPitch)
        ))

        let punctuation: [(String, [String], OldOSKeyboardVariantDirection)] = [
            (".", ["…", "."], .right),
            (",", [], .automatic),
            ("?", ["¿", "?"], .right),
            ("!", ["¡", "!"], .right),
            ("'", ["’", "‘", "`", "'"], .left)
        ]
        let hitLefts: [CGFloat] = [46, 93, 138, 183, 228]
        let hitRights: [CGFloat] = [93, 138, 183, 228, 275]

        for index in punctuation.indices {
            let item = punctuation[index]
            result.append(placed(
                OldOSKeyboardKey(
                    id: "num-third-\(index)-\(item.0)",
                    label: item.0,
                    output: item.0,
                    variants: item.1,
                    variantDirection: item.2
                ),
                visual: utilityKeyFrame(hitLeft: hitLefts[index], hitRight: hitRights[index]),
                hit: CGRect(
                    x: hitLefts[index],
                    y: 108,
                    width: hitRights[index] - hitLefts[index],
                    height: rowPitch
                )
            ))
        }

        result.append(standardUtilityDelete(slotX: 275, slotWidth: 45))
        result += standardBottomRow(
            configuration: configuration,
            leftKind: .switchToLetters,
            leftTitle: "ABC",
            returnKeyEnabled: returnKeyEnabled
        )
        return result
    }

    private static func standardSymbols(
        configuration: OldOSKeyboardConfiguration,
        returnKeyEnabled: Bool
    ) -> [OldOSKeyboardPlacedKey] {
        var result: [OldOSKeyboardPlacedKey] = []
        result += tenKeyRow(["[", "]", "{", "}", "#", "%", "^", "*", "+", "="], row: 0, prefix: "std-sym")
        result += tenKeyRow(["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"], row: 1, prefix: "std-sym")

        result.append(placed(
            OldOSKeyboardKey(id: "switch-numbers", label: "123", kind: .switchToNumbers, style: .dark),
            visual: utilityModifierFrame(slotX: 0, slotWidth: 46),
            hit: CGRect(x: 0, y: 108, width: 46, height: rowPitch)
        ))

        let punctuation = [".", ",", "?", "!", "'"]
        let hitLefts: [CGFloat] = [46, 93, 138, 183, 228]
        let hitRights: [CGFloat] = [93, 138, 183, 228, 275]

        for index in punctuation.indices {
            let item = punctuation[index]
            result.append(placed(
                OldOSKeyboardKey(id: "sym-third-\(index)-\(item)", label: item, output: item),
                visual: utilityKeyFrame(hitLeft: hitLefts[index], hitRight: hitRights[index]),
                hit: CGRect(
                    x: hitLefts[index],
                    y: 108,
                    width: hitRights[index] - hitLefts[index],
                    height: rowPitch
                )
            ))
        }

        result.append(standardUtilityDelete(slotX: 275, slotWidth: 45))
        result += standardBottomRow(
            configuration: configuration,
            leftKind: .switchToLetters,
            leftTitle: "ABC",
            returnKeyEnabled: returnKeyEnabled
        )
        return result
    }

    private static func emailKeys(
        plane: OldOSKeyboardKeyplane,
        shift: OldOSKeyboardShiftState,
        configuration: OldOSKeyboardConfiguration,
        returnKeyEnabled: Bool
    ) -> [OldOSKeyboardPlacedKey] {
        switch plane {
        case .letters:
            var result = alphabeticThreeRows(shift: shift)
            result += fiveKeyBottomRow(
                configuration: configuration,
                leftKind: .switchToNumbers,
                leftTitle: ".?123",
                middle: [
                    ("space", " ", .space),
                    ("@", "@", .character),
                    (".", ".", .character)
                ],
                returnKeyEnabled: returnKeyEnabled,
                prefix: "email"
            )
            return result

        case .numbers:
            var result: [OldOSKeyboardPlacedKey] = []
            result += tenKeyRow(Array("1234567890").map(String.init), row: 0, prefix: "email-num")
            result += centeredSixKeyRow(["$", "!", "~", "&", "=", "#"], row: 1, prefix: "email-num")
            result += fourUtilityRow(
                switchTitle: "#+=",
                switchKind: .switchToSymbols,
                values: [".", "_", "-", "+"],
                prefix: "email-num"
            )
            result += fiveKeyBottomRow(
                configuration: configuration,
                leftKind: .switchToLetters,
                leftTitle: "ABC",
                middle: [
                    ("space", " ", .space),
                    ("@", "@", .character),
                    (".", ".", .character)
                ],
                returnKeyEnabled: returnKeyEnabled,
                prefix: "email"
            )
            return result

        case .symbols:
            var result: [OldOSKeyboardPlacedKey] = []
            result += tenKeyRow(["`", "|", "{", "}", "?", "%", "^", "*", "/", "'"], row: 0, prefix: "email-sym")
            result += centeredSixKeyRow(["$", "!", "~", "&", "=", "#"], row: 1, prefix: "email-sym")
            result += fourUtilityRow(
                switchTitle: "123",
                switchKind: .switchToNumbers,
                values: [".", "_", "-", "+"],
                prefix: "email-sym"
            )
            result += fiveKeyBottomRow(
                configuration: configuration,
                leftKind: .switchToLetters,
                leftTitle: "ABC",
                middle: [
                    ("space", " ", .space),
                    ("@", "@", .character),
                    (".", ".", .character)
                ],
                returnKeyEnabled: returnKeyEnabled,
                prefix: "email"
            )
            return result
        }
    }

    private static func urlKeys(
        plane: OldOSKeyboardKeyplane,
        shift: OldOSKeyboardShiftState,
        configuration: OldOSKeyboardConfiguration,
        returnKeyEnabled: Bool
    ) -> [OldOSKeyboardPlacedKey] {
        switch plane {
        case .letters:
            var result = alphabeticThreeRows(shift: shift)
            result += fiveKeyBottomRow(
                configuration: configuration,
                leftKind: .switchToNumbers,
                leftTitle: "@123",
                middle: [
                    (".", ".", .character),
                    ("/", "/", .character),
                    (".com", ".com", .character)
                ],
                returnKeyEnabled: returnKeyEnabled,
                prefix: "url"
            )
            return result

        case .numbers:
            var result: [OldOSKeyboardPlacedKey] = []
            result += tenKeyRow(Array("1234567890").map(String.init), row: 0, prefix: "url-num")
            result += centeredSixKeyRow(["@", "&", "%", "?", ",", "="], row: 1, prefix: "url-num")
            result += urlUtilityRow(values: ["_", ":", "-", "+"], prefix: "url-num")
            result += fiveKeyBottomRow(
                configuration: configuration,
                leftKind: .switchToLetters,
                leftTitle: "ABC",
                middle: [
                    (".", ".", .character),
                    ("/", "/", .character),
                    (".com", ".com", .character)
                ],
                returnKeyEnabled: returnKeyEnabled,
                prefix: "url"
            )
            return result

        case .symbols:
            var result: [OldOSKeyboardPlacedKey] = []
            result += tenKeyRow(Array("1234567890").map(String.init), row: 0, prefix: "url-sym")
            result += centeredSixKeyRow(["*", "$", "#", "!", "'", "^"], row: 1, prefix: "url-sym")
            result += urlUtilityRow(values: ["~", ";", "(", ")"], prefix: "url-sym")
            result += fiveKeyBottomRow(
                configuration: configuration,
                leftKind: .switchToLetters,
                leftTitle: "ABC",
                middle: [
                    (".", ".", .character),
                    ("/", "/", .character),
                    (".com", ".com", .character)
                ],
                returnKeyEnabled: returnKeyEnabled,
                prefix: "url"
            )
            return result
        }
    }

    private static func fixedNumberPad(decimal: Bool) -> [OldOSKeyboardPlacedKey] {
        var result: [OldOSKeyboardPlacedKey] = []
        let labels = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
        for index in labels.indices {
            let row = index / 3
            let col = index % 3
            result.append(numberPadKey(
                id: "numberpad-\(labels[index])",
                label: labels[index],
                output: labels[index],
                row: row,
                col: col,
                style: .numberPadDark
            ))
        }

        if decimal {
            result.append(numberPadKey(
                id: "numberpad-dot",
                label: ".",
                output: ".",
                row: 3,
                col: 0,
                style: .numberPadLight
            ))
        } else {
            result.append(numberPadKey(
                id: "numberpad-empty",
                label: "",
                output: nil,
                kind: .empty,
                row: 3,
                col: 0,
                style: .numberPadLight,
                isEnabled: false
            ))
        }

        result.append(numberPadKey(
            id: "numberpad-0",
            label: "0",
            output: "0",
            row: 3,
            col: 1,
            style: .numberPadDark
        ))

        result.append(numberPadKey(
            id: "numberpad-empty-right",
            label: "",
            output: nil,
            kind: .empty,
            row: 3,
            col: 2,
            style: .numberPadLight,
            isEnabled: false
        ))
        return result
    }

    private static func phonePad(plane: OldOSKeyboardKeyplane) -> [OldOSKeyboardPlacedKey] {
        if plane == .symbols {
            return phonePadAlternate()
        }
        return phonePadMain()
    }

    private static func phonePadMain() -> [OldOSKeyboardPlacedKey] {
        var result = telephoneDigits(prefix: "phone")
        result.append(numberPadKey(
            id: "phone-more",
            label: "+*#",
            output: nil,
            kind: .switchToSymbols,
            row: 3,
            col: 0,
            style: .numberPadLight
        ))
        result.append(numberPadKey(
            id: "phone-0",
            label: "0",
            output: "0",
            row: 3,
            col: 1,
            style: .numberPadDark
        ))
        result.append(numberPadKey(
            id: "phone-delete",
            label: "",
            output: nil,
            kind: .delete,
            row: 3,
            col: 2,
            style: .numberPadLight
        ))
        return result
    }

    private static func phonePadAlternate() -> [OldOSKeyboardPlacedKey] {
        var result: [OldOSKeyboardPlacedKey] = []
        let top: [(String, String?)] = [
            ("1", nil), ("2", "ABC"), ("3", "DEF"),
            ("4", "GHI"), ("5", "JKL"), ("6", "MNO")
        ]
        for index in top.indices {
            result.append(numberPadKey(
                id: "phone-alt-disabled-\(top[index].0)",
                label: top[index].0,
                output: nil,
                kind: .character,
                row: index / 3,
                col: index % 3,
                style: .numberPadDark,
                isEnabled: false,
                secondaryLabel: top[index].1
            ))
        }

        for (col, symbol) in ["+", "*", "#"].enumerated() {
            result.append(numberPadKey(
                id: "phone-alt-\(symbol)",
                label: symbol,
                output: symbol,
                row: 2,
                col: col,
                style: .numberPadDark
            ))
        }

        result.append(numberPadKey(
            id: "phone-alt-123",
            label: "123",
            output: nil,
            kind: .switchToNumbers,
            row: 3,
            col: 0,
            style: .numberPadLight
        ))
        result.append(numberPadKey(
            id: "phone-alt-pause",
            label: "pause",
            output: ",",
            row: 3,
            col: 1,
            style: .numberPadDark
        ))
        result.append(numberPadKey(
            id: "phone-alt-delete",
            label: "",
            output: nil,
            kind: .delete,
            row: 3,
            col: 2,
            style: .numberPadLight
        ))
        return result
    }

    private static func namePhonePadLetters(
        shift: OldOSKeyboardShiftState,
        configuration: OldOSKeyboardConfiguration,
        returnKeyEnabled: Bool
    ) -> [OldOSKeyboardPlacedKey] {
        var result = alphabeticThreeRows(shift: shift)
        result += standardBottomRow(
            configuration: configuration,
            leftKind: .switchToNumbers,
            leftTitle: "123",
            returnKeyEnabled: returnKeyEnabled
        )
        return result
    }

    private static func namePhonePadNumbers() -> [OldOSKeyboardPlacedKey] {
        var result = telephoneDigits(prefix: "namephone")
        result.append(numberPadKey(
            id: "namephone-abc",
            label: "ABC",
            output: nil,
            kind: .switchToLetters,
            row: 3,
            col: 0,
            style: .numberPadLight
        ))
        result.append(numberPadKey(
            id: "namephone-0-plus",
            label: "0",
            output: "0",
            row: 3,
            col: 1,
            style: .numberPadDark,
            secondaryLabel: "+",
            secondaryLabelPosition: .trailing
        ))
        result.append(numberPadKey(
            id: "namephone-delete",
            label: "",
            output: nil,
            kind: .delete,
            row: 3,
            col: 2,
            style: .numberPadLight
        ))
        return result
    }

    private static func telephoneDigits(prefix: String) -> [OldOSKeyboardPlacedKey] {
        let values: [(String, String?)] = [
            ("1", nil),
            ("2", "ABC"),
            ("3", "DEF"),
            ("4", "GHI"),
            ("5", "JKL"),
            ("6", "MNO"),
            ("7", "PQRS"),
            ("8", "TUV"),
            ("9", "WXYZ")
        ]
        return values.enumerated().map { index, item in
            numberPadKey(
                id: "\(prefix)-\(item.0)",
                label: item.0,
                output: item.0,
                row: index / 3,
                col: index % 3,
                style: .numberPadDark,
                secondaryLabel: item.1
            )
        }
    }

    private static func alphabeticThreeRows(shift: OldOSKeyboardShiftState) -> [OldOSKeyboardPlacedKey] {

        let variants = englishVariants(uppercase: shift != .off)
        var result: [OldOSKeyboardPlacedKey] = []

        result += alphabetRow(
            Array("qwertyuiop").map(String.init),
            row: 0,
            slotStartX: 0,
            shift: shift,
            variants: variants
        )

        result += alphabetRow(
            Array("asdfghjkl").map(String.init),
            row: 1,
            slotStartX: 16,
            shift: shift,
            variants: variants
        )

        result.append(placed(
            OldOSKeyboardKey(id: "shift", label: "", kind: .shift, style: .dark),
            visual: wideModifierFrame(slotX: 0, row: 2, slotWidth: 48),
            hit: CGRect(x: 0, y: 108, width: 48, height: rowPitch)
        ))

        for (index, letter) in Array("zxcvbnm").map(String.init).enumerated() {
            let slotX = CGFloat(48 + index * 32)
            let variantKey = shift == .off ? letter : letter.uppercased()
            result.append(placed(
                OldOSKeyboardKey(
                    id: "char-third-\(letter)",
                    label: letter.uppercased(),
                    output: letter,
                    kind: .character,
                    style: .light,
                    variants: variants[variantKey]?.values ?? [],
                    variantDirection: variants[variantKey]?.direction ?? .automatic
                ),
                visual: standardKeyFrame(slotX: slotX, row: 2),
                hit: CGRect(x: slotX, y: 108, width: 32, height: rowPitch)
            ))
        }

        result.append(placed(
            OldOSKeyboardKey(id: "delete", label: "", kind: .delete, style: .dark),
            visual: wideModifierFrame(slotX: 272, row: 2, slotWidth: 48),
            hit: CGRect(x: 272, y: 108, width: 48, height: rowPitch)
        ))
        return result
    }

    private static func alphabetRow(
        _ characters: [String],
        row: Int,
        slotStartX: CGFloat,
        shift: OldOSKeyboardShiftState,
        variants: [String: VariantInfo]
    ) -> [OldOSKeyboardPlacedKey] {
        characters.enumerated().map { index, value in
            let slotX = slotStartX + CGFloat(index * 32)
            let display = value.uppercased()
            let variantKey = shift == .off ? value.lowercased() : value.uppercased()

            let left: CGFloat
            let right: CGFloat
            if row == 0 {
                left = CGFloat(index * 32)
                right = left + 32
            } else {
                let center = slotX + 16
                left = index == 0 ? 0 : center - 16
                right = index == characters.count - 1 ? 320 : center + 16
            }

            let popupBias: OldOSKeyboardPopupBias
            if row == 0 && index == 0 {
                popupBias = .right
            } else if row == 0 && index == characters.count - 1 {
                popupBias = .left
            } else {
                popupBias = .none
            }

            return placed(
                OldOSKeyboardKey(
                    id: "char-\(row)-\(index)-\(value)",
                    label: display,
                    output: value,
                    kind: .character,
                    style: .light,
                    variants: variants[variantKey]?.values ?? [],
                    variantDirection: variants[variantKey]?.direction ?? .automatic,
                    popupBias: popupBias
                ),
                visual: standardKeyFrame(slotX: slotX, row: row),
                hit: CGRect(x: left, y: CGFloat(row) * rowPitch, width: right - left, height: rowPitch)
            )
        }
    }

    private static func tenKeyRow(_ characters: [String], row: Int, prefix: String) -> [OldOSKeyboardPlacedKey] {
        characters.enumerated().map { index, value in
            let slotX = CGFloat(index * 32)
            var variants: [String] = []
            var direction: OldOSKeyboardVariantDirection = .automatic
            switch value {
            case "\"":
                variants = ["”", "“", "„", "»", "«", "\""]
                direction = .left
            case "$":
                variants = ["$", "¢"]
                direction = .right
            case "-":
                variants = ["—", "•", "-"]
                direction = .right
            case "&":
                variants = ["§", "&"]
                direction = .right
            case "0":
                variants = ["°", "0"]
                direction = .left
            case "%":
                variants = ["‰", "%"]
                direction = .right
            default:
                break
            }

            let popupBias: OldOSKeyboardPopupBias
            if index == 0 {
                popupBias = .right
            } else if index == characters.count - 1 {
                popupBias = .left
            } else {
                popupBias = .none
            }

            return placed(
                OldOSKeyboardKey(
                    id: "\(prefix)-\(row)-\(index)-\(value)",
                    label: value,
                    output: value,
                    variants: variants,
                    variantDirection: direction,
                    popupBias: popupBias
                ),
                visual: standardKeyFrame(slotX: slotX, row: row),
                hit: CGRect(x: slotX, y: CGFloat(row) * rowPitch, width: 32, height: rowPitch)
            )
        }
    }

    private static func centeredSixKeyRow(_ values: [String], row: Int, prefix: String) -> [OldOSKeyboardPlacedKey] {
        precondition(values.count == 6)
        return values.enumerated().map { index, value in
            let slotX = CGFloat(16 + index * 48)
            return placed(
                OldOSKeyboardKey(id: "\(prefix)-six-\(index)-\(value)", label: value, output: value),
                visual: slotFaceFrame(slotX: slotX, row: row, slotWidth: 48),
                hit: CGRect(x: slotX, y: CGFloat(row) * rowPitch, width: 48, height: rowPitch)
            )
        }
    }

    private static func fourUtilityRow(
        switchTitle: String,
        switchKind: OldOSKeyboardKeyKind,
        values: [String],
        prefix: String
    ) -> [OldOSKeyboardPlacedKey] {
        precondition(values.count == 4)
        var result: [OldOSKeyboardPlacedKey] = []
        result.append(placed(
            OldOSKeyboardKey(id: "\(prefix)-switch", label: switchTitle, kind: switchKind, style: .dark),
            visual: slotFaceFrame(slotX: 0, row: 2, slotWidth: 48),
            hit: CGRect(x: 0, y: 108, width: 48, height: rowPitch)
        ))
        for (index, value) in values.enumerated() {
            let slotX = CGFloat(48 + index * 56)
            result.append(placed(
                OldOSKeyboardKey(id: "\(prefix)-utility-\(index)-\(value)", label: value, output: value),
                visual: slotFaceFrame(slotX: slotX, row: 2, slotWidth: 56),
                hit: CGRect(x: slotX, y: 108, width: 56, height: rowPitch)
            ))
        }
        result.append(placed(
            OldOSKeyboardKey(id: "\(prefix)-delete", label: "", kind: .delete, style: .dark),
            visual: slotFaceFrame(slotX: 272, row: 2, slotWidth: 48),
            hit: CGRect(x: 272, y: 108, width: 48, height: rowPitch)
        ))
        return result
    }

    private static func urlUtilityRow(values: [String], prefix: String) -> [OldOSKeyboardPlacedKey] {
        precondition(values.count == 4)
        var result: [OldOSKeyboardPlacedKey] = []
        result.append(placed(
            OldOSKeyboardKey(id: "\(prefix)-plane-chooser", label: "", kind: .planeChooser, style: .dark),
            visual: slotFaceFrame(slotX: 0, row: 2, slotWidth: 48),
            hit: CGRect(x: 0, y: 108, width: 48, height: rowPitch)
        ))
        for (index, value) in values.enumerated() {
            let slotX = CGFloat(48 + index * 56)
            result.append(placed(
                OldOSKeyboardKey(id: "\(prefix)-utility-\(index)-\(value)", label: value, output: value),
                visual: slotFaceFrame(slotX: slotX, row: 2, slotWidth: 56),
                hit: CGRect(x: slotX, y: 108, width: 56, height: rowPitch)
            ))
        }
        result.append(placed(
            OldOSKeyboardKey(id: "\(prefix)-delete", label: "", kind: .delete, style: .dark),
            visual: slotFaceFrame(slotX: 272, row: 2, slotWidth: 48),
            hit: CGRect(x: 272, y: 108, width: 48, height: rowPitch)
        ))
        return result
    }

    private static func standardKeyFrame(slotX: CGFloat, row: Int) -> CGRect {
        CGRect(x: slotX + 3, y: rowSlotY[row] + 2, width: 26, height: faceHeight)
    }

    private static func slotFaceFrame(slotX: CGFloat, row: Int, slotWidth: CGFloat) -> CGRect {
        CGRect(x: slotX + 3, y: rowSlotY[row] + 2, width: max(1, slotWidth - 6), height: faceHeight)
    }

    private static func wideModifierFrame(slotX: CGFloat, row: Int, slotWidth: CGFloat) -> CGRect {
        slotFaceFrame(slotX: slotX, row: row, slotWidth: slotWidth)
    }

    private static func utilityKeyFrame(hitLeft: CGFloat, hitRight: CGFloat) -> CGRect {
        let slotWidth = hitRight - hitLeft
        return CGRect(
            x: hitLeft + (slotWidth - 38) / 2,
            y: rowSlotY[2] + 2,
            width: 38,
            height: faceHeight
        )
    }

    private static func utilityModifierFrame(slotX: CGFloat, slotWidth: CGFloat) -> CGRect {
        CGRect(
            x: slotX + 3,
            y: rowSlotY[2] + 2,
            width: max(1, slotWidth - 6),
            height: faceHeight
        )
    }

    private static func standardUtilityDelete(slotX: CGFloat, slotWidth: CGFloat) -> OldOSKeyboardPlacedKey {
        placed(
            OldOSKeyboardKey(id: "delete", label: "", kind: .delete, style: .dark),
            visual: utilityModifierFrame(slotX: slotX, slotWidth: slotWidth),
            hit: CGRect(x: slotX, y: 108, width: slotWidth, height: rowPitch)
        )
    }

    private static func standardBottomRow(
        configuration: OldOSKeyboardConfiguration,
        leftKind: OldOSKeyboardKeyKind,
        leftTitle: String,
        returnKeyEnabled: Bool
    ) -> [OldOSKeyboardPlacedKey] {
        let y = rowSlotY[3] + 2

        if configuration.showsGlobeKey {
            return [
                placed(
                    OldOSKeyboardKey(id: "bottom-left", label: leftTitle, kind: leftKind, style: .dark),
                    visual: CGRect(x: 3, y: y, width: 50, height: faceHeight),
                    hit: CGRect(x: 0, y: 162, width: 56, height: 54)
                ),
                placed(
                    OldOSKeyboardKey(id: "globe", label: "", kind: .globe, style: .dark),
                    visual: CGRect(x: 59, y: y, width: 42, height: faceHeight),
                    hit: CGRect(x: 56, y: 162, width: 48, height: 54)
                ),
                placed(
                    OldOSKeyboardKey(id: "space", label: "space", output: " ", kind: .space, style: .light),
                    visual: CGRect(x: 107, y: y, width: 130, height: faceHeight),
                    hit: CGRect(x: 104, y: 162, width: 136, height: 54)
                ),
                returnKey(configuration: configuration, enabled: returnKeyEnabled, visualX: 243, visualWidth: 74, hitX: 240, hitWidth: 80)
            ]
        }

        return [
            placed(
                OldOSKeyboardKey(id: "bottom-left", label: leftTitle, kind: leftKind, style: .dark),
                visual: CGRect(x: 3, y: y, width: 74, height: faceHeight),
                hit: CGRect(x: 0, y: 162, width: 80, height: 54)
            ),
            placed(
                OldOSKeyboardKey(id: "space", label: "space", output: " ", kind: .space, style: .light),
                visual: CGRect(x: 83, y: y, width: 154, height: faceHeight),
                hit: CGRect(x: 80, y: 162, width: 160, height: 54)
            ),
            returnKey(configuration: configuration, enabled: returnKeyEnabled, visualX: 243, visualWidth: 74, hitX: 240, hitWidth: 80)
        ]
    }

    private static func fiveKeyBottomRow(
        configuration: OldOSKeyboardConfiguration,
        leftKind: OldOSKeyboardKeyKind,
        leftTitle: String,
        middle: [(label: String, output: String, kind: OldOSKeyboardKeyKind)],
        returnKeyEnabled: Bool,
        prefix: String
    ) -> [OldOSKeyboardPlacedKey] {
        precondition(middle.count == 3)
        let y = rowSlotY[3] + 2
        let boundaries: [CGFloat] = [0, 80, 133, 186, 240, 320]
        var result: [OldOSKeyboardPlacedKey] = []

        result.append(placed(
            OldOSKeyboardKey(id: "\(prefix)-bottom-left", label: leftTitle, kind: leftKind, style: .dark),
            visual: CGRect(x: 3, y: y, width: 74, height: faceHeight),
            hit: CGRect(x: 0, y: 162, width: 80, height: rowPitch)
        ))

        for index in 0..<3 {
            let left = boundaries[index + 1]
            let right = boundaries[index + 2]
            let item = middle[index]
            result.append(placed(
                OldOSKeyboardKey(
                    id: "\(prefix)-bottom-mid-\(index)-\(item.label)",
                    label: item.label,
                    output: item.output,
                    kind: item.kind,
                    style: .light
                ),
                visual: CGRect(x: left + 3, y: y, width: right - left - 6, height: faceHeight),
                hit: CGRect(x: left, y: 162, width: right - left, height: rowPitch)
            ))
        }

        result.append(returnKey(
            configuration: configuration,
            enabled: returnKeyEnabled,
            visualX: 243,
            visualWidth: 74,
            hitX: 240,
            hitWidth: 80
        ))
        return result
    }

    private static func returnKey(
        configuration: OldOSKeyboardConfiguration,
        enabled: Bool,
        visualX: CGFloat,
        visualWidth: CGFloat,
        hitX: CGFloat,
        hitWidth: CGFloat
    ) -> OldOSKeyboardPlacedKey {
        placed(
            OldOSKeyboardKey(
                id: "return",
                label: configuration.returnType.title,
                kind: .returnKey,
                style: configuration.returnType.usesBlueKey && enabled ? .blue : .dark,
                isEnabled: enabled
            ),
            visual: CGRect(x: visualX, y: rowSlotY[3] + 2, width: visualWidth, height: faceHeight),
            hit: CGRect(x: hitX, y: 162, width: hitWidth, height: rowPitch)
        )
    }

    private static func numberPadKey(
        id: String,
        label: String,
        output: String?,
        kind: OldOSKeyboardKeyKind = .character,
        row: Int,
        col: Int,
        style: OldOSKeyboardKeyStyle,
        isEnabled: Bool = true,
        secondaryLabel: String? = nil,
        secondaryLabelPosition: OldOSKeyboardSecondaryLabelPosition = .below
    ) -> OldOSKeyboardPlacedKey {
        let colWidth = referenceSize.width / 3
        let x = CGFloat(col) * colWidth
        let y = CGFloat(row) * rowPitch
        let width = col == 2 ? referenceSize.width - x : colWidth
        return placed(
            OldOSKeyboardKey(
                id: id,
                label: label,
                output: output,
                kind: kind,
                style: style,
                isEnabled: isEnabled,
                secondaryLabel: secondaryLabel,
                secondaryLabelPosition: secondaryLabelPosition
            ),
            visual: CGRect(x: x, y: y, width: width, height: rowPitch),
            hit: CGRect(x: x, y: y, width: width, height: rowPitch)
        )
    }

    private static func placed(_ key: OldOSKeyboardKey, visual: CGRect, hit: CGRect) -> OldOSKeyboardPlacedKey {
        OldOSKeyboardPlacedKey(key: key, visualFrame: visual, hitFrame: hit)
    }

    private static func englishVariants(uppercase: Bool) -> [String: VariantInfo] {
        let lower: [String: VariantInfo] = [
            "a": VariantInfo(values: ["a", "à", "á", "â", "ä", "æ", "ã", "å", "ā"], direction: .right),
            "c": VariantInfo(values: ["c", "ç", "ć", "č"], direction: .right),
            "e": VariantInfo(values: ["e", "è", "é", "ê", "ë", "ē", "ę"], direction: .right),
            "i": VariantInfo(values: ["i", "î", "ï", "í", "ī", "į", "ì"], direction: .left),
            "l": VariantInfo(values: ["l", "ł"], direction: .left),
            "n": VariantInfo(values: ["n", "ñ", "ń"], direction: .left),
            "o": VariantInfo(values: ["o", "ô", "ö", "ò", "ó", "œ", "ø", "ō", "õ"], direction: .left),
            "s": VariantInfo(values: ["s", "ß", "ś", "š"], direction: .right),
            "u": VariantInfo(values: ["u", "û", "ü", "ù", "ú", "ū"], direction: .left),
            "y": VariantInfo(values: ["y", "ÿ"], direction: .left),
            "z": VariantInfo(values: ["z", "ž", "ź", "ż"], direction: .right)
        ]
        guard uppercase else { return lower }

        return [
            "A": VariantInfo(values: ["A", "À", "Á", "Â", "Ä", "Æ", "Ã", "Å", "Ā"], direction: .right),
            "C": VariantInfo(values: ["C", "Ç", "Ć", "Č"], direction: .right),
            "E": VariantInfo(values: ["E", "È", "É", "Ê", "Ë", "Ē", "Ę"], direction: .right),
            "I": VariantInfo(values: ["I", "Î", "Ï", "Í", "Ī", "Į", "Ì"], direction: .left),
            "L": VariantInfo(values: ["L", "Ł"], direction: .left),
            "N": VariantInfo(values: ["N", "Ñ", "Ń"], direction: .left),
            "O": VariantInfo(values: ["O", "Ô", "Ö", "Ò", "Ó", "Œ", "Ø", "Ō", "Õ"], direction: .left),
            "S": VariantInfo(values: ["S", "Ś", "Š"], direction: .right),
            "U": VariantInfo(values: ["U", "Û", "Ü", "Ù", "Ú", "Ū"], direction: .left),
            "Y": VariantInfo(values: ["Y", "Ÿ"], direction: .left),
            "Z": VariantInfo(values: ["Z", "Ž", "Ź", "Ż"], direction: .right)
        ]
    }
}
