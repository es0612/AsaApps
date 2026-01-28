//
//  GameView.swift
//  AsaMultiplayerGame
//
//  ゲームプレイ画面
//

import SwiftUI
import AsaUIKit

struct GameView: View {
    // MARK: - Properties

    @Bindable var viewModel: GameViewModel
    @State private var drawingViewModel = DrawingViewModel()

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景
            Color("AsaSoftCream")
                .ignoresSafeArea()

            // メインコンテンツ
            VStack(spacing: 0) {
                // ヘッダー
                headerSection
                    .padding(.horizontal)
                    .padding(.top, 8)

                // ゲームコンテンツ
                gameContent
                    .padding()
            }

            // カウントダウンオーバーレイ
            if viewModel.gamePhase == .countdown {
                CountdownView(number: viewModel.countdownNumber)
                    .transition(.opacity)
            }

            // ラウンド結果オーバーレイ
            if viewModel.gamePhase == .roundResult {
                roundResultOverlay
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.gamePhase)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            // ミニスコアボード
            MiniScoreboardView(
                players: viewModel.players,
                localPlayerId: viewModel.localPlayer?.id
            )

            // ラウンド情報
            if let round = viewModel.currentRound {
                HStack {
                    Text("ラウンド \(round.roundNumber)/\(round.totalRounds)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("AsaDarkSlate"))

                    Spacer()

                    // 役割表示
                    roleIndicator
                }
            }

            // タイマー
            if viewModel.gamePhase == .drawing {
                TimerView(
                    remainingTime: viewModel.remainingTime,
                    totalTime: viewModel.settings.roundTimeLimit
                )
            }
        }
    }

    private var roleIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: viewModel.myRole == .drawer ? "pencil" : "eye")
            Text(viewModel.myRole == .drawer ? "描く側" : "当てる側")
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(viewModel.myRole == .drawer ? Color("AsaCoffeeBrown") : Color("AsaDarkSlate"))
        .cornerRadius(12)
    }

    // MARK: - Game Content

    @ViewBuilder
    private var gameContent: some View {
        VStack(spacing: 16) {
            // 描く側の場合：お題表示
            if viewModel.myRole == .drawer, let round = viewModel.currentRound {
                WordDisplayView(word: round.word)
            }

            // キャンバス
            DrawingCanvasView(
                canvas: viewModel.canvas,
                currentStroke: drawingViewModel.currentStroke,
                isDrawingEnabled: viewModel.myRole == .drawer && viewModel.gamePhase == .drawing,
                onDrawingStarted: { point in
                    drawingViewModel.startStroke(at: point)
                },
                onDrawingContinued: { point in
                    drawingViewModel.continueStroke(to: point)
                },
                onDrawingEnded: {
                    if let stroke = drawingViewModel.endStroke() {
                        Task {
                            await viewModel.addStroke(stroke)
                        }
                    }
                }
            )
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 350)

            // 描く側の場合：ツールバー
            if viewModel.myRole == .drawer && viewModel.gamePhase == .drawing {
                DrawingToolbar(
                    selectedColor: $drawingViewModel.selectedColor,
                    lineWidth: $drawingViewModel.lineWidth,
                    onClear: {
                        Task {
                            await viewModel.clearDrawing()
                        }
                    },
                    onUndo: {
                        Task {
                            await viewModel.undoDrawing()
                        }
                    }
                )
                .frame(maxWidth: 350)
            }

            // 当てる側の場合：回答入力
            if viewModel.myRole == .guesser && viewModel.gamePhase == .drawing {
                AnswerInputView(
                    answer: $viewModel.answerInput,
                    onSubmit: {
                        Task {
                            await viewModel.submitAnswer()
                        }
                    },
                    isEnabled: viewModel.remainingTime > 0
                )
                .frame(maxWidth: 350)
            }
        }
    }

    // MARK: - Round Result Overlay

    private var roundResultOverlay: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // 結果アイコン
                ZStack {
                    Circle()
                        .fill(viewModel.lastRoundResult?.isCorrect == true ? Color.green : Color.red)
                        .frame(width: 100, height: 100)

                    Image(systemName: viewModel.lastRoundResult?.isCorrect == true ? "checkmark" : "xmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                }

                // 結果テキスト
                VStack(spacing: 8) {
                    Text(viewModel.lastRoundResult?.isCorrect == true ? "正解！" : "不正解...")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    // 正解のお題を表示
                    if let round = viewModel.currentRound {
                        Text("お題: \(round.word)")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // 獲得ポイント
                    if let result = viewModel.lastRoundResult, result.isCorrect {
                        Text("+\(result.earnedPoints) ポイント")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                }

                // 次のラウンドへ
                Text("次のラウンドへ...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = GameViewModel()
    viewModel.currentScreen = .playing
    viewModel.gamePhase = .drawing
    viewModel.myRole = .drawer
    viewModel.remainingTime = 25
    viewModel.players = [
        Player(id: "1", name: "プレイヤー1", avatarEmoji: "🎨", score: 100),
        Player(id: "2", name: "AIプレイヤー", avatarEmoji: "🤖", score: 50)
    ]
    viewModel.localPlayer = viewModel.players[0]
    viewModel.currentRound = GameRound(
        roundNumber: 2,
        totalRounds: 5,
        drawerId: "1",
        guesserId: "2",
        word: "りんご",
        startTime: Date(),
        timeLimit: 30
    )
    return GameView(viewModel: viewModel)
}
