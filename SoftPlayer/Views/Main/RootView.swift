import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI

struct RootView: View {
 
    fileprivate static var debugShowLoginView = false
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager

    @State private var requestTokensCancellable: AnyCancellable? = nil
    
    // MARK: Begin View

    var body: some View {
        VStack {
            if spotify.isAuthorized && !Self.debugShowLoginView {
                PlayerView()
            }
            else {
                LoginView()
            }
        }
        .frame(
            width: CGFloat(AppDelegate.popoverWidth),
            height: CGFloat(AppDelegate.popoverHeight)
        )
        .onReceive(
            spotify.redirectURLSubject
        ) { url in
            if playerManager.popoverisOpen {
                playerManager.handleRedirectURL(url)
            }
        }
        .preferredColorScheme(playerManager.colorScheme)
        
    }
}

struct RootView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())
    
    static var previews: some View {

        Self.withAllColorSchemes {
            RootView()
                .environmentObject(playerManager)
                .environmentObject(playerManager.spotify)
                .onAppear(perform: onAppear)
                .frame(
                    width: CGFloat(AppDelegate.popoverWidth),
                    height: CGFloat(AppDelegate.popoverHeight)
                )
        }
    }
    
    static func onAppear() {
//        RootView.debugShowLoginView = true
//        playerManager.spotify.isAuthorized = true
//        playerManager.spotify.isRetrievingTokens = false
    }
}
