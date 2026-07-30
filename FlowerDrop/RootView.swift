import SwiftUI

/// Лента и экран букета живут в одном стеке — иначе фотография
/// не сможет перелететь из карточки на детальный экран.
struct RootView: View {
    @State private var store = ReservationStore()
    @State private var selected: Bouquet?
    @Namespace private var hero

    var body: some View {
        ZStack {
            FeedView(namespace: hero, isDetailShown: selected != nil) { bouquet in
                withAnimation(DS.Motion.hero) { selected = bouquet }
            }

            if let bouquet = selected {
                BouquetDetailView(bouquet: bouquet, namespace: hero) {
                    withAnimation(DS.Motion.hero) { selected = nil }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .environment(store)
    }
}
