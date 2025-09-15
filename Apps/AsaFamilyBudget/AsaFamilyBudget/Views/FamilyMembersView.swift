//
//  FamilyMembersView.swift
//  AsaFamilyBudget
//
//  Created by Asa Apps on 2025.
//

import SwiftUI
import AsaUIKit

struct FamilyMembersView: View {
    @EnvironmentObject private var viewModel: BudgetViewModel
    @State private var showingAddMember = false
    @State private var selectedMember: FamilyMember?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - メンバー支出サマリー
                    memberSpendingSummary

                    // MARK: - メンバーリスト
                    membersList
                }
                .padding()
            }
            .navigationTitle("家族メンバー")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMember = true }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddFamilyMemberView()
                    .environmentObject(viewModel)
            }
            .sheet(item: $selectedMember) { member in
                MemberDetailView(member: member)
                    .environmentObject(viewModel)
            }
        }
    }

    // MARK: - Member Spending Summary
    private var memberSpendingSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("メンバー別支出")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            AsaCard {
                if viewModel.memberSpendingData().isEmpty {
                    Text("まだ支出データがありません")
                        .foregroundColor(AsaColors.mutedSage)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    VStack(spacing: 16) {
                        ForEach(viewModel.memberSpendingData(), id: \.0) { memberName, amount in
                            HStack {
                                if let member = viewModel.familyMembers.first(where: { $0.name == memberName }) {
                                    Image(systemName: member.avatarName)
                                        .foregroundColor(Color(hex: member.colorHex) ?? AsaColors.coffeeBrown)
                                        .frame(width: 32, height: 32)
                                        .background(
                                            Color(hex: member.colorHex)?.opacity(0.1) ?? AsaColors.softCream
                                        )
                                        .clipShape(Circle())
                                }

                                VStack(alignment: .leading) {
                                    Text(memberName)
                                        .font(.subheadline)
                                        .foregroundColor(AsaColors.darkSlate)
                                    Text("\(transactionCount(for: memberName))件の取引")
                                        .font(.caption)
                                        .foregroundColor(AsaColors.mutedSage)
                                }

                                Spacer()

                                Text(formatCurrency(amount))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(AsaColors.mocha)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Members List
    private var membersList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("メンバー一覧")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            ForEach(viewModel.familyMembers) { member in
                MemberCard(member: member)
                    .onTapGesture {
                        selectedMember = member
                    }
            }
        }
    }

    // MARK: - Helper Methods
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }

    private func transactionCount(for memberName: String) -> Int {
        viewModel.transactions.filter { $0.member?.name == memberName }.count
    }
}

// MARK: - Member Card
struct MemberCard: View {
    let member: FamilyMember

    var body: some View {
        AsaCard {
            HStack {
                // アバター
                ZStack {
                    Circle()
                        .fill(Color(hex: member.colorHex)?.opacity(0.1) ?? AsaColors.softCream)
                        .frame(width: 50, height: 50)

                    if member.avatarName.contains("face") || member.avatarName.contains("person") {
                        Image(systemName: member.avatarName)
                            .foregroundColor(Color(hex: member.colorHex) ?? AsaColors.coffeeBrown)
                            .font(.title2)
                    } else {
                        Text(member.initials)
                            .font(.headline)
                            .foregroundColor(Color(hex: member.colorHex) ?? AsaColors.coffeeBrown)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name)
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    HStack {
                        Text(member.role.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(roleColor(for: member.role).opacity(0.2))
                            .foregroundColor(roleColor(for: member.role))
                            .cornerRadius(4)

                        if member.isActive {
                            Text("アクティブ")
                                .font(.caption)
                                .foregroundColor(Color.green)
                        } else {
                            Text("非アクティブ")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(AsaColors.mutedSage)
                    .font(.caption)
            }
        }
    }

    private func roleColor(for role: MemberRole) -> Color {
        switch role {
        case .parent:
            return AsaColors.coffeeBrown
        case .child:
            return AsaColors.mocha
        case .viewer:
            return AsaColors.mutedSage
        }
    }
}

// MARK: - Add Family Member View
struct AddFamilyMemberView: View {
    @EnvironmentObject private var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var role: MemberRole = .viewer
    @State private var selectedAvatar = "person.circle.fill"
    @State private var selectedColor = "#C68C53"

    let avatarOptions = [
        "person.circle.fill",
        "person.fill",
        "face.smiling.fill",
        "face.dashed.fill",
        "star.circle.fill"
    ]

    let colorOptions = [
        "#C68C53", // AsaCoffeeBrown
        "#8B5A2B", // AsaMocha
        "#E8D5B9", // AsaSoftCream
        "#2F3E46", // AsaDarkSlate
        "#7A918D"  // AsaMutedSage
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("名前", text: $name)
                    TextField("メールアドレス（任意）", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section("役割") {
                    Picker("役割", selection: $role) {
                        ForEach(MemberRole.allCases, id: \.self) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 4) {
                        if role.canEdit {
                            Label("予算の編集が可能", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Color.green)
                        }
                        if role.canAddTransaction {
                            Label("取引の追加が可能", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Color.green)
                        }
                        if !role.canEdit && !role.canAddTransaction {
                            Label("閲覧のみ可能", systemImage: "eye.fill")
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)
                        }
                    }
                }

                Section("アバター") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                        ForEach(avatarOptions, id: \.self) { avatar in
                            Button(action: { selectedAvatar = avatar }) {
                                Image(systemName: avatar)
                                    .font(.title2)
                                    .foregroundColor(
                                        selectedAvatar == avatar ?
                                        Color(hex: selectedColor) ?? AsaColors.coffeeBrown :
                                        AsaColors.mutedSage
                                    )
                                    .frame(width: 60, height: 60)
                                    .background(
                                        selectedAvatar == avatar ?
                                        Color(hex: selectedColor)?.opacity(0.1) ?? AsaColors.softCream :
                                        Color.clear
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                selectedAvatar == avatar ?
                                                Color(hex: selectedColor) ?? AsaColors.coffeeBrown :
                                                AsaColors.mutedSage.opacity(0.3),
                                                lineWidth: 2
                                            )
                                    )
                                    .cornerRadius(10)
                            }
                        }
                    }
                }

                Section("カラー") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                        ForEach(colorOptions, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(Color(hex: color) ?? AsaColors.coffeeBrown)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                selectedColor == color ?
                                                AsaColors.darkSlate :
                                                Color.clear,
                                                lineWidth: 3
                                            )
                                    )
                            }
                        }
                    }
                }
            }
            .navigationTitle("メンバーを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        addMember()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func addMember() {
        let member = FamilyMember(
            name: name,
            email: email.isEmpty ? nil : email,
            avatarName: selectedAvatar,
            role: role,
            colorHex: selectedColor
        )
        viewModel.addFamilyMember(member)
        dismiss()
    }
}

