import AuthenticationServices
import CryptoKit
import Foundation

/// Вход через Google без SDK: системный `ASWebAuthenticationSession` плюс
/// OAuth 2.0 с PKCE, как предписывает RFC 8252 для нативных приложений.
///
/// SDK здесь не нужен. У проекта правило «без сторонних зависимостей», и
/// весь выигрыш SDK — примерно эти полторы сотни строк, зато с чужим кодом
/// в приложении, собственным privacy-манифестом и своим циклом обновлений.
///
/// PKCE обязателен, а не украшение: у публичного клиента нет секрета, и без
/// `code_verifier` перехваченный код обменял бы на токены кто угодно.
@MainActor
enum GoogleSignIn {

    enum Failure: Error {
        case notConfigured
        case cancelled
        case failed(String)
    }

    private static let authorizeURL = URL(
        string: "https://accounts.google.com/o/oauth2/v2/auth"
    )!
    private static let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!

    /// Только личность, ничего больше: эти три скоупа несенситивные, и
    /// поэтому не требуют проверки приложения у Google.
    private static let scopes = "openid email profile"

    static func run() async throws -> String {
        guard let clientID = AppConfiguration.googleClientID, !clientID.isEmpty else {
            throw Failure.notConfigured
        }
        // Google требует именно такой redirect для iOS-клиента: обратный
        // client id как схема. Он же прописан в CFBundleURLTypes.
        let redirectURI = "\(reversed(clientID)):/oauth2redirect"

        let verifier = randomVerifier()
        let code = try await authorize(
            clientID: clientID,
            redirectURI: redirectURI,
            challenge: challenge(for: verifier)
        )
        return try await exchange(
            code: code,
            verifier: verifier,
            clientID: clientID,
            redirectURI: redirectURI
        )
    }

    // MARK: - Шаги

    private static func authorize(
        clientID: String,
        redirectURI: String,
        challenge: String
    ) async throws -> String {
        var components = URLComponents(url: authorizeURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            .init(name: "client_id", value: clientID),
            .init(name: "redirect_uri", value: redirectURI),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: scopes),
            .init(name: "code_challenge", value: challenge),
            .init(name: "code_challenge_method", value: "S256")
        ]

        let callback = try await present(
            url: components.url!,
            scheme: reversed(clientID)
        )

        let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems
        guard let code = items?.first(where: { $0.name == "code" })?.value else {
            let reason = items?.first { $0.name == "error" }?.value ?? "no code"
            throw Failure.failed(reason)
        }
        return code
    }

    private static func present(url: URL, scheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: scheme
            ) { callback, error in
                if let callback {
                    continuation.resume(returning: callback)
                } else if let error = error as? ASWebAuthenticationSessionError,
                          error.code == .canceledLogin {
                    continuation.resume(throwing: Failure.cancelled)
                } else {
                    continuation.resume(
                        throwing: Failure.failed(error?.localizedDescription ?? "unknown")
                    )
                }
            }
            session.presentationContextProvider = Anchor.shared
            // Пусть Google узнаёт уже вошедшего в браузере — иначе человек
            // вводит пароль каждый раз.
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    private static func exchange(
        code: String,
        verifier: String,
        clientID: String,
        redirectURI: String
    ) async throws -> String {
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )
        var body = URLComponents()
        body.queryItems = [
            .init(name: "client_id", value: clientID),
            .init(name: "code", value: code),
            .init(name: "code_verifier", value: verifier),
            .init(name: "grant_type", value: "authorization_code"),
            .init(name: "redirect_uri", value: redirectURI)
        ]
        request.httpBody = body.query?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode)
        else {
            throw Failure.failed("token endpoint \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }

        struct TokenResponse: Decodable {
            let idToken: String
            enum CodingKeys: String, CodingKey { case idToken = "id_token" }
        }
        guard let token = try? JSONDecoder().decode(TokenResponse.self, from: data) else {
            throw Failure.failed("token endpoint returned no id_token")
        }
        return token.idToken
    }

    // MARK: - PKCE

    private static func randomVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return base64URL(Data(bytes))
    }

    private static func challenge(for verifier: String) -> String {
        base64URL(Data(SHA256.hash(data: Data(verifier.utf8))))
    }

    private static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// `123-abc.apps.googleusercontent.com` → `com.googleusercontent.apps.123-abc`
    static func reversed(_ clientID: String) -> String {
        clientID.split(separator: ".").reversed().joined(separator: ".")
    }

    private final class Anchor: NSObject, ASWebAuthenticationPresentationContextProviding {
        static let shared = Anchor()

        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
            return scene?.keyWindow ?? ASPresentationAnchor()
        }
    }
}
