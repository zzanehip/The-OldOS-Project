import Foundation

public final class OldOSZephyrStaticLanguageModel {
    public enum ModelError: Error, CustomStringConvertible {
        case missingResource(String)
        case malformed(String)
        case unsupportedVersion(magic: UInt32, major: UInt32, minor: UInt32)

        public var description: String {
            switch self {
            case .missingResource(let name): return "Missing Zephyr resource: \(name)"
            case .malformed(let reason): return "Malformed iOS 4.3 Zephyr trie: \(reason)"
            case .unsupportedVersion(let magic, let major, let minor):
                return "Unsupported Zephyr trie header \(magic)/\(major)/\(minor)"
            }
        }
    }

    public struct TrieMetadata: Equatable {
        public let wordCount: UInt32
        public let compilationFlags: UInt32
        public let commonLetterFormsOffset: Int
        public let trieRootOffset: Int
        public let unigramPayloadOffset: Int
    }

    public struct NextLetter: Identifiable, Equatable {
        public let character: Character
        public let probability: Double
        public var id: Character { character }
    }

    public struct AutocorrectionCandidate: Equatable {

        public let word: String

        public let sortKey: String
        public let editDistance: Int
        public let lexicalScore: Double

        public let surfaceOrder: Int

        public let capitalizationMask: UInt32
        public let recordFlags: UInt8
        public let wordFlags: UInt8
        public let hasExplicitSurfaceForm: Bool

        public let isDynamic: Bool
        public let dynamicUserFrequency: Int

        public let ztOmegaLogLikelihood: Double?
        public let ztPhysicalLogLikelihood: Double?
        public let ztStringContextLogLikelihood: Double?
        public let ztConsumedStrokeCount: Int?
        public let ztPredictedSymbolCount: Int
        public let ztErasedStrokeCount: Int
        public let ztCameFromPredictStroke: Bool
        public let ztCameFromSpellFallback: Bool

        public let spellCheckQuality: Double?

        public init(
            word: String,
            sortKey: String? = nil,
            editDistance: Int,
            lexicalScore: Double,
            surfaceOrder: Int = 0,
            capitalizationMask: UInt32 = 0,
            recordFlags: UInt8 = 0,
            wordFlags: UInt8 = 0,
            hasExplicitSurfaceForm: Bool = false,
            isDynamic: Bool = false,
            dynamicUserFrequency: Int = 0,
            ztOmegaLogLikelihood: Double? = nil,
            ztPhysicalLogLikelihood: Double? = nil,
            ztStringContextLogLikelihood: Double? = nil,
            ztConsumedStrokeCount: Int? = nil,
            ztPredictedSymbolCount: Int = 0,
            ztErasedStrokeCount: Int = 0,
            ztCameFromPredictStroke: Bool = false,
            ztCameFromSpellFallback: Bool = false,
            spellCheckQuality: Double? = nil
        ) {
            self.word = word
            self.sortKey = sortKey
                ?? OldOSZephyrStaticLanguageModel.autocorrectionLookupKey(for: word)
                ?? word.lowercased()
            self.editDistance = editDistance
            self.lexicalScore = lexicalScore
            self.surfaceOrder = surfaceOrder
            self.capitalizationMask = capitalizationMask
            self.recordFlags = recordFlags
            self.wordFlags = wordFlags
            self.hasExplicitSurfaceForm = hasExplicitSurfaceForm
            self.isDynamic = isDynamic
            self.dynamicUserFrequency = dynamicUserFrequency
            self.ztOmegaLogLikelihood = ztOmegaLogLikelihood
            self.ztPhysicalLogLikelihood = ztPhysicalLogLikelihood
            self.ztStringContextLogLikelihood = ztStringContextLogLikelihood
            self.ztConsumedStrokeCount = ztConsumedStrokeCount
            self.ztPredictedSymbolCount = ztPredictedSymbolCount
            self.ztErasedStrokeCount = ztErasedStrokeCount
            self.ztCameFromPredictStroke = ztCameFromPredictStroke
            self.ztCameFromSpellFallback = ztCameFromSpellFallback
            self.spellCheckQuality = spellCheckQuality
        }

        public var hasDictionaryCapitalization: Bool {
            if capitalizationMask != 0 { return true }
            let letters = word.filter { $0.isLetter }
            guard !letters.isEmpty else { return false }
            return letters != letters.lowercased()
        }
    }

    private struct PackedSibling {
        let offset: Int
        let flags: UInt8
        let patricia: [UInt8]
        let childOffset: Int
        let compactedFrequency: UInt8
        let directTerminationByte: UInt8?
        let unigramListOffset: Int?
        let nextSiblingOffset: Int?

        var partialProbability: Double {
            let x = Double(compactedFrequency) / 255.0
            return x * x
        }

        var directTerminationProbability: Double? {
            guard let b = directTerminationByte else { return nil }
            let x = Double(b) / 255.0
            return x * x
        }
    }

    private let idx: Data
    private let dat: Data
    private var sortKeyToCodePoint: [[UInt8]: UInt32] = [:]
    private var codePointToSortKey: [UInt32: [UInt8]] = [:]

    public let metadata: TrieMetadata

    private static let magic: UInt32 = 1
    private static let requiredMajor: UInt32 = 3
    private static let minimumMinor: UInt32 = 5
    private static let headerSize = 128

    public init(indexData: Data, unigramData: Data) throws {
        self.idx = indexData
        self.dat = unigramData

        try Self.validateHeader(indexData)
        try Self.validateHeader(unigramData)

        let wordCount = try Self.readBE32(unigramData, at: 0x24)
        let compilationFlags = try Self.readBE32(indexData, at: 0x28)
        let commonOffset = Int(try Self.readBE32(indexData, at: 0x38))
        let rootOffset = Int(try Self.readBE32(indexData, at: 0x44))
        let payloadOffset = Int(try Self.readBE32(unigramData, at: 0x44))

        guard commonOffset >= Self.headerSize, commonOffset < indexData.count else {
            throw ModelError.malformed("common letter-form table offset \(commonOffset)")
        }
        guard rootOffset >= Self.headerSize, rootOffset < indexData.count else {
            throw ModelError.malformed("trie root offset \(rootOffset)")
        }

        self.metadata = TrieMetadata(
            wordCount: wordCount,
            compilationFlags: compilationFlags,
            commonLetterFormsOffset: commonOffset,
            trieRootOffset: rootOffset,
            unigramPayloadOffset: payloadOffset
        )

        let maps = try Self.loadCommonLetterForms(from: indexData, offset: commonOffset)
        self.sortKeyToCodePoint = maps.forward
        self.codePointToSortKey = maps.reverse
    }

    public convenience init(indexURL: URL, unigramURL: URL) throws {
        try self.init(indexData: Data(contentsOf: indexURL), unigramData: Data(contentsOf: unigramURL))
    }

    public static func bundledUS() throws -> OldOSZephyrStaticLanguageModel {
        let candidateBundles = [Bundle.main] + Bundle.allFrameworks + Bundle.allBundles
        var seen = Set<ObjectIdentifier>()

        for bundle in candidateBundles {
            let oid = ObjectIdentifier(bundle)
            guard seen.insert(oid).inserted else { continue }
            if let idxURL = bundle.url(forResource: "Unigrams-en_US", withExtension: "idx"),
               let datURL = bundle.url(forResource: "Unigrams-en_US", withExtension: "dat") {
                return try OldOSZephyrStaticLanguageModel(indexURL: idxURL, unigramURL: datURL)
            }
        }
        throw ModelError.missingResource("Unigrams-en_US.idx / Unigrams-en_US.dat")
    }

