import SwiftUI

/// Фото букета 4:5 — основа карточек ленты и экрана букета.
/// Пока грузится, на его месте живёт скелетон того же размера,
/// поэтому лента не дёргается при появлении картинок.
struct BouquetPhoto: View {
    /// `nil` — лавка опубликовала букет без фотографии.
    let url: URL?
    var parallax = true

    /// Переходы между экранами пересоздают вью и отменяют загрузку.
    /// После `maxAttempts` показываем заглушку, но попытки не прекращаем:
    /// иначе исчерпанный счётчик оставлял бы заглушку навсегда — вкладки
    /// живут в памяти, и состояние вью не сбрасывается.
    private static let maxAttempts = 3
    private static let baseRetryDelay: TimeInterval = 0.6
    private static let maxRetryDelay: TimeInterval = 5

    @State private var attempt = 0

    var body: some View {
        Color.clear
            .aspectRatio(DS.Size.photoAspectRatio, contentMode: .fit)
            .overlay {
                if let url, let asset = DemoPhoto.assetName(for: url) {
                    // Демо-режим: фото вшито в ассеты, сеть не нужна вовсе.
                    photo(Image(asset))
                } else if let url {
                    AsyncImage(
                        url: url,
                        transaction: Transaction(animation: DS.Motion.spring)
                    ) { phase in
                        switch phase {
                        case .success(let image):
                            photo(image)
                        case .failure:
                            retryOrFail
                        default:
                            SkeletonView()
                        }
                    }
                    .id(attempt)
                } else {
                    unavailable
                }
            }
            .clipped()
    }

    private func photo(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFill()
            .scaleEffect(parallax ? DS.Motion.parallaxOverscan : 1)
            .visualEffect { content, proxy in
                content.offset(y: parallax ? Self.shift(proxy) : 0)
            }
    }

    private var retryOrFail: some View {
        Group {
            if attempt < Self.maxAttempts {
                SkeletonView()
            } else {
                unavailable
            }
        }
        .task(id: attempt) {
            let delay = min(
                Self.baseRetryDelay * pow(2, Double(min(attempt, 4))),
                Self.maxRetryDelay
            )
            try? await Task.sleep(for: .seconds(delay))
            attempt += 1
        }
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

    /// Спокойная заглушка вместо «сломанной камеры»: в витрине букетов
    /// иконка ошибки пугает сильнее, чем отсутствующее фото.
    private var unavailable: some View {
        DS.Palette.textSecondary
            .opacity(DS.Opacity.subtle)
            .overlay {
                Image(systemName: "leaf")
                    .font(DS.Typography.title)
                    .foregroundStyle(DS.Palette.textSecondary.opacity(DS.Opacity.strong))
            }
    }
}
