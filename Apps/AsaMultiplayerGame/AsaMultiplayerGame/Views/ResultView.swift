//
//  ResultView.swift
//  AsaMultiplayerGame
//
//  結果画面
//

import SwiftUI
import AsaUIKit

struct ResultView: View {
    // MARK: - Properties

    @Bindable var viewModel: GameViewModel

    @State private var showConfetti = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [AsaColors.softCream, Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // 紙吹雪エフェクト
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }

            VStack(spacing: 32) {
                // 結果ヘッダー
                resultHeader

                // プレイヤー結果
                playerResults

                Spacer()

                // アクションボタン
                actionButtons
            }
            .padding()
        }
        .onAppear {
            // 勝者がいる場合は紙吹雪を表示
            if viewModel.gameResult?.isDraw == false {
                withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                    showConfetti = true
                }
            }
        }
    }

    // MARK: - Result Header

    private var resultHeader: some View {
        VStack(spacing: 16) {
            // 勝敗アイコン
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: resultColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)

                if isWinner {
                    Text("🏆")
                        .font(.system(size: 60))
                } else if viewModel.gameResult?.isDraw == true {
                    Text("🤝")
                        .font(.system(size: 60))
                } else {
                    Text("😢")
                        .font(.system(size: 60))
                }
            }

            // 結果テキスト
            VStack(spacing: 4) {
                Text(resultTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AsaColors.darkSlate)

                Text(resultSubtitle)
                    .font(.subheadline)
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
        .padding(.top, 40)
    }

    private var isWinner: Bool {
        guard let result = viewModel.gameResult,
              let playerId = viewModel.localPlayer?.id else { return false }
        return result.winnerIds.contains(playerId)
    }

    private var resultTitle: String {
        if viewModel.gameResult?.isDraw == true {
            return "引き分け！"
        } else if isWinner {
            return "勝利！"
        } else {
            return "残念..."
        }
    }

    private var resultSubtitle: String {
        let totalRounds = viewModel.settings.roundCount
        return "\(totalRounds)ラウンドのお絵かきバトル終了"
    }

    private var resultColors: [Color] {
        if viewModel.gameResult?.isDraw == true {
            return [AsaColors.mutedSage, AsaColors.darkSlate]
        } else if isWinner {
            return [.yellow, .orange]
        } else {
            return [AsaColors.mutedSage, .gray]
        }
    }

    // MARK: - Player Results

    private var playerResults: some View {
        VStack(spacing: 16) {
            Text("最終スコア")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            ForEach(sortedPlayers) { player in
                playerResultRow(player, rank: rankOf(player))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }

    private var sortedPlayers: [Player] {
        viewModel.players.sorted { $0.score > $1.score }
    }

    private func rankOf(_ player: Player) -> Int {
        let sorted = sortedPlayers
        return (sorted.firstIndex(where: { $0.id == player.id }) ?? 0) + 1
    }

    private func playerResultRow(_ player: Player, rank: Int) -> some View {
        HStack {
            // ランク
            ZStack {
                Circle()
                    .fill(rankColor(rank))
                    .frame(width: 36, height: 36)

                Text("\(rank)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            // アバター
            Text(player.avatarEmoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(AsaColors.softCream)
                .clipShape(Circle())

            // 名前
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(player.name)
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    if player.id == viewModel.localPlayer?.id {
                        Text("(あなた)")
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)
                    }
                }

                // 勝者マーク
                if viewModel.gameResult?.winnerIds.contains(player.id) == true {
                    Text("🏆 優勝")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            // スコア
            Text("\(player.score)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AsaColors.coffeeBrown)

            Text("pt")
                .font(.caption)
                .foregroundColor(AsaColors.mutedSage)
        }
        .padding(12)
        .background(
            player.id == viewModel.localPlayer?.id
                ? AsaColors.softCream.opacity(0.5)
                : Color.clear
        )
        .cornerRadius(12)
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .orange
        case 2: return .gray
        case 3: return .brown
        default: return AsaColors.mutedSage
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // もう一度遊ぶ
            Button {
                Task {
                    await viewModel.playAgain()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("もう一度遊ぶ")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AsaColors.coffeeBrown)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // メインメニューに戻る
            Button {
                viewModel.returnToMainMenu()
            } label: {
                HStack {
                    Image(systemName: "house")
                    Text("メインメニューに戻る")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AsaColors.darkSlate)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Confetti View

/// 紙吹雪エフェクト
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
    }

    private func generateConfetti(in size: CGSize) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        let shapes = ["circle", "square", "triangle"]

        confettiPieces = (0..<50).map { _ in
            ConfettiPiece(
                id: UUID(),
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -100...(-50)),
                color: colors.randomElement()!,
                shape: shapes.randomElement()!,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.5),
                delay: Double.random(in: 0...2)
            )
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: UUID
    let x: CGFloat
    let y: CGFloat
    let color: Color
    let shape: String
    let rotation: Double
    let scale: CGFloat
    let delay: Double
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var offsetY: CGFloat = 0
    @State private var rotation: Double = 0

    var body: some View {
        Group {
            switch piece.shape {
            case "circle":
                Circle()
                    .fill(piece.color)
            case "square":
                Rectangle()
                    .fill(piece.color)
            default:
                Triangle()
                    .fill(piece.color)
            }
        }
        .frame(width: 10 * piece.scale, height: 10 * piece.scale)
        .rotationEffect(.degrees(rotation))
        .position(x: piece.x, y: piece.y + offsetY)
        .onAppear {
            withAnimation(
                .linear(duration: 3)
                .delay(piece.delay)
                .repeatForever(autoreverses: false)
            ) {
                offsetY = UIScreen.main.bounds.height + 200
                rotation = piece.rotation + 720
            }
        }
    }
}

/// 三角形シェイプ
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    let viewModel = GameViewModel()
    viewModel.players = [
        Player(id: "1", name: "プレイヤー1", avatarEmoji: "🎨", score: 250),
        Player(id: "2", name: "AIプレイヤー", avatarEmoji: "🤖", score: 150)
    ]
    viewModel.localPlayer = viewModel.players[0]
    viewModel.gameResult = GameResult(
        winnerIds: ["1"],
        finalScores: ["1": 250, "2": 150],
        isDraw: false
    )
    return ResultView(viewModel: viewModel)
}
