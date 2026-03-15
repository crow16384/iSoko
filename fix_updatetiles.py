#!/usr/bin/env python3

filepath = 'Sokoban/Scenes/GameScene.swift'
with open(filepath, 'r') as f:
    content = f.read()

old = """                node.removeAllChildren()
                decorateTile(node, tile: tile, row: r, col: c)
                node.zPosition = tile.isBox ? 5 : 1"""

new = """                node.removeAllChildren()
                let baseTile: Tile = tile.isBox ? (tile == .boxOnGoal ? .goal : .floor) : tile
                decorateTile(node, tile: baseTile, row: r, col: c)
                node.zPosition = 1"""

if old in content:
    content = content.replace(old, new)
    with open(filepath, 'w') as f:
        f.write(content)
    print("Successfully updated updateChangedTiles")
else:
    print("ERROR: Could not find old updateChangedTiles content")
