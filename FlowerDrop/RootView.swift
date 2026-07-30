import SwiftUI

/// Две вкладки, а поверх них — экран букета: лента и деталь обязаны жить
/// в одном стеке, иначе фотография не перелетит из карточки.
struct RootView: View {
    @State private var feed: FeedViewModel
    @State private var auth: AuthStore
    @State private var reservations: ReservationStore
    @State private var tab: Tab = .feed
    @State private var selected: Bouquet?
    @Namespace private var hero

    private let client: any APIClient

    private enum Tab {
        case feed
        case reservations
    }

    init(client: any APIClient = RealAPIClient()) {
        self.client = client
        let auth = AuthStore(client: client)
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
