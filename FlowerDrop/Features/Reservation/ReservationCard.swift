import SwiftUI

/// Карточка резерва: мини-фото, лавка, код получения и живой отсчёт
/// до истечения брони.
///
/// `TimelineView` обёрнут только вокруг строки отсчёта. Когда он охватывал
/// всю карточку, ежесекундная перерисовка отменяла загрузку фотографии,
/// и вместо неё оставалась заглушка.
struct ReservationCard: View {
    let reservation: ReservationStore.Reservation
    let onPickedUp: () -> Void

    private var status: ReservationStore.Status {
        reservation.status()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack(alignment: .top, spacing: DS.Spacing.s) {
                thumbnail
                details
                Spacer(minLength: DS.Spacing.xs)
                code
            }

            if status == .active {
                pickedUpButton
            }
        }
        .dsCard()
        .opacity(status == .expired ? DS.Opacity.strong : 1)
    }

    private var thumbnail: some View {
        BouquetPhoto(url: reservation.bouquet.imageURL, parallax: false)
            .frame(width: DS.Size.thumbnail)
            .clipShape(DS.Radius.shape)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
            Text(verbatim: reservation.bouquet.shopName)
                .font(DS.Typography.bodyEmphasized)
                .foregroundStyle(DS.Palette.textPrimary)
                .lineLimit(1)

            Text(verbatim: reservation.bouquet.title)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Palette.textSecondary)
                .lineLimit(1)

            TimelineView(.periodic(from: .now, by: 1)) { context in
                statusLine(reservation.status(at: context.date), now: context.date)
            }
        }
    }

    private var code: some View {
        VStack(alignment: .trailing, spacing: DS.Spacing.xxs) {
            Text("Код")
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Palette.textSecondary)

            Text(verbatim: reservation.code)
                .font(DS.Typography.price)
                .foregroundStyle(status == .active ? DS.Palette.accent : DS.Palette.textSecondary)
                .strikethrough(status == .expired)
        }
        .accessibilityElement(children: .combine)
    }

    private var pickedUpButton: some View {
        Button(action: onPickedUp) {
            Text("Забрал")
                .font(DS.Typography.bodyEmphasized)
                .foregroundStyle(DS.Palette.accent)
                .frame(maxWidth: .infinity)
                .frame(minHeight: DS.Size.minTapTarget)
                .background(
                    DS.Palette.accent.opacity(DS.Opacity.subtle),
                    in: DS.Radius.shape
                )
        }
        .buttonStyle(.pressable)
    }

    @ViewBuilder
    private func statusLine(_ status: ReservationStore.Status, now: Date) -> some View {
        switch status {
        case .active:
            Label(
                "осталось \(reservation.timeLeft(at: now).formatted(.time(pattern: .hourMinuteSecond)))",
                systemImage: "hourglass"
            )
            .font(DS.Typography.caption)
            .foregroundStyle(DS.Palette.accentSecondary)
            .monospacedDigit()

        case .expired:
            Label("истёк", systemImage: "clock.badge.xmark")
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Palette.textSecondary)

        case .pickedUp:
            Label("получен", systemImage: "checkmark.seal")
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Palette.accent)
        }
    }
}
