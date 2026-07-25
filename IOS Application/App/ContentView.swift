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
            .onAppear {
                locationService.requestPermissionIfConfigured()
            }
    }
}

// MARK: - Shared Models

struct GameSession: Identifiable, Codable, Hashable {
    let id: UUID
    let game: ArcadeGame
    let score: Int
    let timestamp: Date
    let latitude: Double?
    let longitude: Double?

    init(id: UUID = UUID(), game: ArcadeGame, score: Int, timestamp: Date = Date(), coordinate: CLLocationCoordinate2D?) {
        self.id = id
        self.game = game
        self.score = score
        self.timestamp = timestamp
        self.latitude = coordinate?.latitude
        self.longitude = coordinate?.longitude
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var shareText: String {
        "I just scored \(score) in \(game.title) on PlayHub."
    }
}

struct GameStats: Identifiable {
    let game: ArcadeGame
    let sessions: [GameSession]

    var id: ArcadeGame { game }
    var plays: Int { sessions.count }
    var totalScore: Int { sessions.reduce(0) { $0 + $1.score } }
    var bestScore: Int { sessions.map(\.score).max() ?? 0 }
    var averageScore: Int { plays == 0 ? 0 : totalScore / plays }
}

// MARK: - Shared Services

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var sessions: [GameSession] = []

    private let storageKey = "playHubGameSessions"

    init() {
        load()
    }

    func record(game: ArcadeGame, score: Int, coordinate: CLLocationCoordinate2D?) -> GameSession {
        let session = GameSession(game: game, score: score, coordinate: coordinate)
        sessions.append(session)
        save()
        return session
    }

    func reset() {
        sessions.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
        ArcadeGame.allCases.forEach { game in
            UserDefaults.standard.removeObject(forKey: game.highScoreKey)
        }
    }

    func stats(for game: ArcadeGame) -> GameStats {
        GameStats(game: game, sessions: sessions.filter { $0.game == game })
    }

    var allStats: [GameStats] {
        ArcadeGame.allCases.map { stats(for: $0) }
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
    @Published var authorizationMessage = "Enable Location so new scores are saved where you play."
    @Published private(set) var latestCoordinate: CLLocationCoordinate2D?
    @Published private(set) var latestHorizontalAccuracy: CLLocationAccuracy?
    @Published private(set) var latestLocationDate: Date?

    private let manager = CLLocationManager()
    private var pendingLocationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.activityType = .other
        requestPermissionIfConfigured()
    }

    var currentCoordinate: CLLocationCoordinate2D? {
        latestCoordinate ?? manager.location?.coordinate
    }

    var hasLocationPermission: Bool {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }

