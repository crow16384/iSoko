import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("soundEnabled") private var soundEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Audio") {
                    Toggle(isOn: $soundEnabled) {
                        Label("Sound Effects", systemImage: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    }
                    .onChange(of: soundEnabled) { _, newValue in
                        SoundManager.shared.soundEnabled = newValue
                        if newValue {
                            // Play a sample sound so user hears it
                            SoundManager.shared.playStep()
                        }
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Levels")
                        Spacer()
                        Text("138")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
