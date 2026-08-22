import SwiftUI

enum OldOSKeyboardPalette {
    static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> Color {
        Color(red: r / 255, green: g / 255, blue: b / 255, opacity: a)
    }

    static let keyboardTop = rgb(145, 153, 164)
    static let keyboardBottom = rgb(68, 78, 92)
    static let keyboardTopDarkLip = rgb(58, 61, 66)
    static let keyboardTopBrightLip = rgb(178, 184, 191)

    static let lightRows: [(top: Color, bottom: Color, highlight: Color)] = [
        (rgb(250,250,251), rgb(221,223,225), .white),
        (rgb(245,246,247), rgb(217,219,221), .white),
        (rgb(237,238,240), rgb(212,214,218), .white),
        (rgb(224,225,228), rgb(179,183,190), .white)
    ]

    static let darkRows: [(top: Color, bottom: Color, highlight: Color)] = [
        (rgb(149,157,168), rgb(102,111,126), rgb(201,205,209)),
        (rgb(149,157,168), rgb(102,111,126), rgb(201,205,209)),
        (rgb(149,157,168), rgb(102,111,126), rgb(201,205,209)),
        (rgb(130,138,149), rgb(80,89,102), rgb(168,174,182))
    ]

    static let blue = (
        top: rgb(66,135,245),
        bottom: rgb(25,79,220),
        highlight: rgb(108,172,249)
    )

    static let spacePressed = (
        top: rgb(169,173,180),
        bottom: rgb(122,128,139),
        highlight: rgb(201,204,209)
    )
}

struct OldOSKeyboardBackground: View {
    let scale: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [
                    OldOSKeyboardPalette.keyboardTop,
                    OldOSKeyboardPalette.keyboardBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                OldOSKeyboardPalette.keyboardTopDarkLip
                    .frame(height: max(0.5, 1 * scale))
                OldOSKeyboardPalette.keyboardTopBrightLip
                    .frame(height: max(0.5, 1 * scale))
                Spacer(minLength: 0)
            }
        }
    }
}

enum OldOSKeyCapTreatment: Equatable {
    case light
    case dark
    case blue
    case spacePressed
}

struct OldOSKeyCapBackground: View {
    let treatment: OldOSKeyCapTreatment
    let row: Int
    let scale: CGFloat

    private var palette: (top: Color, bottom: Color, highlight: Color) {
        let safeRow = min(max(row, 0), 3)
        switch treatment {
        case .light:
            return OldOSKeyboardPalette.lightRows[safeRow]
        case .dark:
            return OldOSKeyboardPalette.darkRows[safeRow]
        case .blue:
            return OldOSKeyboardPalette.blue
        case .spacePressed:
            return OldOSKeyboardPalette.spacePressed
        }
    }

    var body: some View {
        let radius = 4 * scale
        let shape = RoundedRectangle(cornerRadius: radius, style: .circular)

        ZStack {

            shape
                .fill(Color.black.opacity(0.075))
                .offset(y: 3 * scale)

            shape
                .fill(Color.black.opacity(0.18))
                .offset(y: 2 * scale)

            shape
                .fill(
                    LinearGradient(
                        colors: [palette.top, palette.bottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                .overlay(
                    shape.strokeBorder(
                        Color.black.opacity(0.08),
                        lineWidth: max(0.25, 0.30 * scale)
                    )
                )

                .overlay(
                    shape
                        .strokeBorder(
                            palette.highlight.opacity(0.96),
                            lineWidth: max(0.5, 0.75 * scale)
                        )
                        .mask(
                            VStack(spacing: 0) {
                                Rectangle().frame(height: 2.0 * scale)
                                Spacer(minLength: 0)
                            }
                        )
                )
        }
    }
}

struct OldOSNumberPadKeyBackground: View {
    let light: Bool
    let pressed: Bool
    let disabled: Bool
    let bottomLeft: Bool
    let bottomRight: Bool
    let scale: CGFloat

    var body: some View {

        let top: Color = light
            ? (pressed
                ? OldOSKeyboardPalette.rgb(154, 161, 171)
                : OldOSKeyboardPalette.rgb(249, 250, 251))
            : (pressed
                ? OldOSKeyboardPalette.rgb(121, 151, 196)
                : OldOSKeyboardPalette.rgb(132, 143, 158))

        let bottom: Color = light
            ? (pressed
                ? OldOSKeyboardPalette.rgb(111, 120, 133)
                : OldOSKeyboardPalette.rgb(210, 214, 220))
            : (pressed
                ? OldOSKeyboardPalette.rgb(73, 105, 155)
                : OldOSKeyboardPalette.rgb(78, 91, 109))

        let shape = OldOSNumberPadCellShape(
            radius: 5 * scale,
            bottomLeft: bottomLeft,
            bottomRight: bottomRight
        )

        shape
            .fill(
                LinearGradient(
                    colors: [top, bottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .opacity(disabled ? 0.88 : 1)
            .overlay(
                shape.strokeBorder(
                    Color.black.opacity(0.22),
                    lineWidth: max(0.5, 0.55 * scale)
                )
            )
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(light ? 0.52 : 0.16))
                    .frame(height: max(0.5, 0.65 * scale)),
                alignment: .top
            )
    }
}

private struct OldOSNumberPadCellShape: InsettableShape {
    var radius: CGFloat
    var bottomLeft: Bool
    var bottomRight: Bool
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> OldOSNumberPadCellShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let corner = max(0, min(radius - insetAmount, min(r.width, r.height) / 2))
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))

        if bottomRight {
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - corner))
            p.addQuadCurve(
                to: CGPoint(x: r.maxX - corner, y: r.maxY),
                control: CGPoint(x: r.maxX, y: r.maxY)
            )
        } else {
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        }

