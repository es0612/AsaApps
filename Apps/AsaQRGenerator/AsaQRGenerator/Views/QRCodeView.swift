//
//  QRCodeView.swift
//  AsaQRGenerator
//
//  Created on 2025/09/13
//

import SwiftUI

struct QRCodeView: View {
    // MARK: - Properties
    @Bindable var viewModel: QRGeneratorViewModel
    @State private var isAnimating = false
    
    // MARK: - Body
    var body: some View {
        AsaCard {
            VStack(spacing: 16) {
                // タイトル
                HStack {
                    Image(systemName: "qrcode")
                        .foregroundColor(Color("AsaCoffeeBrown"))
                    Text("生成されたQRコード")
                        .font(.headline)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                
                // QRコード画像
                if let qrImage = viewModel.generatedQRCodeImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: viewModel.qrCodeData.size, height: viewModel.qrCodeData.size)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .scaleEffect(isAnimating ? 1.0 : 0.9)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isAnimating = true
                            }
                        }
                        .onDisappear {
                            isAnimating = false
                        }
                }
                
                // QRコード情報
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(
                        label: "タイプ",
                        value: viewModel.qrCodeData.qrCodeType.rawValue
                    )
                    
                    InfoRow(
                        label: "エラー訂正",
                        value: viewModel.qrCodeData.errorCorrectionLevel.rawValue
                    )
                    
                    InfoRow(
                        label: "サイズ",
                        value: "\(Int(viewModel.qrCodeData.size)) × \(Int(viewModel.qrCodeData.size)) px"
                    )
                    
                    // データプレビュー（長い場合は省略）
                    if !viewModel.qrCodeData.qrCodeString.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("データ:")
                                .font(.caption)
                                .foregroundColor(Color("AsaMutedSage"))
                            
                            Text(viewModel.qrCodeData.qrCodeString)
                                .font(.caption2)
                                .foregroundColor(Color.gray)
                                .lineLimit(3)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(5)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(Color("AsaMutedSage"))
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Spacer()
        }
    }
}

#Preview {
    QRCodeView(viewModel: {
        let vm = QRGeneratorViewModel()
        vm.qrCodeData.inputText = "https://example.com"
        vm.generateQRCode()
        return vm
    }())
    .padding()
    .background(Color("AsaDarkSlate"))
}