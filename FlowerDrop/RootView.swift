import SwiftUI

/// Две вкладки, а поверх них — экран букета: лента и деталь обязаны жить
/// в одном стеке, иначе фотография не перелетит из карточки.
struct RootView: View {
    @State private var reservations = ReservationStore()
    @State private var auth = AuthStore()
    @State private var tab: Tab = .feed
    @State private var selected: Bouquet?
    @Namespace private var hero

    private enum Tab {
        case feed
        case reservations
    }

    var body: some View {
        ZStack {
            TabView(selection: $tab) {
                FeedView(namespace: hero, isDetailShown: selected != nil) { bouquet in
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
                BouquetDetailView(bouquet: bouquet, namespace: hero) {
                    withAnimation(DS.Motion.hero) { selected = nil }
                } onShowReservations: {
                    tab = .reservations
                    withAnimation(DS.Motion.hero) { selected = nil }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .environment(reservations)
        .environment(auth)
    }
}
