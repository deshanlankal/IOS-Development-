import Foundation
import Combine

final class ArcadeHubController: ObservableObject {
    @Published var isShowingSettings = false
    @Published var isShowingHighScores = false
    @Published var glowPulse = false

    func highScore(for game: ArcadeGame) -> Int {
        UserDefaults.standard.integer(forKey: game.highScoreKey)
    }
}
