//
//  CDPlaylist+CoreDataProperties.swift
//  Soft Player
//
//  Created by Peter Schorn on 10/25/22.
//
//

import Foundation
import CoreData


extension CDPlaylist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDPlaylist> {
        return NSFetchRequest<CDPlaylist>(entityName: "CDPlaylist")
    }

    @NSManaged public var name: String?
    @NSManaged public var uri: String?
    @NSManaged public var items: NSSet?
    
    var itemsSet: Set<CDPlaylistItem> {
        self.items as? Set<CDPlaylistItem> ?? []
    }

}

// MARK: Generated accessors for items
extension CDPlaylist {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: CDPlaylistItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: CDPlaylistItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}

extension CDPlaylist : Identifiable {

}
