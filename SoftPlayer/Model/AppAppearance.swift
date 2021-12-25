import Foundation
import SwiftUI

enum AppAppearance: String, CaseIterable {
    
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var colorScheme: ColorScheme? {
        switch self {
            case .system:
                return nil
            case .light:
                return .light
            case .dark:
                return .dark
        }
    }
    
    var nsAppearance: NSAppearance? {
        switch self {
            case .system:
                return nil
            case .light:
                return NSAppearance(named: .aqua)
            case .dark:
                return NSAppearance(named: .darkAqua)
        }
    }
    
    var localizedDescription: String {
        return NSLocalizedString(
            self.rawValue,
            comment: "AppAppearance.rawValue"
        )
    }
    
}