    var authorizationStatusText: String {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            return "Always"
        case .authorizedWhenInUse:
            return "While Using"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not Requested"
        @unknown default:
            return "Unknown"
        }
    }

    var accuracyAuthorizationText: String {
        switch manager.accuracyAuthorization {
        case .fullAccuracy:
            return "Precise"
        case .reducedAccuracy:
            return "Approximate"
        @unknown default:
            return "Unknown"
        }
    }

    var accuracySummary: String {
        guard let latestHorizontalAccuracy else {
            return "No location fix yet."
        }

        let meters = Int(latestHorizontalAccuracy.rounded())
        if let latestLocationDate {
            return "Last fix: ±\(meters)m at \(latestLocationDate.formatted(date: .omitted, time: .shortened))."
        }

        return "Last fix: ±\(meters)m."
    }

    var coordinateSummary: String {
        guard let coordinate = currentCoordinate else {
            return "Coordinate unavailable."
        }

        return String(format: "Lat %.5f, Lon %.5f", coordinate.latitude, coordinate.longitude)
    }

    func requestPermissionIfConfigured() {
        guard Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil else {
            authorizationMessage = "Missing NSLocationWhenInUseUsageDescription in Target Info. iOS cannot show the location permission prompt until this is added."
            return
        }

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            authorizationMessage = manager.accuracyAuthorization == .fullAccuracy
                ? "Location enabled with precise accuracy."
                : "Location enabled with approximate accuracy. Turn on Precise Location in Settings for better map pins."
            startLiveLocationUpdates()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            authorizationMessage = "Location access is disabled. Enable it in Settings to save the real play location."
        }
    }

    func startLiveLocationUpdates() {
        guard hasLocationPermission else {
            requestPermissionIfConfigured()
            return
        }

        manager.startUpdatingLocation()
        manager.requestLocation()
    }

    func coordinateForNewScore() async -> CLLocationCoordinate2D? {
        requestPermissionIfConfigured()

        if let latestCoordinate, let latestLocationDate, Date().timeIntervalSince(latestLocationDate) < 120 {
            return latestCoordinate
        }

        guard hasLocationPermission else {
            return currentCoordinate
        }

        return await withCheckedContinuation { continuation in
            pendingLocationContinuation?.resume(returning: currentCoordinate)
            pendingLocationContinuation = continuation
            manager.requestLocation()

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(4))
                guard let pendingLocationContinuation else { return }
                self.pendingLocationContinuation = nil
                pendingLocationContinuation.resume(returning: currentCoordinate)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            latestCoordinate = location.coordinate
            latestHorizontalAccuracy = location.horizontalAccuracy
            latestLocationDate = location.timestamp
            authorizationMessage = manager.accuracyAuthorization == .fullAccuracy
                ? "Location ready. New scores will use your current coordinate."
                : "Approximate location ready. Enable Precise Location for better map pins."

            if let pendingLocationContinuation {
                self.pendingLocationContinuation = nil
                pendingLocationContinuation.resume(returning: location.coordinate)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            authorizationMessage = "Could not get your location right now. New scores will use the fallback coordinate."
            if let pendingLocationContinuation {
                self.pendingLocationContinuation = nil
                pendingLocationContinuation.resume(returning: currentCoordinate)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                authorizationMessage = manager.accuracyAuthorization == .fullAccuracy
                    ? "Location enabled with precise accuracy."
                    : "Location enabled with approximate accuracy. Turn on Precise Location in Settings for better map pins."
                startLiveLocationUpdates()
            case .denied, .restricted:
                authorizationMessage = "Location is disabled. Enable it in Settings to save the real play location."
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
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                statusMessage = "Notifications are disabled in Settings."
                return
            }

            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            let content = UNMutableNotificationContent()
            content.title = "PlayHub is ready"
            content.body = "Play a quick round and grow your stats."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)

            center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
            try await center.add(request)
            statusMessage = "Daily reminder set for \(date.formatted(date: .omitted, time: .shortened))."
        } catch {
            statusMessage = "Could not schedule reminders right now."
        }
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
        statusMessage = "Daily reminders are off."
    }
}

// MARK: - App Shell

struct AppShellView: View {
    @State private var selectedGame: ArcadeGame?