    public func nextLetterProbabilities(after prefix: String) -> [Character: Double] {
        guard let sortKey = try? sortKey(forASCIIWord: prefix) else { return [:] }

        let candidateRecords: [PackedSibling]
        if sortKey.isEmpty {
            candidateRecords = (try? siblings(at: metadata.trieRootOffset)) ?? []
        } else {
            let cursorValue: Cursor?
            do {
                cursorValue = try cursor(for: sortKey)
            } catch {
                return [:]
            }
            guard let cursor = cursorValue else { return [:] }
            if cursor.segmentIndex < cursor.record.patricia.count {
                let next = cursor.record.patricia[cursor.segmentIndex]
                guard let ch = character(forPrimarySortKeyByte: next), ch.isASCIILetter else { return [:] }
                return [ch: 1.0]
            }
            guard cursor.record.childOffset != 0 else { return [:] }
            candidateRecords = (try? siblings(at: cursor.record.childOffset)) ?? []
        }

        var result: [Character: Double] = [:]
        for record in candidateRecords {
            guard let first = record.patricia.first,
                  let ch = character(forPrimarySortKeyByte: first),
                  ch.isASCIILetter else { continue }
            result[ch] = record.partialProbability
        }
        return result
    }

    public func sortedNextLetters(after prefix: String) -> [NextLetter] {
        nextLetterProbabilities(after: prefix)
            .map { NextLetter(character: $0.key, probability: $0.value) }
            .sorted {
                if $0.probability == $1.probability { return String($0.character) < String($1.character) }
                return $0.probability > $1.probability
            }
    }

    public func logProbability(wordPrefix: String, appending candidate: Character) -> Double {
        let c = Character(String(candidate).lowercased())
        guard let p = nextLetterProbabilities(after: wordPrefix)[c], p > 0 else {
            return -Double.infinity
        }
        return log(p)
    }

    public struct PredictiveExtensionEvidence: Equatable {
        public let suffixLength: Int
        public let dictionaryExtensionLogLikelihood: Double
        public let predictionCostLogLikelihood: Double

        public var combinedExtensionLogLikelihood: Double {
            dictionaryExtensionLogLikelihood + predictionCostLogLikelihood
        }
    }

    public func predictiveExtensionEvidence(
        fromASCIIWordPrefix prefix: String,
        toASCIIWord candidateSortKey: String,
        nonStop: Bool = true
    ) -> PredictiveExtensionEvidence? {
        guard let normalizedPrefix = Self.autocorrectionLookupKey(for: prefix),
              let normalizedCandidate = Self.autocorrectionLookupKey(for: candidateSortKey),
              !normalizedPrefix.isEmpty,
              normalizedCandidate.count > normalizedPrefix.count,
              normalizedCandidate.hasPrefix(normalizedPrefix),
              normalizedPrefix.utf8.allSatisfy({ $0 >= 97 && $0 <= 122 }),
              normalizedCandidate.utf8.allSatisfy({ $0 >= 97 && $0 <= 122 })
        else { return nil }

        let suffix = normalizedCandidate.dropFirst(normalizedPrefix.count)
        guard !suffix.isEmpty,
              suffix.count <= OldOSZephyrHitTester.predictiveMaximumDepth
        else { return nil }

        var currentPrefix = normalizedPrefix
        var dictionaryLog = 0.0
        var predictionCostLog = 0.0

        for ch in suffix {
            guard let edgeProbability = nextLetterProbabilities(after: currentPrefix)[ch],
                  edgeProbability > 0
            else { return nil }

            dictionaryLog += log(edgeProbability)

            let predictionCost: Double
            if nonStop {
                let slot = min(currentPrefix.unicodeScalars.count, OldOSZephyrHitTester.nonStopPredictCosts.count - 1)
                predictionCost = OldOSZephyrHitTester.nonStopPredictCosts[slot]
            } else {
                predictionCost = OldOSZephyrHitTester.stopPredictCost
            }
            guard predictionCost > 0 else { return nil }
            predictionCostLog += log(predictionCost)
            currentPrefix.append(ch)
        }

        return PredictiveExtensionEvidence(
            suffixLength: suffix.count,
            dictionaryExtensionLogLikelihood: dictionaryLog,
            predictionCostLogLikelihood: predictionCostLog
        )
    }

    public static func currentASCIIWordPrefix(in textBeforeCursor: String) -> String {
        var scalars: [UnicodeScalar] = []
        for scalar in textBeforeCursor.unicodeScalars.reversed() {
            let v = scalar.value
            let isUpper = v >= 65 && v <= 90
            let isLower = v >= 97 && v <= 122
            guard isUpper || isLower else { break }
            scalars.append(UnicodeScalar(v + (isUpper ? 32 : 0))!)
        }
        return String(String.UnicodeScalarView(scalars.reversed()))
    }

    public static func currentAutocorrectionSurfacePrefix(in textBeforeCursor: String) -> String {
        var scalars: [UnicodeScalar] = []
        for scalar in textBeforeCursor.unicodeScalars.reversed() {
            let v = scalar.value
            let isUpper = v >= 65 && v <= 90
            let isLower = v >= 97 && v <= 122
            let isApostrophe = v == 0x27 || v == 0x2019
            guard isUpper || isLower || isApostrophe else { break }
            scalars.append(scalar)
        }

        var surface = String(String.UnicodeScalarView(scalars.reversed()))
        while let first = surface.unicodeScalars.first, first.value == 0x27 || first.value == 0x2019 {
            surface.removeFirst()
        }
        while let last = surface.unicodeScalars.last, last.value == 0x27 || last.value == 0x2019 {
            surface.removeLast()
        }
        return surface
    }

    public static func autocorrectionLookupKey(for surface: String) -> String? {
        var bytes: [UInt8] = []
        for scalar in surface.unicodeScalars {
            let v = scalar.value
            if v == 0x27 || v == 0x2019 { continue }
            if v >= 65 && v <= 90 {
                bytes.append(UInt8(v + 32))
            } else if v >= 97 && v <= 122 {
                bytes.append(UInt8(v))
            } else {
                return nil
            }
        }
        guard !bytes.isEmpty else { return nil }
        return String(bytes: bytes, encoding: .utf8)
    }

    private static func canonicalApostrophes(_ value: String) -> String {
        value.replacingOccurrences(of: "’", with: "'")
    }

    public func containsASCIIWord(_ word: String) -> Bool {
        let inputSurface = Self.canonicalApostrophes(word)
        guard let normalized = Self.autocorrectionLookupKey(for: inputSurface),
              normalized.utf8.allSatisfy({ $0 >= 97 && $0 <= 122 }),
              !normalized.isEmpty,
              let sortKey = try? sortKey(forASCIIWord: normalized),
              let cursor = try? cursor(for: sortKey),
              cursor.segmentIndex == cursor.record.patricia.count
        else { return false }

        let record = cursor.record
        let terminal = record.childOffset == 0
            || record.directTerminationByte != nil
            || record.unigramListOffset != nil
        guard terminal else { return false }

        if let words = displayWords(for: record, baseWord: normalized), !words.isEmpty {
            for decoded in words {
                let displayed = Self.canonicalApostrophes(decoded.displayForm)
                if displayed == inputSurface { return true }

                let letters = displayed.filter { $0.isLetter }
                if !displayed.contains("'"),
                   !letters.isEmpty,
                   letters == letters.lowercased(),
                   displayed.lowercased() == inputSurface.lowercased() {
                    return true
                }
            }
            return false
        }

        return !inputSurface.contains("'") && inputSurface.lowercased() == normalized
    }

