import SwiftUI

struct QuizActiveView: View {
    @ObservedObject var controller: QuizRushController

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ScorePanel(title: "Marks", value: "\(controller.score)", tint: .orange)
                ScorePanel(title: "Per Q", value: "+10 / -10", tint: .red)
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
        .offset(x: controller.screenShake ? -8 : 0)
        .animation(.default.repeatCount(3, autoreverses: true), value: controller.screenShake)
    }
}
