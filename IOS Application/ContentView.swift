//
//  ContentView.swift
//  IOS Application
//
//  Created by Deshan Lanka on 2026-07-01.
//

import SwiftUI

struct ContentView: View {
    @State private var screen: GameScreen = .menu

    var body: some View {
        ZStack {
            SpaceBackground()

            switch screen {
            case .menu:
                MainMenuView {
                    screen = .tapFrenzy
                }
            case .tapFrenzy:
                TapFrenzyView {
                    screen = .menu
                }
            }
        }
    }
}

private enum GameScreen {
    case menu
    case tapFrenzy
}

private struct MainMenuView: View {
    let startGame: () -> Void

    private let menuOptions = [
        GameMenuOption(title: "Start Mission", icon: "play.fill", tint: Color.cyan, action: .startGame),
        GameMenuOption(title: "Ship Hangar", icon: "airplane", tint: Color.mint, action: .locked),
        GameMenuOption(title: "Galaxy Settings", icon: "gearshape.fill", tint: Color.orange, action: .locked)
    ]

    var body: some View {
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
                        if option.action == .startGame {
                            startGame()
                        }
                    } label: {
                        MenuOptionRow(option: option)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 38)
        }
        .padding(.horizontal, 24)
    }
}

private struct MenuOptionRow: View {
    let option: GameMenuOption

    var body: some View {
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
}

private struct TapFrenzyView: View {
    let returnToMenu: () -> Void

    @AppStorage("tapFrenzyHighScore") private var highScore = 0
    @State private var score = 0
    @State private var remainingTime = 10
    @State private var isGameOver = false

    private let roundLength = 10
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var isBonusBurstActive: Bool {
        remainingTime == 5 || remainingTime == 4
    }

    private var tapButtonSize: CGFloat {
        let progress = CGFloat(remainingTime) / CGFloat(roundLength)
        return 86 + (progress * 164)
    }

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button {
                    returnToMenu()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Spacer()

                Text("TAP FRENZY")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: "bolt.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(isBonusBurstActive ? .yellow : .cyan)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
            }

            if isGameOver {
                GameOverView(score: score, highScore: highScore, playAgain: resetGame, returnToMenu: returnToMenu)
            } else {
                VStack(spacing: 20) {
                    HStack(spacing: 14) {
                        ScorePanel(title: "Score", value: "\(score)", tint: .cyan)
                        ScorePanel(title: "Time", value: "\(remainingTime)s", tint: remainingTime <= 3 ? .orange : .mint)
                    }

                    Text(isBonusBurstActive ? "DOUBLE POINTS" : "TAP AS FAST AS YOU CAN")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundStyle(isBonusBurstActive ? .yellow : .cyan)
                        .frame(height: 26)

                    Spacer(minLength: 18)

                    Button {
                        score += isBonusBurstActive ? 2 : 1
                    } label: {
                        Text("TAP")
                            .font(.system(size: min(44, tapButtonSize * 0.28), weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(width: tapButtonSize, height: tapButtonSize)
                            .background(
                                Circle()
                                    .fill(isBonusBurstActive ? .yellow : .cyan)
                                    .shadow(color: isBonusBurstActive ? .yellow.opacity(0.8) : .cyan.opacity(0.7), radius: 24)
                            )
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.9), lineWidth: 3)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isGameOver)
                    .animation(.spring(response: 0.25, dampingFraction: 0.75), value: tapButtonSize)
                    .animation(.easeInOut(duration: 0.2), value: isBonusBurstActive)

                    Spacer(minLength: 18)

                    Text("Button shrinks as the timer falls. Bonus burst gives +2 per tap.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .onReceive(timer) { _ in
            guard !isGameOver else { return }

            if remainingTime > 1 {
                remainingTime -= 1
            } else {
                remainingTime = 0
                finishGame()
            }
        }
        .onAppear(perform: resetGame)
    }

    private func finishGame() {
        isGameOver = true
        highScore = max(highScore, score)
    }

    private func resetGame() {
        score = 0
        remainingTime = roundLength
        isGameOver = false
    }
}

private struct ScorePanel: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(tint.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

private struct GameOverView: View {
    let score: Int
    let highScore: Int
    let playAgain: () -> Void
    let returnToMenu: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.yellow)
                    .shadow(color: .yellow.opacity(0.7), radius: 16)

                Text("GAME OVER")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Final Score: \(score)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.cyan)

                Text("High Score: \(highScore)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }

            VStack(spacing: 14) {
                Button(action: playAgain) {
                    Text("Play Again")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: 300, minHeight: 58)
                        .background(.cyan, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button(action: returnToMenu) {
                    Text("Main Menu")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: 300, minHeight: 54)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }
}

private struct GameMenuOption: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let tint: Color
    let action: MenuAction
}

private enum MenuAction {
    case startGame
    case locked
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
