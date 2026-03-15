#!/usr/bin/env python3

filepath = 'Sokoban/Views/GameView.swift'
with open(filepath, 'r') as f:
    content = f.read()

old = """                    Spacer()

                    // Difficulty tier badge
                    HStack {
                        Spacer()
                        Text(gameManager.state.difficultyTier)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(16)
                    }"""

new = """                    Spacer()

                    // D-pad + difficulty tier
                    HStack(alignment: .bottom) {
                        DPadView { direction in
                            guard !gameManager.isAnimating else { return }
                            scene.performMoveFromDPad(direction)
                        }
                        .padding(16)

                        Spacer()

                        Text(gameManager.state.difficultyTier)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(16)
                    }"""

if old in content:
    content = content.replace(old, new)
    with open(filepath, 'w') as f:
        f.write(content)
    print("Successfully added D-pad to GameView body")
else:
    print("ERROR: Could not find old content")
