import Foundation

struct TriviaResponse: Codable {
    let results: [TriviaQuestion]
}

struct TriviaQuestion: Codable, Identifiable {
    let id = UUID()
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]

    enum CodingKeys: String, CodingKey {
        case question
        case correctAnswer = "correct_answer"
        case incorrectAnswers = "incorrect_answers"
    }

    var decodedQuestion: String {
        question.decodedHTML
    }

    var decodedCorrectAnswer: String {
        correctAnswer.decodedHTML
    }

    var shuffledAnswers: [String] {
        ([correctAnswer] + incorrectAnswers).map(\.decodedHTML).shuffled()
    }
}

struct QuizQuestionRound: Identifiable {
    let id = UUID()
    let prompt: String
    let correctAnswer: String
    let answers: [String]
}

enum QuizRushState: Equatable {
    case loading
    case active
    case finished
    case failed(String)
}

extension String {
    var decodedHTML: String {
        guard let data = data(using: .utf8) else { return self }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        return (try? NSAttributedString(data: data, options: options, documentAttributes: nil).string) ?? self
    }
}
