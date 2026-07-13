import SwiftUI
import Charts
import MapKit
import CoreLocation
import UserNotifications
import Combine

struct ContentView: View {
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var locationService = LocationService()
    @StateObject private var notificationService = NotificationService()

    var body: some View {
        AppShellView()
            .environmentObject(sessionStore)
            .environmentObject(locationService)
            .environmentObject(notificationService)
    }
}

// MARK: - Models

enum GameMode: String, CaseIterable, Codable, Identifiable {
    case tapFrenzy
    case lightItUp
    case quizRush

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tapFrenzy: "TapFrenzy"
        case .lightItUp: "LightItUp"
        case .quizRush: "QuizRush"
        }
    }

    var displayTitle: String {
        switch self {
        case .tapFrenzy: "Tap Frenzy"
        case .lightItUp: "Light It Up"
        case .quizRush: "Quiz Rush"
        }
    }

    var subtitle: String {
        switch self {
        case .tapFrenzy: "Tap as fast as possible before the timer ends."
        case .lightItUp: "Hit glowing tiles before they fade away."
        case .quizRush: "Answer multiple-choice trivia for marks."
        }
    }

    var symbolName: String {
        switch self {
        case .tapFrenzy: "hand.tap.fill"
        case .lightItUp: "lightbulb.max.fill"
        case .quizRush: "questionmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .tapFrenzy: .cyan
        case .lightItUp: .yellow
        case .quizRush: .orange
        }
    }
}

struct GameSession: Identifiable, Codable, Hashable {
    let id: UUID
    let mode: GameMode
    let score: Int
    let timestamp: Date
    let latitude: Double
    let longitude: Double

    init(id: UUID = UUID(), mode: GameMode, score: Int, timestamp: Date = Date(), latitude: Double, longitude: Double) {
        self.id = id
        self.mode = mode
        self.score = score
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var shareText: String {
        "I just scored \(score) in \(mode.displayTitle) on PlayHub."
    }
}

struct ModeStats: Identifiable {
    let mode: GameMode
    let sessions: [GameSession]

    var id: GameMode { mode }
    var plays: Int { sessions.count }
    var totalScore: Int { sessions.reduce(0) { $0 + $1.score } }
    var bestScore: Int { sessions.map(\.score).max() ?? 0 }
    var averageScore: Int { plays == 0 ? 0 : totalScore / plays }
}

struct TriviaQuestion: Identifiable, Codable {
    let id: UUID
    let prompt: String
    let correctAnswer: String
    let answers: [String]

    init(id: UUID = UUID(), prompt: String, correctAnswer: String, answers: [String]) {
        self.id = id
        self.prompt = prompt
        self.correctAnswer = correctAnswer
        self.answers = answers
    }
}

private struct TriviaAPIResponse: Decodable {
    let results: [TriviaAPIQuestion]
}

private struct TriviaAPIQuestion: Decodable {
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]

    enum CodingKeys: String, CodingKey {
        case question
        case correctAnswer = "correct_answer"
        case incorrectAnswers = "incorrect_answers"
    }
}

