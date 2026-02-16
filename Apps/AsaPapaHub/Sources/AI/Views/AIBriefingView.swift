//
//  AIBriefingView.swift
//  AsaPapaHub
//
//  AIブリーフィングカードの表示ビュー
//  ストリーミング対応・フォールバックUI付き
//

import SwiftUI
import AsaPapaHubKit

// MARK: - AIBriefingView

/// AI ブリーフィングの表示ビュー
struct AIBriefingView: View {
    // MARK: - Properties

    let dashboard: HubDashboard
    let aiService: PapaHubAIService

    @State private var briefing: MorningBriefingGenerable?
    @State private var streamingGreeting = ""
    @State private var streamingSchedule = ""
    @State private var streamingHealth = ""
    @State private var streamingMotivation = ""
    @State private var isStreaming = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let coffeeBrown = Color(red: 0.776, green: 0.549, blue: 0.325)
    private let softCream = Color(red: 0.910, green: 0.835, blue: 0.725)
    private let darkSlate = Color(red: 0.184, green: 0.243, blue: 0.275)

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            headerSection

            if let briefing {
                // AI生成完了後の表示
                briefingContent(briefing)
            } else if isStreaming {
                // ストリーミング中の表示
                streamingContent
            } else if !aiService.isSessionReady {
                // AI非対応時のフォールバック
                fallbackContent
            } else {
                // 生成開始ボタン
                generateButton
            }
        }
        .padding(16)
        .background(softCream.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .alert("エラー", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(coffeeBrown)

            Text("AIブリーフィング")
                .font(.headline)
                .foregroundStyle(darkSlate)

            Spacer()

            if aiService.isSessionReady {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            } else {
                Image(systemName: "cpu")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

    private func briefingContent(_ data: MorningBriefingGenerable) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            briefingRow(icon: "sun.max.fill", title: "挨拶", text: data.greeting)
            briefingRow(icon: "calendar", title: "スケジュール", text: data.scheduleOverview)
            briefingRow(icon: "heart.fill", title: "健康", text: data.healthAdvice)
            briefingRow(icon: "star.fill", title: "応援", text: data.motivationalMessage)

            // 再生成ボタン
            Button {
                briefing = nil
                Task { await generateBriefing() }
            } label: {
                Label("再生成", systemImage: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(coffeeBrown)
            }
            .padding(.top, 4)
        }
    }

    private var streamingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !streamingGreeting.isEmpty {
                briefingRow(icon: "sun.max.fill", title: "挨拶", text: streamingGreeting)
            }
            if !streamingSchedule.isEmpty {
                briefingRow(icon: "calendar", title: "スケジュール", text: streamingSchedule)
            }
            if !streamingHealth.isEmpty {
                briefingRow(icon: "heart.fill", title: "健康", text: streamingHealth)
            }
            if !streamingMotivation.isEmpty {
                briefingRow(icon: "star.fill", title: "応援", text: streamingMotivation)
            }

            StreamingResponseView(text: "", isLoading: true)
        }
    }

    private var fallbackContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            let fallback = aiService.generateFallbackBriefing(dashboard: dashboard)
            briefingRow(icon: "sun.max.fill", title: "挨拶", text: fallback.greeting)
            briefingRow(icon: "calendar", title: "スケジュール", text: fallback.scheduleOverview)
            briefingRow(icon: "heart.fill", title: "健康", text: fallback.healthAdvice)
            briefingRow(icon: "star.fill", title: "応援", text: fallback.motivationalMessage)

            HStack {
                Image(systemName: "info.circle")
                    .font(.caption2)
                Text("AI非対応デバイスのため定型メッセージを表示しています")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        }
    }

    private var generateButton: some View {
        Button {
            Task { await generateBriefing() }
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("今日のブリーフィングを生成")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(coffeeBrown)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(aiService.isProcessing)
    }

    private func briefingRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(coffeeBrown)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(darkSlate)
            }
        }
    }

    // MARK: - Methods

    private func generateBriefing() async {
        isStreaming = true
        streamingGreeting = ""
        streamingSchedule = ""
        streamingHealth = ""
        streamingMotivation = ""

        do {
            for try await partial in aiService.streamMorningBriefing(dashboard: dashboard) {
                streamingGreeting = partial.greeting ?? ""
                streamingSchedule = partial.scheduleOverview ?? ""
                streamingHealth = partial.healthAdvice ?? ""
                streamingMotivation = partial.motivationalMessage ?? ""
            }

            // ストリーミング完了後、最終結果を取得
            let result = try await aiService.generateMorningBriefing(dashboard: dashboard)
            briefing = result
        } catch {
            // ストリーミング中にエラーが出た場合はフォールバック
            briefing = aiService.generateFallbackBriefing(dashboard: dashboard)
            errorMessage = error.localizedDescription
            showError = true
        }

        isStreaming = false
    }
}
