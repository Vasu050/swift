# iOS Music Player App

A comprehensive iOS music player application built with Swift and SwiftUI that demonstrates core design patterns and modern iOS development practices.

## Features

### 🎵 Multiple Music Sources
- **Local Files**: Play music from device storage
- **Spotify (Mocked)**: Simulated Spotify integration
- **AudioDB**: Integration with TheAudioDB.com API
- **Discogs**: Integration with Discogs.com API

### 🎛️ Playback Controls
- Play, pause, skip, and previous functionality
- Real-time progress tracking
- Seek functionality with progress bar
- Playlist queue management

### 📱 Modern UI
- SwiftUI-based interface
- Tab-based navigation
- Beautiful animations and transitions
- Responsive design for all iOS devices

### 🔄 State Management
- MVVM architecture with Combine
- Reactive data flow
- Real-time state notifications
- Proper audio session management

## Architecture

### Design Patterns Implemented

#### 1. **Strategy Pattern**
- `MusicSource` protocol provides a unified interface
- Different music sources (Local, Spotify, AudioDB, Discogs) implement the same interface
- Easy to add new music sources without modifying existing code

#### 2. **Factory Pattern**
- `MusicSourceFactory` creates appropriate music source instances
- Centralized creation logic
- Easy to extend with new source types

#### 3. **Singleton Pattern**
- `MusicPlayerService` ensures single player instance
- `AudioSessionManager` manages audio session globally
- Prevents resource conflicts and ensures proper state management

### MVVM + Combine Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│      Views      │◄──►│   ViewModels     │◄──►│     Services     │
│                 │    │                  │    │                 │
│ • PlaylistView  │    │ • MusicPlayer    │    │ • MusicPlayer   │
│ • PlayerControls│    │   ViewModel      │    │   Service       │
│ • ContentView   │    │                  │    │ • AudioSession  │
└─────────────────┘    └──────────────────┘    │   Manager       │
                                               │ • Playlist      │
                                               │   Manager       │
                                               │ • MusicSource   │
                                               │   Factory       │
                                               └─────────────────┘
```

## Project Structure

```
MusicPlayerApp/
├── Models/
│   └── Song.swift                 # Song data model
├── Services/
│   ├── MusicSource.swift          # Strategy pattern implementation
│   ├── LocalMusicSource.swift     # Local file music source
│   ├── SpotifyMusicSource.swift   # Spotify (mocked) music source
│   ├── AudioSessionManager.swift  # Audio session management
│   ├── PlaylistManager.swift      # Playlist queue management
│   ├── MusicPlayerService.swift   # Main player service
│   └── NetworkService.swift       # Network requests
├── ViewModels/
│   └── MusicPlayerViewModel.swift # MVVM view model
├── Views/
│   ├── ContentView.swift          # Main app view
│   ├── PlaylistView.swift         # Playlist management
│   └── PlayerControlsView.swift   # Player controls
├── AppDelegate.swift
└── SceneDelegate.swift
```

## Key Components

### MusicSource Protocol (Strategy Pattern)
```swift
protocol MusicSource {
    var sourceType: MusicSourceType { get }
    var name: String { get }
    
    func searchSongs(query: String) -> AnyPublisher<[Song], Error>
    func fetchSongDetails(song: Song) -> AnyPublisher<Song, Error>
    func preparePlayback(song: Song) -> AnyPublisher<Void, Error>
    func startPlayback() -> AnyPublisher<Void, Error>
    func pausePlayback() -> AnyPublisher<Void, Error>
    func stopPlayback() -> AnyPublisher<Void, Error>
    func seek(to time: TimeInterval) -> AnyPublisher<Void, Error>
}
```

### MusicPlayerService (Singleton)
- Central coordination point for all music operations
- Manages multiple music sources
- Handles audio session and interruptions
- Coordinates with PlaylistManager

### AudioSessionManager (Singleton)
- Configures and manages AVAudioSession
- Handles audio interruptions
- Ensures proper audio routing

## Usage

### Basic Playback
1. Open the app
2. Select a music source (Local, Spotify, AudioDB, Discogs)
3. Search for songs or browse the playlist
4. Tap on a song to play it
5. Use the player controls to manage playback

### Playlist Management
- Add songs to playlist from search results
- Reorder songs by dragging
- Remove songs from playlist
- Navigate through playlist with next/previous buttons

### Music Source Switching
- Tap on different source buttons to switch between music sources
- Each source provides different search results and playback methods
- Seamless switching without interrupting current playback

## Technical Highlights

### Combine Integration
- Reactive data flow throughout the app
- Publishers and subscribers for state management
- Error handling with Combine operators
- Real-time UI updates

### SwiftUI Features
- Modern declarative UI
- State management with @StateObject and @ObservedObject
- Custom view modifiers and extensions
- Responsive design with adaptive layouts

### Audio Session Management
- Proper audio session configuration
- Interruption handling
- Background audio support
- Multiple audio source coordination

## API Integration

### TheAudioDB.com
- Search for songs and artists
- Fetch detailed song information
- Album artwork and metadata

### Discogs.com
- Music database integration
- Artist and album information
- Release details and track listings

## Requirements

- iOS 14.0+
- Xcode 12.0+
- Swift 5.3+

## Installation

1. Clone the repository
2. Open `MusicPlayerApp.xcodeproj` in Xcode
3. Build and run the project
4. The app will work with mock data and simulated APIs

## Future Enhancements

- Real Spotify API integration
- Background audio playback
- Offline music storage
- User preferences and settings
- Advanced playlist features
- Social sharing capabilities
- Equalizer and audio effects

## Design Patterns Summary

| Pattern | Implementation | Purpose |
|---------|----------------|---------|
| Strategy | MusicSource protocol | Unified interface for different music sources |
| Factory | MusicSourceFactory | Centralized creation of music sources |
| Singleton | MusicPlayerService, AudioSessionManager | Single instance management |
| MVVM | ViewModels + Views | Separation of concerns |
| Observer | Combine publishers | Reactive state management |

This project demonstrates modern iOS development practices with a focus on clean architecture, design patterns, and user experience. 