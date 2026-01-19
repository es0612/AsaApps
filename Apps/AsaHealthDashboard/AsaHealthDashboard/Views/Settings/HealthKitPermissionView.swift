//
//  HealthKitPermissionView.swift
//  AsaHealthDashboard
//
//  HealthKit権限要求画面
//

import SwiftUI
import AsaUIKit

struct HealthKitPermissionView: View {
    let viewModel: HealthDashboardViewModel
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // アイコン
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundColor(AsaColors.coffeeBrown)

            // タイトル
            Text("HealthKitへのアクセス")
                .font(.title2.bold())
                .foregroundColor(AsaColors.darkSlate)

            // 説明
            Text("健康データをダッシュボードに表示するには、\nHealthKitへのアクセス許可が必要です")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)
                .multilineTextAlignment(.center)

            // 読み取るデータの説明
            VStack(alignment: .leading, spacing: 12) {
                Text("読み取るデータ:")
                    .font(.subheadline.bold())
                    .foregroundColor(AsaColors.darkSlate)

                ForEach(HealthCategory.allCases) { category in
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(category.color)
                            .frame(width: 24)

                        Text(category.displayName)
                            .font(.subheadline)
                            .foregroundColor(AsaColors.darkSlate)

                        Spacer()
                    }
                }
            }
            .padding()
            .background(AsaColors.softCream.opacity(0.5))
            .cornerRadius(12)

            Spacer()

            // 権限要求ボタン
            Button {
                Task {
                    isRequesting = true
                    await viewModel.requestHealthKitAuthorization()
                    isRequesting = false
                }
            } label: {
                HStack {
                    if isRequesting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.shield")
                        Text("アクセスを許可")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AsaColors.coffeeBrown)
                .cornerRadius(12)
            }
            .disabled(isRequesting)

            // ステータス表示
            if viewModel.isHealthKitAvailable {
                Text(viewModel.authorizationStatusDescription)
                    .font(.caption)
                    .foregroundColor(AsaColors.mutedSage)
            } else {
                Text("このデバイスではHealthKitを利用できません")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // 設定アプリへの誘導
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("設定アプリで権限を管理")
                    .font(.caption)
                    .foregroundColor(AsaColors.coffeeBrown)
            }
        }
        .padding()
    }
}

#Preview {
    HealthKitPermissionView(viewModel: HealthDashboardViewModel())
}
