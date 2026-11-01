#if DEBUG
import SwiftUI

struct OldOSAccentRendererHarness: View {
    private struct Sample: Identifiable {
        let id: String
        let width: CGFloat
        let grabber: String
        let grabberX: CGFloat
        let grabberY: CGFloat
        let assetOverride: String?
    }

    private let samples: [Sample] = [
        .init(id: "E top", width: 264, grabber: "kb-accented-right-grabber", grabberX: -12, grabberY: 44, assetOverride: nil),
        .init(id: "A", width: 328, grabber: "kb-accented-right-grabber", grabberX: -12, grabberY: 50, assetOverride: nil),
        .init(id: "O top", width: 328, grabber: "kb-accented-left-grabber", grabberX: 240, grabberY: 44, assetOverride: nil),
        .init(id: "$", width: 104, grabber: "kb-accented-right-grabber", grabberX: -12, grabberY: 50, assetOverride: nil),
        .init(id: "-", width: 136, grabber: "kb-accented-right-grabber", grabberX: -12, grabberY: 50, assetOverride: nil),
        .init(id: "\"", width: 232, grabber: "kb-accented-left-grabber", grabberX: 144, grabberY: 50, assetOverride: nil),
        .init(id: "0", width: 104, grabber: "kb-accented-left-grabber", grabberX: 16, grabberY: 44, assetOverride: nil),
        .init(id: ".", width: 130, grabber: "kb-accented-right-grabber", grabberX: -12, grabberY: 50, assetOverride: nil)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(samples) { sample in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sample.id).font(.caption)
                        OldOSAccentShellView(
                            width: sample.width,
                            grabberName: sample.grabber,
                            grabberX: sample.grabberX,
                            grabberY: sample.grabberY,
                            assetNameOverride: sample.assetOverride,
                            scale: 1
                        )
                        .frame(width: sample.width, height: 122)
                        .background(Color(red: 0.50, green: 0.56, blue: 0.63))
                    }
                }
            }
            .padding()
        }
        .background(Color.black)
    }
}
#endif
