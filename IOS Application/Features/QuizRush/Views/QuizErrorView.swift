import SwiftUI

struct QuizErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        SpacerLayout {
            Image(systemName: "wifi.slash")
                .font(.system(size: 54, weight: .black))
                .foregroundStyle(.orange)
                .shadow(color: .orange.opacity(0.75), radius: 18)

            Text("Offline Warning")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(message)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.68))
                .multilineTextAlignment(.center)

            Button(action: retry) {
                Text("Retry")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: 260, minHeight: 56)
                    .background(.orange, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }
}
