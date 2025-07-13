//
//  ContentView.swift
//  AsaMusicPlayer
//  
//  Created on 2025/07/14
//


import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MusicPlayerViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Color("AsaSoftCream"), Color("AsaDarkSlate").opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    if let currentTrack = viewModel.currentTrack {
                        currentTrackView(track: currentTrack)
                            .padding()
                    } else {
                        noMusicView
                            .padding()
                    }
                    
                    Spacer()
                    
                    controlsSection
                        .background(
                            Color.white.opacity(0.9)
                                .cornerRadius(20, corners: [.topLeft, .topRight])
                                .shadow(radius: 10)
                        )
                }
            }
        }
        .sheet(isPresented: $viewModel.showingLibrary) {
            MusicLibraryView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadMusicLibrary()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("AsaMusicPlayer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text("朝活パパの音楽プレイヤー")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: viewModel.showLibrary) {
                Image(systemName: "music.note.list")
                    .font(.title2)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .padding(12)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
        }
        .padding()
    }
    
    private func currentTrackView(track: MusicTrack) -> some View {
        VStack(spacing: 20) {
            artworkSection(track: track)
            trackInfoSection(track: track)
        }
    }
    
    private func artworkSection(track: MusicTrack) -> some View {
        Group {
            if let artwork = track.artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 80))
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .frame(width: 200, height: 200)
                    .background(Color("AsaSoftCream"))
            }
        }
        .frame(width: 200, height: 200)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
    
    private func trackInfoSection(track: MusicTrack) -> some View {
        VStack(spacing: 8) {
            Text(track.displayTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color("AsaCoffeeBrown"))
                .multilineTextAlignment(.center)
            
            Text(track.displayArtist)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let album = track.album, !album.isEmpty {
                Text(album)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var noMusicView: some View {
        VStack(spacing: 30) {
            Image(systemName: "music.note")
                .font(.system(size: 100))
                .foregroundColor(Color("AsaMutedSage"))
            
            VStack(spacing: 12) {
                Text("音楽を選択してください")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                
                Text("ライブラリから楽曲を選んで\n音楽を楽しみましょう")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("ライブラリを開く") {
                viewModel.showLibrary()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color("AsaCoffeeBrown"))
            .cornerRadius(25)
            .shadow(radius: 5)
        }
    }
    
    private var controlsSection: some View {
        VStack(spacing: 20) {
            PlayerControlButtonsView(viewModel: viewModel)
            PlayerControlsView(viewModel: viewModel)
        }
        .padding(.horizontal)
        .padding(.bottom, 40)
        .padding(.top, 20)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ContentView()
        .background(Color("AsaSoftCream"))
}
