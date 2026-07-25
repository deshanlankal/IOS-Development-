import SwiftUI

struct ScorePanel: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(tint.opacity(0.5), lineWidth: 1)
                )
        )
    }
}
