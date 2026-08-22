#if DEBUG
import SwiftUI
import UIKit

public struct OldOSZephyrDebugView: View {
    @State private var context: String = "th"
    @State private var useLanguage = true
    @State private var interKeyInterval: Double = 0.35
    @State private var majorRadius: Double = 6.5
    @State private var priorDX: Double = 0
    @State private var priorDY: Double = 0
    @State private var selectedPoint = CGPoint(x: 80, y: 27)
    @State private var sampleStep: CGFloat = 3

    private let model: OldOSZephyrStaticLanguageModel?
    private let hitTester: OldOSZephyrHitTester

    public init() {
        let model = try? OldOSZephyrStaticLanguageModel.bundledUS()
        self.model = model
        self.hitTester = OldOSZephyrHitTester(languageModel: model)
    }

    private var placedKeys: [OldOSKeyboardPlacedKey] {
        OldOSKeyboardLayout.keys(
            plane: .letters,
            shift: .off,
            configuration: .standard,
            returnKeyEnabled: true
        )
    }

    private var keyAreas: [OldOSZephyrKeyArea] {
        placedKeys.compactMap { placed in
            let key = placed.key
            let lower = (key.output ?? key.label).lowercased()
            let upper = (key.output ?? key.label).uppercased()
            let alphabetic = lower.count == 1 && lower.unicodeScalars.allSatisfy {
                ($0.value >= 97 && $0.value <= 122)
            }

            guard alphabetic else { return nil }
            return OldOSZephyrKeyArea(
                id: placed.id,
                frame: placed.hitFrame,
                lower: lower,
                upper: upper,
                isAlphabetic: true,
                isEnabled: key.isEnabled
            )
        }
    }

    private var profile: OldOSZephyrTouchProfile {
        var priors: [OldOSZephyrPriorTouchVector] = []
        if abs(priorDX) > 0.0001 || abs(priorDY) > 0.0001 {
            priors = [OldOSZephyrPriorTouchVector(
                error: OldOSZephyrVector(dx: priorDX, dy: priorDY),
                xWeight: 1,
                yWeight: 1
            )]
        }
        return OldOSZephyrTouchProfile(
            interKeyInterval: interKeyInterval,
            majorRadius: CGFloat(majorRadius),
            priorTouchVectors: priors
        )
    }

    private var currentPrefix: String {
        OldOSZephyrStaticLanguageModel.currentASCIIWordPrefix(in: context)
    }

