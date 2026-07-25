import SwiftUI

struct QuizLoadingView: View {
    var body: some View {
        SpacerLayout {
            ZStack {
                Circle()
                    .stroke(.orange.opacity(0.22), lineWidth: 8)
                    .frame(width: 126, height: 126)

                Circle()
                    .trim(from: 0.1, to: 0.82)
                    .stroke(.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 126, height: 126)
                    .rotationEffect(.degrees(28))
                    .shadow(color: .orange.opacity(0.8), radius: 18)

                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.4)
            }

            Text("Downloading trivia matrix...")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Fetching 10 live multiple-choice questions.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
        }
    }
}
