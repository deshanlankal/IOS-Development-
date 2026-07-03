//
//  ContentView.swift
//  IOS Application
//
//  Created by Deshan Lanka on 2026-07-01.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var activeGame: ArcadeGame?

    var body: some View {
        ZStack {
            SpaceBackground()

            switch activeGame {
            case .tapFrenzy:
                TapFrenzyView {
                    activeGame = nil
                }
            case .lightItUp:
                LightItUpView {
                    activeGame = nil
                }
            case .quizRush:
                QuizRushView {
                    activeGame = nil
                }
            case nil:
                ArcadeHubView { game in
                    activeGame = game
                }
            }
        }
    }
}

private enum ArcadeGame {
    case tapFrenzy
    case lightItUp
    case quizRush
}

private struct ArcadeHubView: View {
    let startGame: (ArcadeGame) -> Void

    @AppStorage("tapFrenzyHighScore") private var tapFrenzyHighScore = 0
    @AppStorage("lightItUpHighScore") private var lightItUpHighScore = 0
    @AppStorage("quizRushHighScore") private var quizRushHighScore = 0
    @AppStorage("lightItUpRoundLength") private var lightItUpRoundLength = 60
    @State private var isShowingSettings = false
    @State private var glowPulse = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(.cyan)

                            Text("NEON ARCADE")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundStyle(.cyan)
                        }

                        Text("Select Stage")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [.cyan, .pink, .orange], startPoint: .leading, endPoint: .trailing)
                            )
                            .shadow(color: .cyan.opacity(0.5), radius: 14)

                        Text("HIGH-SCORE ZONE")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.58))
                    }

                    Spacer()

                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 46, height: 46)
                            .background(.cyan, in: RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .cyan.opacity(0.75), radius: 16)
                    }
                    .buttonStyle(.plain)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.36))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.cyan.opacity(0.38), lineWidth: 1)
                        )
                )

                VStack(spacing: 14) {
                    GameTile(
                        title: "Tap Frenzy",
                        subtitle: "10 seconds. One button. Pure speed.",
                        icon: "hand.tap.fill",
                        tint: .cyan,
                        highScore: tapFrenzyHighScore,
                        isGlowing: false
                    ) {
                        startGame(.tapFrenzy)
                    }

                    GameTile(
                        title: "Light It Up",
                        subtitle: "Hunt glowing cards before they fade.",
                        icon: "lightbulb.max.fill",
                        tint: .pink,
                        highScore: lightItUpHighScore,
                        isGlowing: glowPulse
                    ) {
                        startGame(.lightItUp)
                    }

                    GameTile(
                        title: "Quiz Rush",
                        subtitle: "Live trivia with streak multipliers.",
                        icon: "flame.fill",
                        tint: .orange,
                        highScore: quizRushHighScore,
                        isGlowing: false
                    ) {
                        startGame(.quizRush)
                    }
                }

                Spacer(minLength: 10)
            }
            .padding(.horizontal, 24)
            .padding(.top, 34)
            .sheet(isPresented: $isShowingSettings) {
                SettingsSheet(roundLength: $lightItUpRoundLength)
                    .presentationDetents([.medium])
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }
        }
    }
}

