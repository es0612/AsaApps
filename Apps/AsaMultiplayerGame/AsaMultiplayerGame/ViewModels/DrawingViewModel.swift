//
//  DrawingViewModel.swift
//  AsaMultiplayerGame
//
//  描画管理のViewModel
//

import Foundation
import SwiftUI

/// 描画操作を管理するViewModel
///
/// キャンバスへの描画操作、色・線幅の選択、Undo機能などを担当します。
@MainActor
@Observable
final class DrawingViewModel {
    // MARK: - Properties

    /// 現在選択中の色
    var selectedColor: StrokeColor = .black

    /// 現在の線の太さ
    var lineWidth: CGFloat = 4.0

    /// 現在描画中のストローク
    var currentStroke: DrawingStroke?

    /// 描画可能かどうか
    var isDrawingEnabled: Bool = true

    /// 利用可能な線の太さ
    let availableLineWidths: [CGFloat] = [2.0, 4.0, 8.0, 12.0]

    // MARK: - Drawing Methods

    /// 描画を開始
    func startStroke(at point: CGPoint) {
        guard isDrawingEnabled else { return }

        currentStroke = DrawingStroke(
            points: [StrokePoint(point)],
            color: selectedColor,
            lineWidth: lineWidth
        )
    }

    /// 描画を継続
    func continueStroke(to point: CGPoint) {
        guard isDrawingEnabled else { return }
        currentStroke?.addPoint(point)
    }

    /// 描画を終了
    func endStroke() -> DrawingStroke? {
        guard isDrawingEnabled else { return nil }

        let stroke = currentStroke
        currentStroke = nil
        return stroke
    }

    /// 色を選択
    func selectColor(_ color: StrokeColor) {
        selectedColor = color
    }

    /// 線の太さを選択
    func selectLineWidth(_ width: CGFloat) {
        lineWidth = width
    }

    /// 消しゴムモード（白色を選択）
    func enableEraser() {
        selectedColor = .white
    }

    /// 描画をリセット
    func reset() {
        currentStroke = nil
        selectedColor = .black
        lineWidth = 4.0
    }
}
