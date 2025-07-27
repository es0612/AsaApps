//
//  VoiceMemoPlayerView.swift
//  AsaVoiceMemo
//  
//  Created on 2025/07/28
//

import SwiftUI

struct VoiceMemoPlayerView: View {
    let voiceMemo: VoiceMemo
    @Bindable var viewModel: VoiceMemoViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isEditingTitle = false
    @State private var editingTitle = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // タイトル表示
                titleSection
                
                // メタデータ表示
                metadataSection
                
                // 再生進捗表示
                progressSection
                
                // 再生コントロール
                playbackControls
                
                // 音量調整
                volumeControl
                
                Spacer()
            }
            .padding()
            .navigationTitle("音声再生")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            editingTitle = voiceMemo.title
                            isEditingTitle = true
                        } label: {
                            Label("タイトルを編集", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            viewModel.deleteVoiceMemo(voiceMemo)
                            dismiss()
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            // この音声メモが現在再生中でない場合、読み込む
            if viewModel.audioPlayerManager.currentVoiceMemo?.id != voiceMemo.id {
                viewModel.audioPlayerManager.loadVoiceMemo(voiceMemo)
            }
        }
        .alert("タイトル編集", isPresented: $isEditingTitle) {
            TextField("タイトル", text: $editingTitle)
            Button("キャンセル", role: .cancel) { }
            Button("保存") {
                viewModel.updateVoiceMemoTitle(voiceMemo, newTitle: editingTitle)
            }
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(voiceMemo.title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            Button {
                editingTitle = voiceMemo.title
                isEditingTitle = true
            } label: {
                Text("タイトルを編集")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Metadata Section
    private var metadataSection: some View {
        VStack(spacing: 8) {
            HStack {
                Label("録音日時", systemImage: "calendar")
                Spacer()
                Text(voiceMemo.createdAt.formatted(date: .abbreviated, time: .shortened))
            }
            
            HStack {
                Label("ファイルサイズ", systemImage: "doc")
                Spacer()
                Text(fileSizeString)
            }
            
            HStack {
                Label("継続時間", systemImage: "clock")
                Spacer()
                Text(voiceMemo.formattedDuration)
            }
        }
        .font(.body)
        .foregroundColor(.secondary)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 16) {
            // 進捗バー
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { viewModel.audioPlayerManager.progress },
                        set: { newValue in
                            let newTime = newValue * viewModel.audioPlayerManager.duration
                            viewModel.audioPlayerManager.seek(to: newTime)
                        }
                    ),
                    in: 0...1
                )
                .accentColor(Color("AsaCoffeeBrown"))
                
                // 時間表示
                HStack {
                    Text(viewModel.audioPlayerManager.formattedCurrentTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(viewModel.audioPlayerManager.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Playback Controls
    private var playbackControls: some View {
        HStack(spacing: 40) {
            // 15秒戻る
            Button {
                viewModel.audioPlayerManager.seekBackward()
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.title)
                    .foregroundColor(Color("AsaCoffeeBrown"))
            }
            
            // 再生/一時停止
            Button {
                viewModel.audioPlayerManager.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color("AsaCoffeeBrown"))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .offset(x: isPlaying ? 0 : 2)
                }
            }
            
            // 15秒進む
            Button {
                viewModel.audioPlayerManager.seekForward()
            } label: {
                Image(systemName: "goforward.15")
                    .font(.title)
                    .foregroundColor(Color("AsaCoffeeBrown"))
            }
        }
    }
    
    // MARK: - Volume Control
    private var volumeControl: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundColor(.secondary)
                
                Slider(
                    value: Binding(
                        get: { viewModel.audioPlayerManager.volume },
                        set: { viewModel.audioPlayerManager.volume = $0 }
                    ),
                    in: 0...1
                )
                .accentColor(Color("AsaCoffeeBrown"))
                
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(.secondary)
            }
            
            Text("音量: \(Int(viewModel.audioPlayerManager.volume * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Computed Properties
    private var isPlaying: Bool {
        return viewModel.audioPlayerManager.isPlaying && 
               viewModel.audioPlayerManager.currentVoiceMemo?.id == voiceMemo.id
    }
    
    private var fileSizeString: String {
        guard let fileSize = try? voiceMemo.fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            return "不明"
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }
}

#Preview {
    let voiceMemo = VoiceMemo(
        title: "サンプル録音",
        fileURL: URL(fileURLWithPath: "/tmp/sample.m4a"),
        duration: 125.5
    )
    
    return VoiceMemoPlayerView(
        voiceMemo: voiceMemo,
        viewModel: VoiceMemoViewModel()
    )
}