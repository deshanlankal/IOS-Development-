import Foundation
import Combine

final class TapFrenzyController: ObservableObject {
    @Published var score = 0
    @Published var remainingTime = 10
    @Published var isGameOver = false
    @Published private(set) var highScore = UserDefaults.standard.integer(forKey: "tapFrenzyHighScore")

    let round = TapFrenzyRound()
    private var roundEndDate = Date()

    var isBonusBurstActive: Bool {
        round.isBonusBurstActive(remainingTime: remainingTime)
    }

    func tap() {
        guard !isGameOver else { return }
        score += isBonusBurstActive ? 2 : 1
    }

    func updateTimer(now: Date) {
        guard !isGameOver else { return }

        let secondsLeft = Int(ceil(roundEndDate.timeIntervalSince(now)))
        if secondsLeft > 0 {
            remainingTime = min(round.roundLength, secondsLeft)
        } else {
            remainingTime = 0
            finishGame()
        }
    }

    func resetGame() {
        score = 0
        remainingTime = round.roundLength
        isGameOver = false
        roundEndDate = Date().addingTimeInterval(TimeInterval(round.roundLength))
    }

    private func finishGame() {
        isGameOver = true
        highScore = max(highScore, score)
        UserDefaults.standard.set(highScore, forKey: "tapFrenzyHighScore")
    }
}
