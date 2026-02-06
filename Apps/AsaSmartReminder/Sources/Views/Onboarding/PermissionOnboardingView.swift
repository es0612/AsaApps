import AsaSmartReminderKit
import AsaUIKit
import SwiftUI

// MARK: - 権限オンボーディング

struct PermissionOnboardingView: View {
    let permissionService: PermissionService
    let onComplete: () -> Void

    @State private var currentStep = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // アイコン
            Image(systemName: stepIcon)
                .font(.system(size: 80))
                .foregroundStyle(AsaColors.coffeeBrown)
                .symbolEffect(.bounce, value: currentStep)

            // タイトル
            Text(stepTitle)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // 説明
            Text(stepDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // ステップインジケーター
            HStack(spacing: 8) {
                ForEach(0 ..< 3, id: \.self) { step in
                    Circle()
                        .fill(step == currentStep ? AsaColors.coffeeBrown : AsaColors.softCream)
                        .frame(width: 8, height: 8)
                }
            }

            // アクションボタン
            AsaButton(title: stepButtonTitle) {
                Task {
                    await handleStepAction()
                }
            }
            .padding(.horizontal, 32)

            // スキップ
            if currentStep < 2 {
                Button("スキップ") {
                    onComplete()
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // MARK: - ステップ情報

    private var stepIcon: String {
        switch currentStep {
        case 0: "map.fill"
        case 1: "location.fill"
        default: "bell.fill"
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case 0: "ようこそ AsaSmartReminder へ"
        case 1: "位置情報の許可"
        default: "通知の許可"
        }
    }

    private var stepDescription: String {
        switch currentStep {
        case 0:
            "場所に基づいてリマインダーを自動通知するアプリです。スーパーに着いたら買い物リストを、学校を出たら帰宅連絡を通知します。"
        case 1:
            "ジオフェンスによる到着・離脱検知のため、位置情報への常時アクセスが必要です。バッテリー消費は最小限に抑えられます。"
        default:
            "場所に到着・離脱した時にリマインダーを通知するため、通知の許可が必要です。"
        }
    }

    private var stepButtonTitle: String {
        switch currentStep {
        case 0: "はじめる"
        case 1: "位置情報を許可"
        default: "通知を許可"
        }
    }

    // MARK: - アクション

    private func handleStepAction() async {
        switch currentStep {
        case 0:
            withAnimation {
                currentStep = 1
            }
        case 1:
            await permissionService.requestLocationWhenInUse()
            await permissionService.requestLocationAlways()
            withAnimation {
                currentStep = 2
            }
        default:
            await permissionService.requestNotificationPermission()
            onComplete()
        }
    }
}
