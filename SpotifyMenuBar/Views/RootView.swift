import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI

struct RootView: View {
 
    fileprivate static var debugShowLoginView = false
    
    @EnvironmentObject var spotify: Spotify

    @State private var alertIsPresented = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @State private var requestTokensCancellable: AnyCancellable? = nil
    
    var body: some View {
        VStack {
            if spotify.isAuthorized && !Self.debugShowLoginView {
                PlayerView()
//                PlaylistsView(isPresented: .constant(true))
            }
            else {
                LoginView()
            }
        }
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
        }
        .onReceive(
            spotify.redirectURLSubject,
            perform: handleRedirectURL(_:)
        )
        
    }
    
    func handleRedirectURL(_ url: URL) {

        print("LoginView received redirect URL:", url)
        
        spotify.isRetrievingTokens = true
        
        self.requestTokensCancellable = spotify.api.authorizationManager
            .requestAccessAndRefreshTokens(
                redirectURIWithQuery: url,
                codeVerifier: spotify.codeVerifier,
                state: spotify.authorizationState
            )
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: receiveRequestTokensCompletion(_:))
        
        spotify.generateNewAuthorizationParameters()

    }
    
    func receiveRequestTokensCompletion(
        _ completion: Subscribers.Completion<Error>
    ) {
        print("request tokens completion:", completion)
        spotify.isRetrievingTokens = false
        switch completion {
            case .finished:
                self.alertTitle =
                        "Sucessfully connected to your Spotify account"
            case .failure(let error):
                self.alertTitle =
                        "Could not Authorize with your Spotify account"
                
                if let authError = error as? SpotifyAuthorizationError,
                   authError.accessWasDenied {
                    self.alertMessage =
                        "You denied the authorization request (:"
                }
                else {
                    self.alertMessage = error.localizedDescription
                }
        }
        print("\n\nself.alertIsPresented = true\n\n")
        self.alertIsPresented = true
    }
    
}

struct RootView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())
    
    static var previews: some View {

        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            RootView()
                .preferredColorScheme(colorScheme)
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
        playerManager.spotify.isAuthorized = true
//        playerManager.spotify.isRetrievingTokens = false
    }
}
