import Foundation
import SwiftUI

struct NotificationView: View {
    
    fileprivate static var debugIsShowingNotification = false

    @EnvironmentObject var playerManager: PlayerManager

    @State private var isShowingNotification = false
    @State fileprivate var notificationMessage = ""
//        "Evolution is the unifying theory of the life sciences"

    var body: some View {
        VStack {
            if isShowingNotification || Self.debugIsShowingNotification {
                Text(notificationMessage)
                    .font(.callout)
                    .frame(maxWidth: .infinity)
                    .padding(5)
                    .background(
                        VisualEffectView(
                            material: .popover,
                            blendingMode: .withinWindow
                        )
                    )
                    .cornerRadius(5)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .shadow(radius: 5)
                    .transition(.move(edge: .top))
            }
            Spacer()
        }
        .onReceive(playerManager.alertSubject) { message in
            self.notificationMessage = message
            withAnimation() {
                self.isShowingNotification = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation() {
                    self.isShowingNotification = false
                }
            }
            
        }

    }
}

struct NotificationView_Previews: PreviewProvider {
    
    static var previews: some View {
        PlayerView_Previews.previews
            .onAppear(perform: onAppear)
    }
    
    static func onAppear() {
        NotificationView.debugIsShowingNotification = true
    }

}
