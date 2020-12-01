import Foundation
import SpotifyWebAPI
import Combine
import SwiftUI

extension View {
    
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }

}

extension DateComponentsFormatter {
    
    static let playbackTimeWithHours: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    static let playbackTime: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    

}


extension Comparable {
    
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(range.upperBound, max(range.lowerBound, self))
    }

}

extension CGFloat {
    
    func map(
        from old: ClosedRange<CGFloat>,
        to new: ClosedRange<CGFloat>
    ) -> CGFloat {
        let oldMagnitude = old.upperBound - old.lowerBound
        let newPercent = (self - old.lowerBound) / oldMagnitude
        return newPercent * (new.upperBound - new.lowerBound) + new.lowerBound
    }
}



//extension Publisher {
//
//    func handleSpotifyAuthenticationError() -> AnyPublisher<Output, Failure> {
//        return self.handleEvents(receiveCompletion: { completion in
//            guard case .failure(let error) = completion else {
//                return
//            }
//            if let authenticationError = error as? SpotifyAuthenticationError {
//
//            }
//
//        })
//        .eraseToAnyPublisher()
//    }
//
//}
