import SwiftUI

struct ArcadeHubView: View {
    let startGame: (ArcadeGame) -> Void

    @AppStorage("lightItUpRoundLength") private var lightItUpRoundLength = 60
    @StateObject private var controller = ArcadeHubController()

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                header

                VStack(spacing: 14) {
                    ForEach(ArcadeGame.allCases, id: \.self) { game in
                        GameTile(
                            game: game,
                            highScore: controller.highScore(for: game),
                            isGlowing: game == .lightItUp && controller.glowPulse
                        ) {
                            startGame(game)
                        }
                    }
                }

                Spacer(minLength: 10)
            }
            .padding(.horizontal, 24)
            .padding(.top, 34)
            .sheet(isPresented: $controller.isShowingSettings) {
                SettingsSheet(roundLength: $lightItUpRoundLength)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $controller.isShowingHighScores) {
                HighScoresSheet(highScoreProvider: controller.highScore(for:))
                    .presentationDetents([.medium])
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    controller.glowPulse = true
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.cyan)

                    Text("COHNDSE251F iOS Games")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(.cyan)
                }

                Text("Select Stage")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .pink, .orange], startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(color: .cyan.opacity(0.5), radius: 14)

                Text("HIGH-SCORE ZONE")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()

            HStack(spacing: 10) {
                HeaderIconButton(icon: "trophy.fill", tint: .yellow) {
                    controller.isShowingHighScores = true
                }

                HeaderIconButton(icon: "gearshape.fill", tint: .cyan) {
                    controller.isShowingSettings = true
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.36))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.cyan.opacity(0.38), lineWidth: 1)
                )
        )
    }
}

private struct HeaderIconButton: View {
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 46, height: 46)
                .background(tint, in: RoundedRectangle(cornerRadius: 8))
                .shadow(color: tint.opacity(0.75), radius: 16)
        }
        .buttonStyle(.plain)
    }
}