    private var selectedDecision: OldOSZephyrDecision? {
        hitTester.decision(
            at: selectedPoint,
            keys: keyAreas,
            wordPrefix: currentPrefix,
            profile: profile,
            useLanguage: useLanguage
        )
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("iOS 4.3 Zephyr adaptive-key map")
                    .font(.headline)

                HStack(spacing: 8) {
                    ForEach(["", "th", "q", "qu", "hel", "wor"], id: \.self) { prefix in
                        Button(prefix.isEmpty ? "∅" : prefix) { context = prefix }
                    }
                }

                TextField("word prefix", text: $context).oldOSKeyboard(.standard)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                Toggle("Apple en_US static language probability", isOn: $useLanguage)

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "Inter-key interval: %.3f s   quickness: %.3f",
                                interKeyInterval,
                                OldOSZephyrHitTester.quickness(forInterKeyInterval: interKeyInterval)))
                    Slider(value: $interKeyInterval, in: 0.08...0.50, step: 0.005)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "Touch major radius: %.2f   thumbness: %.3f",
                                majorRadius,
                                OldOSZephyrHitTester.thumbness(forMajorRadius: CGFloat(majorRadius))))
                    Slider(value: $majorRadius, in: 5...14, step: 0.25)
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text(String(format: "Prior drift X: %.1f", priorDX))
                        Slider(value: $priorDX, in: -10...10, step: 0.5)
                    }
                    VStack(alignment: .leading) {
                        Text(String(format: "Prior drift Y: %.1f", priorDY))
                        Slider(value: $priorDY, in: -10...10, step: 0.5)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "σtouch %.3f pt   σinter %.3f pt   neighbor %.3f pt",
                                OldOSZephyrHitTester.touchSigma(profile: profile),
                                OldOSZephyrHitTester.interTouchSigma(profile: profile, alphabetic: true),
                                OldOSZephyrHitTester.neighborRadius(profile: profile)))
                        .font(.caption.monospacedDigit())

                    GeometryReader { proxy in
                        let sx = proxy.size.width / OldOSKeyboardLayout.referenceSize.width
                        let sy = proxy.size.height / OldOSKeyboardLayout.referenceSize.height
                        ZStack(alignment: .topLeading) {
                            OldOSZephyrDecisionMapRepresentable(
                                hitTester: hitTester,
                                keys: keyAreas,
                                wordPrefix: currentPrefix,
                                profile: profile,
                                useLanguage: useLanguage,
                                step: sampleStep,
                                selectedPoint: selectedPoint
                            )
                            .allowsHitTesting(false)

                            ForEach(placedKeys) { placed in
                                let frame = placed.hitFrame
                                Rectangle()
                                    .stroke(Color.primary.opacity(0.32), lineWidth: 0.5)
                                    .frame(width: frame.width * sx, height: frame.height * sy)
                                    .position(x: frame.midX * sx, y: frame.midY * sy)

                                if placed.key.kind == .character {
                                    Text(placed.key.displayLabel(shift: .off))
                                        .font(.caption2.bold())
                                        .position(x: frame.midX * sx, y: frame.midY * sy)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    selectedPoint = CGPoint(
                                        x: min(320, max(0, value.location.x / sx)),
                                        y: min(216, max(0, value.location.y / sy))
                                    )
                                }
                        )
                    }
                    .aspectRatio(320.0 / 216.0, contentMode: .fit)
                }

                if let decision = selectedDecision {
                    Text(String(format: "Selected point (%.1f, %.1f) → %@",
                                selectedPoint.x, selectedPoint.y, decision.winner.key.lower.uppercased()))
                        .font(.headline.monospacedDigit())

                    ForEach(Array(decision.candidates.prefix(6))) { score in
                        Text(String(format:
                            "%@  total=% .4f  geom=% .4f  hist=% .4f  P=% .6f  lang=% .4f",
                            score.key.lower.uppercased(),
                            score.totalLogLikelihood,
                            score.geometryLogLikelihood,
                            score.historyLogLikelihood,
                            score.staticLanguageProbability,
                            score.languageLogLikelihood
                        ))
                        .font(.caption.monospacedDigit())
                    }
                }

                if let model {
                    let next = model.sortedNextLetters(after: currentPrefix).prefix(10)
                    Text("Static iOS 4.3 trie: " + next.map {
                        "\($0.character)=\(String(format: "%.4f", $0.probability))"
                    }.joined(separator: "   "))
                    .font(.caption.monospacedDigit())
                } else {
                    Text("Unigrams-en_US.idx/dat not found in the app bundle.")
                        .foregroundColor(.red)
                }

                Text("Production OldOS hit testing is intentionally unchanged in this research build. The map uses exact production hitFrame geometry but only alphabetic candidates until the special-key Zephyr action costs are translated.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

private struct OldOSZephyrDecisionMapRepresentable: UIViewRepresentable {
    let hitTester: OldOSZephyrHitTester
    let keys: [OldOSZephyrKeyArea]
    let wordPrefix: String
    let profile: OldOSZephyrTouchProfile
    let useLanguage: Bool
    let step: CGFloat
    let selectedPoint: CGPoint

    func makeUIView(context: Context) -> OldOSZephyrDecisionMapUIView {
        let view = OldOSZephyrDecisionMapUIView()
        view.isOpaque = true
        return view
    }

    func updateUIView(_ view: OldOSZephyrDecisionMapUIView, context: Context) {
        view.hitTester = hitTester
        view.keys = keys
        view.wordPrefix = wordPrefix
        view.profile = profile
        view.useLanguage = useLanguage
        view.sampleStep = step
        view.selectedPoint = selectedPoint
        view.setNeedsDisplay()
    }
}

private final class OldOSZephyrDecisionMapUIView: UIView {
    var hitTester: OldOSZephyrHitTester?
    var keys: [OldOSZephyrKeyArea] = []
    var wordPrefix = ""
    var profile = OldOSZephyrTouchProfile()
    var useLanguage = true
    var sampleStep: CGFloat = 3
    var selectedPoint = CGPoint.zero

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let hitTester else { return }
        context.setFillColor(UIColor(white: 0.92, alpha: 1).cgColor)
        context.fill(bounds)

        let sx = bounds.width / 320
        let sy = bounds.height / 216
        let logicalStep = max(1, sampleStep)
        let colorByID = Dictionary(uniqueKeysWithValues: keys.enumerated().map { index, key in
            let hue = CGFloat((index * 37) % 360) / 360
            return (key.id, UIColor(hue: hue, saturation: 0.30, brightness: 0.96, alpha: 1))
        })

        var y: CGFloat = logicalStep * 0.5
        while y < 216 {
            var x: CGFloat = logicalStep * 0.5
            while x < 320 {
                if let decision = hitTester.decision(
                    at: CGPoint(x: x, y: y),
                    keys: keys,
                    wordPrefix: wordPrefix,
                    profile: profile,
                    useLanguage: useLanguage
                ), let color = colorByID[decision.winner.key.id] {
                    context.setFillColor(color.cgColor)
                    context.fill(CGRect(
                        x: (x - logicalStep * 0.5) * sx,
                        y: (y - logicalStep * 0.5) * sy,
                        width: logicalStep * sx + 0.5,
                        height: logicalStep * sy + 0.5
                    ))
                }
                x += logicalStep
            }
            y += logicalStep
        }

        context.setStrokeColor(UIColor.black.withAlphaComponent(0.70).cgColor)
        context.setLineWidth(1.0)
        context.strokeEllipse(in: CGRect(
            x: selectedPoint.x * sx - 4,
            y: selectedPoint.y * sy - 4,
            width: 8,
            height: 8
        ))
    }
}
#endif
