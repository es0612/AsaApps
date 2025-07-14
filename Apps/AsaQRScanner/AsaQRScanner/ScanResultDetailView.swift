//
//  ScanResultDetailView.swift
//  AsaQRScanner
//  
//  Created on 2025/07/15
//

import SwiftUI

struct ScanResultDetailView: View {
    let scanResult: QRScanResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // QRコードアイコン
                    AsaCard {
                        VStack(spacing: 16) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 64))
                                .foregroundColor(Color("AsaCoffeeBrown"))
                            
                            Text("QRコード読み取り結果")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .padding()
                    }
                    
                    // スキャン結果内容
                    AsaCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                Text("内容")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            Text(scanResult.content)
                                .font(.body)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .textSelection(.enabled)
                        }
                    }
                    
                    // 詳細情報
                    AsaCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(Color("AsaCoffeeBrown"))
                                Text("詳細情報")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("スキャン日時:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(scanResult.timestamp, style: .date)
                                    Text(scanResult.timestamp, style: .time)
                                }
                                
                                HStack {
                                    Text("タイプ:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(scanResult.scanType)
                                }
                            }
                            .font(.body)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // アクションボタン
                    VStack(spacing: 12) {
                        if isValidURL(scanResult.content) {
                            AsaButton(
                                title: "ウェブサイトを開く",
                                action: {
                                    if let url = URL(string: scanResult.content) {
                                        UIApplication.shared.open(url)
                                    }
                                },
                                color: Color("AsaCoffeeBrown")
                            )
                        }
                        
                        AsaButton(
                            title: "内容をコピー",
                            action: {
                                UIPasteboard.general.string = scanResult.content
                            },
                            color: Color("AsaMutedSage")
                        )
                        
                        if canShare(scanResult.content) {
                            AsaButton(
                                title: "共有",
                                action: {
                                    shareContent(scanResult.content)
                                },
                                color: Color("AsaMutedSage")
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("スキャン結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return url.scheme?.lowercased().hasPrefix("http") == true
    }
    
    private func canShare(_ content: String) -> Bool {
        return !content.isEmpty
    }
    
    private func shareContent(_ content: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        let activityViewController = UIActivityViewController(
            activityItems: [content],
            applicationActivities: nil
        )
        
        if let topController = window.rootViewController {
            // iPadの場合のポップオーバー設定
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(
                    x: window.bounds.midX,
                    y: window.bounds.midY,
                    width: 0,
                    height: 0
                )
            }
            
            topController.present(activityViewController, animated: true)
        }
    }
}

#Preview {
    ScanResultDetailView(
        scanResult: QRScanResult(
            content: "https://www.apple.com",
            timestamp: Date(),
            scanType: "QR"
        )
    )
}