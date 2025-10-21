//
//  PodcastEpisode.swift
//  AsaPodcastPlayer
//
//  Created by AsaPapa on 2025-10-21.
//

import Foundation

/// Podcastエピソードのデータモデル
struct PodcastEpisode: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let audioFileName: String
    let duration: TimeInterval
    let publishedDate: Date

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        audioFileName: String,
        duration: TimeInterval = 0,
        publishedDate: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.audioFileName = audioFileName
        self.duration = duration
        self.publishedDate = publishedDate
    }
}

// MARK: - サンプルデータ

extension PodcastEpisode {
    static let sampleEpisodes: [PodcastEpisode] = [
        PodcastEpisode(
            title: "自分のチームを作り育てるのが難しすぎた話",
            description: "エンジニアリングチームの立ち上げと成長における課題と学びを共有します。チームビルディングの難しさと、それを乗り越えるための実践的なアプローチについて語ります。",
            audioFileName: "自分のチームを作り育てるのが難しすぎた話.m4a",
            duration: 287,
            publishedDate: Date()
        ),
        PodcastEpisode(
            title: "いいプロダクトを作るにはいいチームだけでは足りない話",
            description: "プロダクト開発におけるチームの重要性と、それだけでは足りない要素について議論します。優れたプロダクトを生み出すために必要な、チーム以外の重要な要素とは？",
            audioFileName: "いいプロダクトを作るにはいいチームだけでは足りない話.m4a",
            duration: 309,
            publishedDate: Date().addingTimeInterval(-3*24*60*60)
        ),
        PodcastEpisode(
            title: "保育園通い始めの洗礼の話",
            description: "朝活パパエンジニアが語る、保育園生活スタート時の体験談です。子育てとエンジニアリングを両立する中で経験した、保育園という新しい環境での挑戦と学び。",
            audioFileName: "保育園通い始めの洗礼の話.m4a",
            duration: 224,
            publishedDate: Date().addingTimeInterval(-7*24*60*60)
        )
    ]

    static var preview: PodcastEpisode {
        sampleEpisodes[0]
    }
}
