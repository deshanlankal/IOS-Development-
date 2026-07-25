import Foundation
import UIKit

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

enum TriviaDifficulty: String, CaseIterable, Identifiable {
    case any
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .any:
            return "Mixed"
        case .easy:
            return "Easy"
        case .medium:
            return "Medium"
        case .hard:
            return "Hard"
        }
    }

    var apiValue: String? {
        self == .any ? nil : rawValue
    }
}

struct TriviaCategory: Identifiable, Hashable {
    let id: Int?
    let title: String

    var apiValue: String? {
        id.map(String.init)
    }

    static let all: [TriviaCategory] = [
        TriviaCategory(id: nil, title: "Any Category"),
        TriviaCategory(id: 9, title: "General Knowledge"),
        TriviaCategory(id: 10, title: "Books"),
        TriviaCategory(id: 11, title: "Film"),
        TriviaCategory(id: 12, title: "Music"),
        TriviaCategory(id: 14, title: "Television"),
        TriviaCategory(id: 15, title: "Video Games"),
        TriviaCategory(id: 17, title: "Science & Nature"),
        TriviaCategory(id: 18, title: "Computers"),
        TriviaCategory(id: 19, title: "Mathematics"),
        TriviaCategory(id: 21, title: "Sports"),
        TriviaCategory(id: 22, title: "Geography"),
        TriviaCategory(id: 23, title: "History"),
        TriviaCategory(id: 27, title: "Animals"),
        TriviaCategory(id: 28, title: "Vehicles")
    ]
}

enum QuizRushState: Equatable {
    case setup
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
