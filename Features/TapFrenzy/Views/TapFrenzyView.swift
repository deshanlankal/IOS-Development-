import SwiftUI
import Combine

struct TapFrenzyView: View {
    let returnToMenu: () -> Void
    let onComplete: (Int) -> Void

    @StateObject private var controller = TapFrenzyController()
    @State private var hasReportedResult = false
    @State private var tapButtonAnchor = CGPoint(x: 0.5, y: 0.5)
    @State private var lastMovedSecond = 10
    private let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()

    private var tapButtonSize: CGFloat {
        controller.round.buttonSize(for: controller.remainingTime)
    }

    var body: some View {
        VStack(spacing: 24) {
            GameTopBar(title: "TAP FRENZY", icon: "bolt.fill", tint: controller.isBonusBurstActive ? .yellow : .cyan, returnToMenu: returnToMenu)

            if controller.isGameOver {
                GameOverView(
                    title: "GAME OVER",
                    score: controller.score,
                    highScore: controller.highScore,
                    shareText: "Tap Frenzy result: \(controller.score) taps in 10 seconds. Best run: \(controller.highScore). Think you can beat me on PlayHub?",
                    playAgain: resetRound,
                    returnToMenu: returnToMenu
                )
            } else {
                gameContent
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .onReceive(timer) { now in
            let previousTime = controller.remainingTime
            controller.updateTimer(now: now)
            moveTapButtonIfNeeded(previousTime: previousTime)
        }
        .onAppear {
            resetRound()
        }
        .onChange(of: controller.isGameOver) { _, isGameOver in
            guard isGameOver, !hasReportedResult else { return }
            hasReportedResult = true
            onComplete(controller.score)
        }
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

            movingTapArea
                .frame(maxWidth: .infinity)
                .frame(height: 320)

            Spacer(minLength: 18)

            Text("Button moves during the round. Bonus burst gives +2 per tap.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
        }
    }

    private var movingTapArea: some View {
        GeometryReader { geometry in
            let availableWidth = max(geometry.size.width - tapButtonSize, 1)
            let availableHeight = max(geometry.size.height - tapButtonSize, 1)
            let xPosition = tapButtonSize / 2 + availableWidth * tapButtonAnchor.x
            let yPosition = tapButtonSize / 2 + availableHeight * tapButtonAnchor.y

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.cyan.opacity(0.22), lineWidth: 1)
                    )

                Button {
                    controller.tap()
                    moveTapButton()
                } label: {
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
                .position(x: xPosition, y: yPosition)
                .animation(.spring(response: 0.28, dampingFraction: 0.78), value: tapButtonAnchor)
                .animation(.spring(response: 0.25, dampingFraction: 0.75), value: tapButtonSize)
                .animation(.easeInOut(duration: 0.2), value: controller.isBonusBurstActive)
            }
        }
    }

    private func resetRound() {
        hasReportedResult = false
        tapButtonAnchor = CGPoint(x: 0.5, y: 0.5)
        lastMovedSecond = controller.round.roundLength
        controller.resetGame()
    }

    private func moveTapButtonIfNeeded(previousTime: Int) {
        guard controller.remainingTime != previousTime,
              controller.remainingTime > 0,
              controller.remainingTime.isMultiple(of: 2),
              controller.remainingTime != lastMovedSecond else {
            return
        }

        lastMovedSecond = controller.remainingTime
        moveTapButton()
    }

    private func moveTapButton() {
        tapButtonAnchor = CGPoint(
            x: CGFloat.random(in: 0.05...0.95),
            y: CGFloat.random(in: 0.05...0.95)
        )
    }
}
