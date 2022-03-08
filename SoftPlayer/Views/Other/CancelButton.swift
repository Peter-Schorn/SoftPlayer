import SwiftUI

struct CancelButton: View {
    
    @Environment(\.colorScheme) var colorScheme

    let action: () -> Void
    
    var lineColor: Color {
        colorScheme == .dark ?
            Color(red: 0.7133214474, green: 0.7134256959, blue: 0.7132986188) :
            Color(red: 0.1628836989, green: 0.162913233, blue: 0.1628772318)
    }

    var circleColor: Color {
        colorScheme == .dark ?
            Color(red: 0.2190969288, green: 0.2191341221, blue: 0.2190887928) :
            Color(red: 0.9214980006, green: 0.9216085076, blue: 0.9214602709)
    }

    var body: some View {
        Button(action: action, label: {
            ZStack {
                Circle()
                    .fill(circleColor)
                XShape()
                    .fill(lineColor)
                    .frame(width: 7, height: 7)
                
            }
        })
        .buttonStyle(PlainButtonStyle())
        .shadow(radius: 3)
        .frame(width: 15, height: 15)
    }
    
}

struct CancelButton_Previews: PreviewProvider {
    static var previews: some View {
        CancelButton(action: { })
            .padding(20)
            .background(
                Rectangle().fill(BackgroundStyle())
            )
    }
}