    private struct ApproximateCorrectionState {
        let wordBytes: [UInt8]

        let row: [Int]

        let previousRow: [Int]?
        let lastByte: UInt8?
        let lexicalScore: Double
    }

    public func autocorrectionCandidates(
        for word: String,
        maxDistance explicitMaximum: Int? = nil,
        limit: Int = 5
    ) -> [AutocorrectionCandidate] {
        guard let normalized = Self.autocorrectionLookupKey(for: word) else { return [] }
        let query = Array(normalized.utf8)
        guard !query.isEmpty, query.allSatisfy({ $0 >= 97 && $0 <= 122 }) else { return [] }
        if containsASCIIWord(word) { return [] }

        let maximum = explicitMaximum ?? (query.count == 1 ? 0 : (query.count >= 7 ? 2 : 1))
        guard maximum >= 0 else { return [] }

        let root = ApproximateCorrectionState(
            wordBytes: [],
            row: Array(0...query.count),
            previousRow: nil,
            lastByte: nil,
            lexicalScore: 0
        )

        var found: [AutocorrectionCandidate] = []
        do {
            try collectApproximateCorrections(
                siblingOffset: metadata.trieRootOffset,
                query: query,
                maximum: maximum,
                state: root,
                into: &found
            )
        } catch {
            return []
        }

        found.sort { lhs, rhs in
            if lhs.editDistance != rhs.editDistance { return lhs.editDistance < rhs.editDistance }
            if lhs.lexicalScore != rhs.lexicalScore { return lhs.lexicalScore > rhs.lexicalScore }
            if lhs.surfaceOrder != rhs.surfaceOrder { return lhs.surfaceOrder < rhs.surfaceOrder }
            return lhs.word < rhs.word
        }
        if found.count > limit { return Array(found.prefix(limit)) }
        return found
    }

    private static func isSingleAdjacentTransposition(_ lhs: [UInt8], _ rhs: [UInt8]) -> Bool {
        guard lhs.count == rhs.count, lhs.count >= 2 else { return false }
        var mismatches: [Int] = []
        for index in lhs.indices where lhs[index] != rhs[index] {
            mismatches.append(index)
            if mismatches.count > 2 { return false }
        }
        guard mismatches.count == 2,
              mismatches[1] == mismatches[0] + 1
        else { return false }
        let a = mismatches[0]
        let b = mismatches[1]
        return lhs[a] == rhs[b] && lhs[b] == rhs[a]
    }

    private func collectApproximateCorrections(
        siblingOffset: Int,
        query: [UInt8],
        maximum: Int,
        state parentState: ApproximateCorrectionState,
        into result: inout [AutocorrectionCandidate]
    ) throws {
        for record in try siblings(at: siblingOffset) {
            var state = parentState
            var viable = true

            for sortByte in record.patricia {
                guard let character = character(forPrimarySortKeyByte: sortByte),
                      let scalar = character.unicodeScalars.first,
                      character.unicodeScalars.count == 1,
                      scalar.value >= 97, scalar.value <= 122 else {
                    viable = false
                    break
                }

                let candidateByte = UInt8(scalar.value)
                guard state.wordBytes.count < query.count + maximum else {
                    viable = false
                    break
                }

                var current = Array(repeating: 0, count: query.count + 1)
                current[0] = state.wordBytes.count + 1
                var rowMinimum = current[0]

                if !query.isEmpty {
                    for j in 1...query.count {
                        let substitutionCost = candidateByte == query[j - 1] ? 0 : 1
                        var value = min(
                            current[j - 1] + 1,
                            state.row[j] + 1,
                            state.row[j - 1] + substitutionCost
                        )

                        if j > 1,
                           let previousRow = state.previousRow,
                           let previousByte = state.lastByte,
                           candidateByte == query[j - 2],
                           previousByte == query[j - 1] {
                            value = min(value, previousRow[j - 2] + 1)
                        }

                        current[j] = value
                        rowMinimum = min(rowMinimum, value)
                    }
                }

                guard rowMinimum <= maximum else {
                    viable = false
                    break
                }

                var bytes = state.wordBytes
                bytes.append(candidateByte)
                state = ApproximateCorrectionState(
                    wordBytes: bytes,
                    row: current,
                    previousRow: state.row,
                    lastByte: candidateByte,
                    lexicalScore: state.lexicalScore
                )
            }

            guard viable else { continue }

            let edgeProbability = max(record.partialProbability, Double.leastNonzeroMagnitude)
            let pathScore = state.lexicalScore + log(edgeProbability)
            state = ApproximateCorrectionState(
                wordBytes: state.wordBytes,
                row: state.row,
                previousRow: state.previousRow,
                lastByte: state.lastByte,
                lexicalScore: pathScore
            )

            let isWordTerminal = record.childOffset == 0
                || record.directTerminationByte != nil
                || (record.flags & 0x20) != 0

            if isWordTerminal,
               let distance = state.row.last,
               distance <= maximum,
               let baseCandidate = String(bytes: state.wordBytes, encoding: .utf8) {
                var terminalScore = pathScore
                if let terminalProbability = record.directTerminationProbability {
                    terminalScore += log(max(terminalProbability, Double.leastNonzeroMagnitude))
                }

                let words = displayWords(for: record, baseWord: baseCandidate)
                    ?? [DecodedDatWord(
                        displayForm: baseCandidate,
                        nextOffset: nil,
                        surfaceOrder: 0,
                        capitalizationMask: 0,
                        recordFlags: 0,
                        wordFlags: 0,
                        hasExplicitSurfaceForm: false
                    )]
                for decoded in words {
                    result.append(
                        AutocorrectionCandidate(
                            word: decoded.displayForm,
                            sortKey: baseCandidate,
                            editDistance: distance,
                            lexicalScore: terminalScore,
                            surfaceOrder: decoded.surfaceOrder,
                            capitalizationMask: decoded.capitalizationMask,
                            recordFlags: decoded.recordFlags,
                            wordFlags: decoded.wordFlags,
                            hasExplicitSurfaceForm: decoded.hasExplicitSurfaceForm
                        )
                    )
                }
            }

            if record.childOffset != 0,
               state.wordBytes.count < query.count + maximum {
                try collectApproximateCorrections(
                    siblingOffset: record.childOffset,
                    query: query,
                    maximum: maximum,
                    state: state,
                    into: &result
                )
            }
        }
    }

    private func displayWords(for record: PackedSibling, baseWord: String) -> [DecodedDatWord]? {
        guard let firstOffset = record.unigramListOffset,
              firstOffset > 0, firstOffset < dat.count
        else { return nil }

        var result: [DecodedDatWord] = []
        var offset: Int? = firstOffset
        var guardCount = 0
        while let current = offset, current > 0, current < dat.count, guardCount < 256 {
            guardCount += 1
            guard var decoded = try? decodeDatWord(at: current, baseWord: baseWord) else { break }
            decoded = DecodedDatWord(
                displayForm: decoded.displayForm,
                nextOffset: decoded.nextOffset,
                surfaceOrder: result.count,
                capitalizationMask: decoded.capitalizationMask,
                recordFlags: decoded.recordFlags,
                wordFlags: decoded.wordFlags,
                hasExplicitSurfaceForm: decoded.hasExplicitSurfaceForm
            )
            result.append(decoded)
            offset = decoded.nextOffset
        }
        return result.isEmpty ? nil : result
    }

    private struct DecodedDatWord {
        let displayForm: String
        let nextOffset: Int?
        let surfaceOrder: Int
        let capitalizationMask: UInt32
        let recordFlags: UInt8
        let wordFlags: UInt8
        let hasExplicitSurfaceForm: Bool
    }

