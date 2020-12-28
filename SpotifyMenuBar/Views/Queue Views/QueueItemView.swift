import SwiftUI
import SpotifyWebAPI

struct QueueItemView: View {
    let item: PlaylistItem
    
    var body: some View {
        VStack {
            HStack {
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(1)
                Spacer()
            }
            if let name = item.artistOrShowName {
                HStack {
                    Text(name)
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .fixedSize()
        .padding(.vertical, 2)
    }
}

struct QueueItemView_Previews: PreviewProvider {
    static var previews: some View {
        
        QueueItemView(item: .track(.because))
            .border(Color.primary)
            .padding()

        QueueView_Previews.previews
    }
}
