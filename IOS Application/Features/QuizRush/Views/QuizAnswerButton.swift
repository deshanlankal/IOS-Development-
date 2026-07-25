import SwiftUI

struct QuizAnswerButton: View {
    let answer: String
    let selectedAnswer: String?
    let correctAnswer: String
    let action: () -> Void

    private var tint: Color {
        guard let selectedAnswer else { return .orange }

        if answer == correctAnswer {
            return .green
        }

        if answer == selectedAnswer {
            return .red
        }

        return .orange.opacity(0.45)
    }

    var body: some View {
        Button(action: action) {
            Text(answer)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, minHeight: 54)
                .padding(.horizontal, 14)
                .background(tint.opacity(selectedAnswer == nil ? 0.16 : 0.28), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(tint.opacity(0.85), lineWidth: 1)
                )
                .shadow(color: tint.opacity(selectedAnswer == nil ? 0.18 : 0.38), radius: 12)
        }
        .buttonStyle(.plain)
        .disabled(selectedAnswer != nil)
    }
}
