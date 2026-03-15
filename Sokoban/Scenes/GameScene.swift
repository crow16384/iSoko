import SpriteKit
import UIKit

final class GameScene: SKScene {

    weak var gameManager: GameManager?

    private var tileSize: CGFloat = 32
    private var gridOrigin: CGPoint = .zero
    private var tileNodes: [[SKSpriteNode]] = []
    private var playerNode: SKSpriteNode!
    private var lastDirection: Direction = .down

    private let animationDuration: TimeInterval = 0.12
    private var isMovingAlongPath = false

    // Palette inspired by classic Win32 Sokoban
    private let wallColorBase = UIColor(red: 0.41, green: 0.35, blue: 0.27, alpha: 1.0)
    private let wallMortar = UIColor(red: 0.22, green: 0.18, blue: 0.14, alpha: 1.0)
    private let wallHighlight = UIColor(red: 0.53, green: 0.47, blue: 0.38, alpha: 1.0)
    private let floorColor = UIColor(red: 0.78, green: 0.80, blue: 0.71, alpha: 1.0)
    private let floorLine = UIColor(red: 0.72, green: 0.74, blue: 0.66, alpha: 1.0)
    private let goalFrameColor = UIColor(red: 0.70, green: 0.30, blue: 0.30, alpha: 1.0)
    private let boxBodyColor = UIColor(red: 0.65, green: 0.55, blue: 0.33, alpha: 1.0)
    private let boxDarkColor = UIColor(red: 0.47, green: 0.39, blue: 0.24, alpha: 1.0)
    private let boxLightColor = UIColor(red: 0.76, green: 0.69, blue: 0.43, alpha: 1.0)
    private let boxGoalBodyColor = UIColor(red: 0.39, green: 0.65, blue: 0.43, alpha: 1.0)
    private let boxGoalDarkColor = UIColor(red: 0.24, green: 0.51, blue: 0.31, alpha: 1.0)
    private let boxGoalLightColor = UIColor(red: 0.55, green: 0.76, blue: 0.55, alpha: 1.0)
    private let playerBodyColor = UIColor(red: 0.96, green: 0.87, blue: 0.40, alpha: 1.0)
    private let playerOutlineColor = UIColor(red: 0.78, green: 0.69, blue: 0.27, alpha: 1.0)
    private let playerHatColor = UIColor(red: 0.82, green: 0.71, blue: 0.24, alpha: 1.0)
    private let outerColor = UIColor(red: 0.12, green: 0.10, blue: 0.08, alpha: 1.0)

    override func didMove(to view: SKView) {
        backgroundColor = outerColor
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        setupGestures(in: view)
        layoutGrid()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if !size.equalTo(.zero) {
            layoutGrid()
        }
    }

    // MARK: - Grid Layout

    private func layoutGrid() {
        guard let manager = gameManager else { return }

        removeAllChildren()
        tileNodes = []

        let cols = GameState.columns
        let rows = GameState.rows

        let maxTileW = size.width / CGFloat(cols)
        let maxTileH = size.height / CGFloat(rows)
        tileSize = floor(min(maxTileW, maxTileH))

        let gridW = tileSize * CGFloat(cols)
        let gridH = tileSize * CGFloat(rows)
        gridOrigin = CGPoint(x: -gridW / 2, y: gridH / 2)

        let state = manager.state

        for r in 0..<rows {
            var rowNodes: [SKSpriteNode] = []
            for c in 0..<cols {
                let tile = state.grid[r][c]
                let node = makeTileNode(tile, row: r, col: c)
                node.position = positionForCell(row: r, col: c)
                addChild(node)
                rowNodes.append(node)
            }
            tileNodes.append(rowNodes)
        }

        playerNode = makePlayerNode()
        playerNode.position = positionForCell(row: state.playerPosition.row, col: state.playerPosition.col)
        addChild(playerNode)
    }

    private func positionForCell(row: Int, col: Int) -> CGPoint {
        CGPoint(
            x: gridOrigin.x + CGFloat(col) * tileSize + tileSize / 2,
            y: gridOrigin.y - CGFloat(row) * tileSize - tileSize / 2
        )
    }

    // MARK: - Stylized Tile Creation

    private func makeTileNode(_ tile: Tile, row: Int, col: Int) -> SKSpriteNode {
        let container = SKSpriteNode(color: .clear, size: CGSize(width: tileSize, height: tileSize))
        container.zPosition = tile.isBox ? 5 : 1
        addTileDecoration(to: container, tile: tile, row: row, col: col)
        return container
    }

