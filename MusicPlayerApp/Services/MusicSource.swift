import Foundation
import Combine

// MARK: - Music Source Protocol (Strategy Pattern)
protocol MusicSource {
    var sourceType: Song.MusicSourceType { get }
    var name: String { get }
    
    // Search and fetch songs
    func searchSongs(query: String) -> AnyPublisher<[Song], Error>
    func fetchSongDetails(id: String) -> AnyPublisher<Song, Error>
    
    // Playback control
    func preparePlayback(for song: Song) -> AnyPublisher<Void, Error>
    func startPlayback() -> AnyPublisher<Void, Error>
    func pausePlayback() -> AnyPublisher<Void, Error>
    func stopPlayback() -> AnyPublisher<Void, Error>
    func seek(to time: TimeInterval) -> AnyPublisher<Void, Error>
    
    // State management
    var currentSong: Song? { get }
    var playbackState: PlaybackState { get }
    var playbackProgress: PlaybackProgress { get }
    
    // Publishers for state changes
    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> { get }
    var playbackProgressPublisher: AnyPublisher<PlaybackProgress, Never> { get }
    var currentSongPublisher: AnyPublisher<Song?, Never> { get }
}

// MARK: - Music Source Factory (Factory Pattern)
class MusicSourceFactory {
    static func createMusicSource(for type: Song.MusicSourceType) -> MusicSource {
        switch type {
        case .local:
            return LocalMusicSource()
        case .spotify:
            return SpotifyMusicSource()
        case .audioDB:
            return AudioDBMusicSource()
        case .discogs:
            return DiscogsMusicSource()
        }
    }
}

// MARK: - AudioDB Music Source
class AudioDBMusicSource: MusicSource {
    let sourceType: Song.MusicSourceType = .audioDB
    let name = "AudioDB"
    
    private let networkService = NetworkService()
    private var currentSongSubject = CurrentValueSubject<Song?, Never>(nil)
    private var playbackStateSubject = CurrentValueSubject<PlaybackState, Never>(.stopped)
    private var playbackProgressSubject = CurrentValueSubject<PlaybackProgress, Never>(PlaybackProgress(currentTime: 0, duration: 0))
    
    var currentSong: Song? { currentSongSubject.value }
    var playbackState: PlaybackState { playbackStateSubject.value }
    var playbackProgress: PlaybackProgress { playbackProgressSubject.value }
    
    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> { playbackStateSubject.eraseToAnyPublisher() }
    var playbackProgressPublisher: AnyPublisher<PlaybackProgress, Never> { playbackProgressSubject.eraseToAnyPublisher() }
    var currentSongPublisher: AnyPublisher<Song?, Never> { currentSongSubject.eraseToAnyPublisher() }
    
    func searchSongs(query: String) -> AnyPublisher<[Song], Error> {
        let url = "https://www.theaudiodb.com/api/v1/json/2/search.php?s=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        return networkService.fetch(url: url)
            .tryMap { data -> [Song] in
                let decoder = JSONDecoder()
                let response = try decoder.decode(AudioDBResponse.self, from: data)
                return response.tracks?.map { track in
                    Song.streaming(
                        id: track.idTrack ?? UUID().uuidString,
                        title: track.strTrack ?? "Unknown",
                        artist: track.strArtist ?? "Unknown",
                        album: track.strAlbum ?? "Unknown",
                        duration: TimeInterval(track.intDuration ?? 0),
                        streamURL: track.strMusicVidUrl,
                        artworkURL: track.strTrackThumb,
                        source: .audioDB
                    )
                } ?? []
            }
            .eraseToAnyPublisher()
    }
    
    func fetchSongDetails(id: String) -> AnyPublisher<Song, Error> {
        let url = "https://www.theaudiodb.com/api/v1/json/2/track.php?h=\(id)"
        
        return networkService.fetch(url: url)
            .tryMap { data -> Song in
                let decoder = JSONDecoder()
                let response = try decoder.decode(AudioDBResponse.self, from: data)
                guard let track = response.tracks?.first else {
                    throw NetworkError.invalidData
                }
                
                return Song.streaming(
                    id: track.idTrack ?? UUID().uuidString,
                    title: track.strTrack ?? "Unknown",
                    artist: track.strArtist ?? "Unknown",
                    album: track.strAlbum ?? "Unknown",
                    duration: TimeInterval(track.intDuration ?? 0),
                    streamURL: track.strMusicVidUrl,
                    artworkURL: track.strTrackThumb,
                    source: .audioDB
                )
            }
            .eraseToAnyPublisher()
    }
    