// MARK: - Services

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var sessions: [GameSession] = []

    private let storageKey = "playHubGameSessions"

    init() {
        load()
    }

    func record(mode: GameMode, score: Int, coordinate: CLLocationCoordinate2D) -> GameSession {
        let session = GameSession(mode: mode, score: score, latitude: coordinate.latitude, longitude: coordinate.longitude)
        sessions.insert(session, at: 0)
        save()
        return session
    }

    func reset() {
        sessions.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    func stats(for mode: GameMode) -> ModeStats {
        ModeStats(mode: mode, sessions: sessions.filter { $0.mode == mode })
    }

    var allStats: [ModeStats] {
        GameMode.allCases.map { stats(for: $0) }
    }

    var totalScore: Int {
        sessions.reduce(0) { $0 + $1.score }
    }

    var bestSession: GameSession? {
        sessions.max { $0.score < $1.score }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        sessions = (try? JSONDecoder().decode([GameSession].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationMessage = "Location is optional. Scores use your current coordinate when available."

    private let manager = CLLocationManager()
    private let fallbackCoordinate = CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var currentCoordinate: CLLocationCoordinate2D {
        manager.location?.coordinate ?? fallbackCoordinate
    }

    func requestPermissionIfConfigured() {
        guard Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil else {
            authorizationMessage = "Add NSLocationWhenInUseUsageDescription to use live location. Using fallback coordinates for now."
            return
        }

        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                authorizationMessage = "Location enabled. New results can use your current coordinate."
                manager.requestLocation()
            case .denied, .restricted:
                authorizationMessage = "Location is disabled. New results use fallback coordinates."
            case .notDetermined:
                authorizationMessage = "Location permission has not been requested."
            @unknown default:
                authorizationMessage = "Location status is unavailable."
            }
        }
    }
}

@MainActor
final class NotificationService: ObservableObject {
    @Published var statusMessage = "Daily reminders are off."

    private let reminderIdentifier = "playHubDailyReminder"

    func scheduleDailyReminder(at date: Date) async {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])

            guard granted else {
                statusMessage = "Notification permission was not granted."
                return
            }

            center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

            let content = UNMutableNotificationContent()
            content.title = "PlayHub challenge"
            content.body = "Play a quick round and beat your best score."
            content.sound = .default

            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)

            try await center.add(request)
            statusMessage = "Daily reminder scheduled."
        } catch {
            statusMessage = "Could not schedule reminder."
        }
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
        statusMessage = "Daily reminders are off."
    }
}

struct TriviaService {
    func fetchQuestions() async -> [TriviaQuestion] {
        guard let url = URL(string: "https://opentdb.com/api.php?amount=5&type=multiple") else {
            return Self.fallbackQuestions
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                return Self.fallbackQuestions
            }

            let decoded = try JSONDecoder().decode(TriviaAPIResponse.self, from: data)
            let questions = decoded.results.map { apiQuestion in
                let correct = apiQuestion.correctAnswer.decodedHTML
                let answers = ([apiQuestion.correctAnswer] + apiQuestion.incorrectAnswers)
                    .map(\.decodedHTML)
                    .shuffled()

                return TriviaQuestion(prompt: apiQuestion.question.decodedHTML, correctAnswer: correct, answers: answers)
            }

            return questions.isEmpty ? Self.fallbackQuestions : questions
        } catch {
            return Self.fallbackQuestions
        }
    }

    private static let fallbackQuestions = [
        TriviaQuestion(prompt: "Which framework builds declarative iOS interfaces?", correctAnswer: "SwiftUI", answers: ["SwiftUI", "SpriteKit", "CloudKit", "MapKit"]),
        TriviaQuestion(prompt: "Which Apple framework displays maps?", correctAnswer: "MapKit", answers: ["MapKit", "Charts", "Photos", "StoreKit"]),
        TriviaQuestion(prompt: "What type is commonly used for unique model IDs?", correctAnswer: "UUID", answers: ["UUID", "URL", "Int8", "CGFloat"]),
        TriviaQuestion(prompt: "Which framework schedules local notifications?", correctAnswer: "UserNotifications", answers: ["UserNotifications", "CoreMotion", "AVKit", "RealityKit"]),
        TriviaQuestion(prompt: "Which property wrapper stores simple settings?", correctAnswer: "AppStorage", answers: ["AppStorage", "GestureState", "Namespace", "SceneStorage"])
    ]
}

extension String {
    var decodedHTML: String {
        guard let data = data(using: .utf8) else { return self }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        return (try? NSAttributedString(data: data, options: options, documentAttributes: nil).string) ?? self
    }
}

// MARK: - View Models

@MainActor
final class GameRouter: ObservableObject {
    @Published var selectedMode: GameMode?
    @Published var completedSession: GameSession?
}

@MainActor
final class TapFrenzyViewModel: ObservableObject {
    @Published var score = 0
    @Published var remainingTime = 10
    @Published var isFinished = false

    var buttonSize: CGFloat {
        90 + (CGFloat(remainingTime) / 10 * 150)
    }

    var isBonusActive: Bool {
        remainingTime == 5 || remainingTime == 4
    }

    func start() {
        score = 0
        remainingTime = 10
        isFinished = false
    }

