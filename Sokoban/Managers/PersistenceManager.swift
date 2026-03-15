import Foundation

final class PersistenceManager {
    static let shared = PersistenceManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let savedState = "savedGameState"
        static let highestCompleted = "highestCompletedLevel"
        static let completedLevels = "completedLevels"
    }

    private init() {}

    func saveGame(_ state: GameState) {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: Keys.savedState)
        }
    }

    func loadGame() -> GameState? {
        guard let data = defaults.data(forKey: Keys.savedState) else { return nil }
        return try? JSONDecoder().decode(GameState.self, from: data)
    }

    func clearSave() {
        defaults.removeObject(forKey: Keys.savedState)
    }

    func markLevelCompleted(_ index: Int, moves: Int) {
        var completed = completedLevels
        let existing = completed[String(index)]
        if existing == nil || moves < existing! {
            completed[String(index)] = moves
            defaults.set(completed, forKey: Keys.completedLevels)
        }
        let highest = highestCompletedLevel
        if index > highest {
            defaults.set(index, forKey: Keys.highestCompleted)
        }
    }

    var highestCompletedLevel: Int {
        defaults.integer(forKey: Keys.highestCompleted)
    }

    var completedLevels: [String: Int] {
        defaults.dictionary(forKey: Keys.completedLevels) as? [String: Int] ?? [:]
    }

    func bestMoves(forLevel index: Int) -> Int? {
        completedLevels[String(index)]
    }

    func isLevelCompleted(_ index: Int) -> Bool {
        completedLevels[String(index)] != nil
    }
}
