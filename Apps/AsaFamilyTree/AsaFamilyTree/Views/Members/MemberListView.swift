import SwiftUI
import AsaFamilyTreeKit
import AsaUIKit

struct MemberListView: View {
    // MARK: - Environment

    @Environment(FamilyTreeViewModel.self) private var viewModel

    // MARK: - State

    @State private var showingAddMemberSheet = false
    @State private var selectedMemberForDetail: FamilyMember?

    // MARK: - Body

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                if viewModel.appState == .loading {
                    ProgressView("読み込み中...")
                } else if viewModel.filteredMembers.isEmpty {
                    emptyStateView
                } else {
                    memberListContent
                }
            }
            .navigationTitle("メンバー")
            .searchable(text: $viewModel.searchQuery, prompt: "名前で検索")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        filterMenu

                        Button {
                            showingAddMemberSheet = true
                        } label: {
                            Image(systemName: "person.badge.plus")
                        }
                        .disabled(viewModel.currentTree == nil)
                    }
                }
            }
            .sheet(isPresented: $showingAddMemberSheet) {
                AddMemberSheet()
            }
            .sheet(item: $selectedMemberForDetail) { member in
                MemberDetailView(member: member)
            }
        }
    }

    // MARK: - Member List Content

    private var memberListContent: some View {
        List {
            // 世代別にグループ化して表示
            let membersByGeneration = groupMembersByGeneration()
            let sortedGenerations = membersByGeneration.keys.sorted()

            ForEach(sortedGenerations, id: \.self) { generation in
                Section("第\(generation + 1)世代") {
                    ForEach(membersByGeneration[generation] ?? [], id: \.id) { member in
                        MemberRowView(member: member)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedMemberForDetail = member
                            }
                    }
                    .onDelete { indexSet in
                        deleteMembers(at: indexSet, generation: generation, members: membersByGeneration[generation] ?? [])
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundStyle(AsaColors.mutedSage)

            if viewModel.searchQuery.isEmpty {
                Text("メンバーがいません")
                    .font(.title3)
                    .fontWeight(.medium)

                Text("家族メンバーを追加しましょう")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Button(action: {
                    showingAddMemberSheet = true
                }) {
                    Label("メンバーを追加", systemImage: "person.badge.plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(AsaColors.coffeeBrown)
                        .clipShape(Capsule())
                }
                .disabled(viewModel.currentTree == nil)
            } else {
                Text("検索結果がありません")
                    .font(.title3)
                    .fontWeight(.medium)

                Text("「\(viewModel.searchQuery)」に一致するメンバーは見つかりませんでした")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    // MARK: - Filter Menu

    private var filterMenu: some View {
        @Bindable var viewModel = viewModel

        return Menu {
            Toggle("存命のみ表示", isOn: $viewModel.showOnlyAlive)

            if !viewModel.generations.isEmpty {
                Divider()
                Menu("世代でフィルター") {
                    Button("すべて") {
                        viewModel.selectedGeneration = nil
                    }
                    ForEach(viewModel.generations, id: \.self) { generation in
                        Button("第\(generation + 1)世代") {
                            viewModel.selectedGeneration = generation
                        }
                    }
                }
            }
        } label: {
            Image(systemName: filterIsActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }

    private var filterIsActive: Bool {
        viewModel.showOnlyAlive || viewModel.selectedGeneration != nil
    }

    // MARK: - Helper Methods

    private func groupMembersByGeneration() -> [Int: [FamilyMember]] {
        viewModel.currentTree?.calculateGenerations()

        var result: [Int: [FamilyMember]] = [:]
        for member in viewModel.filteredMembers {
            result[member.generation, default: []].append(member)
        }

        // 各世代内で名前順にソート
        for generation in result.keys {
            result[generation]?.sort { $0.fullName < $1.fullName }
        }

        return result
    }

    private func deleteMembers(at indexSet: IndexSet, generation: Int, members: [FamilyMember]) {
        Task {
            for index in indexSet {
                let member = members[index]
                try? await viewModel.deleteMember(member)
            }
        }
    }
}

// MARK: - Member Row View

struct MemberRowView: View {
    let member: FamilyMember

    var body: some View {
        HStack(spacing: 12) {
            // プロフィール画像
            ZStack {
                Circle()
                    .fill(member.gender.nodeBackgroundColor)
                    .frame(width: 44, height: 44)

                if let imageData = member.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Image(systemName: member.gender.iconName)
                        .font(.title2)
                        .foregroundStyle(member.gender.nodeBorderColor)
                }

                Circle()
                    .strokeBorder(member.gender.nodeBorderColor, lineWidth: 2)
                    .frame(width: 44, height: 44)
            }
            .opacity(member.isAlive ? 1.0 : 0.6)

            // 名前と詳細
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.fullName)
                        .font(.headline)

                    if !member.isAlive {
                        Text("故人")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 8) {
                    if let age = member.age {
                        Text(member.isAlive ? "\(age)歳" : "享年\(age)歳")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !member.lifeSpanString.isEmpty {
                        Text(member.lifeSpanString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // 関係者数
            VStack(alignment: .trailing, spacing: 2) {
                if !member.children.isEmpty {
                    Text("\(member.children.count)人の子")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if !member.spouses.isEmpty {
                    Text("配偶者あり")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    MemberListView()
        .environment(FamilyTreeViewModel())
}
