import SwiftUI

/// Профиль: номер, юридические ссылки и два выхода — из сессии и из сервиса.
///
/// Экран существует ради последней строки: App Store требует, чтобы аккаунт
/// удалялся из самого приложения (guideline 5.1.1(v)). Всё остальное здесь
/// потому, что кнопке «Удалить аккаунт» нужно место, где её ищут.
struct ProfileView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.apiClient) private var client
    @Environment(\.isDemoMode) private var isDemoMode
    @Environment(\.appSessionReset) private var sessionReset
    @Environment(\.dismiss) private var dismiss

    @State private var isConfirmingDeletion = false
    @State private var isDeleting = false
    @State private var failure: String?
    @State private var legalPage: LegalPage?

    /// Страницы живут на бэкенде — те же адреса указаны в App Store Connect,
    /// поэтому второй копии текста в приложении нет.
    private enum LegalPage: String, Identifiable {
        case privacy
        case terms

        var id: String { rawValue }

        var url: URL {
            APIConfiguration.baseURL.appending(path: rawValue)
        }

        var title: LocalizedStringKey {
            switch self {
            case .privacy: "Политика конфиденциальности"
            case .terms: "Условия использования"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.l) {
                    account
                    legal
                    dangerZone
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DS.Spacing.m)
            }
            .background(DS.Palette.bg)
            .scrollIndicators(.hidden)
            .navigationTitle(Text("Профиль"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                        .foregroundStyle(DS.Palette.accent)
                }
            }
        }
        .sheet(item: $legalPage) { page in
            SafariView(url: page.url)
                .ignoresSafeArea()
        }
        .confirmationDialog(
            Text("Удалить аккаунт?"),
            isPresented: $isConfirmingDeletion,
            titleVisibility: .visible
        ) {
            Button("Удалить аккаунт", role: .destructive) { delete() }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text(
                "Номер и активные резервы будут удалены без возможности восстановить. "
                + "Букеты, которые вы держите, вернутся в продажу."
            )
        }
        .alert(
            Text("Не удалось удалить аккаунт"),
            isPresented: .init(get: { failure != nil }, set: { if !$0 { failure = nil } })
        ) {
            Button("Понятно", role: .cancel) { failure = nil }
        } message: {
            Text(failure ?? "")
        }
    }

    // MARK: - Секции

    private var account: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text("Номер")
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Palette.textSecondary)

            HStack(spacing: DS.Spacing.xs) {
                Text(verbatim: auth.formattedPhone)
                    .font(DS.Typography.title)
                    .foregroundStyle(DS.Palette.textPrimary)
                    .monospacedDigit()

                if isDemoMode {
                    DemoBadge()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
    }

    private var legal: some View {
        VStack(spacing: 0) {
            legalRow(.privacy)
            Rectangle()
                .fill(DS.Palette.textSecondary.opacity(DS.Opacity.subtle))
                .frame(height: DS.Size.hairline)
            legalRow(.terms)
        }
        .dsCard(padding: 0)
    }

    private func legalRow(_ page: LegalPage) -> some View {
        Button {
            legalPage = page
        } label: {
            HStack(spacing: DS.Spacing.s) {
                Text(page.title)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Palette.textPrimary)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: DS.Spacing.xs)

                Image(systemName: "arrow.up.right")
                    .font(DS.Typography.callout)
                    .foregroundStyle(DS.Palette.textSecondary)
            }
            .padding(DS.Spacing.m)
            .frame(minHeight: DS.Size.minTapTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.pressable)
    }

    private var dangerZone: some View {
        VStack(spacing: DS.Spacing.s) {
            Button("Выйти") { signOut() }
                .font(DS.Typography.bodyEmphasized)
                .foregroundStyle(DS.Palette.accent)
                .frame(maxWidth: .infinity)
                .frame(height: DS.Size.control)
                .background(DS.Palette.surface, in: DS.Radius.shape)
                .buttonStyle(.pressable)

            Button {
                isConfirmingDeletion = true
            } label: {
                HStack(spacing: DS.Spacing.xs) {
                    if isDeleting {
                        ProgressView()
                            .tint(DS.Palette.accentSecondary)
                    }
                    Text("Удалить аккаунт")
                }
                .font(DS.Typography.bodyEmphasized)
                .foregroundStyle(DS.Palette.accentSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: DS.Size.control)
                .contentShape(.rect)
            }
            .buttonStyle(.pressable)
            .disabled(isDeleting)

            Text("Удаление необратимо. История резервов останется у лавки обезличенной.")
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Palette.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Действия

    private func signOut() {
        auth.signOut()
        dismiss()
    }

    private func delete() {
        guard let token = auth.token else { return }
        isDeleting = true
        Task {
            do {
                try await client.deleteAccount(token: token)
                // Сессии больше нет — приложение должно выглядеть так же,
                // как после установки.
                sessionReset.reset()
            } catch {
                failure = Self.message(for: error)
            }
            isDeleting = false
        }
    }

    private static func message(for error: Error) -> String {
        guard let apiError = error as? APIError else {
            return String(localized: "Что-то пошло не так. Попробуйте ещё раз.")
        }
        switch apiError {
        case .unreachable:
            return String(localized: "Нет связи с сервером. Проверьте соединение.")
        case .notAuthenticated:
            return String(localized: "Сессия истекла. Войдите заново.")
        default:
            return String(localized: "Что-то пошло не так. Попробуйте ещё раз.")
        }
    }
}
