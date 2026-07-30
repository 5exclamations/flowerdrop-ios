import SwiftUI

@main
struct FlowerDropApp: App {
    var body: some Scene {
        WindowGroup {
            FeedView()
                .tint(DS.Palette.accent)
        }
    }
}
