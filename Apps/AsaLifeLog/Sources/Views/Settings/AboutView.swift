import SwiftUI

// MARK: - AboutView

/// アプリ情報ビュー
struct AboutView: View {
    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.accentColor)

                    Text("AsaLifeLog")
                        .font(.title.weight(.bold))

                    Text("あなたの毎日を美しく記録する")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            Section("アプリ情報") {
                LabeledContent("バージョン", value: "1.0")
                LabeledContent("開発者", value: "朝活パパエンジニア")
                LabeledContent("対応OS", value: "iOS 18.0+")
            }

            Section("100本ノック") {
                LabeledContent("アプリ番号", value: "#99")
                Text("AsaAppsプロジェクトの99番目のアプリです。ライフログの統合管理を目的とし、HealthKit、CoreLocation、CoreMotion、Photos、Swift Charts、WidgetKitなど複数のAppleフレームワークを統合しています。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("アプリについて")
    }
}
