import SwiftUI

/// Цена поверх фотографии: новая крупная, старая зачёркнута.
struct PhotoPriceLabel: View {
    let bouquet: Bouquet
    var compact = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.xs) {
            Text(verbatim: DS.Format.price(bouquet.discountedPrice))
                .font(compact ? DS.Typography.priceCompact : DS.Typography.price)
                .foregroundStyle(DS.Palette.onPhoto)

            Text(verbatim: DS.Format.price(bouquet.originalPrice))
                .font(DS.Typography.priceStruck)
                .strikethrough()
                .foregroundStyle(DS.Palette.onPhoto.opacity(DS.Opacity.strong))
        }
        .accessibilityElement(children: .combine)
    }
}

/// Остаток букетов поверх фото. В сетке нет места на слово «осталось»,
/// поэтому иконка и число, а полная фраза уходит в VoiceOver.
struct PhotoCountChip: View {
    let count: Int

    var body: some View {
        HStack(spacing: DS.Spacing.xxs) {
            Image(systemName: "basket")
            Text(verbatim: "\(count)")
                .monospacedDigit()
        }
        .font(DS.Typography.caption)
        .foregroundStyle(DS.Palette.onPhoto)
        .padding(.horizontal, DS.Spacing.xs)
        .padding(.vertical, DS.Spacing.xxs)
        .background(DS.Palette.scrim.opacity(DS.Opacity.strong), in: DS.Radius.shape)
        .accessibilityElement()
        .accessibilityLabel("осталось \(count)")
    }
}
