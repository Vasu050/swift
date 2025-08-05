import Foundation

struct Song: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let artworkURL: String?
    let source: MusicSourceType
    let streamURL: String?
    let localPath: String?
    
    enum MusicSourceType: String, Codable, CaseIterable {
        case local = "local"
        case spotify = "spotify"
        case audioDB = "audioDB"
        case discogs = "discogs"
    }
    
    init(id: String, title: String, artist: String, album: String, duration: TimeInterval, artworkURL: String? = nil, source: MusicSourceType, streamURL: String? = nil, localPath: String? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.artworkURL = artworkURL
        self.source = source
        self.streamURL = streamURL
        self.localPath = localPath
    }
    
    // Convenience initializer for local files
    static func local(id: String, title: String, artist: String, album: String, duration: TimeInterval, localPath: String, artworkURL: String? = nil) -> Song {
        return Song(id: id, title: title, artist: artist, album: album, duration: duration, artworkURL: artworkURL, source: .local, localPath: localPath)
    }
    
    // Convenience initializer for streaming songs
    static func streaming(id: String, title: String, artist: String, album: String, duration: TimeInterval, streamURL: String, artworkURL: String? = nil, source: MusicSourceType) -> Song {
        return Song(id: id, title: title, artist: artist, album: album, duration: duration, artworkURL: artworkURL, source: source, streamURL: streamURL)
    }
}

// MARK: - Playback State
enum PlaybackState {
    case stopped
    case playing
    case paused
    case loading
    case error(String)
}

// MARK: - Playback Progress
struct PlaybackProgress {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let progress: Double // 0.0 to 1.0
    
    init(currentTime: TimeInterval, duration: TimeInterval) {
        self.currentTime = currentTime
        self.duration = duration
        self.progress = duration > 0 ? currentTime / duration : 0.0
    }
} 