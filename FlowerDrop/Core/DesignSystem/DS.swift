import SwiftUI

/// Единственный источник визуальных токенов приложения.
/// Магические значения во вьюхах запрещены — всё берётся отсюда.
enum DS {

    // MARK: - Цвета

    /// Семантическая палитра. Светлая и тёмная версии живут в Assets.xcassets,
    /// поэтому тёмная тема работает без единого `colorScheme`-условия во вьюхах.
    enum Palette {
        static let bg = Color("bg")
        static let surface = Color("surface")
        static let accent = Color("accent")
        static let accentSecondary = Color("accentSecondary")
        /// Контент поверх accent / accentSecondary (белый в светлой, тёмный в тёмной).
        static let onAccent = Color("onAccent")
        static let textPrimary = Color("textPrimary")
        static let textSecondary = Color("textSecondary")

        /// Скрим поверх фотографии тёмный в обеих темах — значит и контент
        /// поверх него всегда светлый. Это не «магический white», а токен.
        static let scrim = Color.black
        static let onPhoto = Color.white
    }

    /// Затемнение под ценой и дедлайном на фото.
    static var photoScrim: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: Palette.scrim.opacity(Opacity.strong), location: 1)
            ],
            startPoint: .center,
            endPoint: .bottom
        )
    }

    // MARK: - Сетка отступов (8pt)

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - Радиус (один на всё приложение)

    enum Radius {
        static let value: CGFloat = 20
        static let style: RoundedCornerStyle = .continuous
        static var shape: RoundedRectangle {
            RoundedRectangle(cornerRadius: value, style: style)
        }
    }

    // MARK: - Прозрачность (ровно три значения)

    enum Opacity {
        static let subtle: Double = 0.08
        static let medium: Double = 0.32
        static let strong: Double = 0.72
    }

    // MARK: - Типографика

    /// Заголовки — serif semibold, остальное SF Pro, шкала 34/22/17/15/13.
    enum Typography {
        static let display = Font.system(size: 34, weight: .semibold, design: .serif)
        static let title = Font.system(size: 22, weight: .semibold, design: .serif)
        static let body = Font.system(size: 17)
        static let bodyEmphasized = Font.system(size: 17, weight: .semibold)
        static let callout = Font.system(size: 15)
        static let caption = Font.system(size: 13)
        static let eyebrow = Font.system(size: 13, weight: .semibold)
        static let eyebrowKerning: CGFloat = 1.2
        /// Нижняя граница автоуменьшения текста в тесных ячейках.
        static let minimumScale: CGFloat = 0.8

        /// Цены — моноширинные цифры, чтобы не «прыгали» при обновлении.
        /// Код получения резерва — крупно, серифом, с разрядкой.
        static let code = Font.system(size: 34, weight: .semibold, design: .serif).monospacedDigit()
        static let codeKerning: CGFloat = 8

        static let price = Font.system(size: 22, weight: .semibold).monospacedDigit()
        static let priceCompact = Font.system(size: 17, weight: .semibold).monospacedDigit()
        static let priceStruck = Font.system(size: 15).monospacedDigit()
        static let badge = Font.system(size: 13, weight: .semibold).monospacedDigit()
    }

    // MARK: - Движение

    enum Motion {
        static let spring = Animation.spring(response: 0.32, dampingFraction: 0.72)
        /// Перелёт фотографии из ленты на экран букета.
        static let hero = Animation.spring(response: 0.42, dampingFraction: 0.84)
        static let shimmerDuration: TimeInterval = 1.4
        static let pressedScale: CGFloat = 0.97
        /// Задержка между появлением соседних карточек, с.
        static let staggerStep: TimeInterval = 0.05
        /// Глубина параллакса фотографии при скролле, pt.
        static let parallaxDepth: CGFloat = 24
        /// Запас фотографии за краями кадра, чтобы параллакс не оголял углы.
        static let parallaxOverscan: CGFloat = 1.16
    }

    // MARK: - Размеры

    enum Size {
        /// Высота основной кнопки, кратна 8pt и выше минимального тапа 44pt.
        static let control: CGFloat = 56
        /// Photo-first: карточка товара всегда 4:5.
        static let photoAspectRatio: CGFloat = 4.0 / 5.0
        static let swatch: CGFloat = 56
        static let swatchMinWidth: CGFloat = 96
        /// Ширина карточки в горизонтальной полке «рядом с тобой».
        static let shelfCard: CGFloat = 160
        /// Минимальная зона нажатия по HIG.
        static let minTapTarget: CGFloat = 44
        /// Разделитель внутри карточки.
        static let hairline: CGFloat = 1
    }

    // MARK: - Формат

    enum Format {
        /// Азербайджанский манат. Символ ставим вручную: в ru-локали
        /// системный `.currency(code:)` печатает «AZN», а не ₼.
        static let currencySymbol = "₼"
        static let price = Decimal.FormatStyle().precision(.fractionLength(0...2))

        static func price(_ value: Decimal) -> String {
            "\(value.formatted(price)) \(currencySymbol)"
        }
    }
}

extension View {
    /// Карточка дизайн-системы: единый радиус, единая поверхность, без теней.
    func dsCard(padding: CGFloat = DS.Spacing.m) -> some View {
        self
            .padding(padding)
            .background(DS.Palette.surface, in: DS.Radius.shape)
    }
}
