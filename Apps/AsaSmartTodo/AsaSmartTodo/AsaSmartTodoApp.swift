//
//  AsaSmartTodoApp.swift
//  AsaSmartTodo
//
//  AIでタスク優先度を提案するスマートToDo管理アプリ
//  朝活パパエンジニアによるSwiftUI学習プロジェクト
//

import SwiftUI
import SwiftData

@main
struct AsaSmartTodoApp: App {
    // DataServiceのインスタンスを作成
    private let dataService = DataService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(dataService.modelContainer)
                .onAppear {
                    // ViewModelを初期化
                    setupViewModel()
                }
        }
    }

    private func setupViewModel() {
        // アプリ起動時の初期化処理
        print("AsaSmartTodo起動: AI優先度予測システム稼働中")
    }
}
