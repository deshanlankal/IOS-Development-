import SwiftUI

struct QuizActiveView: View {
    @ObservedObject var controller: QuizRushController

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ScorePanel(title: "Marks", value: controller.marksText, tint: .orange)
                ScorePanel(title: "Correct", value: "\(controller.correctAnswers)", tint: .green)
            }

            HStack(spacing: 8) {
                Text(controller.questionProgressText)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(.orange)

                Spacer()

                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)

                Text("\(controller.streak)")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .frame(height: 26)

            Text(controller.answerFeedbackText)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(controller.answerWasCorrect == false ? .red : .green)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

            if let question = controller.currentQuestion {
                Text(question.prompt)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .padding(18)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.orange.opacity(0.45), lineWidth: 1)
                    )

                VStack(spacing: 12) {
                    ForEach(question.answers, id: \.self) { answer in
                        QuizAnswerButton(
                            answer: answer,
                            selectedAnswer: controller.selectedAnswer,
                            correctAnswer: question.correctAnswer,
                            action: {
                                withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                                    controller.chooseAnswer(answer)
                                }
                            }
                        )
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }
}
