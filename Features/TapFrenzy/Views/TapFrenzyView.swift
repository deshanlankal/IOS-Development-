import SwiftUI
import Combine

struct TapFrenzyView: View {
    let returnToMenu: () -> Void

    @StateObject private var controller = TapFrenzyController()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var tapButtonSize: CGFloat {
        controller.round.buttonSize(for: controller.remainingTime)
    }

    var body: some View {
        VStack(spacing: 24) {
            GameTopBar(title: "TAP FRENZY", icon: "bolt.fill", tint: controller.isBonusBurstActive ? .yellow : .cyan, returnToMenu: returnToMenu)

            if controller.isGameOver {
                GameOverView(title: "GAME OVER", score: controller.score, highScore: controller.highScore, playAgain: controller.resetGame, returnToMenu: returnToMenu)
            } else {
                gameContent
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .onReceive(timer) { _ in
            controller.tick()
        }
        .onAppear(perform: controller.resetGame)
    }

    private var gameContent: some View {
        VStack(spacing: 20) {
            HStack(spacing: 14) {
                ScorePanel(title: "Score", value: "\(controller.score)", tint: .cyan)
                ScorePanel(title: "Time", value: "\(controller.remainingTime)s", tint: controller.remainingTime <= 3 ? .orange : .mint)
            }

            Text(controller.isBonusBurstActive ? "DOUBLE POINTS" : "TAP AS FAST AS YOU CAN")
                .font(.system(size: 15, weight: .black, design: .monospaced))
                .foregroundStyle(controller.isBonusBurstActive ? .yellow : .cyan)
                .frame(height: 26)

            Spacer(minLength: 18)

            Button(action: controller.tap) {
                Text("TAP")
                    .font(.system(size: min(44, tapButtonSize * 0.28), weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(width: tapButtonSize, height: tapButtonSize)
                    .background(
                        Circle()
                            .fill(controller.isBonusBurstActive ? .yellow : .cyan)
                            .shadow(color: controller.isBonusBurstActive ? .yellow.opacity(0.8) : .cyan.opacity(0.7), radius: 24)
                    )
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.9), lineWidth: 3)
                    )
            }
            .buttonStyle(.plain)
            .disabled(controller.isGameOver)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: tapButtonSize)
            .animation(.easeInOut(duration: 0.2), value: controller.isBonusBurstActive)

            Spacer(minLength: 18)

            Text("Button shrinks as the timer falls. Bonus burst gives +2 per tap.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
        }
    }
}
