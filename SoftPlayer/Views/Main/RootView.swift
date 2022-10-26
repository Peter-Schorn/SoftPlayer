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
            spotify.redirectURLSubject,
            perform: handleRedirectURL(_:)
        )
        .preferredColorScheme(playerManager.colorScheme)
        
    }
    
    // MARK: Handle Redirect

    func handleRedirectURL(_ url: URL) {

        Loggers.general.trace("LoginView received redirect URL: \(url)")

        // peter-schorn-soft-player://login-callback

        guard url.scheme == self.spotify.loginCallbackURL.scheme,
              url.host == self.spotify.loginCallbackURL.host else {
                  
            self.showAlert(
                title: NSLocalizedString(
                    "Unexpected URL",
                    comment: ""
                ),
                message: NSLocalizedString(
                    "This URL could not be handled.",
                    comment: ""
                )
            )
                    
            return
        }

        if self.spotify.isAuthorized {
            self.showAlert(
                title: NSLocalizedString(
                    "Your Spotify Account is Already Connected",
                    comment: ""
                ),
                message: NSLocalizedString(
                    """
                    If you would like to use another account, please log out \
                    first.
                    """,
                    comment: ""
                )
            )
            return
        }

        AppDelegate.shared.openPopover()

        self.spotify.isRetrievingTokens = true
        
        self.requestTokensCancellable = self.spotify.api.authorizationManager
            .requestAccessAndRefreshTokens(
                redirectURIWithQuery: url,
                codeVerifier: self.spotify.codeVerifier,
                state: self.spotify.authorizationState
            )
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: receiveRequestTokensCompletion(_:))
        
        self.spotify.generateNewAuthorizationParameters()

    }
    
    func receiveRequestTokensCompletion(
        _ completion: Subscribers.Completion<Error>
    ) {
        Loggers.general.trace("request tokens completion: \(completion)")
        self.spotify.isRetrievingTokens = false

        let alert = NSAlert()
        let alertTitle: String
        let alertMessage: String
        
        switch completion {
            case .finished:
                alertTitle = NSLocalizedString(
                    "Successfully Connected to Your Spotify Account",
                    comment: ""
                )
                alertMessage = NSLocalizedString(
                    "You may close the authorization page in your browser.",
                    comment: ""
                )
                alert.alertStyle = .informational
            case .failure(let error):
                alert.alertStyle = .warning
                alertTitle = NSLocalizedString(
                    "Could not Authorize with your Spotify Account",
                    comment: ""
                )
                if let authError = error as? SpotifyAuthorizationError,
                   authError.accessWasDenied {
                    alertMessage = NSLocalizedString(
                        "You denied the Authorization Request :(",
                        comment: ""
                    )
                }
                else {
                    alertMessage = error.customizedLocalizedDescription
                }
        }

        alert.messageText = alertTitle
        alert.informativeText = alertMessage
        alert.runModal()
        
    }
    
    func showAlert(
        title: String,
        message: String
    ) {
        
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()

    }
}

struct RootView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(
        spotify: Spotify(),
        viewContext: AppDelegate.shared.persistentContainer.viewContext
    )
    
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
