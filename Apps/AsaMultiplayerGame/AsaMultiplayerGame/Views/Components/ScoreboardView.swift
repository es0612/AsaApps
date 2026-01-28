//
//  ScoreboardView.swift
//  AsaMultiplayerGame
//
//  スコアボードコンポーネント
//

import SwiftUI

/// スコアボードビュー
///
/// プレイヤーのスコアを表示するコンポーネントです。
struct ScoreboardView: View {
    // MARK: - Properties

    let players: [Player]
    let currentRound: Int
    let totalRounds: Int
    let localPlayerId: String?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // ラウンド情報
            HStack {
                Text("ラウンド \(currentRound)/\(totalRounds)")
                    .font(.headline)
                    .foregroundColor(Color("AsaDarkSlate"))

                Spacer()
            }

            // プレイヤースコア
            HStack(spacing: 16) {
                ForEach(players) { player in
                    playerScoreCard(player)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }

    // MARK: - Player Score Card

    private func playerScoreCard(_ player: Player) -> some View {
        VStack(spacing: 8) {
            // アバター
            Text(player.avatarEmoji)
                .font(.title)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(player.id == localPlayerId ? Color("AsaSoftCream") : Color.gray.opacity(0.1))
                )
                .overlay(
                    Circle()
                        .stroke(
                            player.id == localPlayerId ? Color("AsaCoffeeBrown") : Color.clear,
                            lineWidth: 2
                        )
                )

            // 名前
            Text(player.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaDarkSlate"))
                .lineLimit(1)

            // スコア
            Text("\(player.score)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("AsaCoffeeBrown"))

            // ローカルプレイヤーマーク
            if player.id == localPlayerId {
                Text("あなた")
                    .font(.caption2)
                    .foregroundColor(Color("AsaMutedSage"))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Mini Scoreboard

/// ミニスコアボード（ゲーム中に常時表示）
struct MiniScoreboardView: View {
    let players: [Player]
    let localPlayerId: String?

    var body: some View {
        HStack(spacing: 16) {
            ForEach(players) { player in
                HStack(spacing: 4) {
                    Text(player.avatarEmoji)
                        .font(.caption)

                    Text(player.name)
                        .font(.caption)
                        .fontWeight(player.id == localPlayerId ? .bold : .regular)
                        .lineLimit(1)

                    Text("\(player.score)pt")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color("AsaCoffeeBrown"))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(player.id == localPlayerId ? Color("AsaSoftCream") : Color.gray.opacity(0.1))
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("Scoreboard") {
    let players = [
        Player(id: "1", name: "プレイヤー1", avatarEmoji: "🎨", score: 150),
        Player(id: "2", name: "AIプレイヤー", avatarEmoji: "🤖", score: 100)
    ]

    return ScoreboardView(
        players: players,
        currentRound: 3,
        totalRounds: 5,
        localPlayerId: "1"
    )
    .padding()
}

#Preview("Mini Scoreboard") {
    let players = [
        Player(id: "1", name: "プレイヤー1", avatarEmoji: "🎨", score: 150),
        Player(id: "2", name: "AIプレイヤー", avatarEmoji: "🤖", score: 100)
    ]

    return MiniScoreboardView(
        players: players,
        localPlayerId: "1"
    )
    .padding()
}
