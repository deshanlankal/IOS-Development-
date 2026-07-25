import SwiftUI

struct SpacerLayout<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            content
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
