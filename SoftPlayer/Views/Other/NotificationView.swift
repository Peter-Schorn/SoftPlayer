import Foundation
import SwiftUI

struct NotificationView: View {
    
    fileprivate static var debugIsPresented = false
    
    @EnvironmentObject var playerManager: PlayerManager
    
    @State private var isPresented = false
    @State private var title = ""
    @State private var message = ""

    @State private var messageId = UUID()

    @State private var cancelButtonIsShowing = false

    var body: some View {
        
        VStack {
            if isPresented || Self.debugIsPresented {
                ZStack(alignment: .topLeading) {
                    VStack {
                        Text(title)
                            .fontWeight(.medium)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 5)
                        if !message.isEmpty {
                            Text(message)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(7)
                    .background(
                        VisualEffectView(
                            material: .popover,
                            blendingMode: .withinWindow
                        )
                    )
                    .cornerRadius(5)
                    .padding(10)
                    .shadow(radius: 5)
                    
                    CancelButton(action: {
                        withAnimation {
                            self.isPresented = false
                        }
                    })
                    .padding(5)
                    .contentShape(Rectangle())
                    .onHover { isHovering in
                        withAnimation(.linear(duration: 0.2)) {
                            self.cancelButtonIsShowing = isHovering
                        }
                    }
                    .opacity(cancelButtonIsShowing ? 1 : 0)
                    
                }
                .transition(.move(edge: .top))
                
                Spacer()
            }
        }
        .onReceive(playerManager.notificationSubject) { alert in
    
            let id = UUID()
            self.messageId = id

            withAnimation {
                self.title = alert.title
                self.message = alert.message
                self.isPresented = true
            }

            let delay: Double = message.isEmpty ? 2 : 3
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if self.messageId == id {
                    withAnimation() {
                        self.isPresented = false
                    }
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
        NotificationView.debugIsPresented = true
    }
    
}
