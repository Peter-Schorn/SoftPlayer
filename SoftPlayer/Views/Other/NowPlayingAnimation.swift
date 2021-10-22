import SwiftUI
import Foundation

struct NowPlayingAnimation: View {
    
    @State private var rectangleSize: CGFloat = 0.2

    private let animation = Animation
        .linear(duration: 1)
        .repeatForever()

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<3) { i in
                barView
                    .onAppear {
                        let delayedAnimation = self.animation
                            .delay(Double(i) * 1)
                        withAnimation(delayedAnimation) {
                            self.rectangleSize = 1
                        }
                    }
            }
        }
    }
    
    var barView: some View {
         GeometryReader.init { geometry in
            VStack {
                Spacer()
                    .frame(height: geometry.size.height * (1 - rectangleSize))
                Rectangle()
                    .fill(Color.green)
                    .frame(
                        height: geometry.size.height * rectangleSize
                        ,alignment: .top
                    )
    //                .scaleEffect(
    //                    CGSize(width: 1, height: rectangleHeight),
    //                    anchor: .bottom
    //                )
    //                .transition(.scale)
                    
            }
        }
        .frame(width: 10)
    }

}

struct NowPlayingAnimation_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        PlaylistCellView(playlist: .rockClassics, isSelected: false)
            .frame(width: AppDelegate.popoverWidth)
            .overlay(
                HStack {
                    Spacer()
                    NowPlayingAnimation()
                }
            )
            .environmentObject(playerManager.spotify)
            .environmentObject(playerManager)
    }
}
