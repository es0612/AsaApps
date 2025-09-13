//
//  InputView.swift
//  AsaQRGenerator
//
//  Created on 2025/09/13
//

import SwiftUI

struct InputView: View {
    // MARK: - Properties
    @Bindable var viewModel: QRGeneratorViewModel
    
    // MARK: - Body
    var body: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 16) {
                // タイトル
                Text("QRコード入力")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                // QRコードタイプ選択
                VStack(alignment: .leading, spacing: 8) {
                    Text("タイプ")
                        .font(.subheadline)
                        .foregroundColor(Color("AsaMutedSage"))
                    
                    Picker("QRコードタイプ", selection: $viewModel.qrCodeData.qrCodeType) {
                        ForEach(QRCodeType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .background(Color("AsaSoftCream").opacity(0.3))
                    .cornerRadius(8)
                }
                
                // メイン入力フィールド
                VStack(alignment: .leading, spacing: 8) {
                    Text("内容")
                        .font(.subheadline)
                        .foregroundColor(Color("AsaMutedSage"))
                    
                    TextField(
                        viewModel.qrCodeData.qrCodeType.placeholder,
                        text: $viewModel.qrCodeData.inputText
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(viewModel.qrCodeData.qrCodeType == .url ? .none : .sentences)
                    .keyboardType(keyboardType)
                }
                
                // タイプ別追加フィールド
                additionalFields
                
                // エラー訂正レベル選択
                VStack(alignment: .leading, spacing: 8) {
                    Text("エラー訂正レベル")
                        .font(.subheadline)
                        .foregroundColor(Color("AsaMutedSage"))
                    
                    Picker("エラー訂正レベル", selection: $viewModel.qrCodeData.errorCorrectionLevel) {
                        ForEach(ErrorCorrectionLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .background(Color("AsaSoftCream").opacity(0.3))
                    .cornerRadius(8)
                }
                
                // サイズ調整
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("サイズ")
                            .font(.subheadline)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Spacer()
                        
                        Text("\(Int(viewModel.qrCodeData.size))px")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                    
                    Slider(
                        value: $viewModel.qrCodeData.size,
                        in: 100...400,
                        step: 50
                    )
                    .accentColor(Color("AsaCoffeeBrown"))
                }
            }
        }
    }
    
    // MARK: - Keyboard Type
    private var keyboardType: UIKeyboardType {
        switch viewModel.qrCodeData.qrCodeType {
        case .url:
            return .URL
        case .contact:
            return .emailAddress
        default:
            return .default
        }
    }
    
    // MARK: - Additional Fields
    @ViewBuilder
    private var additionalFields: some View {
        switch viewModel.qrCodeData.qrCodeType {
        case .wifi:
            VStack(alignment: .leading, spacing: 8) {
                Text("パスワード")
                    .font(.subheadline)
                    .foregroundColor(Color("AsaMutedSage"))
                
                SecureField("WiFiパスワード", text: $viewModel.qrCodeData.wifiPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
        case .contact:
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("メールアドレス（オプション）")
                        .font(.subheadline)
                        .foregroundColor(Color("AsaMutedSage"))
                    
                    TextField("email@example.com", text: $viewModel.qrCodeData.contactEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("電話番号（オプション）")
                        .font(.subheadline)
                        .foregroundColor(Color("AsaMutedSage"))
                    
                    TextField("090-1234-5678", text: $viewModel.qrCodeData.contactPhone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                }
            }
            
        default:
            EmptyView()
        }
    }
}

#Preview {
    InputView(viewModel: QRGeneratorViewModel())
        .padding()
        .background(Color("AsaDarkSlate"))
}