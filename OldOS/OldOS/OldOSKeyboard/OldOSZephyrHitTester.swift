import Foundation

public struct OldOSZephyrVector: Equatable {
    public let dx: Double
    public let dy: Double

    public init(dx: Double, dy: Double) {
        self.dx = dx
        self.dy = dy
    }
}

public struct OldOSZephyrKeyArea: Identifiable, Equatable {
    public let id: String
    public let frame: CGRect
    public let lower: String
    public let upper: String
    public let isAlphabetic: Bool
    public let isEnabled: Bool

    public init(
        id: String,
        frame: CGRect,
        lower: String,
        upper: String,
        isAlphabetic: Bool,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.frame = frame
        self.lower = lower
        self.upper = upper
        self.isAlphabetic = isAlphabetic
        self.isEnabled = isEnabled
    }

    public var center: CGPoint { CGPoint(x: frame.midX, y: frame.midY) }
    public var horizontalRadius: CGFloat { frame.width * 0.5 }
    public var verticalRadius: CGFloat { frame.height * 0.5 }
}

public struct OldOSZephyrPriorTouchVector: Equatable {

    public let error: OldOSZephyrVector
    public let xWeight: Double
    public let yWeight: Double

    public init(error: OldOSZephyrVector, xWeight: Double = 1, yWeight: Double = 1) {
        self.error = error
        self.xWeight = xWeight
        self.yWeight = yWeight
    }
}

public struct OldOSZephyrTouchProfile: Equatable {
    public var interKeyInterval: TimeInterval
    public var majorRadius: CGFloat
    public var forceMaximumCorrelation: Bool
    public var priorTouchVectors: [OldOSZephyrPriorTouchVector]

    public init(
        interKeyInterval: TimeInterval = 0.35,
        majorRadius: CGFloat = 6.5,
        forceMaximumCorrelation: Bool = false,
        priorTouchVectors: [OldOSZephyrPriorTouchVector] = []
    ) {
        self.interKeyInterval = interKeyInterval
        self.majorRadius = majorRadius
        self.forceMaximumCorrelation = forceMaximumCorrelation
        self.priorTouchVectors = priorTouchVectors
    }
}

public struct OldOSZephyrScore: Identifiable, Equatable {
    public let id: String
    public let key: OldOSZephyrKeyArea
    public let errorVector: OldOSZephyrVector
    public let squareError: Double
    public let geometryLogLikelihood: Double
    public let historyLogLikelihood: Double
    public let staticLanguageProbability: Double
    public let languageLogLikelihood: Double
    public let totalLogLikelihood: Double
}

public struct OldOSZephyrDecision: Equatable {
    public let winner: OldOSZephyrScore
    public let candidates: [OldOSZephyrScore]
}

public struct OldOSZephyrAutocorrectionTouchEvidence: Equatable {
    public let point: CGPoint
    public let committedLowercaseASCII: UInt8

    public let relativePhysicalLogLikelihoods: [UInt8: Double]

    public let geometryLogLikelihoods: [UInt8: Double]
    public let keyErrorVectors: [UInt8: OldOSZephyrVector]
    public let keySquareErrors: [UInt8: Double]
    public let neighborRadiusSquared: Double?
    public let interTouchSigma: Double?

    public let sourceLogPruningRatio: Double?

    public let erasedKeyHistory: [UInt8]

    public init(
        point: CGPoint,
        committedLowercaseASCII: UInt8,
        relativePhysicalLogLikelihoods: [UInt8: Double],
        geometryLogLikelihoods: [UInt8: Double] = [:],
        keyErrorVectors: [UInt8: OldOSZephyrVector] = [:],
        keySquareErrors: [UInt8: Double] = [:],
        neighborRadiusSquared: Double? = nil,
        interTouchSigma: Double? = nil,
        sourceLogPruningRatio: Double? = nil,
        erasedKeyHistory: [UInt8] = []
    ) {
        self.point = point
        self.committedLowercaseASCII = committedLowercaseASCII
        self.relativePhysicalLogLikelihoods = relativePhysicalLogLikelihoods
        self.geometryLogLikelihoods = geometryLogLikelihoods
        self.keyErrorVectors = keyErrorVectors
        self.keySquareErrors = keySquareErrors
        self.neighborRadiusSquared = neighborRadiusSquared
        self.interTouchSigma = interTouchSigma
        self.sourceLogPruningRatio = sourceLogPruningRatio
        self.erasedKeyHistory = Array(erasedKeyHistory.suffix(2))
    }

