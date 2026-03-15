import SwiftUI

@main
struct SokobanApp: App {
    @StateObject private var gameManager = GameManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainMenuView()
            }
            .environmentObject(gameManager)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background || newPhase == .inactive {
                    PersistenceManager.shared.saveGame(gameManager.state)
                }
            }
        }
    }
}
