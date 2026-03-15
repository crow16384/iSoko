import Foundation
import Combine

final class GameManager: ObservableObject {
    @Published var state: GameState
    @Published var isLevelComplete = false
    @Published var isAnimating = false

    private var undoStack: [GameState] = []

    var canUndo: Bool { !undoStack.isEmpty }

    init(levelIndex: Int = 0) {
        state = LevelManager.shared.makeGameState(forLevel: levelIndex)
    }

    func loadLevel(_ index: Int) {
        guard index >= 0, index < LevelManager.shared.levelCount else { return }
        state = LevelManager.shared.makeGameState(forLevel: index)
        undoStack.removeAll()
        isLevelComplete = false
    }

    func restart() {
        loadLevel(state.levelIndex)
    }

    func tryMove(_ direction: Direction) -> MoveResult {
        guard !isAnimating, !isLevelComplete else { return .blocked }

        let nextPos = state.playerPosition.moved(direction)
        let nextTile = state.tile(at: nextPos)

        if nextTile == .floor || nextTile == .goal {
            // Simple move
            let saved = state
            undoStack.append(saved)

            let currentTile = state.tile(at: state.playerPosition)
            state.setTile(currentTile.withoutPlayer, at: state.playerPosition)
            state.setTile(nextTile.withPlayer, at: nextPos)
            state.playerPosition = nextPos
            state.moveCount += 1

            return .moved
        }

        if nextTile.isBox {
            // Push attempt — check space beyond box
            let beyondPos = nextPos.moved(direction)
            let beyondTile = state.tile(at: beyondPos)

            if beyondTile == .floor || beyondTile == .goal {
                let saved = state
                undoStack.append(saved)

                // Move box
                state.setTile(nextTile.withoutBox, at: nextPos)
                state.setTile(beyondTile.withBox, at: beyondPos)

                // Move player onto where box was
                let currentTile = state.tile(at: state.playerPosition)
                state.setTile(currentTile.withoutPlayer, at: state.playerPosition)
                let newPlayerTile = state.tile(at: nextPos)
                state.setTile(newPlayerTile.withPlayer, at: nextPos)
                state.playerPosition = nextPos
                state.moveCount += 1

                if state.isComplete {
                    isLevelComplete = true
                }

                return .pushed
            }
        }

        return .blocked
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        state = previous
        isLevelComplete = false
    }

    func advanceToNextLevel() {
        let next = state.levelIndex + 1
        if next < LevelManager.shared.levelCount {
            loadLevel(next)
        }
    }

    var hasNextLevel: Bool {
        state.levelIndex + 1 < LevelManager.shared.levelCount
    }
}

enum MoveResult {
    case moved
    case pushed
    case blocked
}