private struct GameTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let highScore: Int
    let isGlowing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.34), Color.black.opacity(0.78)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(alignment: .topLeading) {
                        Rectangle()
                            .fill(tint.opacity(0.95))
                            .frame(width: 6)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: icon)
                            .font(.system(size: 82, weight: .black))
                            .foregroundStyle(tint.opacity(0.12))
                            .offset(x: 12, y: 14)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(tint.opacity(isGlowing ? 1.0 : 0.62), lineWidth: isGlowing ? 2 : 1)
                    )

                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.48))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(tint.opacity(0.8), lineWidth: 1)
                            )

                        Image(systemName: icon)
                            .font(.system(size: 30, weight: .black))
                            .foregroundStyle(tint)
                            .shadow(color: tint.opacity(0.85), radius: 10)
                    }
                    .frame(width: 60, height: 60)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(title.uppercased())
                                .font(.system(size: 21, weight: .black, design: .rounded))
                                .foregroundStyle(tint)
                                .lineLimit(1)
                                .minimumScaleFactor(0.74)

                            Spacer(minLength: 6)

                            Text("BEST \(highScore)")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(tint, in: Capsule())
                        }

                        Text(subtitle)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.78))
                            .lineLimit(2)

                        HStack(spacing: 7) {
                            ForEach(0..<3, id: \.self) { index in
                                Capsule()
                                    .fill(index == 0 ? tint : tint.opacity(0.32))
                                    .frame(width: index == 0 ? 24 : 11, height: 5)
                            }

                            Spacer()

                            Image(systemName: "play.fill")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(.black)
                                .frame(width: 28, height: 28)
                                .background(tint, in: Circle())
                        }
                    }
                }
                .padding(18)
            }
            .frame(maxWidth: .infinity, minHeight: 126)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: tint.opacity(isGlowing ? 0.55 : 0.28), radius: isGlowing ? 26 : 16, y: 10)
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsSheet: View {
    @Binding var roundLength: Int

    private let options = [30, 60, 90]

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.04, blue: 0.10)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                Text("Settings")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Light It Up Round")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(.cyan)

                Picker("Round Length", selection: $roundLength) {
                    ForEach(options, id: \.self) { option in
                        Text("\(option)s").tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Text("Shorter rounds ramp faster. Longer rounds keep the final level running longer.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))

                Spacer()
            }
            .padding(24)
        }
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
            GameTopBar(title: "TAP FRENZY", icon: "bolt.fill", tint: isBonusBurstActive ? .yellow : .cyan, returnToMenu: returnToMenu)

            if isGameOver {
                GameOverView(title: "GAME OVER", score: score, highScore: highScore, playAgain: resetGame, returnToMenu: returnToMenu)
            } else {
                gameContent
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

    private var gameContent: some View {
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

private struct LightItUpView: View {
    let returnToMenu: () -> Void

    @AppStorage("lightItUpHighScore") private var highScore = 0
    @AppStorage("lightItUpRoundLength") private var roundLength = 60
    @State private var score = 0
    @State private var lives = 3
    @State private var remainingTime = 60
    @State private var isGameOver = false
    @State private var activeCards: Set<Int> = []
    @State private var litDeadline = Date()
    @State private var nextSpawnTime = Date()
    @State private var roundStartTime = Date()
    @State private var currentPhase = LightPhase.level1
    @State private var levelBanner: String?
    @State private var boardShake = false

    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: currentPhase.columns)
    }

    var body: some View {
        VStack(spacing: 18) {
            GameTopBar(title: "LIGHT IT UP", icon: "lightbulb.max.fill", tint: currentPhase.tint, returnToMenu: returnToMenu)

            if isGameOver {
                GameOverView(title: lives == 0 ? "LIGHTS OUT" : "TIME UP", score: score, highScore: highScore, playAgain: resetGame, returnToMenu: returnToMenu)
            } else {
                gameContent
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .offset(x: boardShake ? -8 : 0)
        .animation(.default.repeatCount(3, autoreverses: true), value: boardShake)
        .overlay(alignment: .center) {
            if let levelBanner {
                LevelUpOverlay(text: levelBanner, tint: currentPhase.tint)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear(perform: resetGame)
        .onReceive(timer) { now in
            updateGame(now: now)
        }
    }

    private var gameContent: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ScorePanel(title: "Score", value: "\(score)", tint: currentPhase.tint)
                ScorePanel(title: "Time", value: "\(remainingTime)s", tint: remainingTime <= 5 ? .orange : .mint)
            }

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < lives ? "heart.fill" : "heart.slash.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(index < lives ? .red : .gray)
                        .shadow(color: index < lives ? .red.opacity(0.75) : .clear, radius: 9)
                }

                Spacer()

                Text("LEVEL \(currentPhase.rawValue)")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(currentPhase.tint)
            }
            .frame(height: 28)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<currentPhase.cardCount, id: \.self) { cardID in
                    LightCardView(isLit: activeCards.contains(cardID), tint: currentPhase.tint) {
                        tapCard(cardID)
                    }
                }
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: currentPhase)
            .animation(.easeInOut(duration: 0.12), value: activeCards)

            Text(currentPhase.caption)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)
                .frame(height: 38)
        }
    }

    private func updateGame(now: Date) {
        guard !isGameOver else { return }

        let elapsed = now.timeIntervalSince(roundStartTime)
        remainingTime = max(0, roundLength - Int(elapsed.rounded(.down)))

        if remainingTime <= 0 {
            finishGame()
            return
        }

        let nextPhase = LightPhase.phase(for: elapsed, roundLength: roundLength)
        if nextPhase != currentPhase {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                currentPhase = nextPhase
                activeCards = []
                levelBanner = "LEVEL \(nextPhase.rawValue): SPEED UP"
            }
            nextSpawnTime = now.addingTimeInterval(0.35)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.2)) {
                    levelBanner = nil
                }
            }
        }

        if !activeCards.isEmpty && now >= litDeadline {
            loseLife()
            activeCards = []
            nextSpawnTime = now.addingTimeInterval(0.25)
        }

        if activeCards.isEmpty && now >= nextSpawnTime {
            spawnCards(now: now)
        }
    }

    private func tapCard(_ cardID: Int) {
        guard !isGameOver else { return }

        if activeCards.contains(cardID) {
            score += currentPhase.points
            activeCards.remove(cardID)

            if activeCards.isEmpty {
                nextSpawnTime = Date().addingTimeInterval(0.18)
            }
        } else {
            loseLife()
        }
    }

    private func spawnCards(now: Date) {
        let cardCount = currentPhase.cardCount
        let lightCount = min(currentPhase.litCardCount, cardCount)
        activeCards = Set((0..<cardCount).shuffled().prefix(lightCount))
        litDeadline = now.addingTimeInterval(currentPhase.reactionWindow)
    }

    private func loseLife() {
        guard lives > 0 else { return }

        lives -= 1
        boardShake.toggle()

        if lives == 0 {
            finishGame()
        }
    }

    private func finishGame() {
        isGameOver = true
        activeCards = []
        highScore = max(highScore, score)
    }

    private func resetGame() {
        score = 0
        lives = 3
        remainingTime = roundLength
        isGameOver = false
        activeCards = []
        currentPhase = .level1
        levelBanner = nil
        roundStartTime = Date()
        nextSpawnTime = Date().addingTimeInterval(0.45)
        litDeadline = Date()
    }
}

