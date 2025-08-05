import Foundation
import Combine
import AVFoundation

class LocalMusicSource: MusicSource {
    let sourceType: Song.MusicSourceType = .local
    let name = "Local Files"
    
    private var currentSongSubject = CurrentValueSubject<Song?, Never>(nil)
    private var playbackStateSubject = CurrentValueSubject<PlaybackState, Never>(.stopped)
    private var playbackProgressSubject = CurrentValueSubject<PlaybackProgress, Never>(PlaybackProgress(currentTime: 0, duration: 0))
    
    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    
    var currentSong: Song? { currentSongSubject.value }
    var playbackState: PlaybackState { playbackStateSubject.value }
    var playbackProgress: PlaybackProgress { playbackProgressSubject.value }
    
    var playbackStatePublisher: AnyPublisher<PlaybackState, Never> { playbackStateSubject.eraseToAnyPublisher() }
    var playbackProgressPublisher: AnyPublisher<PlaybackProgress, Never> { playbackProgressSubject.eraseToAnyPublisher() }
    var currentSongPublisher: AnyPublisher<Song?, Never> { currentSongSubject.eraseToAnyPublisher() }
    
    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func searchSongs(query: String) -> AnyPublisher<[Song], Error> {
        // Mock local songs for demonstration
        let mockLocalSongs = [
            Song.local(
                id: "local-1",
                title: "Local Song 1",
                artist: "Local Artist",
                album: "Local Album",
                duration: 180,
                localPath: "/path/to/local/song1.mp3"
            ),
            Song.local(
                id: "local-2",
                title: "Local Song 2",
                artist: "Local Artist",
                album: "Local Album",
                duration: 240,
                localPath: "/path/to/local/song2.mp3"
            )
        ]
        
        let filteredSongs = mockLocalSongs.filter { song in
            song.title.localizedCaseInsensitiveContains(query) ||
            song.artist.localizedCaseInsensitiveContains(query) ||
            song.album.localizedCaseInsensitiveContains(query)
        }
        
        return Just(filteredSongs)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchSongDetails(id: String) -> AnyPublisher<Song, Error> {
        // Mock implementation - in real app, this would fetch from local database
        let song = Song.local(
            id: id,
            title: "Local Song",
            artist: "Local Artist",
            album: "Local Album",
            duration: 180,
            localPath: "/path/to/local/song.mp3"
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
            
            // In a real app, you would load the actual file
            // For now, we'll simulate loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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