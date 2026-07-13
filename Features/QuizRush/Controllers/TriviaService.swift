import Foundation

struct TriviaService {
    func fetchQuestions() async throws -> [QuizQuestionRound] {
        let url = URL(string: "https://opentdb.com/api.php?amount=10&type=multiple")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let triviaResponse = try JSONDecoder().decode(TriviaResponse.self, from: data)

        guard !triviaResponse.results.isEmpty else {
            throw URLError(.zeroByteResource)
        }

        return triviaResponse.results.map { question in
            QuizQuestionRound(
                prompt: question.decodedQuestion,
                correctAnswer: question.decodedCorrectAnswer,
                answers: question.shuffledAnswers
            )
        }
    }
}
