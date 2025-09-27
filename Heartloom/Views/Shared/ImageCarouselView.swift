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
                    .clipped()
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }
}
