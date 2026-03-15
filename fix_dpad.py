#!/usr/bin/env python3

filepath = 'Sokoban/Scenes/GameScene.swift'
with open(filepath, 'r') as f:
    lines = f.readlines()

# Insert performMoveFromDPad before the "/// Centralised" comment at line 701
insert_at = 700  # 0-indexed for line 701

new_lines = [
    '    /// Called from the SwiftUI D-pad overlay.\n',
    '    func performMoveFromDPad(_ direction: Direction) {\n',
    '        guard let manager = gameManager,\n',
    '              !manager.isAnimating, !isMovingAlongPath else { return }\n',
    '        performMove(direction, on: manager)\n',
    '    }\n',
    '\n',
]

lines = lines[:insert_at] + new_lines + lines[insert_at:]

with open(filepath, 'w') as f:
    f.writelines(lines)

print(f"Inserted performMoveFromDPad before line {insert_at+1}")