private enum LightPhase: Int {
    case level1 = 1
    case level2 = 2
    case level3 = 3
    case level4 = 4

    var cardCount: Int {
        switch self {
        case .level1: 3
        case .level2: 4
        case .level3: 6
        case .level4: 9
        }
    }

    var columns: Int {
        switch self {
        case .level1: 3
        case .level2: 2
        case .level3: 3
        case .level4: 3
        }
    }

    var reactionWindow: TimeInterval {
        switch self {
        case .level1: 1.5
        case .level2: 1.2
        case .level3: 1.0
        case .level4: 0.8
        }
    }

    var litCardCount: Int {
        self == .level4 ? 2 : 1
    }

    var points: Int {
        rawValue * 10
    }

    var tint: Color {
        switch self {
        case .level1: .cyan
        case .level2: .orange
        case .level3: .pink
        case .level4: .red
        }
    }

    var caption: String {
        switch self {
        case .level1: "Soft cyan warmup. Watch for one glowing card."
        case .level2: "Amber speed-up. The reaction window is tighter."
        case .level3: "Neon pink spread. Scan the whole board."
        case .level4: "Electric red overload. Two cards can light at once."
        }
    }

    static func phase(for elapsed: TimeInterval, roundLength: Int) -> LightPhase {
        let segment = max(TimeInterval(roundLength) / 4.0, 1.0)

        switch elapsed {
        case 0..<segment:
            return .level1
        case segment..<(segment * 2):
            return .level2
        case (segment * 2)..<(segment * 3):
            return .level3
        default:
            return .level4
        }
    }
}

