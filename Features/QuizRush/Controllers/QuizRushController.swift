import SwiftUI
import Combine

@MainActor
final class QuizRushController: ObservableObject {
    @Published var state: QuizRushState = .setup
    @Published var questions: [QuizQuestionRound] = []
    @Published var currentQuestionIndex = 0
    @Published var score = 0
    @Published var streak = 0
    @Published var correctAnswers = 0
    @Published var wrongAnswers = 0
    @Published var selectedAnswer: String?
    @Published var answerWasCorrect: Bool?
    @Published var selectedCategory = TriviaCategory.all[0]
    @Published var selectedDifficulty = TriviaDifficulty.any
    @Published private(set) var highScore = UserDefaults.standard.integer(forKey: "quizRushHighScore")

    private let service = TriviaService()
    let correctAnswerMarks = 1
    let wrongAnswerMarks = 0

    var currentQuestion: QuizQuestionRound? {
        guard questions.indices.contains(currentQuestionIndex) else { return nil }
        return questions[currentQuestionIndex]
    }

    var questionProgressText: String {
        "Question \(min(currentQuestionIndex + 1, questions.count)) of \(questions.count)"
    }

    var marksText: String {
        "\(score) / \(questions.count)"
    }

    var answerFeedbackText: String {
        guard let answerWasCorrect else {
            return "Choose one answer. Correct answers give 1 mark."
        }

        if answerWasCorrect {
            return "Correct: +1 mark"
        }

        guard let currentQuestion else {
            return "Wrong: +0 marks"
        }

        return "Wrong: +0 marks. Correct answer: \(currentQuestion.correctAnswer)"
    }

    func startRound() {
        Task {
            await loadRound()
        }
    }

    func showSetup() {
        state = .setup
        questions = []
        currentQuestionIndex = 0
        score = 0
        streak = 0
        correctAnswers = 0
        wrongAnswers = 0
        selectedAnswer = nil
        answerWasCorrect = nil
    }

    func loadRound() async {
        state = .loading
        questions = []
        currentQuestionIndex = 0
        score = 0
        streak = 0
        correctAnswers = 0
        wrongAnswers = 0
        selectedAnswer = nil
        answerWasCorrect = nil

        do {
            questions = try await service.fetchQuestions(category: selectedCategory, difficulty: selectedDifficulty)
            state = .active
        } catch {
            state = .failed("Could not download trivia. Connect to the internet and try again.")
        }
    }

    func chooseAnswer(_ answer: String) {
        guard state == .active, selectedAnswer == nil, let question = currentQuestion else { return }

        let isCorrect = answer == question.correctAnswer
        selectedAnswer = answer
        answerWasCorrect = isCorrect

        if isCorrect {
            score += correctAnswerMarks
            correctAnswers += 1
            streak += 1
        } else {
            wrongAnswers += 1
            streak = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) { [weak self] in
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
