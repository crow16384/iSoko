import Foundation

enum Direction: String, CaseIterable, Codable {
    case up, down, left, right

    var rowDelta: Int {
        switch self {
        case .up:          return -1
        case .down:        return  1
        case .left, .right: return  0
        }
    }

    var colDelta: Int {
        switch self {
        case .left:      return -1
        case .right:     return  1
        case .up, .down: return  0
        }
    }

    var opposite: Direction {
        switch self {
        case .up:    return .down
        case .down:  return .up
        case .left:  return .right
        case .right: return .left
        }
    }
}
