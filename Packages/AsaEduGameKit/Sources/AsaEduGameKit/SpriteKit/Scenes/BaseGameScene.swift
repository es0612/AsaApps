import SpriteKit
import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - ゲームシーンデリゲート

/// SpriteKitシーンからSwiftUI層への通知プロトコル
@MainActor
public protocol GameSceneDelegate: AnyObject {
    /// 選択肢がタップされた
    func sceneDidSelectAnswer(_ scene: BaseGameScene, answer: String)
    /// 次の問題リクエスト
    func sceneDidRequestNextQuestion(_ scene: BaseGameScene)
    /// お祝いアニメーション完了
    func sceneDidFinishCelebration(_ scene: BaseGameScene)
}

// MARK: - 基底ゲームシーン

/// SpriteKitの共通基底シーン（全ゲームモードの親クラス）
public class BaseGameScene: SKScene {

    // MARK: - Properties

    /// SwiftUI層へのデリゲート
    public weak var gameDelegate: GameSceneDelegate?

    /// 現在表示中の問題
    public var currentQuestion: GameQuestion?

    /// 現在のゲーム状態
    public var gameState: EduGameState = .idle

    // MARK: - 共通ノード

    /// 問題文表示ラベル
    var questionLabel: SKLabelNode!

    /// スコア表示ラベル（右上）
    var scoreLabel: SKLabelNode!

    /// コンボ表示ラベル（左上）
    var comboLabel: SKLabelNode!

    /// 応援キャラクター
    var characterNode: CharacterNode!

    // MARK: - 定数

    /// 共通フォント名
    let fontName = "HiraginoSans-W6"

    /// 背景色（薄いクリーム色）
    let backgroundColorValue = SKColor(red: 0.97, green: 0.93, blue: 0.87, alpha: 1.0)

    // MARK: - Scene Ready State

    /// シーンが didMove 完了済みか（共通ノード初期化済みか）
    private var isSceneReady = false

    /// didMove 前に届いた問題の保留先（マウント完了後に再駆動する）
    private var pendingQuestion: GameQuestion?

    // MARK: - Lifecycle

    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = backgroundColorValue
        setupCommonNodes()
        isSceneReady = true

