#!/usr/bin/env python3
import sys

filepath = 'Sokoban/Scenes/GameScene.swift'
with open(filepath, 'r') as f:
    lines = f.readlines()

# Find the second occurrence of "HapticsManager.shared.boxPushed()" 
# which is in pushBoxAlongPath
count = 0
insert_after = -1
for i, line in enumerate(lines):
    if 'HapticsManager.shared.boxPushed()' in line:
        count += 1
        if count == 2:
            insert_after = i
            break

if insert_after == -1:
    print("Could not find second boxPushed() call")
    sys.exit(1)

# Insert the animateBoxSlide lines after that line
new_lines = [
    '\n',
    '        let boxOldPos = manager.state.playerPosition\n',
    '        let boxNewPos = boxOldPos.moved(direction)\n',
    '        animateBoxSlide(from: boxOldPos, to: boxNewPos, state: manager.state)\n',
]

lines = lines[:insert_after+1] + new_lines + lines[insert_after+1:]

with open(filepath, 'w') as f:
    f.writelines(lines)

print(f"Inserted animateBoxSlide after line {insert_after+1}")
