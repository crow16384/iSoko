import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var gameManager: GameManager
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var showLevelSelect = false
    @State private var showAbout = false
    @State private var showSettings = false

    private var hasSavedGame: Bool {
        PersistenceManager.shared.loadGame() != nil
    }

    private var theme: UITheme { themeManager.uiTheme }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                theme.menuBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Big game title
                    VStack(spacing: 8) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: min(geo.size.width * 0.12, 80)))
                            .foregroundStyle(theme.accentColor)
                            .shadow(color: theme.accentColor.opacity(0.4), radius: 20)

                        Text("SOKOBAN")
                            .font(.system(size: min(geo.size.width * 0.14, 96), weight: .black, design: .rounded))
                            .foregroundStyle(theme.titleColor)
                            .shadow(color: theme.accentColor.opacity(0.3), radius: 10, x: 0, y: 4)

                        Text("138 PUZZLE LEVELS")
                            .font(.system(size: min(geo.size.width * 0.025, 18), weight: .semibold, design: .rounded))
                            .tracking(4)
                            .foregroundStyle(theme.subtitleColor)
                    }

                    Spacer()
                        .frame(height: geo.size.height * 0.08)

                    // Big buttons
                    VStack(spacing: 14) {
                        NavigationLink {
                            GameView()
                                .onAppear { gameManager.loadLevel(0) }
                        } label: {
                            BigMenuButton(
                                title: "NEW GAME",
                                systemImage: "play.fill",
                                color: theme.accentColor,
                                fullWidth: true
                            )
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
                                BigMenuButton(
                                    title: "CONTINUE",
                                    systemImage: "arrow.forward.circle.fill",
                                    color: Color.green,
                                    fullWidth: true
                                )
                            }
                        }

                        HStack(spacing: 14) {
                            Button { showLevelSelect = true } label: {
                                BigMenuButton(
                                    title: "LEVELS",
                                    systemImage: "square.grid.3x3.fill",
                                    color: Color.orange,
                                    fullWidth: true
                                )
                            }

                            Button { showSettings = true } label: {
                                BigMenuButton(
                                    title: "SETTINGS",
                                    systemImage: "gearshape.fill",
                                    color: Color.gray,
                                    fullWidth: true
                                )
                            }
                        }

                        Button { showAbout = true } label: {
                            Text("About")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(theme.subtitleColor)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, min(geo.size.width * 0.1, 60))

                    Spacer()

                    // Version footer
                    Text("v1.0")
                        .font(.caption2)
                        .foregroundStyle(theme.subtitleColor.opacity(0.5))
                        .padding(.bottom, 12)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                MusicManager.shared.play()
            }
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        .sheet(isPresented: $showLevelSelect) {
            LevelSelectView()
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
    }

}

struct BigMenuButton: View {
    let title: String
    let systemImage: String
    let color: Color
    var fullWidth: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if fullWidth { Spacer() }

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
