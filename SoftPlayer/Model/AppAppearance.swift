import Foundation
import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String {
        self.rawValue
    }

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

extension ColorScheme {
    
    init?(nsAppearance: NSAppearance) {
        switch nsAppearance.name {
            case .aqua:
                self = .light
            case .darkAqua:
                self = .dark
            default:
                return nil
        }
    }

}