    func tap() {
        guard !isFinished else { return }
        score += isBonusActive ? 2 : 1
    }

    func tick() {
        guard !isFinished else { return }

        if remainingTime > 0 {
            remainingTime -= 1
        }

        if remainingTime == 0 {
            isFinished = true
        }
    }
}

@MainActor
final class LightItUpViewModel: ObservableObject {
    @Published var score = 0
    @Published var lives = 3
    @Published var remainingTime = 30
    @Published var activeTiles: Set<Int> = []
    @Published var level = 1
    @Published var isFinished = false

    private var tickCount = 0

    var tileCount: Int { level < 3 ? 6 : 9 }
    var activeTileCount: Int { min(level, 3) }
    var tint: Color { level == 1 ? .yellow : level == 2 ? .orange : .red }

    func start() {
        score = 0
        lives = 3
        remainingTime = 30
        activeTiles = []
        level = 1
        tickCount = 0
        isFinished = false
        spawnTiles()
    }

    func tapTile(_ tile: Int) {
        guard !isFinished else { return }

        if activeTiles.contains(tile) {
            score += level * 10
            activeTiles.remove(tile)
            if activeTiles.isEmpty {
                spawnTiles()
            }
        } else {
            lives -= 1
            if lives <= 0 {
                isFinished = true
            }
        }
    }

    func tick() {
        guard !isFinished else { return }

        tickCount += 1
        remainingTime -= 1

        if remainingTime <= 20 { level = max(level, 2) }
        if remainingTime <= 10 { level = max(level, 3) }

        if tickCount.isMultiple(of: max(2, 5 - level)) {
            spawnTiles()
        }

        if remainingTime <= 0 {
            isFinished = true
        }
    }

    private func spawnTiles() {
        let range = 0..<tileCount
        activeTiles = Set(range.shuffled().prefix(activeTileCount))
    }
}

@MainActor
final class QuizRushViewModel: ObservableObject {
    @Published var questions: [TriviaQuestion] = []
    @Published var currentIndex = 0
    @Published var score = 0
    @Published var selectedAnswer: String?
    @Published var isLoading = true
    @Published var isFinished = false

    private let service = TriviaService()

    var currentQuestion: TriviaQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var progressText: String {
        "Question \(min(currentIndex + 1, questions.count)) of \(questions.count)"
    }

    func start() async {
        isLoading = true
        questions = await service.fetchQuestions()
        currentIndex = 0
        score = 0
        selectedAnswer = nil
        isFinished = false
        isLoading = false
    }

    func choose(_ answer: String) {
        guard selectedAnswer == nil, let question = currentQuestion else { return }

        selectedAnswer = answer
        score += answer == question.correctAnswer ? 10 : -10

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(550))
            selectedAnswer = nil

            if currentIndex + 1 < questions.count {
                currentIndex += 1
            } else {
                isFinished = true
            }
        }
    }
}

// MARK: - App Shell

struct AppShellView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }

            NavigationStack {
                SessionMapView()
            }
            .tabItem {
                Label("Map", systemImage: "map.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @StateObject private var router = GameRouter()

    var body: some View {
        ZStack {
            PlayHubBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HeaderView()

                    ForEach(GameMode.allCases) { mode in
                        NavigationLink {
                            GameHostView(mode: mode)
                                .environmentObject(router)
                        } label: {
                            GameModeCard(mode: mode, bestScore: sessionStore.stats(for: mode).bestScore)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("PlayHub")
        .environmentObject(router)
    }
}

struct HeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("COHNDSE251F iOS Games", systemImage: "gamecontroller.fill")
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundStyle(.cyan)

            Text("Choose a game mode")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Sessions are saved for stats, maps, and sharing.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.black.opacity(0.32), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.cyan.opacity(0.35), lineWidth: 1)
        )
    }
}

struct GameModeCard: View {
    let mode: GameMode
    let bestScore: Int

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: mode.symbolName)
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(.black)
                .frame(width: 60, height: 60)
                .background(mode.tint, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text(mode.displayTitle)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(mode.subtitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("BEST")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.62))

                Text("\(bestScore)")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(mode.tint)
            }
        }
        .padding(16)
        .background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(mode.tint.opacity(0.48), lineWidth: 1)
        )
    }
}

