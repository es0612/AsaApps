import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var viewModel = FilterViewModel()
    @State private var showingPhotoPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    colors: [Color("AsaSoftCream"), Color("AsaMutedSage")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // ヘッダー
                        headerSection
                        
                        // 画像表示エリア
                        imageDisplaySection
                        
                        // フィルター選択
                        filterSelectionSection
                        
                        // 強度調整（セピア用）
                        if viewModel.selectedFilter.supportsIntensity {
                            intensitySection
                        }
                        
                        // ボタンエリア
                        buttonsSection
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $viewModel.selectedPhotoItem
        )
        .onChange(of: viewModel.selectedPhotoItem) { _, _ in
            Task {
                await viewModel.loadImageFromPhotoItem()
            }
        }
        .alert("保存結果", isPresented: $viewModel.showingSaveAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.saveMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image("AsaPapaLabLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .shadow(radius: 2)
            
            Text("アサパパの写真フィルター")
                .font(.title2.weight(.medium))
                .foregroundColor(Color("AsaCoffeeBrown"))
        }
        .padding(.top, 16)
    }
    
    private var imageDisplaySection: some View {
        AsaCard {
            VStack {
                if viewModel.isProcessing {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color("AsaSoftCream").opacity(0.3))
                            .frame(width: 280, height: 280)
                        
                        ProgressView("処理中...")
                            .progressViewStyle(CircularProgressViewStyle(tint: Color("AsaCoffeeBrown")))
                            .scaleEffect(1.2)
                    }
                } else if let displayImage = viewModel.filteredImage ?? viewModel.originalImage {
                    Image(uiImage: displayImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 280, maxHeight: 280)
                        .cornerRadius(15)
                        .shadow(radius: 3)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color("AsaSoftCream").opacity(0.3))
                            .frame(width: 280, height: 280)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(Color("AsaMutedSage"))
                            
                            Text("写真を選択してください")
                                .font(.body.weight(.medium))
                                .foregroundColor(Color("AsaMutedSage"))
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var filterSelectionSection: some View {
        AsaCard {
            VStack(spacing: 16) {
                Text("フィルター選択")
                    .font(.headline.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Picker("フィルター", selection: $viewModel.selectedFilter) {
                    ForEach(FilterType.allCases, id: \.self) { filter in
                        Text(filter.displayName)
                            .tag(filter)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: viewModel.selectedFilter) { _, newValue in
                    viewModel.updateFilter(newValue)
                }
                
                if viewModel.selectedFilter != .none {
                    Text(viewModel.selectedFilter.description)
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
    }
    
    private var intensitySection: some View {
        AsaCard {
            VStack(spacing: 12) {
                Text("フィルター強度")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Slider(
                    value: $viewModel.filterIntensity,
                    in: 0...1,
                    step: 0.1
                ) {
                    Text("強度")
                } minimumValueLabel: {
                    Text("弱")
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                } maximumValueLabel: {
                    Text("強")
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                }
                .tint(Color("AsaCoffeeBrown"))
                .onChange(of: viewModel.filterIntensity) { _, newValue in
                    viewModel.updateIntensity(newValue)
                }
                
                Text("\(Int(viewModel.filterIntensity * 100))%")
                    .font(.caption.weight(.medium))
                    .foregroundColor(Color("AsaCoffeeBrown"))
            }
            .padding()
        }
    }
    
    private var buttonsSection: some View {
        VStack(spacing: 12) {
            AsaButton(title: "写真を選択") {
                showingPhotoPicker = true
            }
            .disabled(viewModel.isProcessing)
            
            HStack(spacing: 16) {
                AsaButton(title: "保存", action: {
                    viewModel.saveToPhotoLibrary()
                }, color: Color("AsaMutedSage"))
                .disabled(viewModel.originalImage == nil || viewModel.isProcessing)
                
                AsaButton(title: "リセット", action: {
                    viewModel.resetToOriginal()
                }, color: Color("AsaMocha"))
                .disabled(viewModel.originalImage == nil || viewModel.isProcessing)
            }
        }
    }
}

#Preview {
    ContentView()
}