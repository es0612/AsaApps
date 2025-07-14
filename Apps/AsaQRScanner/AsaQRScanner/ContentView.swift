//
//  ContentView.swift
//  AsaQRScanner
//  
//  Created on 2025/07/15
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \QRScanResult.timestamp, order: .reverse) private var scanResults: [QRScanResult]
    @StateObject private var viewModel = QRScannerViewModel()
    @State private var showingScanner = false
    @State private var selectedResult: QRScanResult?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if scanResults.isEmpty {
                    EmptyStateView {
                        showingScanner = true
                    }
                } else {
                    List {
                        ForEach(scanResults) { result in
                            ScanResultRowView(result: result) {
                                selectedResult = result
                            }
                        }
                        .onDelete(perform: deleteResults)
                    }
                }
            }
            .navigationTitle("QRスキャナー")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingScanner = true
                    }) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.title2)
                    }
                }
                
                if !scanResults.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingScanner) {
                QRScannerView(viewModel: viewModel)
                    .onAppear {
                        viewModel.setModelContext(modelContext)
                    }
            }
            .sheet(item: $selectedResult) { result in
                ScanResultDetailView(scanResult: result)
            }
        }
    }
    
    private func deleteResults(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(scanResults[index])
            }
        }
    }
}

struct EmptyStateView: View {
    let onScanTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "qrcode")
                .font(.system(size: 80))
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            VStack(spacing: 12) {
                Text("QRコードをスキャンしてみましょう")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("スキャンした履歴はここに表示されます")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            AsaButton(
                title: "QRコードをスキャン",
                action: onScanTapped,
                color: Color("AsaCoffeeBrown")
            )
            .frame(maxWidth: 250)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ScanResultRowView: View {
    let result: QRScanResult
    let onTapped: () -> Void
    
    var body: some View {
        Button(action: onTapped) {
            AsaCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: iconName)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                            .frame(width: 20)
                        
                        Text(contentPreview)
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(result.timestamp, style: .date)
                        Text("•")
                        Text(result.timestamp, style: .time)
                        Spacer()
                        Text(result.scanType)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color("AsaMutedSage").opacity(0.3))
                            .cornerRadius(4)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var contentPreview: String {
        if result.content.count > 30 {
            return String(result.content.prefix(30)) + "..."
        }
        return result.content
    }
    
    private var iconName: String {
        if result.content.hasPrefix("http") {
            return "link"
        } else if result.content.contains("@") {
            return "envelope"
        } else if result.content.hasPrefix("tel:") {
            return "phone"
        } else {
            return "text.alignleft"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: QRScanResult.self, inMemory: true)
}