    public func withErasedKeyHistory(_ history: [UInt8]) -> OldOSZephyrAutocorrectionTouchEvidence {
        OldOSZephyrAutocorrectionTouchEvidence(
            point: point,
            committedLowercaseASCII: committedLowercaseASCII,
            relativePhysicalLogLikelihoods: relativePhysicalLogLikelihoods,
            geometryLogLikelihoods: geometryLogLikelihoods,
            keyErrorVectors: keyErrorVectors,
            keySquareErrors: keySquareErrors,
            neighborRadiusSquared: neighborRadiusSquared,
            interTouchSigma: interTouchSigma,
            sourceLogPruningRatio: sourceLogPruningRatio,
            erasedKeyHistory: history
        )
    }

    public func relativePhysicalLogLikelihood(for lowercaseASCII: UInt8) -> Double? {
        relativePhysicalLogLikelihoods[lowercaseASCII]
    }
}

public final class OldOSZephyrHitTester {

    public static let pointsPerMillimeter: Double = 6.3

    public static let maximumRadiusBeforeDeadzone: Double = 3.0 * pointsPerMillimeter
    public static let slowNeighborRadius: Double = 10.25 * pointsPerMillimeter
    public static let fastNeighborRadius: Double = 11.0 * pointsPerMillimeter

    public static let fingerKeyCenterSigma: Double = 1.15 * pointsPerMillimeter
    public static let thumbKeyCenterSigma: Double = 1.75 * pointsPerMillimeter
    public static let fingerInterTouchSigma: Double = 1.70 * pointsPerMillimeter
    public static let thumbInterTouchSigma: Double = 2.40 * pointsPerMillimeter
    public static let nonAlphabeticInterTouchSigma: Double = 5.0 * pointsPerMillimeter

    public static let fingertipMajorRadius: Double = 6.5
    public static let thumbHighMajorRadius: Double = 12.0

    public static let fastInterKeyInterval: Double = 0.15
    public static let moderateInterKeyInterval: Double = 0.35
    public static let slowInterKeyInterval: Double = 0.50
    public static let interKeyIntervalFilterAlpha: Double = 0.80

    public static let letterTypingSpellPowerPhone: Double = 0.14
    public static let letterTypingSpellPowerPad: Double = 0.18
    public static let correctiveTypingSpellPower: Double = 0.12
    public static let numberPunctuationSpellPower: Double = 0.02
    public static let predictiveSpellPowerPhone: Double = 0.30
    public static let predictiveSpellPowerPad: Double = 0.35

    public static let unknownSpellProbability: Double = 0.00004
    public static let unknownAccentPredecessorProbability: Double = 0.0000004
    public static let repeatedNonLetterProbability: Double = 0.0025

    public static let keyTapPruningBaseProbability: Double = 0.0025
    public static let returnSpellProbabilityCost: Double = 0.005
    public static let shiftMoreSpellProbability: Double = 0.002
    public static let backspaceSpellProbability: Double = 0.004
    public static let letterModifierProbability: Double = 0.0004
    public static let longerPredictionCost: Double = 0.8

    public static let erasedCharacterLogCost: Double = -0.1625

    public static let erasedSymbolHistoryMatchCost: Double = 0.005

    public static let sourceMaximumPriorTouchVectors = 32

    public static let sourceBeamWidth = 20
    public static let predictiveMaximumDepth = 31

