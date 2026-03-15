import SwiftUI

@main
struct SokobanApp: App {
    @StateObject private var gameManager = GameManager()
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainMenuView()
            }
            .environmentObject(gameManager)
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .background, .inactive:
                    PersistenceManager.shared.saveGame(gameManager.state)
                    MusicManager.shared.pause()
                case .active:
                    MusicManager.shared.resume()
                @unknown default:
                    break
                }
            }
        }
    }
}
