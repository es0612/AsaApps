import SwiftUI

// MARK: - QuickControlCard

/// クイックアクションカード（シーン実行用）
struct QuickControlCard: View {
    // MARK: - Properties

    let scene: SmartScene
    let onExecute: () async -> Void

    @State private var isExecuting = false

    // MARK: - Body

    var body: some View {
        Button {
            executeScene()
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: scene.colorHex).opacity(0.2))
                        .frame(width: 56, height: 56)

                    if isExecuting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: scene.iconName)
                            .font(.system(size: 24))
                            .foregroundStyle(Color(hex: scene.colorHex))
                    }
                }

                Text(scene.name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: scene.colorHex).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isExecuting)
    }

    // MARK: - Private Methods

    private func executeScene() {
        isExecuting = true
        Task {
            await onExecute()
            isExecuting = false
        }
    }
}

// MARK: - QuickControlGrid

/// クイックアクショングリッド
struct QuickControlGrid: View {
    let scenes: [SmartScene]
    let onExecute: (SmartScene) async -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("クイックアクション")
                .font(.headline)
                .foregroundStyle(.white)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(scenes) { scene in
                    QuickControlCard(scene: scene) {
                        await onExecute(scene)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Quick Controls") {
    let scenes = [
        SmartScene(name: "おやすみ", iconName: "moon.stars.fill", colorHex: "5E5CE6"),
        SmartScene(name: "おはよう", iconName: "sun.max.fill", colorHex: "FF9F0A"),
        SmartScene(name: "外出", iconName: "figure.walk", colorHex: "30D158"),
        SmartScene(name: "帰宅", iconName: "house.fill", colorHex: "C68C53")
    ]

    QuickControlGrid(scenes: scenes) { scene in
        print("Executing: \(scene.name)")
    }
    .padding()
    .background(Color.asaDarkSlate)
}