    public static let nonStopPredictCosts: [Double] = [
        0.001, 0.03, 0.0005, 0.0004, 0.0005, 0.0006
    ]
    public static let stopPredictCost: Double = 0.001

    public static let maximumNeighborCount = 13

    public var languageModel: OldOSZephyrStaticLanguageModel?

    public init(languageModel: OldOSZephyrStaticLanguageModel? = nil) {
        self.languageModel = languageModel
    }

    public static func quickness(forInterKeyInterval interval: TimeInterval) -> Double {
        let x = Double(interval)
        if x < fastInterKeyInterval { return 1 }
        if x >= moderateInterKeyInterval { return 0 }
        return (moderateInterKeyInterval - x) / (moderateInterKeyInterval - fastInterKeyInterval)
    }

    public static func thumbness(forMajorRadius majorRadius: CGFloat) -> Double {
        let x = Double(majorRadius)
        if x < fingertipMajorRadius { return 0 }
        if x >= thumbHighMajorRadius { return 1 }
        return (x - fingertipMajorRadius) / (thumbHighMajorRadius - fingertipMajorRadius)
    }

    public static func zoneCorrelation(profile: OldOSZephyrTouchProfile) -> Double {
        if profile.forceMaximumCorrelation { return 1 }
        let thumb = thumbness(forMajorRadius: profile.majorRadius)
        let quick = quickness(forInterKeyInterval: profile.interKeyInterval)

        return min(1, 0.3 * thumb + quick * (1 + 0.7 * thumb))
    }

    public static func touchSigma(profile: OldOSZephyrTouchProfile) -> Double {
        let c = zoneCorrelation(profile: profile)
        return fingerKeyCenterSigma + c * (thumbKeyCenterSigma - fingerKeyCenterSigma)
    }

    public static func interTouchSigma(profile: OldOSZephyrTouchProfile, alphabetic: Bool) -> Double {
        guard alphabetic else { return nonAlphabeticInterTouchSigma }
        let c = zoneCorrelation(profile: profile)
        return fingerInterTouchSigma + c * (thumbInterTouchSigma - fingerInterTouchSigma)
    }

    public static func neighborRadius(profile: OldOSZephyrTouchProfile) -> Double {
        let q = quickness(forInterKeyInterval: profile.interKeyInterval)
        return slowNeighborRadius + q * (fastNeighborRadius - slowNeighborRadius)
    }

    public static func keyTapLogPruningRatio(
        profile: OldOSZephyrTouchProfile,
        spellingPower: Double = letterTypingSpellPowerPhone
    ) -> Double {
        let radius = neighborRadius(profile: profile)
        let radiusSquared = radius * radius
        let fingerKeyNormalizer = normalizer(sigma: touchSigma(profile: profile))
        let interTouchNormalizer = normalizer(
            sigma: interTouchSigma(profile: profile, alphabetic: true)
        )
        return spellingPower * log(keyTapPruningBaseProbability)
            - radiusSquared * fingerKeyNormalizer
            - 0.5 * radiusSquared * interTouchNormalizer
    }

    public static var predictiveLogPruningRatioPhone: Double {
        predictiveSpellPowerPhone * log(unknownSpellProbability)
    }

    public static func errorVector(touch: CGPoint, key: OldOSZephyrKeyArea) -> OldOSZephyrVector {
        var dx = Double(touch.x - key.center.x)
        let dy = Double(touch.y - key.center.y)
        let horizontalRadius = Double(key.horizontalRadius)
        if horizontalRadius > maximumRadiusBeforeDeadzone {
            let deadzone = horizontalRadius - maximumRadiusBeforeDeadzone
            let magnitude = abs(dx)
            if magnitude <= deadzone {
                dx = 0
            } else {
                dx = dx < 0 ? -(magnitude - deadzone) : (magnitude - deadzone)
            }
        }
        return OldOSZephyrVector(dx: dx, dy: dy)
    }

