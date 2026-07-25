import Foundation

struct TriviaService {
    func fetchQuestions(category: TriviaCategory, difficulty: TriviaDifficulty) async throws -> [QuizQuestionRound] {
        var components = URLComponents(string: "https://opentdb.com/api.php")
        var queryItems = [
            URLQueryItem(name: "amount", value: "10"),
            URLQueryItem(name: "type", value: "multiple")
        ]

        if let categoryValue = category.apiValue {
            queryItems.append(URLQueryItem(name: "category", value: categoryValue))
        }

        if let difficultyValue = difficulty.apiValue {
            queryItems.append(URLQueryItem(name: "difficulty", value: difficultyValue))
        }

        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

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