        if bottomLeft {
            p.addLine(to: CGPoint(x: r.minX + corner, y: r.maxY))
            p.addQuadCurve(
                to: CGPoint(x: r.minX, y: r.maxY - corner),
                control: CGPoint(x: r.minX, y: r.maxY)
            )
        } else {
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        }
        p.closeSubpath()
        return p
    }
}

struct OldOSAccentCellBackground: View {
    let selected: Bool
    let scale: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 4 * scale, style: .continuous)

        ZStack {

            shape
                .fill(Color.black.opacity(selected ? 0.20 : 0.16))
                .offset(y: 1.0 * scale)

            shape
                .fill(
                    LinearGradient(
                        colors: selected
                            ? [
                                Color(red: 67/255, green: 137/255, blue: 246/255),
                                Color(red: 28/255, green: 82/255, blue: 221/255)
                              ]
                            : [
                                Color(red: 250/255, green: 250/255, blue: 250/255),
                                Color(red: 218/255, green: 218/255, blue: 218/255)
                              ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    shape.strokeBorder(
                        Color.black.opacity(selected ? 0.42 : 0.30),
                        lineWidth: max(0.5, 0.75 * scale)
                    )
                )
                .overlay(
                    shape
                        .strokeBorder(Color.white.opacity(selected ? 0.28 : 0.92), lineWidth: max(0.45, 0.6 * scale))
                        .mask(
                            VStack(spacing: 0) {
                                Rectangle().frame(height: 2 * scale)
                                Spacer(minLength: 0)
                            }
                        )
                )
        }
    }
}

struct OldOSAccentShellView: UIViewRepresentable {
    let width: CGFloat
    let grabberName: String
    let grabberX: CGFloat
    let grabberY: CGFloat
    let assetNameOverride: String?
    let scale: CGFloat

    func makeUIView(context: Context) -> OldOSAccentShellDrawingView {
        let view = OldOSAccentShellDrawingView(frame: .zero)
        view.backgroundColor = .clear
        view.isOpaque = false
        view.isUserInteractionEnabled = false
        apply(to: view)
        return view
    }

    func updateUIView(_ uiView: OldOSAccentShellDrawingView, context: Context) {
        apply(to: uiView)
    }

    private func apply(to view: OldOSAccentShellDrawingView) {
        view.logicalWidth = width
        view.grabberName = grabberName
        view.grabberX = grabberX
        view.grabberY = grabberY
        view.assetNameOverride = assetNameOverride
        view.logicalScale = scale
        view.setNeedsDisplay()
    }
}

final class OldOSAccentShellDrawingView: UIView {
    var logicalWidth: CGFloat = 56
    var grabberName: String = "kb-accented-mid-grabber"
    var grabberX: CGFloat = 0
    var grabberY: CGFloat = 50
    var assetNameOverride: String? = nil
    var logicalScale: CGFloat = 1

