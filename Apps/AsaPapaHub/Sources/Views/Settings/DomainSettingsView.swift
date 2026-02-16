import SwiftUI
import AsaPapaHubKit
import AsaUIKit

// MARK: - ドメイン設定ビュー

/// 各ドメインの有効・無効を切り替える設定
struct DomainSettingsView: View {
    @Binding var preferences: HubUserPreferences?

    // MARK: - Body

    var body: some View {
        List {
            Section {
                ForEach(LifeDomain.allCases, id: \.self) { domain in
                    Toggle(isOn: binding(for: domain)) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(domain.displayName)
                                    .font(.body)
                                Text("ドメインの表示を切り替えます")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: domain.icon)
                                .foregroundStyle(Color(hex: domain.accentColorHex))
                        }
                    }
                    .tint(AsaColors.coffeeBrown)
                }
            } header: {
                Text("表示するドメイン")
            } footer: {
                Text("無効にしたドメインはダッシュボードに表示されません。")
            }
        }
        .navigationTitle("ドメイン設定")
    }

    // MARK: - Private

    private func binding(for domain: LifeDomain) -> Binding<Bool> {
        Binding(
            get: {
                preferences?.enabledDomains.contains(domain) ?? true
            },
            set: { isEnabled in
                guard var prefs = preferences else { return }
                var domains = prefs.enabledDomains
                if isEnabled {
                    if !domains.contains(domain) {
                        domains.append(domain)
                    }
                } else {
                    domains.removeAll { $0 == domain }
                }
                prefs.enabledDomains = domains
                prefs.updatedAt = Date()
            }
        )
    }
}
