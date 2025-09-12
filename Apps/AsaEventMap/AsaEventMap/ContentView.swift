//
//  ContentView.swift
//  AsaEventMap
//  
//  Created on 2025/09/12
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = EventMapViewModel()
    
    var body: some View {
        TabView {
            EventMapView(viewModel: viewModel)
                .tabItem {
                    Label("地図", systemImage: "map")
                }
            
            EventListView(viewModel: viewModel)
                .tabItem {
                    Label("リスト", systemImage: "list.bullet")
                }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            // サンプルデータを作成（初回のみ）
            if viewModel.events.isEmpty {
                viewModel.createSampleData()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Event.self, inMemory: true)
}