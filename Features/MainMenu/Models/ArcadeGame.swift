import SwiftUI

enum ArcadeGame: CaseIterable {
    case tapFrenzy
    case lightItUp
    case quizRush

    var title: String {
        switch self {
        case .tapFrenzy: "Tap Frenzy"
        case .lightItUp: "Light It Up"
        case .quizRush: "Quiz Rush"
        }
    }

    var subtitle: String {
        switch self {
        case .tapFrenzy: "10 seconds. One button. Pure speed."
        case .lightItUp: "Hunt glowing cards before they fade."
        case .quizRush: "Live trivia with simple marks."
        }
    }

    var icon: String {
        switch self {
        case .tapFrenzy: "hand.tap.fill"
        case .lightItUp: "lightbulb.max.fill"
        case .quizRush: "flame.fill"
        }
    }

    var tint: Color {
        switch self {
        case .tapFrenzy: .cyan
        case .lightItUp: .pink
        case .quizRush: .orange
        }
    }

    var highScoreKey: String {
        switch self {
        case .tapFrenzy: "tapFrenzyHighScore"
        case .lightItUp: "lightItUpHighScore"
        case .quizRush: "quizRushHighScore"
        }
    }
}
