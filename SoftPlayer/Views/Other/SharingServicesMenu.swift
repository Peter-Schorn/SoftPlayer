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

    func makeCopyLinkService() -> NSSharingService {
        return NSSharingService(
            title: "Copy Link",
            image: NSImage(
                systemSymbolName: "doc.on.doc.fill",
                accessibilityDescription: nil
            )!,
            alternateImage: nil,
            handler: {
                guard let item = self.items.first else {
                    return
                }
                guard let url = item as? URL else {
                    return
                }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url.absoluteString, forType: .URL)
            }
        )
    }
    
    func sharingServices() -> [NSSharingService] {
        var services = NSSharingService.sharingServices(
            forItems: self.items
        )
        let copyLinkService = self.makeCopyLinkService()
        services.insert(copyLinkService, at: 0)
        return services
    }

    var body: some View {
        Menu {
            ForEach(
                sharingServices(),
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
