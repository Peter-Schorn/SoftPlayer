import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI
import KeyboardShortcuts

struct PlayerView: View {

    static var debugIsShowingLibraryView = false
    
    static let animation = Animation.easeOut(duration: 0.5)
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    @Environment(\.colorScheme) var colorScheme
    
    @Namespace var namespace
    
    
    @State private var cancellables: Set<AnyCancellable> = []

    // MARK: DEBUG
    
//    let trackTitle = "Tabu"
//    let albumArtistTitle = "Gustavo Cerati - Bocanada"

    var body: some View {
        ZStack(alignment: .top) {
            if playerManager.isShowingLibraryView
                || Self.debugIsShowingLibraryView {
                VStack(spacing: 0) {
                    
                    miniPlayerViewBackground
                    
                    LibraryView()
                    
                }
                .background(
                    Rectangle()
                        .fill(BackgroundStyle())
                )
                // MARK: Library View Transition
                .transition(.move(edge: .bottom))
                .onExitCommand {
                    self.playerManager.dismissLibraryView(animated: true)
                }
                .onReceive(playerManager.popoverDidClose) {
                    self.playerManager.dismissLibraryView(animated: false)
                }
                
                MiniPlayerView(namespace: namespace)
                
            }
            else {
                LargePlayerView(namespace: namespace)
            }
        }
        .overlay(NotificationView())
        .frame(
            width: AppDelegate.popoverWidth,
            height: AppDelegate.popoverHeight
        )
        .onExitCommand {
            if self.playerManager.isShowingLibraryView {
                self.playerManager.dismissLibraryView(animated: true)
            }
            else {
                AppDelegate.shared.closePopover()
            }
        }
        
    }

    var miniPlayerViewBackground: some View {
        VStack {
            HStack {
                Button(action: {
                    self.playerManager.dismissLibraryView(animated: true)
                }, label: {
                    Image(systemName: "chevron.down")
                        .padding(-3)
                })
                .padding(3)
                
                Spacer()

                LibrarySegmentedControl()

            }
            .padding(.horizontal, 5)
            .padding(.top, 7)
            
            Spacer()
                .frame(height: 87)
        }
        .frame(maxWidth: .infinity)
        .background(
            Rectangle()
                .fill(BackgroundStyle())
                .adaptiveShadow(radius: 3, y: 2)
        )
        
    }

}

struct PlayerView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())
    static let playerManager2 = PlayerManager(spotify: Spotify())
    
    static var previews: some View {
//        Self.withAllColorSchemes {
        PlayerView()
            .environmentObject(playerManager.spotify)
            .environmentObject(playerManager)
            .frame(
                width: AppDelegate.popoverWidth,
                height: AppDelegate.popoverHeight
            )
            .onAppear(perform: onAppear)
        
        PlayerView()
            .environmentObject(playerManager2.spotify)
            .environmentObject(playerManager2)
            .frame(
                width: AppDelegate.popoverWidth,
                height: AppDelegate.popoverHeight
            )
            .onAppear(perform: onAppear)

//        }
    }
    
    static func onAppear() {
        playerManager2.isShowingLibraryView = true
    }
    
}
