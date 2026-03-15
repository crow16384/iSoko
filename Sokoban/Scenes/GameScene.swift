import SpriteKit
import UIKit

final class GameScene: SKScene {

    weak var gameManager: GameManager?

    private var tileSize: CGFloat = 32
    private var gridOrigin: CGPoint = .zero
    private var tileNodes: [[SKSpriteNode]] = []
    private var playerNode: SKSpriteNode!
    private var lastDirection: Direction = .down
    private var previousGrid: [[Tile]] = []

    private let animationDuration: TimeInterval = 0.12
    private var isMovingAlongPath = false

    // MARK: - Palette

    private enum Palette {
        static let wallBase    = UIColor(red: 0.41, green: 0.35, blue: 0.27, alpha: 1)
        static let wallMortar  = UIColor(red: 0.22, green: 0.18, blue: 0.14, alpha: 1)
        static let wallLight   = UIColor(red: 0.53, green: 0.47, blue: 0.38, alpha: 1)
        static let floor       = UIColor(red: 0.78, green: 0.80, blue: 0.71, alpha: 1)
        static let floorLine   = UIColor(red: 0.72, green: 0.74, blue: 0.66, alpha: 1)
        static let goalFrame   = UIColor(red: 0.70, green: 0.30, blue: 0.30, alpha: 1)
        static let boxBody     = UIColor(red: 0.65, green: 0.55, blue: 0.33, alpha: 1)
        static let boxDark     = UIColor(red: 0.47, green: 0.39, blue: 0.24, alpha: 1)
        static let boxLight    = UIColor(red: 0.76, green: 0.69, blue: 0.43, alpha: 1)
        static let boxGoalBody = UIColor(red: 0.39, green: 0.65, blue: 0.43, alpha: 1)
        static let boxGoalDark = UIColor(red: 0.24, green: 0.51, blue: 0.31, alpha: 1)
        static let boxGoalLit  = UIColor(red: 0.55, green: 0.76, blue: 0.55, alpha: 1)
        static let playerBody  = UIColor(red: 0.96, green: 0.87, blue: 0.40, alpha: 1)
        static let playerEdge  = UIColor(red: 0.78, green: 0.69, blue: 0.27, alpha: 1)
        static let playerHat   = UIColor(red: 0.82, green: 0.71, blue: 0.24, alpha: 1)
        static let outer       = UIColor(red: 0.12, green: 0.10, blue: 0.08, alpha: 1)
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = Palette.outer
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        setupGestures(in: view)
        layoutGrid()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size != .zero else { return }
        layoutGrid()
    }

    // MARK: - Grid Layout

    private func layoutGrid() {
        guard let manager = gameManager else { return }

        removeAllChildren()
        tileNodes = []
        previousGrid = []

        let cols = GameState.columns
        let rows = GameState.rows
        tileSize = floor(min(size.width / CGFloat(cols), size.height / CGFloat(rows)))

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
        previousGrid = state.grid

        playerNode = makePlayerNode()
        playerNode.position = positionForCell(
            row: state.playerPosition.row,
            col: state.playerPosition.col
        )
        addChild(playerNode)
    }

    private func positionForCell(row: Int, col: Int) -> CGPoint {
        CGPoint(
            x: gridOrigin.x + CGFloat(col) * tileSize + tileSize / 2,
            y: gridOrigin.y - CGFloat(row) * tileSize - tileSize / 2
        )
    }

    // MARK: - Tile Drawing

    private func makeTileNode(_ tile: Tile, row: Int, col: Int) -> SKSpriteNode {
        let container = SKSpriteNode(color: .clear, size: CGSize(width: tileSize, height: tileSize))
        container.zPosition = tile.isBox ? 5 : 1
        decorateTile(container, tile: tile, row: row, col: col)
        return container
    }

