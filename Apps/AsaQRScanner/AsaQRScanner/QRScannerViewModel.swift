//
//  QRScannerViewModel.swift
//  AsaQRScanner
//  
//  Created on 2025/07/15
//

import Foundation
import SwiftData
import AVFoundation

@MainActor
class QRScannerViewModel: ObservableObject {
    @Published var isScanning = false
    @Published var lastScannedCode: String = ""
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var hasError = false
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    
    private var modelContext: ModelContext?
    
    init() {
        checkCameraPermission()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requestCameraPermission() async {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            self.cameraPermissionStatus = status ? .authorized : .denied
        }
    }
    
    func handleScannedCode(_ code: String) {
        guard !code.isEmpty else { return }
        
        lastScannedCode = code
        saveScannedCode(code)
        showScannedCodeAlert(code)
    }
    
    private func saveScannedCode(_ code: String) {
        guard let context = modelContext else { return }
        
        let result = QRScanResult(content: code)
        context.insert(result)
        
        do {
            try context.save()
        } catch {
            print("スキャン結果の保存に失敗: \(error)")
            hasError = true
            alertMessage = "スキャン結果の保存に失敗しました"
            showingAlert = true
        }
    }
    
    private func showScannedCodeAlert(_ code: String) {
        alertMessage = "QRコードを読み取りました"
        showingAlert = true
    }
    
    func startScanning() {
        guard cameraPermissionStatus == .authorized else {
            alertMessage = "カメラの使用許可が必要です"
            showingAlert = true
            return
        }
        isScanning = true
    }
    
    func stopScanning() {
        isScanning = false
    }
}