import Foundation

final class LightItUpController: ObservableObject {
    @Published var score = 0
    @Published var lives = 3
    @Published var remainingTime = 60
    @Published var isGameOver = false
    @Published var activeCards: Set<Int> = []
    @Published var currentPhase = LightPhase.level1
    @Published var levelBanner: String?
    @Published var boardShake = false
    @Published private(set) var highScore = UserDefaults.standard.integer(forKey: "lightItUpHighScore")

    private var litDeadline = Date()
    private var nextSpawnTime = Date()
    private var roundStartTime = Date()
    private var roundLength = 60

    func updateGame(now: Date) {
        guard !isGameOver else { return }

        let elapsed = now.timeIntervalSince(roundStartTime)
        remainingTime = max(0, roundLength - Int(elapsed.rounded(.down)))

        if remainingTime <= 0 {
            finishGame()
            return
        }

        let nextPhase = LightPhase.phase(for: elapsed, roundLength: roundLength)
        if nextPhase != currentPhase {
            currentPhase = nextPhase
            activeCards = []
            levelBanner = "LEVEL \(nextPhase.rawValue): SPEED UP"
            nextSpawnTime = now.addingTimeInterval(0.35)
        }

        if !activeCards.isEmpty && now >= litDeadline {
            loseLife()
            activeCards = []
            nextSpawnTime = now.addingTimeInterval(0.25)
        }

        if activeCards.isEmpty && now >= nextSpawnTime {
            spawnCards(now: now)
        }
    }

    func tapCard(_ cardID: Int) {
        guard !isGameOver else { return }

        if activeCards.contains(cardID) {
            score += currentPhase.points
            activeCards.remove(cardID)

            if activeCards.isEmpty {
                nextSpawnTime = Date().addingTimeInterval(0.18)
            }
        } else {
            loseLife()
        }
    }

    func clearLevelBanner() {
        levelBanner = nil
    }

    func resetGame(roundLength: Int) {
        self.roundLength = roundLength
        score = 0
        lives = 3
        remainingTime = roundLength
        isGameOver = false
        activeCards = []
        currentPhase = .level1
        levelBanner = nil
        roundStartTime = Date()
        nextSpawnTime = Date().addingTimeInterval(0.45)
        litDeadline = Date()
    }

    private func spawnCards(now: Date) {
        let cardCount = currentPhase.cardCount
        let lightCount = min(currentPhase.litCardCount, cardCount)
        activeCards = Set((0..<cardCount).shuffled().prefix(lightCount))
        litDeadline = now.addingTimeInterval(currentPhase.reactionWindow)
    }

    private func loseLife() {
        guard lives > 0 else { return }

        lives -= 1
        boardShake.toggle()

        if lives == 0 {
            finishGame()
        }
    }

    private func finishGame() {
        isGameOver = true
        activeCards = []
        highScore = max(highScore, score)
        UserDefaults.standard.set(highScore, forKey: "lightItUpHighScore")
    }
}
