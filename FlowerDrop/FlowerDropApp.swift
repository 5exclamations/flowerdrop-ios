import SwiftUI

@main
struct FlowerDropApp: App {
    var body: some Scene {
        WindowGroup {
            DesignSystemPreview()
                .tint(DS.Palette.accent)
        }
    }
}
