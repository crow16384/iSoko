import Foundation

final class LevelManager {
    static let shared = LevelManager()

    private(set) var levels: [[[Tile]]] = []

    private init() {
        loadLevels()
    }

    var levelCount: Int { levels.count }

    func makeGameState(forLevel index: Int) -> GameState {
        let grid = levels[index]
        var playerPos = Position(row: 0, col: 0)
        for r in 0..<GameState.rows {
            for c in 0..<GameState.columns {
                if grid[r][c].hasPlayer {
                    playerPos = Position(row: r, col: c)
                }
            }
        }
        return GameState(grid: grid, playerPosition: playerPos, moveCount: 0, levelIndex: index)
    }

    private func loadLevels() {
        guard let url = Bundle.main.url(forResource: "Levels", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return
        }

        let lines = content.components(separatedBy: "\n")
        var currentRows: [[Tile]] = []

        for line in lines {
            if line.hasPrefix(";") || line.isEmpty {
                // If we accumulated 16 rows, save as a level
                if currentRows.count == GameState.rows {
                    levels.append(currentRows)
                    currentRows = []
                }
                continue
            }

            // Pad or trim to exactly 20 characters
            var padded = line
            if padded.count < GameState.columns {
                padded += String(repeating: " ", count: GameState.columns - padded.count)
            }

            let row: [Tile] = padded.prefix(GameState.columns).map { ch in
                Tile(rawValue: ch) ?? .wall
            }
            currentRows.append(row)
        }

        // Catch last level if file doesn't end with blank line
        if currentRows.count == GameState.rows {
            levels.append(currentRows)
        }
    }
}
