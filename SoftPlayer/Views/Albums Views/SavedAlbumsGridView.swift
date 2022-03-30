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
    @State private var selectedAlbumURI: String? = nil

    @State private var loadAlbumsCancellable: AnyCancellable? = nil

    let columns = [
        GridItem(.flexible(), alignment: .top),
        GridItem(.flexible(), alignment: .top),
        GridItem(.flexible(), alignment: .top)
    ]

    let searchFieldId = "search field"

    let highlightAnimation = Animation.linear(duration: 0.1)

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
                    if playerManager.isLoadingSavedAlbums {
                            ProgressView("Loading Albums")
                            .padding(.top, 120)
                    }
                    else {
                        Text("No Albums Found")
                            .foregroundColor(.secondary)
                            .font(.headline)
                            .padding(.top, 135)
                    }
                }
                else {
                    LazyVGrid(
                        columns: columns
                    ) {
                        ForEach(
                            self.filteredAlbums,
                            id: \.element.id
                        ) { offset, album in
                            AlbumGridItemView(
                                album: album,
                                isSelected: selectedAlbumURI == album.uri
                            )
                            .if((0...2).contains(offset)) {
                                $0.padding(.top, 7)
                            }
                            .id(offset)
                        }
                    }
                    .padding(.horizontal, 5)
                }
                
            }
            .onExitCommand {
                self.playerManager.dismissLibraryView(animated: true)
            }
            .background(
                KeyEventHandler(name: "SavedAlbumsGridView") { event in
                    return self.receiveKeyEvent(event, scrollView: scrollView)
                }
                .touchBar(content: PlayPlaylistsTouchBarView.init)
            )
            .onAppear {
                if !self.playerManager.didScrollToAlbumsSearchBar {
                    scrollView.scrollTo(0, anchor: .top)
                    self.playerManager.didScrollToAlbumsSearchBar = true
                }
                searchFieldIsFocused = true
            }
//            .onDisappear {
////                print("SavedAlbumsGridView disapeared")
//                searchFieldIsFocused = false
//            }
            .onChange(of: searchText) { text in
                scrollView.scrollTo(searchFieldId, anchor: .top)
            }
            .onChange(of: playerManager.libraryPage) { page in
                if page == .albums {
                    searchFieldIsFocused = true
                }
                else {
                    searchFieldIsFocused = false
                }
            }
            .onChange(of: playerManager.isShowingLibraryView) { isShowing in
                if !isShowing {
//                    print("SavedAlbumsGridView.onChange: searchFieldIsFocused = false")
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
        if playerManager.libraryPage == .playlists {
            Loggers.keyEvent.debug(
                "SavedAlbumsGridView not handling event because not shown"
            )
            return false
        }

        // If at least one shortcut modifier was used
        if !event.modifierFlags.intersection(.shortchutModifiers).isEmpty {
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
            
            self.searchFieldIsFocused = true
            self.searchText += character
            scrollView.scrollTo(searchFieldId, anchor: .top)
            return true

        }
        return false
    }

    func searchFieldDidCommit() {
        guard self.playerManager.isShowingLibraryView,
              playerManager.libraryPage == .albums else {
            return
        }
        
        if let firstAlbum = self.filteredAlbums.first?.element {
            withAnimation(highlightAnimation) {
                self.selectedAlbumURI = firstAlbum.uri
            }
            Loggers.savedAlbumsGridView.trace(
                "playing album '\(firstAlbum.name)'"
            )
            self.playAlbum(firstAlbum)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(highlightAnimation) {
                    self.selectedAlbumURI = nil
                }
            }
        }
        else {
            withAnimation(highlightAnimation) {
                self.selectedAlbumURI = nil
            }
        }

    }
    
    func playAlbum(_ album: Album) {
        self.playerManager.playAlbum(album)
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
