import SafariServices
import SwiftUI

/// Юридические страницы открываем в SFSafariViewController, а не в WKWebView
/// и не в Safari: App Review хочет видеть политику внутри приложения, а
/// собственный веб-контейнер пришлось бы объяснять отдельно.
///
/// Цвета берём из дизайн-системы — контроллер системный, но не чужой.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false

        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.preferredControlTintColor = UIColor(DS.Palette.accent)
        controller.preferredBarTintColor = UIColor(DS.Palette.bg)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
