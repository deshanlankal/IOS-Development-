import SwiftUI

struct LevelUpOverlay: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(size: 26, weight: .black, design: .rounded))
            .foregroundStyle(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(tint, in: RoundedRectangle(cornerRadius: 8))
            .shadow(color: tint.opacity(0.85), radius: 28)
            .padding(.horizontal, 24)
    }
}
