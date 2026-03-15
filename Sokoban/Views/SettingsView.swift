import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @AppStorage(SoundManager.soundEnabledKey) private var soundEnabled = true
    @AppStorage(MusicManager.musicEnabledKey) private var musicEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                // Audio section
                Section {
                    Toggle(isOn: $musicEnabled) {
                        Label {
                            Text("Background Music")
                        } icon: {
                            Image(systemName: musicEnabled ? "music.note" : "music.note.slash")
                                .foregroundStyle(musicEnabled ? .blue : .secondary)
                        }
                    }
                    .onChange(of: musicEnabled) { _, newValue in
                        MusicManager.shared.isMusicEnabled = newValue
                    }

                    Toggle(isOn: $soundEnabled) {
                        Label {
                            Text("Sound Effects")
                        } icon: {
                            Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .foregroundStyle(soundEnabled ? .blue : .secondary)
                        }
                    }
                    .onChange(of: soundEnabled) { _, newValue in
                        if newValue {
                            SoundManager.shared.playStep()
                        }
                    }
                } header: {
                    Label("Audio", systemImage: "speaker.wave.3.fill")
                        .font(.subheadline.weight(.semibold))
                }

                // Theme section
                Section {
                    ForEach(AppTheme.allCases) { theme in
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                themeManager.currentTheme = theme
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: theme.systemImage)
                                    .font(.title3)
                                    .foregroundStyle(theme == .light ? .orange : .indigo)
                                    .frame(width: 30)

                                Text(theme.displayName)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if themeManager.currentTheme == theme {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                        .font(.title3)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Label("Appearance", systemImage: "paintbrush.fill")
                        .font(.subheadline.weight(.semibold))
                }

                // Info section
                Section {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Levels", value: "\(LevelManager.shared.levelCount)")
                } header: {
                    Label("About", systemImage: "info.circle")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(themeManager.currentTheme.colorScheme)
    }
}
