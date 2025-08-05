import Foundation
import Combine
import AVFoundation

// MARK: - Music Player Service (Singleton Pattern)
class MusicPlayerService: ObservableObject {
    static let shared = MusicPlayerService()
    
    // MARK: - Published Properties
    @Published var currentSong: Song?
    @Published var playbackState: PlaybackState = .stopped
    @Published var playbackProgress: PlaybackProgress = PlaybackProgress(currentTime: 0, duration: 0)
    @Published var currentMusicSource: MusicSource?
    @Published var availableSources: [MusicSource] = []
    
    // MARK: - Private Properties
    private var musicSources: [Song.MusicSourceType: MusicSource] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let audioSessionManager = AudioSessionManager.shared
    private let playlistManager = PlaylistManager()
    
    // MARK: - Initialization
    private init() {
        setupMusicSources()
        setupAudioSession()
        setupNotifications()
        observePlaylistChanges()
    }
    
    // MARK: - Setup Methods
    
    private func setupMusicSources() {
        // Initialize all music sources
        let localSource = LocalMusicSource()
        let spotifySource = SpotifyMusicSource()
        let audioDBSource = AudioDBMusicSource()
        let discogsSource = DiscogsMusicSource()
        
        musicSources[.local] = localSource
        musicSources[.spotify] = spotifySource
        musicSources[.audioDB] = audioDBSource
        musicSources[.discogs] = discogsSource
        
        availableSources = [localSource, spotifySource, audioDBSource, discogsSource]
        currentMusicSource = localSource // Default to local source
    }
    
    private func setupAudioSession() {
        audioSessionManager.configureAudioSession()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: .audioSessionInterrupted,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionResume),
            name: .audioSessionResumed,
            object: nil
        )
    }
    
    private func observePlaylistChanges() {
        playlistManager.$currentSong
            .compactMap { $0 }
            .sink { [weak self] song in
                self?.playSong(song)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Interface
    
    func playSong(_ song: Song) {
        guard let musicSource = musicSources[song.source] else {
            print("Music source not found for: \(song.source)")
            return
        }
        
        currentMusicSource = musicSource
        currentSong = song
        
        musicSource.preparePlayback(for: song)
            .flatMap { _ in musicSource.startPlayback() }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Playback error: \(error)")
                        self.playbackState = .error(error.localizedDescription)
                    }
                },
                receiveValue: { _ in
                    print("Started playing: \(song.title)")
                }
            )
            .store(in: &cancellables)
        
        // Observe state changes from the music source
        observeMusicSourceState(musicSource)
    }
    
    func play() {
        guard let musicSource = currentMusicSource else { return }
        
        musicSource.startPlayback()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Play error: \(error)")
                        self.playbackState = .error(error.localizedDescription)
                    }
                },
                receiveValue: { _ in
                    print("Playback resumed")
                }
            )
            .store(in: &cancellables)
    }
    
    func pause() {
        guard let musicSource = currentMusicSource else { return }
        
        musicSource.pausePlayback()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Pause error: \(error)")
                        self.playbackState = .error(error.localizedDescription)
                    }
                },
                receiveValue: { _ in
                    print("Playback paused")
                }
            )
            .store(in: &cancellables)
    }
    
    func stop() {
        guard let musicSource = currentMusicSource else { return }
        
        musicSource.stopPlayback()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Stop error: \(error)")
                        self.playbackState = .error(error.localizedDescription)
                    }
                },
                receiveValue: { _ in
                    print("Playback stopped")
                }
            )
            .store(in: &cancellables)
    }
    
    func next() {
        if let nextSong = playlistManager.nextSong() {
            playSong(nextSong)
        }
    }
    
    func previous() {
        if let previousSong = playlistManager.previousSong() {
            playSong(previousSong)
        }
    }
    
    func seek(to time: TimeInterval) {
        guard let musicSource = currentMusicSource else { return }
        
        musicSource.seek(to: time)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Seek error: \(error)")
                    }
                },
                receiveValue: { _ in
                    print("Seeked to: \(time)")
                }
            )
            .store(in: &cancellables)
    }
    
    func searchSongs(query: String, source: Song.MusicSourceType) -> AnyPublisher<[Song], Error> {
        guard let musicSource = musicSources[source] else {
            return Fail(error: NetworkError.invalidData)
                .eraseToAnyPublisher()
        }
        
        return musicSource.searchSongs(query: query)
    }
    
    // MARK: - Playlist Management
    
    func addToPlaylist(_ song: Song) {
        playlistManager.addSong(song)
    }
    
    func removeFromPlaylist(at index: Int) {
        playlistManager.removeSong(at: index)
    }
    
    func moveInPlaylist(from sourceIndex: Int, to destinationIndex: Int) {
        playlistManager.moveSong(from: sourceIndex, to: destinationIndex)
    }
    
    var playlist: [Song] {
        return playlistManager.playlist
    }
    
    var currentPlaylistIndex: Int {
        return playlistManager.currentIndex
    }
    
    // MARK: - Private Methods
    
    private func observeMusicSourceState(_ musicSource: MusicSource) {
        // Observe playback state changes
        musicSource.playbackStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.playbackState = state
            }
            .store(in: &cancellables)
        
        // Observe playback progress changes
        musicSource.playbackProgressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.playbackProgress = progress
            }
            .store(in: &cancellables)
        
        // Observe current song changes
        musicSource.currentSongPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] song in
                self?.currentSong = song
            }
            .store(in: &cancellables)
    }
    
    @objc private func handleAudioSessionInterruption() {
        pause()
    }
    
    @objc private func handleAudioSessionResume() {
        play()
    }
    
    // MARK: - Utility Methods
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func getMusicSource(for type: Song.MusicSourceType) -> MusicSource? {
        return musicSources[type]
    }
    
    func switchMusicSource(to type: Song.MusicSourceType) {
        guard let musicSource = musicSources[type] else { return }
        currentMusicSource = musicSource
    }
} 