    var body: some View {
        ZStack {
            SpaceBackground()

            if let selectedGame {
                GameHostView(game: selectedGame) {
                    self.selectedGame = nil
                }
                .transition(.opacity)
            } else {
                TabView {
                    ArcadeHubView { game in
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedGame = game
                        }
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
                .toolbarBackground(.black.opacity(0.55), for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            }
        }
    }
}

struct GameHostView: View {
    let game: ArcadeGame
    let returnToMenu: () -> Void

    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var locationService: LocationService

    var body: some View {
        Group {
            switch game {
            case .tapFrenzy:
                TapFrenzyView(returnToMenu: returnToMenu, onComplete: recordScore)
            case .lightItUp:
                LightItUpView(returnToMenu: returnToMenu, onComplete: recordScore)
            case .quizRush:
                QuizRushView(returnToMenu: returnToMenu, onComplete: recordScore)
            }
        }
        .onAppear {
            locationService.requestPermissionIfConfigured()
        }
    }

    private func recordScore(_ score: Int) {
        Task {
            let coordinate = await locationService.coordinateForNewScore()
            _ = sessionStore.record(game: game, score: score, coordinate: coordinate)
        }
    }
}

// MARK: - Stats

struct StatsView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    StatCard(title: "Sessions", value: "\(sessionStore.sessions.count)", tint: .cyan)
                    StatCard(title: "Total", value: "\(sessionStore.totalScore)", tint: .orange)
                    StatCard(title: "Best", value: "\(sessionStore.bestSession?.score ?? 0)", tint: .yellow)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Scores by Game")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Chart(sessionStore.allStats) { stat in
                        BarMark(
                            x: .value("Game", stat.game.title),
                            y: .value("Total Score", stat.totalScore)
                        )
                        .foregroundStyle(by: .value("Game", stat.game.title))
                    }
                    .frame(height: 240)
                    .chartXAxisLabel("Game")
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
                        ForEach(sessionStore.sessions.reversed().prefix(8)) { session in
                            SessionRow(session: session)
                        }
                    }
                }
                .panelStyle()
            }
            .padding(20)
        }
        .navigationTitle("Stats")
        .scrollContentBackground(.hidden)
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
            Image(systemName: session.game.icon)
                .foregroundStyle(.black)
                .frame(width: 40, height: 40)
                .background(session.game.tint, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(session.game.title)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(session.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()

            Text("\(session.score)")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(session.game.tint)
        }
        .padding(12)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Map

struct SessionMapView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @EnvironmentObject private var locationService: LocationService

    @State private var selectedCluster: SessionLocationCluster?
    @State private var position = MapCameraPosition.automatic
    @State private var hasCenteredInitialMap = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                UserAnnotation()

                ForEach(locationClusters) { cluster in
                    Annotation(cluster.title, coordinate: cluster.coordinate) {
                        Button {
                            selectedCluster = cluster
                        } label: {
                            SessionMapClusterMarker(cluster: cluster)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea(edges: .bottom)

            VStack {
                HStack {
                    Spacer()

                    VStack(spacing: 8) {
                        Button {
                            fitMapToCurrentLocation()
                        } label: {
                            Label("Me", systemImage: "location.fill")
                                .labelStyle(.iconOnly)
                                .font(.system(size: 17, weight: .black))
                                .foregroundStyle(.black)
                                .frame(width: 44, height: 44)
                                .background(.cyan, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)

                        Button {
                            fitMapToSessions()
                        } label: {
                            Label("Plays", systemImage: "scope")
                                .labelStyle(.iconOnly)
                                .font(.system(size: 17, weight: .black))
                                .foregroundStyle(.black)
                                .frame(width: 44, height: 44)
                                .background(.yellow, in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .disabled(locationClusters.isEmpty)
                        .opacity(locationClusters.isEmpty ? 0.45 : 1)
                    }
                    .padding(.top, 14)
                    .padding(.trailing, 14)
                }

                Spacer()
            }

            if locationClusters.isEmpty {
                EmptyStateView(text: "Completed sessions will appear here after the iPhone provides a location.")
                    .padding(20)
            }

            if let selectedCluster {
                SessionMapClusterCallout(cluster: selectedCluster)
                    .padding(20)
            }
        }
        .navigationTitle("Map")
        .onAppear {
            locationService.startLiveLocationUpdates()
            centerInitialMapIfNeeded()
        }
        .onChange(of: locationService.latestLocationDate) { _, _ in
            centerInitialMapIfNeeded()
        }
        .onChange(of: sessionStore.sessions) { _, _ in
            centerInitialMapIfNeeded()
        }
    }

    private func centerInitialMapIfNeeded() {
        guard !hasCenteredInitialMap else { return }

        if let coordinate = locationService.currentCoordinate {
            fitMap(to: coordinate, latitudeDelta: 0.02, longitudeDelta: 0.02)
            hasCenteredInitialMap = true
        } else if !locationClusters.isEmpty {
            fitMapToSessions()
            hasCenteredInitialMap = true
        }
    }

    private func fitMapToCurrentLocation() {
        locationService.startLiveLocationUpdates()
        guard let coordinate = locationService.currentCoordinate else { return }
        fitMap(to: coordinate, latitudeDelta: 0.02, longitudeDelta: 0.02)
        hasCenteredInitialMap = true
    }

    private func fitMapToSessions() {
        let clusters = locationClusters
        guard !clusters.isEmpty else { return }

        let latitudes = clusters.map { $0.coordinate.latitude }
        let longitudes = clusters.map { $0.coordinate.longitude }
        guard let minimumLatitude = latitudes.min(),
              let maximumLatitude = latitudes.max(),
              let minimumLongitude = longitudes.min(),
              let maximumLongitude = longitudes.max() else {
            return
        }

        let center = CLLocationCoordinate2D(
            latitude: (minimumLatitude + maximumLatitude) / 2,
            longitude: (minimumLongitude + maximumLongitude) / 2
        )
        let latitudeDelta = max((maximumLatitude - minimumLatitude) * 1.5, 0.02)
        let longitudeDelta = max((maximumLongitude - minimumLongitude) * 1.5, 0.02)

        position = .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            )
        )
        hasCenteredInitialMap = true
    }

    private func fitMap(to coordinate: CLLocationCoordinate2D, latitudeDelta: CLLocationDegrees, longitudeDelta: CLLocationDegrees) {
        position = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            )
        )
    }

    private var locationClusters: [SessionLocationCluster] {
        let groups = Dictionary(grouping: sessionStore.sessions.compactMap { session -> (String, CLLocationCoordinate2D, GameSession)? in
            guard let coordinate = session.coordinate else { return nil }
            let key = String(format: "%.5f,%.5f", coordinate.latitude, coordinate.longitude)
            return (key, coordinate, session)
        }) { item in
            item.0
        }

        return groups.map { key, values in
            SessionLocationCluster(
                id: key,
                coordinate: values[0].1,
                sessions: values.map(\.2).sorted { $0.timestamp > $1.timestamp }
            )
        }
        .sorted { $0.latestDate > $1.latestDate }
    }
}

