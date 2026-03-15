import SwiftUI
import SpriteKit

struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss

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
                        if complete {
                            showLevelComplete = true
                        }
                    }

                // HUD overlay
                VStack {
                    HStack(spacing: 16) {
                        HUDLabel(title: "Level", value: "\(gameManager.state.levelIndex + 1)")
                        HUDLabel(title: "Moves", value: "\(gameManager.state.moveCount)")
                        HUDLabel(title: "Boxes", value: "\(gameManager.state.boxesRemaining)/\(gameManager.state.totalGoals)")

                        Spacer()

                        HStack(spacing: 12) {
                            Button {
                                if gameManager.canUndo {
                                    gameManager.undo()
                                    scene.refreshFullBoard()
                                }
                            } label: {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                    .font(.title)
                            }
                            .disabled(!gameManager.canUndo)

                            Button {
                                gameManager.restart()
                                scene.refreshFullBoard()
                            } label: {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.title)
                            }

                            Button {
                                showMenu = true
                            } label: {
                                Image(systemName: "line.3.horizontal.circle.fill")
                                    .font(.title)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)

                    Spacer()

                    // Difficulty tier badge
                    HStack {
                        Spacer()
                        Text(gameManager.state.difficultyTier)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(16)
                    }
                }
            }
        }
        .navigationBarHidden(true)
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

struct HUDLabel: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(.semibold).monospacedDigit())
        }
    }
}
