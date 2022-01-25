import SwiftUI

struct SharingServicesMenu: View {
    
    @FocusState var focus

    /// The items to share
    let items: [Any]

    init(items: [Any]) {
        self.items = items
    }

    init(item: Any) {
        self.items = [item]
    }

    var body: some View {
        Menu {
            ForEach(
                NSSharingService.sharingServices(
                    forItems: items
                ),
                id: \.title
            ) { service in
                Button {
                    service.perform(withItems: items)
                } label: {
                    HStack {
                        Image(nsImage: service.image)
                        Text(service.title)
                    }
                }

            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .menuStyle(BorderlessButtonMenuStyle())
    }

}