    func preparePlayback(for song: Song) -> AnyPublisher<Void, Error> {
        currentSongSubject.send(song)
        playbackStateSubject.send(.loading)
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func startPlayback() -> AnyPublisher<Void, Error> {
        playbackStateSubject.send(.playing)
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func pausePlayback() -> AnyPublisher<Void, Error> {
        playbackStateSubject.send(.paused)
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func stopPlayback() -> AnyPublisher<Void, Error> {
        playbackStateSubject.send(.stopped)
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func seek(to time: TimeInterval) -> AnyPublisher<Void, Error> {
        let progress = PlaybackProgress(currentTime: time, duration: currentSong?.duration ?? 0)
        playbackProgressSubject.send(progress)
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - Discogs Music Source
class DiscogsMusicSource: MusicSource {
    let sourceType: Song.MusicSourceType = .discogs
    let name = "Discogs"
    
    private var currentSongSubject = CurrentValueSubject<Song?, Never>(nil)
    private var playbackStateSubject = CurrentValueSubject<PlaybackState, Never>(.stopped)
    private var playbackProgressSubject = CurrentValueSubject<PlaybackProgress, Never>(PlaybackProgress(currentTime: 0, duration: 0))
    
    var currentSong: Song? { currentSongSubject.value }
    var playbackState: PlaybackState { playbackStateSubject.value }
    var playbackProgress: PlaybackProgress { playbackProgressSubject.value }
    
    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> { playbackStateSubject.eraseToAnyPublisher() }
    var playbackProgressPublisher: AnyPublisher<PlaybackProgress, Never> { playbackProgressSubject.eraseToAnyPublisher() }
    var currentSongPublisher: AnyPublisher<Song?, Never> { currentSongSubject.eraseToAnyPublisher() }
    
    func searchSongs(query: String) -> AnyPublisher<[Song], Error> {
        // Mock implementation for Discogs
        let mockSongs = [
            Song.streaming(
                id: "discogs-1",
                title: "Sample Track 1",
                artist: "Sample Artist",
                album: "Sample Album",
                duration: 180,
                streamURL: "https://example.com/sample1.mp3",
                source: .discogs
            ),
            Song.streaming(
                id: "discogs-2",
                title: "Sample Track 2",
                artist: "Sample Artist",
                album: "Sample Album",
                duration: 240,
                streamURL: "https://example.com/sample2.mp3",
                source: .discogs
            )
        ]
        
        return Just(mockSongs)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchSongDetails(id: String) -> AnyPublisher<Song, Error> {
        let song = Song.streaming(
            id: id,
            title: "Sample Track",
            artist: "Sample Artist",
            album: "Sample Album",
            duration: 180,
            streamURL: "https://example.com/sample.mp3",
            source: .discogs
        )
        
        return Just(song)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func preparePlayback(for song: Song) -> AnyPublisher<Void, Error> {
        currentSongSubject.send(song)
        playbackStateSubject.send(.loading)
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func startPlayback() -> AnyPublisher<Void, Error> {
        playbackStateSubject.send(.playing)
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func pausePlayback() -> AnyPublisher<Void, Error> {
        playbackStateSubject.send(.paused)
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func stopPlayback() -> AnyPublisher<Void, Error> {
        playbackStateSubject.send(.stopped)
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func seek(to time: TimeInterval) -> AnyPublisher<Void, Error> {
        let progress = PlaybackProgress(currentTime: time, duration: currentSong?.duration ?? 0)
        playbackProgressSubject.send(progress)
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - AudioDB Response Models
struct AudioDBResponse: Codable {
    let tracks: [AudioDBTrack]?
}

struct AudioDBTrack: Codable {
    let idTrack: String?
    let strTrack: String?
    let strArtist: String?
    let strAlbum: String?
    let intDuration: String?
    let strMusicVidUrl: String?
    let strTrackThumb: String?
}

// MARK: - Network Error
enum NetworkError: Error {
    case invalidURL
    case invalidData
    case networkError(Error)
} 