import SwiftUI

/// Главный экран: лента «вчерашних» букетов в две колонки.
struct FeedView: View {
    @State private var viewModel = FeedViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: DS.Spacing.s),
        GridItem(.flexible(), spacing: DS.Spacing.s)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                header
                content
            }
            .padding(.top, DS.Spacing.xs)
            .padding(.bottom, DS.Spacing.xl)
        }
        .background(DS.Palette.bg)
        .scrollIndicators(.hidden)
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.load() }
        .animation(DS.Motion.spring, value: viewModel.state)
    }

    // MARK: - Шапка

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
            Text(verbatim: "FlowerDrop")
                .font(DS.Typography.display)
                .foregroundStyle(DS.Palette.textPrimary)

            Label("Баку", systemImage: "mappin.and.ellipse")
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Palette.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Spacing.m)
    }

    // MARK: - Состояния

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            skeletons
        case .loaded(let items):
            grid(items)
        case .empty:
            emptyState
        case .failed:
            failedState
        }
    }

    private func grid(_ items: [Bouquet]) -> some View {
        LazyVGrid(columns: columns, spacing: DS.Spacing.s) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, bouquet in
                BouquetCardCompact(bouquet: bouquet) {}
                    .transition(appearance(at: index))
                    .scrollTransition { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : DS.Opacity.medium)
                            .scaleEffect(phase.isIdentity ? 1 : DS.Motion.pressedScale)
                    }
            }
        }
        .padding(.horizontal, DS.Spacing.m)
    }

    /// Карточки всплывают снизу с небольшой лесенкой — первый экран
    /// собирается сам, а не появляется рывком.
    private func appearance(at index: Int) -> AnyTransition {
        .opacity
        .combined(with: .offset(y: DS.Spacing.l))
        .animation(DS.Motion.spring.delay(Double(min(index, 5)) * DS.Motion.staggerStep))
    }

    private var skeletons: some View {
        LazyVGrid(columns: columns, spacing: DS.Spacing.s) {
            ForEach(0..<4, id: \.self) { _ in
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    SkeletonView()
                        .aspectRatio(DS.Size.photoAspectRatio, contentMode: .fit)
                    SkeletonView()
                        .frame(height: DS.Spacing.m)
                    SkeletonView()
                        .frame(height: DS.Spacing.s)
                        .padding(.trailing, DS.Spacing.xl)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.m)
    }

    private var emptyState: some View {
        FeedPlaceholder(
            systemImage: "basket",
            title: "Сегодня всё разобрали",
            message: "Загляни вечером — лавки выкладывают вчерашние букеты после шести."
        )
    }

    private var failedState: some View {
        FeedPlaceholder(
            systemImage: "wifi.exclamationmark",
            title: "Лента не загрузилась",
            message: "Проверь соединение и попробуй ещё раз."
        ) {
            PrimaryButton("Повторить", systemImage: "arrow.clockwise") {
                Task { await viewModel.load() }
            }
        }
    }
}

/// Задизайненная заглушка для пустого экрана и ошибки.
struct FeedPlaceholder<Action: View>: View {
    let systemImage: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    @ViewBuilder var action: () -> Action

    init(
        systemImage: String,
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        @ViewBuilder action: @escaping () -> Action = { EmptyView() }
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.action = action
    }

    var body: some View {
        VStack(spacing: DS.Spacing.s) {
            Image(systemName: systemImage)
                .font(DS.Typography.display)
                .foregroundStyle(DS.Palette.accent)
                .padding(.bottom, DS.Spacing.xxs)

            Text(title)
                .font(DS.Typography.title)
                .foregroundStyle(DS.Palette.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(DS.Typography.callout)
                .foregroundStyle(DS.Palette.textSecondary)
                .multilineTextAlignment(.center)

            action()
                .padding(.top, DS.Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DS.Spacing.xl)
        .padding(.horizontal, DS.Spacing.l)
    }
}

#Preview("Лента") {
    FeedView()
}
