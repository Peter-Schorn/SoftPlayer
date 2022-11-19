import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI
import SpotifyExampleContent
import RegularExpressions
import Logging
import KeyboardShortcuts

struct PlaylistsScrollView: View {
    
    private typealias RatedPlaylist = (
        playlist: Playlist<PlaylistItemsReference>,
        rating: Double
    )
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    @AppStorage("onlyShowMyPlaylists") var onlyShowMyPlaylists = false
    
    @State private var searchText = ""
    @State private var selectedPlaylistURI: String? = nil
//    @State var searchFieldIsFocused = false
    
    @State private var playPlaylistCancellable: AnyCancellable? = nil
    
    let highlightAnimation = Animation.linear(duration: 0.1)
    let searchFieldId = "search field"
    
    var onlyShowMyPlaylistsShortcut: String {
        if let name = KeyboardShortcuts.getShortcut(for: .onlyShowMyPlaylists) {
            return " \(name)"
        }
        return ""
    }

    var filteredPlaylists:
        [(offset: Int, element: Playlist<PlaylistItemsReference>)] {
        
        let currentUserURI = self.playerManager.currentUser?.uri
        
        let lowercasedSearch = searchText.strip().lowercased()

        if lowercasedSearch.isEmpty {
            let playlists = self.playerManager.playlists
                .filter { playlist in
                    if self.onlyShowMyPlaylists,
                            let userURI = playlist.owner?.uri,
                            userURI != currentUserURI {
                        return false
                    }
                    return true
                }
                .enumerated()
            
            return Array(playlists)
        }
        
        let searchWords = lowercasedSearch.words
        
        let playlists = self.playerManager.playlists
            .compactMap { playlist -> RatedPlaylist? in
                
                if self.onlyShowMyPlaylists,
                        let userURI = playlist.owner?.uri,
                        userURI != currentUserURI {
                    return nil
                }
                
                let lowercasedPlaylistName = playlist.name.lowercased()
                if lowercasedSearch == lowercasedPlaylistName {
                    return (playlist: playlist, rating: .infinity)
                }
                
                var rating: Double = 0
                if try! lowercasedPlaylistName.regexMatch(
                    lowercasedSearch,
                    regexOptions: [.ignoreMetacharacters]
                ) != nil {
                    rating += Double(lowercasedSearch.count)
                }
                
                for searchWord in searchWords {
                    if try! lowercasedPlaylistName.regexMatch(
                        searchWord,
                        regexOptions: [.ignoreMetacharacters]
                    ) != nil {
                        rating += Double(searchWord.count)
                    }
                }
                
                if rating == 0 {
                    return nil
                }
                
                return (playlist: playlist, rating: rating)
                
            }
            .sorted { $0.rating > $1.rating }
            .map(\.playlist)
            .enumerated()
        
        return Array(playlists)
        
        
    }
    
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                HStack {
                    FocusableTextField(
                        name: "PlaylistsScrollView",
                        text: $searchText,
                        isFirstResponder: $playerManager.playlistsScrollViewIsFirstResponder,
                        onCommit: searchFieldDidCommit,
                        receiveKeyEvent: { event in
                            return self.receiveKeyEvent(
                                event, scrollView: scrollView
                            )
                        }
                    )
                    .touchBar(content: PlayPlaylistsTouchBarView.init)
                    .padding(.leading, 6)
                    .padding(.trailing, -5)
                    
                    filterMenuView
                        .padding(.trailing, 5)
                }
                .padding(.top, 5)
                .padding(.bottom, -7)
                .id(searchFieldId)
                
                LazyVStack {
                    if self.filteredPlaylists.isEmpty {
                        if playerManager.isLoadingPlaylists {
                            ProgressView("Loading Playlists")
                                .padding(.top, 120)
                        }
                        else {
                            VStack {
                                Text("No Playlists Found")
                                    .foregroundColor(.secondary)
                                    .font(.headline)
                                if onlyShowMyPlaylists {
                                    Button(action: {
                                        onlyShowMyPlaylists = false
                                    }, label: {
                                        Text("Remove Filters")
                                    })
                                    .padding(.top, 5)
                                }
                            }
                            .padding(.top, 135)
                        }
                    }
                    else {
                        ForEach(
                            self.filteredPlaylists,
                            id: \.element.uri
//                            Array(Playlist.spanishPlaylists.enumerated()),
//                            id: \.offset
                        ) { playlist in
                            PlaylistCellView(
                                playlist: playlist.element,
                                isSelected: selectedPlaylistURI == playlist.element.uri
                            )
                            .if(playlist.offset == 0) { view in
                                view.padding(.top, 10)
                            }
                            .id(playlist.offset)
                        }
                    }
                }
                
