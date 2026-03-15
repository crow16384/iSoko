import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.brown)
                        .padding(.top, 30)

                    Text("Sokoban")
                        .font(.largeTitle.weight(.bold))

                    Text("138 Puzzle Levels")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        infoRow("Original Game", value: "Win32 Sokoban v2.0")
                        infoRow("Original Author", value: "Vladimir A. Larchenko")
                        infoRow("Original Handle", value: "Crow16384")
                        Divider()
                        infoRow("iPad Version", value: "Swift + SpriteKit")
                        infoRow("Levels", value: "138 (Beginner, Standard, Expert)")
                        Divider()
                        infoRow("Expert Levels", value: "Yoshio Murase collection")
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Text("Push all boxes onto the goal squares.\nSwipe to move. Tap undo to take back a move.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("About")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
