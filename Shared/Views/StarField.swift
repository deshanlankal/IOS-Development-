import SwiftUI

struct StarField: View {
    private let stars: [CGPoint] = [
        CGPoint(x: 0.08, y: 0.10), CGPoint(x: 0.22, y: 0.18), CGPoint(x: 0.40, y: 0.08),
        CGPoint(x: 0.70, y: 0.14), CGPoint(x: 0.88, y: 0.09), CGPoint(x: 0.15, y: 0.34),
        CGPoint(x: 0.32, y: 0.43), CGPoint(x: 0.57, y: 0.33), CGPoint(x: 0.82, y: 0.42),
        CGPoint(x: 0.10, y: 0.66), CGPoint(x: 0.28, y: 0.78), CGPoint(x: 0.48, y: 0.62),
        CGPoint(x: 0.68, y: 0.76), CGPoint(x: 0.90, y: 0.70), CGPoint(x: 0.76, y: 0.90)
    ]

    var body: some View {
        GeometryReader { geometry in
            ForEach(stars.indices, id: \.self) { index in
                Circle()
                    .fill(index.isMultiple(of: 3) ? .cyan : .white)
                    .frame(width: index.isMultiple(of: 4) ? 4 : 2, height: index.isMultiple(of: 4) ? 4 : 2)
                    .position(
                        x: stars[index].x * geometry.size.width,
                        y: stars[index].y * geometry.size.height
                    )
                    .shadow(color: .white.opacity(0.8), radius: 4)
            }
        }
    }
}