    private func decodeDatWord(at offset: Int, baseWord: String) throws -> DecodedDatWord {
        var p = offset
        let nextDelta = Int(try readByte(dat, at: p)); p += 1
        let flags = try readByte(dat, at: p); p += 1

        if flags & 0x04 != 0 { p += 1 }

        var wordFlags: UInt8 = 0
        if flags & 0x20 != 0 {
            wordFlags = try readByte(dat, at: p); p += 1
        }

        var capitalizationMask: UInt32 = (wordFlags & 0x01) != 0 ? 1 : 0
        if flags & 0x01 != 0 {
            capitalizationMask = try Self.readBE32(dat, at: p); p += 4
        }
        if flags & 0x40 != 0 { p += 4 }

        var substitutionStart: Int = 0

        if (metadata.compilationFlags & 0x800) == 0
            || (flags & 0x08 != 0 && wordFlags & 0x10 != 0) {
            let packed = try readBE16(dat, at: p); p += 2
            substitutionStart = Int(packed & 0x001f)
        }

        let display: String
        if flags & 0x10 != 0 {
            let literal = try readCString(dat, at: p)
            display = literal.string
            p = literal.nextOffset
        } else if flags & 0x08 != 0 {
            let substitution = try decodeSubstitutionList(
                baseWord: baseWord,
                at: p,
                initialPosition: substitutionStart
            )
            display = substitution.string
            p = substitution.nextOffset
        } else {
            display = baseWord
        }

        let capitalizedDisplay = applyCapitalizationMask(capitalizationMask, to: display)
        return DecodedDatWord(
            displayForm: capitalizedDisplay,
            nextOffset: flags & 0x80 != 0 ? offset + nextDelta : nil,
            surfaceOrder: 0,
            capitalizationMask: capitalizationMask,
            recordFlags: flags,
            wordFlags: wordFlags,
            hasExplicitSurfaceForm: (flags & 0x18) != 0 || capitalizationMask != 0
        )
    }

    private func applyCapitalizationMask(_ mask: UInt32, to value: String) -> String {
        guard mask != 0 else { return value }
        var result = ""
        for (index, character) in value.enumerated() {
            if index < 32, (mask & (UInt32(1) << UInt32(index))) != 0 {
                result += String(character).uppercased()
            } else {
                result.append(character)
            }
        }
        return result
    }

    private func decodeSubstitutionList(
        baseWord: String,
        at offset: Int,
        initialPosition: Int
    ) throws -> (string: String, nextOffset: Int) {
        let source = Array(baseWord)
        var sourceIndex = 0
        var p = offset
        var output = ""

        let carried = initialPosition == 0 ? 0 : max(0, source.count - initialPosition)

        while true {
            let control = try readByte(dat, at: p); p += 1
            let replacement = try readCString(dat, at: p)
            p = replacement.nextOffset

            let target = min(source.count, carried + Int(control & 0x1f))
            while sourceIndex < target {
                output.append(source[sourceIndex])
                sourceIndex += 1
            }
            output.append(replacement.string)

            if control & 0x20 != 0 {

                sourceIndex = min(source.count, sourceIndex + 2)
            } else if control & 0x40 != 0 {

            } else {
                sourceIndex = min(source.count, sourceIndex + Array(replacement.string).count)
            }

            if control & 0x80 == 0 { break }
        }

        while sourceIndex < source.count {
            output.append(source[sourceIndex])
            sourceIndex += 1
        }
        return (output, p)
    }

    private func readCString(_ data: Data, at offset: Int) throws -> (string: String, nextOffset: Int) {
        guard offset >= 0, offset < data.count else {
            throw ModelError.malformed("C string outside .dat @ \(offset)")
        }
        var end = offset
        while end < data.count, data[data.index(data.startIndex, offsetBy: end)] != 0 { end += 1 }
        guard end < data.count else { throw ModelError.malformed("unterminated .dat string @ \(offset)") }
        let bytes = data.subdata(in: offset..<end)
        guard let string = String(data: bytes, encoding: .utf8) else {
            throw ModelError.malformed("invalid UTF-8 .dat string @ \(offset)")
        }
        return (string, end + 1)
    }

    private struct Cursor {
        let record: PackedSibling
        let segmentIndex: Int
    }

    private func cursor(for sortKey: [UInt8]) throws -> Cursor? {
        guard !sortKey.isEmpty else { return nil }
        var siblingOffset = metadata.trieRootOffset
        var inputIndex = 0
        var current: PackedSibling?

        while inputIndex < sortKey.count {
            let list = try siblings(at: siblingOffset)
            guard let record = list.first(where: { $0.patricia.first == sortKey[inputIndex] }) else {
                return nil
            }
            current = record

            var segmentIndex = 0
            while segmentIndex < record.patricia.count && inputIndex < sortKey.count {
                guard record.patricia[segmentIndex] == sortKey[inputIndex] else { return nil }
                segmentIndex += 1
                inputIndex += 1
            }

            if inputIndex == sortKey.count {
                return Cursor(record: record, segmentIndex: segmentIndex)
            }
            guard segmentIndex == record.patricia.count, record.childOffset != 0 else { return nil }
            siblingOffset = record.childOffset
        }
        guard let current else { return nil }
        return Cursor(record: current, segmentIndex: current.patricia.count)
    }

    private func siblings(at offset: Int) throws -> [PackedSibling] {
        guard offset > 0 else { return [] }
        var result: [PackedSibling] = []
        var next: Int? = offset
        while let p = next {
            let record = try parseSibling(at: p)
            result.append(record)
            next = record.nextSiblingOffset
            if result.count > 256 { throw ModelError.malformed("sibling chain > 256 records") }
        }
        return result
    }

    private func parseSibling(at start: Int) throws -> PackedSibling {
        var p = start
        let flags = try readByte(idx, at: p); p += 1

        let patriciaLength = Int(flags & 0x03) + 1
        guard p + patriciaLength <= idx.count else { throw ModelError.malformed("Patricia segment out of bounds") }
        let patricia = Array(idx[p..<(p + patriciaLength)])
        p += patriciaLength

        let childEncoding = (flags >> 2) & 0x03
        let childOffset: Int
        switch childEncoding {
        case 0:
            childOffset = 0
        case 1:
            childOffset = start + Int(try readByte(idx, at: p)); p += 1
        case 2:
            let raw = try readBE16(idx, at: p); p += 2
            let signed = Int(Int16(bitPattern: raw))
            childOffset = start + signed
        default:
            childOffset = try readBE24(idx, at: p); p += 3
        }

        let compactedFrequency: UInt8
        if flags & 0x40 != 0 {
            compactedFrequency = try readByte(idx, at: p); p += 1
        } else {
            compactedFrequency = 255
        }

        var directTermination: UInt8?
        var unigramListOffset: Int?
        if flags & 0x20 != 0 {
            unigramListOffset = try readBE24(idx, at: p); p += 3
        } else if flags & 0x10 != 0 {
            directTermination = try readByte(idx, at: p); p += 1
        }

        return PackedSibling(
            offset: start,
            flags: flags,
            patricia: patricia,
            childOffset: childOffset,
            compactedFrequency: compactedFrequency,
            directTerminationByte: directTermination,
            unigramListOffset: unigramListOffset,
            nextSiblingOffset: flags & 0x80 != 0 ? p : nil
        )
    }

    private func sortKey(forASCIIWord word: String) throws -> [UInt8] {
        var out: [UInt8] = []
        for scalar in word.lowercased().unicodeScalars {
            guard let bytes = codePointToSortKey[scalar.value] else {
                throw ModelError.malformed("no common sort-key mapping for U+\(String(scalar.value, radix: 16))")
            }
            out.append(contentsOf: bytes)
        }
        return out
    }

