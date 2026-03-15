import SwiftUI

struct LevelSelectView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss

    private let levelCount = LevelManager.shared.levelCount
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    levelSection(title: "Beginner", range: 0..<min(49, levelCount))
                    levelSection(title: "Standard", range: 49..<min(91, levelCount))
                    levelSection(title: "Expert", range: 91..<levelCount)
                }
                .padding()
            }
            .navigationTitle("Select Level")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func levelSection(title: String, range: Range<Int>) -> some View {
        if !range.isEmpty {
            Section {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(range, id: \.self) { index in
                        NavigationLink {
                            GameView()
                                .onAppear {
                                    gameManager.loadLevel(index)
                                }
                        } label: {
                            levelCell(index: index)
                        }
                    }
                }
            } header: {
                Text(title)
                    .font(.title2.weight(.bold))
                    .padding(.top, 4)
            }
        }
    }

    private func levelCell(index: Int) -> some View {
        let completed = PersistenceManager.shared.isLevelCompleted(index)
        let bestMoves = PersistenceManager.shared.bestMoves(forLevel: index)

        return VStack(spacing: 4) {
            Text("\(index + 1)")
                .font(.body.weight(.semibold).monospacedDigit())

            if let best = bestMoves {
                Text("\(best)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(completed ? Color.green.opacity(0.15) : Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(completed ? Color.green.opacity(0.4) : Color.clear, lineWidth: 2)
        )
    }
}
