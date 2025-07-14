//
//  QRCameraRepresentable.swift
//  AsaQRScanner
//  
//  Created on 2025/07/15
//

import SwiftUI
import AVFoundation

struct QRCameraRepresentable: UIViewRepresentable {
    @Binding var isScanning: Bool
    let onCodeScanned: (String) -> Void
    
    func makeUIView(context: Context) -> QRCameraView {
        let cameraView = QRCameraView()
        cameraView.delegate = context.coordinator
        return cameraView
    }
    
    func updateUIView(_ uiView: QRCameraView, context: Context) {
        if isScanning {
            uiView.startScanning()
        } else {
            uiView.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }
    
    class Coordinator: NSObject, QRCameraViewDelegate {
        let onCodeScanned: (String) -> Void
        
        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }
        
        func didScanCode(_ code: String) {
            onCodeScanned(code)
        }
    }
}

protocol QRCameraViewDelegate: AnyObject {
    func didScanCode(_ code: String)
}

class QRCameraView: UIView, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: QRCameraViewDelegate?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }
    
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("カメラの設定に失敗しました")
            return
        }
        
        captureSession = AVCaptureSession()
        captureSession?.addInput(input)
        
        let metadataOutput = AVCaptureMetadataOutput()
        captureSession?.addOutput(metadataOutput)
        
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer!)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    func startScanning() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    func stopScanning() {
        captureSession?.stopRunning()
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }
        
        delegate?.didScanCode(stringValue)
    }
}