struct SessionLocationCluster: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let sessions: [GameSession]

    var title: String {
        sessions.count == 1 ? sessions[0].game.title : "\(sessions.count) plays"
    }

    var totalScore: Int {
        sessions.reduce(0) { $0 + $1.score }
    }

    var bestScore: Int {
        sessions.map(\.score).max() ?? 0
    }

    var latestDate: Date {
        sessions.map(\.timestamp).max() ?? .distantPast
    }

    var gameBreakdownText: String {
        ArcadeGame.allCases
            .compactMap { game -> String? in
                let count = sessions.filter { $0.game == game }.count
                return count == 0 ? nil : "\(game.title) \(count)"
            }
            .joined(separator: "  •  ")
    }
}

struct SessionMapClusterMarker: View {
    let cluster: SessionLocationCluster

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: cluster.sessions.count == 1 ? cluster.sessions[0].game.icon : "square.stack.3d.up.fill")
                .font(.system(size: 16, weight: .black))

            Text(cluster.sessions.count == 1 ? "\(cluster.bestScore)" : "\(cluster.sessions.count)")
                .font(.system(size: 11, weight: .black, design: .rounded))
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(markerTint, in: RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 6)
    }

    private var markerTint: Color {
        cluster.sessions.count == 1 ? cluster.sessions[0].game.tint : .yellow
    }
}

struct SessionMapClusterCallout: View {
    let cluster: SessionLocationCluster

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: cluster.sessions.count == 1 ? cluster.sessions[0].game.icon : "square.stack.3d.up.fill")
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(cluster.sessions.count == 1 ? cluster.sessions[0].game.tint : .yellow, in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(cluster.sessions.count == 1 ? cluster.sessions[0].game.title : "Same Place Summary")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("\(cluster.sessions.count) play\(cluster.sessions.count == 1 ? "" : "s") • total \(cluster.totalScore) • best \(cluster.bestScore)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()
            }

            if !cluster.gameBreakdownText.isEmpty {
                Text(cluster.gameBreakdownText)
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(.yellow)
            }

            VStack(spacing: 8) {
                ForEach(cluster.sessions.prefix(4)) { session in
                    HStack(spacing: 10) {
                        Text(session.game.title)
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(session.game.tint)

                        Spacer()

                        Text("\(session.score)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text(session.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.58))
                    }
                }
            }
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

                LabeledContent("Permission", value: locationService.authorizationStatusText)
                LabeledContent("Accuracy", value: locationService.accuracyAuthorizationText)
                LabeledContent("Current Fix", value: locationService.accuracySummary)
                LabeledContent("Coordinate", value: locationService.coordinateSummary)

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

// MARK: - Shared View Helpers

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
