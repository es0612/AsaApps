//
//  QRGeneratorViewModel.swift
//  AsaQRGenerator
//
//  Created on 2025/09/13
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import PhotosUI

@Observable
final class QRGeneratorViewModel {
    // MARK: - Properties
    var qrCodeData = QRCodeData()
    var generatedQRCodeImage: UIImage?
    var showSaveAlert = false
    var saveAlertMessage = ""
    var isGenerating = false
    
    private let context = CIContext()
    private let qrCodeGenerator = CIFilter.qrCodeGenerator()
    
    // MARK: - Methods
    
    // QRコード生成
    func generateQRCode() {
        isGenerating = true
        
        // 入力テキストが空の場合は処理しない
        guard !qrCodeData.inputText.isEmpty else {
            generatedQRCodeImage = nil
            isGenerating = false
            return
        }
        
        // QRコードデータを設定
        qrCodeGenerator.message = Data(qrCodeData.qrCodeString.utf8)
        qrCodeGenerator.correctionLevel = qrCodeData.errorCorrectionLevel.correctionString
        
        // CIImageを取得
        guard let outputImage = qrCodeGenerator.outputImage else {
            isGenerating = false
            return
        }
        
        // スケーリング計算
        let scaleX = qrCodeData.size / outputImage.extent.size.width
        let scaleY = qrCodeData.size / outputImage.extent.size.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // UIImageに変換
        if let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) {
            generatedQRCodeImage = UIImage(cgImage: cgImage)
        }
        
        isGenerating = false
    }
    
    // QRコードを写真ライブラリに保存
    func saveQRCodeToPhotos() {
        guard let image = generatedQRCodeImage else { return }
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        saveAlertMessage = "QRコードを写真ライブラリに保存しました"
        showSaveAlert = true
    }
    
    // QRコードを共有
    func shareQRCode() -> ShareView? {
        guard let image = generatedQRCodeImage else { return nil }
        return ShareView(items: [image])
    }
    
    // 入力をクリア
    func clearInput() {
        qrCodeData = QRCodeData()
        generatedQRCodeImage = nil
    }
}

// MARK: - ShareView
struct ShareView: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}