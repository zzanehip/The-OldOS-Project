import SwiftUI

public struct OldOSKeyboardDemo: View {
    @StateObject private var keyboard = OldOSKeyboardController()
    @State private var text = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 18) {
            Text("iOS 4.3 keyboard test")
                .font(.headline)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gray)
                OldOSTextField(
                    "Search iPhone",
                    text: $text,
                    configuration: OldOSKeyboardConfiguration.search
                )
            }
            .padding(.horizontal, 10)
            .frame(height: 31)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 15.5))
            .overlay(RoundedRectangle(cornerRadius: 15.5).stroke(Color.gray.opacity(0.55)))
            .padding(.horizontal)

            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

            Spacer()
        }
        .oldOSKeyboardHost(keyboard)
        .ignoresSafeArea(.keyboard)
    }
}