    private func character(forPrimarySortKeyByte byte: UInt8) -> Character? {
        guard let cp = sortKeyToCodePoint[[byte]], let scalar = UnicodeScalar(cp) else { return nil }
        return Character(String(scalar).lowercased())
    }

    private static func loadCommonLetterForms(
        from data: Data,
        offset: Int
    ) throws -> (forward: [[UInt8]: UInt32], reverse: [UInt32: [UInt8]]) {
        let count = Int(try readBE32(data, at: offset))
        var forward: [[UInt8]: UInt32] = [:]
        var reverse: [UInt32: [UInt8]] = [:]

        for index in 0..<count {
            let record = offset + 8 + index * 8
            guard record + 8 <= data.count else { throw ModelError.malformed("common-letter table") }
            let raw = Array(data[record..<(record + 4)])
            let sortKey = Array(raw.prefix { $0 != 0 })
            let codePoint = try readBE32(data, at: record + 4)
            guard !sortKey.isEmpty else { continue }
            forward[sortKey] = codePoint
            reverse[codePoint] = sortKey
        }
        return (forward, reverse)
    }

    private static func validateHeader(_ data: Data) throws {
        guard data.count >= headerSize else { throw ModelError.malformed("header shorter than 128 bytes") }
        let magic = try readBE32(data, at: 0)
        let major = try readBE32(data, at: 4)
        let minor = try readBE32(data, at: 8)
        guard magic == self.magic, major == requiredMajor, minor >= minimumMinor else {
            throw ModelError.unsupportedVersion(magic: magic, major: major, minor: minor)
        }
    }

    private func readByte(_ data: Data, at offset: Int) throws -> UInt8 {
        try Self.readByte(data, at: offset)
    }

    private static func readByte(_ data: Data, at offset: Int) throws -> UInt8 {
        guard offset >= 0, offset < data.count else { throw ModelError.malformed("read outside file @ \(offset)") }
        return data[data.index(data.startIndex, offsetBy: offset)]
    }

    private func readBE16(_ data: Data, at offset: Int) throws -> UInt16 { try Self.readBE16(data, at: offset) }
    private static func readBE16(_ data: Data, at offset: Int) throws -> UInt16 {
        let a = UInt16(try readByte(data, at: offset))
        let b = UInt16(try readByte(data, at: offset + 1))
        return (a << 8) | b
    }

    private func readBE24(_ data: Data, at offset: Int) throws -> Int { try Self.readBE24(data, at: offset) }
    private static func readBE24(_ data: Data, at offset: Int) throws -> Int {
        let a = Int(try readByte(data, at: offset))
        let b = Int(try readByte(data, at: offset + 1))
        let c = Int(try readByte(data, at: offset + 2))
        return (a << 16) | (b << 8) | c
    }

    private static func readBE32(_ data: Data, at offset: Int) throws -> UInt32 {
        let a = UInt32(try readByte(data, at: offset))
        let b = UInt32(try readByte(data, at: offset + 1))
        let c = UInt32(try readByte(data, at: offset + 2))
        let d = UInt32(try readByte(data, at: offset + 3))
        return (a << 24) | (b << 16) | (c << 8) | d
    }
}

extension OldOSZephyrStaticLanguageModel {

    public struct ZTStaticCursor: Equatable, Hashable {
        public let sortKey: String

        public let staticSiblingCount: Int

        fileprivate init(sortKey: String, staticSiblingCount: Int) {
            self.sortKey = sortKey
            self.staticSiblingCount = max(0, staticSiblingCount)
        }
    }

    public struct ZTCursorAdvance: Equatable {
        public let cursor: ZTStaticCursor
        public let staticPartialProbability: Double
    }

    public struct ZTDynamicEntry: Equatable, Hashable {
        public let surface: String
        public let sortKey: String
        public let userFrequency: Int

        public init?(surface: String, userFrequency: Int) {
            guard userFrequency > 0,
                  let sortKey = OldOSZephyrStaticLanguageModel.autocorrectionLookupKey(for: surface),
                  !sortKey.isEmpty
            else { return nil }
            self.surface = surface
            self.sortKey = sortKey
            self.userFrequency = userFrequency
        }
    }

    public struct ZTDictionaryCursors: Equatable {
        public let staticCursor: ZTStaticCursor?

        public let dynamicEntries: [ZTDynamicEntry]
        public let sortKey: String

        public let customDynamicSiblingCount: Int
        public let abDynamicSiblingCount: Int

        public var staticSiblingCount: Int {
            staticCursor?.staticSiblingCount ?? 0
        }

        public var hasAnyCursor: Bool {
            staticCursor != nil || !dynamicEntries.isEmpty
        }

        public var finishesStaticWord: Bool {
            staticCursor != nil
        }

        public var finishesDynamicWord: Bool {
            dynamicEntries.contains { $0.sortKey == sortKey }
        }

        public var customDynamicEntryCountSum: Int {
            dynamicEntries.reduce(0) { partial, entry in
                guard entry.sortKey == sortKey else { return partial }
                return partial + max(0, entry.userFrequency)
            }
        }
    }

    public struct ZTSymbolEntry: Equatable {
        public let sortKey: String
        public let parentSortKey: String
        public let strokeIndex: Int
        public let symbolASCII: UInt8?
        public let dictionaryCursors: ZTDictionaryCursors
        public let physicalLogLikelihood: Double
        public let stringContextLogLikelihood: Double
        public let spellingPower: Double

        public let priorTouchVectors: [OldOSZephyrPriorTouchVector]

        public let erasedStrokeCount: Int
        public let predictedSymbolCount: Int
        public let cameFromPredictStroke: Bool

        public var totalLogLikelihood: Double {
            physicalLogLikelihood + spellingPower * stringContextLogLikelihood
        }
    }

    public struct ZTInsertionSortStack {
        public let capacity: Int
        public private(set) var entries: [ZTSymbolEntry] = []

        public init(capacity: Int = OldOSZephyrHitTester.sourceBeamWidth) {
            self.capacity = max(1, capacity)
        }

        public mutating func insert(_ entry: ZTSymbolEntry) {

            if let existing = entries.firstIndex(where: {
                $0.sortKey == entry.sortKey
                    && $0.strokeIndex == entry.strokeIndex
                    && $0.erasedStrokeCount == entry.erasedStrokeCount
                    && $0.predictedSymbolCount == entry.predictedSymbolCount
                    && $0.cameFromPredictStroke == entry.cameFromPredictStroke
                    && $0.priorTouchVectors == entry.priorTouchVectors
            }) {
                if entry.totalLogLikelihood > entries[existing].totalLogLikelihood {
                    entries[existing] = entry
                }
            } else {
                entries.append(entry)
            }

            entries.sort(by: Self.sortsBefore)
            if entries.count > capacity {
                entries.removeSubrange(capacity..<entries.count)
            }
        }

        public mutating func pruneWithRatioToNewTop(_ logRatio: Double) {
            guard logRatio.isFinite, let top = entries.first else { return }
            let threshold = top.totalLogLikelihood + logRatio
            if let firstRejected = entries.firstIndex(where: {
                $0.totalLogLikelihood < threshold
            }) {
                entries.removeSubrange(firstRejected..<entries.count)
            }
        }

