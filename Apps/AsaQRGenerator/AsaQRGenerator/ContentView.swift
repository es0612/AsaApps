//
//  ContentView.swift
//  AsaQRGenerator
//
//  Created on 2025/09/13
//

import SwiftUI

struct ContentView: View {
    // MARK: - Properties
    @State private var viewModel = QRGeneratorViewModel()
    @State private var showShareSheet = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 入力セクション
                    InputView(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    // QRコードプレビュー
                    if viewModel.generatedQRCodeImage != nil {
                        QRCodeView(viewModel: viewModel)
                            .padding(.horizontal)
                    }
                    
                    // アクションボタン
                    actionButtons
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color("AsaDarkSlate"))
            .navigationTitle("QRコード生成")
            .navigationBarTitleDisplayMode(.large)
            .alert("保存完了", isPresented: $viewModel.showSaveAlert) {
                Button("OK") { }
            } message: {
                Text(viewModel.saveAlertMessage)
            }
            .sheet(isPresented: $showShareSheet) {
                if let shareView = viewModel.shareQRCode() {
                    shareView
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 生成ボタン
            AsaButton(
                title: viewModel.isGenerating ? "生成中..." : "QRコード生成",
                action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.generateQRCode()
                    }
                },
                color: Color("AsaCoffeeBrown"),
                isEnabled: !viewModel.qrCodeData.inputText.isEmpty && !viewModel.isGenerating
            )
            
            // QRコードが生成されている場合のみ表示
            if viewModel.generatedQRCodeImage != nil {
                HStack(spacing: 12) {
                    // 保存ボタン
                    AsaButton(
                        title: "保存",
                        action: {
                            viewModel.saveQRCodeToPhotos()
                        },
                        color: Color("AsaMocha")
                    )
                    
                    // 共有ボタン
                    AsaButton(
                        title: "共有",
                        action: {
                            showShareSheet = true
                        },
                        color: Color("AsaSoftCream")
                    )
                }
                
                // クリアボタン
                AsaButton(
                    title: "クリア",
                    action: {
                        withAnimation {
                            viewModel.clearInput()
                        }
                    },
                    color: Color("AsaMutedSage")
                )
            }
        }
    }
}

// MARK: - AsaButton Component
struct AsaButton: View {
    let title: String
    let action: () -> Void
    let color: Color
    let isEnabled: Bool
    
    init(title: String, action: @escaping () -> Void, color: Color = Color("AsaCoffeeBrown"), isEnabled: Bool = true) {
        self.title = title
        self.action = action
        self.color = color
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title3)
                .fontWeight(.medium)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isEnabled ? color : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(radius: 2)
                .scaleEffect(isEnabled ? 1.0 : 0.95)
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - AsaCard Component
struct AsaCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ContentView()
}