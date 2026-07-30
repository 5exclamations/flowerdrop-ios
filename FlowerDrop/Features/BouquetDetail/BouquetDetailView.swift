import SwiftUI

/// Экран букета: фотография во всю ширину под статусбаром,
/// факты о букете и закреплённая снизу кнопка резерва.
struct BouquetDetailView: View {
    let bouquet: Bouquet
    let namespace: Namespace.ID
    let onClose: () -> Void

    @Environment(ReservationStore.self) private var store

    @State private var isConfirming = false
    @State private var pendingReservation: ReservationStore.Reservation?
    @State private var successReservation: ReservationStore.Reservation?

    private var remaining: Int {
        store.remaining(for: bouquet)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            DS.Palette.bg
                .ignoresSafeArea()

            scrollContent

            closeButton
                .padding(DS.Spacing.m)
        }
        .safeAreaInset(edge: .bottom) { reserveBar }
        .sheet(isPresented: $isConfirming, onDismiss: presentSuccessIfReserved) {
            ReserveConfirmationSheet(bouquet: bouquet) {
                pendingReservation = store.reserve(bouquet)
                isConfirming = false
            }
        }
        .fullScreenCover(item: $successReservation) { reservation in
            ReservationSuccessView(reservation: reservation) {
                successReservation = nil
            }
        }
    }

    /// Успех показываем только после того, как sheet закрылся —
    /// две презентации одновременно iOS не любит.
    private func presentSuccessIfReserved() {
        guard let pendingReservation else { return }
        successReservation = pendingReservation
        self.pendingReservation = nil
    }

    // MARK: - Содержимое

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                photo
                details
            }
            .padding(.bottom, DS.Spacing.l)
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
    }

    private var photo: some View {
        BouquetPhoto(url: bouquet.imageURL, parallax: false)
            .matchedGeometryEffect(id: bouquet.id, in: namespace, isSource: true)
            .overlay { DS.photoScrim }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text(bouquet.title)
                    .font(DS.Typography.display)
                    .foregroundStyle(DS.Palette.textPrimary)

                Text(verbatim: "\(bouquet.shopName) · \(bouquet.distanceText)")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Palette.textSecondary)
            }

            HStack(spacing: DS.Spacing.xs) {
                InfoChip(
                    systemImage: "clock",
                    title: "до \(bouquet.pickupUntilText)",
                    isAccented: true
                )
                InfoChip(systemImage: "basket", title: "осталось \(remaining)")
            }

            PriceTag(original: bouquet.originalPrice, current: bouquet.discountedPrice)

            Text(bouquet.summary)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Palette.textSecondary)
                .lineSpacing(DS.Spacing.xxs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Spacing.m)
    }

    // MARK: - Управление

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "chevron.left")
                .font(DS.Typography.bodyEmphasized)
                .foregroundStyle(DS.Palette.onPhoto)
                .frame(width: DS.Size.minTapTarget, height: DS.Size.minTapTarget)
                .background(DS.Palette.scrim.opacity(DS.Opacity.strong), in: DS.Radius.shape)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Назад")
    }

    private var reserveBar: some View {
        PrimaryButton(
            remaining > 0 ? "Зарезервировать" : "Разобрали",
            systemImage: remaining > 0 ? "basket" : "xmark"
        ) {
            isConfirming = true
        }
        .disabled(remaining == 0)
        .padding(DS.Spacing.m)
        .background(DS.Palette.surface.ignoresSafeArea(edges: .bottom))
    }
}
