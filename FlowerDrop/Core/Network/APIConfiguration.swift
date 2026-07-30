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
