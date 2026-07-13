import SwiftUI

enum LightPhase: Int {
    case level1 = 1
    case level2 = 2
    case level3 = 3
    case level4 = 4

    var cardCount: Int {
        switch self {
        case .level1: 3
        case .level2: 6
        case .level3: 6
        case .level4: 9
        }
    }

    var columns: Int {
        switch self {
        case .level1: 3
        case .level2: 3
        case .level3: 3
        case .level4: 3
        }
    }

    var reactionWindow: TimeInterval {
        switch self {
        case .level1: 1.25
        case .level2: 0.95
        case .level3: 0.75
        case .level4: 0.6
        }
    }

    var litCardCount: Int {
        switch self {
        case .level1, .level2: 1
        case .level3: 2
        case .level4: 3
        }
    }

    var points: Int {
        rawValue * 15
    }

    var tint: Color {
        switch self {
        case .level1: .cyan
        case .level2: .orange
        case .level3: .pink
        case .level4: .red
        }
    }

    var caption: String {
        switch self {
        case .level1: "Soft cyan warmup. One target, less time to react."
        case .level2: "Amber 2x3 grid. Six squares arrive early."
        case .level3: "Neon pink pressure. Two cards can light at once."
        case .level4: "Electric red overload. Three cards flash at hyper-speed."
        }
    }

    static func phase(for elapsed: TimeInterval, roundLength: Int) -> LightPhase {
        let segment = max(TimeInterval(roundLength) / 4.0, 1.0)

        switch elapsed {
        case 0..<segment:
            return .level1
        case segment..<(segment * 2):
            return .level2
        case (segment * 2)..<(segment * 3):
            return .level3
        default:
            return .level4
        }
    }
}
