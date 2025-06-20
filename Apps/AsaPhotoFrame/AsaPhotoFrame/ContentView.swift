import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var viewModel = PhotoFrameViewModel()
    @State private var showPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [.asaSoftCream, .asaMocha], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Image("AsaPapaLabLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .padding(.top, 8)
                        .shadow(radius: 1)
                    
                    Text("アサパパの写真フレーム")
                        .font(.title2.weight(.medium))
                        .foregroundColor(.asaCoffeeBrown)
                    
                    AsaCard {
                        if let image = viewModel.photoImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color("#C68C53"), lineWidth: viewModel.currentFrame.frameWidth)
                                )
                                .padding()
                        } else {
                            Rectangle()
                                .fill(.asaSoftCream)
                                .frame(width: 300, height: 300)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.asaCoffeeBrown, lineWidth: 5)
                                )
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                    
                    AsaButton(title: "写真を選択") {
                        showPicker = true
                    }
                    .padding(.horizontal)
                    .photosPicker(isPresented: $showPicker, selection: $viewModel.selectedPhoto)
                    .onChange(of: viewModel.selectedPhoto) { _, _ in
                        Task {
                            await viewModel.loadImage(from: viewModel.selectedPhoto)
                        }
                    }
                    
                    NavigationLink("保存履歴", destination: Text("未実装"))
                        .font(.body.weight(.medium))
                        .foregroundColor(.asaMutedSage)
                        .padding(.bottom, 16)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .onAppear {
                viewModel.loadFromUserDefaults()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
