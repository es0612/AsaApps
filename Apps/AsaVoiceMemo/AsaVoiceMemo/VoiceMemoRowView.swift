//
//  VoiceMemoRowView.swift
//  AsaVoiceMemo
//  
//  Created on 2025/07/28
//

import SwiftUI

struct VoiceMemoRowView: View {
    let voiceMemo: VoiceMemo
    @Bindable var viewModel: VoiceMemoViewModel
    @State private var isEditingTitle = false
    @State private var editingTitle = ""
    @State private var isShowingPlayer = false
    
    var body: some View {
        HStack(spacing: 16) {
            // 再生ボタン
            playButton
            
            // メモ情報
            VStack(alignment: .leading, spacing: 4) {
                // タイトル
                titleView
                
                // メタデータ
                metadataView
            }
            
            Spacer()
            
            // 継続時間
            durationView
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            isShowingPlayer = true
        }
        .sheet(isPresented: $isShowingPlayer) {
            VoiceMemoPlayerView(voiceMemo: voiceMemo, viewModel: viewModel)
        }
        .alert("タイトル編集", isPresented: $isEditingTitle) {
            TextField("タイトル", text: $editingTitle)
            Button("キャンセル", role: .cancel) { }
            Button("保存") {
                viewModel.updateVoiceMemoTitle(voiceMemo, newTitle: editingTitle)
            }
        }
        .onAppear {
            editingTitle = voiceMemo.title
        }
    }
    
    // MARK: - Play Button
    private var playButton: some View {
        Button {
            viewModel.playVoiceMemo(voiceMemo)
        } label: {
            ZStack {
                Circle()
                    .fill(isCurrentlyPlaying ? Color.red : Color("AsaCoffeeBrown"))
                    .frame(width: 50, height: 50)
                
                Image(systemName: isCurrentlyPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .offset(x: isCurrentlyPlaying ? 0 : 2) // 再生アイコンを少し右にずらす
            }
        }
        .scaleEffect(isCurrentlyPlaying ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isCurrentlyPlaying)
    }
    
    // MARK: - Title View
    private var titleView: some View {
        HStack {
            Text(voiceMemo.title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Button {
                editingTitle = voiceMemo.title
                isEditingTitle = true
            } label: {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Metadata View
    private var metadataView: some View {
        HStack(spacing: 12) {
            // 作成日時
            Label(voiceMemo.relativeCreatedAt, systemImage: "clock")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // ファイル存在チェック
            if !voiceMemo.fileExists {
                Label("ファイル無し", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Duration View
    private var durationView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(voiceMemo.formattedDuration)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            // 現在再生中の場合、進捗表示
            if isCurrentlyPlaying {
                progressIndicator
            }
        }
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        VStack(spacing: 2) {
            // 進捗バー
            ProgressView(value: viewModel.audioPlayerManager.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color("AsaCoffeeBrown")))
                .frame(width: 60)
            
            // 現在時間 / 総時間
            Text("\(viewModel.audioPlayerManager.formattedCurrentTime) / \(viewModel.audioPlayerManager.formattedDuration)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Computed Properties
    private var isCurrentlyPlaying: Bool {
        return viewModel.isCurrentlyPlaying(voiceMemo)
    }
}

#Preview {
    let voiceMemo = VoiceMemo(
        title: "サンプル録音",
        fileURL: URL(fileURLWithPath: "/tmp/sample.m4a"),
        duration: 125.5
    )
    
    VoiceMemoRowView(
        voiceMemo: voiceMemo,
        viewModel: VoiceMemoViewModel()
    )
    .padding()
}