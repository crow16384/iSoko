import Foundation

enum Tile: Character, Codable, Equatable {
    case wall = "@"
    case floor = " "
    case goal = "x"
    case box = "o"
    case boxOnGoal = "#"
    case player = "$"
    case playerOnGoal = "+"

    var isWalkable: Bool {
        switch self {
        case .floor, .goal, .player, .playerOnGoal:
            return true
        default:
            return false
        }
    }

    var isBox: Bool {
        self == .box || self == .boxOnGoal
    }

    var isGoal: Bool {
        self == .goal || self == .boxOnGoal || self == .playerOnGoal
    }

    var hasPlayer: Bool {
        self == .player || self == .playerOnGoal
    }

    /// What this tile becomes when the player leaves it
    var withoutPlayer: Tile {
        self == .playerOnGoal ? .goal : .floor
    }

    /// What this tile becomes when the player enters it
    var withPlayer: Tile {
        self == .goal ? .playerOnGoal : .player
    }

    /// What this tile becomes when a box leaves it
    var withoutBox: Tile {
        self == .boxOnGoal ? .goal : .floor
    }

    /// What this tile becomes when a box enters it
    var withBox: Tile {
        self == .goal ? .boxOnGoal : .box
    }
}
