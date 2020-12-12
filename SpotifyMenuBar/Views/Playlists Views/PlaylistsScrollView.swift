import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI
import RegularExpressions
import Logging

struct PlaylistsScrollView: View {
    
    private typealias RatedPlaylist = (
        playlist: Playlist<PlaylistsItemsReference>,
        rating: Double
    )
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    @Binding var isShowingPlaylistsView: Bool
    
    @AppStorage("onlyShowMyPlaylists") var onlyShowMyPlaylists = false
    
    @State private var searchText = ""
    @State private var selectedPlaylistURI: String? = nil
    @State private var searchFieldIsFocused = false
    
    @State private var alertIsPresented = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @State private var playPlaylistCancellable: AnyCancellable? = nil
    
    let highlightAnimation = Animation.linear(duration: 0.1)
    let searchFieldId = "search field"
    
    var filteredPlaylists:
        [(offset: Int, element: Playlist<PlaylistsItemsReference>)] {
        
        let currentUserId = self.playerManager.currentUser?.id
        
        if searchText.strip().isEmpty {
            return Array(
                self.playerManager.playlistsSortedByLastedModifiedDate
                    .filter { playlist in
                        if onlyShowMyPlaylists, let userId = playlist.owner?.id,
                                userId != currentUserId {
                            return false
                        }
                        return true
                    }
                    .enumerated()
            )
        }
        
        let lowerCasedSearch = searchText.lowercased()
        let searchWords = lowerCasedSearch.words
        
        let playlists = self.playerManager.playlistsSortedByLastedModifiedDate
            .compactMap { playlist -> RatedPlaylist? in
                
                if onlyShowMyPlaylists, let userId = playlist.owner?.id,
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
                        onCommit: onSearchFieldCommit
                    )
                    .id(searchFieldId)
                    .padding(.vertical, 5)
                    .padding(.leading, 3)
                    .padding(.trailing, -5)
                    
                    filterMenuView
                        .padding(.trailing, 3)
                }
                .padding(.top, 5)
                .padding(.bottom, -12)
                
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
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 3)
            .alert(isPresented: $alertIsPresented) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage)
                )
            }
            .onAppear {
//                if !ProcessInfo.processInfo.isPreviewing {
                print("\nPlaylistsScrollView DID APPEAR\n")
                    scrollView.scrollTo(0, anchor: .top)
//                }
            }
            .onKeyEvent { event in
                self.receiveKeyEvent(event, scrollView: scrollView)
            }
            .onChange(of: searchText) { text in
//                print("search text change scroll")
                scrollView.scrollTo(searchFieldId, anchor: .top)
            }
            .onReceive(playerManager.keyEventSubject) { event in
                self.receiveKeyEvent(event, scrollView: scrollView)
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
                    Text("Only Show My Playlists")
                }
            })
        } label: {
            Image(systemName: "line.horizontal.3.decrease.circle.fill")
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .frame(width: 30)
    }
    
    func receiveKeyEvent(_ event: NSEvent, scrollView: ScrollViewProxy) {
        
        if [76, 36].contains(event.keyCode) {
            self.onSearchFieldCommit()
        }
        else if let character = event.charactersIgnoringModifiers {
            print("PlaylistsScrollView receiveKeyEvent: '\(character)'")
            print(event)

            self.searchFieldIsFocused = true
            self.searchText += character
            print("scrolling to search field")
            scrollView.scrollTo(searchFieldId, anchor: .top)
        }
    }
    
    func onSearchFieldCommit() {
        print("onSearchFieldCommit")
        guard isShowingPlaylistsView else {
            print("skipping because not presented")
            return
        }
        if let firstPlaylist = self.filteredPlaylists.first?.element {
//            DispatchQueue.main.async {
                withAnimation(highlightAnimation) {
                    self.selectedPlaylistURI = firstPlaylist.uri
                }
                print("playing playlist \(firstPlaylist.name)")
                self.playPlaylist(firstPlaylist)
//            }
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
                    self.alertTitle =
                        #"Couldn't play "\#(playlist.name)""#
                    self.alertMessage = error.localizedDescription
                    self.alertIsPresented = true
                    print("\(alertTitle): \(error)")
                }
            })

    }

}

struct PlaylistsScrollView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistsView_Previews.previews
    }
}
