import SwiftUI
import Combine

struct LightItUpView: View {
    let returnToMenu: () -> Void
    let onComplete: (Int) -> Void

    @AppStorage("lightItUpRoundLength") private var roundLength = 60
    @StateObject private var controller = LightItUpController()
    @State private var hasReportedResult = false
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: controller.currentPhase.columns)
    }

    var body: some View {
        VStack(spacing: 18) {
            GameTopBar(title: "LIGHT IT UP", icon: "lightbulb.max.fill", tint: controller.currentPhase.tint, returnToMenu: returnToMenu)

            if controller.isGameOver {
                GameOverView(
                    title: controller.lives == 0 ? "LIGHTS OUT" : "TIME UP",
                    score: controller.score,
                    highScore: controller.highScore,
                    shareText: "Light It Up result: \(controller.score) points, reached Level \(controller.currentPhase.rawValue), best score \(controller.highScore). Try to outplay me on PlayHub.",
                    playAgain: resetRound,
                    returnToMenu: returnToMenu
                )
            } else {
                gameContent
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .overlay(alignment: .center) {
            if let levelBanner = controller.levelBanner {
                LevelUpOverlay(text: levelBanner, tint: controller.currentPhase.tint)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            resetRound()
        }
        .onReceive(timer) { now in
            let previousPhase = controller.currentPhase
            controller.updateGame(now: now)

            if previousPhase != controller.currentPhase {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        controller.clearLevelBanner()
                    }
                }
            }
        }
        .onChange(of: controller.isGameOver) { _, isGameOver in
            guard isGameOver, !hasReportedResult else { return }
            hasReportedResult = true
            onComplete(controller.score)
        }
    }

    private var gameContent: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ScorePanel(title: "Score", value: "\(controller.score)", tint: controller.currentPhase.tint)
                ScorePanel(title: "Time", value: "\(controller.remainingTime)s", tint: controller.remainingTime <= 5 ? .orange : .mint)
            }

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < controller.lives ? "heart.fill" : "heart.slash.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(index < controller.lives ? .red : .gray)
                        .shadow(color: index < controller.lives ? .red.opacity(0.75) : .clear, radius: 9)
                }

                Spacer()

                Text("LEVEL \(controller.currentPhase.rawValue)")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(controller.currentPhase.tint)
            }
            .frame(height: 28)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<controller.currentPhase.cardCount, id: \.self) { cardID in
                    LightCardView(isLit: controller.activeCards.contains(cardID), tint: controller.currentPhase.tint) {
                        controller.tapCard(cardID)
                    }
                }
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: controller.currentPhase)
            .animation(.easeInOut(duration: 0.12), value: controller.activeCards)

            Text(controller.currentPhase.caption)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)
                .frame(height: 38)
        }
    }

    private func resetRound() {
        hasReportedResult = false
        controller.resetGame(roundLength: roundLength)
    }
}