private struct LightCardView: View {
    let isLit: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 8)
                .fill(isLit ? tint : .white.opacity(0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isLit ? .white.opacity(0.95) : .white.opacity(0.14), lineWidth: isLit ? 2 : 1)
                )
                .shadow(color: isLit ? tint.opacity(0.85) : .clear, radius: 20)
                .scaleEffect(isLit ? 1.04 : 1.0)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: isLit ? "sparkle" : "circle.grid.cross")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(isLit ? .black.opacity(0.78) : .white.opacity(0.18))
                }
        }
        .buttonStyle(.plain)
    }
}

private struct LevelUpOverlay: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(size: 26, weight: .black, design: .rounded))
            .foregroundStyle(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(tint, in: RoundedRectangle(cornerRadius: 8))
            .shadow(color: tint.opacity(0.85), radius: 28)
            .padding(.horizontal, 24)
    }
}

private struct QuizRushView: View {
    let returnToMenu: () -> Void

    @StateObject private var viewModel = QuizRushViewModel()

    var body: some View {
        VStack(spacing: 18) {
            GameTopBar(title: "QUIZ RUSH", icon: "flame.fill", tint: .orange, returnToMenu: returnToMenu)

            switch viewModel.state {
            case .loading:
                QuizLoadingView()
            case .active:
                QuizActiveView(viewModel: viewModel)
            case .finished:
                GameOverView(title: "QUIZ COMPLETE", score: viewModel.score, highScore: viewModel.highScore, playAgain: viewModel.startRound, returnToMenu: returnToMenu)
            case .failed(let message):
                QuizErrorView(message: message, retry: viewModel.startRound)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .task {
            if viewModel.questions.isEmpty {
                await viewModel.loadRound()
            }
        }
    }
}

private enum QuizRushState: Equatable {
    case loading
    case active
    case finished
    case failed(String)
}

private struct TriviaResponse: Codable {
    let results: [TriviaQuestion]
}

private struct TriviaQuestion: Codable, Identifiable {
    let id = UUID()
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]

    enum CodingKeys: String, CodingKey {
        case question
        case correctAnswer = "correct_answer"
        case incorrectAnswers = "incorrect_answers"
    }

    var decodedQuestion: String {
        question.decodedHTML
    }

    var decodedCorrectAnswer: String {
        correctAnswer.decodedHTML
    }

    var shuffledAnswers: [String] {
        ([correctAnswer] + incorrectAnswers).map(\.decodedHTML).shuffled()
    }
}

private struct QuizQuestionRound: Identifiable {
    let id = UUID()
    let prompt: String
    let correctAnswer: String
    let answers: [String]
}

private struct TriviaService {
    func fetchQuestions() async throws -> [QuizQuestionRound] {
        let url = URL(string: "https://opentdb.com/api.php?amount=10&type=multiple")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let triviaResponse = try JSONDecoder().decode(TriviaResponse.self, from: data)

        guard !triviaResponse.results.isEmpty else {
            throw URLError(.zeroByteResource)
        }

        return triviaResponse.results.map { question in
            QuizQuestionRound(
                prompt: question.decodedQuestion,
                correctAnswer: question.decodedCorrectAnswer,
                answers: question.shuffledAnswers
            )
        }
    }
}

@MainActor
private final class QuizRushViewModel: ObservableObject {
    @AppStorage("quizRushHighScore") var highScore = 0
    @Published var state: QuizRushState = .loading
    @Published var questions: [QuizQuestionRound] = []
    @Published var currentQuestionIndex = 0
    @Published var score = 0
    @Published var streak = 0
    @Published var selectedAnswer: String?
    @Published var answerWasCorrect: Bool?
    @Published var screenShake = false

