//
//  CDAlbum+CoreDataProperties.swift
//  Soft Player
//
//  Created by Peter Schorn on 10/26/22.
//
//

import Foundation
import CoreData


extension CDAlbum {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAlbum> {
        return NSFetchRequest<CDAlbum>(entityName: "CDAlbum")
    }

    @NSManaged public var name: String?
    @NSManaged public var uri: String?
    @NSManaged public var items: NSSet?

    var itemsSet: Set<CDPlaylistItem> {
        self.items as? Set<CDPlaylistItem> ?? []
    }

}

// MARK: Generated accessors for items
extension CDAlbum {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: CDPlaylistItem)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: CDPlaylistItem)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}

extension CDAlbum : Identifiable {

}