        private static func sortsBefore(_ lhs: ZTSymbolEntry, _ rhs: ZTSymbolEntry) -> Bool {
            if lhs.totalLogLikelihood != rhs.totalLogLikelihood {
                return lhs.totalLogLikelihood > rhs.totalLogLikelihood
            }
            if lhs.erasedStrokeCount != rhs.erasedStrokeCount {
                return lhs.erasedStrokeCount < rhs.erasedStrokeCount
            }
            if lhs.predictedSymbolCount != rhs.predictedSymbolCount {
                return lhs.predictedSymbolCount < rhs.predictedSymbolCount
            }
            return lhs.sortKey < rhs.sortKey
        }
    }

    public struct ZTBeamResult {
        public let liveEntries: [ZTSymbolEntry]
        public let candidates: [AutocorrectionCandidate]
        public let usedPhysicalTouchEvidence: Bool
    }

    public func ztRootDictionaryCursors(dynamicEntries: [ZTDynamicEntry]) -> ZTDictionaryCursors {
        let rootStaticSiblingCount = (try? siblings(at: metadata.trieRootOffset).count) ?? 0
        return ZTDictionaryCursors(
            staticCursor: ZTStaticCursor(
                sortKey: "",
                staticSiblingCount: rootStaticSiblingCount
            ),
            dynamicEntries: dynamicEntries,
            sortKey: "",
            customDynamicSiblingCount: ztDynamicSiblingCount(
                dynamicEntries,
                parentPrefix: ""
            ),
            abDynamicSiblingCount: 0
        )
    }

    private func ztStaticCursorState(for sortKeyString: String) -> ZTStaticCursor? {
        if sortKeyString.isEmpty {
            let count = (try? siblings(at: metadata.trieRootOffset).count) ?? 0
            return ZTStaticCursor(sortKey: "", staticSiblingCount: count)
        }
        guard let bytes = try? sortKey(forASCIIWord: sortKeyString), !bytes.isEmpty else {
            return nil
        }

        var siblingOffset = metadata.trieRootOffset
        var inputIndex = 0
        while inputIndex < bytes.count {
            guard let list = try? siblings(at: siblingOffset), !list.isEmpty,
                  let record = list.first(where: { $0.patricia.first == bytes[inputIndex] })
            else { return nil }

            var segmentIndex = 0
            while segmentIndex < record.patricia.count && inputIndex < bytes.count {
                guard record.patricia[segmentIndex] == bytes[inputIndex] else { return nil }
                segmentIndex += 1
                inputIndex += 1
            }

            if inputIndex == bytes.count {

                let count = segmentIndex <= 1 ? list.count : 1
                return ZTStaticCursor(
                    sortKey: sortKeyString,
                    staticSiblingCount: count
                )
            }

            guard segmentIndex == record.patricia.count, record.childOffset != 0 else {
                return nil
            }
            siblingOffset = record.childOffset
        }
        return nil
    }

    public func ztAdvanceStaticCursor(
        _ cursorState: ZTStaticCursor,
        lowercaseASCII: UInt8
    ) -> ZTCursorAdvance? {
        guard lowercaseASCII >= 97, lowercaseASCII <= 122,
              let scalar = UnicodeScalar(Int(lowercaseASCII))
        else { return nil }
        let ch = Character(String(scalar))
        let probabilities = nextLetterProbabilities(after: cursorState.sortKey)
        guard let probability = probabilities[ch], probability > 0 else { return nil }
        let newSortKey = cursorState.sortKey + String(ch)
        guard let advancedState = ztStaticCursorState(for: newSortKey) else { return nil }
        return ZTCursorAdvance(
            cursor: advancedState,
            staticPartialProbability: probability
        )
    }

    private func ztDynamicChildEntries(
        _ entries: [ZTDynamicEntry],
        parentPrefix: String,
        lowercaseASCII: UInt8
    ) -> [ZTDynamicEntry] {
        guard let scalar = UnicodeScalar(Int(lowercaseASCII)) else { return [] }
        let prefix = parentPrefix + String(Character(String(scalar)))
        return entries.filter { $0.sortKey.hasPrefix(prefix) }
    }

    private func ztDynamicSiblingCount(
        _ entries: [ZTDynamicEntry],
        parentPrefix: String
    ) -> Int {
        let parentBytes = Array(parentPrefix.utf8)
        let offset = parentBytes.count
        var keys = Set<UInt8>()
        for entry in entries where entry.sortKey.hasPrefix(parentPrefix) {
            let bytes = Array(entry.sortKey.utf8)
            guard offset < bytes.count else { continue }
            keys.insert(bytes[offset])
        }
        return min(255, keys.count)
    }

    public func ztSourceDynamicPartialProbabilityForUsageCount(
        usageMass: Int,
        depth: Int,
        staticSiblingCount: Int,
        customDynamicSiblingCount: Int,
        abDynamicSiblingCount: Int = 0
    ) -> Double {
        guard usageMass > 0 else { return 0 }
        let depthFactor = depth <= 8 ? max(1, 10 - depth) : 1
        let denominator = max(0, staticSiblingCount) * depthFactor
            + max(0, customDynamicSiblingCount)
            + max(0, abDynamicSiblingCount)
        guard denominator > 0 else { return 0 }

        return Double(Float(usageMass) / Float(denominator))
    }

    public func ztSourceDynamicPartialProbability(
        cursors: ZTDictionaryCursors,
        depth: Int
    ) -> Double {
        var usageMass = 0
        if !cursors.dynamicEntries.isEmpty {
            usageMass += cursors.customDynamicEntryCountSum + 1
        }

        guard usageMass > 0 else { return 0 }
        return ztSourceDynamicPartialProbabilityForUsageCount(
            usageMass: usageMass,
            depth: depth,
            staticSiblingCount: cursors.staticSiblingCount,
            customDynamicSiblingCount: cursors.customDynamicSiblingCount,
            abDynamicSiblingCount: cursors.abDynamicSiblingCount
        )
    }

    public func ztAdvanceDictionaryCursors(
        _ cursors: ZTDictionaryCursors,
        lowercaseASCII: UInt8
    ) -> (cursors: ZTDictionaryCursors, combinedPartialProbability: Double)? {
        let staticAdvance = cursors.staticCursor.flatMap {
            ztAdvanceStaticCursor($0, lowercaseASCII: lowercaseASCII)
        }
        let dynamicChildren = ztDynamicChildEntries(
            cursors.dynamicEntries,
            parentPrefix: cursors.sortKey,
            lowercaseASCII: lowercaseASCII
        )

        guard staticAdvance != nil || !dynamicChildren.isEmpty,
              let scalar = UnicodeScalar(Int(lowercaseASCII))
        else { return nil }

        let newSortKey = cursors.sortKey + String(Character(String(scalar)))
        let childCursors = ZTDictionaryCursors(
            staticCursor: staticAdvance?.cursor,
            dynamicEntries: dynamicChildren,
            sortKey: newSortKey,
            customDynamicSiblingCount: ztDynamicSiblingCount(
                cursors.dynamicEntries,
                parentPrefix: cursors.sortKey
            ),
            abDynamicSiblingCount: 0
        )

        let staticPartial = staticAdvance?.staticPartialProbability ?? 0
        let dynamicPartial = ztSourceDynamicPartialProbability(
            cursors: childCursors,
            depth: newSortKey.utf8.count
        )
        let combined = staticPartial + dynamicPartial
        guard combined > 0 else { return nil }

        return (childCursors, combined)
    }

