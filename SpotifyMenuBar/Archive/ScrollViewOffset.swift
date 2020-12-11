import SwiftUI

// credit: https://github.com/zntfdr/FiveStarsCodeSamples/blob/main/ScrollView-Offset/ScrollViewOffset.swift
// see also https://fivestars.blog/swiftui/scrollview-offset.html

struct ScrollViewOffset<Content: View>: View {
    
    @Binding var offset: CGFloat
    let content: () -> Content
    
    init(
        offset: Binding<CGFloat>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._offset = offset
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            offsetReader
            content()
                .padding(.top, -8)
        }
        .coordinateSpace(name: "frameLayer")
        .onPreferenceChange(OffsetPreferenceKey.self) { offset in
            print("offset: \(offset)")
            self.offset = offset
        }
    }
    
    var offsetReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: OffsetPreferenceKey.self,
                    value: proxy.frame(in: .named("frameLayer")).minY
                )
        }
        .frame(height: 0)
    }
}

private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {}
}
