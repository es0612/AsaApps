import SwiftUI

struct PlayerControlsView: View {
    @ObservedObject var viewModel: MusicPlayerViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            progressView
            controlButtonsView
            volumeControlView
        }
        .padding()
    }
    
    private var progressView: some View {
        VStack(spacing: 8) {
            ProgressView(value: viewModel.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color("AsaCoffeeBrown")))
                .scaleEffect(y: 2.0)
            
            HStack {
                Text(formatTime(viewModel.currentTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatTime(viewModel.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var controlButtonsView: some View {
        HStack(spacing: 40) {
            Button(action: viewModel.previousTrack) {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundColor(viewModel.hasPreviousTrack ? Color("AsaCoffeeBrown") : .gray)
            }
            .disabled(!viewModel.hasPreviousTrack)
            
            Button(action: viewModel.seekBackward) {
                Image(systemName: "gobackward.15")
                    .font(.title3)
                    .foregroundColor(Color("AsaMutedSage"))
            }
            
            Button(action: viewModel.togglePlayPause) {
                Image(systemName: playPauseIcon)
                    .font(.largeTitle)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .scaleEffect(1.2)
            }
            .disabled(viewModel.currentTrack == nil)
            
            Button(action: viewModel.seekForward) {
                Image(systemName: "goforward.15")
                    .font(.title3)
                    .foregroundColor(Color("AsaMutedSage"))
            }
            
            Button(action: viewModel.nextTrack) {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundColor(viewModel.hasNextTrack ? Color("AsaCoffeeBrown") : .gray)
            }
            .disabled(!viewModel.hasNextTrack)
        }
    }
    
    private var volumeControlView: some View {
        HStack {
            Image(systemName: "speaker.fill")
                .foregroundColor(.secondary)
            
            Slider(value: Binding(
                get: { viewModel.volume },
                set: { viewModel.volume = $0 }
            ), in: 0...1)
            .accentColor(Color("AsaCoffeeBrown"))
            
            Image(systemName: "speaker.wave.3.fill")
                .foregroundColor(.secondary)
        }
    }
    
    private var playPauseIcon: String {
        switch viewModel.playerState {
        case .playing:
            return "pause.fill"
        case .loading:
            return "hourglass"
        default:
            return "play.fill"
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct PlayerControlButtonsView: View {
    @ObservedObject var viewModel: MusicPlayerViewModel
    
    var body: some View {
        HStack(spacing: 30) {
            shuffleButton
            repeatButton
        }
        .padding(.horizontal)
    }
    
    private var shuffleButton: some View {
        Button(action: viewModel.toggleShuffle) {
            Image(systemName: "shuffle")
                .font(.title3)
                .foregroundColor(viewModel.shuffleEnabled ? Color("AsaCoffeeBrown") : Color("AsaMutedSage"))
                .scaleEffect(viewModel.shuffleEnabled ? 1.1 : 1.0)
        }
    }
    
    private var repeatButton: some View {
        Button(action: cycleRepeatMode) {
            Image(systemName: viewModel.repeatMode.systemImageName)
                .font(.title3)
                .foregroundColor(viewModel.repeatMode == .none ? Color("AsaMutedSage") : Color("AsaCoffeeBrown"))
                .scaleEffect(viewModel.repeatMode != .none ? 1.1 : 1.0)
        }
    }
    
    private func cycleRepeatMode() {
        switch viewModel.repeatMode {
        case .none:
            viewModel.setRepeatMode(.all)
        case .all:
            viewModel.setRepeatMode(.one)
        case .one:
            viewModel.setRepeatMode(.none)
        }
    }
}

#Preview {
    @StateObject var viewModel = MusicPlayerViewModel()
    
    return VStack {
        PlayerControlsView(viewModel: viewModel)
        
        Divider().padding()
        
        PlayerControlButtonsView(viewModel: viewModel)
    }
    .padding()
    .background(Color("AsaSoftCream"))
}