import SwiftUI
import AsaUIKit

struct HelpView: View {
    @Environment(ARCardViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                AsaColors.softCream.opacity(0.3)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        welcomeSection
                        buttonsSection
                        troubleshootingSection
                        tipsSection
                        restartOnboardingSection
                    }
                    .padding()
                }
            }
            .navigationTitle("ヘルプ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                }
            }
        }
    }

    private var welcomeSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "hand.wave.fill")
                        .font(.title)
                        .foregroundColor(AsaColors.coffeeBrown)

                    Text("AsaARCard へようこそ")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AsaColors.darkSlate)
                }

                Text("拡張現実（AR）を使ってあなたの名刺を3D空間に表示するアプリです。")
                    .font(.body)
                    .foregroundColor(AsaColors.darkSlate.opacity(0.8))
                    .lineSpacing(4)
            }
        }
    }

    private var buttonsSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("ボタンの機能説明")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                VStack(spacing: 12) {
                    HelpButtonRow(
                        icon: "questionmark.circle.fill",
                        color: AsaColors.softCream,
                        title: "ヘルプ",
                        description: "このヘルプ画面を表示します"
                    )

                    HelpButtonRow(
                        icon: "eye.fill",
                        color: AsaColors.coffeeBrown,
                        title: "名刺表示/非表示",
                        description: "AR名刺を表示または非表示にします。平面検出後に使用可能です"
                    )

                    HelpButtonRow(
                        icon: "arrow.triangle.2.circlepath",
                        color: AsaColors.mutedSage,
                        title: "名刺回転",
                        description: "名刺を180度回転して裏面を表示します。名刺表示中のみ使用可能です"
                    )

                    HelpButtonRow(
                        icon: "gearshape.fill",
                        color: AsaColors.mocha,
                        title: "設定",
                        description: "名刺情報を編集できます。名前、会社名、連絡先などを設定してください"
                    )
                }
            }
        }
    }

    private var troubleshootingSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.title3)
                        .foregroundColor(AsaColors.mocha)

                    Text("トラブルシューティング")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                }

                VStack(alignment: .leading, spacing: 12) {
                    TroubleshootingItem(
                        problem: "名刺が表示されない",
                        solution: "1. カメラを床や机などの平面に向けてください\n2. 明るい場所で使用してください\n3. デバイスをゆっくり動かして平面検出を待ってください"
                    )

                    TroubleshootingItem(
                        problem: "AR追跡が不安定",
                        solution: "1. デバイスの動きをゆっくりにしてください\n2. 周囲に特徴的な物体がある場所で使用してください\n3. アプリを再起動してみてください"
                    )

                    TroubleshootingItem(
                        problem: "名刺の内容が古い",
                        solution: "設定ボタンから最新の情報に更新してください。保存後、名刺を再表示すると反映されます"
                    )
                }
            }
        }
    }

    private var tipsSection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.title3)
                        .foregroundColor(AsaColors.coffeeBrown)

                    Text("使い方のコツ")
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)
                }

                VStack(alignment: .leading, spacing: 10) {
                    TipItem(tip: "明るい場所で使用すると平面検出がスムーズです")
                    TipItem(tip: "平面検出は床や机など、広くて平らな面で最も効果的です")
                    TipItem(tip: "名刺を回転させると、AsaAppsブランドデザインが見られます")
                    TipItem(tip: "デバイスをゆっくり動かすと追跡が安定します")
                }
            }
        }
    }

    private var restartOnboardingSection: some View {
        VStack(spacing: 12) {
            Text("初回ガイドをもう一度見たい場合")
                .font(.subheadline)
                .foregroundColor(AsaColors.darkSlate.opacity(0.8))

            AsaButton(
                title: "チュートリアルを再表示",
                action: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        UserDefaults.standard.set(false, forKey: "AsaARCard_HasCompletedOnboarding")
                        viewModel.showingOnboarding = true
                    }
                },
                color: AsaColors.mutedSage
            )
        }
    }
}

struct HelpButtonRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(color, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AsaColors.darkSlate)

                Text(description)
                    .font(.caption)
                    .foregroundColor(AsaColors.darkSlate.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(10)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct TroubleshootingItem: View {
    let problem: String
    let solution: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)

                Text(problem)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AsaColors.darkSlate)
            }

            Text(solution)
                .font(.caption)
                .foregroundColor(AsaColors.darkSlate.opacity(0.8))
                .padding(.leading, 24)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(AsaColors.softCream.opacity(0.3))
        .cornerRadius(8)
    }
}

struct TipItem: View {
    let tip: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)

            Text(tip)
                .font(.caption)
                .foregroundColor(AsaColors.darkSlate.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    HelpView()
        .environment(ARCardViewModel())
}