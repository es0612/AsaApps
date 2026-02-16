import SwiftUI
import SwiftData
import AsaPapaHubKit
import AsaUIKit

// MARK: - ドメイン選択ビュー

/// 初回起動時のドメイン選択
struct DomainSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State private var selectedDomains: Set<LifeDomain> = Set(LifeDomain.allCases)

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // ヘッダー
            VStack(spacing: 8) {
                Text("ライフドメインを選択")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("管理したいドメインを選択してください。\n後からいつでも変更できます。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)

            // ドメインリスト
            List {
                ForEach(LifeDomain.allCases, id: \.self) { domain in
                    domainRow(domain)
                }
            }
            .listStyle(.insetGrouped)

            // 完了ボタン
            Button {
                saveAndComplete()
            } label: {
                Text("完了 (\(selectedDomains.count)個選択)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        selectedDomains.isEmpty
                            ? AsaColors.mutedSage
                            : AsaColors.coffeeBrown,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
            }
            .disabled(selectedDomains.isEmpty)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle("ドメイン選択")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - ドメイン行

    private func domainRow(_ domain: LifeDomain) -> some View {
        Button {
            if selectedDomains.contains(domain) {
                selectedDomains.remove(domain)
            } else {
                selectedDomains.insert(domain)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: domain.icon)
                    .font(.title3)
                    .foregroundStyle(Color(hex: domain.accentColorHex))
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(domain.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(domainDescription(domain))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: selectedDomains.contains(domain) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(
                        selectedDomains.contains(domain) ? AsaColors.coffeeBrown : .secondary
                    )
                    .font(.title3)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Private

    private func domainDescription(_ domain: LifeDomain) -> String {
        switch domain {
        case .morning: "朝活ルーティンの管理・スコア追跡"
        case .health: "歩数・睡眠・運動の記録"
        case .family: "家族イベント・子供の学習管理"
        case .finance: "資産目標・支出管理"
        case .community: "地域イベント・安全情報"
        case .learning: "学習ストリーク・勉強時間管理"
        }
    }

    private func saveAndComplete() {
        // 設定を保存
        let descriptor = FetchDescriptor<HubUserPreferences>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let prefs = try? modelContext.fetch(descriptor).first {
            prefs.enabledDomains = Array(selectedDomains)
            prefs.updatedAt = Date()
            try? modelContext.save()
        }

        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        isPresented = false
    }
}
