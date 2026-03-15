import Foundation

struct Position: Equatable, Codable, Hashable {
    var row: Int
    var col: Int

    func moved(_ direction: Direction) -> Position {
        Position(row: row + direction.rowDelta, col: col + direction.colDelta)
    }
}

struct GameState: Codable {
    var grid: [[Tile]]
    var playerPosition: Position
    var moveCount: Int
    var levelIndex: Int

    static let columns = 20
    static let rows = 16

    var boxesRemaining: Int {
        var count = 0
        for row in grid {
            for tile in row {
                if tile == .box { count += 1 }
            }
        }
        return count
    }

    var totalGoals: Int {
        var count = 0
        for row in grid {
            for tile in row {
                if tile.isGoal { count += 1 }
            }
        }
        return count
    }

    var isComplete: Bool {
        boxesRemaining == 0
    }

    func tile(at pos: Position) -> Tile {
        guard pos.row >= 0, pos.row < GameState.rows,
              pos.col >= 0, pos.col < GameState.columns else {
            return .wall
        }
        return grid[pos.row][pos.col]
    }

    mutating func setTile(_ tile: Tile, at pos: Position) {
        guard pos.row >= 0, pos.row < GameState.rows,
              pos.col >= 0, pos.col < GameState.columns else { return }
        grid[pos.row][pos.col] = tile
    }

    var difficultyTier: String {
        if levelIndex < 49 { return "Beginner" }
        if levelIndex < 91 { return "Standard" }
        return "Expert"
    }

    // MARK: - BFS Pathfinding

    /// Returns the shortest path (as a list of Directions) from the player position
    /// to the target position, walking only on walkable tiles (no walls, no boxes).
    /// Returns nil if no path exists.
    func findPath(to target: Position) -> [Direction]? {
        let start = playerPosition
        guard start != target else { return [] }

        // Target must be walkable (floor or goal)
        let targetTile = tile(at: target)
        guard targetTile == .floor || targetTile == .goal else { return nil }

        var visited: Set<Position> = [start]
        // Each element: (position, directions taken so far)
        var queue: [(position: Position, path: [Direction])] = [(start, [])]
        var head = 0

        while head < queue.count {
            let current = queue[head]
            head += 1

            for direction in Direction.allCases {
                let next = current.position.moved(direction)

                guard !visited.contains(next) else { continue }

                let nextTile = tile(at: next)
                // Can only walk on floor, goal, player, playerOnGoal tiles
                guard nextTile.isWalkable else { continue }

                let newPath = current.path + [direction]

                if next == target {
                    return newPath
                }

                visited.insert(next)
                queue.append((next, newPath))
            }
        }

        return nil // No path found
    }
}