// MARK: - Member Detail View
struct MemberDetailView: View {
    let member: FamilyMember
    @EnvironmentObject private var viewModel: BudgetViewModel
    @Environment(\.dismiss) private var dismiss

    var memberTransactions: [Transaction] {
        viewModel.transactions.filter { $0.member?.id == member.id }
    }

    var totalSpending: Double {
        memberTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("メンバー情報") {
                    LabeledContent("名前", value: member.name)
                    if let email = member.email {
                        LabeledContent("メールアドレス", value: email)
                    }
                    LabeledContent("役割", value: member.role.rawValue)
                    LabeledContent("参加日") {
                        Text(member.joinedAt, format: .dateTime.year().month().day())
                    }
                    if let lastActive = member.lastActiveAt {
                        LabeledContent("最終アクティブ") {
                            Text(lastActive, format: .dateTime.year().month().day())
                        }
                    }
                }

                Section("権限") {
                    if member.role.canEdit {
                        Label("予算の編集", systemImage: "checkmark.circle.fill")
                            .foregroundColor(Color.green)
                    }
                    if member.role.canAddTransaction {
                        Label("取引の追加", systemImage: "checkmark.circle.fill")
                            .foregroundColor(Color.green)
                    }
                    if !member.role.canEdit && !member.role.canAddTransaction {
                        Label("閲覧のみ", systemImage: "eye.fill")
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }

                Section("活動サマリー") {
                    LabeledContent("取引数", value: "\(memberTransactions.count)件")
                    LabeledContent("総支出", value: formatCurrency(totalSpending))
                }

                if !memberTransactions.isEmpty {
                    Section("最近の取引") {
                        ForEach(memberTransactions.sorted { $0.date > $1.date }.prefix(5)) { transaction in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(transaction.title)
                                        .font(.subheadline)
                                    Text(transaction.date, format: .dateTime.month().day())
                                        .font(.caption)
                                        .foregroundColor(AsaColors.mutedSage)
                                }
                                Spacer()
                                Text(transaction.formattedAmount)
                                    .font(.subheadline)
                                    .foregroundColor(
                                        transaction.type == .income ?
                                        Color.green : AsaColors.mocha
                                    )
                            }
                        }
                    }
                }
            }
            .navigationTitle("メンバー詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "¥0"
    }
}