    private func ztStaticTerminalCandidates(
        for entry: ZTSymbolEntry
    ) -> [AutocorrectionCandidate] {
        guard let cursorState = entry.dictionaryCursors.staticCursor,
              !cursorState.sortKey.isEmpty,
              let sortBytes = try? sortKey(forASCIIWord: cursorState.sortKey),
              let cursor = try? cursor(for: sortBytes),
              cursor.segmentIndex == cursor.record.patricia.count
        else { return [] }

        let record = cursor.record
        let isTerminal = record.childOffset == 0
            || record.directTerminationByte != nil
            || record.unigramListOffset != nil
            || (record.flags & 0x20) != 0
        guard isTerminal else { return [] }

        var terminalStringLog = entry.stringContextLogLikelihood
        if let terminalProbability = record.directTerminationProbability,
           terminalProbability > 0 {
            terminalStringLog += log(terminalProbability)
        }

        let decoded = displayWords(for: record, baseWord: cursorState.sortKey)
            ?? [DecodedDatWord(
                displayForm: cursorState.sortKey,
                nextOffset: nil,
                surfaceOrder: 0,
                capitalizationMask: 0,
                recordFlags: 0,
                wordFlags: 0,
                hasExplicitSurfaceForm: false
            )]

        return decoded.map { surface in
            AutocorrectionCandidate(
                word: surface.displayForm,
                sortKey: cursorState.sortKey,
                editDistance: 0,
                lexicalScore: terminalStringLog,
                surfaceOrder: surface.surfaceOrder,
                capitalizationMask: surface.capitalizationMask,
                recordFlags: surface.recordFlags,
                wordFlags: surface.wordFlags,
                hasExplicitSurfaceForm: surface.hasExplicitSurfaceForm,
                ztOmegaLogLikelihood: entry.physicalLogLikelihood
                    + entry.spellingPower * terminalStringLog,
                ztPhysicalLogLikelihood: entry.physicalLogLikelihood,
                ztStringContextLogLikelihood: terminalStringLog,
                ztConsumedStrokeCount: entry.strokeIndex,
                ztPredictedSymbolCount: entry.predictedSymbolCount,
                ztErasedStrokeCount: entry.erasedStrokeCount,
                ztCameFromPredictStroke: entry.cameFromPredictStroke
            )
        }
    }

    private func ztDynamicTerminalCandidates(
        for entry: ZTSymbolEntry
    ) -> [AutocorrectionCandidate] {
        let exact = entry.dictionaryCursors.dynamicEntries.filter {
            $0.sortKey == entry.dictionaryCursors.sortKey
        }
        guard !exact.isEmpty else { return [] }

        return exact.map { dynamic in
            AutocorrectionCandidate(
                word: dynamic.surface,
                sortKey: dynamic.sortKey,
                editDistance: 0,
                lexicalScore: entry.stringContextLogLikelihood,
                isDynamic: true,
                dynamicUserFrequency: dynamic.userFrequency,
                ztOmegaLogLikelihood: entry.totalLogLikelihood,
                ztPhysicalLogLikelihood: entry.physicalLogLikelihood,
                ztStringContextLogLikelihood: entry.stringContextLogLikelihood,
                ztConsumedStrokeCount: entry.strokeIndex,
                ztPredictedSymbolCount: entry.predictedSymbolCount,
                ztErasedStrokeCount: entry.erasedStrokeCount,
                ztCameFromPredictStroke: entry.cameFromPredictStroke
            )
        }
    }

    private func ztTerminalCandidates(for entry: ZTSymbolEntry) -> [AutocorrectionCandidate] {
        ztStaticTerminalCandidates(for: entry) + ztDynamicTerminalCandidates(for: entry)
    }

    private func ztLiteralTouchEvidence(for lowercaseASCII: UInt8) -> OldOSZephyrAutocorrectionTouchEvidence {
        OldOSZephyrAutocorrectionTouchEvidence(
            point: .zero,
            committedLowercaseASCII: lowercaseASCII,
            relativePhysicalLogLikelihoods: [lowercaseASCII: 0]
        )
    }

    private struct ZTPhysicalAlternative {
        let letter: UInt8
        let fallbackPhysicalLogLikelihood: Double
        let geometryLogLikelihood: Double?
        let errorVector: OldOSZephyrVector?
    }

    private func ztOrderedPhysicalAlternatives(
        _ evidence: OldOSZephyrAutocorrectionTouchEvidence
    ) -> [ZTPhysicalAlternative] {
        if !evidence.keySquareErrors.isEmpty {
            var ordered = evidence.keySquareErrors
                .filter { ascii, square in
                    ascii >= 97 && ascii <= 122 && square.isFinite
                        && (evidence.neighborRadiusSquared.map { square <= $0 } ?? true)
                }
                .map { ($0.key, $0.value) }
                .sorted {
                    if $0.1 != $1.1 { return $0.1 < $1.1 }
                    return $0.0 < $1.0
                }

            if !ordered.contains(where: { $0.0 == evidence.committedLowercaseASCII }),
               let square = evidence.keySquareErrors[evidence.committedLowercaseASCII] {
                ordered.append((evidence.committedLowercaseASCII, square))
                ordered.sort { $0.1 == $1.1 ? $0.0 < $1.0 : $0.1 < $1.1 }
            }

            if ordered.count > OldOSZephyrHitTester.maximumNeighborCount {
                ordered.removeSubrange(
                    OldOSZephyrHitTester.maximumNeighborCount..<ordered.count
                )
            }

            return ordered.map { ascii, _ in
                ZTPhysicalAlternative(
                    letter: ascii,
                    fallbackPhysicalLogLikelihood: evidence.relativePhysicalLogLikelihoods[ascii] ?? -.infinity,
                    geometryLogLikelihood: evidence.geometryLogLikelihoods[ascii],
                    errorVector: evidence.keyErrorVectors[ascii]
                )
            }
        }

        var alternatives = evidence.relativePhysicalLogLikelihoods
            .filter { $0.key >= 97 && $0.key <= 122 && $0.value.isFinite }
            .map { ($0.key, $0.value) }
            .sorted {
                if $0.1 != $1.1 { return $0.1 > $1.1 }
                return $0.0 < $1.0
            }

        if !alternatives.contains(where: { $0.0 == evidence.committedLowercaseASCII }) {
            alternatives.append((evidence.committedLowercaseASCII, 0))
            alternatives.sort { $0.1 > $1.1 }
        }
        if alternatives.count > OldOSZephyrHitTester.maximumNeighborCount {
            alternatives.removeSubrange(
                OldOSZephyrHitTester.maximumNeighborCount..<alternatives.count
            )
        }
        return alternatives.map {
            ZTPhysicalAlternative(
                letter: $0.0,
                fallbackPhysicalLogLikelihood: $0.1,
                geometryLogLikelihood: nil,
                errorVector: nil
            )
        }
    }

