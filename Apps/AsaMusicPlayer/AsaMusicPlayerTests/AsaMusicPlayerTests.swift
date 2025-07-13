//
//  AsaMusicPlayerTests.swift
//  AsaMusicPlayerTests
//  
//  Created on 2025/07/14
//


import Testing
import Foundation
import UIKit
@testable import AsaMusicPlayer

struct AsaMusicPlayerTests {

    // MARK: - MusicTrack Tests
    
    @Test func musicTrackInitialization() async throws {
        let title = "テスト楽曲"
        let artist = "テストアーティスト"
        let album = "テストアルバム"
        let duration: TimeInterval = 180.5
        let filePath = URL(fileURLWithPath: "/test/path/music.mp3")
        let artwork = UIImage()
        
        let track = MusicTrack(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            filePath: filePath,
            artwork: artwork
        )
        
        #expect(track.title == title)
        #expect(track.artist == artist)
        #expect(track.album == album)
        #expect(track.duration == duration)
        #expect(track.filePath == filePath)
        #expect(track.artwork == artwork)
        #expect(track.dateAdded != nil)
    }
    
    @Test func musicTrackFormattedDuration() async throws {
        let track1 = MusicTrack(
            title: "短い曲",
            artist: "アーティスト",
            duration: 65,
            filePath: URL(fileURLWithPath: "/test/short.mp3")
        )
        
        let track2 = MusicTrack(
            title: "長い曲",
            artist: "アーティスト",
            duration: 3665,
            filePath: URL(fileURLWithPath: "/test/long.mp3")
        )
        
        #expect(track1.formattedDuration == "1:05")
        #expect(track2.formattedDuration == "61:05")
    }
    
    @Test func musicTrackDisplayProperties() async throws {
        let trackWithTitle = MusicTrack(
            title: "実際のタイトル",
            artist: "実際のアーティスト",
            duration: 120,
            filePath: URL(fileURLWithPath: "/test/music.mp3")
        )
        
        let trackWithoutTitle = MusicTrack(
            title: "",
            artist: "",
            duration: 120,
            filePath: URL(fileURLWithPath: "/test/unknown.mp3")
        )
        
        #expect(trackWithTitle.displayTitle == "実際のタイトル")
        #expect(trackWithTitle.displayArtist == "実際のアーティスト")
        
        #expect(trackWithoutTitle.displayTitle == "unknown.mp3")
        #expect(trackWithoutTitle.displayArtist == "不明なアーティスト")
    }
    
    @Test func musicTrackEquality() async throws {
        let track1 = MusicTrack(
            title: "楽曲",
            artist: "アーティスト",
            duration: 120,
            filePath: URL(fileURLWithPath: "/test/music.mp3")
        )
        
        let track2 = MusicTrack(
            title: "楽曲",
            artist: "アーティスト",
            duration: 120,
            filePath: URL(fileURLWithPath: "/test/music.mp3")
        )
        
        #expect(track1 == track1)
        #expect(track1 != track2)
    }
    
    // MARK: - MusicPlayerState Tests
    
    @Test func musicPlayerStateProperties() async throws {
        #expect(MusicPlayerState.stopped.isStopped == true)
        #expect(MusicPlayerState.stopped.isPlaying == false)
        #expect(MusicPlayerState.stopped.isPaused == false)
        #expect(MusicPlayerState.stopped.isLoading == false)
        
        #expect(MusicPlayerState.playing.isPlaying == true)
        #expect(MusicPlayerState.playing.isStopped == false)
        #expect(MusicPlayerState.playing.isPaused == false)
        #expect(MusicPlayerState.playing.isLoading == false)
        
        #expect(MusicPlayerState.paused.isPaused == true)
        #expect(MusicPlayerState.paused.isPlaying == false)
        #expect(MusicPlayerState.paused.isStopped == false)
        #expect(MusicPlayerState.paused.isLoading == false)
        
        #expect(MusicPlayerState.loading.isLoading == true)
        #expect(MusicPlayerState.loading.isPlaying == false)
        #expect(MusicPlayerState.loading.isStopped == false)
        #expect(MusicPlayerState.loading.isPaused == false)
    }
    
    // MARK: - RepeatMode Tests
    
