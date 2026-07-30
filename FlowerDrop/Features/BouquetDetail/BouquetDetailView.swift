import SwiftUI

/// Экран букета: фотография во всю ширину под статусбаром,
/// факты о букете и закреплённая снизу кнопка резерва.
struct BouquetDetailView: View {
    let namespace: Namespace.ID
    let corrections: FeedCorrections
    let onClose: () -> Void
    let onShowReservations: () -> Void

    @Environment(\.apiClient) private var client
    @Environment(ReservationStore.self) private var reservations
    @Environment(AuthStore.self) private var auth

    /// Своя копия: после проигранной гонки перечитываем букет с сервера.
    @State private var bouquet: Bouquet
    @State private var isConfirming = false
    @State private var isReserving = false
    @State private var pendingReservation: Reservation?
    @State private var presented: Presentation?
    @State private var confirmAfterAuth = false
    @State private var alert: ReserveAlert?

    init(
        bouquet: Bouquet,
        namespace: Namespace.ID,
        corrections: FeedCorrections,
        onClose: @escaping () -> Void,
        onShowReservations: @escaping () -> Void
    ) {
        _bouquet = State(initialValue: bouquet)
        self.namespace = namespace
        self.corrections = corrections
        self.onClose = onClose
        self.onShowReservations = onShowReservations
    }

    /// Полноэкранных презентаций на вью может быть только одна,
    /// поэтому вход и успех живут в общем перечислении.
    private enum Presentation: Identifiable {
        case auth
        case success(Reservation)

        var id: String {
            switch self {
            case .auth: "auth"
            case .success(let reservation): "success-\(reservation.id)"
            }
        }
    }

    private enum ReserveAlert: Identifiable {
        /// 409 bouquet_unavailable — лента протухла.
        case soldOut
        /// 409 already_reserved.
        case alreadyMine
        /// Сеть или сервер — можно просто попробовать снова.
        case failed

        var id: String {
            switch self {
            case .soldOut: "soldOut"
            case .alreadyMine: "alreadyMine"
            case .failed: "failed"
            }
        }
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
            ReserveConfirmationSheet(bouquet: bouquet, isBusy: isReserving) {
                Task { await confirmReservation() }
            }
        }
        .fullScreenCover(item: $presented, onDismiss: continueAfterAuth) { presentation in
            switch presentation {
            case .auth:
                AuthFlowView()
            case .success(let reservation):
                ReservationSuccessView(reservation: reservation) {
                    presented = nil
                } onOpenReservations: {
                    presented = nil
                    onShowReservations()
                }
            }
        }
        .alert(item: $alert) { alert in
            switch alert {
            case .soldOut:
                Alert(
                    title: Text("Только что разобрали"),
                    message: Text("Кто-то успел раньше. Мы обновили ленту."),
                    dismissButton: .default(Text("Понятно"))
                )
            case .alreadyMine:
                Alert(
                    title: Text("Этот букет уже у вас"),
                    message: Text("Код получения ждёт в «Моих резервах»."),
                    dismissButton: .default(Text("Понятно"))
                )
            case .failed:
                Alert(
                    title: Text("Не получилось зарезервировать"),
                    message: Text("Проверь соединение и попробуй ещё раз."),
                    dismissButton: .default(Text("Понятно"))
                )
            }
        }
    }

    // MARK: - Сценарий резерва

    private func reserveTapped() {
        guard auth.isSignedIn else {
            confirmAfterAuth = true
            presented = .auth
            return
        }
        isConfirming = true
    }

    private func confirmReservation() async {
        isReserving = true
        defer { isReserving = false }

        do {
            pendingReservation = try await reservations.reserve(bouquet)
            isConfirming = false
        } catch let error as APIError {
            isConfirming = false
            await handle(error)
        } catch {
            isConfirming = false
            alert = .failed
        }
    }

    /// Разбор по контракту: 404 и 409 — разные случаи.
    private func handle(_ error: APIError) async {
        switch error {
        case .notFound:
            corrections.remove(bouquet.id)
        case .bouquetUnavailable:
            await refreshBouquet()
            alert = .soldOut
        case .alreadyReserved:
            alert = .alreadyMine
        case .notAuthenticated:
            auth.signOut()
            confirmAfterAuth = true
            presented = .auth
        default:
            alert = .failed
        }
    }

    /// Тянем свежий букет и чиним и экран, и карточку в ленте.
    private func refreshBouquet() async {
        guard let fresh = try? await client.bouquet(id: bouquet.id) else { return }
        bouquet = fresh
        corrections.replace(fresh)
    }

    /// После входа сразу продолжаем резерв — пользователь нажимал именно его.
    private func continueAfterAuth() {
        guard confirmAfterAuth else { return }
        confirmAfterAuth = false
        if auth.isSignedIn { isConfirming = true }
    }

    /// Успех показываем только после того, как sheet закрылся —
    /// две презентации одновременно iOS не любит.
    private func presentSuccessIfReserved() {
        guard let pendingReservation else { return }
        presented = .success(pendingReservation)
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

                Text(verbatim: bouquet.shopLine)
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Palette.textSecondary)
            }

            HStack(spacing: DS.Spacing.xs) {
                InfoChip(
                    systemImage: "clock",
                    title: "до \(bouquet.pickupUntilText)",
                    isAccented: true
                )
                InfoChip(systemImage: "basket", title: "осталось \(bouquet.quantityLeft)")
            }

            PriceTag(
                original: bouquet.originalPrice,
                current: bouquet.discountedPrice,
                discountPercent: bouquet.discountPercent
            )

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
            bouquet.isAvailable ? "Зарезервировать" : "Разобрали",
            systemImage: bouquet.isAvailable ? "basket" : "xmark",
            action: reserveTapped
        )
        .disabled(!bouquet.isAvailable)
        .padding(DS.Spacing.m)
        .background(DS.Palette.surface.ignoresSafeArea(edges: .bottom))
    }
}
