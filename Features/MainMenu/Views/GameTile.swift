import SwiftUI

struct GameTile: View {
    let game: ArcadeGame
    let highScore: Int
    let isGlowing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [game.tint.opacity(0.34), Color.black.opacity(0.78)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(alignment: .topLeading) {
                        Rectangle()
                            .fill(game.tint.opacity(0.95))
                            .frame(width: 6)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: game.icon)
                            .font(.system(size: 82, weight: .black))
                            .foregroundStyle(game.tint.opacity(0.12))
                            .offset(x: 12, y: 14)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(game.tint.opacity(isGlowing ? 1.0 : 0.62), lineWidth: isGlowing ? 2 : 1)
                    )

                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.48))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(game.tint.opacity(0.8), lineWidth: 1)
                            )

                        Image(systemName: game.icon)
                            .font(.system(size: 30, weight: .black))
                            .foregroundStyle(game.tint)
                            .shadow(color: game.tint.opacity(0.85), radius: 10)
                    }
                    .frame(width: 60, height: 60)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(game.title.uppercased())
                                .font(.system(size: 21, weight: .black, design: .rounded))
                                .foregroundStyle(game.tint)
                                .lineLimit(1)
                                .minimumScaleFactor(0.74)

                            Spacer(minLength: 6)

                            Text("BEST \(highScore)")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(game.tint, in: Capsule())
                        }

                        Text(game.subtitle)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.78))
                            .lineLimit(2)

                        HStack(spacing: 7) {
                            ForEach(0..<3, id: \.self) { index in
                                Capsule()
                                    .fill(index == 0 ? game.tint : game.tint.opacity(0.32))
                                    .frame(width: index == 0 ? 24 : 11, height: 5)
                            }

                            Spacer()

                            Image(systemName: "play.fill")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(.black)
                                .frame(width: 28, height: 28)
                                .background(game.tint, in: Circle())
                        }
                    }
                }
                .padding(18)
            }
            .frame(maxWidth: .infinity, minHeight: 126)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: game.tint.opacity(isGlowing ? 0.55 : 0.28), radius: isGlowing ? 26 : 16, y: 10)
        }
        .buttonStyle(.plain)
    }
}