struct GameHostView: View {
    let mode: GameMode

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var locationService: LocationService
    @State private var completedSession: GameSession?

    var body: some View {
        ZStack {
            PlayHubBackground()

            if let completedSession {
                ResultView(session: completedSession) {
                    self.completedSession = nil
                } exit: {
                    dismiss()
                }
                .padding(20)
            } else {
                gameView
                    .padding(20)
            }
        }
        .navigationTitle(mode.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var gameView: some View {
        switch mode {
        case .tapFrenzy:
            TapFrenzyGameView { score in
                finish(score: score)
            }
        case .lightItUp:
            LightItUpGameView { score in
                finish(score: score)
            }
        case .quizRush:
            QuizRushGameView { score in
                finish(score: score)
            }
        }
    }

    private func finish(score: Int) {
        completedSession = sessionStore.record(
            mode: mode,
            score: score,
            coordinate: locationService.currentCoordinate
        )
    }
}

// MARK: - Games

struct TapFrenzyGameView: View {
    let onComplete: (Int) -> Void

    @StateObject private var viewModel = TapFrenzyViewModel()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 22) {
            GameTopBar(title: "Tap Frenzy", symbol: "hand.tap.fill", tint: .cyan)

            HStack(spacing: 12) {
                ScoreBadge(title: "Score", value: "\(viewModel.score)", tint: .cyan)
                ScoreBadge(title: "Time", value: "\(viewModel.remainingTime)s", tint: .mint)
            }

            Text(viewModel.isBonusActive ? "DOUBLE POINTS" : "TAP AS FAST AS YOU CAN")
                .font(.system(size: 15, weight: .black, design: .monospaced))
                .foregroundStyle(viewModel.isBonusActive ? .yellow : .cyan)
                .frame(height: 26)

            Spacer()

            Button(action: viewModel.tap) {
                Text("TAP")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(width: viewModel.buttonSize, height: viewModel.buttonSize)
                    .background(viewModel.isBonusActive ? .yellow : .cyan, in: Circle())
                    .shadow(color: (viewModel.isBonusActive ? Color.yellow : Color.cyan).opacity(0.65), radius: 24)
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: viewModel.buttonSize)

            Spacer()
        }
        .onAppear(perform: viewModel.start)
        .onReceive(timer) { _ in
            viewModel.tick()
            if viewModel.isFinished {
                onComplete(viewModel.score)
            }
        }
    }
}

struct LightItUpGameView: View {
    let onComplete: (Int) -> Void

    @StateObject private var viewModel = LightItUpViewModel()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    }

    var body: some View {
        VStack(spacing: 18) {
            GameTopBar(title: "Light It Up", symbol: "lightbulb.max.fill", tint: viewModel.tint)

            HStack(spacing: 12) {
                ScoreBadge(title: "Score", value: "\(viewModel.score)", tint: viewModel.tint)
                ScoreBadge(title: "Time", value: "\(viewModel.remainingTime)s", tint: .mint)
            }

            HStack {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < viewModel.lives ? "heart.fill" : "heart.slash.fill")
                        .foregroundStyle(index < viewModel.lives ? .red : .gray)
                }

                Spacer()

                Text("LEVEL \(viewModel.level)")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(viewModel.tint)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<viewModel.tileCount, id: \.self) { tile in
                    Button {
                        viewModel.tapTile(tile)
                        if viewModel.isFinished {
                            onComplete(viewModel.score)
                        }
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.activeTiles.contains(tile) ? viewModel.tint : .white.opacity(0.10))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                Image(systemName: viewModel.activeTiles.contains(tile) ? "sparkle" : "square.grid.3x3")
                                    .font(.system(size: 24, weight: .black))
                                    .foregroundStyle(viewModel.activeTiles.contains(tile) ? .black : .white.opacity(0.2))
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Tap lit tiles only. Wrong taps cost lives.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.64))

            Spacer()
        }
        .onAppear(perform: viewModel.start)
        .onReceive(timer) { _ in
            viewModel.tick()
            if viewModel.isFinished {
                onComplete(viewModel.score)
            }
        }
    }
}

