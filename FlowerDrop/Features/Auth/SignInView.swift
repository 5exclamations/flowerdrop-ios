import AuthenticationServices
import SwiftUI

/// Вход: две кнопки и ни одного поля. Показываем при первой попытке
/// зарезервировать букет, а не на старте — витрину смотрят без входа.
struct SignInView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var busy: AuthProvider?
    @State private var failure: LocalizedStringKey?

    var body: some View {
        ZStack {
            DS.Palette.bg
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                HStack {
                    Spacer(minLength: 0)
                    closeButton
                }

                Spacer(minLength: DS.Spacing.l)

                Text("Вход")
                    .font(DS.Typography.display)
                    .foregroundStyle(DS.Palette.textPrimary)

                Text("Нужен, чтобы держать букет за вами. Номер телефона можно добавить потом — он нужен только чтобы лавка могла позвонить.")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: DS.Spacing.l)

                buttons

                if let failure {
                    Label(failure, systemImage: "exclamationmark.circle")
                        .font(DS.Typography.callout)
                        .foregroundStyle(DS.Palette.accentSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: DS.Spacing.xl)
            }
            .padding(.horizontal, DS.Spacing.m)
            .padding(.top, DS.Spacing.xs)
        }
    }

    private var buttons: some View {
        VStack(spacing: DS.Spacing.s) {
            // Системная кнопка Apple: её вид, размер и текст диктует HIG,
            // и переопределять их нельзя — ревью на это смотрит.
            SignInWithAppleButton(.signIn) { _ in
            } onCompletion: { _ in
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: DS.Size.control)
            .clipShape(DS.Radius.shape)
            .allowsHitTesting(false)
            .overlay {
                // Кнопка Apple не отдаёт свой результат в async-код, а нам
                // нужен именно он. Жест снимаем поверх, вид остаётся её.
                Color.clear
                    .contentShape(.rect)
                    .onTapGesture { start(.apple) }
            }
            .opacity(busy == nil ? 1 : DS.Opacity.strong)

            googleButton
        }
        .disabled(busy != nil)
    }

    /// Google диктует свои требования к кнопке: собственный знак, читаемая
    /// подпись, никакой самодеятельности с цветом знака.
    private var googleButton: some View {
        Button {
            start(.google)
        } label: {
            HStack(spacing: DS.Spacing.xs) {
                if busy == .google {
                    ProgressView().tint(DS.Palette.textPrimary)
                } else {
                    // ЗАГЛУШКА. Гайдлайны Google требуют их собственный
                    // четырёхцветный знак «G»; брать его из интернета и
                    // класть в репозиторий — вопрос лицензии, поэтому знак
                    // добавляется из официального brand kit перед подачей.
                    Image(systemName: "person.crop.circle")
                        .font(DS.Typography.body)
                        .frame(width: DS.Size.providerMark, height: DS.Size.providerMark)
                }
                Text("Войти через Google")
            }
            .font(DS.Typography.bodyEmphasized)
            .foregroundStyle(DS.Palette.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: DS.Size.control)
            .background(DS.Palette.surface, in: DS.Radius.shape)
        }
        .buttonStyle(.pressable)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(DS.Typography.bodyEmphasized)
                .foregroundStyle(DS.Palette.textPrimary)
                .frame(width: DS.Size.minTapTarget, height: DS.Size.minTapTarget)
                .background(DS.Palette.surface, in: Circle())
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(Text("Закрыть"))
    }

    private func start(_ provider: AuthProvider) {
        busy = provider
        failure = nil
        Task {
            do {
                switch provider {
                case .apple:
                    let result = try await AppleSignIn.run()
                    try await auth.signIn(
                        provider: .apple,
                        identityToken: result.identityToken,
                        name: result.name
                    )
                case .google:
                    let token = try await GoogleSignIn.run()
                    try await auth.signIn(provider: .google, identityToken: token, name: "")
                }
                dismiss()
            } catch is CancellationError {
                // Человек передумал — это не ошибка.
            } catch AppleSignIn.Failure.cancelled, GoogleSignIn.Failure.cancelled {
            } catch GoogleSignIn.Failure.notConfigured {
                failure = "Вход через Google не настроен в этой сборке."
            } catch let error as APIError where error == .unreachable {
                failure = "Нет связи с сервером. Проверьте соединение."
            } catch {
                failure = "Войти не удалось. Попробуйте ещё раз."
            }
            busy = nil
        }
    }
}
