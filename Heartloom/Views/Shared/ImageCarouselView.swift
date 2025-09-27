import SwiftUI
import UIKit

struct ImageCarouselView: View {
    let images: [UIImage]
    var body: some View {
        TabView {
            ForEach(Array(images.enumerated()), id: \.offset) { pair in
                Image(uiImage: pair.element)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(
                        LinearGradient(colors: [Color.black.opacity(0.05), Color.black.opacity(0.35)], startPoint: .top, endPoint: .bottom)
                            .blendMode(.overlay)
                    )
                    .clipped()
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(LinearGradient(colors: [Color.white.opacity(0.25), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }
}
