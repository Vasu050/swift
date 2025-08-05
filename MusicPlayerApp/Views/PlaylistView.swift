import SwiftUI
import Combine

struct PlaylistView: View {
    @ObservedObject var viewModel: MusicPlayerViewModel
    @State private var showingAddSong = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Music Source Selector
                musicSourceSelector
                
                // Search Bar
                searchBar
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if !viewModel.searchResults.isEmpty {
                    searchResultsView
                } else {
                    playlistView
                }
            }
            .navigationTitle("Music Player")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Song") {
                        showingAddSong = true
                    }
                }
            }
            .sheet(isPresented: $showingAddSong) {
                AddSongView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Music Source Selector
    private var musicSourceSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MusicSourceType.allCases, id: \.self) { sourceType in
                    Button(action: {
                        viewModel.switchMusicSource(sourceType)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: viewModel.getSourceIcon(sourceType))
                                .foregroundColor(viewModel.getSourceColor(sourceType))
                            Text(sourceType.rawValue.capitalized)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(viewModel.selectedMusicSource == sourceType ? 
                                      viewModel.getSourceColor(sourceType).opacity(0.2) : 
                                      Color.gray.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(viewModel.selectedMusicSource == sourceType ? 
                                       viewModel.getSourceColor(sourceType) : 
                                       Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search songs...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: searchText) { newValue in
                    if !newValue.isEmpty {
                        viewModel.searchSongs(query: newValue)
                    } else {
                        viewModel.clearSearch()
                    }
                }
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                    viewModel.clearSearch()
                }
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading...")
                .foregroundColor(.gray)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Search Results View
    private var searchResultsView: some View {
        List {
            ForEach(viewModel.searchResults) { song in
                SongRowView(song: song, viewModel: viewModel)
                    .contextMenu {
                        Button("Add to Playlist") {
                            viewModel.addToPlaylist(song)
                        }
                        Button("Play Now") {
                            viewModel.playSong(song)
                        }
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Playlist View
    private var playlistView: some View {
        VStack {
            if viewModel.playlist.isEmpty {
                emptyPlaylistView
            } else {
                playlistListView
            }
        }
    }
    
    private var emptyPlaylistView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Your playlist is empty")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            
            Text("Search for songs and add them to your playlist")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var playlistListView: some View {
        List {
            ForEach(Array(viewModel.playlist.enumerated()), id: \.element.id) { index, song in
                PlaylistSongRowView(
                    song: song,
                    index: index,
                    isCurrentSong: viewModel.currentSong?.id == song.id,
                    viewModel: viewModel
                )
                .contextMenu {
                    Button("Play") {
                        viewModel.playSongAtIndex(index)
                    }
                    Button("Remove from Playlist") {
                        viewModel.removeFromPlaylist(song)
                    }
                }
            }
            .onMove(perform: viewModel.moveInPlaylist)
        }
        .listStyle(PlainListStyle())
        .environment(\.editMode, .constant(.active))
    }
}

// MARK: - Song Row View
struct SongRowView: View {
    let song: Song
    let viewModel: MusicPlayerViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Artwork
            AsyncImage(url: song.artworkURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 50, height: 50)
            .cornerRadius(8)
            
            // Song Info
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack {
                    Text(song.album)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(viewModel.formatDuration(song.duration))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Source Icon
            Image(systemName: viewModel.getSourceIcon(song.source))
                .foregroundColor(viewModel.getSourceColor(song.source))
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Playlist Song Row View
struct PlaylistSongRowView: View {
    let song: Song
    let index: Int
    let isCurrentSong: Bool
    let viewModel: MusicPlayerViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Song Number
            Text("\(index + 1)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isCurrentSong ? .blue : .gray)
                .frame(width: 20)
            
            // Artwork
            AsyncImage(url: song.artworkURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 50, height: 50)
            .cornerRadius(8)
            
            // Song Info
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(isCurrentSong ? .blue : .primary)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack {
                    Text(song.album)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(viewModel.formatDuration(song.duration))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Playing Indicator
            if isCurrentSong {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .background(isCurrentSong ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

// MARK: - Add Song View
struct AddSongView: View {
    @ObservedObject var viewModel: MusicPlayerViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var selectedSource: MusicSourceType = .local
    
    var body: some View {
        NavigationView {
            VStack {
                // Source Selector
                Picker("Music Source", selection: $selectedSource) {
                    ForEach(MusicSourceType.allCases, id: \.self) { source in
                        Text(source.rawValue.capitalized).tag(source)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search songs...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { newValue in
                            if !newValue.isEmpty {
                                viewModel.searchSongs(query: newValue)
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                
                // Results
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.searchResults) { song in
                            SongRowView(song: song, viewModel: viewModel)
                                .onTapGesture {
                                    viewModel.addToPlaylist(song)
                                    presentationMode.wrappedValue.dismiss()
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Add Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct PlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistView(viewModel: MusicPlayerViewModel())
    }
} 