    @Test func repeatModeProperties() async throws {
        #expect(RepeatMode.none.displayName == "リピートなし")
        #expect(RepeatMode.all.displayName == "全曲リピート")
        #expect(RepeatMode.one.displayName == "1曲リピート")
        
        #expect(RepeatMode.none.systemImageName == "repeat")
        #expect(RepeatMode.all.systemImageName == "repeat")
        #expect(RepeatMode.one.systemImageName == "repeat.1")
    }
    
    @Test func repeatModeAllCases() async throws {
        let allCases = RepeatMode.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.none))
        #expect(allCases.contains(.all))
        #expect(allCases.contains(.one))
    }
    
    // MARK: - AudioManager Tests
    
    @Test func audioManagerInitialization() async throws {
        await MainActor.run {
            let audioManager = AudioManager()
            
            #expect(audioManager.currentTrack == nil)
            #expect(audioManager.playerState == .stopped)
            #expect(audioManager.currentTime == 0)
            #expect(audioManager.duration == 0)
            #expect(audioManager.volume == 1.0)
            #expect(audioManager.shuffleEnabled == false)
            #expect(audioManager.repeatMode == .none)
            #expect(audioManager.isPlaying == false)
            #expect(audioManager.progress == 0)
        }
    }
    
    @Test func audioManagerVolumeControl() async throws {
        await MainActor.run {
            let audioManager = AudioManager()
            
            audioManager.volume = 0.5
            #expect(audioManager.volume == 0.5)
            
            audioManager.volume = 0.0
            #expect(audioManager.volume == 0.0)
            
            audioManager.volume = 1.0
            #expect(audioManager.volume == 1.0)
        }
    }
    
    @Test func audioManagerShuffleToggle() async throws {
        await MainActor.run {
            let audioManager = AudioManager()
            
            #expect(audioManager.shuffleEnabled == false)
            
            audioManager.toggleShuffle()
            #expect(audioManager.shuffleEnabled == true)
            
            audioManager.toggleShuffle()
            #expect(audioManager.shuffleEnabled == false)
        }
    }
    
    @Test func audioManagerRepeatModeSettings() async throws {
        await MainActor.run {
            let audioManager = AudioManager()
            
            #expect(audioManager.repeatMode == .none)
            
            audioManager.setRepeatMode(.all)
            #expect(audioManager.repeatMode == .all)
            
            audioManager.setRepeatMode(.one)
            #expect(audioManager.repeatMode == .one)
            
            audioManager.setRepeatMode(.none)
            #expect(audioManager.repeatMode == .none)
        }
    }
    
    @Test func audioManagerProgressCalculation() async throws {
        await MainActor.run {
            let audioManager = AudioManager()
            
            #expect(audioManager.progress == 0)
            
            let testTrack = MusicTrack(
                title: "テスト",
                artist: "テスト",
                duration: 100,
                filePath: URL(fileURLWithPath: "/test/dummy.mp3")
            )
            
            audioManager.loadTrack(testTrack)
        }
    }

    // MARK: - MusicLibraryManager Tests
    
    @Test func musicLibraryManagerInitialization() async throws {
        let libraryManager = MusicLibraryManager()
        
        #expect(libraryManager.musicTracks.isEmpty)
        #expect(libraryManager.isLoading == false)
    }
    
    @Test func musicLibraryManagerSearchTracks() async throws {
        let libraryManager = MusicLibraryManager()
        
        let track1 = MusicTrack(title: "ロック楽曲", artist: "ロックバンド", duration: 180, filePath: URL(fileURLWithPath: "/test1.mp3"))
        let track2 = MusicTrack(title: "ポップソング", artist: "ポップアーティスト", duration: 200, filePath: URL(fileURLWithPath: "/test2.mp3"))
        let track3 = MusicTrack(title: "ジャズナンバー", artist: "ジャズミュージシャン", duration: 250, filePath: URL(fileURLWithPath: "/test3.mp3"))
        
        libraryManager.musicTracks = [track1, track2, track3]
        
        let searchResults1 = libraryManager.searchTracks(query: "ロック")
        #expect(searchResults1.count == 1)
        #expect(searchResults1.first?.title == "ロック楽曲")
        
        let searchResults2 = libraryManager.searchTracks(query: "アーティスト")
        #expect(searchResults2.count == 1)
        #expect(searchResults2.first?.artist == "ポップアーティスト")
        
        let searchResults3 = libraryManager.searchTracks(query: "")
        #expect(searchResults3.count == 3)
        
        let searchResults4 = libraryManager.searchTracks(query: "見つからない")
        #expect(searchResults4.isEmpty)
    }
    
    @Test func musicLibraryManagerRemoveTrack() async throws {
        let libraryManager = MusicLibraryManager()
        
        let track1 = MusicTrack(title: "楽曲1", artist: "アーティスト1", duration: 180, filePath: URL(fileURLWithPath: "/test1.mp3"))
        let track2 = MusicTrack(title: "楽曲2", artist: "アーティスト2", duration: 200, filePath: URL(fileURLWithPath: "/test2.mp3"))
        
        libraryManager.musicTracks = [track1, track2]
        
        #expect(libraryManager.musicTracks.count == 2)
        
        libraryManager.removeTrack(track1)
        #expect(libraryManager.musicTracks.count == 1)
        #expect(libraryManager.musicTracks.first?.title == "楽曲2")
    }

    // MARK: - MusicPlayerViewModel Tests
    
    @Test func musicPlayerViewModelInitialization() async throws {
        await MainActor.run {
            let audioManager = AudioManager()
            let libraryManager = MusicLibraryManager()
            let viewModel = MusicPlayerViewModel(audioManager: audioManager, libraryManager: libraryManager)
            
            #expect(viewModel.currentPlaylist.isEmpty)
            #expect(viewModel.currentTrackIndex == 0)
            #expect(viewModel.searchText.isEmpty)
            #expect(viewModel.showingLibrary == false)
            #expect(viewModel.currentTrack == nil)
            #expect(viewModel.playerState == .stopped)
            #expect(viewModel.volume == 1.0)
            #expect(viewModel.shuffleEnabled == false)
            #expect(viewModel.repeatMode == .none)
        }
    }
    
    @Test func musicPlayerViewModelPlaylistManagement() async throws {
        await MainActor.run {
            let audioManager = AudioManager()
            let libraryManager = MusicLibraryManager()
            let viewModel = MusicPlayerViewModel(audioManager: audioManager, libraryManager: libraryManager)
            
            let track1 = MusicTrack(title: "楽曲1", artist: "アーティスト1", duration: 180, filePath: URL(fileURLWithPath: "/test1.mp3"))
            let track2 = MusicTrack(title: "楽曲2", artist: "アーティスト2", duration: 200, filePath: URL(fileURLWithPath: "/test2.mp3"))
            let track3 = MusicTrack(title: "楽曲3", artist: "アーティスト3", duration: 220, filePath: URL(fileURLWithPath: "/test3.mp3"))
            
            let playlist = [track1, track2, track3]
            viewModel.playPlaylist(playlist, startingAt: 1)
            
            #expect(viewModel.currentPlaylist.count == 3)
            #expect(viewModel.currentTrackIndex == 1)
            #expect(viewModel.currentTrack?.title == "楽曲2")
        }
    }
    
    @Test func musicPlayerViewModelAddToPlaylist() async throws {
        await MainActor.run {
            let audioManager = AudioManager()
            let libraryManager = MusicLibraryManager()
            let viewModel = MusicPlayerViewModel(audioManager: audioManager, libraryManager: libraryManager)
            
            let track1 = MusicTrack(title: "楽曲1", artist: "アーティスト1", duration: 180, filePath: URL(fileURLWithPath: "/test1.mp3"))
            let track2 = MusicTrack(title: "楽曲2", artist: "アーティスト2", duration: 200, filePath: URL(fileURLWithPath: "/test2.mp3"))
            
            #expect(viewModel.currentPlaylist.isEmpty)
            
            viewModel.addToPlaylist(track1)
            #expect(viewModel.currentPlaylist.count == 1)
            #expect(viewModel.currentPlaylist.first?.title == "楽曲1")
            
            viewModel.addToPlaylist(track2)
            #expect(viewModel.currentPlaylist.count == 2)
            
            viewModel.addToPlaylist(track1)
            #expect(viewModel.currentPlaylist.count == 2)
        }
    }
    
    @Test func musicPlayerViewModelRemoveFromPlaylist() async throws {
        await MainActor.run {
            let audioManager = AudioManager()
            let libraryManager = MusicLibraryManager()
            let viewModel = MusicPlayerViewModel(audioManager: audioManager, libraryManager: libraryManager)
            
            let track1 = MusicTrack(title: "楽曲1", artist: "アーティスト1", duration: 180, filePath: URL(fileURLWithPath: "/test1.mp3"))
            let track2 = MusicTrack(title: "楽曲2", artist: "アーティスト2", duration: 200, filePath: URL(fileURLWithPath: "/test2.mp3"))
            let track3 = MusicTrack(title: "楽曲3", artist: "アーティスト3", duration: 220, filePath: URL(fileURLWithPath: "/test3.mp3"))
            
            viewModel.playPlaylist([track1, track2, track3], startingAt: 1)
            #expect(viewModel.currentPlaylist.count == 3)
            #expect(viewModel.currentTrackIndex == 1)
            
            viewModel.removeFromPlaylist(track1)
            #expect(viewModel.currentPlaylist.count == 2)
            #expect(viewModel.currentTrackIndex == 0)
            
            viewModel.removeFromPlaylist(track2)
            #expect(viewModel.currentPlaylist.count == 1)
            #expect(viewModel.currentTrackIndex == 0)
            #expect(viewModel.currentTrack?.title == "楽曲3")
        }
    }
    
    @Test func musicPlayerViewModelClearPlaylist() async throws {
        await MainActor.run {
            let audioManager = AudioManager()
            let libraryManager = MusicLibraryManager()
            let viewModel = MusicPlayerViewModel(audioManager: audioManager, libraryManager: libraryManager)
            
            let track1 = MusicTrack(title: "楽曲1", artist: "アーティスト1", duration: 180, filePath: URL(fileURLWithPath: "/test1.mp3"))
            let track2 = MusicTrack(title: "楽曲2", artist: "アーティスト2", duration: 200, filePath: URL(fileURLWithPath: "/test2.mp3"))
            
            viewModel.playPlaylist([track1, track2])
            #expect(viewModel.currentPlaylist.count == 2)
            
            viewModel.clearPlaylist()
            #expect(viewModel.currentPlaylist.isEmpty)
            #expect(viewModel.currentTrackIndex == 0)
            #expect(viewModel.currentTrack == nil)
        }
    }
    
    @Test func musicPlayerViewModelNavigationState() async throws {
        await MainActor.run {
            let audioManager = AudioManager()
            let libraryManager = MusicLibraryManager()
            let viewModel = MusicPlayerViewModel(audioManager: audioManager, libraryManager: libraryManager)
            
            let track1 = MusicTrack(title: "楽曲1", artist: "アーティスト1", duration: 180, filePath: URL(fileURLWithPath: "/test1.mp3"))
            let track2 = MusicTrack(title: "楽曲2", artist: "アーティスト2", duration: 200, filePath: URL(fileURLWithPath: "/test2.mp3"))
            let track3 = MusicTrack(title: "楽曲3", artist: "アーティスト3", duration: 220, filePath: URL(fileURLWithPath: "/test3.mp3"))
            
            viewModel.playPlaylist([track1, track2, track3], startingAt: 1)
            
            #expect(viewModel.hasNextTrack == true)
            #expect(viewModel.hasPreviousTrack == true)
            
            viewModel.playPlaylist([track1], startingAt: 0)
            viewModel.repeatMode = .none
            
            #expect(viewModel.hasNextTrack == false)
            #expect(viewModel.hasPreviousTrack == false)
            
            viewModel.repeatMode = .all
            #expect(viewModel.hasNextTrack == true)
            #expect(viewModel.hasPreviousTrack == true)
            
            viewModel.repeatMode = .one
            #expect(viewModel.hasNextTrack == true)
            #expect(viewModel.hasPreviousTrack == true)
        }
    }
    
    @Test func musicPlayerViewModelLibraryDisplay() async throws {
        await MainActor.run {
            let audioManager = AudioManager()
            let libraryManager = MusicLibraryManager()
            let viewModel = MusicPlayerViewModel(audioManager: audioManager, libraryManager: libraryManager)
            
            #expect(viewModel.showingLibrary == false)
            
            viewModel.showLibrary()
            #expect(viewModel.showingLibrary == true)
            
            viewModel.hideLibrary()
            #expect(viewModel.showingLibrary == false)
        }
    }

}
