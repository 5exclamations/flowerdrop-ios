import SwiftUI

/// Экран успеха: код получения — главный герой экрана.
struct ReservationSuccessView: View {
    let reservation: ReservationStore.Reservation
    let onClose: () -> Void

    @State private var celebrated = false
    @State private var showsReservations = false

    var body: some View {
        VStack(spacing: DS.Spacing.m) {
            Spacer(minLength: DS.Spacing.xl)

            Image(systemName: "checkmark.seal")
                .font(DS.Typography.display)
                .foregroundStyle(DS.Palette.accent)

            Text("Букет ваш")
                .font(DS.Typography.display)
                .foregroundStyle(DS.Palette.textPrimary)

            Text("Назовите код в лавке — резерв держится до \(reservation.expiresAtText)")
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Palette.textSecondary)
                .multilineTextAlignment(.center)

            code
                .padding(.top, DS.Spacing.xs)

            Spacer(minLength: DS.Spacing.xl)

            VStack(spacing: DS.Spacing.xs) {
                PrimaryButton("В мои резервы", systemImage: "basket") {
                    showsReservations = true
                }

                Button("Закрыть", action: onClose)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Palette.textSecondary)
                    .frame(minHeight: DS.Size.minTapTarget)
            }
        }
        .padding(DS.Spacing.m)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Palette.bg)
        .sensoryFeedback(.success, trigger: celebrated)
        .onAppear { celebrated = true }
        .sheet(isPresented: $showsReservations) {
            MyReservationsView()
        }
    }

    private var code: some View {
        VStack(spacing: DS.Spacing.xs) {
            Text("Код получения")
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Palette.textSecondary)

            Text(verbatim: reservation.code)
                .font(DS.Typography.code)
                .kerning(DS.Typography.codeKerning)
                .foregroundStyle(DS.Palette.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .dsCard(padding: DS.Spacing.l)
        .accessibilityElement(children: .combine)
    }
}
