import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI
import SpotifyExampleContent
import Logging

struct SavedAlbumsGridView: View {
    
    private typealias RatedAlbum = (album: Album, rating: Double)

    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager

    @State private var searchText = ""
    @State private var searchFieldIsFocused = false
    
    @State private var loadAlbumsCancellable: AnyCancellable? = nil

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    let searchFieldId = "search field"

    var filteredAlbums: [(offset: Int, element: Album)] {

        let lowercasedSearch = searchText.strip().lowercased()
        
        if lowercasedSearch.isEmpty {
            let filteredAlbums = self.playerManager.savedAlbums
                .enumerated()
            
            return Array(filteredAlbums)
                
        }

        let searchWords = lowercasedSearch.words

        let filteredAlbums = self.playerManager.savedAlbums
            .compactMap { album -> RatedAlbum? in
                
                let lowercasedAlbumName = album.name.lowercased()
                let lowercasedArtistNames = album.artists?
                    .map({ $0.name.lowercased() }) ?? []
                
                if lowercasedSearch == lowercasedAlbumName {
                    return (album: album, rating: .infinity)
                }
                
                for artistName in lowercasedArtistNames {
                    // An exact match to the artist name does not rank quite
                    // as high as an exact match to the album name.
                    if lowercasedSearch == artistName {
                        return (
                            album: album,
                            rating: .greatestFiniteMagnitude
                        )
                    }
                }

                /// The album and artist names
                var names = lowercasedArtistNames
                names.append(lowercasedAlbumName)

                var rating: Double = 0
                
                for name in names {
                    // search the full string
                    if try! name.regexMatch(
                        lowercasedSearch,
                        regexOptions: [.ignoreMetacharacters]
                    ) != nil {
                        rating += Double(lowercasedSearch.count)
                    }
                    
                    // search each word
                    for searchWord in searchWords {
                        if try! name.regexMatch(
                            searchWord,
                            regexOptions: [.ignoreMetacharacters]
                        ) != nil {
                            rating += Double(searchWord.count)
                        }
                    }

                }
                
                if rating == 0 {
                    return nil
                }
                
                return (album: album, rating: rating)

            }
            .sorted { $0.rating > $1.rating }
            .map(\.album)
            .enumerated()
        
        return Array(filteredAlbums)
        
    }

    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                FocusableTextField(
                    name: "SavedAlbumsGridView",
                    text: $searchText,
                    isFirstResponder: $searchFieldIsFocused,
                    onCommit: searchFieldDidCommit,
                    receiveKeyEvent: { event in
                        return self.receiveKeyEvent(
                            event, scrollView: scrollView
                        )
                    }
                )
                .touchBar(content: PlayPlaylistsTouchBarView.init)
                .padding([.horizontal, .top], 5)
                .padding(.bottom, -5)
                .id(searchFieldId)
                
                if self.filteredAlbums.isEmpty {
                    Text("No Albums Found")
                        .foregroundColor(.secondary)
                        .font(.headline)
                }
                else {
                    LazyVGrid(columns: columns) {
                        ForEach(
                            self.filteredAlbums,
                            id: \.element.id
                        ) { offset, album in
                            AlbumGridItemView(album: album)
                                .if((0...3).contains(offset)) {
                                    $0.padding(.top, 7)
                                }
                                .id(offset)
                        }
                    }
                    .padding(.horizontal, 5)
                }
                
            }
            .onExitCommand {
                self.playerManager.dismissPlaylistsView(animated: true)
            }
            .background(
                KeyEventHandler { event in
                    return self.receiveKeyEvent(event, scrollView: scrollView)
                }
                .touchBar(content: PlayPlaylistsTouchBarView.init)
            )
            .onAppear {
                if !self.playerManager.didScrollToAlbumsSearchBar {
                    scrollView.scrollTo(0, anchor: .top)
                    self.playerManager.didScrollToAlbumsSearchBar = true
                }
            }
            .onChange(of: searchText) { text in
                scrollView.scrollTo(searchFieldId, anchor: .top)
            }
            .onChange(of: playerManager.libraryPage) { page in
                if page == 1 {
                    searchFieldIsFocused = true
                }
                else {
                    searchFieldIsFocused = false
                }
            }
        }
    }
    
    /// Returns `true` if the key event was handled; else, `false`.
    func receiveKeyEvent(
        _ event: NSEvent,
        scrollView: ScrollViewProxy?
    ) -> Bool {
        
        Loggers.keyEvent.trace("SavedAlbumsGridView: \(event)")
        
        // don't handle the key event if the
        // `PlaylistsScrollView` page is being shown
        if playerManager.libraryPage == 0 {
            Loggers.keyEvent.debug(
                "SavedAlbumsGridView not handling event because not shown"
            )
            return false
        }

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
        // escape key
        else if event.keyCode == 53 {
            self.playerManager.dismissPlaylistsView(animated: true)
            return true
        }
        else if let scrollView = scrollView, event.specialKey == nil,
                let character = event.charactersIgnoringModifiers {
            
            self.searchFieldIsFocused = true
            self.searchText += character
            scrollView.scrollTo(searchFieldId, anchor: .top)
            return true

        }
        return false
    }

    func searchFieldDidCommit() {
        
    }

}

struct SavedAlbumsGridView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        SavedAlbumsGridView()
            .frame(width: AppDelegate.popoverWidth, height: 320)
            .onAppear {
                playerManager.retrieveSavedAlbums()
            }
            .environmentObject(playerManager)
            .environmentObject(playerManager.spotify)
            
    }
}
