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

    // Colors for tiles
    private let wallColor = UIColor(red: 0.25, green: 0.2, blue: 0.15, alpha: 1.0)
    private let floorColor = UIColor(red: 0.85, green: 0.82, blue: 0.75, alpha: 1.0)
    private let goalColor = UIColor(red: 0.7, green: 0.85, blue: 0.7, alpha: 1.0)
    private let boxColor = UIColor(red: 0.72, green: 0.52, blue: 0.25, alpha: 1.0)
    private let boxOnGoalColor = UIColor(red: 0.3, green: 0.7, blue: 0.35, alpha: 1.0)
    private let playerColor = UIColor(red: 0.2, green: 0.45, blue: 0.8, alpha: 1.0)
    private let outerColor = UIColor(red: 0.15, green: 0.12, blue: 0.1, alpha: 1.0)

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

        // Player node on top
        playerNode = SKSpriteNode(color: playerColor, size: CGSize(width: tileSize * 0.65, height: tileSize * 0.65))
        playerNode.zPosition = 10
        playerNode.position = positionForCell(row: state.playerPosition.row, col: state.playerPosition.col)

        // Add a direction indicator (small triangle)
        let indicator = SKShapeNode(circleOfRadius: tileSize * 0.12)
        indicator.fillColor = .white
        indicator.strokeColor = .clear
        indicator.position = CGPoint(x: 0, y: tileSize * 0.16)
        indicator.name = "indicator"
        playerNode.addChild(indicator)

        addChild(playerNode)
    }

    private func positionForCell(row: Int, col: Int) -> CGPoint {
        CGPoint(
            x: gridOrigin.x + CGFloat(col) * tileSize + tileSize / 2,
            y: gridOrigin.y - CGFloat(row) * tileSize - tileSize / 2
        )
    }

    private func makeTileNode(_ tile: Tile, row: Int, col: Int) -> SKSpriteNode {
        let node = SKSpriteNode(color: colorForTile(tile), size: CGSize(width: tileSize, height: tileSize))
        node.zPosition = tile.isBox ? 5 : 1

        // Add visual details
        if tile == .wall {
            // Brick pattern — small inner rectangle
            let inner = SKSpriteNode(color: wallColor.lighter(by: 0.1), size: CGSize(width: tileSize * 0.85, height: tileSize * 0.85))
            inner.zPosition = 0.1
            node.addChild(inner)
        } else if tile.isGoal && !tile.isBox {
            // Goal marker — diamond shape
            let diamond = SKShapeNode(rectOf: CGSize(width: tileSize * 0.3, height: tileSize * 0.3))
            diamond.fillColor = UIColor(red: 0.3, green: 0.6, blue: 0.3, alpha: 0.8)
            diamond.strokeColor = .clear
            diamond.zRotation = .pi / 4
            diamond.zPosition = 0.1
            node.addChild(diamond)
        } else if tile.isBox {
            // Box cross pattern
            let crossH = SKSpriteNode(color: tile == .boxOnGoal ? boxOnGoalColor.darker(by: 0.15) : boxColor.darker(by: 0.15),
                                       size: CGSize(width: tileSize * 0.7, height: tileSize * 0.1))
            crossH.zPosition = 0.1
            node.addChild(crossH)
            let crossV = SKSpriteNode(color: crossH.color,
                                       size: CGSize(width: tileSize * 0.1, height: tileSize * 0.7))
            crossV.zPosition = 0.1
            node.addChild(crossV)
        }

        return node
    }

    private func colorForTile(_ tile: Tile) -> UIColor {
        switch tile {
        case .wall: return wallColor
        case .floor: return floorColor
        case .goal: return goalColor
        case .box: return boxColor
        case .boxOnGoal: return boxOnGoalColor
        case .player: return floorColor
        case .playerOnGoal: return goalColor
        }
    }

    // MARK: - Update Visuals After Move

    func refreshAfterMove(direction: Direction, pushed: Bool) {
        guard let manager = gameManager else { return }
        let state = manager.state
        lastDirection = direction

        manager.isAnimating = true

        // Update all tile colors/visuals
        updateTileVisuals()

        // Animate player
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
        let offset = tileSize * 0.16
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
        
        // Convert scene coordinates to grid row/col
        let col = Int(floor((sceneLocation.x - gridOrigin.x) / tileSize))
        let row = Int(floor((gridOrigin.y - sceneLocation.y) / tileSize))
        
        let target = Position(row: row, col: col)

        // Bounds check
        guard row >= 0, row < GameState.rows,
              col >= 0, col < GameState.columns else { return }

        // Find shortest path via BFS
        guard let path = manager.state.findPath(to: target), !path.isEmpty else { return }

        // Animate movement along path
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

            // Update tile visuals
            updateTileVisuals()

            let targetPos = positionForCell(row: manager.state.playerPosition.row, col: manager.state.playerPosition.col)
            let moveAction = SKAction.move(to: targetPos, duration: animationDuration)
            moveAction.timingMode = .easeOut

            playerNode.run(moveAction) { [weak self] in
                manager.isAnimating = false
                self?.moveAlongPath(path, stepIndex: stepIndex + 1)
            }

        case .pushed, .blocked:
            // Stop path movement if we hit a box or wall (path may have become invalid)
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
                node.color = colorForTile(tile)
                node.zPosition = tile.isBox ? 5 : 1

                node.removeAllChildren()
                if tile == .wall {
                    let inner = SKSpriteNode(color: wallColor.lighter(by: 0.1), size: CGSize(width: tileSize * 0.85, height: tileSize * 0.85))
                    inner.zPosition = 0.1
                    node.addChild(inner)
                } else if tile.isGoal && !tile.isBox {
                    let diamond = SKShapeNode(rectOf: CGSize(width: tileSize * 0.3, height: tileSize * 0.3))
                    diamond.fillColor = UIColor(red: 0.3, green: 0.6, blue: 0.3, alpha: 0.8)
                    diamond.strokeColor = .clear
                    diamond.zRotation = .pi / 4
                    diamond.zPosition = 0.1
                    node.addChild(diamond)
                } else if tile.isBox {
                    let baseColor = tile == .boxOnGoal ? boxOnGoalColor.darker(by: 0.15) : boxColor.darker(by: 0.15)
                    let crossH = SKSpriteNode(color: baseColor, size: CGSize(width: tileSize * 0.7, height: tileSize * 0.1))
                    crossH.zPosition = 0.1
                    node.addChild(crossH)
                    let crossV = SKSpriteNode(color: baseColor, size: CGSize(width: tileSize * 0.1, height: tileSize * 0.7))
                    crossV.zPosition = 0.1
                    node.addChild(crossV)
                }
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

            // Cmd+Z for undo
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
