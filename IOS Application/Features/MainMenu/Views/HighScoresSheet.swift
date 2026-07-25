import SwiftUI

struct HighScoresSheet: View {
    let highScoreProvider: (ArcadeGame) -> Int

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.04, blue: 0.10)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(.yellow)
                        .shadow(color: .yellow.opacity(0.8), radius: 14)

                    Text("High Scores")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 12) {
                    ForEach(ArcadeGame.allCases, id: \.self) { game in
                        HighScoreRow(game: game, score: highScoreProvider(game))
                    }
                }

                Spacer()
            }
            .padding(24)
        }
    }
}

private struct HighScoreRow: View {
    let game: ArcadeGame
    let score: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: game.icon)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(game.tint)
                .frame(width: 48, height: 48)
                .background(game.tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 8))
                .shadow(color: game.tint.opacity(0.5), radius: 10)

            Text(game.title)
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Text("\(score)")
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundStyle(game.tint)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.36))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(game.tint.opacity(0.45), lineWidth: 1)
                )
        )
    }
}