    private func addTileDecoration(to node: SKSpriteNode, tile: Tile, row: Int, col: Int) {
        let s = tileSize

        switch tile {
        case .wall:
            drawWall(on: node, size: s, row: row, col: col)
        case .floor, .player:
            drawFloor(on: node, size: s)
        case .playerOnGoal:
            drawFloor(on: node, size: s)
            drawGoalMarker(on: node, size: s)
        case .goal:
            drawFloor(on: node, size: s)
            drawGoalMarker(on: node, size: s)
        case .box:
            drawFloor(on: node, size: s)
            drawBox(on: node, size: s, onGoal: false)
        case .boxOnGoal:
            drawFloor(on: node, size: s)
            drawGoalMarker(on: node, size: s)
            drawBox(on: node, size: s, onGoal: true)
        }
    }

    // MARK: - Draw Wall (3D brick pattern)

    private func drawWall(on node: SKSpriteNode, size s: CGFloat, row: Int, col: Int) {
        let base = SKSpriteNode(color: wallMortar, size: CGSize(width: s, height: s))
        base.zPosition = 0.01
        node.addChild(base)

        let brickH = floor(s / 4)
        let brickW = floor(s / 2)
        let gap: CGFloat = max(1, floor(s * 0.06))

        for brickRow in 0..<4 {
            let offset: CGFloat = (brickRow % 2 == 1) ? brickW / 2 : 0
            let by = -s / 2 + CGFloat(brickRow) * brickH + gap / 2

            for brickCol in -1..<3 {
                let bx = -s / 2 + CGFloat(brickCol) * brickW + offset + gap / 2
                let bw = brickW - gap
                let bh = brickH - gap

                let left = max(-s / 2, bx)
                let right = min(s / 2, bx + bw)
                let bottom = max(-s / 2, by)
                let top = min(s / 2, by + bh)
                guard right > left && top > bottom else { continue }

                let clippedW = right - left
                let clippedH = top - bottom

                let brick = SKSpriteNode(color: wallColorBase, size: CGSize(width: clippedW, height: clippedH))
                brick.position = CGPoint(x: left + clippedW / 2, y: bottom + clippedH / 2)
                brick.zPosition = 0.02

                let highlightH = max(1, clippedH * 0.2)
                let highlight = SKSpriteNode(color: wallHighlight, size: CGSize(width: clippedW, height: highlightH))
                highlight.position = CGPoint(x: 0, y: clippedH / 2 - highlightH / 2)
                highlight.zPosition = 0.01
                brick.addChild(highlight)

                node.addChild(brick)
            }
        }
    }

    // MARK: - Draw Floor (subtle stone texture)

    private func drawFloor(on node: SKSpriteNode, size s: CGFloat) {
        let bg = SKSpriteNode(color: floorColor, size: CGSize(width: s, height: s))
        bg.zPosition = 0.01
        node.addChild(bg)

        let lineW = max(1, s * 0.02)
        let step = floor(s / 4)
        for i in 1..<4 {
            let pos = -s / 2 + CGFloat(i) * step
            let vLine = SKSpriteNode(color: floorLine, size: CGSize(width: lineW, height: s))
            vLine.position = CGPoint(x: pos, y: 0)
            vLine.zPosition = 0.02
            node.addChild(vLine)

            let hLine = SKSpriteNode(color: floorLine, size: CGSize(width: s, height: lineW))
            hLine.position = CGPoint(x: 0, y: pos)
            hLine.zPosition = 0.02
            node.addChild(hLine)
        }
    }

    // MARK: - Draw Goal Marker (red square frame + diamond)

