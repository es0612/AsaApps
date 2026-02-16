import SwiftUI
import AsaUIKit

// MARK: - About ビュー

/// アプリ情報と100本ノック完走記念メッセージ
struct AboutView: View {
    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // アプリアイコン
                VStack(spacing: 12) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AsaColors.coffeeBrown, AsaColors.mocha],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("AsaPapaHub")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("バージョン 1.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // 完走記念メッセージ
                completionMessage

                // プロジェクト情報
                projectInfo

                // クレジット
                creditsSection
            }
            .padding()
        }
        .navigationTitle("このアプリについて")
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - 完走記念メッセージ

    private var completionMessage: some View {
        VStack(spacing: 12) {
            Text("SwiftUI 100本ノック完走！")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AsaColors.coffeeBrown)

            Text("""
            朝活パパエンジニアとして、1年間で100のSwiftUIアプリを作成するという \
            挑戦を達成しました。このAsaPapaHubは、その集大成として作られた \
            ライフハブアプリです。

            毎朝の積み重ねが、大きな成果を生みました。 \
            これからも朝活と学習を続けていきましょう！
            """)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AsaColors.softCream.opacity(0.3))
        )
    }

    // MARK: - プロジェクト情報

    private var projectInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("プロジェクト情報")
                .font(.headline)

            infoRow(label: "アプリ番号", value: "#100 / 100")
            infoRow(label: "カテゴリ", value: "ライフスタイル")
            infoRow(label: "フレームワーク", value: "SwiftUI + SwiftData")
            infoRow(label: "Swift", value: "6.0")
            infoRow(label: "対応OS", value: "iOS 26.0+")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
    }

    // MARK: - クレジット

    private var creditsSection: some View {
        VStack(spacing: 8) {
            Text("Made with Coffee & Code")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("by 朝活パパエンジニア")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(AsaColors.coffeeBrown)
        }
    }

    // MARK: - Private

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
