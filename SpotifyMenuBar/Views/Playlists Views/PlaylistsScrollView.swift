import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI
import RegularExpressions
import Logging
import KeyboardShortcuts

struct PlaylistsScrollView: View {
    
    private typealias RatedPlaylist = (
        playlist: Playlist<PlaylistsItemsReference>,
        rating: Double
    )
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    @AppStorage("onlyShowMyPlaylists") var onlyShowMyPlaylists = false
    
    @State private var searchText = ""
    @State private var selectedPlaylistURI: String? = nil
    @State private var searchFieldIsFocused = false
    
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
        [(offset: Int, element: Playlist<PlaylistsItemsReference>)] {
        
        let currentUserId = self.playerManager.currentUser?.id
        
        if searchText.strip().isEmpty {
            let playlists = self.playerManager.playlistsSortedByLastModifiedDate
                .filter { playlist in
                    if self.onlyShowMyPlaylists,
                       let userId = playlist.owner?.id,
                       userId != currentUserId {
                        return false
                    }
                    return true
                }
                .enumerated()
            
            return Array(playlists)
        }
        
        let lowerCasedSearch = searchText.lowercased()
        let searchWords = lowerCasedSearch.words
        
        let playlists = self.playerManager.playlistsSortedByLastModifiedDate
            .compactMap { playlist -> RatedPlaylist? in
                
                if self.onlyShowMyPlaylists,
                        let userId = playlist.owner?.id,
                        userId != currentUserId {
                    return nil
                }
                
                let lowerCasedPlaylistName = playlist.name.lowercased()
                if lowerCasedSearch == lowerCasedPlaylistName {
                    return (playlist: playlist, rating: .infinity)
                }
                
                var rating: Double = 0
                if try! lowerCasedPlaylistName.regexMatch(
                    lowerCasedSearch,
                    regexOptions: [.ignoreMetacharacters]
                ) != nil {
                    rating += Double(lowerCasedSearch.count)
                }
                
                for searchWord in searchWords {
                    if try! lowerCasedPlaylistName.regexMatch(
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
            .sorted { lhs, rhs in
                lhs.rating > rhs.rating
            }
            .map(\.playlist)
            .enumerated()
        
        return Array(playlists)
        
        
    }
    
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                HStack {
                    FocusableTextField(
                        text: $searchText,
                        isFirstResponder: $searchFieldIsFocused,
                        onCommit: searchFieldDidCommit,
                        receiveKeyEvent: receiveSearchFieldKeyEvent
                    )
                    .touchBar(content: PlayPlaylistsTouchBarView.init)
                    .padding(.leading, 6)
                    .padding(.trailing, -5)
                    
                    filterMenuView
                        .padding(.trailing, 5)
                }
                .padding(.top, 10)
                .padding(.bottom, -7)
                .id(searchFieldId)
                
                LazyVStack {
                    
                    ForEach(
                        self.filteredPlaylists,
                        id: \.element.uri
                    ) { playlist in
                        PlaylistsCellView(
                            playlist: playlist.element,
                            isSelected: selectedPlaylistURI == playlist.element.uri
                        )
                        .if(playlist.offset == 0) {
                            $0.padding(.top, 10)
                        }
                        .id(playlist.offset)
                    }
                    
                }
                
                Spacer()
                    .frame(height: 8)
                
            }
            .background(
                KeyEventHandler { event in
                    return self.receiveKeyEvent(event, scrollView: scrollView)
                }
                .touchBar(content: PlayPlaylistsTouchBarView.init)
            )
            .onAppear {
                scrollView.scrollTo(0, anchor: .top)
            }
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
                    Text("Only Show My Playlists\(onlyShowMyPlaylistsShortcut)")
                }
            })
        } label: {
            Image(systemName: "line.horizontal.3.decrease.circle.fill")
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .help("Filters")
        .frame(width: 30)
    }

    func receiveSearchFieldKeyEvent(_ event: NSEvent) -> Bool {
        print("receiveSearchFieldKeyEvent: \(event)")
        return receiveKeyEvent(event, scrollView: nil)
    }
    
    /// Returns `true` if the key event was handled; else, `false`.
    func receiveKeyEvent(_ event: NSEvent, scrollView: ScrollViewProxy?) -> Bool {

        Loggers.keyEvent.trace("PlaylistsScrollView: \(event)")

        if event.modifierFlags.contains(.command) {
            return self.playerManager.receiveKeyEvent(
                event, requireModifierKey: true
            )
        }
        // return or enter key
        else if [76, 36].contains(event.keyCode) {
            self.searchFieldDidCommit()
            return true
        }
        else if let scrollView = scrollView, event.specialKey == nil,
                let character = event.charactersIgnoringModifiers {
            print("charactersIgnoringModifiers: '\(character)'")
            print("PlaylistsScrollView receiveKeyEvent: '\(character)'")
            print(event)

            self.searchFieldIsFocused = true
            self.searchText += character
            print("scrolling to search field")
            scrollView.scrollTo(searchFieldId, anchor: .top)
            return true
        }
        return false
    }

    func searchFieldDidCommit() {
        print("onSearchFieldCommit")
        guard self.playerManager.isShowingPlaylistsView else {
            print("skipping because not presented")
            return
        }
        if let firstPlaylist = self.filteredPlaylists.first?.element {
            withAnimation(highlightAnimation) {
                self.selectedPlaylistURI = firstPlaylist.uri
            }
            print("playing playlist \(firstPlaylist.name)")
            self.playPlaylist(firstPlaylist)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(highlightAnimation) {
                    self.selectedPlaylistURI = nil
                }
            }
        }
        else {
            withAnimation(highlightAnimation) {
                self.selectedPlaylistURI = nil
            }
        }
    }

    func playPlaylist(_ playlist: Playlist<PlaylistsItemsReference>) {
        self.playPlaylistCancellable = self.playerManager
            .playPlaylist(playlist)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    let alertTitle = #"Couldn't play "\#(playlist.name)""#
                    self.playerManager.presentNotification(
                        title: alertTitle,
                        message: error.localizedDescription
                    )
                    print("PlaylistsScrollView: \(alertTitle): \(error)")
                }
            })

    }

}

struct PlaylistsScrollView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
            .onAppear {
                PlayerView.debugIsShowingPlaylistsView = true
            }
    }
}
