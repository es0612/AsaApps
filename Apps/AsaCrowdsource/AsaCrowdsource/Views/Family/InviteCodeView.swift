//
//  InviteCodeView.swift
//  AsaCrowdsource
//
//  招待コード表示画面
//

import SwiftUI
import AsaUIKit

struct InviteCodeView: View {
    // MARK: - Properties

    @EnvironmentObject private var familyViewModel: FamilyGroupViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isCopied = false
    @State private var showRegenerateAlert = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // ヘッダー
                headerSection

                // 招待コード表示
                inviteCodeSection

                // アクションボタン
                actionButtons

                // 説明
                instructionSection

                Spacer()
            }
            .padding(24)
            .background(Color(AsaColors.softCream).opacity(0.3))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(Color(AsaColors.coffeeBrown))
                }
            }
            .alert("招待コードを再生成", isPresented: $showRegenerateAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("再生成", role: .destructive) {
                    Task {
                        await familyViewModel.regenerateInviteCode()
                    }
                }
            } message: {
                Text("現在の招待コードは使えなくなります。新しいコードを生成しますか？")
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(Color(AsaColors.coffeeBrown))

            Text("メンバーを招待")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(AsaColors.darkSlate))

            Text("下記のコードを共有して、\n家族をグループに招待しましょう")
                .font(.subheadline)
                .foregroundColor(Color(AsaColors.mutedSage))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    private var inviteCodeSection: some View {
        VStack(spacing: 16) {
            Text(familyViewModel.groupName)
                .font(.subheadline)
                .foregroundColor(Color(AsaColors.mutedSage))

            // 招待コード
            HStack(spacing: 8) {
                ForEach(Array(familyViewModel.inviteCode.enumerated()), id: \.offset) { _, char in
                    Text(String(char))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(AsaColors.darkSlate))
                        .frame(width: 44, height: 56)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }

            // コピー済み表示
            if isCopied {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("コピーしました")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding()
        .background(Color(AsaColors.softCream))
        .cornerRadius(16)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // コピーボタン
            Button {
                UIPasteboard.general.string = familyViewModel.inviteCode
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCopied = true
                }
                // 2秒後にリセット
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCopied = false
                    }
                }
            } label: {
                HStack {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    Text(isCopied ? "コピーしました" : "コードをコピー")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(AsaColors.coffeeBrown))
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // 共有ボタン
            ShareLink(
                item: "「\(familyViewModel.groupName)」の招待コード: \(familyViewModel.inviteCode)\n\nAsaCrowdsourceアプリで入力してください。",
                subject: Text("グループへの招待")
            ) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("共有する")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(AsaColors.mutedSage).opacity(0.2))
                .foregroundColor(Color(AsaColors.darkSlate))
                .cornerRadius(12)
            }

            // 再生成ボタン（オーナーのみ）
            if familyViewModel.isOwner {
                Button {
                    showRegenerateAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("コードを再生成")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(AsaColors.mutedSage))
                }
                .padding(.top, 8)
            }
        }
    }

    private var instructionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("招待方法")
                .font(.headline)
                .foregroundColor(Color(AsaColors.darkSlate))

            VStack(alignment: .leading, spacing: 8) {
                instructionRow(number: 1, text: "上記のコードをコピーまたは共有")
                instructionRow(number: 2, text: "相手にAsaCrowdsourceアプリを開いてもらう")
                instructionRow(number: 3, text: "「グループに参加」からコードを入力")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    private func instructionRow(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color(AsaColors.coffeeBrown))
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundColor(Color(AsaColors.darkSlate))
        }
    }
}

// MARK: - Preview

#Preview {
    InviteCodeView()
        .environmentObject(FamilyGroupViewModel())
}