    private func drawGoalMarker(on node: SKSpriteNode, size s: CGFloat) {
        let m = s * 0.22
        let frameW = max(2, s * 0.08)

        let frameSize = s - 2 * m
        let frame = SKShapeNode(rectOf: CGSize(width: frameSize, height: frameSize))
        frame.strokeColor = goalFrameColor
        frame.fillColor = .clear
        frame.lineWidth = frameW
        frame.zPosition = 0.05
        node.addChild(frame)

        let dm = s * 0.14
        let diamond = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: dm))
        path.addLine(to: CGPoint(x: dm, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -dm))
        path.addLine(to: CGPoint(x: -dm, y: 0))
        path.closeSubpath()
        diamond.path = path
        diamond.fillColor = goalFrameColor.withAlphaComponent(0.7)
        diamond.strokeColor = .clear
        diamond.zPosition = 0.06
        node.addChild(diamond)
    }

    // MARK: - Draw Box (wooden crate with 3D edges and plank pattern)

    private func drawBox(on node: SKSpriteNode, size s: CGFloat, onGoal: Bool) {
        let inset = s * 0.10
        let bs = s - 2 * inset
        let bodyColor = onGoal ? boxGoalBodyColor : boxBodyColor
        let darkColor = onGoal ? boxGoalDarkColor : boxDarkColor
        let lightColor = onGoal ? boxGoalLightColor : boxLightColor

        let body = SKSpriteNode(color: bodyColor, size: CGSize(width: bs, height: bs))
        body.zPosition = 0.10
        node.addChild(body)

        let edgeW = max(2, bs * 0.08)

        let topEdge = SKSpriteNode(color: lightColor, size: CGSize(width: bs, height: edgeW))
        topEdge.position = CGPoint(x: 0, y: bs / 2 - edgeW / 2)
        topEdge.zPosition = 0.11
        body.addChild(topEdge)

        let leftEdge = SKSpriteNode(color: lightColor, size: CGSize(width: edgeW, height: bs))
        leftEdge.position = CGPoint(x: -bs / 2 + edgeW / 2, y: 0)
        leftEdge.zPosition = 0.11
        body.addChild(leftEdge)

        let bottomEdge = SKSpriteNode(color: darkColor, size: CGSize(width: bs, height: edgeW))
        bottomEdge.position = CGPoint(x: 0, y: -bs / 2 + edgeW / 2)
        bottomEdge.zPosition = 0.11
        body.addChild(bottomEdge)

        let rightEdge = SKSpriteNode(color: darkColor, size: CGSize(width: edgeW, height: bs))
        rightEdge.position = CGPoint(x: bs / 2 - edgeW / 2, y: 0)
        rightEdge.zPosition = 0.11
        body.addChild(rightEdge)

        let lineW = max(1, bs * 0.05)

        let hPlank = SKSpriteNode(color: darkColor, size: CGSize(width: bs - 2 * edgeW, height: lineW))
        hPlank.zPosition = 0.12
        body.addChild(hPlank)

        let vPlank = SKSpriteNode(color: darkColor, size: CGSize(width: lineW, height: bs - 2 * edgeW))
        vPlank.zPosition = 0.12
        body.addChild(vPlank)

        let third = (bs - 2 * edgeW) / 3
        for i in [1, 2] {
            let xPos = -bs / 2 + edgeW + CGFloat(i) * third
            let divider = SKSpriteNode(color: darkColor.withAlphaComponent(0.5),
                                        size: CGSize(width: max(1, lineW * 0.6), height: bs - 2 * edgeW))
            divider.position = CGPoint(x: xPos - (bs - 2 * edgeW) / 2, y: 0)
            divider.zPosition = 0.12
            body.addChild(divider)
        }
    }

    // MARK: - Create Player Node (character with hat, face, body)

    private func makePlayerNode() -> SKSpriteNode {
        let container = SKSpriteNode(color: .clear, size: CGSize(width: tileSize, height: tileSize))
        container.zPosition = 10

        let s = tileSize
        let bodyRadius = s * 0.32

        let body = SKShapeNode(circleOfRadius: bodyRadius)
        body.fillColor = playerBodyColor
        body.strokeColor = playerOutlineColor
        body.lineWidth = max(1.5, s * 0.04)
        body.position = CGPoint(x: 0, y: -s * 0.04)
        body.zPosition = 0.1
        container.addChild(body)

        let hat = SKShapeNode()
        let hatPath = CGMutablePath()
        let hatW = bodyRadius * 0.7
        let hatH = bodyRadius * 0.55
        let hatBase = bodyRadius * 0.5
        hatPath.move(to: CGPoint(x: 0, y: hatBase + hatH))
        hatPath.addLine(to: CGPoint(x: -hatW, y: hatBase))
        hatPath.addLine(to: CGPoint(x: hatW, y: hatBase))
        hatPath.closeSubpath()
        hat.path = hatPath
        hat.fillColor = playerHatColor
        hat.strokeColor = playerOutlineColor
        hat.lineWidth = max(1, s * 0.03)
        hat.position = CGPoint(x: 0, y: -s * 0.04)
        hat.zPosition = 0.2
        container.addChild(hat)

        let eyeSep = bodyRadius * 0.3
        let eyeR = max(2.5, s * 0.055)
        let eyeY: CGFloat = s * 0.02

        for dx in [-eyeSep, eyeSep] {
            let eye = SKShapeNode(circleOfRadius: eyeR)
            eye.fillColor = UIColor(white: 0.15, alpha: 1.0)
            eye.strokeColor = .clear
            eye.position = CGPoint(x: dx, y: eyeY)
            eye.zPosition = 0.3
            container.addChild(eye)

            let glint = SKShapeNode(circleOfRadius: eyeR * 0.35)
            glint.fillColor = .white
            glint.strokeColor = .clear
            glint.position = CGPoint(x: dx - eyeR * 0.2, y: eyeY + eyeR * 0.25)
            glint.zPosition = 0.31
            container.addChild(glint)
        }

        let smile = SKShapeNode()
        let smilePath = CGMutablePath()
        let smileW = bodyRadius * 0.35
        let smileY = -s * 0.10
        smilePath.addArc(center: CGPoint(x: 0, y: smileY),
                         radius: smileW,
                         startAngle: CGFloat.pi * 0.15,
                         endAngle: CGFloat.pi * 0.85,
                         clockwise: true)
        smile.path = smilePath
        smile.strokeColor = UIColor(white: 0.15, alpha: 1.0)
        smile.lineWidth = max(1.5, s * 0.04)
        smile.fillColor = .clear
        smile.zPosition = 0.3
        container.addChild(smile)

        let indicator = SKShapeNode(circleOfRadius: s * 0.06)
        indicator.fillColor = playerOutlineColor
        indicator.strokeColor = .clear
        indicator.position = CGPoint(x: 0, y: bodyRadius + s * 0.02)
        indicator.name = "indicator"
        indicator.zPosition = 0.4
        container.addChild(indicator)

        return container
    }

    // MARK: - Update Visuals After Move

    func refreshAfterMove(direction: Direction, pushed: Bool) {
        guard let manager = gameManager else { return }
        let state = manager.state
        lastDirection = direction

        manager.isAnimating = true

        updateTileVisuals()

        let targetPos = positionForCell(row: state.playerPosition.row, col: state.playerPosition.col)
        updatePlayerIndicator(direction: direction)

        let moveAction = SKAction.move(to: targetPos, duration: animationDuration)
        moveAction.timingMode = .easeOut
        playerNode.run(moveAction) { [weak self] in
            self?.gameManager?.isAnimating = false
        }
    }

    func refreshFullBoard() {
        layoutGrid()
    }

    private func updatePlayerIndicator(direction: Direction) {
        guard let indicator = playerNode.childNode(withName: "indicator") as? SKShapeNode else { return }
        let offset = tileSize * 0.34
        switch direction {
        case .up: indicator.position = CGPoint(x: 0, y: offset)
        case .down: indicator.position = CGPoint(x: 0, y: -offset)
        case .left: indicator.position = CGPoint(x: -offset, y: 0)
        case .right: indicator.position = CGPoint(x: offset, y: 0)
        }
    }

    // MARK: - Gesture Handling

    private func setupGestures(in view: SKView) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tap)

        for dir: UISwipeGestureRecognizer.Direction in [.up, .down, .left, .right] {
            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            gesture.direction = dir
            view.addGestureRecognizer(gesture)
        }
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard let manager = gameManager, !manager.isAnimating, !isMovingAlongPath else { return }

        let direction: Direction
        switch gesture.direction {
        case .up: direction = .up
        case .down: direction = .down
        case .left: direction = .left
        case .right: direction = .right
        default: return
        }

        let result = manager.tryMove(direction)
        switch result {
        case .moved:
            refreshAfterMove(direction: direction, pushed: false)
        case .pushed:
            refreshAfterMove(direction: direction, pushed: true)
            if manager.isLevelComplete {
                PersistenceManager.shared.markLevelCompleted(manager.state.levelIndex, moves: manager.state.moveCount)
            }
        case .blocked:
            break
        }
    }

    // MARK: - Tap-to-Move

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended,
              let manager = gameManager,
              !manager.isAnimating,
              !isMovingAlongPath,
              let view = self.view else { return }

        let viewLocation = gesture.location(in: view)
        let sceneLocation = convertPoint(fromView: viewLocation)

        let col = Int(floor((sceneLocation.x - gridOrigin.x) / tileSize))
        let row = Int(floor((gridOrigin.y - sceneLocation.y) / tileSize))

        let target = Position(row: row, col: col)

        guard row >= 0, row < GameState.rows,
              col >= 0, col < GameState.columns else { return }

        if let push = manager.state.findBoxPush(to: target) {
            pushBoxAlongPath(direction: push.direction, remainingSteps: push.steps)
            return
        }

        guard let path = manager.state.findPath(to: target), !path.isEmpty else { return }

        moveAlongPath(path, stepIndex: 0)
    }

    private func moveAlongPath(_ path: [Direction], stepIndex: Int) {
        guard stepIndex < path.count,
              let manager = gameManager,
              !manager.isLevelComplete else {
            isMovingAlongPath = false
            return
        }

        isMovingAlongPath = true
        let direction = path[stepIndex]
        let result = manager.tryMove(direction)

        switch result {
        case .moved:
            lastDirection = direction
            updatePlayerIndicator(direction: direction)
            manager.isAnimating = true

            updateTileVisuals()

            let targetPos = positionForCell(row: manager.state.playerPosition.row, col: manager.state.playerPosition.col)
            let moveAction = SKAction.move(to: targetPos, duration: animationDuration)
            moveAction.timingMode = .easeOut

            playerNode.run(moveAction) { [weak self] in
                manager.isAnimating = false
                self?.moveAlongPath(path, stepIndex: stepIndex + 1)
            }

        case .pushed, .blocked:
            isMovingAlongPath = false
        }
    }

    private func pushBoxAlongPath(direction: Direction, remainingSteps: Int) {
        guard remainingSteps > 0,
              let manager = gameManager,
              !manager.isLevelComplete else {
            isMovingAlongPath = false
            return
        }

        isMovingAlongPath = true
        let result = manager.tryMove(direction)

        switch result {
        case .pushed:
            lastDirection = direction
            updatePlayerIndicator(direction: direction)
            manager.isAnimating = true

            updateTileVisuals()

            let targetPos = positionForCell(row: manager.state.playerPosition.row, col: manager.state.playerPosition.col)
            let moveAction = SKAction.move(to: targetPos, duration: animationDuration)
            moveAction.timingMode = .easeOut

            playerNode.run(moveAction) { [weak self] in
                manager.isAnimating = false
                if manager.isLevelComplete {
                    PersistenceManager.shared.markLevelCompleted(manager.state.levelIndex, moves: manager.state.moveCount)
                    self?.isMovingAlongPath = false
                } else {
                    self?.pushBoxAlongPath(direction: direction, remainingSteps: remainingSteps - 1)
                }
            }

        case .moved, .blocked:
            isMovingAlongPath = false
        }
    }

    private func updateTileVisuals() {
        guard let manager = gameManager else { return }
        let state = manager.state

        for r in 0..<GameState.rows {
            for c in 0..<GameState.columns {
                let tile = state.grid[r][c]
                let node = tileNodes[r][c]
                node.removeAllChildren()
                addTileDecoration(to: node, tile: tile, row: r, col: c)
                node.zPosition = tile.isBox ? 5 : 1
            }
        }
    }

    // MARK: - Keyboard Support

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let manager = gameManager, !manager.isAnimating, !isMovingAlongPath else {
            super.pressesBegan(presses, with: event)
            return
        }

        for press in presses {
            guard let key = press.key else { continue }

            if key.modifierFlags.contains(.command) && key.charactersIgnoringModifiers == "z" {
                manager.undo()
                refreshFullBoard()
                return
            }

            let direction: Direction?
            switch key.keyCode {
            case .keyboardUpArrow: direction = .up
            case .keyboardDownArrow: direction = .down
            case .keyboardLeftArrow: direction = .left
            case .keyboardRightArrow: direction = .right
            default: direction = nil
            }

            if let dir = direction {
                let result = manager.tryMove(dir)
                switch result {
                case .moved:
                    refreshAfterMove(direction: dir, pushed: false)
                case .pushed:
                    refreshAfterMove(direction: dir, pushed: true)
                    if manager.isLevelComplete {
                        PersistenceManager.shared.markLevelCompleted(manager.state.levelIndex, moves: manager.state.moveCount)
                    }
                case .blocked:
                    break
                }
                return
            }
        }
        super.pressesBegan(presses, with: event)
    }
}

// MARK: - UIColor Helpers

extension UIColor {
    func lighter(by percentage: CGFloat) -> UIColor {
        adjust(by: abs(percentage))
    }

    func darker(by percentage: CGFloat) -> UIColor {
        adjust(by: -abs(percentage))
    }

    private func adjust(by percentage: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(
            red: min(r + percentage, 1.0),
            green: min(g + percentage, 1.0),
            blue: min(b + percentage, 1.0),
            alpha: a
        )
    }
}
