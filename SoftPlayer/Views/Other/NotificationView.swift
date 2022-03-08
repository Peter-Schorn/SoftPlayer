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

    let presentAnimation = Animation.spring(
        response: 0.5,
        dampingFraction: 0.9,
        blendDuration: 0
    )

    var body: some View {
        
        VStack {
            if isPresented || Self.debugIsPresented {
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
                    .onHover { isHovering in
                        withAnimation(.easeOut(duration: 0.1)) {
                            self.cancelButtonIsShowing = isHovering
                        }
                    }
                    .overlay(
                        Group {
                            if self.cancelButtonIsShowing {
                                CancelButton(action: {
                                    withAnimation {
                                        self.isPresented = false
                                    }
                                })
                                .padding(5)
                                .contentShape(Rectangle())
                                .transition(.scale)
                            }
                        },
                        alignment: .topLeading
                    )
                    .transition(.move(edge: .top))
                
                Spacer()
            }
        }
        .onReceive(
            playerManager.notificationSubject,
            perform: recieveAlert(_:)
        )
        
    }
    
    func recieveAlert(_ alert: AlertItem) {
        
        let id = UUID()
        self.messageId = id

        self.title = alert.title
        self.message = alert.message

        withAnimation(self.presentAnimation) {
            self.isPresented = true
        }

        let delay: Double = message.isEmpty ? 2 : 3
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if self.messageId == id {
                withAnimation(self.presentAnimation) {
                    self.isPresented = false
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
