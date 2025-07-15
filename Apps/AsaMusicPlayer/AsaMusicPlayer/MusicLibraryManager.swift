import Foundation
import AVFoundation
import UIKit

class MusicLibraryManager: ObservableObject {
    @Published var musicTracks: [MusicTrack] = []
    @Published var isLoading: Bool = false
    
    private let supportedFileTypes = ["mp3", "m4a", "wav", "aac", "flac"]
    
    func loadMusicLibrary() {
        isLoading = true
        musicTracks.removeAll()
        
        Task {
            await searchForMusicFiles()
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    private func searchForMusicFiles() async {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let musicPath = documentsPath.appendingPathComponent("Music")
        
        if !fileManager.fileExists(atPath: musicPath.path) {
            do {
                try fileManager.createDirectory(at: musicPath, withIntermediateDirectories: true)
                print("Musicディレクトリを作成しました: \(musicPath.path)")
            } catch {
                print("Musicディレクトリの作成に失敗: \(error)")
            }
        }
        
        await scanDirectory(musicPath)
        
        let bundleMusicFiles = await scanBundleForMusic()
        
        DispatchQueue.main.async {
            self.musicTracks.append(contentsOf: bundleMusicFiles)
            self.musicTracks.sort { $0.title < $1.title }
        }
    }
    
    private func scanDirectory(_ directory: URL) async {
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            
            for file in files {
                if file.hasDirectoryPath {
                    await scanDirectory(file)
                } else if supportedFileTypes.contains(file.pathExtension.lowercased()) {
                    if let track = await createMusicTrack(from: file) {
                        DispatchQueue.main.async {
                            self.musicTracks.append(track)
                        }
                    }
                }
            }
        } catch {
            print("ディレクトリのスキャンに失敗: \(error)")
        }
    }
    
    private func scanBundleForMusic() async -> [MusicTrack] {
        guard let resourcePath = Bundle.main.resourcePath else { return [] }
        let resourceURL = URL(fileURLWithPath: resourcePath)
        let fileManager = FileManager.default
        var bundleTracks: [MusicTrack] = []
        
        do {
            let files = try fileManager.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil)
            
            for file in files {
                if supportedFileTypes.contains(file.pathExtension.lowercased()) {
                    if let track = await createMusicTrack(from: file) {
                        bundleTracks.append(track)
                    }
                }
            }
        } catch {
            print("バンドルのスキャンに失敗: \(error)")
        }
        
        return bundleTracks
    }
    
    private func createMusicTrack(from url: URL) async -> MusicTrack? {
        let asset = AVURLAsset(url: url)
        
        do {
            let duration = try await asset.load(.duration).seconds
            let metadata = try await asset.load(.metadata)
            
            var title = url.deletingPathExtension().lastPathComponent
            var artist = "不明なアーティスト"
            var album: String? = nil
            var artwork: UIImage? = nil
            
            for item in metadata {
                guard let key = item.commonKey?.rawValue,
                      let value = try? await item.load(.stringValue) else { continue }
                
                switch key {
                case "title":
                    title = value
                case "artist":
                    artist = value
                case "albumName":
                    album = value
                default:
                    break
                }
            }
            
            for item in metadata {
                if let artworkData = try? await item.load(.dataValue),
                   let image = UIImage(data: artworkData) {
                    artwork = image
                    break
                }
            }
            
            return MusicTrack(
                title: title,
                artist: artist,
                album: album,
                duration: duration.isFinite ? duration : 0,
                filePath: url,
                artwork: artwork
            )
        } catch {
            print("メタデータの読み込みに失敗: \(error)")
            return MusicTrack(
                title: url.deletingPathExtension().lastPathComponent,
                artist: "不明なアーティスト",
                duration: 0,
                filePath: url
            )
        }
    }
    
    
    func addMusicFile(from url: URL) async {
        guard supportedFileTypes.contains(url.pathExtension.lowercased()) else {
            print("サポートされていないファイル形式: \(url.pathExtension)")
            return
        }
        
        if let track = await createMusicTrack(from: url) {
            DispatchQueue.main.async {
                self.musicTracks.append(track)
                self.musicTracks.sort { $0.title < $1.title }
            }
        }
    }
    
    func searchTracks(query: String) -> [MusicTrack] {
        guard !query.isEmpty else { return musicTracks }
        
        return musicTracks.filter { track in
            track.title.localizedCaseInsensitiveContains(query) ||
            track.artist.localizedCaseInsensitiveContains(query) ||
            track.album?.localizedCaseInsensitiveContains(query) == true
        }
    }
    
    func removeTrack(_ track: MusicTrack) {
        musicTracks.removeAll { $0.id == track.id }
    }
}