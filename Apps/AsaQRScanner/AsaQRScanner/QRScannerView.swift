//
//  QRScannerView.swift
//  AsaQRScanner
//  
//  Created on 2025/07/15
//

import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @ObservedObject var viewModel: QRScannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // カメラビュー
            if viewModel.cameraPermissionStatus == .authorized {
                QRCameraRepresentable(
                    isScanning: $viewModel.isScanning,
                    onCodeScanned: { code in
                        viewModel.handleScannedCode(code)
                        viewModel.stopScanning()
                    }
                )
                .ignoresSafeArea()
                
                // スキャン範囲のオーバーレイ
                ScanOverlayView()
                
                // UI コントロール
                VStack {
                    // 上部: 閉じるボタン
                    HStack {
                        Button(action: {
                            viewModel.stopScanning()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .background(Circle().fill(.black.opacity(0.5)))
                        }
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    // 下部: 説明とボタン
                    VStack(spacing: 16) {
                        Text("QRコードをカメラに向けてください")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(.black.opacity(0.7)))
                        
                        HStack(spacing: 20) {
                            AsaButton(
                                title: viewModel.isScanning ? "スキャン停止" : "スキャン開始",
                                action: {
                                    if viewModel.isScanning {
                                        viewModel.stopScanning()
                                    } else {
                                        viewModel.startScanning()
                                    }
                                },
                                color: viewModel.isScanning ? Color("AsaMutedSage") : Color("AsaCoffeeBrown")
                            )
                            .frame(maxWidth: 200)
                        }
                    }
                    .padding()
                }
            } else {
                // カメラ権限なしの状態
                PermissionRequestView(viewModel: viewModel)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.checkCameraPermission()
            if viewModel.cameraPermissionStatus == .authorized {
                viewModel.startScanning()
            }
        }
        .onDisappear {
            viewModel.stopScanning()
        }
        .alert("QRスキャナー", isPresented: $viewModel.showingAlert) {
            Button("OK", role: .cancel) {
                if !viewModel.hasError {
                    dismiss()
                }
            }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

struct ScanOverlayView: View {
    var body: some View {
        ZStack {
            // 暗いオーバーレイ
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // スキャン領域の枠
            Rectangle()
                .stroke(Color("AsaCoffeeBrown"), lineWidth: 3)
                .frame(width: 250, height: 250)
                .background(Color.clear)
            
            // 角の装飾
            VStack {
                HStack {
                    ScanCornerView()
                    Spacer()
                    ScanCornerView()
                        .rotationEffect(.degrees(90))
                }
                Spacer()
                HStack {
                    ScanCornerView()
                        .rotationEffect(.degrees(-90))
                    Spacer()
                    ScanCornerView()
                        .rotationEffect(.degrees(180))
                }
            }
            .frame(width: 250, height: 250)
        }
    }
}

struct ScanCornerView: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color("AsaCoffeeBrown"))
                .frame(width: 20, height: 4)
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color("AsaCoffeeBrown"))
                    .frame(width: 4, height: 20)
                Spacer()
            }
        }
        .frame(width: 20, height: 20)
    }
}

struct PermissionRequestView: View {
    @ObservedObject var viewModel: QRScannerViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Text("カメラへのアクセスが必要です")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("QRコードをスキャンするために\nカメラの使用を許可してください")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            AsaButton(
                title: "カメラを許可",
                action: {
                    Task {
                        await viewModel.requestCameraPermission()
                    }
                },
                color: Color("AsaCoffeeBrown")
            )
            .frame(maxWidth: 200)
        }
        .padding()
    }
}

#Preview {
    QRScannerView(viewModel: QRScannerViewModel())
}