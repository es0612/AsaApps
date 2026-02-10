import Foundation

// MARK: - ひらがなモードViewModel

/// ひらがな練習モード専用のUI状態管理（手書き認識対応）
@Observable
@MainActor
public final class HiraganaViewModel {

    // MARK: - Dependencies

    /// 手書き認識サービス（オプショナル: 手書きモード時のみ使用）
    private let handwritingService: HandwritingRecognizing?

    // MARK: - Properties

    /// 現在の対象ひらがな文字
    public var currentCharacter: String = ""

    /// 手書きモードかどうか（true: 手書き入力、false: 選択式）
    public var isWritingMode: Bool = false

    /// 手書きの描画ポイント（ストローク単位の配列）
    public var drawingPoints: [[CGPoint]] = []

    /// 手書き認識の結果
    public var recognitionResult: HandwritingResult?

    /// 認識処理中フラグ
    public var isRecognizing: Bool = false

    // MARK: - Init

    public init(handwritingService: HandwritingRecognizing? = nil) {
        self.handwritingService = handwritingService
    }

    // MARK: - Methods

    /// 問題データからUI表示用の状態をセットアップ
    public func setupForQuestion(_ question: GameQuestion) {
        // 描画状態をリセット
        clearDrawing()
        recognitionResult = nil

        // 問題タイプに応じてモードを設定
        switch question.questionType {
        case .hiraganaWriting:
            // 手書きモード: 表示された文字を手書きで書く
            isWritingMode = true
            currentCharacter = question.correctAnswer
        case .hiraganaReading, .hiraganaMatching:
            // 選択式モード: 問題文に対応する選択肢を選ぶ
            isWritingMode = false
            currentCharacter = question.questionText
        default:
            isWritingMode = false
            currentCharacter = question.questionText
        }
    }

    /// 手書き描画を認識サービスに送信して結果を取得
    public func submitDrawing() async {
        guard let service = handwritingService else { return }
        guard !drawingPoints.isEmpty else { return }

        isRecognizing = true

        do {
            let result = try await service.recognize(drawingPoints: drawingPoints)
            recognitionResult = result
        } catch {
            // 認識失敗時は結果をnilに
            recognitionResult = nil
        }

        isRecognizing = false
    }

    /// 手書き描画データをクリア
    public func clearDrawing() {
        drawingPoints = []
        recognitionResult = nil
    }
}
