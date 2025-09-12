//
//  LayerManagerSheet.swift
//  AsaDrawingPro
//  
//  Created on 2025/09/12
//

import SwiftUI

struct LayerManagerSheet: View {
    @Bindable var viewModel: DrawingProViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // レイヤー追加ボタン
                addLayerSection
                
                Divider()
                
                // レイヤーリスト
                layerList
            }
            .navigationTitle("レイヤー管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完了") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("全てのレイヤーをクリア", role: .destructive) {
                            viewModel.clearAllLayers()
                        }
                        
                        Button("新規レイヤー") {
                            viewModel.addLayer()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    // MARK: - Add Layer Section
    
    private var addLayerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("レイヤー数: \(viewModel.layers.count)/10")
                    .font(.headline)
                    .foregroundColor(Color.asaDarkSlate)
                
                Text("現在: \(viewModel.selectedLayer?.name ?? "なし")")
                    .font(.caption)
                    .foregroundColor(Color.asaMutedSage)
            }
            
            Spacer()
            
            Button(action: {
                viewModel.addLayer()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("レイヤー追加")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.asaCoffeeBrown)
                )
            }
            .disabled(!viewModel.canAddLayer)
        }
        .padding()
    }
    
    // MARK: - Layer List
    
    private var layerList: some View {
        List {
            ForEach(viewModel.layers) { layer in
                LayerRowView(
                    layer: layer,
                    isSelected: layer.id == viewModel.selectedLayerID,
                    viewModel: viewModel
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .onMove { from, to in
                viewModel.reorderLayers(from: IndexSet(from), to: to)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Layer Row View

struct LayerRowView: View {
    let layer: DrawingLayer
    let isSelected: Bool
    let viewModel: DrawingProViewModel
    
    @State private var showingRenameAlert = false
    @State private var newName = ""
    
    var body: some View {
        HStack(spacing: 12) {
            // レイヤー選択インジケーター
            Circle()
                .fill(isSelected ? Color.asaCoffeeBrown : .clear)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.asaMutedSage.opacity(0.5), lineWidth: 1)
                )
            
            // レイヤー情報
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(layer.name)
                        .font(.headline)
                        .foregroundColor(Color.asaDarkSlate)
                    
                    if layer.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(Color.asaMocha)
                    }
                }
                
                Text("ストローク: \(layer.strokes.count)")
                    .font(.caption)
                    .foregroundColor(Color.asaMutedSage)
            }
            
            Spacer()
            
            // コントロールボタン
            HStack(spacing: 8) {
                // 表示/非表示
                Button(action: {
                    viewModel.toggleLayerVisibility(layer.id)
                }) {
                    Image(systemName: layer.isVisible ? "eye.fill" : "eye.slash.fill")
                        .font(.title3)
                        .foregroundColor(layer.isVisible ? .asaCoffeeBrown : Color.asaMutedSage)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.asaSoftCream.opacity(0.5))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // ロック/アンロック
                Button(action: {
                    viewModel.toggleLayerLock(layer.id)
                }) {
                    Image(systemName: layer.isLocked ? "lock.fill" : "lock.open.fill")
                        .font(.title3)
                        .foregroundColor(layer.isLocked ? Color.asaMocha : Color.asaMutedSage)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.asaSoftCream.opacity(0.5))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.asaCoffeeBrown.opacity(0.1) : .clear)
                .stroke(isSelected ? Color.asaCoffeeBrown.opacity(0.3) : .clear, lineWidth: 1)
        )
        .onTapGesture {
            viewModel.selectedLayerID = layer.id
        }
        .contextMenu {
            Button("名前を変更") {
                newName = layer.name
                showingRenameAlert = true
            }
            
            Button("複製") {
                // TODO: レイヤー複製機能の実装
            }
            
            Divider()
            
            Button("レイヤーをクリア", role: .destructive) {
                viewModel.clearLayer(layer.id)
            }
            
            if viewModel.layers.count > 1 {
                Button("レイヤーを削除", role: .destructive) {
                    viewModel.deleteLayer(layer.id)
                }
            }
        }
        .alert("レイヤー名を変更", isPresented: $showingRenameAlert) {
            TextField("レイヤー名", text: $newName)
            Button("キャンセル", role: .cancel) { }
            Button("変更") {
                viewModel.renameLayer(layer.id, newName: newName)
            }
        }
    }
}

// MARK: - Opacity Slider

struct LayerOpacitySlider: View {
    @Bindable var viewModel: DrawingProViewModel
    let layerID: UUID
    
    private var opacity: Binding<Double> {
        Binding(
            get: {
                viewModel.layers.first { $0.id == layerID }?.opacity ?? 1.0
            },
            set: { newValue in
                viewModel.updateLayerOpacity(layerID, opacity: newValue)
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("透明度: \(Int(opacity.wrappedValue * 100))%")
                .font(.caption)
                .foregroundColor(Color.asaMutedSage)
            
            Slider(value: opacity, in: 0...1, step: 0.1)
                .tint(.asaCoffeeBrown)
        }
    }
}