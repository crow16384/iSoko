import AVFoundation
import AudioToolbox

final class SoundManager {
    static let shared = SoundManager()

    static let soundEnabledKey = "soundEnabled"

    var isSoundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Self.soundEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Self.soundEnabledKey) }
    }

    private let stepSoundID: SystemSoundID = 1104
    private let pushSoundID: SystemSoundID = 1306
    private let blockedSoundID: SystemSoundID = 1073
    private let levelCompleteSoundID: SystemSoundID = 1025

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
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
        AudioServicesPlaySystemSound(levelCompleteSoundID)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard self?.isSoundEnabled == true else { return }
            AudioServicesPlaySystemSound(1025)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard self?.isSoundEnabled == true else { return }
            AudioServicesPlaySystemSound(1057)
        }
    }
}