struct QuizRushGameView: View {
    let onComplete: (Int) -> Void

    @StateObject private var viewModel = QuizRushViewModel()

    var body: some View {
        VStack(spacing: 18) {
            GameTopBar(title: "Quiz Rush", symbol: "questionmark.circle.fill", tint: .orange)

            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading trivia")
                    .tint(.orange)
                    .foregroundStyle(.white)
                Spacer()
            } else if let question = viewModel.currentQuestion {
                HStack(spacing: 12) {
                    ScoreBadge(title: "Marks", value: "\(viewModel.score)", tint: .orange)
                    ScoreBadge(title: "Round", value: viewModel.progressText, tint: .red)
                }

                Text(question.prompt)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .padding(16)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))

                VStack(spacing: 12) {
                    ForEach(question.answers, id: \.self) { answer in
                        Button {
                            viewModel.choose(answer)
                        } label: {
                            Text(answer)
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .padding(.horizontal, 12)
                                .background(answerColor(answer, question: question), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.selectedAnswer != nil)
                    }
                }

                Spacer()
            }
        }
        .task {
            await viewModel.start()
        }
        .onChange(of: viewModel.isFinished) { _, isFinished in
            if isFinished {
                onComplete(viewModel.score)
            }
        }
    }

    private func answerColor(_ answer: String, question: TriviaQuestion) -> Color {
        guard let selected = viewModel.selectedAnswer else { return .orange.opacity(0.22) }
        if answer == question.correctAnswer { return .green.opacity(0.55) }
        if answer == selected { return .red.opacity(0.55) }
        return .white.opacity(0.10)
    }
}

// MARK: - Stats

struct StatsView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        ZStack {
            PlayHubBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        StatCard(title: "Sessions", value: "\(sessionStore.sessions.count)", tint: .cyan)
                        StatCard(title: "Total", value: "\(sessionStore.totalScore)", tint: .orange)
                        StatCard(title: "Best", value: "\(sessionStore.bestSession?.score ?? 0)", tint: .yellow)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Scores by Mode")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Chart(sessionStore.allStats) { stat in
                            BarMark(
                                x: .value("Mode", stat.mode.displayTitle),
                                y: .value("Total Score", stat.totalScore)
                            )
                            .foregroundStyle(by: .value("Mode", stat.mode.displayTitle))
                        }
                        .frame(height: 240)
                        .chartXAxisLabel("Game Mode")
                        .chartYAxisLabel("Total Score")
                    }
                    .panelStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Games")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        if sessionStore.sessions.isEmpty {
                            EmptyStateView(text: "Play a game to create your first session.")
                        } else {
                            ForEach(sessionStore.sessions.prefix(8)) { session in
                                SessionRow(session: session)
                            }
                        }
                    }
                    .panelStyle()
                }
                .padding(20)
            }
        }
        .navigationTitle("Stats")
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 86)
        .background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(tint.opacity(0.4), lineWidth: 1))
    }
}

struct SessionRow: View {
    let session: GameSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.mode.symbolName)
                .foregroundStyle(.black)
                .frame(width: 40, height: 40)
                .background(session.mode.tint, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(session.mode.displayTitle)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(session.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Text("\(session.score)")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(session.mode.tint)
        }
        .padding(12)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Map

struct SessionMapView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @State private var selectedSession: GameSession?
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
            span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        )
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                ForEach(sessionStore.sessions) { session in
                    Annotation(session.mode.displayTitle, coordinate: session.coordinate) {
                        Button {
                            selectedSession = session
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: session.mode.symbolName)
                                    .font(.system(size: 15, weight: .black))
                                Text("\(session.score)")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                            }
                            .foregroundStyle(.black)
                            .padding(8)
                            .background(session.mode.tint, in: RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea(edges: .bottom)

            if sessionStore.sessions.isEmpty {
                EmptyStateView(text: "Completed sessions will appear as map pins.")
                    .padding(20)
            }

            if let selectedSession {
                SessionMapCallout(session: selectedSession)
                    .padding(20)
            }
        }
        .navigationTitle("Map")
    }
}

