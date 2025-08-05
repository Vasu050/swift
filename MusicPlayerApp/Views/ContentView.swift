import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MusicPlayerViewModel()
    
    var body: some View {
        TabView {
            PlaylistView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "music.note.list")
                    Text("Playlist")
                }
            
            PlayerControlsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "play.circle.fill")
                    Text("Player")
                }
        }
        .accentColor(.blue)
        .onAppear {
            // Initialize the music player service
            _ = MusicPlayerService.shared
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 