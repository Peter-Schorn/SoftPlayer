import SwiftUI

struct PlaylistsAndQueueTabHeader: View {
    
    @Namespace var namespace

    @Binding var selectedTab: Int

    let playlistsQueueTabId = "playlistsQueueTab"

    var body: some View {
        HStack {
            self.tab(0, label: "Playlists", width: 60)
            self.tab(1, label: "Queue", width: 50)
        }
        .font(.callout)
        .buttonStyle(PlainButtonStyle())
        .padding(.bottom, 5)
    }
    
    func tab(_ tab: Int, label: String, width: CGFloat) -> some View {
        Button(action: {
            withAnimation {
                self.selectedTab = tab
            }
        }, label: {
            VStack(spacing: 0) {
                Text(label)
                    .frame(maxHeight: .infinity, alignment: .top)
                if selectedTab == tab {
                    Capsule()
                        .frame(width: width, height: 2)
                        .matchedGeometryEffect(
                            id: playlistsQueueTabId,
                            in: namespace
                        )
                }
            }
        })
        .frame(width: width, height: 20)
    }

}

struct PlaylistsAndQueueTabHeader_Previews: PreviewProvider {
    
    @State static var selectedTab = 0

    static var previews: some View {
        PlaylistsAndQueueTabHeader(selectedTab: $selectedTab)
            .padding(20)
    }
}