struct SessionMapCallout: View {
    let session: GameSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.mode.symbolName)
                .foregroundStyle(.black)
                .frame(width: 44, height: 44)
                .background(session.mode.tint, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(session.mode.displayTitle)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Score \(session.score) at \(session.timestamp.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
            }

            Spacer()
        }
        .padding(14)
        .background(.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var notificationService: NotificationService

    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("reminderTimeInterval") private var reminderTimeInterval = 20.0 * 60.0 * 60.0
    @State private var isShowingResetConfirmation = false

    private var reminderDate: Binding<Date> {
        Binding {
            Calendar.current.startOfDay(for: Date()).addingTimeInterval(reminderTimeInterval)
        } set: { newValue in
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderTimeInterval = Double((components.hour ?? 20) * 3600 + (components.minute ?? 0) * 60)
        }
    }

    var body: some View {
        ZStack {
            PlayHubBackground()

            Form {
                Section("Daily Reminder") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)

                    DatePicker("Reminder Time", selection: reminderDate, displayedComponents: .hourAndMinute)

                    Text(notificationService.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Location") {
                    Button("Enable Location for New Scores") {
                        locationService.requestPermissionIfConfigured()
                    }

                    Text(locationService.authorizationMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Stats") {
                    Button("Reset All Stats", role: .destructive) {
                        isShowingResetConfirmation = true
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .onChange(of: notificationsEnabled) { _, isEnabled in
            Task {
                if isEnabled {
                    await notificationService.scheduleDailyReminder(at: reminderDate.wrappedValue)
                } else {
                    notificationService.cancelDailyReminder()
                }
            }
        }
        .onChange(of: reminderTimeInterval) { _, _ in
            Task {
                if notificationsEnabled {
                    await notificationService.scheduleDailyReminder(at: reminderDate.wrappedValue)
                }
            }
        }
        .confirmationDialog("Reset all saved game sessions?", isPresented: $isShowingResetConfirmation, titleVisibility: .visible) {
            Button("Reset All Stats", role: .destructive) {
                sessionStore.reset()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

// MARK: - Shared Views

struct ResultView: View {
    let session: GameSession
    let playAgain: () -> Void
    let exit: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 58, weight: .black))
                .foregroundStyle(.yellow)
                .shadow(color: .yellow.opacity(0.6), radius: 18)

            Text("Result Saved")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("\(session.mode.displayTitle) score: \(session.score)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(session.mode.tint)

            ShareLink(item: session.shareText) {
                Label("Share Score", systemImage: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: 280, minHeight: 54)
                    .background(.cyan, in: RoundedRectangle(cornerRadius: 8))
            }

            Button(action: playAgain) {
                Text("Play Again")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: 280, minHeight: 54)
                    .background(session.mode.tint, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Button(action: exit) {
                Text("Back to Home")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: 280, minHeight: 50)
                    .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .panelStyle()
    }
}

struct GameTopBar: View {
    let title: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Image(systemName: symbol)
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(.black)
                .frame(width: 44, height: 44)
                .background(tint, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct ScoreBadge: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 82)
        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(tint.opacity(0.45), lineWidth: 1))
    }
}

struct EmptyStateView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.74))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 88)
            .background(.black.opacity(0.44), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct PlayHubBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.03, blue: 0.08),
                    Color(red: 0.05, green: 0.08, blue: 0.12),
                    Color(red: 0.10, green: 0.03, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geometry in
                ForEach(0..<18, id: \.self) { index in
                    Circle()
                        .fill(index.isMultiple(of: 3) ? .cyan.opacity(0.85) : .white.opacity(0.7))
                        .frame(width: index.isMultiple(of: 4) ? 4 : 2, height: index.isMultiple(of: 4) ? 4 : 2)
                        .position(
                            x: CGFloat((index * 47) % 100) / 100 * geometry.size.width,
                            y: CGFloat((index * 29) % 100) / 100 * geometry.size.height
                        )
                }
            }
        }
        .ignoresSafeArea()
    }
}

extension View {
    func panelStyle() -> some View {
        self
            .padding(16)
            .background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.12), lineWidth: 1))
    }
}

#Preview {
    ContentView()
}
