//
//  CDPlaylistItem+CoreDataProperties.swift
//  Soft Player
//
//  Created by Peter Schorn on 10/26/22.
//
//

import Foundation
import CoreData
import SpotifyWebAPI

extension CDPlaylistItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDPlaylistItem> {
        return NSFetchRequest<CDPlaylistItem>(entityName: "CDPlaylistItem")
    }

    @NSManaged public var name: String?
    @NSManaged public var uri: String?
    @NSManaged public var playlist: CDPlaylist?
    @NSManaged public var album: CDAlbum?
    
    var spotifyIdentifier: SpotifyIdentifier? {
        self.uri.flatMap { try? SpotifyIdentifier(uri: $0) }
    }

}

extension CDPlaylistItem : Identifiable {

}
