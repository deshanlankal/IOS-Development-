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
            case .setup:
                QuizSetupView(controller: controller)
            case .loading:
                QuizLoadingView()
            case .active:
                QuizActiveView(controller: controller)
            case .finished:
                QuizResultView(controller: controller, playAgain: startRound, returnToMenu: returnToMenu)
            case .failed(let message):
                QuizErrorView(message: message, retry: controller.startRound)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .onChange(of: controller.state) { _, state in
            switch state {
            case .loading:
                hasReportedResult = false
            case .finished:
                guard !hasReportedResult else { return }
                hasReportedResult = true
                onComplete(controller.score)
            case .setup, .active, .failed:
                break
            }
        }
    }

    private func startRound() {
        hasReportedResult = false
        controller.startRound()
    }
}

private struct QuizResultView: View {
    @ObservedObject var controller: QuizRushController
    let playAgain: () -> Void
    let returnToMenu: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.green)
                    .shadow(color: .green.opacity(0.7), radius: 16)

                Text("QUIZ COMPLETE")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Final Marks: \(controller.score) / \(controller.questions.count)")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.orange)

                Text("Correct \(controller.correctAnswers)  •  Wrong \(controller.wrongAnswers)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))

                Text("Best Marks: \(controller.highScore)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            VStack(spacing: 14) {
                Button(action: playAgain) {
                    Text("Play Again")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: 300, minHeight: 58)
                        .background(.orange, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button(action: returnToMenu) {
                    Text("Main Menu")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: 300, minHeight: 54)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }
}

private struct QuizSetupView: View {
    @ObservedObject var controller: QuizRushController

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Choose Quiz Options")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(.orange)

                    Picker("Category", selection: $controller.selectedCategory) {
                        ForEach(TriviaCategory.all) { category in
                            Text(category.title).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Difficulty")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(.orange)

                    Picker("Difficulty", selection: $controller.selectedDifficulty) {
                        ForEach(TriviaDifficulty.allCases) { difficulty in
                            Text(difficulty.title).tag(difficulty)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Button(action: controller.startRound) {
                    Label("Start Quiz", systemImage: "play.fill")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(.orange, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
        }
    }
}
