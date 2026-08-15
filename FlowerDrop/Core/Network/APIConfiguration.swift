import Foundation

/// Адрес бэкенда приходит из Info.plist, а тот — из build-конфигурации.
/// Debug смотрит на localhost, Release — на боевой хост, и подменить это
/// из кода нельзя.
enum APIConfiguration {
    static var baseURL: URL {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
            let url = URL(string: raw)
        else {
            preconditionFailure("APIBaseURL отсутствует в Info.plist сборки")
        }
        return url
    }
}


/// Прочие значения из Info.plist. Отдельно от адреса бэкенда, потому что
/// это настройки не сети, а входа.
enum AppConfiguration {
    /// Client ID из Google Cloud Console. Не секрет: он зашит в приложение
    /// по замыслу OAuth для публичных клиентов, а тайну бережёт PKCE.
    /// `nil` означает «Google-вход не настроен» — кнопка не показывается.
    static var googleClientID: String? {
        let value = Bundle.main.object(forInfoDictionaryKey: "GoogleClientID") as? String
        return (value?.isEmpty == false) ? value : nil
    }
}
