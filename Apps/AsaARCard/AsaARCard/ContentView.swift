import SwiftUI
import RealityKit
import ARKit
import AsaUIKit

// MARK: - ContentView
struct ContentView: View {
    @EnvironmentObject private var viewModel: ARCardViewModel
    
    var body: some View {
        ZStack {
            // ARView
            ARViewContainer(viewModel: viewModel)
                .ignoresSafeArea()
            
            // UI Overlay
            VStack {
                // 上部：エラーメッセージ
                if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                        .padding()
                }
                
                Spacer()
                
                // 下部：コントロールパネル
                controlPanel
                    .padding()
            }
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            SettingsView()
                .environmentObject(viewModel)
        }
    }
    
    // MARK: - Views
    
    private func errorView(message: String) -> some View {
        AsaCard {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(message)
                    .font(.caption)
                    .foregroundColor(AsaColors.darkSlate)
                
                Spacer()
                
                Button("閉じる") {
                    viewModel.clearError()
                }
                .font(.caption)
                .foregroundColor(AsaColors.coffeeBrown)
            }
        }
    }
    
    private var controlPanel: some View {
        AsaCard {
            HStack(spacing: 20) {
                // 名刺表示/非表示ボタン
                Button(action: toggleCardVisibility) {
                    Image(systemName: viewModel.isCardVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(AsaColors.coffeeBrown, in: Circle())
                        .shadow(radius: 2)
                }
                
                // 名刺回転ボタン
                Button(action: viewModel.flipCard) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(viewModel.isCardVisible ? AsaColors.mutedSage : Color.gray.opacity(0.5), in: Circle())
                        .shadow(radius: viewModel.isCardVisible ? 2 : 0)
                }
                .disabled(!viewModel.isCardVisible)
                
                // 設定ボタン
                Button(action: viewModel.showSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(AsaColors.mocha, in: Circle())
                        .shadow(radius: 2)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Actions
    
    private func toggleCardVisibility() {
        if viewModel.isCardVisible {
            viewModel.hideBusinessCard()
        } else {
            viewModel.showBusinessCard()
        }
    }
}

// MARK: - ARViewContainer
struct ARViewContainer: UIViewRepresentable {
    let viewModel: ARCardViewModel
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // ViewModelにARViewを設定
        viewModel.arView = arView
        
        // ARSessionの設定
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        arView.session.run(configuration)
        
        // セッションデリゲートを設定
        arView.session.delegate = context.coordinator
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // UIの更新が必要な場合はここで処理
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        let viewModel: ARCardViewModel
        
        init(viewModel: ARCardViewModel) {
            self.viewModel = viewModel
        }
        
        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            DispatchQueue.main.async {
                self.viewModel.updateARSessionState(camera.trackingState)
            }
        }
    }
}

// MARK: - SettingsView
struct SettingsView: View {
    @EnvironmentObject private var viewModel: ARCardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editingCard: BusinessCard
    
    init() {
        // 現在の名刺データで初期化（一時的な状態）
        _editingCard = State(initialValue: BusinessCard())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                AsaColors.softCream.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ScrollView {
                        VStack(spacing: 16) {
                            // 個人情報セクション
                            AsaCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("個人情報")
                                        .font(.headline)
                                        .foregroundColor(AsaColors.darkSlate)
                                    
                                    VStack(spacing: 8) {
                                        TextField("氏名", text: $editingCard.name)
                                            .textFieldStyle(.roundedBorder)
                                        TextField("役職", text: $editingCard.title)
                                            .textFieldStyle(.roundedBorder)
                                        TextField("会社名", text: $editingCard.company)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                            
                            // 連絡先セクション
                            AsaCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("連絡先")
                                        .font(.headline)
                                        .foregroundColor(AsaColors.darkSlate)
                                    
                                    VStack(spacing: 8) {
                                        TextField("メールアドレス", text: $editingCard.email)
                                            .keyboardType(.emailAddress)
                                            .textFieldStyle(.roundedBorder)
                                        TextField("電話番号", text: $editingCard.phone)
                                            .keyboardType(.phonePad)
                                            .textFieldStyle(.roundedBorder)
                                        TextField("ウェブサイト", text: $editingCard.website)
                                            .keyboardType(.URL)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // ボタン群
                    HStack(spacing: 16) {
                        AsaButton(
                            title: "キャンセル",
                            action: { dismiss() },
                            color: AsaColors.mutedSage
                        )
                        
                        AsaButton(
                            title: "保存",
                            action: {
                                viewModel.updateBusinessCard(editingCard)
                                dismiss()
                            },
                            color: AsaColors.coffeeBrown
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("名刺設定")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            editingCard = viewModel.businessCard
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(ARCardViewModel())
}