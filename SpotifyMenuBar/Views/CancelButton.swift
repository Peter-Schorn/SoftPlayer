import SwiftUI

struct CancelButton: View {
    
    @Environment(\.colorScheme) var colorScheme

    let action: () -> Void
    
    var body: some View {
        ZStack {
            Button(action: action, label: {
                Circle()
                    .fill(Color(colorScheme == .dark ? #colorLiteral(red: 0.2190969288, green: 0.2191341221, blue: 0.2190887928, alpha: 1) : #colorLiteral(red: 0.9214980006, green: 0.9216085076, blue: 0.9214602709, alpha: 1)))
            })
            .buttonStyle(PlainButtonStyle())
            .shadow(radius: 3)
            Capsule()
                .rotation(.degrees(45))
                .fill(Color(colorScheme == .dark ? #colorLiteral(red: 0.7133214474, green: 0.7134256959, blue: 0.7132986188, alpha: 1) : #colorLiteral(red: 0.1628836989, green: 0.162913233, blue: 0.1628772318, alpha: 1)))
                .frame(width: 1, height: 10)
            Capsule()
                .rotation(.degrees(-45))
                .fill(Color(colorScheme == .dark ? #colorLiteral(red: 0.7133214474, green: 0.7134256959, blue: 0.7132986188, alpha: 1) : #colorLiteral(red: 0.1628836989, green: 0.162913233, blue: 0.1628772318, alpha: 1)))
                .frame(width: 1, height: 10)
                
        }
        .frame(width: 15, height: 15)
    }
    
}

struct CancelButton_Previews: PreviewProvider {
    static var previews: some View {
        CancelButton(action: { })
            .padding(20)
            .background(Rectangle().fill(BackgroundStyle()))
    }
}
