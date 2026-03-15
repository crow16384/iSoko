import SwiftUI
import UIKit

// MARK: - Theme Definition

enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark:  return "Dark"
        }
    }

    var systemImage: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark:  return "moon.fill"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        case .dark:  return .dark
        }
    }
}

// MARK: - Game Palette (used by GameScene)

struct GamePalette {
    // Walls
    let wallBase: UIColor
    let wallMortar: UIColor
    let wallLight: UIColor
    // Floor
    let floor: UIColor
    let floorLine: UIColor
    // Goal
    let goalRing: UIColor
    // Box
    let boxTop: UIColor
    let boxBottom: UIColor
    let boxStroke: UIColor
    let boxShadow: UIColor
    // Box on goal
    let boxGoalTop: UIColor
    let boxGoalBot: UIColor
    let boxGoalStrk: UIColor
    // Player
    let playerTop: UIColor
    let playerBot: UIColor
    let playerStroke: UIColor
    let playerEye: UIColor
    let playerPupil: UIColor
    let playerCheek: UIColor
    // Background
    let outer: UIColor

    static let dark = GamePalette(
        wallBase:    UIColor(red: 0.38, green: 0.40, blue: 0.44, alpha: 1),
        wallMortar:  UIColor(red: 0.25, green: 0.26, blue: 0.30, alpha: 1),
        wallLight:   UIColor(red: 0.50, green: 0.52, blue: 0.56, alpha: 1),
        floor:       UIColor(red: 0.22, green: 0.23, blue: 0.26, alpha: 1),
        floorLine:   UIColor(red: 0.27, green: 0.28, blue: 0.31, alpha: 1),
        goalRing:    UIColor(red: 0.35, green: 0.62, blue: 0.95, alpha: 1),
        boxTop:      UIColor(red: 0.98, green: 0.76, blue: 0.30, alpha: 1),
        boxBottom:   UIColor(red: 0.90, green: 0.58, blue: 0.15, alpha: 1),
        boxStroke:   UIColor(red: 0.75, green: 0.50, blue: 0.12, alpha: 0.5),
        boxShadow:   UIColor(red: 0.0,  green: 0.0,  blue: 0.0,  alpha: 0.30),
        boxGoalTop:  UIColor(red: 0.42, green: 0.82, blue: 0.52, alpha: 1),
        boxGoalBot:  UIColor(red: 0.25, green: 0.65, blue: 0.38, alpha: 1),
        boxGoalStrk: UIColor(red: 0.18, green: 0.50, blue: 0.28, alpha: 0.5),
        playerTop:   UIColor(red: 0.35, green: 0.68, blue: 1.00, alpha: 1),
        playerBot:   UIColor(red: 0.20, green: 0.45, blue: 0.90, alpha: 1),
        playerStroke: UIColor(red: 0.15, green: 0.35, blue: 0.70, alpha: 0.6),
        playerEye:   UIColor(white: 1.0, alpha: 0.95),
        playerPupil: UIColor(red: 0.12, green: 0.14, blue: 0.20, alpha: 1),
        playerCheek: UIColor(red: 1.0,  green: 0.55, blue: 0.55, alpha: 0.35),
        outer:       UIColor(red: 0.12, green: 0.13, blue: 0.15, alpha: 1)
    )

    static let light = GamePalette(
        wallBase:    UIColor(red: 0.62, green: 0.65, blue: 0.70, alpha: 1),
        wallMortar:  UIColor(red: 0.50, green: 0.52, blue: 0.56, alpha: 1),
        wallLight:   UIColor(red: 0.75, green: 0.77, blue: 0.80, alpha: 1),
        floor:       UIColor(red: 0.93, green: 0.92, blue: 0.90, alpha: 1),
        floorLine:   UIColor(red: 0.87, green: 0.86, blue: 0.83, alpha: 1),
        goalRing:    UIColor(red: 0.25, green: 0.52, blue: 0.85, alpha: 1),
        boxTop:      UIColor(red: 1.00, green: 0.80, blue: 0.35, alpha: 1),
        boxBottom:   UIColor(red: 0.92, green: 0.62, blue: 0.18, alpha: 1),
        boxStroke:   UIColor(red: 0.78, green: 0.55, blue: 0.15, alpha: 0.45),
        boxShadow:   UIColor(red: 0.0,  green: 0.0,  blue: 0.0,  alpha: 0.12),
        boxGoalTop:  UIColor(red: 0.45, green: 0.85, blue: 0.55, alpha: 1),
        boxGoalBot:  UIColor(red: 0.30, green: 0.70, blue: 0.42, alpha: 1),
        boxGoalStrk: UIColor(red: 0.22, green: 0.55, blue: 0.32, alpha: 0.45),
        playerTop:   UIColor(red: 0.30, green: 0.62, blue: 0.98, alpha: 1),
        playerBot:   UIColor(red: 0.18, green: 0.42, blue: 0.85, alpha: 1),
        playerStroke: UIColor(red: 0.12, green: 0.32, blue: 0.65, alpha: 0.5),
        playerEye:   UIColor(white: 1.0, alpha: 0.95),
        playerPupil: UIColor(red: 0.15, green: 0.16, blue: 0.22, alpha: 1),
        playerCheek: UIColor(red: 1.0,  green: 0.50, blue: 0.50, alpha: 0.30),
        outer:       UIColor(red: 0.82, green: 0.83, blue: 0.85, alpha: 1)
    )
}

// MARK: - UI Theme (used by SwiftUI views)

struct UITheme {
    let menuBackground: Color
    let menuCardBackground: Color
    let menuCardStroke: Color
    let titleColor: Color
    let subtitleColor: Color
    let accentColor: Color
    let hudMaterial: Material

    static let dark = UITheme(
        menuBackground:     Color(red: 0.08, green: 0.09, blue: 0.11),
        menuCardBackground: Color(red: 0.16, green: 0.17, blue: 0.20),
        menuCardStroke:     Color.white.opacity(0.08),
        titleColor:         Color.white,
        subtitleColor:      Color.white.opacity(0.5),
        accentColor:        Color(red: 0.35, green: 0.68, blue: 1.0),
        hudMaterial:        .ultraThinMaterial as Material
    )

    static let light = UITheme(
        menuBackground:     Color(red: 0.92, green: 0.93, blue: 0.95),
        menuCardBackground: Color.white,
        menuCardStroke:     Color.black.opacity(0.06),
        titleColor:         Color(red: 0.10, green: 0.12, blue: 0.18),
        subtitleColor:      Color.secondary,
        accentColor:        Color(red: 0.20, green: 0.50, blue: 0.90),
        hudMaterial:        .regularMaterial as Material
    )
}

// MARK: - ThemeManager

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    static let themeKey = "appTheme"

    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: Self.themeKey)
        }
    }

    var gamePalette: GamePalette {
        currentTheme == .dark ? .dark : .light
    }

    var uiTheme: UITheme {
        currentTheme == .dark ? .dark : .light
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.themeKey) ?? AppTheme.dark.rawValue
        currentTheme = AppTheme(rawValue: saved) ?? .dark
    }
}
