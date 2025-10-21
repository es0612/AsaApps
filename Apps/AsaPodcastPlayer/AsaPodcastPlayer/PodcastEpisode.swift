//
//  PodcastEpisode.swift
//  AsaPodcastPlayer
//
//  Created by AsaPapa on 2025-10-21.
//

import Foundation

/// Podcastエピソードのデータモデル
struct PodcastEpisode: Identifiable, Codable, Sendable {
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
            title: "保育園通い始めの洗礼の話",
            description: "朝活パパエンジニアが語る、保育園生活スタート時の体験談です。",
            audioFileName: "保育園通い始めの洗礼の話.m4a",
            duration: 0,
            publishedDate: Date()
        )
    ]

    static var preview: PodcastEpisode {
        sampleEpisodes[0]
    }
}
