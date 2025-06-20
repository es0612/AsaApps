import Foundation
import SwiftUI

struct PhotoFrame: Codable, Identifiable {
    let id = UUID()
    var imageData: Data? // 写真データ
    var frameColorHex: String = "#C68C53" // 16進数カラーコード（デフォルトasaCoffeeBrown）
    var frameWidth: CGFloat = 5.0 // デフォルト枠太さ
    let createdDate: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id, imageData, frameColorHex, frameWidth, createdDate
    }
}


