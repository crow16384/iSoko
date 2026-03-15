import AVFoundation
import AudioToolbox

final class SoundManager {
    static let shared = SoundManager()

    private var isSoundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "soundEnabled") }
    }

    // System sound IDs for lightweight audio
    private let stepSoundID: SystemSoundID = 1104      // Tock
    private let pushSoundID: SystemSoundID = 1306      // Tink (heavier)
    private let blockedSoundID: SystemSoundID = 1073    // Low beep
    private let levelCompleteSoundID: SystemSoundID = 1025  // Fanfare-like

    private var synthesizer: AVAudioEngine?
    private var tonePlayer: AVTonePlayerNode?

    private init() {
        // Configure audio session
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    var soundEnabled: Bool {
        get { isSoundEnabled }
        set { isSoundEnabled = newValue }
    }

    func playStep() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(stepSoundID)
    }

    func playPush() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(pushSoundID)
    }

    func playBlocked() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(blockedSoundID)
    }

    func playLevelComplete() {
        guard isSoundEnabled else { return }
        // Play a sequence of tones for celebration effect
        AudioServicesPlaySystemSound(levelCompleteSoundID)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            AudioServicesPlaySystemSound(1025)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            AudioServicesPlaySystemSound(1057)
        }
    }
}

// Simple tone player node for custom sounds
private class AVTonePlayerNode: AVAudioPlayerNode {
    // Placeholder for future custom tone generation
}
