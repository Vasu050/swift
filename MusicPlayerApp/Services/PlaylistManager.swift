import Foundation
import Combine

class PlaylistManager: ObservableObject {
    @Published var playlist: [Song] = []
    @Published var currentIndex: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load sample playlist
        loadSamplePlaylist()
    }
    
    // MARK: - Playlist Management
    
    func addSong(_ song: Song) {
        playlist.append(song)
    }
    
    func addSongs(_ songs: [Song]) {
        playlist.append(contentsOf: songs)
    }
    
    func removeSong(at index: Int) {
        guard index >= 0 && index < playlist.count else { return }
        
        playlist.remove(at: index)
        
        // Adjust current index if necessary
        if index <= currentIndex && currentIndex > 0 {
            currentIndex -= 1
        }
    }
    
    func moveSong(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex >= 0 && sourceIndex < playlist.count,
              destinationIndex >= 0 && destinationIndex < playlist.count else { return }
        
        let song = playlist.remove(at: sourceIndex)
        playlist.insert(song, at: destinationIndex)
        
        // Adjust current index if necessary
        if sourceIndex == currentIndex {
            currentIndex = destinationIndex
        } else if sourceIndex < currentIndex && destinationIndex >= currentIndex {
            currentIndex -= 1
        } else if sourceIndex > currentIndex && destinationIndex <= currentIndex {
            currentIndex += 1
        }
    }
    
    func clearPlaylist() {
        playlist.removeAll()
        currentIndex = 0
    }
    
    // MARK: - Playback Navigation
    
    func nextSong() -> Song? {
        guard !playlist.isEmpty else { return nil }
        
        currentIndex = (currentIndex + 1) % playlist.count
        return currentSong
    }
    
    func previousSong() -> Song? {
        guard !playlist.isEmpty else { return nil }
        
        currentIndex = currentIndex == 0 ? playlist.count - 1 : currentIndex - 1
        return currentSong
    }
    
    func setCurrentSong(_ song: Song) {
        if let index = playlist.firstIndex(where: { $0.id == song.id }) {
            currentIndex = index
        }
    }
    
    var currentSong: Song? {
        guard !playlist.isEmpty && currentIndex >= 0 && currentIndex < playlist.count else { return nil }
        return playlist[currentIndex]
    }
    
    var hasNextSong: Bool {
        return !playlist.isEmpty
    }
    
    var hasPreviousSong: Bool {
        return !playlist.isEmpty
    }
    
    // MARK: - Playlist Persistence
    
    func savePlaylist() {
        // In a real app, you would save to UserDefaults or Core Data
        print("Playlist saved with \(playlist.count) songs")
    }
    
    func loadPlaylist() {
        // In a real app, you would load from UserDefaults or Core Data
        loadSamplePlaylist()
    }
    
    private func loadSamplePlaylist() {
        playlist = [
            Song.streaming(
                id: "sample-1",
                title: "Bohemian Rhapsody",
                artist: "Queen",
                album: "A Night at the Opera",
                duration: 354,
                streamURL: "https://example.com/bohemian.mp3",
                source: .spotify
            ),
            Song.streaming(
                id: "sample-2",
                title: "Hotel California",
                artist: "Eagles",
                album: "Hotel California",
                duration: 391,
                streamURL: "https://example.com/hotel.mp3",
                source: .spotify
            ),
            Song.streaming(
                id: "sample-3",
                title: "Stairway to Heaven",
                artist: "Led Zeppelin",
                album: "Led Zeppelin IV",
                duration: 482,
                streamURL: "https://example.com/stairway.mp3",
                source: .spotify
            ),
            Song.local(
                id: "local-1",
                title: "Local Song 1",
                artist: "Local Artist",
                album: "Local Album",
                duration: 180,
                localPath: "/path/to/local/song1.mp3"
            ),
            Song.streaming(
                id: "audiodb-1",
                title: "AudioDB Track",
                artist: "AudioDB Artist",
                album: "AudioDB Album",
                duration: 200,
                streamURL: "https://example.com/audiodb.mp3",
                source: .audioDB
            )
        ]
        currentIndex = 0
    }
    
    // MARK: - Playlist Statistics
    
    var totalDuration: TimeInterval {
        return playlist.reduce(0) { $0 + $1.duration }
    }
    
    var formattedTotalDuration: String {
        let totalSeconds = Int(totalDuration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var songCount: Int {
        return playlist.count
    }
} 