    public static func squareError(_ vector: OldOSZephyrVector) -> Double {
        vector.dx * vector.dx + vector.dy * vector.dy
    }

    public static func normalizer(sigma: Double) -> Double {
        1.0 / (4.0 * sigma * sigma)
    }

    public static func historyLogLikelihood(
        candidateError: OldOSZephyrVector,
        priors: [OldOSZephyrPriorTouchVector],
        sigma: Double
    ) -> Double {
        guard !priors.isEmpty else { return 0 }
        var xWeightedError = 0.0
        var yWeightedError = 0.0
        var xWeightSum = 0.0
        var yWeightSum = 0.0
        for p in priors {
            let dx = candidateError.dx - p.error.dx
            let dy = candidateError.dy - p.error.dy
            xWeightedError += p.xWeight * dx * dx
            yWeightedError += p.yWeight * dy * dy
            xWeightSum += p.xWeight
            yWeightSum += p.yWeight
        }
        let square = xWeightedError / max(xWeightSum, 2.0)
                   + yWeightedError / max(yWeightSum, 2.0)
        return -square * normalizer(sigma: sigma)
    }

    public static func branchPriorTouchCache(
        appending error: OldOSZephyrVector?,
        to existing: [OldOSZephyrPriorTouchVector],
        xWeight: Double = 1,
        yWeight: Double = 1
    ) -> [OldOSZephyrPriorTouchVector] {
        guard let error else { return existing }
        var result = [OldOSZephyrPriorTouchVector(
            error: error,
            xWeight: xWeight,
            yWeight: yWeight
        )]
        result.append(contentsOf: existing.prefix(max(0, sourceMaximumPriorTouchVectors - 1)))
        return result
    }

    public static func autocorrectionTouchEvidence(
        at touch: CGPoint,
        keys: [OldOSZephyrKeyArea],
        committedKeyID: String,
        profile: OldOSZephyrTouchProfile
    ) -> OldOSZephyrAutocorrectionTouchEvidence? {
        let alphabetic = keys.filter { $0.isEnabled && $0.isAlphabetic }
        guard let committedKey = alphabetic.first(where: { $0.id == committedKeyID }),
              let committedScalar = committedKey.lower.lowercased().unicodeScalars.first,
              committedKey.lower.lowercased().unicodeScalars.count == 1,
              committedScalar.value >= 97,
              committedScalar.value <= 122
        else { return nil }

        let touchSigma = self.touchSigma(profile: profile)
        let geometryNormalizer = self.normalizer(sigma: touchSigma)
        let historySigma = self.interTouchSigma(profile: profile, alphabetic: true)

        var absolute: [UInt8: Double] = [:]
        var geometry: [UInt8: Double] = [:]
        var errors: [UInt8: OldOSZephyrVector] = [:]
        var squareErrors: [UInt8: Double] = [:]
        absolute.reserveCapacity(alphabetic.count)
        geometry.reserveCapacity(alphabetic.count)
        errors.reserveCapacity(alphabetic.count)
        squareErrors.reserveCapacity(alphabetic.count)

        for key in alphabetic {
            guard let scalar = key.lower.lowercased().unicodeScalars.first,
                  key.lower.lowercased().unicodeScalars.count == 1,
                  scalar.value >= 97,
                  scalar.value <= 122
            else { continue }

            let ascii = UInt8(scalar.value)
            let error = self.errorVector(touch: touch, key: key)
            let square = self.squareError(error)
            let geometryLL = -square * geometryNormalizer
            let historyLL = self.historyLogLikelihood(
                candidateError: error,
                priors: profile.priorTouchVectors,
                sigma: historySigma
            )
            geometry[ascii] = geometryLL
            errors[ascii] = error
            squareErrors[ascii] = square
            absolute[ascii] = geometryLL + historyLL
        }

        let committedASCII = UInt8(committedScalar.value)
        guard let baseline = absolute[committedASCII] else { return nil }

        var relative: [UInt8: Double] = [:]
        relative.reserveCapacity(absolute.count)
        for (ascii, value) in absolute {
            relative[ascii] = value - baseline
        }

        let radius = self.neighborRadius(profile: profile)
        return OldOSZephyrAutocorrectionTouchEvidence(
            point: touch,
            committedLowercaseASCII: committedASCII,
            relativePhysicalLogLikelihoods: relative,
            geometryLogLikelihoods: geometry,
            keyErrorVectors: errors,
            keySquareErrors: squareErrors,
            neighborRadiusSquared: radius * radius,
            interTouchSigma: historySigma,
            sourceLogPruningRatio: self.keyTapLogPruningRatio(profile: profile)
        )
    }

