import SwiftUI

/// Карточка ленты: фото 4:5, цена и скидка поверх фотографии,
/// подпись под ней. Нажатие даёт spring и haptic.
struct BouquetCardCompact: View {
    let bouquet: Bouquet
    let action: () -> Void

    @State private var tapCount = 0

    var body: some View {
        Button {
            tapCount += 1
            action()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                photo
                info
            }
            .background(DS.Palette.surface)
            .clipShape(DS.Radius.shape)
        }
        .buttonStyle(.pressable)
        .sensoryFeedback(.impact(weight: .light), trigger: tapCount)
        .accessibilityElement(children: .combine)
    }

    private var photo: some View {
        BouquetPhoto(url: bouquet.imageURL)
            .overlay { DS.photoScrim }
            .overlay(alignment: .topLeading) {
                DiscountBadge(percent: bouquet.discountPercent)
                    .padding(DS.Spacing.xs)
            }
            .overlay(alignment: .topTrailing) {
                PhotoCountChip(count: bouquet.quantityLeft)
                    .padding(DS.Spacing.xs)
            }
            .overlay(alignment: .bottomLeading) {
                PhotoPriceLabel(bouquet: bouquet, compact: true)
                    .padding(DS.Spacing.xs)
            }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
            Text(bouquet.title)
                .font(DS.Typography.bodyEmphasized)
                .foregroundStyle(DS.Palette.textPrimary)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)

            Text(verbatim: "\(bouquet.shopName) · \(bouquet.distanceText)")
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Palette.textSecondary)
                .lineLimit(1)

            Label("до \(bouquet.pickupUntilText)", systemImage: "clock")
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Palette.accentSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.s)
    }
}
