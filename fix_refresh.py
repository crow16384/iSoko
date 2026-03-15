#!/usr/bin/env python3

filepath = 'Sokoban/Scenes/GameScene.swift'
with open(filepath, 'r') as f:
    content = f.read()

old_refresh = """    func refreshAfterMove(direction: Direction, pushed: Bool) {
        guard let manager = gameManager else { return }
        lastDirection = direction
        manager.isAnimating = true

        updateChangedTiles()
        updatePlayerVisual(direction: direction)

        if pushed {
            SoundManager.shared.playPush()
            HapticsManager.shared.boxPushed()
        } else {
            SoundManager.shared.playStep()
            HapticsManager.shared.playerMoved()
        }

        let state = manager.state
        let target = positionForCell(row: state.playerPosition.row, col: state.playerPosition.col)
        let move = SKAction.move(to: target, duration: animationDuration)
        move.timingMode = .easeOut
        playerNode.run(move) { [weak self] in
            self?.gameManager?.isAnimating = false
        }
    }"""

new_refresh = """    func refreshAfterMove(direction: Direction, pushed: Bool) {
        guard let manager = gameManager else { return }
        lastDirection = direction
        manager.isAnimating = true

        updatePlayerVisual(direction: direction)

        if pushed {
            SoundManager.shared.playPush()
            HapticsManager.shared.boxPushed()
            let boxOldPos = manager.state.playerPosition
            let boxNewPos = boxOldPos.moved(direction)
            animateBoxSlide(from: boxOldPos, to: boxNewPos, state: manager.state)
        } else {
            SoundManager.shared.playStep()
            HapticsManager.shared.playerMoved()
        }

        updateChangedTiles()

        let state = manager.state
        let target = positionForCell(row: state.playerPosition.row, col: state.playerPosition.col)
        let move = SKAction.move(to: target, duration: animationDuration)
        move.timingMode = .easeOut

        let squish = SKAction.scaleY(to: 0.92, duration: 0.06)
        squish.timingMode = .easeOut
        let unsquish = SKAction.scaleY(to: 1.0, duration: 0.08)
        unsquish.timingMode = .easeOut
        let bounce = SKAction.sequence([squish, unsquish])

        playerNode.run(move) { [weak self] in
            self?.playerNode.run(bounce)
            self?.gameManager?.isAnimating = false
        }
    }"""

if old_refresh in content:
    content = content.replace(old_refresh, new_refresh)
    with open(filepath, 'w') as f:
        f.write(content)
    print("Successfully replaced refreshAfterMove")
else:
    print("ERROR: Could not find old refreshAfterMove")
