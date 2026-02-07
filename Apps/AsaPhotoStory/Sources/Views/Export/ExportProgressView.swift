import SwiftUI
import AsaUIKit

/// エクスポート進捗ビュー
/// エクスポート処理の進捗を表示し、完了後に共有ボタンを提供する
struct ExportProgressView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Binding var progress: Double
    @Binding var isExporting: Bool
    let onComplete: () -> Void
    let onCancel: () -> Void

    private var isCompleted: Bool { progress >= 1.0 && !isExporting }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                if isExporting {
                    exportingView
                } else if isCompleted {
                    completedView
                }

                Spacer()
            }
            .padding()
            .navigationTitle("エクスポート中")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                        if isCompleted {
                            onComplete()
                        }
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                }
            }
        }
    }

    // MARK: - Subviews

    private var exportingView: some View {
        VStack(spacing: 20) {
            // 進捗リング
            ZStack {
                Circle()
                    .stroke(AsaColors.softCream, lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AsaColors.coffeeBrown, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.title.bold())
                    .foregroundColor(AsaColors.darkSlate)
            }

            Text("エクスポート中...")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            Text("ストーリーを書き出しています")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)

            // キャンセルボタン
            Button("キャンセル") {
                onCancel()
            }
            .foregroundColor(.red)
            .padding(.top, 8)
        }
    }

    private var completedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("エクスポート完了!")
                .font(.title2.bold())
                .foregroundColor(AsaColors.darkSlate)

            Text("ストーリーが正常に書き出されました")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)

            AsaButton(
                title: "完了",
                action: {
                    dismiss()
                    onComplete()
                },
                color: AsaColors.coffeeBrown
            )
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    ExportProgressView(
        progress: .constant(0.5),
        isExporting: .constant(true),
        onComplete: {},
        onCancel: {}
    )
}