    private func decorateTile(_ node: SKSpriteNode, tile: Tile, row: Int, col: Int) {
        let s = tileSize
        switch tile {
        case .wall:
            drawWall(on: node, size: s)
        case .floor, .player:
            drawFloor(on: node, size: s)
        case .playerOnGoal, .goal:
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

    private func drawWall(on node: SKSpriteNode, size s: CGFloat) {
        let base = SKSpriteNode(color: Palette.wallMortar, size: CGSize(width: s, height: s))
        base.zPosition = 0.01
        node.addChild(base)

        let brickH = floor(s / 4)
        let brickW = floor(s / 2)
        let gap = max(1, floor(s * 0.06))

        for brickRow in 0..<4 {
            let offset: CGFloat = brickRow.isMultiple(of: 2) ? 0 : brickW / 2
            let by = -s / 2 + CGFloat(brickRow) * brickH + gap / 2

            for brickCol in -1..<3 {
                let bx = -s / 2 + CGFloat(brickCol) * brickW + offset + gap / 2
                let left   = max(-s / 2, bx)
                let right  = min( s / 2, bx + brickW - gap)
                let bottom = max(-s / 2, by)
                let top    = min( s / 2, by + brickH - gap)
                guard right > left, top > bottom else { continue }

                let cw = right - left, ch = top - bottom
                let brick = SKSpriteNode(color: Palette.wallBase, size: CGSize(width: cw, height: ch))
                brick.position = CGPoint(x: left + cw / 2, y: bottom + ch / 2)
                brick.zPosition = 0.02

                let hh = max(1, ch * 0.2)
                let hl = SKSpriteNode(color: Palette.wallLight, size: CGSize(width: cw, height: hh))
                hl.position = CGPoint(x: 0, y: ch / 2 - hh / 2)
                hl.zPosition = 0.01
                brick.addChild(hl)
                node.addChild(brick)
            }
        }
    }

    private func drawFloor(on node: SKSpriteNode, size s: CGFloat) {
        let bg = SKSpriteNode(color: Palette.floor, size: CGSize(width: s, height: s))
        bg.zPosition = 0.01
        node.addChild(bg)

        let lineW = max(1, s * 0.02)
        let step = floor(s / 4)
        for i in 1..<4 {
            let pos = -s / 2 + CGFloat(i) * step
            let v = SKSpriteNode(color: Palette.floorLine, size: CGSize(width: lineW, height: s))
            v.position = CGPoint(x: pos, y: 0)
            v.zPosition = 0.02
            node.addChild(v)
            let h = SKSpriteNode(color: Palette.floorLine, size: CGSize(width: s, height: lineW))
            h.position = CGPoint(x: 0, y: pos)
            h.zPosition = 0.02
            node.addChild(h)
        }
    }

    private func drawGoalMarker(on node: SKSpriteNode, size s: CGFloat) {
        let m = s * 0.22
        let fw = max(2, s * 0.08)
        let fs = s - 2 * m

        let frame = SKShapeNode(rectOf: CGSize(width: fs, height: fs))
        frame.strokeColor = Palette.goalFrame
        frame.fillColor = .clear
        frame.lineWidth = fw
        frame.zPosition = 0.05
        node.addChild(frame)

        let dm = s * 0.14
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: dm))
        path.addLine(to: CGPoint(x: dm, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -dm))
        path.addLine(to: CGPoint(x: -dm, y: 0))
        path.closeSubpath()
        let diamond = SKShapeNode(path: path)
        diamond.fillColor = Palette.goalFrame.withAlphaComponent(0.7)
        diamond.strokeColor = .clear
        diamond.zPosition = 0.06
        node.addChild(diamond)
    }

    private func drawBox(on node: SKSpriteNode, size s: CGFloat, onGoal: Bool) {
        let inset = s * 0.10
        let bs = s - 2 * inset
        let bodyColor = onGoal ? Palette.boxGoalBody : Palette.boxBody
        let darkColor = onGoal ? Palette.boxGoalDark : Palette.boxDark
        let lightColor = onGoal ? Palette.boxGoalLit : Palette.boxLight

        let box = SKSpriteNode(color: bodyColor, size: CGSize(width: bs, height: bs))
        box.zPosition = 0.10
        node.addChild(box)

        let ew = max(2, bs * 0.08)
        for (color, w, h, pos) in [
            (lightColor, bs, ew, CGPoint(x: 0, y: bs / 2 - ew / 2)),
            (lightColor, ew, bs, CGPoint(x: -bs / 2 + ew / 2, y: 0)),
            (darkColor,  bs, ew, CGPoint(x: 0, y: -bs / 2 + ew / 2)),
            (darkColor,  ew, bs, CGPoint(x: bs / 2 - ew / 2, y: 0)),
        ] as [(UIColor, CGFloat, CGFloat, CGPoint)] {
            let e = SKSpriteNode(color: color, size: CGSize(width: w, height: h))
            e.position = pos
            e.zPosition = 0.11
            box.addChild(e)
        }

        let lw = max(1, bs * 0.05)
        let inner = bs - 2 * ew

        let hp = SKSpriteNode(color: darkColor, size: CGSize(width: inner, height: lw))
        hp.zPosition = 0.12
        box.addChild(hp)
        let vp = SKSpriteNode(color: darkColor, size: CGSize(width: lw, height: inner))
        vp.zPosition = 0.12
        box.addChild(vp)

        let third = inner / 3
        for i in [CGFloat(1), CGFloat(2)] {
            let xOff = -inner / 2 + i * third
            let div = SKSpriteNode(
                color: darkColor.withAlphaComponent(0.5),
                size: CGSize(width: max(1, lw * 0.6), height: inner)
            )
            div.position = CGPoint(x: xOff, y: 0)
            div.zPosition = 0.12
            box.addChild(div)
        }
    }

