import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI
import KeyboardShortcuts

struct QueueView: View {
    
    private typealias RatedQueueItem = (queueItem: PlaylistItem, rating: Double)

    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    @State private var searchText = ""
    
    @State private var selectedQueueItemURI: String? = nil
    
    let searchFieldId = "search field"

    let highlightAnimation = Animation.linear(duration: 0.1)

    var filteredQueueItems: [(offset: Int, element: PlaylistItem)] {
        
        let lowercasedSearch = searchText.strip().lowercased()
        
        if lowercasedSearch.isEmpty {
            let filteredQueueItems = self.playerManager.queue
                .enumerated()
            
            return Array(filteredQueueItems)
                
        }
        
        let searchWords = lowercasedSearch.words
        
        let filteredQueueItems = self.playerManager.queue
            .compactMap { queueItem -> RatedQueueItem? in
                
                let lowercasedName = queueItem.name.lowercased()
                
                if lowercasedSearch == lowercasedName {
                    return (queueItem: queueItem, rating: .infinity)
                }

                // artist or show names
                let lowercasedArtistNames: [String]
                switch queueItem {
                    case .track(let track):
                        lowercasedArtistNames = track.artists?
                            .map({ $0.name.lowercased() }) ?? []
                    case .episode(let episode):
                        lowercasedArtistNames = (episode.show?.name)
                            .map({ [$0] }) ?? []
                }
                
                for artistName in lowercasedArtistNames {
                    // An exact match to the artist/show name does not rank
                    // quite as high as an exact match to the album name.
                    if lowercasedSearch == artistName {
                        return (
                            queueItem: queueItem,
                            rating: .greatestFiniteMagnitude
                        )
                    }
                }
                
                var names = lowercasedArtistNames
                names.append(lowercasedName)
                
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
                
                return (queueItem: queueItem, rating: rating)

            }
            .sorted { $0.rating > $1.rating }
            .map(\.queueItem)
            .enumerated()
        
        
        return Array(filteredQueueItems)

    }

    var body: some View {
        Group {
            if playerManager.queue.isEmpty {
                Text("The Queue is Empty")
                    .foregroundColor(.secondary)
                    .font(.headline)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            else {
                ScrollViewReader { scrollView in
                    ScrollView {
                        FocusableTextField(
                            name: "QueueView",
                            text: $searchText,
                            isFirstResponder: $playerManager.queueViewIsFirstResponder,
                            onCommit: searchFieldDidCommit,
                            receiveKeyEvent: { event in
                                return self.receiveKeyEvent(
                                    event, scrollView: scrollView
                                )
                            }
                        )
                        .touchBar(content: PlayPlaylistsTouchBarView.init)
                        .padding(.top, 7)
                        .padding(.trailing, 5)
                        .id(searchFieldId)
                        
                        if filteredQueueItems.isEmpty {
                            Text("No Results")
                                .foregroundColor(.secondary)
                                .font(.headline)
                                .padding(.top, 135)
                        }

                        ForEach(
    //                        Array(Self.sampleQueue2.enumerated()),
                            filteredQueueItems,
                            id: \.offset
                        ) { (offset, item) in
                            QueueItemView(
                                item: item,
                                index: offset,
                                isSelected: selectedQueueItemURI == item.uri
                            )
                            .if(offset == 0) { view in
                                view.padding(.top, 10)
                            }
                            .id(offset)
                                
                        }
                        if self.playerManager.queue.count <= 2 &&
                                !self.filteredQueueItems.isEmpty &&
                                searchText.strip().isEmpty {
                            Text(
                                """
                                If you expect to see more items in the queue, \
                                then this is a bug on Spotify's end, not with \
                                this app.
                                """
                            )
                            .foregroundColor(.secondary)
                            .font(.caption)
                        }
                    }
                    .padding(.leading, 10)
                    .onAppear {
                        scrollView.scrollTo(0, anchor: .top)
                    }
                    .onChange(of: searchText) { _ in
                        scrollView.scrollTo(searchFieldId, anchor: .top)
                    }
                }
            }
        }
        .background(
            KeyEventHandler(name: "QueueView") { event in
                self.playerManager.receiveKeyEvent(
                    event, requireModifierKey: true
                )
            }
            .touchBar(content: PlayPlaylistsTouchBarView.init)
        )
        
    }
    
    /// Returns `true` if the key event was handled; else, `false`.
    func receiveKeyEvent(
        _ event: NSEvent,
        scrollView: ScrollViewProxy?
    ) -> Bool {
        
        Loggers.keyEvent.trace("QueueView: \(event)")
        
        // don't handle the key event if the
        // `PlaylistsScrollView` page is being shown
        if playerManager.libraryPage == .playlists {
            Loggers.keyEvent.debug(
                "QueueView not handling event because not shown"
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
            
            self.playerManager.queueViewIsFirstResponder = true
            self.searchText += character
            scrollView.scrollTo(searchFieldId, anchor: .top)
            return true

        }
        return false
    }

    func searchFieldDidCommit() {
        
        guard self.playerManager.isShowingLibraryView,
                playerManager.libraryPage == .queue else {
            return
        }
        
        if let firstQueueItem = self.filteredQueueItems.first?.element {
            withAnimation(self.highlightAnimation) {
                self.selectedQueueItemURI = firstQueueItem.uri
            }
            Loggers.queue.trace(
                "playing queue item '\(firstQueueItem.name)'"
            )
            self.playerManager.playQueueItem(firstQueueItem)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(self.highlightAnimation) {
                    self.selectedQueueItemURI = nil
                }
            }
        }
        else {
            withAnimation(highlightAnimation) {
                self.selectedQueueItemURI = nil
            }
        }

    }
    
}

extension QueueView {
    
    static let sampleQueue: [PlaylistItem] = [
        .echoesAcousticVersion,
        .joeRogan1536,
        .joeRogan1537,
        .killshot,
        .oceanBloom,
        .samHarris216,
        .samHarris217,
        .track(.comeTogether),
        .track(.because),
        .track(.reckoner),
        .track(.time),
        .track(.theEnd),
        .track(.illWind),
        .track(.odeToViceroy)
    ]
    
    static let sampleQueue2: [PlaylistItem] = Album.darkSideOfTheMoon.tracks!
        .items[1...].map { track in
            PlaylistItem.track(track)
        }
    
}

struct QueueView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        QueueView()
            .frame(
                width: AppDelegate.popoverWidth,
                height: AppDelegate.popoverHeight
            )
            .environmentObject(playerManager)
            .environmentObject(playerManager.spotify)
    }
    
}
