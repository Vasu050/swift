import Foundation
import Combine
import SwiftUI

class MusicPlayerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentSong: Song?
    @Published var playbackState: PlaybackState = .stopped
    @Published var playbackProgress: PlaybackProgress = PlaybackProgress(currentTime: 0, duration: 0)
    @Published var playlist: [Song] = []
    @Published var searchResults: [Song] = []
    @Published var selectedMusicSource: Song.MusicSourceType = .local
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let musicPlayerService = MusicPlayerService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var isPlaying: Bool {
        return playbackState == .playing
    }
    
    var isPaused: Bool {
        return playbackState == .paused
    }
    
    var isStopped: Bool {
        return playbackState == .stopped
    }
    
    var isLoading: Bool {
        return playbackState == .loading
    }
    
    var hasError: Bool {
        if case .error = playbackState {
            return true
        }
        return false
    }
    
    var formattedCurrentTime: String {
        return musicPlayerService.formatTime(playbackProgress.currentTime)
    }
    
    var formattedDuration: String {
        return musicPlayerService.formatTime(playbackProgress.duration)
    }
    
    var progressPercentage: Double {
        return playbackProgress.progress
    }
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadPlaylist()
    }
    
    // MARK: - Setup Methods
    private func setupBindings() {
        // Bind to music player service
        musicPlayerService.$currentSong
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentSong, on: self)
            .store(in: &cancellables)
        
        musicPlayerService.$playbackState
            .receive(on: DispatchQueue.main)
            .assign(to: \.playbackState, on: self)
            .store(in: &cancellables)
        
        musicPlayerService.$playbackProgress
            .receive(on: DispatchQueue.main)
            .assign(to: \.playbackProgress, on: self)
            .store(in: &cancellables)
        
        musicPlayerService.$playlist
            .receive(on: DispatchQueue.main)
            .assign(to: \.playlist, on: self)
            .store(in: &cancellables)
        
        // Handle error states
        $playbackState
            .sink { [weak self] state in
                if case .error(let message) = state {
                    self?.errorMessage = message
                } else {
                    self?.errorMessage = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    // Playback Control
    func play() {
        musicPlayerService.play()
    }
    
    func pause() {
        musicPlayerService.pause()
    }
    
    func stop() {
        musicPlayerService.stop()
    }
    
    func next() {
        musicPlayerService.next()
    }
    
    func previous() {
        musicPlayerService.previous()
    }
    
    func seek(to time: TimeInterval) {
        musicPlayerService.seek(to: time)
    }
    
    func seekToPercentage(_ percentage: Double) {
        guard let currentSong = currentSong else { return }
        let time = currentSong.duration * percentage
        seek(to: time)
    }
    
    // Playlist Management
    func addToPlaylist(_ song: Song) {
        musicPlayerService.addToPlaylist(song)
    }
    
    func removeFromPlaylist(at index: Int) {
        musicPlayerService.removeFromPlaylist(at: index)
    }
    
    func moveInPlaylist(from sourceIndex: Int, to destinationIndex: Int) {
        musicPlayerService.moveInPlaylist(from: sourceIndex, to: destinationIndex)
    }
    
    func playSong(_ song: Song) {
        musicPlayerService.playSong(song)
    }
    
    func playSongAtIndex(_ index: Int) {
        guard index >= 0 && index < playlist.count else { return }
        let song = playlist[index]
        playSong(song)
    }
    
    // Search Functionality
    func searchSongs() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        musicPlayerService.searchSongs(query: searchQuery, source: selectedMusicSource)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] songs in
                    self?.searchResults = songs
                }
            )
            .store(in: &cancellables)
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
    
    // Music Source Management
    func switchMusicSource(to source: Song.MusicSourceType) {
        selectedMusicSource = source
        musicPlayerService.switchMusicSource(to: source)
    }
    
    // Playlist Loading
    private func loadPlaylist() {
        // The playlist is already loaded in PlaylistManager
        // This method can be used for additional playlist loading logic
    }
    
    // MARK: - Utility Methods
    
    func formatDuration(_ duration: TimeInterval) -> String {
        return musicPlayerService.formatTime(duration)
    }
    
    func getSourceIcon(for source: Song.MusicSourceType) -> String {
        switch source {
        case .local:
            return "music.note"
        case .spotify:
            return "music.note.list"
        case .audioDB:
            return "music.note"
        case .discogs:
            return "music.note"
        }
    }
    
    func getSourceColor(for source: Song.MusicSourceType) -> Color {
        switch source {
        case .local:
            return .blue
        case .spotify:
            return .green
        case .audioDB:
            return .orange
        case .discogs:
            return .purple
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - State Management
    
    func togglePlayPause() {
        switch playbackState {
        case .playing:
            pause()
        case .paused, .stopped:
            play()
        case .loading:
            // Do nothing while loading
            break
        case .error:
            // Try to play again
            play()
        }
    }
    
    // MARK: - Playlist Statistics
    
    var playlistDuration: TimeInterval {
        return playlist.reduce(0) { $0 + $1.duration }
    }
    
    var formattedPlaylistDuration: String {
        return musicPlayerService.formatTime(playlistDuration)
    }
    
    var playlistSongCount: Int {
        return playlist.count
    }
} 