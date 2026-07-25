import SwiftUI

struct SpaceBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.03, blue: 0.09),
                    Color(red: 0.04, green: 0.10, blue: 0.18),
                    Color(red: 0.10, green: 0.03, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            StarField()
                .opacity(0.95)

            VStack(spacing: 18) {
                Spacer()

                ForEach(0..<5, id: \.self) { index in
                    Rectangle()
                        .fill(.cyan.opacity(0.08 + Double(index) * 0.025))
                        .frame(height: 1)
                        .padding(.horizontal, CGFloat(26 + index * 22))
                }
            }
            .padding(.bottom, 38)
        }
        .ignoresSafeArea()
    }
}
