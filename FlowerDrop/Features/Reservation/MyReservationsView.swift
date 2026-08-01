import SwiftUI

/// Вкладка «Мои резервы»: список приходит с сервера, он же гасит просроченные.
struct MyReservationsView: View {
    @Environment(ReservationStore.self) private var store
    @Environment(AuthStore.self) private var auth
    @Environment(\.isDemoMode) private var isDemoMode

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.xs) {
                    Text("Мои резервы")
                        .font(DS.Typography.display)
                        .foregroundStyle(DS.Palette.textPrimary)

                    if isDemoMode {
                        DemoBadge()
                    }
                }

                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.Spacing.m)
            .padding(.top, DS.Spacing.xs)
            .padding(.bottom, DS.Spacing.xl)
        }
        .background(DS.Palette.bg)
        .scrollIndicators(.hidden)
        .refreshable { await store.refresh() }
        .task { await store.load() }
        .animation(DS.Motion.spring, value: store.state)
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            skeletons
        case .loaded(let items):
            ForEach(items) { reservation in
                ReservationCard(reservation: reservation) {
                    Task { await store.pickup(reservation) }
                }
            }
        case .empty:
            emptyState
        case .failed(let retryable):
            failedState(retryable: retryable)
        }
    }

    private var skeletons: some View {
        VStack(spacing: DS.Spacing.m) {
            ForEach(0..<2, id: \.self) { _ in
                SkeletonView()
                    .frame(height: DS.Size.thumbnail + DS.Spacing.xl)
            }
        }
    }

    private var emptyState: some View {
        FeedPlaceholder(
            systemImage: "basket",
            title: auth.isSignedIn ? "Пока нет резервов" : "Резервы после входа",
            message: auth.isSignedIn
                ? "Зарезервируй букет — он появится здесь вместе с кодом получения."
                : "Выбери букет в ленте — войти попросим на резерве."
        )
    }

    private func failedState(retryable: Bool) -> some View {
        FeedPlaceholder(
            systemImage: "wifi.exclamationmark",
            title: "Резервы не загрузились",
            message: "Проверь соединение и попробуй ещё раз."
        ) {
            if retryable {
                PrimaryButton("Повторить", systemImage: "arrow.clockwise") {
                    Task { await store.load() }
                }
            }
        }
    }
}
