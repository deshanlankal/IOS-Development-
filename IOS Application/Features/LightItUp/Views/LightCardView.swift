import SwiftUI

struct LightCardView: View {
    let isLit: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 8)
                .fill(isLit ? tint : .white.opacity(0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isLit ? .white.opacity(0.95) : .white.opacity(0.14), lineWidth: isLit ? 2 : 1)
                )
                .shadow(color: isLit ? tint.opacity(0.85) : .clear, radius: 20)
                .scaleEffect(isLit ? 1.04 : 1.0)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: isLit ? "sparkle" : "circle.grid.cross")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(isLit ? .black.opacity(0.78) : .white.opacity(0.18))
                }
        }
        .buttonStyle(.plain)
    }
}
