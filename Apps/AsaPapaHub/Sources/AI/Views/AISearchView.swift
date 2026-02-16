//
//  AISearchView.swift
//  AsaPapaHub
//
//  自然言語検索ビュー
//  AIによる検索結果と関連ドメイン・アクション提案を表示
//

import SwiftUI

// MARK: - AISearchView

/// AI 自然言語検索ビュー
struct AISearchView: View {
    // MARK: - Properties

    let aiService: PapaHubAIService

    @State private var searchQuery = ""
    @State private var searchResult: AISearchResult?
    @State private var isSearching = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let coffeeBrown = Color(red: 0.776, green: 0.549, blue: 0.325)
    private let softCream = Color(red: 0.910, green: 0.835, blue: 0.725)
    private let darkSlate = Color(red: 0.184, green: 0.243, blue: 0.275)
    private let mutedSage = Color(red: 0.478, green: 0.569, blue: 0.553)

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 検索バー
            searchBar

            // 検索結果
            if let result = searchResult {
                resultContent(result)
            } else if isSearching {
                StreamingResponseView(text: "", isLoading: true)
            } else {
                placeholderContent
            }
        }
        .padding(16)
        .background(softCream.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .alert("検索エラー", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkle.magnifyingglass")
                .foregroundStyle(coffeeBrown)

            TextField("何でも聞いてください...", text: $searchQuery)
                .textFieldStyle(.plain)
                .onSubmit {
                    Task { await performSearch() }
                }

            if isSearching {
                ProgressView()
                    .controlSize(.small)
            } else if !searchQuery.isEmpty {
                Button {
                    Task { await performSearch() }
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(coffeeBrown)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func resultContent(_ result: AISearchResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 回答
            Text(result.answer)
                .font(.body)
                .foregroundStyle(darkSlate)

            // 関連ドメインタグ
            if !result.relatedDomains.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("関連ドメイン")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 6) {
                        ForEach(result.relatedDomains, id: \.self) { domain in
                            Text(domain)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(coffeeBrown.opacity(0.15))
                                .foregroundStyle(coffeeBrown)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // 提案アクション
            if !result.suggestedActions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("おすすめアクション")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    ForEach(result.suggestedActions, id: \.self) { action in
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle")
                                .font(.caption)
                                .foregroundStyle(coffeeBrown)

                            Text(action)
                                .font(.subheadline)
                                .foregroundStyle(darkSlate)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private var placeholderContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.magnifyingglass")
                .font(.title2)
                .foregroundStyle(mutedSage)

            Text("AIに質問してみましょう")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("「今週の歩数の傾向は？」「睡眠を改善するには？」など")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Methods

    private func performSearch() async {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        isSearching = true
        searchResult = nil

        do {
            searchResult = try await aiService.searchNaturalLanguage(query: searchQuery)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isSearching = false
    }
}

// MARK: - FlowLayout

/// タグを折り返し配置するレイアウト
struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func arrangeSubviews(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (positions: [CGPoint], sizes: [CGSize], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)

            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalHeight = currentY + lineHeight
        }

        return (positions, sizes, CGSize(width: maxWidth, height: totalHeight))
    }
}
