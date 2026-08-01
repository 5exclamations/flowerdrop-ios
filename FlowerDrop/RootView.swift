import SwiftUI

/// Корень приложения: выбирает, с каким бэкендом работать — настоящим или
/// демонстрационным, — и пересоздаёт сцену при переключении.
///
/// Сторы получают клиента в `init`, поэтому подменить его на лету нельзя:
/// `.id(isDemoMode)` заставляет SwiftUI собрать сцену заново, и вместе с ней
/// заново создаются лента, вход и резервы. Это же и есть сброс состояния
/// при выходе из демо.
struct RootView: View {
    @AppStorage(DemoMode.storageKey) private var isDemoMode = false
    @State private var demoClient = DemoAPIClient()

    private let liveClient: any APIClient

    init(client: any APIClient = RealAPIClient()) {
        self.liveClient = client
    }

    var body: some View {
        AppScene(
            client: isDemoMode ? demoClient : liveClient,
            authNamespace: isDemoMode ? DemoMode.authNamespace : ""
        )
        .id(isDemoMode)
        .environment(\.isDemoMode, isDemoMode)
        .environment(\.demoModeToggle, DemoModeToggle(toggle: toggleDemoMode))
    }

    /// Демо всегда начинается с чистого листа: новый клиент — значит пустые
    /// резервы и полный остаток, а демо-токен не переживает показ.
    private func toggleDemoMode() {
        AuthStore.clear(namespace: DemoMode.authNamespace)
        demoClient = DemoAPIClient()
        withAnimation(DS.Motion.spring) { isDemoMode.toggle() }
    }
}

/// Две вкладки, а поверх них — экран букета: лента и деталь обязаны жить
/// в одном стеке, иначе фотография не перелетит из карточки.
private struct AppScene: View {
    @State private var feed: FeedViewModel
    @State private var auth: AuthStore
    @State private var reservations: ReservationStore
    @State private var tab: Tab = .feed
    @State private var selected: Bouquet?
    @Namespace private var hero
    /// Экран знакомства показывается один раз за установку.
    @AppStorage("onboarding.seen") private var hasSeenOnboarding = false

    private let client: any APIClient

    private enum Tab {
        case feed
        case reservations
    }

    init(client: any APIClient, authNamespace: String) {
        self.client = client
        let auth = AuthStore(client: client, namespace: authNamespace)
        _auth = State(initialValue: auth)
        _feed = State(initialValue: FeedViewModel(client: client))
        _reservations = State(initialValue: ReservationStore(client: client, auth: auth))
    }

    var body: some View {
        ZStack {
            TabView(selection: $tab) {
                FeedView(viewModel: feed, namespace: hero, isDetailShown: selected != nil) { bouquet in
                    withAnimation(DS.Motion.hero) { selected = bouquet }
                }
                .tabItem {
                    Label("Лента", systemImage: "square.grid.2x2")
                }
                .tag(Tab.feed)

                MyReservationsView()
                    .tabItem {
                        Label("Мои резервы", systemImage: "basket")
                    }
                    .tag(Tab.reservations)
            }

            if let bouquet = selected {
                BouquetDetailView(
                    bouquet: bouquet,
                    namespace: hero,
                    corrections: FeedCorrections(
                        replace: { feed.replace($0) },
                        remove: { id in
                            feed.remove(id: id)
                            close()
                        }
                    ),
                    onClose: close,
                    onShowReservations: {
                        tab = .reservations
                        close()
                    }
                )
                .transition(.opacity)
                .zIndex(1)
            }

            if !hasSeenOnboarding {
                OnboardingView {
                    withAnimation(DS.Motion.spring) { hasSeenOnboarding = true }
                }
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .environment(\.apiClient, client)
        .environment(auth)
        .environment(reservations)
    }

    private func close() {
        withAnimation(DS.Motion.hero) { selected = nil }
    }
}

/// Что экран букета просит поправить в ленте, когда сервер сказал своё.
struct FeedCorrections {
    /// Свежие данные по букету — после проигранной гонки за остаток.
    let replace: (Bouquet) -> Void
    /// 404: такого букета нет, карточку убрать.
    let remove: (Int) -> Void
}
