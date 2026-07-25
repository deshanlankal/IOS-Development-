import SwiftUI

struct QuizRushView: View {
    let returnToMenu: () -> Void
    let onComplete: (Int) -> Void

    @StateObject private var controller = QuizRushController()
    @State private var hasReportedResult = false

    var body: some View {
        VStack(spacing: 18) {
            GameTopBar(title: "QUIZ RUSH", icon: "flame.fill", tint: .orange, returnToMenu: returnToMenu)

            switch controller.state {
            case .loading:
                QuizLoadingView()
            case .active:
                QuizActiveView(controller: controller)
            case .finished:
                GameOverView(title: "QUIZ COMPLETE", score: controller.score, highScore: controller.highScore, playAgain: startRound, returnToMenu: returnToMenu)
            case .failed(let message):
                QuizErrorView(message: message, retry: controller.startRound)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .task {
            if controller.questions.isEmpty {
                await controller.loadRound()
            }
        }
        .onChange(of: controller.state) { _, state in
            switch state {
            case .loading:
                hasReportedResult = false
            case .finished:
                guard !hasReportedResult else { return }
                hasReportedResult = true
                onComplete(controller.score)
            case .active, .failed:
                break
            }
        }
    }

    private func startRound() {
        hasReportedResult = false
        controller.startRound()
    }
}
