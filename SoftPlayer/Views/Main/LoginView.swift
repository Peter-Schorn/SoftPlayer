import Foundation
import SwiftUI
import Combine
import SpotifyWebAPI

/**
 A view that presents a button to login with Spotify.
 
 It is presented when `isAuthorized` is `false`.
 
 When the user taps the button, the authorization URL is opened in the browser,
 which prompts them to login with their Spotify account and authorize this
 application.
 
 After Spotify redirects back to this app and the access and refresh
 tokens have been retrieved, dismiss this view by setting `isAuthorized`
 to `true`.
 */
struct LoginView: View {

    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var spotify: Spotify

    @State private var requestTokensCancellable: AnyCancellable? = nil
    
    let backgroundGradient = LinearGradient(
        gradient: Gradient(
            colors: [Color(#colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)), Color(#colorLiteral(red: 0.1903857588, green: 0.8321116255, blue: 0.4365008013, alpha: 1))]
        ),
        startPoint: .leading, endPoint: .trailing
    )
    
    var spotifyLogo: ImageName {
        colorScheme == .dark ? .spotifyLogoWhite
                : .spotifyLogoBlack
    }
    
    var body: some View {
        VStack {

            loginButton
            
            if spotify.isRetrievingTokens {
                HStack {
                    ProgressView()
                        .scaleEffect(0.5)
                    Text("Authenticating")
                }
            }
        }
        .background(FocusView(isFirstResponder: .constant(true)))
        
    }
    
    var loginButton: some View {
        
        Button(action: self.spotify.authorize, label: {
            HStack {
                Image(spotifyLogo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 60)
                Text("Log in with Spotify")
                    .font(.title2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 15)
            .background(backgroundGradient)
            .clipShape(Capsule())
            .shadow(radius: 5)
        })
        .buttonStyle(PlainButtonStyle())
        .allowsHitTesting(!spotify.isRetrievingTokens)
        .padding(5)


    }

}

struct LoginView_Previews: PreviewProvider {
    
    static let spotify = Spotify()
    
    static let locales: [Locale] = [
        .init(identifier: "es"),
        .init(identifier: "en")
    ]

    static var previews: some View {
        
        ForEach(locales, id: \.self) { locale in
            LoginView()
                .onAppear(perform: onAppear)
                .frame(
                    width: CGFloat(AppDelegate.popoverWidth),
                    height: CGFloat(AppDelegate.popoverHeight)
                )
                .environmentObject(spotify)
                .environment(\.locale, locale)
        }
        
    }
    
    static func onAppear() {
        spotify.isRetrievingTokens = true
    }
    
}
