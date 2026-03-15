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

    // MARK: - Cached Counts

    /// Number of boxes NOT yet on goals (decremented by setTile automatically).
    private(set) var boxesRemaining: Int = 0

    /// Total number of goal positions (constant for the level).
    private(set) var totalGoals: Int = 0

    var isComplete: Bool { boxesRemaining == 0 }

    /// Create a GameState and pre-compute cached counts from the grid.
    init(grid: [[Tile]], playerPosition: Position, moveCount: Int, levelIndex: Int) {
        self.grid = grid
        self.playerPosition = playerPosition
        self.moveCount = moveCount
        self.levelIndex = levelIndex
        self.boxesRemaining = 0
        self.totalGoals = 0
        recomputeCounts()
    }

    /// Backwards-compatible decoding: recompute cached counts if missing from old saves.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        grid = try container.decode([[Tile]].self, forKey: .grid)
        playerPosition = try container.decode(Position.self, forKey: .playerPosition)
        moveCount = try container.decode(Int.self, forKey: .moveCount)
        levelIndex = try container.decode(Int.self, forKey: .levelIndex)
        boxesRemaining = try container.decodeIfPresent(Int.self, forKey: .boxesRemaining) ?? 0
        totalGoals = try container.decodeIfPresent(Int.self, forKey: .totalGoals) ?? 0
        recomputeCounts()
    }

    private mutating func recomputeCounts() {
        var boxCount = 0
        var goalCount = 0
        for row in grid {
            for tile in row {
                if tile == .box { boxCount += 1 }
                if tile.isGoal { goalCount += 1 }
            }
        }
        boxesRemaining = boxCount
        totalGoals = goalCount
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

        let old = grid[pos.row][pos.col]
        grid[pos.row][pos.col] = tile

        // Keep boxesRemaining in sync
        if old == .box && tile != .box { boxesRemaining -= 1 }
        if old != .box && tile == .box { boxesRemaining += 1 }
    }

    var difficultyTier: String {
        switch levelIndex {
        case ..<49:  return "Beginner"
        case ..<91:  return "Standard"
        default:     return "Expert"
        }
    }

    // MARK: - BFS Pathfinding (O(V) memory via cameFrom dictionary)

    /// Returns the shortest path from the player to the target,
    /// walking only on walkable tiles. Returns nil if unreachable.
    func findPath(to target: Position) -> [Direction]? {
        let start = playerPosition
        guard start != target else { return [] }

        let targetTile = tile(at: target)
        guard targetTile == .floor || targetTile == .goal else { return nil }

        var cameFrom: [Position: (from: Position, dir: Direction)] = [:]
        var visited: Set<Position> = [start]
        var queue: [Position] = [start]
        var head = 0

        while head < queue.count {
            let current = queue[head]
            head += 1

            for direction in Direction.allCases {
                let next = current.moved(direction)
                guard !visited.contains(next) else { continue }
                guard tile(at: next).isWalkable else { continue }

                visited.insert(next)
                cameFrom[next] = (current, direction)

                if next == target {
                    // Reconstruct path by walking backwards
                    var path: [Direction] = []
                    var pos = target
                    while let step = cameFrom[pos] {
                        path.append(step.dir)
                        pos = step.from
                    }
                    return path.reversed()
                }

                queue.append(next)
            }
        }

        return nil
    }

    // MARK: - Box Push Detection

    /// Checks if the player can push a box in a straight line toward the target.
    /// Returns the push direction and number of steps, or nil if not possible.
    ///
    /// Conditions:
    /// - There is a box adjacent to the player
    /// - The target is along the same line as player→box, further in that direction
    /// - Every tile from box+1 to target (inclusive) is walkable (floor or goal)
    func findBoxPush(to target: Position) -> (direction: Direction, steps: Int)? {
        for direction in Direction.allCases {
            let boxPos = playerPosition.moved(direction)

            // Must have a box next to the player in this direction
            guard tile(at: boxPos).isBox else { continue }

            // Target must be along the same line beyond the box
            switch direction {
            case .up:
                guard target.col == boxPos.col, target.row < boxPos.row else { continue }
            case .down:
                guard target.col == boxPos.col, target.row > boxPos.row else { continue }
            case .left:
                guard target.row == boxPos.row, target.col < boxPos.col else { continue }
            case .right:
                guard target.row == boxPos.row, target.col > boxPos.col else { continue }
            }

            // Count steps from box to target
            let steps: Int
            if direction == .up || direction == .down {
                steps = abs(target.row - boxPos.row)
            } else {
                steps = abs(target.col - boxPos.col)
            }

            // Verify every tile the box would move through is clear
            var checkPos = boxPos
            var pathClear = true
            for _ in 0..<steps {
                checkPos = checkPos.moved(direction)
                let t = tile(at: checkPos)
                if t != .floor && t != .goal {
                    pathClear = false
                    break
                }
            }

            if pathClear && steps > 0 {
                return (direction, steps)
            }
        }
        return nil
    }
}