    // MARK: - Player Node

    private func makePlayerNode() -> SKSpriteNode {
        let container = SKSpriteNode(color: .clear, size: CGSize(width: tileSize, height: tileSize))
        container.zPosition = 10
        let s = tileSize
        let r = s * 0.32

        let body = SKShapeNode(circleOfRadius: r)
        body.fillColor = Palette.playerBody
        body.strokeColor = Palette.playerEdge
        body.lineWidth = max(1.5, s * 0.04)
        body.position = CGPoint(x: 0, y: -s * 0.04)
        body.zPosition = 0.1
        container.addChild(body)

        let hatPath = CGMutablePath()
        let hw = r * 0.7, hh = r * 0.55, hb = r * 0.5
        hatPath.move(to: CGPoint(x: 0, y: hb + hh))
        hatPath.addLine(to: CGPoint(x: -hw, y: hb))
        hatPath.addLine(to: CGPoint(x: hw, y: hb))
        hatPath.closeSubpath()
        let hat = SKShapeNode(path: hatPath)
        hat.fillColor = Palette.playerHat
        hat.strokeColor = Palette.playerEdge
        hat.lineWidth = max(1, s * 0.03)
        hat.position = CGPoint(x: 0, y: -s * 0.04)
        hat.zPosition = 0.2
        container.addChild(hat)

        let sep = r * 0.3, er = max(2.5, s * 0.055), ey = s * 0.02
        for dx in [-sep, sep] {
            let eye = SKShapeNode(circleOfRadius: er)
            eye.fillColor = UIColor(white: 0.15, alpha: 1)
            eye.strokeColor = .clear
            eye.position = CGPoint(x: dx, y: ey)
            eye.zPosition = 0.3
            container.addChild(eye)

            let glint = SKShapeNode(circleOfRadius: er * 0.35)
            glint.fillColor = .white
            glint.strokeColor = .clear
            glint.position = CGPoint(x: dx - er * 0.2, y: ey + er * 0.25)
            glint.zPosition = 0.31
            container.addChild(glint)
        }

        let smilePath = CGMutablePath()
        smilePath.addArc(
            center: CGPoint(x: 0, y: -s * 0.10),
            radius: r * 0.35,
            startAngle: .pi * 0.15,
            endAngle: .pi * 0.85,
            clockwise: true
        )
        let smile = SKShapeNode(path: smilePath)
        smile.strokeColor = UIColor(white: 0.15, alpha: 1)
        smile.lineWidth = max(1.5, s * 0.04)
        smile.fillColor = .clear
        smile.zPosition = 0.3
        container.addChild(smile)

        let ind = SKShapeNode(circleOfRadius: s * 0.06)
        ind.fillColor = Palette.playerEdge
        ind.strokeColor = .clear
        ind.position = CGPoint(x: 0, y: r + s * 0.02)
        ind.name = "indicator"
        ind.zPosition = 0.4
        container.addChild(ind)

        return container
    }

    // MARK: - Visual Updates

    func refreshAfterMove(direction: Direction, pushed: Bool) {
        guard let manager = gameManager else { return }
        lastDirection = direction
        manager.isAnimating = true

        updateChangedTiles()
        updatePlayerIndicator(direction: direction)

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
    }

    func refreshFullBoard() {
        layoutGrid()
    }

    private func updateChangedTiles() {
        guard let manager = gameManager else { return }
        let grid = manager.state.grid

        for r in 0..<GameState.rows {
            for c in 0..<GameState.columns {
                let tile = grid[r][c]
                guard previousGrid.isEmpty || previousGrid[r][c] != tile else { continue }
                let node = tileNodes[r][c]
                node.removeAllChildren()
                decorateTile(node, tile: tile, row: r, col: c)
                node.zPosition = tile.isBox ? 5 : 1
            }
        }
        previousGrid = grid
    }

