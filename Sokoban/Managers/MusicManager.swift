import AVFoundation
import Foundation

/// Generates and plays a looping ambient background music track
/// using AVAudioEngine — no bundled audio files required.
final class MusicManager {
    static let shared = MusicManager()
    static let musicEnabledKey = "musicEnabled"

    var isMusicEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Self.musicEnabledKey) as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.musicEnabledKey)
            if newValue { play() } else { stop() }
        }
    }

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var buffer: AVAudioPCMBuffer?
    private var isPlaying = false

    private init() {}

    // MARK: - Audio Session

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default, options: .mixWithOthers)
            try session.setActive(true)
        } catch {
            print("[MusicManager] Audio session error: \(error)")
        }
    }

    // MARK: - Public

    func play() {
        guard isMusicEnabled, !isPlaying else { return }
        configureAudioSession()
        setupEngineIfNeeded()
        guard let player = playerNode, let buf = buffer, let engine = audioEngine else {
            print("[MusicManager] Engine/player/buffer is nil, cannot play")
            return
        }
        do {
            if !engine.isRunning {
                try engine.start()
            }
            player.stop() // reset any prior schedule
            player.scheduleBuffer(buf, at: nil, options: .loops)
            player.volume = 0.35
            player.play()
            isPlaying = true
        } catch {
            print("[MusicManager] Failed to start engine: \(error)")
        }
    }

    func stop() {
        guard isPlaying, let player = playerNode else { return }
        player.stop()
        audioEngine?.stop()
        isPlaying = false
    }

    func pause() {
        guard isPlaying, let player = playerNode else { return }
        player.pause()
        isPlaying = false
    }

    func resume() {
        guard isMusicEnabled, !isPlaying else { return }
        guard let player = playerNode, let engine = audioEngine else {
            play()
            return
        }
        do {
            if !engine.isRunning { try engine.start() }
            player.play()
            isPlaying = true
        } catch {
            print("[MusicManager] Failed to resume: \(error)")
        }
    }

    // MARK: - Audio Generation

    private func setupEngineIfNeeded() {
        guard audioEngine == nil else { return }

        let sampleRate: Double = 44100
        let duration: Double = 16.0 // loop length in seconds
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buf.frameLength = frameCount

        guard let leftChannel = buf.floatChannelData?[0],
              let rightChannel = buf.floatChannelData?[1] else { return }

        // Generate a calm ambient loop
        generateAmbientTrack(left: leftChannel, right: rightChannel,
                             frameCount: Int(frameCount), sampleRate: sampleRate)

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.prepare()

        self.audioEngine = engine
        self.playerNode = player
        self.buffer = buf
    }

    /// Procedurally generates a gentle ambient soundtrack.
    ///
    /// Uses layered sine waves in a pentatonic scale with slow LFO modulation,
    /// subtle pad chords, and a soft sub-bass — creating a calm puzzle-game atmosphere.
    private func generateAmbientTrack(left: UnsafeMutablePointer<Float>,
                                       right: UnsafeMutablePointer<Float>,
                                       frameCount: Int, sampleRate: Double) {
        // Pentatonic scale frequencies (C major pentatonic, octave 3–4)
        let notes: [Double] = [
            130.81, 146.83, 164.81, 196.00, 220.00,  // C3 D3 E3 G3 A3
            261.63, 293.66, 329.63, 392.00, 440.00,  // C4 D4 E4 G4 A4
        ]

        // Chord progressions (indices into notes array)
        let chords: [[Int]] = [
            [0, 2, 5],   // C  - E  - C4
            [3, 5, 7],   // G  - C4 - E4
            [1, 4, 6],   // D  - A  - D4
            [0, 3, 5],   // C  - G  - C4
            [4, 7, 9],   // A  - E4 - A4
            [2, 5, 8],   // E  - C4 - G4
        ]

        let beatsPerChord = Int(sampleRate * 2.667)  // ~2.67s per chord, 6 chords ≈ 16s

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            var sample: Float = 0

            // --- Pad layer: slowly evolving chords ---
            let chordIndex = (i / beatsPerChord) % chords.count
            let chord = chords[chordIndex]
            let chordFade = smoothstep(Double(i % beatsPerChord) / Double(beatsPerChord))

            for noteIdx in chord {
                let freq = notes[noteIdx]
                let phase = t * freq * 2.0 * .pi
                // Mix sine + softened triangle for warmth
                let sine = sin(phase)
                let tri = 2.0 * abs(2.0 * (t * freq - floor(t * freq + 0.5))) - 1.0
                let padVoice = Float(sine * 0.6 + tri * 0.15)
                // Gentle tremolo
                let tremolo = Float(1.0 + 0.15 * sin(t * 0.8 * 2 * .pi))
                sample += padVoice * tremolo * Float(0.18 * chordFade)
            }

            // --- Sub bass: root note, very quiet ---
            let rootFreq = notes[chords[chordIndex][0]]
            let bassSample = Float(sin(t * rootFreq * 0.5 * 2 * .pi)) * 0.10
            sample += bassSample

            // --- High sparkle: random arpeggio notes fading in and out ---
            let sparkleFreq = notes[(i / Int(sampleRate * 0.5)) % notes.count] * 2.0
            let sparkleEnv = Float(sin(t * 0.3 * 2 * .pi) * 0.5 + 0.5) * 0.04
            sample += Float(sin(t * sparkleFreq * 2 * .pi)) * sparkleEnv

            // --- Stereo widening via slight delay ---
            let stereoShift = Float(sin(t * 0.1 * 2 * .pi)) * 0.3
            left[i] = sample * (1.0 + stereoShift) * 0.5
            right[i] = sample * (1.0 - stereoShift) * 0.5
        }

        // Apply fade-in at start and fade-out near the end of the loop for seamless looping
        let fadeSamples = Int(sampleRate * 0.5)
        for i in 0..<fadeSamples {
            let factor = Float(i) / Float(fadeSamples)
            left[i] *= factor
            right[i] *= factor
            let endIdx = frameCount - 1 - i
            left[endIdx] *= factor
            right[endIdx] *= factor
        }
    }

    private func smoothstep(_ t: Double) -> Double {
        let clamped = max(0, min(1, t))
        return clamped * clamped * (3.0 - 2.0 * clamped)
    }
}
