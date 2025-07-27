//
//  RecordingView.swift
//  AsaVoiceMemo
//  
//  Created on 2025/07/28
//

import SwiftUI

struct RecordingView: View {
    @Bindable var viewModel: VoiceMemoViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                // 録音状態表示
                recordingStateView
                
                // 録音時間表示
                timeDisplayView
                
                // 波形表示（アニメーション）
                if viewModel.audioRecorderManager.isRecording {
                    waveformView
                }
                
                Spacer()
                
                // 録音コントロール
                recordingControls
                
                Spacer()
            }
            .padding()
            .navigationTitle("音声録音")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        viewModel.cancelRecording()
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Recording State View
    private var recordingStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                // アニメーション付きの円
                if viewModel.audioRecorderManager.isRecording {
                    Circle()
                        .fill(Color("AsaCoffeeBrown").opacity(0.3))
                        .frame(width: 150, height: 150)
                        .scaleEffect(viewModel.audioRecorderManager.isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.audioRecorderManager.isRecording)
                }
                
                Circle()
                    .fill(viewModel.audioRecorderManager.isRecording ? Color.red : Color("AsaCoffeeBrown"))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            Text(viewModel.audioRecorderManager.isRecording ? "録音中..." : "録音準備完了")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Time Display View
    private var timeDisplayView: some View {
        VStack(spacing: 8) {
            Text(viewModel.audioRecorderManager.formattedRecordingTime)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundColor(.primary)
            
            if !viewModel.audioRecorderManager.isRecording {
                Text("録音ボタンを押して開始")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Waveform View
    private var waveformView: some View {
        HStack(spacing: 4) {
            ForEach(0..<10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color("AsaCoffeeBrown"))
                    .frame(width: 6, height: CGFloat.random(in: 10...50))
                    .animation(.easeInOut(duration: 0.5).repeatForever(), value: viewModel.audioRecorderManager.isRecording)
            }
        }
        .padding()
    }
    
    // MARK: - Recording Controls
    private var recordingControls: some View {
        HStack(spacing: 40) {
            if viewModel.audioRecorderManager.isRecording {
                // 録音中：停止ボタンとキャンセルボタン
                Button {
                    viewModel.stopRecordingAndSave()
                    dismiss()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 35))
                        
                        Text("停止して保存")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                
                Button {
                    viewModel.cancelRecording()
                    dismiss()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 35))
                        
                        Text("キャンセル")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            } else {
                // 録音前：録音開始ボタン
                Button {
                    viewModel.startRecording()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "record.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(Color("AsaCoffeeBrown"))
                            .clipShape(Circle())
                        
                        Text("録音開始")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    RecordingView(viewModel: VoiceMemoViewModel())
}