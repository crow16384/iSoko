import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var gameManager: GameManager

    @State private var showLevelSelect = false
    @State private var showAbout = false
    @State private var showSettings = false

    private var hasSavedGame: Bool {
        PersistenceManager.shared.loadGame() != nil
    }

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("SOKOBAN")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("138 Puzzle Levels")
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()

            VStack(spacing: 16) {
                NavigationLink {
                    GameView()
                        .onAppear { gameManager.loadLevel(0) }
                } label: {
                    MenuButton(title: "New Game", systemImage: "play.fill")
                }

                if hasSavedGame {
                    NavigationLink {
                        GameView()
                            .onAppear {
                                if let saved = PersistenceManager.shared.loadGame() {
                                    gameManager.state = saved
                                    gameManager.isLevelComplete = false
                                }
                            }
                    } label: {
                        MenuButton(title: "Continue", systemImage: "arrow.forward.circle.fill")
                    }
                }

                Button {
                    showLevelSelect = true
                } label: {
                    MenuButton(title: "Select Level", systemImage: "list.number")
                }

                Button {
                    showAbout = true
                } label: {
                    MenuButton(title: "About", systemImage: "info.circle")
                }

                Button {
                    showSettings = true
                } label: {
                    MenuButton(title: "Settings", systemImage: "gearshape")
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: UIColor.systemGroupedBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showLevelSelect) {
            LevelSelectView()
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

struct MenuButton: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.title2)
                .frame(width: 32)
            Text(title)
                .font(.title2.weight(.semibold))
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