    private let service = TriviaService()

    var currentQuestion: QuizQuestionRound? {
        guard questions.indices.contains(currentQuestionIndex) else { return nil }
        return questions[currentQuestionIndex]
    }

    var questionProgressText: String {
        "Question \(min(currentQuestionIndex + 1, questions.count)) of \(questions.count)"
    }

    var streakMultiplier: Int {
        max(1, min(4, (streak / 3) + 1))
    }

    func startRound() {
        Task {
            await loadRound()
        }
    }

    func loadRound() async {
        state = .loading
        questions = []
        currentQuestionIndex = 0
        score = 0
        streak = 0
        selectedAnswer = nil
        answerWasCorrect = nil

        do {
            questions = try await service.fetchQuestions()
            state = .active
        } catch {
            state = .failed("Could not download trivia. Check your connection and try again.")
        }
    }

    func chooseAnswer(_ answer: String) {
        guard state == .active, selectedAnswer == nil, let question = currentQuestion else { return }

        let isCorrect = answer == question.correctAnswer
        selectedAnswer = answer
        answerWasCorrect = isCorrect

        if isCorrect {
            streak += 1
            score += 100 * streakMultiplier
        } else {
            streak = 0
            score = max(0, score - 40)
            screenShake.toggle()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
            self?.advanceQuestion()
        }
    }

    private func advanceQuestion() {
        selectedAnswer = nil
        answerWasCorrect = nil

        if currentQuestionIndex + 1 < questions.count {
            withAnimation(.easeInOut(duration: 0.18)) {
                currentQuestionIndex += 1
            }
        } else {
            highScore = max(highScore, score)
            state = .finished
        }
    }
}

private struct QuizLoadingView: View {
    var body: some View {
        SpacerLayout {
            ZStack {
                Circle()
                    .stroke(.orange.opacity(0.22), lineWidth: 8)
                    .frame(width: 126, height: 126)

                Circle()
                    .trim(from: 0.1, to: 0.82)
                    .stroke(.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 126, height: 126)
                    .rotationEffect(.degrees(28))
                    .shadow(color: .orange.opacity(0.8), radius: 18)

                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.4)
            }

            Text("Downloading trivia matrix...")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Fetching 10 live multiple-choice questions.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
        }
    }
}

private struct QuizActiveView: View {
    @ObservedObject var viewModel: QuizRushViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ScorePanel(title: "Score", value: "\(viewModel.score)", tint: .orange)
                ScorePanel(title: "Streak", value: "x\(viewModel.streakMultiplier)", tint: .red)
            }

            HStack(spacing: 8) {
                Text(viewModel.questionProgressText)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(.orange)

                Spacer()

                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)

                Text("\(viewModel.streak)")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .frame(height: 26)

            if let question = viewModel.currentQuestion {
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
                            selectedAnswer: viewModel.selectedAnswer,
                            correctAnswer: question.correctAnswer,
                            action: {
                                withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                                    viewModel.chooseAnswer(answer)
                                }
                            }
                        )
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .offset(x: viewModel.screenShake ? -8 : 0)
        .animation(.default.repeatCount(3, autoreverses: true), value: viewModel.screenShake)
    }
}

private struct QuizAnswerButton: View {
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

private struct QuizErrorView: View {
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

private struct SpacerLayout<Content: View>: View {
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

private extension String {
    var decodedHTML: String {
        guard let data = data(using: .utf8) else { return self }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        return (try? NSAttributedString(data: data, options: options, documentAttributes: nil).string) ?? self
    }
}

private struct GameTopBar: View {
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
    let title: String
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

                Text(title)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

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
