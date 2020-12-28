import Foundation
import SwiftUI
import SpotifyWebAPI
import SpotifyExampleContent

struct QueueView: View {

    @Environment(\.colorScheme) var colorScheme

    @State private var upNextItems: [PlaylistItem] = [
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
    
    @State private var nextFromContextItems =
            Playlist.crumb.items.items.compactMap(\.item)


    var upNextHeader: some View {
        Text("Up Next")
            .headerModifiers(colorScheme)
    }

    var nextFromContextHeader: some View {
        Text(#"Next from "Crumb""#)
            .headerModifiers(colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.1)
            List {
                Section(header: upNextHeader) {
                    ForEach(upNextItems.identifiedArray()) { item in
                        QueueItemView(item: item.item)
                    }
                    .onMove(perform: onMoveUpNextItems)
                    .onDelete(perform: onDeleteUpNextItems)
                }
                Section(header: nextFromContextHeader) {
                    ForEach(nextFromContextItems.identifiedArray()) { item in
                        QueueItemView(item: item.item)
                    }
                    .onMove(perform: onMoveNextFromContextItems)
                    .onDelete(perform: onDeleteNextFromContextItems)
                }
            }
            .listStyle(PlainListStyle())
        }
    }

    func onMoveUpNextItems(offsets: IndexSet, newOffset: Int) {
        self.upNextItems.move(
            fromOffsets: offsets,
            toOffset: newOffset
        )
    }
    
    func onDeleteUpNextItems(offsets: IndexSet) {
        self.upNextItems.remove(atOffsets: offsets)
    }

    func onMoveNextFromContextItems(offsets: IndexSet, newOffset: Int) {
        self.nextFromContextItems.move(
            fromOffsets: offsets,
            toOffset: newOffset
        )
    }
    
    func onDeleteNextFromContextItems(offsets: IndexSet) {
        self.nextFromContextItems.remove(atOffsets: offsets)
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

