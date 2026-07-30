import SwiftUI

/// Вкладка «Мои резервы»: активные брони сверху, истёкшие и полученные ниже.
struct MyReservationsView: View {
    @Environment(ReservationStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                Text("Мои резервы")
                    .font(DS.Typography.display)
                    .foregroundStyle(DS.Palette.textPrimary)
                    .padding(.top, DS.Spacing.xs)

                if store.reservations.isEmpty {
                    emptyState
                } else {
                    ForEach(store.sortedReservations) { reservation in
                        ReservationCard(reservation: reservation) {
                            store.markPickedUp(reservation.id)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.Spacing.m)
            .padding(.bottom, DS.Spacing.xl)
        }
        .background(DS.Palette.bg)
        .scrollIndicators(.hidden)
        .animation(DS.Motion.spring, value: store.reservations)
    }

    private var emptyState: some View {
        FeedPlaceholder(
            systemImage: "basket",
            title: "Пока нет резервов",
            message: "Зарезервируй букет — он появится здесь вместе с кодом получения."
        )
    }
}
