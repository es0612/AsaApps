//
//  EventTemplate.swift
//  AsaEventPlanner
//  
//  Created on 2025/08/03
//

import Foundation
import SwiftData

@Model
final class EventTemplate {
    var id: UUID
    var name: String
    var eventType: EventType
    var templateDescription: String
    var defaultTasks: [String]
    var defaultShoppingCategories: [ShoppingCategory]
    var suggestedBudget: Double
    var isCustom: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        eventType: EventType,
        templateDescription: String = "",
        defaultTasks: [String] = [],
        defaultShoppingCategories: [ShoppingCategory] = [],
        suggestedBudget: Double = 0.0,
        isCustom: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.eventType = eventType
        self.templateDescription = templateDescription
        self.defaultTasks = defaultTasks
        self.defaultShoppingCategories = defaultShoppingCategories
        self.suggestedBudget = suggestedBudget
        self.isCustom = isCustom
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    static func createDefaultTemplates() -> [EventTemplate] {
        return [
            EventTemplate(
                name: "誕生日パーティー",
                eventType: .birthday,
                templateDescription: "誕生日パーティーの計画テンプレート",
                defaultTasks: [
                    "ゲストリストの作成",
                    "招待状の送付",
                    "ケーキの注文",
                    "プレゼントの準備",
                    "会場の装飾",
                    "音楽プレイリストの準備",
                    "写真撮影の準備"
                ],
                defaultShoppingCategories: [.food, .drinks, .decoration, .gift],
                suggestedBudget: 15000
            ),
            EventTemplate(
                name: "会議・ミーティング",
                eventType: .meeting,
                templateDescription: "ビジネスミーティングの計画テンプレート",
                defaultTasks: [
                    "議題の準備",
                    "資料の準備",
                    "会議室の予約",
                    "参加者への通知",
                    "プロジェクターの確認",
                    "議事録の準備"
                ],
                defaultShoppingCategories: [.drinks, .stationery],
                suggestedBudget: 5000
            ),
            EventTemplate(
                name: "旅行計画",
                eventType: .travel,
                templateDescription: "旅行の計画テンプレート",
                defaultTasks: [
                    "行き先の決定",
                    "交通手段の予約",
                    "宿泊先の予約",
                    "観光地の調査",
                    "持ち物の準備",
                    "保険の確認",
                    "現地通貨の準備"
                ],
                defaultShoppingCategories: [.clothing, .supplies, .other],
                suggestedBudget: 100000
            ),
            EventTemplate(
                name: "家族イベント",
                eventType: .family,
                templateDescription: "家族行事の計画テンプレート",
                defaultTasks: [
                    "日程調整",
                    "場所の決定",
                    "料理の準備",
                    "写真撮影の準備",
                    "交通手段の確認"
                ],
                defaultShoppingCategories: [.food, .drinks],
                suggestedBudget: 10000
            ),
            EventTemplate(
                name: "結婚式",
                eventType: .wedding,
                templateDescription: "結婚式の計画テンプレート",
                defaultTasks: [
                    "会場の予約",
                    "ゲストリストの作成",
                    "招待状の準備",
                    "衣装の準備",
                    "料理・ケーキの手配",
                    "写真・ビデオ撮影の手配",
                    "装花の手配",
                    "音響・照明の確認"
                ],
                defaultShoppingCategories: [.decoration, .clothing, .gift],
                suggestedBudget: 500000
            )
        ]
    }
}