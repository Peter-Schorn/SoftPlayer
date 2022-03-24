import SwiftUI

struct SavedTracksImage: View {
    
    let gradient = LinearGradient(
        gradient: Gradient(
            stops: [
                .init(color: Color(hex: 0x3A16B2), location: 0),
                .init(color: Color(hex: 0x605998), location: 0.5),
                .init(color: Color(hex: 0x809188), location: 1)
            ]
        ),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            Rectangle()
                .fill(gradient)
            HeartShape()
                .scale(0.5)
                .fill(.white)
                .shadow(radius: 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct SavedTracksImage_Previews: PreviewProvider {
    static var previews: some View {
        withAllColorSchemes {
            SavedTracksImage()
                .previewLayout(.sizeThatFits)
        }
    }
}