    public func decision(
        at touch: CGPoint,
        keys: [OldOSZephyrKeyArea],
        wordPrefix: String,
        profile: OldOSZephyrTouchProfile,
        useLanguage: Bool = true,
        forceShift: Bool = false
    ) -> OldOSZephyrDecision? {
        let enabled = keys.filter(\.isEnabled)
        guard !enabled.isEmpty else { return nil }

        let withError = enabled.map { key -> (OldOSZephyrKeyArea, OldOSZephyrVector, Double) in
            let e = Self.errorVector(touch: touch, key: key)
            return (key, e, Self.squareError(e))
        }.sorted { a, b in
            if a.2 == b.2 { return a.0.id < b.0.id }
            return a.2 < b.2
        }

        let radiusSquared = pow(Self.neighborRadius(profile: profile), 2)
        var physicalNeighbors = withError.filter { $0.2 <= radiusSquared }
        if physicalNeighbors.isEmpty { physicalNeighbors = Array(withError.prefix(Self.maximumNeighborCount)) }
        if physicalNeighbors.count > Self.maximumNeighborCount {
            physicalNeighbors = Array(physicalNeighbors.prefix(Self.maximumNeighborCount))
        }

        let touchSigma = Self.touchSigma(profile: profile)
        let geometryNormalizer = Self.normalizer(sigma: touchSigma)
        let staticProbabilities = useLanguage ? languageModel?.nextLetterProbabilities(after: wordPrefix) ?? [:] : [:]

        var scores: [OldOSZephyrScore] = []
        scores.reserveCapacity(physicalNeighbors.count)
        for (key, error, squareError) in physicalNeighbors {
            let geometryLL = -squareError * geometryNormalizer
            let historySigma = Self.interTouchSigma(profile: profile, alphabetic: key.isAlphabetic)
            let historyLL = Self.historyLogLikelihood(
                candidateError: error,
                priors: profile.priorTouchVectors,
                sigma: historySigma
            )

            let candidateText = forceShift ? key.upper : key.lower
            let candidateCharacter = candidateText.lowercased().first
            let p: Double
            let spellPower: Double
            if useLanguage, key.isAlphabetic, let candidateCharacter {
                p = staticProbabilities[candidateCharacter] ?? Self.unknownSpellProbability
                spellPower = Self.letterTypingSpellPowerPhone
            } else {

                p = 1
                spellPower = 0
            }

            let languageLL = spellPower == 0 ? 0 : spellPower * log(max(p, Double.leastNonzeroMagnitude))
            let total = geometryLL + historyLL + languageLL
            scores.append(OldOSZephyrScore(
                id: key.id,
                key: key,
                errorVector: error,
                squareError: squareError,
                geometryLogLikelihood: geometryLL,
                historyLogLikelihood: historyLL,
                staticLanguageProbability: p,
                languageLogLikelihood: languageLL,
                totalLogLikelihood: total
            ))
        }

        scores.sort {
            if $0.totalLogLikelihood == $1.totalLogLikelihood { return $0.squareError < $1.squareError }
            return $0.totalLogLikelihood > $1.totalLogLikelihood
        }
        guard let winner = scores.first else { return nil }
        return OldOSZephyrDecision(winner: winner, candidates: scores)
    }
}
