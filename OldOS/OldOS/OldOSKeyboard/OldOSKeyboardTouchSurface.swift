import SwiftUI
import UIKit

struct OldOSKeyboardTouchSample {
    enum Phase {
        case began
        case moved
        case ended
        case cancelled
    }

    let touchID: ObjectIdentifier
    let sequence: UInt64
    let phase: Phase
    let location: CGPoint
    let timestamp: TimeInterval
    let majorRadius: CGFloat
}

struct OldOSKeyboardTouchSurface: UIViewRepresentable {
    let logicalScale: CGFloat
    let onSample: (OldOSKeyboardTouchSample) -> Void

    func makeUIView(context: Context) -> OldOSKeyboardTouchCaptureView {
        let view = OldOSKeyboardTouchCaptureView()
        view.backgroundColor = .clear
        view.isOpaque = false

        view.isMultipleTouchEnabled = true
        view.logicalScale = max(logicalScale, 0.0001)
        view.onSample = onSample
        return view
    }

    func updateUIView(_ uiView: OldOSKeyboardTouchCaptureView, context: Context) {
        uiView.logicalScale = max(logicalScale, 0.0001)
        uiView.onSample = onSample
        if !uiView.isMultipleTouchEnabled {
            uiView.isMultipleTouchEnabled = true
        }
    }
}

final class OldOSKeyboardTouchCaptureView: UIView {
    var logicalScale: CGFloat = 1
    var onSample: ((OldOSKeyboardTouchSample) -> Void)?

    private var nextSequence: UInt64 = 0
    private var touchSequences: [ObjectIdentifier: UInt64] = [:]

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        let ordered = touches.sorted {
            if $0.timestamp != $1.timestamp { return $0.timestamp < $1.timestamp }
            return UInt(bitPattern: ObjectIdentifier($0)) < UInt(bitPattern: ObjectIdentifier($1))
        }

        for touch in ordered {
            let id = ObjectIdentifier(touch)
            guard touchSequences[id] == nil else { continue }
            let sequence = nextSequence
            nextSequence &+= 1
            touchSequences[id] = sequence
            emit(touch, id: id, sequence: sequence, phase: .began)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in orderedTrackedTouches(touches) {
            let id = ObjectIdentifier(touch)
            guard let sequence = touchSequences[id] else { continue }
            emit(touch, id: id, sequence: sequence, phase: .moved)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in orderedTrackedTouches(touches) {
            let id = ObjectIdentifier(touch)
            guard let sequence = touchSequences[id] else { continue }
            emit(touch, id: id, sequence: sequence, phase: .ended)
            touchSequences.removeValue(forKey: id)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in orderedTrackedTouches(touches) {
            let id = ObjectIdentifier(touch)
            guard let sequence = touchSequences[id] else { continue }
            emit(touch, id: id, sequence: sequence, phase: .cancelled)
            touchSequences.removeValue(forKey: id)
        }
    }

    private func orderedTrackedTouches(_ touches: Set<UITouch>) -> [UITouch] {
        touches.sorted {
            let lhs = touchSequences[ObjectIdentifier($0)] ?? UInt64.max
            let rhs = touchSequences[ObjectIdentifier($1)] ?? UInt64.max
            if lhs != rhs { return lhs < rhs }
            return $0.timestamp < $1.timestamp
        }
    }

    private func emit(
        _ touch: UITouch,
        id: ObjectIdentifier,
        sequence: UInt64,
        phase: OldOSKeyboardTouchSample.Phase
    ) {
        let scale = max(logicalScale, 0.0001)
        let p = touch.location(in: self)
        onSample?(OldOSKeyboardTouchSample(
            touchID: id,
            sequence: sequence,
            phase: phase,
            location: CGPoint(x: p.x / scale, y: p.y / scale),
            timestamp: touch.timestamp,

            majorRadius: touch.majorRadius / scale
        ))
    }
}
