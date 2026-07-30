import SwiftUI

/// Активные резервы: код, лавка и время, до которого держат букет.
struct MyReservationsView: View {
    @Environment(ReservationStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                Text("Мои резервы")
                    .font(DS.Typography.display)
                    .foregroundStyle(DS.Palette.textPrimary)

                if store.activeReservations.isEmpty {
                    FeedPlaceholder(
                        systemImage: "basket",
                        title: "Пока пусто",
                        message: "Зарезервируй букет — он появится здесь вместе с кодом получения."
                    )
                } else {
                    ForEach(store.activeReservations) { reservation in
                        ReservationRow(reservation: reservation)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Spacing.m)
        }
        .scrollIndicators(.hidden)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(DS.Palette.bg)
    }
}

private struct ReservationRow: View {
    let reservation: ReservationStore.Reservation

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.m) {
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text(reservation.bouquet.title)
                    .font(DS.Typography.bodyEmphasized)
                    .foregroundStyle(DS.Palette.textPrimary)

                Text(verbatim: reservation.bouquet.shopName)
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Palette.textSecondary)

                Label("до \(reservation.expiresAtText)", systemImage: "hourglass")
                    .font(DS.Typography.caption)
                    .foregroundStyle(DS.Palette.accentSecondary)
            }

            Spacer(minLength: DS.Spacing.xs)

            Text(verbatim: reservation.code)
                .font(DS.Typography.price)
                .foregroundStyle(DS.Palette.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
        .accessibilityElement(children: .combine)
    }
}
