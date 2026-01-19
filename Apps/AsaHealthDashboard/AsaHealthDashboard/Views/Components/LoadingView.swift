//
//  LoadingView.swift
//  AsaHealthDashboard
//
//  ローディング表示
//

import SwiftUI
import AsaUIKit

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AsaColors.coffeeBrown))
                .scaleEffect(1.5)

            Text("データを読み込み中...")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)
        }
    }
}

// MARK: - 空の状態表示

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)?
    var actionTitle: String?

    init(
        icon: String = "chart.bar.xaxis",
        title: String = "データがありません",
        message: String = "まだデータが記録されていません",
        action: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
        self.actionTitle = actionTitle
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AsaColors.mutedSage)

            Text(title)
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            Text(message)
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)
                .multilineTextAlignment(.center)

            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AsaColors.coffeeBrown)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}

#Preview {
    VStack(spacing: 40) {
        LoadingView()

        EmptyStateView(
            icon: "moon.zzz",
            title: "睡眠データがありません",
            message: "Apple Watchで睡眠を記録すると、ここにデータが表示されます"
        )
    }
}
