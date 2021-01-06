import Foundation
import SwiftUI
import SpotifyWebAPI
import SpotifyExampleContent

struct QueueView: View {

    @Environment(\.colorScheme) var colorScheme

    let upNextItems: [PlaylistItem] = [
        .track(.missingArtist),
        .episode(.samHarris215),
        .track(.because),
        .track(.comeTogether),
        .episode(.seanCarroll111),
        .episode(.seanCarroll112),
        .episode(.samHarris213),
        .track(.illWind),
        .episode(.samHarris214),
        .track(.odeToViceroy),
        .track(.reckoner),
        .track(.theEnd),
        .track(.time)
    ]
    
    let nextFromContextItems =
            Playlist.crumb.items.items.compactMap(\.item)

    @State private var allItems: [PlaylistItem]
    @State private var nextFromContextOffset: Int

    init() {
        self._allItems = State(initialValue: upNextItems + nextFromContextItems)
        self._nextFromContextOffset = State(initialValue: upNextItems.count)
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.1)
            List {
                Section(header: upNextHeader) {
                    ForEach(
                        allItems[..<nextFromContextOffset].identifiedArray()
                    ) { item in
                        QueueItemView(item: item.item)
                    }
                    .onMove(perform: onMove)
                    .onDelete(perform: onDelete)
                }
                Section(header: nextFromContextHeader) {
                    ForEach(
                        allItems[nextFromContextOffset...].identifiedArray()
                    ) { item in
                        QueueItemView(item: item.item)
                    }
                    .onMove(perform: onMove)
                    .onDelete(perform: onDelete)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    var upNextHeader: some View {
        Text("Up Next")
            .headerModifiers(colorScheme)
    }

    var nextFromContextHeader: some View {
        Text(#"Next from "Crumb""#)
            .headerModifiers(colorScheme)
    }

    func onMove(offsets: IndexSet, newOffset: Int) {
        self.allItems.move(
            fromOffsets: offsets,
            toOffset: newOffset
        )
    }

    func onDelete(offsets: IndexSet) {
        self.allItems.remove(atOffsets: offsets)
    }

}

private extension Text {
    func headerModifiers(_ colorScheme: ColorScheme) -> some View {
        self
            .font(.callout)
            .fontWeight(.heavy)
            .foregroundColor(.primary)
//            .foregroundColor(colorScheme == .dark ? .white : .black)
//            .foregroundColor(Color(colorScheme == .dark ? #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)))
    }
}

struct QueueView_Previews: PreviewProvider {
    static var previews: some View {
        
        PlayerView_Previews.previews
        
        QueueView()
            .frame(
                width: AppDelegate.popoverWidth,
//                height: AppDelegate.popoverHeight - 100
                height: 500
            )
    }
}

