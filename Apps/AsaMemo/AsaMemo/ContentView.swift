//
//  ContentView.swift
//  AsaMemo
//  
//  Created on 2025/05/26
//


import SwiftUI

struct ContentView: View {
    @StateObject private var memoManager = MemoManager()
    @State private var newMemoContent: String = ""
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                Color(colorScheme == .dark ? "AsaDarkSlate" : "AsaSoftCream")
                    .opacity(colorScheme == .dark ? 0.9 : 0.1)
                    .ignoresSafeArea()
                Color(colorScheme == .dark ? "AsaSoftCream" : "AsaDarkSlate")
                    .opacity(colorScheme == .dark ? 0.2 : 0.8)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("AsaMemo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))

                    // メモ入力欄と保存ボタン
                    HStack {
                        TextField("メモを入力", text: $newMemoContent)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                            .accentColor(Color("AsaCoffeeBrown"))
                            .background(Color("AsaSoftCream").opacity(colorScheme == .dark ? 0.4 : 0.2))
                            .cornerRadius(8)

                        Button(action: saveMemo) {
                            Image(systemName: "square.and.arrow.down.fill")
                                .foregroundColor(Color("AsaMocha"))
                                .font(.title2)
                        }
                        .disabled(newMemoContent.isEmpty)
                    }
                    .padding(.horizontal)

                    // メモ一覧
                    List {
                        ForEach(memoManager.memos) { memo in
                            VStack(alignment: .leading) {
                                Text(memo.content)
                                    .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))
                                Text(memo.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream").opacity(0.7) : Color("AsaCoffeeBrown").opacity(0.7))
                            }
                        }
                        .onDelete(perform: deleteMemos)
                    }
                    .background(
                        Color(colorScheme == .dark ? "AsaDarkSlate" : "AsaSoftCream")
                            .opacity(colorScheme == .dark ? 0.9 : 0.1)
                    )

                    Spacer()
                }
                .padding(.top)
                .navigationTitle("メモ")
                .toolbar {
                    EditButton()
                        .foregroundColor(Color("AsaMocha"))
                }
            }
        }
    }

    // メモ保存
    private func saveMemo() {
        guard !newMemoContent.isEmpty else { return }
        memoManager.addMemo(content: newMemoContent)
        newMemoContent = ""
    }

    // メモ削除
    private func deleteMemos(at offsets: IndexSet) {
        memoManager.memos.remove(atOffsets: offsets)
    }
}

#Preview {
    ContentView()
}
