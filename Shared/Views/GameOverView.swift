import SwiftUI

struct GameOverView: View {
    let title: String
    let score: Int
    let highScore: Int
    let playAgain: () -> Void
    let returnToMenu: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.yellow)
                    .shadow(color: .yellow.opacity(0.7), radius: 16)

                Text(title)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Final Score: \(score)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.cyan)

                Text("High Score: \(highScore)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }

            VStack(spacing: 14) {
                Button(action: playAgain) {
                    Text("Play Again")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: 300, minHeight: 58)
                        .background(.cyan, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button(action: returnToMenu) {
                    Text("Main Menu")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: 300, minHeight: 54)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }
}