                Spacer()
                    .frame(height: 8)
                
            }
            .onExitCommand {
                self.playerManager.dismissLibraryView(animated: true)
            }
            .background(
                KeyEventHandler(name: "PlaylistsScrollView") { event in
                    return self.receiveKeyEvent(event, scrollView: scrollView)
                }
                .touchBar(content: PlayPlaylistsTouchBarView.init)
            )
            .onAppear {
                Loggers.firstResponder.trace(
                    "PlaylistsScrollView.onAppear"
                )
                scrollView.scrollTo(0, anchor: .top)
            }
//            .onDisappear {
////                print("PlaylistsScrollView disapeared")
//                playerManager.playlistsScrollViewIsFirstResponder = false
//            }
            .onChange(of: searchText) { text in
                scrollView.scrollTo(searchFieldId, anchor: .top)
            }
            
        }
        
    }
    
    var filterMenuView: some View {
        Menu {
            Button(action: {
                self.onlyShowMyPlaylists.toggle()
            }, label: {
                HStack {
                    if onlyShowMyPlaylists {
                        Image(systemName: "checkmark")
                    }
                    Text("Only Show My Playlists") +
                    Text(onlyShowMyPlaylistsShortcut)
                        .foregroundColor(.secondary)
                    
                }
            })
        } label: {
            Image(systemName: "line.horizontal.3.decrease.circle.fill")
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .help(Text("Filters"))
        .frame(width: 30)
    }
    
    /// Returns `true` if the key event was handled; else, `false`.
    func receiveKeyEvent(
        _ event: NSEvent,
        scrollView: ScrollViewProxy?
    ) -> Bool {

        Loggers.keyEvent.trace("PlaylistsScrollView: \(event)")

        // don't handle the key event if the
        // `SavedAlbumsGridView` page is being shown
        if playerManager.libraryPage != .playlists {
            Loggers.keyEvent.debug(
                "PlaylistsScrollView not handling event because not shown"
            )
            return false
        }

        if !event.modifierFlags.isEmpty && !event.modifierFlags.isDisjoint(
            with: NSEvent.ModifierFlags.shortchutModifiers
        ) {
            return self.playerManager.receiveKeyEvent(
                event, requireModifierKey: true
            )
        }
        // return or enter key
        else if [76, 36].contains(event.keyCode) {
            self.searchFieldDidCommit()
            return true
        }
        // escape key
        else if event.keyCode == 53 {
            self.playerManager.dismissLibraryView(animated: true)
            return true
        }
        else if let scrollView = scrollView, event.specialKey == nil,
                let character = event.characters {

            self.playerManager.playlistsScrollViewIsFirstResponder = true
            self.searchText += character
            scrollView.scrollTo(searchFieldId, anchor: .top)
            return true

        }
        return false
    }

    func searchFieldDidCommit() {
        guard self.playerManager.isShowingLibraryView,
              playerManager.libraryPage == .playlists else {
            return
        }
        
        if let firstPlaylist = self.filteredPlaylists.first?.element {
            withAnimation(self.highlightAnimation) {
                self.selectedPlaylistURI = firstPlaylist.uri
            }
            Loggers.playlistsScrollView.trace(
                "playing playlist '\(firstPlaylist.name)'"
            )
            self.playPlaylist(firstPlaylist)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(self.highlightAnimation) {
                    self.selectedPlaylistURI = nil
                }
            }
        }
        else {
            withAnimation(self.highlightAnimation) {
                self.selectedPlaylistURI = nil
            }
        }
    }

    func playPlaylist(_ playlist: Playlist<PlaylistItemsReference>) {
        self.playPlaylistCancellable = self.playerManager
            .playPlaylist(playlist)
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        self.playerManager.retrieveCurrentlyPlayingContext()
                    case .failure(let alert):
                        self.playerManager.notificationSubject.send(alert)
                }
            })

    }

}

struct PlaylistsScrollView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        PlaylistsScrollView()
            .frame(
                width: AppDelegate.popoverWidth,
                height: AppDelegate.popoverHeight
            )
            .environmentObject(playerManager)
            .environmentObject(playerManager.spotify)
    }
    
}
