import SwiftUI
import SpriteKit

struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var scene: GameScene = {
        let s = GameScene()
        s.scaleMode = .resizeFill
        return s
    }()

    @State private var showLevelComplete = false
    @State private var showMenu = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // SpriteKit game board
                SpriteView(scene: scene)
                    .ignoresSafeArea()
                    .onAppear {
                        scene.gameManager = gameManager
                        scene.size = geo.size
                        scene.refreshFullBoard()
                    }
                    .onChange(of: gameManager.isLevelComplete) { _, complete in
                        if complete { showLevelComplete = true }
                    }

                // --- On-field HUD ---
                VStack(spacing: 0) {
                    // ── Top bar ──
                    HStack(alignment: .top, spacing: 10) {
                        // Level badge
                        GameBadge {
                            VStack(spacing: 0) {
                                Text("LEVEL")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.55))
                                Text("\(gameManager.state.levelIndex + 1)")
                                    .font(.system(size: 36, weight: .black, design: .rounded).monospacedDigit())
                                    .foregroundStyle(.white)
                            }
                        }

                        Spacer()

                        // Action buttons
                        HStack(spacing: 8) {
                            GameIconButton(
                                icon: "arrow.uturn.backward",
                                label: "UNDO",
                                disabled: !gameManager.canUndo
                            ) {
                                guard gameManager.canUndo else { return }
                                gameManager.undo()
                                scene.refreshFullBoard()
                            }

                            GameIconButton(icon: "arrow.counterclockwise", label: "RETRY") {
                                gameManager.restart()
                                scene.refreshFullBoard()
                            }

                            GameIconButton(icon: "viewfinder", label: "FIT") {
                                scene.resetZoom()
                            }

                            GameIconButton(icon: "ellipsis", label: "MENU") {
                                showMenu = true
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, geo.safeAreaInsets.top > 0 ? geo.safeAreaInsets.top + 4 : 14)

                    Spacer()

                    // ── Bottom bar ──
                    HStack(alignment: .bottom, spacing: 0) {
                        // D-pad
                        GameDPad { direction in
                            guard !gameManager.isAnimating else { return }
                            scene.performMoveFromDPad(direction)
                        }
                        .padding(.leading, 14)

                        Spacer()

                        // Stats
                        VStack(spacing: 8) {
                            GameStatBadge(
                                icon: "figure.walk",
                                label: "MOVES",
                                value: "\(gameManager.state.moveCount)"
                            )
                            GameStatBadge(
                                icon: "shippingbox.fill",
                                label: "BOXES",
                                value: "\(gameManager.state.totalGoals - gameManager.state.boxesRemaining)/\(gameManager.state.totalGoals)"
                            )
                        }
                        .padding(.trailing, 14)
                    }
                    .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? geo.safeAreaInsets.bottom + 4 : 14)
                }
            }
            .ignoresSafeArea()
        }
        .navigationBarHidden(true)
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
        .onChange(of: themeManager.currentTheme) { _, _ in
            scene.refreshFullBoard()
        }
        .alert("Level Complete! 🎉", isPresented: $showLevelComplete) {
            if gameManager.hasNextLevel {
                Button("Next Level") {
                    scene.clearCelebration()
                    gameManager.advanceToNextLevel()
                    scene.refreshFullBoard()
                }
            }
            Button("Level Select") {
                scene.clearCelebration()
                dismiss()
            }
        } message: {
            Text("Completed in \(gameManager.state.moveCount) moves!")
        }
        .confirmationDialog("Menu", isPresented: $showMenu) {
            Button("Restart Level") {
                gameManager.restart()
                scene.refreshFullBoard()
            }
            Button("Main Menu") {
                PersistenceManager.shared.saveGame(gameManager.state)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Game-Styled HUD Components

/// Semi-transparent rounded badge container.
struct GameBadge<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.black.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    )
            )
    }
}

/// Big icon button with label underneath.
struct GameIconButton: View {
    let icon: String
    let label: String
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white.opacity(disabled ? 0.25 : 0.9))
                Text(label)
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(disabled ? 0.2 : 0.5))
            }
            .frame(width: 54, height: 54)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.black.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .disabled(disabled)
    }
}

/// Stat counter with icon, big number, and label.
struct GameStatBadge: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white.opacity(0.45))

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 24, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                Text(label)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

/// Game-styled D-pad with bigger buttons.
struct GameDPad: View {
    let onDirection: (Direction) -> Void

    private let btnSize: CGFloat = 58
    private let spacing: CGFloat = 5

    var body: some View {
        VStack(spacing: spacing) {
            dpadBtn(.up, icon: "chevron.up")
            HStack(spacing: spacing) {
                dpadBtn(.left, icon: "chevron.left")
                // Center space
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white.opacity(0.04))
                    .frame(width: btnSize, height: btnSize)
                dpadBtn(.right, icon: "chevron.right")
            }
            dpadBtn(.down, icon: "chevron.down")
        }
    }

    private func dpadBtn(_ direction: Direction, icon: String) -> some View {
        Button {
            onDirection(direction)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: btnSize, height: btnSize)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.black.opacity(0.45))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        )
                )
        }
    }
}
