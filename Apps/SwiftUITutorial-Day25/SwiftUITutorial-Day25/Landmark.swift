import Foundation
import SwiftUI

struct Landmark: Identifiable {
    let id = UUID()
    let name: String
    let park: String
    let state: String
    let description: String
    var isFavorite: Bool // いいね状態
    var isFeatured: Bool // フィルタリング用に追加
    var dateAdded: Date // 並べ替え用に追加
}

