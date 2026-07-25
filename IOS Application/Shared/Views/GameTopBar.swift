import SwiftUI

struct GameTopBar: View {
    let title: String
    let icon: String
    let tint: Color
    let returnToMenu: () -> Void

    var body: some View {
        HStack {
            Button(action: returnToMenu) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}
