import AuthenticationServices
import Foundation

/// Sign in with Apple, свёрнутый в один `await`.
///
/// `ASAuthorizationController` работает через делегата, а вызывающему коду
/// нужен результат — поэтому делегат живёт ровно на время запроса и держит
/// сам себя, пока система не ответит.
@MainActor
enum AppleSignIn {

    struct Result {
        /// JWT, который проверит бэкенд. Наружу мы его не разбираем.
        let identityToken: String
        /// Apple отдаёт имя один раз, при первой авторизации. Второго шанса
        /// не будет, поэтому передаём его на сервер сразу.
        let name: String
    }

    enum Failure: Error {
        case cancelled
        case noIdentityToken
        case failed(String)
    }

    static func run() async throws -> Result {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        return try await withCheckedThrowingContinuation { continuation in
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = Delegate(continuation: continuation)
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            // Контроллер держит делегата слабо — без этого он умрёт раньше ответа.
            delegate.retain(controller)
            controller.performRequests()
        }
    }

    private final class Delegate: NSObject, ASAuthorizationControllerDelegate,
        ASAuthorizationControllerPresentationContextProviding {

        private let continuation: CheckedContinuation<Result, Error>
        private var controller: ASAuthorizationController?
        private var isFinished = false

        init(continuation: CheckedContinuation<Result, Error>) {
            self.continuation = continuation
        }

        func retain(_ controller: ASAuthorizationController) {
            self.controller = controller
            // Пока запрос идёт, делегата не должно унести ARC.
            objc_setAssociatedObject(controller, &Self.key, self, .OBJC_ASSOCIATION_RETAIN)
        }

        private static var key: UInt8 = 0

        private func finish(_ result: Swift.Result<Result, Error>) {
            // Система может позвать делегата дважды на отмене — вторая
            // отправка в continuation это краш, а не ошибка.
            guard !isFinished else { return }
            isFinished = true
            controller = nil
            continuation.resume(with: result)
        }

        func authorizationController(
            controller: ASAuthorizationController,
            didCompleteWithAuthorization authorization: ASAuthorization
        ) {
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let data = credential.identityToken,
                let token = String(data: data, encoding: .utf8)
            else {
                finish(.failure(Failure.noIdentityToken))
                return
            }

            let parts = [credential.fullName?.givenName, credential.fullName?.familyName]
            let name = parts.compactMap { $0 }.joined(separator: " ")
            finish(.success(Result(identityToken: token, name: name)))
        }

        func authorizationController(
            controller: ASAuthorizationController,
            didCompleteWithError error: Error
        ) {
            let code = (error as? ASAuthorizationError)?.code
            if code == .canceled {
                finish(.failure(Failure.cancelled))
            } else {
                finish(.failure(Failure.failed(error.localizedDescription)))
            }
        }

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
            return scene?.keyWindow ?? ASPresentationAnchor()
        }
    }
}
