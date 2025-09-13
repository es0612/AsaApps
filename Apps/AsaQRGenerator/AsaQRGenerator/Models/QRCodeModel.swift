//
//  QRCodeModel.swift
//  AsaQRGenerator
//
//  Created on 2025/09/13
//

import Foundation

// MARK: - QRコードタイプ
enum QRCodeType: String, CaseIterable, Identifiable {
    case text = "テキスト"
    case url = "URL"
    case wifi = "WiFi"
    case contact = "連絡先"
    
    var id: String { self.rawValue }
    
    var placeholder: String {
        switch self {
        case .text:
            return "テキストを入力"
        case .url:
            return "https://example.com"
        case .wifi:
            return "ネットワーク名"
        case .contact:
            return "名前を入力"
        }
    }
}

// MARK: - エラー訂正レベル
enum ErrorCorrectionLevel: String, CaseIterable, Identifiable {
    case l = "L (7%)"
    case m = "M (15%)"
    case q = "Q (25%)"
    case h = "H (30%)"
    
    var id: String { self.rawValue }
    
    var correctionString: String {
        switch self {
        case .l: return "L"
        case .m: return "M"
        case .q: return "Q"
        case .h: return "H"
        }
    }
}

// MARK: - QRコードデータ
struct QRCodeData {
    var inputText: String = ""
    var qrCodeType: QRCodeType = .text
    var errorCorrectionLevel: ErrorCorrectionLevel = .m
    var size: CGFloat = 200
    
    // WiFi設定用
    var wifiPassword: String = ""
    var wifiSecurityType: String = "WPA"
    
    // 連絡先用
    var contactEmail: String = ""
    var contactPhone: String = ""
    
    // QRコード用データを生成
    var qrCodeString: String {
        switch qrCodeType {
        case .text:
            return inputText
        case .url:
            return inputText.hasPrefix("http") ? inputText : "https://\(inputText)"
        case .wifi:
            // WiFi QRコードフォーマット: WIFI:T:WPA;S:ネットワーク名;P:パスワード;;
            return "WIFI:T:\(wifiSecurityType);S:\(inputText);P:\(wifiPassword);;"
        case .contact:
            // vCardフォーマット
            var vCard = "BEGIN:VCARD\nVERSION:3.0\n"
            vCard += "FN:\(inputText)\n"
            if !contactEmail.isEmpty {
                vCard += "EMAIL:\(contactEmail)\n"
            }
            if !contactPhone.isEmpty {
                vCard += "TEL:\(contactPhone)\n"
            }
            vCard += "END:VCARD"
            return vCard
        }
    }
}