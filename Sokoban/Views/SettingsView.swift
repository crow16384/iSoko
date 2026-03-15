import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SoundManager.soundEnabledKey) private var soundEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Audio") {
                    Toggle(isOn: $soundEnabled) {
                        Label(
                            "Sound Effects",
                            systemImage: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
                        )
                    }
                    .onChange(of: soundEnabled) { _, newValue in
                        if newValue {
                            SoundManager.shared.playStep()
                        }
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Levels", value: "\(LevelManager.shared.levelCount)")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