    private func updatePlayerIndicator(direction: Direction) {
        guard let ind = playerNode.childNode(withName: "indicator") as? SKShapeNode else { return }
        let off = tileSize * 0.34
        switch direction {
        case .up:    ind.position = CGPoint(x: 0, y: off)
        case .down:  ind.position = CGPoint(x: 0, y: -off)
        case .left:  ind.position = CGPoint(x: -off, y: 0)
        case .right: ind.position = CGPoint(x: off, y: 0)
        }
    }

    // MARK: - Level Completion Celebration

    func showLevelCompleteCelebration() {
        let colors: [UIColor] = [
            UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1),
            UIColor(red: 0.3, green: 0.85, blue: 0.4, alpha: 1),
            UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1),
            UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1),
            UIColor(red: 0.9, green: 0.5, blue: 1.0, alpha: 1),
        ]

        let texSize = CGSize(width: 8, height: 8)
        let renderer = UIGraphicsImageRenderer(size: texSize)
        let texImage = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: texSize))
        }
        let texture = SKTexture(image: texImage)

        for i in 0..<5 {
            let emitter = SKEmitterNode()
            emitter.particleBirthRate = 80
            emitter.numParticlesToEmit = 40
            emitter.particleLifetime = 1.5
            emitter.particleLifetimeRange = 0.5
            emitter.emissionAngleRange = .pi * 2
            emitter.particleSpeed = 200
            emitter.particleSpeedRange = 100
            emitter.particleAlpha = 1.0
            emitter.particleAlphaSpeed = -0.7
            emitter.particleScale = 0.15
            emitter.particleScaleRange = 0.1
            emitter.particleScaleSpeed = -0.05
            emitter.particleColor = colors[i]
            emitter.particleColorBlendFactor = 1.0
            emitter.particleBlendMode = .add
            emitter.particleTexture = texture
            emitter.yAcceleration = -200
            emitter.position = CGPoint(
                x: CGFloat.random(in: -size.width * 0.35...size.width * 0.35),
                y: CGFloat.random(in: 0...size.height * 0.4)
            )
            emitter.zPosition = 100
            emitter.name = "celebration"

            let delay = SKAction.wait(forDuration: Double(i) * 0.2)
            run(SKAction.sequence([
                delay,
                .run { [weak self] in self?.addChild(emitter) },
                .wait(forDuration: 3.0),
                .run { emitter.removeFromParent() }
            ]))
        }

        let label = SKLabelNode(text: "LEVEL COMPLETE!")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = min(size.width / 10, 60)
        label.fontColor = UIColor(red: 1, green: 0.9, blue: 0.3, alpha: 1)
        label.position = CGPoint(x: 0, y: size.height * 0.15)
        label.zPosition = 101
        label.alpha = 0
        label.setScale(0.3)
        label.name = "celebration"

        let shadow = SKLabelNode(text: label.text ?? "")
        shadow.fontName = label.fontName
        shadow.fontSize = label.fontSize
        shadow.fontColor = UIColor(white: 0, alpha: 0.4)
        shadow.position = CGPoint(x: 2, y: -2)
        shadow.zPosition = -0.1
        label.addChild(shadow)
        addChild(label)

        label.run(.group([
            .scale(to: 1, duration: 0.4),
            .fadeIn(withDuration: 0.3)
        ]))
        let pulse = SKAction.sequence([
            .scale(to: 1.08, duration: 0.6),
            .scale(to: 1.0, duration: 0.6)
        ])
        label.run(.sequence([.wait(forDuration: 0.5), .repeatForever(pulse)]))

        SoundManager.shared.playLevelComplete()
        HapticsManager.shared.levelCompleted()
    }

    func clearCelebration() {
        enumerateChildNodes(withName: "celebration") { node, _ in
            node.removeFromParent()
        }
    }

    // MARK: - Input Handling

    private func setupGestures(in view: SKView) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tap)

        for dir: UISwipeGestureRecognizer.Direction in [.up, .down, .left, .right] {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            swipe.direction = dir
            view.addGestureRecognizer(swipe)
        }
    }

    private func directionFromSwipe(_ dir: UISwipeGestureRecognizer.Direction) -> Direction? {
        switch dir {
        case .up:    return .up
        case .down:  return .down
        case .left:  return .left
        case .right: return .right
        default:     return nil
        }
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard let manager = gameManager,
              !manager.isAnimating, !isMovingAlongPath,
              let direction = directionFromSwipe(gesture.direction) else { return }
        performMove(direction, on: manager)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended,
              let manager = gameManager,
              !manager.isAnimating, !isMovingAlongPath,
              let view = self.view else { return }

        let loc = convertPoint(fromView: gesture.location(in: view))
        let col = Int(floor((loc.x - gridOrigin.x) / tileSize))
        let row = Int(floor((gridOrigin.y - loc.y) / tileSize))

        guard row >= 0, row < GameState.rows,
              col >= 0, col < GameState.columns else { return }

        let target = Position(row: row, col: col)

        if let push = manager.state.findBoxPush(to: target) {
            pushBoxAlongPath(direction: push.direction, remainingSteps: push.steps)
            return
        }

        guard let path = manager.state.findPath(to: target), !path.isEmpty else { return }
        moveAlongPath(path, stepIndex: 0)
    }

    /// Centralised move handling — eliminates duplication across swipe/keyboard/tap.
    private func performMove(_ direction: Direction, on manager: GameManager) {
        let result = manager.tryMove(direction)
        switch result {
        case .moved:
            refreshAfterMove(direction: direction, pushed: false)
        case .pushed:
            refreshAfterMove(direction: direction, pushed: true)
            handleLevelCompleteIfNeeded(manager)
        case .blocked:
            SoundManager.shared.playBlocked()
            HapticsManager.shared.blocked()
        }
    }

    private func handleLevelCompleteIfNeeded(_ manager: GameManager) {
        guard manager.isLevelComplete else { return }
        PersistenceManager.shared.markLevelCompleted(
            manager.state.levelIndex, moves: manager.state.moveCount
        )
        showLevelCompleteCelebration()
    }

    // MARK: - Path Walking

    private func moveAlongPath(_ path: [Direction], stepIndex: Int) {
        guard stepIndex < path.count,
              let manager = gameManager,
              !manager.isLevelComplete else {
            isMovingAlongPath = false
            return
        }

        isMovingAlongPath = true
        let direction = path[stepIndex]

        guard case .moved = manager.tryMove(direction) else {
            isMovingAlongPath = false
            return
        }

        lastDirection = direction
        updatePlayerIndicator(direction: direction)
        manager.isAnimating = true
        SoundManager.shared.playStep()
        HapticsManager.shared.playerMoved()
        updateChangedTiles()

        let target = positionForCell(
            row: manager.state.playerPosition.row,
            col: manager.state.playerPosition.col
        )
        let move = SKAction.move(to: target, duration: animationDuration)
        move.timingMode = .easeOut
        playerNode.run(move) { [weak self] in
            manager.isAnimating = false
            self?.moveAlongPath(path, stepIndex: stepIndex + 1)
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

        guard case .pushed = manager.tryMove(direction) else {
            isMovingAlongPath = false
            return
        }

        lastDirection = direction
        updatePlayerIndicator(direction: direction)
        manager.isAnimating = true
        SoundManager.shared.playPush()
        HapticsManager.shared.boxPushed()
        updateChangedTiles()

        let target = positionForCell(
            row: manager.state.playerPosition.row,
            col: manager.state.playerPosition.col
        )
        let move = SKAction.move(to: target, duration: animationDuration)
        move.timingMode = .easeOut
        playerNode.run(move) { [weak self] in
            manager.isAnimating = false
            if manager.isLevelComplete {
                self?.handleLevelCompleteIfNeeded(manager)
                self?.isMovingAlongPath = false
            } else {
                self?.pushBoxAlongPath(direction: direction, remainingSteps: remainingSteps - 1)
            }
        }
    }

    // MARK: - Keyboard

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let manager = gameManager,
              !manager.isAnimating, !isMovingAlongPath else {
            super.pressesBegan(presses, with: event)
            return
        }

        for press in presses {
            guard let key = press.key else { continue }

            if key.modifierFlags.contains(.command),
               key.charactersIgnoringModifiers == "z" {
                manager.undo()
                refreshFullBoard()
                return
            }

            let direction: Direction?
            switch key.keyCode {
            case .keyboardUpArrow:    direction = .up
            case .keyboardDownArrow:  direction = .down
            case .keyboardLeftArrow:  direction = .left
            case .keyboardRightArrow: direction = .right
            default:                  direction = nil
            }

            if let dir = direction {
                performMove(dir, on: manager)
                return
            }
        }
        super.pressesBegan(presses, with: event)
    }
}
