import Foundation
import Combine
import AppKit
import SwiftUI
import KeychainAccess
import SpotifyWebAPI

/**
 A helper class that wraps around an instance of `SpotifyAPI`
 and provides convenience methods for authorizing your application.
 
 Its most important role is to handle changes to the authorization
 information and save them to persistent storage in the keychain.
 */
final class Spotify: ObservableObject {
    
    private static let clientId: String = {
        
        if let clientId = ProcessInfo.processInfo.environment["CLIENT_ID"] {
            return clientId
        }

        let __clientId__ = "f9b05de1274c4851a2293a540cb8705e"
        if __clientId__.isEmpty {
            fatalError(
                "failed to inject value for client id in pre-build script"
            )
        }
        return __clientId__
    }()
    
    private static let tokensURL: URL = {
       
        let __tokensURL__ = "https://spotify-now-backend.herokuapp.com/authorization-code-flow-pkce/retrieve-tokens"
        if __tokensURL__.isEmpty {
            fatalError(
                "failed to inject value for tokens URL in pre-build script"
            )
        }
        if let url = URL(string: __tokensURL__) {
            return url
        }
        fatalError("could not convert to URL: '\(__tokensURL__)'")

    }()
    
    private static let tokensRefreshURL: URL = {
        
        let __tokensRefreshURL__ = "https://spotify-now-backend.herokuapp.com/authorization-code-flow-pkce/refresh-tokens"
        if __tokensRefreshURL__.isEmpty {
            fatalError(
                "failed to inject value for tokens refresh URL in pre-build script"
            )
        }
        if let url = URL(string: __tokensRefreshURL__) {
            return url
        }
        fatalError("could not convert to URL: '\(__tokensRefreshURL__)'")
        
    }()
    

    
    /// The key in the keychain that is used to store the authorization
    /// information: "authorizationManager".
    let authorizationManagerKey = "authorizationManager"
    
    /// The URL that Spotify will redirect to after the user either
    /// authorizes or denies authorization for your application.
    let loginCallbackURL: URL
    
    // MARK: Authorization Parameters
    /// A cryptographically-secure random string used to ensure
    /// than an incoming redirect from Spotify was the result of a request
    /// made by this app, and not an attacker. **This value is regenerated**
    /// **after each authorization process completes.**
    var authorizationState: String
    var codeVerifier: String
    var codeChallenge: String
    
    let redirectURLSubject = PassthroughSubject<URL, Never>()
    
    /**
     Whether or not the application has been authorized. If `true`,
     then you can begin making requests to the Spotify web API
     using the `api` property of this class, which contains an instance
     of `SpotifyAPI`.
     
     When `false`, `LoginView` is presented, which prompts the user to
     login. When this is set to `true`, `LoginView` is dismissed.
     
     This property provides a convenient way for the user interface
     to be updated based on whether the user has logged in with their
     Spotify account yet. For example, you could use this property disable
     UI elements that require the user to be logged in.
     
     This property is updated by `authorizationManagerDidChange()`,
     which is called every time the authorization information changes,
     and `authorizationManagerDidDeauthorize()`, which is called
     every time `SpotifyAPI.authorizationManager.deauthorize()` is called.
     */
    @Published var isAuthorized = false

    /// If `true`, then the app is retrieving access and refresh tokens.
    /// Used by `LoginView` to present an activity indicator.
    @Published var isRetrievingTokens = false
    
    /// The keychain to store the authorization information in.
    let keychain = Keychain(service: "com.Peter-Schorn.MusicNow")
    
    let api = SpotifyAPI(
        authorizationManager: AuthorizationCodeFlowPKCEBackendManager(
            backend: AuthorizationCodeFlowPKCEProxyBackend(
                clientId: Spotify.clientId,
                tokensURL: Spotify.tokensURL,
                tokenRefreshURL: Spotify.tokensRefreshURL
            )
        )
    )
    
    var cancellables: Set<AnyCancellable> = []
    
    init() {
        
//        self.api.apiRequestLogger.logLevel = .trace
        
//        self.api.setupDebugging()
        
        self.codeVerifier = String.randomURLSafe(length: 128)
        self.codeChallenge = String.makeCodeChallenge(
            codeVerifier: self.codeVerifier
        )
        self.authorizationState = String.randomURLSafe(length: 128)
        
        let urlTypes = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleURLTypes"
        ) as! [[String: Any]]
        let urlScheme = (urlTypes[0]["CFBundleURLSchemes"] as! [String])[0]
        
        do {
            var components = URLComponents()
            components.scheme = urlScheme
            components.host = "login-callback"
            guard let url = components.url else {
                fatalError("could not convert to URL: \(components)")
            }
            self.loginCallbackURL = url
        }

        // MARK: Important: Subscribe to `authorizationManagerDidChange` BEFORE
        // MARK: retrieving `authorizationManager` from persistent storage
        self.api.authorizationManagerDidChange
            // We must receive on the main thread because we are
            // updating the @Published `isAuthorized` property.
            .receive(on: RunLoop.main)
            .sink(receiveValue: authorizationManagerDidChange)
            .store(in: &cancellables)
        
