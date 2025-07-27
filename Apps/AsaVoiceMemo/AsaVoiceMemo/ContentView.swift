//
//  ContentView.swift
//  AsaVoiceMemo
//  
//  Created on 2025/07/28
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VoiceMemo.createdAt, order: .reverse) private var voiceMemos: [VoiceMemo]
    @State private var viewModel = VoiceMemoViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                if voiceMemos.isEmpty {
                    emptyStateView
                } else {
                    voiceMemoList
                }
            }
            .navigationTitle("ボイスメモ")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    recordButton
                }
            }
            .sheet(isPresented: $viewModel.isShowingRecordingView) {
                RecordingView(viewModel: viewModel)
            }
            .alert("音声録音", isPresented: $viewModel.isShowingMicrophonePermissionAlert) {
                Button("OK") { }
            } message: {
                Text(viewModel.alertMessage)
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "mic.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("まだ録音がありません")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("右上の録音ボタンを押して\n最初の音声メモを作成しましょう")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            recordButtonLarge
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Voice Memo List
    private var voiceMemoList: some View {
        VStack {
            // 統計情報
            statisticsHeader
            
            // リスト
            List {
                ForEach(voiceMemos) { voiceMemo in
                    VoiceMemoRowView(
                        voiceMemo: voiceMemo,
                        viewModel: viewModel
                    )
                }
                .onDelete(perform: deleteVoiceMemos)
            }
            .listStyle(PlainListStyle())
        }
    }
    
    // MARK: - Statistics Header
    private var statisticsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.getRecordingCount(for: voiceMemos))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("総録音時間: \(viewModel.getTotalRecordingTime(for: voiceMemos))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Record Buttons
    private var recordButton: some View {
        Button {
            Task {
                await viewModel.prepareToRecord()
            }
        } label: {
            Image(systemName: "mic.fill")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color("AsaCoffeeBrown"))
                .clipShape(Circle())
        }
    }
    
    private var recordButtonLarge: some View {
        Button {
            Task {
                await viewModel.prepareToRecord()
            }
        } label: {
            HStack {
                Image(systemName: "mic.fill")
                    .font(.title2)
                Text("録音開始")
                    .font(.title2)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: 200)
            .background(Color("AsaCoffeeBrown"))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
    
    // MARK: - Delete Function
    private func deleteVoiceMemos(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                viewModel.deleteVoiceMemo(voiceMemos[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: VoiceMemo.self, inMemory: true)
}
