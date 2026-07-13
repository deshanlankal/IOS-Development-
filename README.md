# PlayHub

PlayHub is a SwiftUI iOS app shell that combines three game modes into one app: Tap Frenzy, Light It Up, and Quiz Rush.

## Architecture

- `App`: app entry point and root `ContentView`.
- `Models`: `GameMode`, `GameSession`, `ModeStats`, and `TriviaQuestion`.
- `ViewModels`: state and game logic for Tap Frenzy, Light It Up, and Quiz Rush.
- `Services`: `SessionStore`, `TriviaService`, `LocationService`, and `NotificationService`.
- `Views`: tab screens, game screens, stats, map, settings, result, and shared UI components.

The Xcode project currently has a target membership issue where newly split files are not compiled. To keep the app buildable, these architecture sections are implemented as separate types inside the compiled app source file. Once target membership is repaired in Xcode, the types can be moved into the required physical folders without changing behavior.

## Features

- Four-tab app shell: Home, Stats, Map, Settings.
- Three playable game modes.
- `GameSession` persistence using JSON encoded into `UserDefaults`.
- Stats dashboard using Swift Charts.
- Map tab using MapKit annotations for saved sessions.
- Settings screen with notification toggle, reminder time picker, location action, and reset confirmation.
- Daily local notifications using UserNotifications.
- Result screen with `ShareLink`.

## Known Limitations

- Live location requires `NSLocationWhenInUseUsageDescription` in the app Info.plist. Until that key is added, the app uses fallback coordinates for saved sessions.
- Trivia uses the Open Trivia DB API and falls back to built-in questions if networking fails.
- The folder hierarchy exists in the project navigator, but the current target membership configuration prevents those separate files from compiling.

## Reflection

This version changes the app from separate portfolio games into a real app shell. The main design decision is to treat every completed game as a `GameSession`, then let Stats, Map, Settings, and sharing all work from that same persisted model.