        self.api.authorizationManagerDidDeauthorize
            .receive(on: RunLoop.main)
            .sink(receiveValue: authorizationManagerDidDeauthorize)
            .store(in: &cancellables)
        
        // Check to see if the authorization information is saved in
        // the keychain.
        if let authManagerData = keychain[data: authorizationManagerKey] {

            do {
                // Try to decode the data.
                let authorizationManager = try JSONDecoder().decode(
                    AuthorizationCodeFlowPKCEBackendManager<AuthorizationCodeFlowPKCEProxyBackend>.self,
                    from: authManagerData
                )
                Loggers.spotify.trace(
                    "found authorization information in keychain"
                )

                /*
                 This assignment causes `authorizationManagerDidChange`
                 to emit a signal, meaning that
                 `authorizationManagerDidChange()` will be called.

                 Note that if you had subscribed to
                 `authorizationManagerDidChange` after this line,
                 then `authorizationManagerDidChange()` would not
                 have been called and the @Published `isAuthorized` property
                 would not have been properly updated.

                 We do not need to update `isAuthorized` here because it
                 is already done in `authorizationManagerDidChange()`.
                 */
                self.api.authorizationManager = authorizationManager

                // MARK: DEBUG
//                self.api.authorizationManager.setExpirationDate(to: Date())
//                self.api.authorizationManager.deauthorize()

            } catch {
                Loggers.spotify.error(
                    "could not decode authorizationManager from data:\n\(error)"
                )
            }
        }
        else {
            Loggers.spotify.notice(
                "did NOT find authorization information in keychain"
            )
        }
        
    }
    
    /**
     A convenience method that creates the authorization URL and opens it
     in the browser.
     
     You could also configure it to accept parameters for the authorization
     scopes.
     
     This is called when the user taps the "Log in with Spotify" button
     in `LoginView`.
     */
    func authorize() {

        guard let url = self.api.authorizationManager.makeAuthorizationURL(
            redirectURI: loginCallbackURL,
            codeChallenge: codeChallenge,
            state: authorizationState,
            scopes: [
                .userReadPlaybackState,
                .userModifyPlaybackState,
                .playlistReadPrivate,
                .playlistReadCollaborative,
                .playlistModifyPublic,
                .playlistModifyPrivate
            ]
        ) else {
            fatalError("could not create authorization URL")
        }
        
        AppDelegate.shared.closePopover()
        NSWorkspace.shared.open(url)
        
    }
    
    /// Generates new values for the code verifier, code challenge,
    /// and authorization state.
    func generateNewAuthorizationParameters() {
        self.codeVerifier = String.randomURLSafe(length: 128)
        self.codeChallenge = String.makeCodeChallenge(
            codeVerifier: self.codeVerifier
        )
        self.authorizationState = String.randomURLSafe(length: 128)
    }
    
    /**
     Saves changes to `api.authorizationManager` to the keychain.
     
     This method is called every time the authorization information changes. For
     example, when the access token gets automatically refreshed, (it expires after
     an hour) this method will be called.
     
     It will also be called after the access and refresh tokens are retrieved using
     `requestAccessAndRefreshTokens(redirectURIWithQuery:state:)`.
     
     Read the full documentation for [SpotifyAPI.authorizationManagerDidChange][1].
     
     [1]: https://peter-schorn.github.io/SpotifyAPI/Classes/SpotifyAPI.html#/s:13SpotifyWebAPI0aC0C29authorizationManagerDidChange7Combine18PassthroughSubjectCyyts5NeverOGvp
     */
    func authorizationManagerDidChange() {
        
        // Update the @Published `isAuthorized` property.
        // When set to `true`, `LoginView` is dismissed, allowing the
        // user to interact with the rest of the app.
        self.isAuthorized = self.api.authorizationManager.isAuthorized()
        
        do {
            // Encode the authorization information to data.
            let authManagerData = try JSONEncoder().encode(
                self.api.authorizationManager
            )

            // Save the data to the keychain.
            keychain[data: authorizationManagerKey] = authManagerData

        } catch {
            Loggers.spotify.error(
                """
                couldn't encode authorizationManager for storage in keychain:
                \(error)
                """
            )
        }
        
    }
 
    /**
     Removes `api.authorizationManager` from the keychain.
     
     This method is called every time `api.authorizationManager.deauthorize` is
     called.
     */
    func authorizationManagerDidDeauthorize() {
        
        withAnimation {
            self.isAuthorized = false
        }

        do {
            /*
             Remove the authorization information from the keychain.

             If you don't do this, then the authorization information
             that you just removed from memory by calling `deauthorize()`
             will be retrieved again from persistent storage after this
             app is quit and relaunched.
             */
            try keychain.remove(authorizationManagerKey)

        } catch {
            Loggers.spotify.error(
                "couldn't remove authorization manager from keychain: \(error)"
            )
        }
    }
    
}
