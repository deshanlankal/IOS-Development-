//
//  ContentView.swift
//  IOS Application
//
//  Created by Deshan Lanka on 2026-07-01.
//

import SwiftUI

struct ContentView: View {
    private let menuOptions = [
        GameMenuOption(title: "Start Mission", icon: "play.fill", tint: Color.cyan),
        GameMenuOption(title: "Ship Hangar", icon: "airplane", tint: Color.mint),
        GameMenuOption(title: "Galaxy Settings", icon: "gearshape.fill", tint: Color.orange)
    ]

    var body: some View {
        ZStack {
            SpaceBackground()

            VStack(spacing: 34) {
                Spacer(minLength: 28)

                VStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(.cyan)
                        .shadow(color: .cyan.opacity(0.8), radius: 12)

                    Text("NEBULA RAID")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("DEEP SPACE COMMAND")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.85))
                }

                VStack(spacing: 16) {
                    ForEach(menuOptions) { option in
                        Button {
                            print("Selected \(option.title)")
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: option.icon)
                                    .font(.system(size: 20, weight: .bold))
                                    .frame(width: 30)
                                    .foregroundStyle(option.tint)

                                Text(option.title)
                                    .font(.system(size: 19, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                            .padding(.horizontal, 20)
                            .frame(maxWidth: 330, minHeight: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.white.opacity(0.10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(option.tint.opacity(0.65), lineWidth: 1)
                                    )
                            )
                            .shadow(color: option.tint.opacity(0.24), radius: 16, y: 8)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: 38)
            }
            .padding(.horizontal, 24)
        }
    }
}

private struct GameMenuOption: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let tint: Color
}

private struct SpaceBackground: View {
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

private struct StarField: View {
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

#Preview {
    ContentView()
}
