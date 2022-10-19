import Foundation
import SwiftUI

struct QueueImage {
    
    let image: Image
    var lastAccessed: Date

    init(_ image: Image, lastAccessed: Date = Date()) {
        self.image = image
        self.lastAccessed = lastAccessed
    }

}
