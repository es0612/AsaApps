//
//  ShoppingItem.swift
//  AsaEventPlanner
//  
//  Created on 2025/08/03
//

import Foundation
import SwiftData

enum ShoppingCategory: String, CaseIterable, Codable {
    case food = "食材・食品"
    case drinks = "飲み物"
    case decoration = "装飾品"
    case supplies = "備品"
    case gift = "プレゼント"
    case stationery = "文房具"
    case clothing = "衣装・服装"
    case electronics = "電子機器"
    case other = "その他"
    
    var iconName: String {
        switch self {
        case .food: return "fork.knife"
        case .drinks: return "cup.and.saucer.fill"
        case .decoration: return "star.fill"
        case .supplies: return "shippingbox.fill"
        case .gift: return "gift.fill"
        case .stationery: return "pencil"
        case .clothing: return "tshirt.fill"
        case .electronics: return "tv.fill"
        case .other: return "bag.fill"
        }
    }
}

@Model
final class ShoppingItem {
    var id: UUID
    var name: String
    var itemDescription: String
    var category: ShoppingCategory
    var quantity: Int
    var estimatedPrice: Double
    var actualPrice: Double
    var isPurchased: Bool
    var purchasedAt: Date?
    var store: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(inverse: \Event.shoppingItems) var event: Event?
    
    init(
        name: String,
        itemDescription: String = "",
        category: ShoppingCategory = .other,
        quantity: Int = 1,
        estimatedPrice: Double = 0.0,
        store: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.itemDescription = itemDescription
        self.category = category
        self.quantity = quantity
        self.estimatedPrice = estimatedPrice
        self.actualPrice = 0.0
        self.isPurchased = false
        self.purchasedAt = nil
        self.store = store
        self.notes = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func markAsPurchased(actualPrice: Double? = nil) {
        self.isPurchased = true
        self.purchasedAt = Date()
        if let price = actualPrice {
            self.actualPrice = price
        } else if self.actualPrice == 0.0 {
            self.actualPrice = self.estimatedPrice
        }
        self.updatedAt = Date()
    }
    
    func markAsUnpurchased() {
        self.isPurchased = false
        self.purchasedAt = nil
        self.updatedAt = Date()
    }
    
    var totalEstimatedCost: Double {
        estimatedPrice * Double(quantity)
    }
    
    var totalActualCost: Double {
        actualPrice * Double(quantity)
    }
    
    var displayName: String {
        quantity > 1 ? "\(name) ×\(quantity)" : name
    }
    
    var priceDisplay: String {
        if isPurchased && actualPrice > 0 {
            return "¥\(Int(totalActualCost))"
        } else if estimatedPrice > 0 {
            return "¥\(Int(totalEstimatedCost)) (予算)"
        } else {
            return "価格未設定"
        }
    }
}