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
    @AppStorage(AppScene.onboardingKey) private var hasSeenOnboarding = false
    @State private var demoClient = DemoAPIClient()
    /// Меняется, когда сцену надо собрать заново, не меняя режим, — сейчас
    /// это единственный случай: после удаления аккаунта.
    @State private var sessionID = UUID()

    private let liveClient: any APIClient

    init(client: any APIClient = RealAPIClient()) {
        self.liveClient = client
    }

    private var authNamespace: String {
        isDemoMode ? DemoMode.authNamespace : ""
    }

    var body: some View {
        AppScene(
            client: isDemoMode ? demoClient : liveClient,
            authNamespace: authNamespace
        )
        .id(SceneIdentity(isDemoMode: isDemoMode, session: sessionID))
        .environment(\.isDemoMode, isDemoMode)
        .environment(\.demoModeToggle, DemoModeToggle(toggle: toggleDemoMode))
        .environment(\.appSessionReset, AppSessionReset(reset: resetToOnboarding))
    }

    /// Демо всегда начинается с чистого листа: новый клиент — значит пустые
    /// резервы и полный остаток, а демо-токен не переживает показ.
    private func toggleDemoMode() {
        AuthStore.clear(namespace: DemoMode.authNamespace)
        demoClient = DemoAPIClient()
        withAnimation(DS.Motion.spring) { isDemoMode.toggle() }
    }

    /// После удаления аккаунта приложение обязано выглядеть как только что
    /// установленное: ни токена, ни номера, ни пройденного знакомства.
    private func resetToOnboarding() {
        AuthStore.clear(namespace: authNamespace)
        if isDemoMode {
            demoClient = DemoAPIClient()
        }
        withAnimation(DS.Motion.spring) {
            hasSeenOnboarding = false
            sessionID = UUID()
        }
    }
}

/// Пара «режим + сессия»: смена любого из двух пересобирает сцену вместе
/// со всеми сторами, которые получили клиента в `init`.
private struct SceneIdentity: Hashable {
    let isDemoMode: Bool
    let session: UUID
}

/// Полный сброс приложения к экрану знакомства. В окружении, потому что
/// просит его экран профиля, лежащий на несколько уровней ниже.
struct AppSessionReset {
    let reset: () -> Void

    static let inactive = AppSessionReset {}
}

private struct AppSessionResetKey: EnvironmentKey {
    static let defaultValue = AppSessionReset.inactive
}

extension EnvironmentValues {
    var appSessionReset: AppSessionReset {
        get { self[AppSessionResetKey.self] }
        set { self[AppSessionResetKey.self] = newValue }
    }
}

/// Две вкладки, а поверх них — экран букета: лента и деталь обязаны жить
/// в одном стеке, иначе фотография не перелетит из карточки.
private struct AppScene: View {
    /// Один ключ на два места: сцена его читает, корень — сбрасывает.
    static let onboardingKey = "onboarding.seen"

    @State private var feed: FeedViewModel
    @State private var auth: AuthStore
    @State private var reservations: ReservationStore
    @State private var tab: Tab = .feed
    @State private var selected: Bouquet?
    @Namespace private var hero
    /// Экран знакомства показывается один раз за установку.
    @AppStorage(AppScene.onboardingKey) private var hasSeenOnboarding = false

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