    public func ztBuildLiveBeam(
        typedSortKey: String,
        touchEvidence: [OldOSZephyrAutocorrectionTouchEvidence],
        dynamicEntries: [ZTDynamicEntry],
        beamWidth: Int = OldOSZephyrHitTester.sourceBeamWidth
    ) -> [ZTSymbolEntry] {
        let typedBytes = Array(typedSortKey.utf8)
        guard !typedBytes.isEmpty,
              typedBytes.allSatisfy({ $0 >= 97 && $0 <= 122 })
        else { return [] }

        let evidence: [OldOSZephyrAutocorrectionTouchEvidence]
        let hasRealEvidence = touchEvidence.count == typedBytes.count
            && zip(touchEvidence, typedBytes).allSatisfy {
                $0.0.committedLowercaseASCII == $0.1
            }
        if hasRealEvidence {
            evidence = touchEvidence
        } else {
            evidence = typedBytes.map { ztLiteralTouchEvidence(for: $0) }
        }

        let rootCursors = ztRootDictionaryCursors(dynamicEntries: dynamicEntries)
        var current = [ZTSymbolEntry(
            sortKey: "",
            parentSortKey: "",
            strokeIndex: 0,
            symbolASCII: nil,
            dictionaryCursors: rootCursors,
            physicalLogLikelihood: 0,
            stringContextLogLikelihood: 0,
            spellingPower: OldOSZephyrHitTester.letterTypingSpellPowerPhone,
            priorTouchVectors: [],
            erasedStrokeCount: 0,
            predictedSymbolCount: 0,
            cameFromPredictStroke: false
        )]

        for (strokeOffset, stroke) in evidence.enumerated() {
            var next = ZTInsertionSortStack(capacity: beamWidth)

            for parent in current {
                for alternative in ztOrderedPhysicalAlternatives(stroke) {
                    guard let advanced = ztAdvanceDictionaryCursors(
                        parent.dictionaryCursors,
                        lowercaseASCII: alternative.letter
                    ) else { continue }

                    let strokePhysicalLogLikelihood: Double
                    if let geometry = alternative.geometryLogLikelihood,
                       let currentError = alternative.errorVector {

                        let history: Double
                        if let sigma = stroke.interTouchSigma {
                            history = OldOSZephyrHitTester.historyLogLikelihood(
                                candidateError: currentError,
                                priors: parent.priorTouchVectors,
                                sigma: sigma
                            )
                        } else {
                            history = 0
                        }
                        strokePhysicalLogLikelihood = geometry + history
                    } else {
                        strokePhysicalLogLikelihood = alternative.fallbackPhysicalLogLikelihood
                    }

                    let erasedHistoryAdjustment = Double(
                        stroke.erasedKeyHistory.filter { $0 == alternative.letter }.count
                    ) * OldOSZephyrHitTester.erasedSymbolHistoryMatchCost

                    let partial = max(
                        advanced.combinedPartialProbability,
                        Double.leastNonzeroMagnitude
                    )
                    let child = ZTSymbolEntry(
                        sortKey: advanced.cursors.sortKey,
                        parentSortKey: parent.sortKey,
                        strokeIndex: strokeOffset + 1,
                        symbolASCII: alternative.letter,
                        dictionaryCursors: advanced.cursors,
                        physicalLogLikelihood: parent.physicalLogLikelihood
                            + strokePhysicalLogLikelihood
                            + erasedHistoryAdjustment,
                        stringContextLogLikelihood: parent.stringContextLogLikelihood + log(partial),
                        spellingPower: OldOSZephyrHitTester.letterTypingSpellPowerPhone,
                        priorTouchVectors: OldOSZephyrHitTester.branchPriorTouchCache(
                            appending: alternative.errorVector,
                            to: parent.priorTouchVectors
                        ),
                        erasedStrokeCount: parent.erasedStrokeCount,
                        predictedSymbolCount: 0,
                        cameFromPredictStroke: false
                    )
                    next.insert(child)
                }
            }

            if let logRatio = stroke.sourceLogPruningRatio {
                next.pruneWithRatioToNewTop(logRatio)
            }
            current = next.entries
            if current.isEmpty { break }
        }

        return current
    }

    public func ztPredictiveCandidates(
        from liveEntries: [ZTSymbolEntry],
        maximumDepth: Int = OldOSZephyrHitTester.predictiveMaximumDepth,
        beamWidth: Int = OldOSZephyrHitTester.sourceBeamWidth
    ) -> [AutocorrectionCandidate] {
        guard !liveEntries.isEmpty, maximumDepth > 0 else { return [] }

        var parents = liveEntries
        var found: [AutocorrectionCandidate] = []

        for depth in 1...maximumDepth {
            var next = ZTInsertionSortStack(capacity: beamWidth)

            for parent in parents {

                var nextLetters = Set<UInt8>()
                for nextLetter in sortedNextLetters(after: parent.sortKey) {
                    guard let scalar = nextLetter.character.unicodeScalars.first,
                          scalar.value >= 97, scalar.value <= 122 else { continue }
                    nextLetters.insert(UInt8(scalar.value))
                }
                for dynamic in parent.dictionaryCursors.dynamicEntries {
                    let bytes = Array(dynamic.sortKey.utf8)
                    let offset = parent.sortKey.utf8.count
                    if offset < bytes.count { nextLetters.insert(bytes[offset]) }
                }

                for letter in nextLetters {
                    guard let advanced = ztAdvanceDictionaryCursors(
                        parent.dictionaryCursors,
                        lowercaseASCII: letter
                    ) else { continue }

                    let prefixLength = parent.sortKey.unicodeScalars.count
                    let costIndex = min(
                        prefixLength,
                        OldOSZephyrHitTester.nonStopPredictCosts.count - 1
                    )
                    let predictionCost = OldOSZephyrHitTester.nonStopPredictCosts[costIndex]
                    let combinedPartial = advanced.combinedPartialProbability * predictionCost
                    guard combinedPartial > 0 else { continue }

                    let child = ZTSymbolEntry(
                        sortKey: advanced.cursors.sortKey,
                        parentSortKey: parent.sortKey,
                        strokeIndex: parent.strokeIndex,
                        symbolASCII: letter,
                        dictionaryCursors: advanced.cursors,
                        physicalLogLikelihood: parent.physicalLogLikelihood,
                        stringContextLogLikelihood: parent.stringContextLogLikelihood + log(combinedPartial),
                        spellingPower: OldOSZephyrHitTester.predictiveSpellPowerPhone,
                        priorTouchVectors: parent.priorTouchVectors,
                        erasedStrokeCount: parent.erasedStrokeCount,
                        predictedSymbolCount: depth,
                        cameFromPredictStroke: true
                    )
                    next.insert(child)
                }
            }

            next.pruneWithRatioToNewTop(
                OldOSZephyrHitTester.predictiveLogPruningRatioPhone
            )
            parents = next.entries
            if parents.isEmpty { break }
            for entry in parents {
                found.append(contentsOf: ztTerminalCandidates(for: entry))
            }
        }

        return found
    }

    public func ztLiveBeamCandidates(
        for typedSurface: String,
        touchEvidence: [OldOSZephyrAutocorrectionTouchEvidence],
        learnedSurfaces: [String: Int],
        includePredictStroke: Bool = true
    ) -> ZTBeamResult {
        guard let typedSortKey = Self.autocorrectionLookupKey(for: typedSurface) else {
            return ZTBeamResult(liveEntries: [], candidates: [], usedPhysicalTouchEvidence: false)
        }

        let dynamicEntries = learnedSurfaces.compactMap {
            ZTDynamicEntry(surface: $0.key, userFrequency: $0.value)
        }
        let live = ztBuildLiveBeam(
            typedSortKey: typedSortKey,
            touchEvidence: touchEvidence,
            dynamicEntries: dynamicEntries
        )

        var candidates: [AutocorrectionCandidate] = []
        for entry in live {
            candidates.append(contentsOf: ztTerminalCandidates(for: entry))
        }
        if includePredictStroke {
            candidates.append(contentsOf: ztPredictiveCandidates(from: live))
        }

        let hasRealEvidence = touchEvidence.count == typedSortKey.utf8.count
            && zip(touchEvidence, typedSortKey.utf8).allSatisfy {
                $0.0.committedLowercaseASCII == $0.1
            }
        return ZTBeamResult(
            liveEntries: live,
            candidates: candidates,
            usedPhysicalTouchEvidence: hasRealEvidence
        )
    }
}

private extension Character {
    var isASCIILetter: Bool {
        guard let scalar = unicodeScalars.first, unicodeScalars.count == 1 else { return false }
        let v = scalar.value
        return v >= 97 && v <= 122
    }
}
