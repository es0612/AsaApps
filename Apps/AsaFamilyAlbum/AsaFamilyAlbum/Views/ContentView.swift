//
//  ContentView.swift
//  AsaFamilyAlbum
//
//  Created on 2025/09/05
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: FamilyAlbumViewModel?
    @State private var selectedTab = 0
    
    var body: some View {
        if let viewModel = viewModel {
            TabView(selection: $selectedTab) {
                AlbumsView(viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("アルバム")
                    }
                    .tag(0)

                PhotosGridView(viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "photo.stack")
                        Text("すべての写真")
                    }
                    .tag(1)

                FamilyMembersView(viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "person.3.sequence")
                        Text("家族")
                    }
                    .tag(2)

                SearchView(viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("検索")
                    }
                    .tag(3)
            }
            .tint(Color("AsaCoffeeBrown"))
            .task {
                await viewModel.loadInitialData()
            }
            .sheet(isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.clearError() }
            )) {
                ErrorView(errorMessage: viewModel.errorMessage ?? "")
            }
        } else {
            ProgressView("読み込み中...")
                .onAppear {
                    // ViewModelを初期化してModelContextを設定
                    let vm = FamilyAlbumViewModel()
                    vm.dataService.setModelContext(modelContext)
                    self.viewModel = vm
                    vm.requestPhotoLibraryAccess()
                }
        }
    }
}

struct ErrorView: View {
    let errorMessage: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(Color("AsaMocha"))
            
            Text("エラーが発生しました")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("AsaDarkSlate"))
            
            Text(errorMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(Color("AsaDarkSlate"))
                .padding(.horizontal)
            
            Button("閉じる") {
                // シートが自動的に閉じられます
            }
            .buttonStyle(AsaButtonStyle())
        }
        .padding(32)
        .background(Color("AsaSoftCream"))
        .cornerRadius(16)
        .shadow(color: Color("AsaDarkSlate").opacity(0.1), radius: 8)
    }
}

struct AsaButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.headline)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color("AsaCoffeeBrown"))
            .cornerRadius(8)
            .shadow(color: Color("AsaDarkSlate").opacity(0.2), radius: 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Album.self, Photo.self, Comment.self, FamilyMember.self])
}