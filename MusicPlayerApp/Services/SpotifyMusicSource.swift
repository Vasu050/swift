import Foundation
import Combine

class SpotifyMusicSource: MusicSource {
    let sourceType: Song.MusicSourceType = .spotify
    let name = "Spotify"
    
    private var currentSongSubject = CurrentValueSubject<Song?, Never>(nil)
    private var playbackStateSubject = CurrentValueSubject<PlaybackState, Never>(.stopped)
    private var playbackProgressSubject = CurrentValueSubject<PlaybackProgress, Never>(PlaybackProgress(currentTime: 0, duration: 0))
    
    private var progressTimer: Timer?
    
    var currentSong: Song? { currentSongSubject.value }
    var playbackState: PlaybackState { playbackStateSubject.value }
    var playbackProgress: PlaybackProgress { playbackProgressSubject.value }
    
    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> { playbackStateSubject.eraseToAnyPublisher() }
    var playbackProgressPublisher: AnyPublisher<PlaybackProgress, Never> { playbackProgressSubject.eraseToAnyPublisher() }
    var currentSongPublisher: AnyPublisher<Song?, Never> { currentSongSubject.eraseToAnyPublisher() }
    
    func searchSongs(query: String) -> AnyPublisher<[Song], Error> {
        // Mock Spotify search results
        let mockSpotifySongs = [
            Song.streaming(
                id: "spotify-1",
                title: "Spotify Song 1",
                artist: "Spotify Artist",
                album: "Spotify Album",
                duration: 200,
                streamURL: "https://open.spotify.com/track/spotify-1",
                artworkURL: "https://example.com/spotify-artwork1.jpg",
                source: .spotify
            ),
            Song.streaming(
                id: "spotify-2",
                title: "Spotify Song 2",
                artist: "Spotify Artist",
                album: "Spotify Album",
                duration: 180,
                streamURL: "https://open.spotify.com/track/spotify-2",
                artworkURL: "https://example.com/spotify-artwork2.jpg",
                source: .spotify
            ),
            Song.streaming(
                id: "spotify-3",
                title: "Popular Track",
                artist: "Famous Artist",
                album: "Hit Album",
                duration: 220,
                streamURL: "https://open.spotify.com/track/spotify-3",
                artworkURL: "https://example.com/spotify-artwork3.jpg",
                source: .spotify
            )
        ]
        
        let filteredSongs = mockSpotifySongs.filter { song in
            song.title.localizedCaseInsensitiveContains(query) ||
            song.artist.localizedCaseInsensitiveContains(query) ||
            song.album.localizedCaseInsensitiveContains(query)
        }
        
        return Just(filteredSongs)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchSongDetails(id: String) -> AnyPublisher<Song, Error> {
        // Mock Spotify track details
        let song = Song.streaming(
            id: id,
            title: "Spotify Track",
            artist: "Spotify Artist",
            album: "Spotify Album",
            duration: 180,
            streamURL: "https://open.spotify.com/track/\(id)",
            artworkURL: "https://example.com/spotify-artwork.jpg",
            source: .spotify
        )
        
        return Just(song)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func preparePlayback(for song: Song) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NetworkError.invalidData))
                return
            }
            
            // Simulate Spotify API call to prepare playback
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.currentSongSubject.send(song)
                self.playbackStateSubject.send(.loading)
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func startPlayback() -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NetworkError.invalidData))
                return
            }
            
            self.playbackStateSubject.send(.playing)
            self.startProgressTimer()
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }
    
    func pausePlayback() -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NetworkError.invalidData))
                return
            }
            
            self.playbackStateSubject.send(.paused)
            self.stopProgressTimer()
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }
    
    func stopPlayback() -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NetworkError.invalidData))
                return
            }
            
            self.playbackStateSubject.send(.stopped)
            self.stopProgressTimer()
            self.resetProgress()
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }
    
    func seek(to time: TimeInterval) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NetworkError.invalidData))
                return
            }
            
            let progress = PlaybackProgress(currentTime: time, duration: self.currentSong?.duration ?? 0)
            self.playbackProgressSubject.send(progress)
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }
    
    private func startProgressTimer() {
        stopProgressTimer()
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self,
                  let currentSong = self.currentSong,
                  self.playbackState == .playing else { return }
            
            let currentTime = self.playbackProgress.currentTime + 1.0
            let progress = PlaybackProgress(currentTime: currentTime, duration: currentSong.duration)
            self.playbackProgressSubject.send(progress)
            
            // Auto-stop when song ends
            if currentTime >= currentSong.duration {
                self.stopPlayback()
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &self.cancellables)
            }
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func resetProgress() {
        let progress = PlaybackProgress(currentTime: 0, duration: currentSong?.duration ?? 0)
        playbackProgressSubject.send(progress)
    }
    
    private var cancellables = Set<AnyCancellable>()
} 