        // マウント前に届いた問題があれば再駆動（dynamic dispatch でサブクラスの override に届く）
        if let queued = pendingQuestion {
            pendingQuestion = nil
            presentQuestion(queued)
        }
    }

    // MARK: - 共通セットアップ

    /// 共通ノード（問題ラベル、スコア、コンボ、キャラクター）を配置
    public func setupCommonNodes() {
        let sceneWidth = size.width
        let sceneHeight = size.height

        // 問題文ラベル（画面上部1/4）
        questionLabel = SKLabelNode(fontNamed: fontName)
        questionLabel.fontSize = 32
        questionLabel.fontColor = SKColor(red: 0.18, green: 0.24, blue: 0.27, alpha: 1.0)
        questionLabel.position = CGPoint(x: sceneWidth / 2, y: sceneHeight * 0.75)
        questionLabel.horizontalAlignmentMode = .center
        questionLabel.verticalAlignmentMode = .center
        questionLabel.numberOfLines = 0
        questionLabel.preferredMaxLayoutWidth = sceneWidth * 0.85
        questionLabel.zPosition = 10
        addChild(questionLabel)

        // スコアラベル（右上）
        scoreLabel = SKLabelNode(fontNamed: fontName)
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = SKColor(red: 0.78, green: 0.55, blue: 0.33, alpha: 1.0)
        scoreLabel.position = CGPoint(x: sceneWidth - 20, y: sceneHeight - 40)
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.text = "0"
        scoreLabel.zPosition = 10
        addChild(scoreLabel)

        // コンボラベル（左上）
        comboLabel = SKLabelNode(fontNamed: fontName)
        comboLabel.fontSize = 20
        comboLabel.fontColor = SKColor(red: 0.85, green: 0.40, blue: 0.20, alpha: 1.0)
        comboLabel.position = CGPoint(x: 20, y: sceneHeight - 40)
        comboLabel.horizontalAlignmentMode = .left
        comboLabel.verticalAlignmentMode = .top
        comboLabel.text = ""
        comboLabel.zPosition = 10
        addChild(comboLabel)

        // キャラクターノード（画面中央やや上）
        characterNode = CharacterNode(emoji: "🐱", size: 60)
        characterNode.position = CGPoint(x: sceneWidth / 2, y: sceneHeight * 0.60)
        characterNode.zPosition = 5
        addChild(characterNode)
        characterNode.idle()
    }

    // MARK: - 問題表示（サブクラスでオーバーライド）

    /// 問題を表示する（サブクラスでオーバーライドして具体的な表示を実装）
    public func presentQuestion(_ question: GameQuestion) {
        // didMove 前にビュー側から呼ばれた場合は最後の 1 件だけ保留し、
        // didMove 末尾で再駆動する。IUO ノードへのアクセスを避けてクラッシュを防ぐ。
        guard isSceneReady else {
            pendingQuestion = question
            return
        }

        currentQuestion = question
        gameState = .playing

        // 問題文を更新
        questionLabel.text = question.questionText
        questionLabel.alpha = 0
        questionLabel.run(SKAction.fadeIn(withDuration: 0.3))

        // キャラクターを応援モードに
        characterNode.idle()
    }

    // MARK: - エフェクト

    /// 正解エフェクトを表示
    public func showCorrectEffect() {
        gameState = .showingResult

        // キャラクターがお祝い
        characterNode.celebrate()

        // 正解エフェクト
        CelebrationEffect.showCorrectAnswer(
            in: self,
            at: CGPoint(x: size.width / 2, y: size.height * 0.50)
        )

        // 一定時間後に次の問題をリクエスト
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.gameDelegate?.sceneDidRequestNextQuestion(self)
            }
        ]))
    }

    /// 不正解エフェクトを表示
    public func showIncorrectEffect() {
        gameState = .showingResult

        // キャラクターが励ます
        characterNode.encourage()

        // 励ましエフェクト
        CelebrationEffect.showEncouragement(
            in: self,
            at: CGPoint(x: size.width / 2, y: size.height * 0.50)
        )

        // 画面を軽く揺らす
        let shakeAction = SKAction.sequence([
            SKAction.moveBy(x: -5, y: 0, duration: 0.05),
            SKAction.moveBy(x: 10, y: 0, duration: 0.05),
            SKAction.moveBy(x: -10, y: 0, duration: 0.05),
            SKAction.moveBy(x: 5, y: 0, duration: 0.05),
        ])
        questionLabel.run(shakeAction)

        // 一定時間後に次の問題をリクエスト
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.gameDelegate?.sceneDidRequestNextQuestion(self)
            }
        ]))
    }

    /// コンボエフェクトを表示
    public func showComboEffect(combo: Int) {
        CelebrationEffect.showCombo(
            in: self,
            combo: combo,
            at: CGPoint(x: size.width / 2, y: size.height * 0.50)
        )
    }

    // MARK: - スコア・コンボ更新

    /// スコア表示を更新
    public func updateScore(_ score: Int) {
        scoreLabel.text = "\(score)"

        // スコア更新アニメーション
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        scoreLabel.run(SKAction.sequence([scaleUp, scaleDown]))
    }

    /// コンボ表示を更新
    public func updateCombo(_ combo: Int) {
        if combo >= 2 {
            comboLabel.text = "\(combo)コンボ!"
            let scaleUp = SKAction.scale(to: 1.3, duration: 0.1)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
            comboLabel.run(SKAction.sequence([scaleUp, scaleDown]))
        } else {
            comboLabel.text = ""
        }
    }

    // MARK: - ユーティリティ

    /// 選択肢ノードを全てクリア
    func clearAnswerOptions() {
        enumerateChildNodes(withName: "answer_option") { node, _ in
            node.removeFromParent()
        }
        enumerateChildNodes(withName: "//answer_option") { node, _ in
            node.removeFromParent()
        }
    }

    // MARK: - タッチ位置取得ヘルパー

    /// タッチ/クリック位置を取得するヘルパー（iOS/macOS両対応）
    #if os(iOS)
    /// iOS: タッチ位置を取得
    func touchLocation(from touches: Set<UITouch>) -> CGPoint? {
        guard let touch = touches.first else { return nil }
        return touch.location(in: self)
    }
    #else
    /// macOS: クリック位置を取得
    func clickLocation(from event: NSEvent) -> CGPoint? {
        return event.location(in: self)
    }
    #endif
}
