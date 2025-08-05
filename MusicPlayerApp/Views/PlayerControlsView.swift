import SwiftUI

struct PlayerControlsView: View {
    @ObservedObject var viewModel: MusicPlayerViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Current Song Info
            currentSongView
            
            // Progress Bar
            progressView
            
            // Playback Controls
            playbackControlsView
            
            // Time Labels
            timeLabelsView
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
    
    // MARK: - Current Song View
    private var currentSongView: some View {
        VStack(spacing: 8) {
            // Album Artwork Placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                )
            
            // Song Info
            VStack(spacing: 4) {
                Text(viewModel.currentSong?.title ?? "No Song Playing")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(viewModel.currentSong?.artist ?? "Unknown Artist")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(viewModel.currentSong?.album ?? "Unknown Album")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Progress View
    private var progressView: some View {
        VStack(spacing: 8) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Progress
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * viewModel.progressPercentage, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
            
            // Progress Slider
            Slider(
                value: Binding(
                    get: { viewModel.progressPercentage },
                    set: { viewModel.seekToPercentage($0) }
                ),
                in: 0...1
            )
            .accentColor(.blue)
        }
    }
    
    // MARK: - Playback Controls
    private var playbackControlsView: some View {
        HStack(spacing: 40) {
            // Previous Button
            Button(action: {
                viewModel.previous()
            }) {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            .disabled(viewModel.playlist.isEmpty)
            
            // Play/Pause Button
            Button(action: {
                viewModel.togglePlayPause()
            }) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }
            .disabled(viewModel.currentSong == nil)
            
            // Next Button
            Button(action: {
                viewModel.next()
            }) {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            .disabled(viewModel.playlist.isEmpty)
        }
    }
    
    // MARK: - Time Labels
    private var timeLabelsView: some View {
        HStack {
            Text(viewModel.formattedCurrentTime)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(viewModel.formattedDuration)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Playback State Indicator
struct PlaybackStateIndicator: View {
    let state: PlaybackState
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundColor(iconColor)
            
            Text(stateText)
                .font(.caption)
                .foregroundColor(iconColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .cornerRadius(8)
    }
    
    private var iconName: String {
        switch state {
        case .playing:
            return "play.fill"
        case .paused:
            return "pause.fill"
        case .stopped:
            return "stop.fill"
        case .loading:
            return "clock"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var stateText: String {
        switch state {
        case .playing:
            return "Playing"
        case .paused:
            return "Paused"
        case .stopped:
            return "Stopped"
        case .loading:
            return "Loading"
        case .error(let message):
            return "Error"
        }
    }
    
    private var iconColor: Color {
        switch state {
        case .playing:
            return .green
        case .paused:
            return .orange
        case .stopped:
            return .gray
        case .loading:
            return .blue
        case .error:
            return .red
        }
    }
    
    private var backgroundColor: Color {
        switch state {
        case .playing:
            return .green.opacity(0.2)
        case .paused:
            return .orange.opacity(0.2)
        case .stopped:
            return .gray.opacity(0.2)
        case .loading:
            return .blue.opacity(0.2)
        case .error:
            return .red.opacity(0.2)
        }
    }
}

// MARK: - Preview
struct PlayerControlsView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerControlsView(viewModel: MusicPlayerViewModel())
            .previewLayout(.sizeThatFits)
            .padding()
    }
} 