    private static let shellCache = NSCache<NSString, UIImage>()

    private static func exact1xImage(named name: String) -> UIImage? {

        if let path = Bundle.main.path(forResource: name, ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        return UIImage(named: name)
    }

    private static func shellAssetName(width: CGFloat, grabberName: String, grabberX: CGFloat, grabberY: CGFloat) -> String? {
        let direction: String
        if grabberName.contains("right-grabber") {
            direction = "r"
        } else if grabberName.contains("left-grabber") {
            direction = "l"
        } else if grabberName.contains("mid-grabber") {
            direction = "m"
        } else {
            return nil
        }

        func token(_ value: CGFloat) -> String {
            let i = Int(round(value))
            return i < 0 ? "m\(abs(i))" : "\(i)"
        }

        let base = "kb-accent-shell-\(direction)-w\(Int(round(width)))-gx\(token(grabberX))"
        return abs(grabberY - 50) < 0.001 ? base : "\(base)-gy\(token(grabberY))"
    }

    private static func logicalComposite(width: CGFloat, grabberName: String, grabberX: CGFloat, grabberY: CGFloat, assetNameOverride: String?) -> UIImage? {
        let key = "\(assetNameOverride ?? "")|\(grabberName)|\(width)|\(grabberX)|\(grabberY)" as NSString
        if let cached = shellCache.object(forKey: key) { return cached }

        if let assetName = assetNameOverride ?? shellAssetName(width: width, grabberName: grabberName, grabberX: grabberX, grabberY: grabberY),
           let baked = UIImage(named: assetName) {

            shellCache.setObject(baked, forKey: key)
            return baked
        }

        let cleanGrabberName: String
        switch grabberName {
        case "kb-accented-right-grabber": cleanGrabberName = "kb-accented-right-grabber-composite"
        case "kb-accented-left-grabber": cleanGrabberName = "kb-accented-left-grabber-composite"
        default: cleanGrabberName = "kb-accented-mid-grabber-composite"
        }
        guard let tube = exact1xImage(named: "kb-accented-tube"),
              let grabber = exact1xImage(named: cleanGrabberName) ?? exact1xImage(named: grabberName) else { return nil }

        let logicalSize = CGSize(width: width, height: 122)
        UIGraphicsBeginImageContextWithOptions(logicalSize, false, 1.0)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        ctx.interpolationQuality = .high
        ctx.setShouldAntialias(true)

        guard let tubeCG = tube.cgImage else {
            UIGraphicsEndImageContext()
            return nil
        }

        let sourceScale = CGFloat(tubeCG.width) / 56.0
        func cropTube(x: CGFloat, width cropWidth: CGFloat) -> UIImage? {
            let pxRect = CGRect(
                x: x * sourceScale,
                y: 0,
                width: cropWidth * sourceScale,
                height: CGFloat(tubeCG.height)
            ).integral
            guard let cropped = tubeCG.cropping(to: pxRect) else { return nil }
            return UIImage(cgImage: cropped, scale: sourceScale, orientation: .up)
        }

        guard let leftCap = cropTube(x: 0, width: 22),
              let centerStrip = cropTube(x: 22, width: 12),
              let rightCap = cropTube(x: 34, width: 22) else {
            UIGraphicsEndImageContext()
            return nil
        }

        let centerWidth = max(0, width - 44)
        leftCap.draw(in: CGRect(x: 0, y: 5, width: 22, height: 75))
        if centerWidth > 0 {
            centerStrip.draw(in: CGRect(x: 22, y: 5, width: centerWidth, height: 75))
        }
        rightCap.draw(in: CGRect(x: width - 22, y: 5, width: 22, height: 75))

        grabber.draw(in: CGRect(x: grabberX, y: grabberY, width: 100, height: 70))

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let result { shellCache.setObject(result, forKey: key) }
        return result
    }

    override func draw(_ rect: CGRect) {
        guard let composite = Self.logicalComposite(
            width: logicalWidth,
            grabberName: grabberName,
            grabberX: grabberX,
            grabberY: grabberY,
            assetNameOverride: assetNameOverride
        ) else { return }

        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.interpolationQuality = .high
        context.setShouldAntialias(true)

        composite.draw(in: bounds)
        context.restoreGState()
    }
}
