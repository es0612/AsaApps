//
//  DrawingData.swift
//  AsaMultiplayerGame
//
//  描画データモデル
//

import Foundation
import SwiftUI

/// 描画ストローク（一筆分）
struct DrawingStroke: Codable, Sendable, Identifiable, Equatable {
    // MARK: - Properties

    /// ストロークID
    let id: String

    /// ストロークを構成する点群
    var points: [StrokePoint]

    /// ストロークの色
    let color: StrokeColor

    /// 線の太さ
    let lineWidth: CGFloat

    /// 作成タイムスタンプ
    let timestamp: Date

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        points: [StrokePoint] = [],
        color: StrokeColor = .black,
        lineWidth: CGFloat = 4.0,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
        self.timestamp = timestamp
    }

    // MARK: - Methods

    /// 点を追加
    mutating func addPoint(_ point: CGPoint) {
        points.append(StrokePoint(x: point.x, y: point.y))
    }

    /// CGPointの配列に変換
    var cgPoints: [CGPoint] {
        points.map { CGPoint(x: $0.x, y: $0.y) }
    }
}

/// ストロークの点（Codable対応）
struct StrokePoint: Codable, Sendable, Equatable {
    let x: CGFloat
    let y: CGFloat

    init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }

    init(_ point: CGPoint) {
        self.x = point.x
        self.y = point.y
    }
}

/// ストロークの色
enum StrokeColor: String, Codable, Sendable, CaseIterable {
    case black = "black"
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case green = "green"
    case blue = "blue"
    case purple = "purple"
    case brown = "brown"
    case white = "white"

    /// SwiftUI Colorに変換
    var color: Color {
        switch self {
        case .black: return .black
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .brown: return .brown
        case .white: return .white
        }
    }

    /// 表示用絵文字
    var emoji: String {
        switch self {
        case .black: return "⚫️"
        case .red: return "🔴"
        case .orange: return "🟠"
        case .yellow: return "🟡"
        case .green: return "🟢"
        case .blue: return "🔵"
        case .purple: return "🟣"
        case .brown: return "🟤"
        case .white: return "⚪️"
        }
    }
}

/// 描画キャンバス全体のデータ
struct DrawingCanvas: Codable, Sendable, Equatable {
    /// 全ストローク
    var strokes: [DrawingStroke]

    /// キャンバスサイズ
    var canvasSize: CGSize

    init(strokes: [DrawingStroke] = [], canvasSize: CGSize = CGSize(width: 300, height: 300)) {
        self.strokes = strokes
        self.canvasSize = canvasSize
    }

    /// ストロークを追加
    mutating func addStroke(_ stroke: DrawingStroke) {
        strokes.append(stroke)
    }

    /// 最後のストロークを削除（Undo）
    mutating func undoLastStroke() {
        if !strokes.isEmpty {
            strokes.removeLast()
        }
    }

    /// 全消去
    mutating func clear() {
        strokes.removeAll()
    }
}
