import SwiftUI

/// Фото букета 4:5 — основа всех карточек ленты.
/// Пока грузится, на его месте живёт скелетон того же размера,
/// поэтому лента не дёргается при появлении картинок.
struct BouquetPhoto: View {
    let url: URL
    var parallax = true

    var body: some View {
        Color.clear
            .aspectRatio(DS.Size.photoAspectRatio, contentMode: .fit)
            .overlay {
                AsyncImage(
                    url: url,
                    transaction: Transaction(animation: DS.Motion.spring)
                ) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(parallax ? DS.Motion.parallaxOverscan : 1)
                            .visualEffect { content, proxy in
                                content.offset(y: parallax ? Self.shift(proxy) : 0)
                            }
                    case .failure:
                        unavailable
                    default:
                        SkeletonView()
                    }
                }
            }
            .clipped()
    }

    /// Сдвигаем кадр относительно его позиции в скролле — фотография
    /// «дышит» медленнее ленты. Это фирменная деталь экрана.
    nonisolated private static func shift(_ proxy: GeometryProxy) -> CGFloat {
        guard let container = proxy.bounds(of: .scrollView(axis: .vertical)),
              container.height > 0
        else { return 0 }

        let frame = proxy.frame(in: .scrollView(axis: .vertical))
        let progress = (frame.midY - container.height / 2) / container.height
        return -progress * DS.Motion.parallaxDepth
    }

    private var unavailable: some View {
        DS.Palette.textSecondary
            .opacity(DS.Opacity.subtle)
            .overlay {
                Image(systemName: "camera.metering.unknown")
                    .font(DS.Typography.title)
                    .foregroundStyle(DS.Palette.textSecondary)
            }
    }
}
