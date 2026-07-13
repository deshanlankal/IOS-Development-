import SwiftUI

@MainActor
final class QuizRushController: ObservableObject {
    @Published var state: QuizRushState = .loading
    @Published var questions: [QuizQuestionRound] = []
    @Published var currentQuestionIndex = 0
    @Published var score = 0
    @Published var streak = 0
    @Published var selectedAnswer: String?
    @Published var answerWasCorrect: Bool?
    @Published var screenShake = false
    @Published private(set) var highScore = UserDefaults.standard.integer(forKey: "quizRushHighScore")

    private let service = TriviaService()
    let correctAnswerMarks = 10
    let wrongAnswerPenalty = 10

    var currentQuestion: QuizQuestionRound? {
        guard questions.indices.contains(currentQuestionIndex) else { return nil }
        return questions[currentQuestionIndex]
    }

    var questionProgressText: String {
        "Question \(min(currentQuestionIndex + 1, questions.count)) of \(questions.count)"
    }

    func startRound() {
        Task {
            await loadRound()
        }
    }

    func loadRound() async {
        state = .loading
        questions = []
        currentQuestionIndex = 0
        score = 0
        streak = 0
        selectedAnswer = nil
        answerWasCorrect = nil

        do {
            questions = try await service.fetchQuestions()
            state = .active
        } catch {
            state = .failed("Could not download trivia. Check your connection and try again.")
        }
    }

    func chooseAnswer(_ answer: String) {
        guard state == .active, selectedAnswer == nil, let question = currentQuestion else { return }

        let isCorrect = answer == question.correctAnswer
        selectedAnswer = answer
        answerWasCorrect = isCorrect

        if isCorrect {
            score += correctAnswerMarks
            streak += 1
        } else {
            streak = 0
            score -= wrongAnswerPenalty
            screenShake.toggle()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
            self?.advanceQuestion()
        }
    }

    private func advanceQuestion() {
        selectedAnswer = nil
        answerWasCorrect = nil

        if currentQuestionIndex + 1 < questions.count {
            withAnimation(.easeInOut(duration: 0.18)) {
                currentQuestionIndex += 1
            }
        } else {
            highScore = max(highScore, score)
            UserDefaults.standard.set(highScore, forKey: "quizRushHighScore")
            state = .finished
        }
    }
}
